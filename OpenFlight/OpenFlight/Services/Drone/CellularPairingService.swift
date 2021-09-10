//
//  Copyright (C) 2021 Parrot Drones SAS.
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
import Reachability
import SwiftyUserDefaults

public protocol CellularPairingService: AnyObject {

    func retryPairingProcess()
    func listenPairingProcessRequest()
    func startUnpairProcessRequest()

    var pairingProcessErrorPublisher: AnyPublisher<PairingProcessError?, Never> { get }
    var pairingProcessStepPublisher: AnyPublisher<PairingProcessStep?, Never> { get }
    var operatorNamePublisher: AnyPublisher<String?, Never> { get }
    var cellularStatusPublisher: AnyPublisher<DetailsCellularStatus, Never> { get }
    var unpairStatePublisher: AnyPublisher<UnpairDroneState, Never> { get }
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
    var unpairStateSubject = CurrentValueSubject<UnpairDroneState, Never>(.notStarted)

    // MARK: - Private Properties
    private var cellularRef: Ref<Cellular>?
    private var secureElementRef: Ref<SecureElement>?
    private var networkControlRef: Ref<NetworkControl>?
    private var reachability: Reachability?
    private var academyApiService: AcademyApiService
    private var apcAPIManager = APCApiManager()
    private var pairingRequestObserver: Any?
    private var isUserLogged: Bool = Defaults.isUserConnected
        || SecureKeyStorage.current.isTemporaryAccountCreated
    private var token: String?
    private var challenge: String?
    private var isSimLocked: Bool = true
    private var cancellables = Set<AnyCancellable>()
    private let currentDroneHolder: CurrentDroneHolder
    private let connectedDroneHolder: ConnectedDroneHolder
    private let userRepo: UserRepository
    private var pairingAction: PairingAction = .pairUser
    private var unpairState: UnpairDroneState = .notStarted

    init(currentDroneHolder: CurrentDroneHolder, userRepo: UserRepository, connectedDroneHolder: ConnectedDroneHolder, academyApiService: AcademyApiService) {
        self.currentDroneHolder = currentDroneHolder
        self.userRepo = userRepo
        self.connectedDroneHolder = connectedDroneHolder
        self.academyApiService = academyApiService
        listenReachability()
        listenPairingProcessRequest()

        currentDroneHolder.dronePublisher
            .sink { [unowned self] drone in
                listenSecureElement(drone)
            }
            .store(in: &cancellables)

        connectedDroneHolder.dronePublisher
            .compactMap { $0 }
            .sink { [unowned self] drone in
                listenCellular(drone)
                listenNetworkControl(drone)
            }
            .store(in: &cancellables)
    }
}

extension CellularPairingServiceImpl {

    /// Retry pairing process if there is an error.
    func retryPairingProcess() {
        pairingAction = .pairUser

        updateProcessError(error: .noError)

        guard isUserLogged else {
            startProcess(action: .pairUser)
            return
        }

        switch pairingProcessStepSubject.value {
        case .challengeRequestSuccess, .processing:
            guard challenge != nil else {
                updateProcessError(error: .unableToConnect)
                return
            }

            signChallenge(with: challenge)

        case .challengeSignSuccess:
            guard let token = token, !token.isEmpty else {
                updateProcessError(error: .unableToConnect)
                return
            }

            performAssociationRequest(with: token)

        case .associationRequestSuccess:
            updateGsdkUserAccount()
        default:
            startProcess(action: .pairUser)
        }
    }

    // TODO: Remove notification and integrate in the coordinator
    /// Observes notification on pairing process request.
    func listenPairingProcessRequest() {
        pairingRequestObserver = NotificationCenter.default.addObserver(forName: .requestCellularPairingProcess,
                                                                        object: nil,
                                                                        queue: nil) { [weak self] _ in
            self?.pairingAction = .pairUser
            self?.updateLoggingState()
            self?.startProcess(action: .pairUser)
        }
    }

    /// Triggers an unpair process
    func startUnpairProcessRequest() {
        pairingAction = .unpairUser
        updateLoggingState()
        startProcess(action: .unpairUser)
    }

}

private extension CellularPairingServiceImpl {

    /// Starts the pair or unpair process
    /// - Parameter action: the process (pair or unpair)
    func startProcess(action: PairingAction) {
        guard reachability?.isConnected == true else {
            updateProcessError(error: .connectionUnreachable)
            return
        }

        guard isUserLogged else {
            switch action {
            case .pairUser:
                createTemporaryAccount()
                return

            case .unpairUser:
                return
            }
        }

        performChallengeRequest(action: action)
    }

    /// Creates a temporary account in order to pair the drone without a real MyParrot account.
    func createTemporaryAccount() {
        guard reachability?.isConnected == true else {
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
                self.userRepo.updateTokenForAnonymousUser(token)
                self.updateLoggingState()
                self.startProcess(action: .pairUser)
            }
        })
    }

    /// Observes network reachability.
    func listenReachability() {
        do {
            try reachability = Reachability()
            try reachability?.startNotifier()
        } catch {
            updateProcessError(error: .connectionUnreachable)
        }

        reachability?.whenUnreachable = { [weak self] _ in
            self?.updateProcessError(error: .connectionUnreachable)
        }
    }

    /// Performs challenge AcademyV request.
    /// Notes: First step of the pairing process.
    /// - Parameter action: the process (pair or unpair)
    func performChallengeRequest(action: PairingAction) {

        academyApiService.performChallengeRequest(action: action) { challenge, error in
            DispatchQueue.main.async {
                guard error == nil,
                      let challenge = challenge,
                      !challenge.isEmpty else {
                    self.updateProcessError(error: .unableToConnect)
                    return
                }

                self.updateChallenge(with: challenge)
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
        guard let chalEncoded = challenge,
              let secureElement = currentDroneHolder.drone.getPeripheral(Peripherals.secureElement),
              currentDroneHolder.drone.isConnected == true else {

            updateProcessError(error: .unableToConnect)
            return
        }

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
        guard reachability?.isConnected == true else {
            updateProcessError(error: .connectionUnreachable)
            return
        }

        academyApiService.performAssociationRequest(token: token) { isCompleted in
            DispatchQueue.main.async {
                guard isCompleted else {
                    self.updateProcessError(error: .unableToConnect)
                    return
                }

                self.updateProcessStep(step: .associationRequestSuccess)

                let uid = self.currentDroneHolder.drone.uid

                var dronePairedListSet = Set(Defaults.cellularPairedDronesList)
                dronePairedListSet.insert(uid)
                Defaults.cellularPairedDronesList = Array(dronePairedListSet)

                self.updateGsdkUserAccount()
            }
        }
    }

    /// Sends given drone signature to AcademyV for 4G unpairing.
    /// Notes: Third step of the unpairing process.
    ///
    /// - Parameters:
    ///     - token: token signature given by the drone
    func performUnpairRequest(with token: String) {
        guard reachability?.isConnected == true else {
            updateProcessError(error: .connectionUnreachable)
            return
        }

        academyApiService.unpairAllUsers(token: token) { _, error in
            // Academy calls are asynchronous update should be done on main thread
            DispatchQueue.main.async {
                guard error == nil else {
                    self.updateProcessError(error: .serverError)
                    return
                }
                self.forgetDrone()
            }
        }
    }

    /// Updates GroundSdk user account with drone list retrieved from Academy.
    func updateGsdkUserAccount() {
        academyApiService.performPairedDroneListRequest { droneList in
            DispatchQueue.main.async {
                guard droneList != nil,
                      let jsonString = ParserUtils.jsonString(droneList),
                      let userAccount = GroundSdk().getFacility(Facilities.userAccount) else {

                    self.updateProcessError(error: .unableToConnect)
                    return
                }

                self.updateProcessStep(step: .pairingProcessSuccess)
                userAccount.set(droneList: jsonString)
            }
        }
    }

    /// Updates token signature.
    ///
    /// - Parameters:
    ///     - signature: the signed token given by the drone
    func updateToken(with signature: String?) {
        token = signature
    }

    /// Updates user login state.
    func updateLoggingState() {
        isUserLogged = Defaults.isUserConnected
            || SecureKeyStorage.current.isTemporaryAccountCreated
    }

    /// Unpairs the current drone.
    func forgetDrone() {
        let reachability = try? Reachability()
        guard reachability?.isConnected == true else {
            updateResetStatus(with: .noInternet(context: .details))
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
                    self.updateResetStatus(with: .forgetError(context: .details))
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
                                self.updateResetStatus(with: .forgetError(context: .details))
                                return
                            }

                            self.updateResetStatus(with: .done)
                            self.removeFromPairedList(with: uid)
                            self.resetPairingDroneListIfNeeded()
                            self.updateCellularSubject(with: .userNotPaired)
                        }
                    }
                }
        }
    }

    /// Updates the reset status.
    ///
    /// - Parameters:
    ///     - unpairState: current drone unpair state
    func updateResetStatus(with unpairState: UnpairDroneState) {
        unpairStateSubject.send(unpairState)
    }

    /// Updates drones paired list by removing element after unpairing process.
    ///
    /// - Parameters:
    ///     - uid: drone uid
    func removeFromPairedList(with uid: String) {
        var dronePairedListSet = Set(Defaults.cellularPairedDronesList)
        dronePairedListSet.remove(uid)
        Defaults.cellularPairedDronesList = Array(dronePairedListSet)
    }

    /// Removes current drone uid in the dismissed pairing list.
    /// The pairing process for the current drone could be displayed again in the HUD.
    func resetPairingDroneListIfNeeded() {
        let uid = currentDroneHolder.drone.uid
        guard Defaults.dronesListPairingProcessHidden.contains(uid),
              currentDroneHolder.drone.isAlreadyPaired == false else {
            return
        }

        Defaults.dronesListPairingProcessHidden.removeAll(where: { $0 == uid })
    }

}

extension CellularPairingServiceImpl {

    /// Updates pairing error which could occur during the process.
    ///
    /// - Parameters:
    ///     - error: new error
    func updateProcessError(error: PairingProcessError) {
        pairingProcessErrorSubject.send(error)
    }

    /// Updates pairing state with the current process step.
    ///
    /// - Parameters:
    ///     - step: new step to update
    func updateProcessStep(step: PairingProcessStep) {
        pairingProcessStepSubject.send(step)
    }

    /// Updates challenge.
    ///
    /// - Parameters:
    ///     - challenge: the challenge string to give to the drone
    func updateChallenge(with challenge: String?) {
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

    func updateSecureElementState() {
        guard pairingProcessStepSubject.value == .challengeRequestSuccess
                || pairingProcessStepSubject.value == .processing else {
            return
        }

        let state = currentDroneHolder.drone.getPeripheral(Peripherals.secureElement)?.challengeRequestState

        switch state {
        case .processing:
            updateProcessStep(step: .processing)
            updateProcessError(error: .noError)
        case .success(challenge: _, token: let token):
            updateToken(with: token)
            updateProcessError(error: .noError)
            updateProcessStep(step: .challengeSignSuccess)

            switch pairingAction {
            case .pairUser:
                performAssociationRequest(with: token)
            case .unpairUser:
                performUnpairRequest(with: token)
            }

        default:
            updateProcessError(error: .unableToConnect)
        }
    }

    /// Updates cellular state.
    func updateCellularStatus(drone: Drone) {
        var status: DetailsCellularStatus = .noState

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
        } else if cellular.mode.value == .nodata {
            status = .noData
        } else if cellular.simStatus == .absent {
            status = .simNotDetected
        } else if cellular.simStatus == .unknown {
            status = .simNotRecognized
        } else if cellular.simStatus == .locked {
            if cellular.pinRemainingTries == 0 {
                status = .simBlocked
            } else {
                status = .simLocked
            }
        } else if !isDronePaired {
            status = .userNotPaired
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
        } else {
            status = .noState
        }

        updateCellularSubject(with: status)
        updateOperatorName(operatorName: cellular.operator)
    }

    /// Updates cellular status.
    ///
    /// - Parameters:
    ///     - cellularStatus: 4G status to update
    func updateCellularSubject(with cellularStatus: DetailsCellularStatus) {
        self.cellularStatusSubject.send(cellularStatus)
    }

    /// Updates operator name.
    ///
    /// - Parameters:
    ///     - operatorName: name of the operator
    func updateOperatorName(operatorName: String) {
        self.operatorNameSubject.send(operatorName)
    }
}

extension CellularPairingServiceImpl {

    var pairingProcessErrorPublisher: AnyPublisher<PairingProcessError?, Never> { pairingProcessErrorSubject.eraseToAnyPublisher() }
    var pairingProcessStepPublisher: AnyPublisher<PairingProcessStep?, Never> { pairingProcessStepSubject.eraseToAnyPublisher() }
    var operatorNamePublisher: AnyPublisher<String?, Never> { operatorNameSubject.eraseToAnyPublisher() }
    var cellularStatusPublisher: AnyPublisher<DetailsCellularStatus, Never> { cellularStatusSubject.eraseToAnyPublisher() }
    var unpairStatePublisher: AnyPublisher<UnpairDroneState, Never> { unpairStateSubject.eraseToAnyPublisher() }
}
