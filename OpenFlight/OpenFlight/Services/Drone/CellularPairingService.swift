//    Copyright (C) 2021 Parrot Drones SAS
//
//    Redistribution and use in source and binary forms, with or without
//    modification, are permitted provided that the following conditions
//    are met:
//    * Redistributions of source code must retain the above copyright
//      notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright
//      notice, this list of conditions and the following disclaimer in
//      the documentation and/or other materials provided with the
//      distribution.
//    * Neither the name of the Parrot Company nor the names
//      of its contributors may be used to endorse or promote products
//      derived from this software without specific prior written
//      permission.
//
//    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
//    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
//    PARROT COMPANY BE LIABLE FOR ANY DIRECT, INDIRECT,
//    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
//    OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
//    AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
//    OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
//    SUCH DAMAGE.

import Foundation
import GroundSdk
import Combine
import SwiftyUserDefaults

// swiftlint:disable file_length

private extension ULogTag {
    static let tag = ULogTag(name: "CellularPairingService")
}

public protocol CellularPairingService: AnyObject {

    func retryPairingProcess()
    func startPairingProcessRequest()
    func startUnpairProcessRequest()
    func updateGsdkUserAccount()
    func updateAnonymousDroneList(token: String)

    var pairingProcessErrorPublisher: AnyPublisher<PairingProcessError?, Never> { get }
    var pairingProcessStepPublisher: AnyPublisher<PairingProcessStep?, Never> { get }
    var operatorNamePublisher: AnyPublisher<String?, Never> { get }
    var cellularStatusPublisher: AnyPublisher<DetailsCellularStatus, Never> { get }
    var unpairDroneStatePublisher: AnyPublisher<UnpairDroneState, Never> { get }

    var isWaitingAutoRetry: Bool { get }
}

public enum PairingAction {
    case pairUser
    case unpairUser
}

class CellularPairingServiceImpl: CellularPairingService {

    var pairingProcessErrorSubject = CurrentValueSubject<PairingProcessError?, Never>(nil)
    var pairingProcessStepSubject = CurrentValueSubject<PairingProcessStep?, Never>(nil)
    var operatorNameSubject = CurrentValueSubject<String?, Never>(nil)
    var cellularStatusSubject = CurrentValueSubject<DetailsCellularStatus, Never>(.noState)
    var unpairDroneStateSubject = CurrentValueSubject<UnpairDroneState, Never>(.notStarted)

    var isWaitingPairingAutoRetry = false

    // MARK: - Private Properties
    private var cellularRef: Ref<Cellular>?
    private var secureElementRef: Ref<SecureElement>?
    private var networkControlRef: Ref<NetworkControl>?
    private unowned let networkService: NetworkService
    private var academyApiService: AcademyApiService
    private var apcAPIManager = APCApiManager()
    private var isUserLogged: Bool { Defaults.isUserConnected || SecureKeyStorage.current.isTemporaryAccountCreated }
    private var signedChallengeToken: String?
    private var challenge: String?
    private var isSimLocked: Bool = true
    private var cancellables = Set<AnyCancellable>()
    private let currentDroneHolder: CurrentDroneHolder
    private let connectedDroneHolder: ConnectedDroneHolder
    private let userRepo: UserRepository
    private var pairingAction: PairingAction = .pairUser
    private var processErrorSubscription: AnyCancellable?
    private var userInformation: UserInformation { Services.hub.userInformation }

    /// Retry Pairing timer
    private var retryPairingTimer: Timer?

    init(currentDroneHolder: CurrentDroneHolder,
         userRepo: UserRepository,
         connectedDroneHolder: ConnectedDroneHolder,
         academyApiService: AcademyApiService,
         networkService: NetworkService) {
        self.currentDroneHolder = currentDroneHolder
        self.userRepo = userRepo
        self.connectedDroneHolder = connectedDroneHolder
        self.academyApiService = academyApiService
        self.networkService = networkService

        networkService.networkReachable
            .removeDuplicates()
            .sink { [weak self] reachable in
                guard let self = self else { return }
                if reachable {
                    if self.pairingAction == .pairUser,
                       self.pairingProcessErrorSubject.value != .noError {
                        // Don't wait the auto retry delay,
                        // relaunch the process as soon as data connection is reachable
                        self.retryPairingProcess()
                    }
                } else {
                    self.updateProcessError(error: .connectionUnreachable)
                }
            }
            .store(in: &cancellables)

        connectedDroneHolder.dronePublisher
            .compactMap { $0 }
            .sink { [unowned self] drone in
                listenSecureElement(drone)
                listenCellular(drone)
                listenNetworkControl(drone)
            }
            .store(in: &cancellables)

        academyApiService.academyErrorPublisher
            .compactMap { $0 }
            .sink { [unowned self] error in
                let decodedError = AcademyApiService.ApiError.error4xx(error)
                if decodedError == .authenticationError || decodedError == .accessDenied {
                    SecureKeyStorage.current.temporaryToken =  ""
                    retryPairingProcess()
                }
            }
            .store(in: &cancellables)

        // Listen when unpairing is successfully done.
        unpairDroneStatePublisher
            .removeDuplicates()
            .filter { $0 == .done }
            .sink { [unowned self] _ in
                // Restart drone when unpairing is done
                ULog.i(.tag, "Resetting Drone's Cellular Settings (Rebooting)...")
                _ = connectedDroneHolder.drone?.getPeripheral(Peripherals.cellular)?.resetSettings()
                updateUnpairDroneStatus(with: .notStarted)
            }
            .store(in: &cancellables)
    }

    // MARK: - Constants
    enum Constants {
        static let uploadRetrySlotTime = TimeInterval(30)
    }
}

extension CellularPairingServiceImpl {

    /// Retry pairing process if there is an error.
    // TODO: Discuss about the wished behavior when an unpair process fails.
    //       (As the drone must be restarted, we can't do this in background)
    func retryPairingProcess() {
        ULog.i(.tag, "retryPairingProcess")
        retryPairingTimer?.invalidate()
        pairingAction = .pairUser

        updateProcessError(error: .noError)

        // If user is not logged, start from the beginning (create temporary account)
        guard isUserLogged else {
            startProcess(action: .pairUser)
            return
        }

        switch pairingProcessStepSubject.value {
        case .challengeRequestSuccess:
            // Challenge is received by AcademyV
            guard challenge != nil else {
                // Incorrect challenge, returns to .notStarted to re-ask a challenge
                updateProcessStep(step: .notStarted)
                return
            }

            // Ask the drone's secure element to sign the challenge
            signChallenge(with: challenge)

        case .processing:
            // Challenge signing is ongoing, we should just wait in a 'normal' behaviour,
            // but in this case an error occured, so we need to go back to the previous step
            updateProcessError(error: .unableToConnect)
            updateProcessStep(step: .challengeRequestSuccess)

        case .challengeSignSuccess:
            // Challenge is correctly signed by the drone
            guard let signedChallengeToken = signedChallengeToken,
                  !signedChallengeToken.isEmpty else {
                      // Incorrect token, returns to .challengeRequestSuccess to re-ask to sign the challenge
                      updateProcessStep(step: .challengeRequestSuccess)
                      return
                  }

            // Ask AcademyV to associate the drone to the user.
            performAssociationRequest(with: signedChallengeToken)

        case .associationRequestSuccess:
            // Drone and user association is correctly done on Academy side,
            // Save GSDK user account.
            updateGsdkUserAccount()
        default:
            // Other cases (e.g. .notStarted), start the process
            startProcess(action: .pairUser)
        }
    }

    /// Triggers a pairing process
    ///
    ///  - Note: `CellularPairingAvailabilityService` is responsable to update the local paired list
    ///           when a drone is connected and to call this method if needed.
    func startPairingProcessRequest() {
        ULog.i(.tag, "startPairingProcessRequest")
        let startProcesses = { [unowned self] in
            Defaults.dronesListPairingProcessHidden.removeAll(where: { $0 == connectedDroneHolder.drone?.uid })
            resetProcessStates()
            retryPairingTimer?.invalidate()
            pairingAction = .pairUser
            // Listen process error changes to handle auto retry.
            listenProcessErrors()
            startProcess(action: pairingAction)
        }

        academyApiService.performPairedDroneListRequest { [unowned self] droneList in
            DispatchQueue.main.async {
                guard let droneList = droneList,
                      let jsonString = ParserUtils.jsonString(droneList),
                      let userAccount = GroundSdk().getFacility(Facilities.userAccount) else {
                          startProcesses()
                          return
                      }

                guard droneList.contains(where: { $0.serial == connectedDroneHolder.drone?.uid && $0.pairedFor4G }) else {
                    startProcesses()
                    return
                }

                userAccount.set(droneList: jsonString)
            }
        }
    }

    /// Triggers an unpair process
    func startUnpairProcessRequest() {
        ULog.i(.tag, "startUnpairProcessRequest")
        resetProcessStates()
        retryPairingTimer?.invalidate()
        pairingAction = .unpairUser
        startProcess(action: .unpairUser)
    }

    /// Updates GroundSdk user account with drone list retrieved from Academy.
    func updateGsdkUserAccount() {
        ULog.i(.tag, "updateGsdkUserAccount")
        academyApiService.performPairedDroneListRequest { droneList in
            DispatchQueue.main.async {
                guard droneList != nil,
                      let jsonString = ParserUtils.jsonString(droneList),
                      let userAccount = GroundSdk().getFacility(Facilities.userAccount) else {

                          self.updateProcessError(error: .unableToConnect)
                          return
                      }

                userAccount.set(droneList: jsonString)
                self.updateProcessStep(step: .pairingProcessSuccess)
            }
        }
    }

    func updateAnonymousDroneList(token: String) {
        ULog.i(.tag, "updateAnonymousDroneList with \(token)")
        apcAPIManager.updateGsdkUserAccount(token: token)

        if let userAccount = GroundSdk().getFacility(Facilities.userAccount) {
            userAccount.set(droneList: "")
        }

        academyApiService.performPairedDroneListRequest { droneList in
            DispatchQueue.main.async {
                guard droneList != nil,
                      let jsonString = ParserUtils.jsonString(droneList),
                      let userAccount = GroundSdk().getFacility(Facilities.userAccount) else {

                          self.updateProcessError(error: .unableToConnect)
                          return
                      }

                userAccount.set(droneList: jsonString)
                self.updateProcessStep(step: .pairingProcessSuccess)
            }
        }
    }
}

private extension CellularPairingServiceImpl {

    /// Starts the pair or unpair process
    /// - Parameter action: the process (pair or unpair)
    func startProcess(action: PairingAction) {
        ULog.i(.tag, "startProcess [\(action)]")
        guard networkService.networkIsReachable else {
            updateProcessError(error: .connectionUnreachable)
            return
        }

        // When not logged (e.i. not logged to MyParrot, and temporary account has never
        // been created during a pairing process attempt), ...
        guard isUserLogged else {
            switch action {
            case .pairUser:
                // ... create a temporary account to manage pairing process
                // with his dedicated apc token.
                createTemporaryAccount()
                return

            case .unpairUser:
                // ... there is nothing to unpair.
                return
            }
        }

        performChallengeRequest(action: action)
    }

    /// Creates a temporary account in order to pair the drone without a real MyParrot account.
    func createTemporaryAccount() {
        ULog.i(.tag, "createTemporaryAccount")
        guard networkService.networkIsReachable else {
            updateProcessError(error: .connectionUnreachable)
            return
        }

        apcAPIManager.createTemporaryAccount(completion: { (isAccountCreated, token, error) in
            DispatchQueue.main.async {
                guard error == nil,
                      isAccountCreated == true,
                      let token = token,
                      !token.isEmpty else {
                          self.updateProcessError(error: .serverError)
                          return
                      }

                self.updateProcessError(error: .noError)
                SecureKeyStorage.current.temporaryToken = token
                self.userInformation.token = token
                self.userRepo.updateTokenForAnonymousUser(token)
                self.startProcess(action: .pairUser)
            }
        })
    }

    /// Performs challenge AcademyV request.
    /// Notes: First step of the pairing process.
    /// - Parameter action: the process (pair or unpair)
    func performChallengeRequest(action: PairingAction) {
        ULog.i(.tag, "performChallengeRequest [\(action)]")
        // `academyApiService` is responsable to get the current authenticated user's apc token
        // to use to perform the challenge request.
        academyApiService.performChallengeRequest(action: action) { challenge, error in
            DispatchQueue.main.async {
                guard error == nil,
                      let challenge = challenge,
                      !challenge.isEmpty else {
                          self.updateProcessError(error: .unableToConnect)
                          return
                      }

                // Store localy the challenge to use during the next steps of the process
                self.updateChallenge(with: challenge)
                // Prepare the next step
                self.updateProcessStep(step: .challengeRequestSuccess)
                self.signChallenge(with: challenge)
            }
        }
    }

    /// Signs the challenge by the drone.
    /// Notes: Second step of the pairing process.
    ///
    /// - Parameters:
    ///     - challenge: challenge string given by Academy
    func signChallenge(with challenge: String?) {
        ULog.i(.tag, "signChallenge with challenge \(challenge ?? "")")
        guard let chalEncoded = challenge,
              let secureElement = currentDroneHolder.drone.getPeripheral(Peripherals.secureElement),
              currentDroneHolder.drone.isConnected == true else {
                  updateProcessError(error: .unableToConnect)
                  return
              }

        // Ask the drone to sign the challenge received from AcademyV.
        // The response is handled by listening `secureElement` changes
        // then processing the next steps in `updateSecureElementState`
        switch pairingAction {
        case .pairUser:
            secureElement.sign(challenge: chalEncoded, with: .associate)

        case .unpairUser:
            secureElement.sign(challenge: chalEncoded, with: .unpair_all)
        }
    }

    /// Sends given drone signature to AcademyV for 4G association.
    /// Notes: Third step of the pairing process.
    ///
    /// - Parameters:
    ///     - token: token signature given by the drone
    func performAssociationRequest(with token: String) {
        ULog.i(.tag, "performAssociationRequest with token \(token)")
        guard networkService.networkIsReachable else {
            updateProcessError(error: .connectionUnreachable)
            return
        }

        academyApiService.performAssociationRequest(token: token) { [unowned self] result in
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    // If it's an 'Error 4xx', its useless to retry continuously the same step.
                    // Restart process from the begining
                    if AcademyApiService.ApiError.error4xx(error) != nil {
                        updateProcessStep(step: .notStarted)
                    }
                    updateProcessError(error: .serverError)

                case .success:
                    updateProcessStep(step: .associationRequestSuccess)
                    addToPairedListDroneUid(self.currentDroneHolder.drone.uid)
                    updateGsdkUserAccount()
                }
            }
        }
    }

    /// Sends given drone signature to AcademyV for 4G unpairing.
    /// - Note: Third step of the unpairing process.
    ///         Unpair request asked when tapped `Forget PIN`, expect to unpair
    ///         all users associated to the drone. This process is performed in two steps:
    ///         Remove all users except the authenticated one (`unpairAllUsers`),  then
    ///         remove the authenticated user (`unpairDrone`)
    ///
    /// - Parameters:
    ///     - token: token signature given by the drone
    func performUnpairRequest(with token: String) {
        ULog.i(.tag, "performUnpairRequest with token \(token)")
        guard networkService.networkIsReachable else {
            updateProcessError(error: .connectionUnreachable)
            return
        }

        // Unpair all users except the authenticated one.
        academyApiService.unpairAllUsers(token: token) { _, error in
            // Academy calls are asynchronous update should be done on main thread
            DispatchQueue.main.async {
                guard error == nil else {
                    self.updateProcessError(error: .serverError)
                    return
                }
                // Now, drone can be unpaired from current user
                self.forgetDrone()
            }
        }
    }

    /// Updates token signature.
    ///
    /// - Parameters:
    ///     - signature: the signed token given by the drone
    func updateToken(with signature: String?) {
        ULog.i(.tag, "updateToken with signature \(signature ?? "")")
        signedChallengeToken = signature
    }

    /// Unpairs the current drone.
    func forgetDrone() {
        ULog.i(.tag, "forgetDrone")
        guard networkService.networkIsReachable else {
            updateUnpairDroneStatus(with: .noInternet(context: .details))
            return
        }

        // Get the list of paired drone.
        academyApiService.performPairedDroneListRequest { pairedDroneList in
            let uid = self.currentDroneHolder.drone.uid

            // Academy calls are asynchronous update should be done on main thread
            DispatchQueue.main.async {
                guard pairedDroneList != nil,
                      pairedDroneList?.isEmpty == false
                else {
                    self.updateUnpairDroneStatus(with: .forgetError(context: .details))
                    return
                }
            }

            pairedDroneList?
                .compactMap { $0.serial == uid ? $0.commonName : nil }
                .forEach { commonName in
                    // Unpair the drone.
                    self.academyApiService.unpairDrone(commonName: commonName) { _, error in
                        // Academy calls are asynchronous update should be done on main thread
                        DispatchQueue.main.async {
                            guard error == nil else {
                                self.updateUnpairDroneStatus(with: .forgetError(context: .details))
                                return
                            }

                            self.updateUnpairDroneStatus(with: .done)
                            self.updateCellularSubject(with: .userNotPaired)
                        }
                    }
                }
        }
    }

    /// Updates the unpair drone status.
    ///
    /// - Parameters:
    ///     - unpairState: current drone unpair state
    func updateUnpairDroneStatus(with unpairState: UnpairDroneState) {
        ULog.i(.tag, "updateUnpairDroneStatus [\(unpairState)]")
        unpairDroneStateSubject.send(unpairState)
    }

    /// Updates drones paired list by adding element after pairing process.
    ///
    /// - Parameters:
    ///     - uid: drone uid
    func addToPairedListDroneUid(_ uid: String) {
        ULog.i(.tag, "addToPairedListDroneUid \(uid)")
        var dronePairedListSet = Set(Defaults.cellularPairedDronesList)
        guard !dronePairedListSet.contains(uid) else { return }
        dronePairedListSet.insert(uid)
        Defaults.cellularPairedDronesList = Array(dronePairedListSet)
    }

    /// Reset the pairing states.
    func resetProcessStates() {
        ULog.i(.tag, "resetProcessStates")
        retryPairingTimer?.invalidate()
        pairingProcessErrorSubject.value = .noError
        pairingProcessStepSubject.value = .notStarted
        unpairDroneStateSubject.value = .notStarted
    }

    /// Listen Pairing Process Errors
    func listenProcessErrors() {
        processErrorSubscription = pairingProcessErrorPublisher
            .filter { $0 != .noError }
            .sink {  [unowned self] error in
                updatePairingProcessAutoRetryState(for: error)
            }
    }

    /// Stop listening Pairing Process Errors
    func stopListeningProcessErrors() {
        processErrorSubscription?.cancel()
    }
}

extension CellularPairingServiceImpl {

    /// Updates pairing error which could occur during the process.
    ///
    /// - Parameters:
    ///     - error: new error
    func updateProcessError(error: PairingProcessError) {
        ULog.i(.tag, "Update process error [\(error)]")
        pairingProcessErrorSubject.send(error)
    }

    /// Updates pairing state with the current process step.
    ///
    /// - Parameters:
    ///     - step: new step to update
    func updateProcessStep(step: PairingProcessStep) {
        ULog.i(.tag, "Update process step [\(step)]")
        pairingProcessStepSubject.send(step)
    }

    /// Updates challenge.
    ///
    /// - Parameters:
    ///     - challenge: the challenge string to give to the drone
    func updateChallenge(with challenge: String?) {
        ULog.i(.tag, "Update challenge with \(challenge ?? "")")
        self.challenge = challenge
    }

    /// Starts watcher for Cellular.
    func listenCellular(_ drone: Drone) {
        cellularRef = drone.getPeripheral(Peripherals.cellular) { [weak self] _ in
            self?.updateCellularState()
            self?.updateCellularStatus(drone: drone)
        }
        updateCellularState()
        updateCellularStatus(drone: drone)
    }

    /// Starts watcher for drone network control.
    func listenNetworkControl(_ drone: Drone) {
        networkControlRef = drone.getPeripheral(Peripherals.networkControl) { [weak self] _ in
            self?.updateCellularStatus(drone: drone)
        }
    }

    /// Starts watcher for Secure Element.
    func listenSecureElement(_ drone: Drone) {
        secureElementRef = drone.getPeripheral(Peripherals.secureElement) { [weak self] _ in
            self?.updateSecureElementState()
        }
        updateSecureElementState()
    }

    func updateCellularState() {
        let simLocked: Bool = currentDroneHolder.drone.getPeripheral(Peripherals.cellular)?.simStatus == .locked
        isSimLocked = simLocked
    }

    /// Drone's SecureElement state Handler
    ///
    ///  - Note:
    ///     This handler is called when state is updated after the drone tried to sign the challenge.
    func updateSecureElementState() {
        guard pairingProcessStepSubject.value == .challengeRequestSuccess
                || pairingProcessStepSubject.value == .processing else {
                    return
                }

        guard let state = connectedDroneHolder.drone?.getPeripheral(Peripherals.secureElement)?.challengeRequestState else {
            return
        }

        switch state {
        case .processing:
            // Signing is ongoing, update process state
            updateProcessStep(step: .processing)
            updateProcessError(error: .noError)

        case .success(challenge: _, token: let signedChallengeToken):
            // Challenge is sucessfully signed, save the signed challenge token for the next steps
            updateToken(with: signedChallengeToken)
            updateProcessError(error: .noError)
            updateProcessStep(step: .challengeSignSuccess)

            // Ask to AcademyV to perform pair or unpair request
            switch pairingAction {
            case .pairUser:
                performAssociationRequest(with: signedChallengeToken)
            case .unpairUser:
                performUnpairRequest(with: signedChallengeToken)
            }

        case .failure:
            ULog.i(.tag, "faillure update secure element")
            updateProcessError(error: .unableToConnect)
        }
    }

    /// Updates cellular state.
    func updateCellularStatus(drone: Drone) {
        var status: DetailsCellularStatus = .noState
        var operatorName = ""

        guard let cellular = drone.getPeripheral(Peripherals.cellular),
              drone.isConnected == true else {
                  updateCellularSubject(with: status)
                  return
              }

        // Update the current cellular state.
        let networkControl = drone.getPeripheral(Peripherals.networkControl)
        let cellularLink = networkControl?.links.first(where: { $0.type == .cellular })
        let isDronePaired: Bool = drone.isAlreadyPaired == true

        if cellularLink?.status == .running,
           isDronePaired {
            status = .cellularConnected
            operatorName = cellular.operator
        } else if cellular.mode.value == .nodata {
            status = .noData
        } else if cellular.simStatus == .absent {
            status = .simNotDetected
        } else if cellular.simStatus == .unknown {
            status = .simNotRecognized
        } else if cellular.simStatus == .initializing {
            status = .initializing
        } else if cellular.simStatus == .locked {
            if cellular.pinRemainingTries == 0 {
                status = .simBlocked
            } else {
                status = .simLocked
            }
        } else if cellularLink?.status == .error || cellularLink?.error != nil {
            status = .connectionFailed
        } else if cellular.modemStatus != .online {
            status = .modemStatusOff
        } else if cellular.registrationStatus == .notRegistered {
            status = .notRegistered
        } else if cellular.networkStatus == .error {
            status = .networkStatusError
        } else if cellular.networkStatus == .denied {
            status = .networkStatusDenied
        } else if cellular.isAvailable {
            status = .cellularConnecting
            operatorName = cellular.operator
        } else if !isDronePaired {
            status = .userNotPaired
        } else {
            status = .noState
        }

        updateCellularSubject(with: status)
        updateOperatorName(operatorName: operatorName)
    }

    /// Updates cellular status.
    ///
    /// - Parameters:
    ///     - cellularStatus: 4G status to update
    func updateCellularSubject(with cellularStatus: DetailsCellularStatus) {
        cellularStatusSubject.send(cellularStatus)
    }

    /// Updates operator name.
    ///
    /// - Parameters:
    ///     - operatorName: name of the operator
    func updateOperatorName(operatorName: String) {
        operatorNameSubject.send(operatorName)
    }
}

// MARK: - Handling Pairing Process Retries
extension CellularPairingServiceImpl {

    /// Updates Pairing Process auto retry state.
    ///
    /// - Parameters:
    ///     - error: new error
    func updatePairingProcessAutoRetryState(for error: PairingProcessError?) {
        // Be sure there is an error
        guard let error = error, error != .noError else { return }

        // Ensure current pairing process is not already done
        guard pairingAction == .pairUser,
              pairingProcessStepSubject.value != .pairingProcessSuccess else { return }

        ULog.i(.tag, "[\(pairingAction)] Schedule (in \(Constants.uploadRetrySlotTime) sec) auto-retry for error: \(error)")

        // Configure the auto retry timer
        retryPairingTimer?.invalidate()
        isWaitingPairingAutoRetry = true
        retryPairingTimer = Timer.scheduledTimer(withTimeInterval: Constants.uploadRetrySlotTime, repeats: false) { [unowned self] _ in
            isWaitingPairingAutoRetry = false
            retryPairingProcess()
        }
    }
}

extension CellularPairingServiceImpl {

    var pairingProcessErrorPublisher: AnyPublisher<PairingProcessError?, Never> { pairingProcessErrorSubject.eraseToAnyPublisher() }
    var pairingProcessStepPublisher: AnyPublisher<PairingProcessStep?, Never> { pairingProcessStepSubject.eraseToAnyPublisher() }
    var operatorNamePublisher: AnyPublisher<String?, Never> { operatorNameSubject.eraseToAnyPublisher() }
    var cellularStatusPublisher: AnyPublisher<DetailsCellularStatus, Never> { cellularStatusSubject.eraseToAnyPublisher() }
    var unpairDroneStatePublisher: AnyPublisher<UnpairDroneState, Never> { unpairDroneStateSubject.eraseToAnyPublisher() }

    var isWaitingAutoRetry: Bool { isWaitingPairingAutoRetry }
}
