//
//  Copyright (C) 2020 Parrot Drones SAS.
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

import GroundSdk
import Reachability
import SwiftyUserDefaults

/// State for `CellularPairingProcessViewModel`.
final class CellularPairingProcessState: ViewModelState, EquatableState, Copying {
    // MARK: - Internal Properties
    /// Current pairing process step. There are three steps ordered.
    /// Challenge request, sign challenge to the drone to get signature token and assaocitation request.
    fileprivate(set) var pairingProcessStep: PairingProcessStep?
    /// Current pairing error.
    fileprivate(set) var pairingProcessError: PairingProcessError?
    /// Tells if sim is locked.
    fileprivate(set) var isSimLocked: Bool = true
    /// Challenge given in the first step.
    fileprivate(set) var challenge: String?
    /// Signature token given by the drone.
    fileprivate(set) var token: String?
    /// Tells if user is logged.
    fileprivate(set) var isUserLogged: Bool = Defaults.isUserConnected
        || SecureKeyStorage.current.isTemporaryAccountCreated

    // MARK: - Init
    required init() { }

    /// Init.
    ///
    /// - Parameters:
    ///    - pairingProcessStep: current pairing process state
    ///    - pairingProcessError: current error
    ///    - isSimLocked: tells if sim is locked
    ///    - challenge: challenge string
    ///    - token: token signature
    ///    - isUserLogged: tells if user is logged
    init(pairingProcessStep: PairingProcessStep?,
         pairingProcessError: PairingProcessError?,
         isSimLocked: Bool,
         challenge: String?,
         token: String?,
         isUserLogged: Bool) {
        self.pairingProcessStep = pairingProcessStep
        self.pairingProcessError = pairingProcessError
        self.isSimLocked = isSimLocked
        self.challenge = challenge
        self.token = token
        self.isUserLogged = isUserLogged
    }

    // MARK: - Internal Funcs
    func isEqual(to other: CellularPairingProcessState) -> Bool {
        return self.pairingProcessStep == other.pairingProcessStep
            && self.pairingProcessError == other.pairingProcessError
            && self.isSimLocked == other.isSimLocked
            && self.challenge == other.challenge
            && self.token == other.token
            && self.isUserLogged == other.isUserLogged
    }

    /// Returns a copy of the object.
    func copy() -> CellularPairingProcessState {
        return CellularPairingProcessState(pairingProcessStep: pairingProcessStep,
                                           pairingProcessError: pairingProcessError,
                                           isSimLocked: isSimLocked,
                                           challenge: challenge,
                                           token: token,
                                           isUserLogged: isUserLogged)
    }
}

/// Describes and manages current drone pairing configuration.
final class CellularPairingProcessViewModel: DroneWatcherViewModel<CellularPairingProcessState> {
    // MARK: - Internal Properties
    /// Returns true if a pin code is needed.
    var isPinCodeRequested: Bool {
        return drone?.getPeripheral(Peripherals.cellular)?.isPinCodeRequested == true
    }

    // MARK: - Private Properties
    private var cellularRef: Ref<Cellular>?
    private var secureElementRef: Ref<SecureElement>?
    private var reachability: Reachability?
    private var academyAPIManager = AcademyApiManager()
    private var apcAPIManager = APCApiManager()
    private var pairingRequestObserver: Any?

    // MARK: - Init
    override init() {
        super.init()

        listenReachability()
        updateLoggingState()
        listenPairingProcessRequest()
    }

    // MARK: - Deinit
    deinit {
        cellularRef = nil
        secureElementRef = nil
        pairingRequestObserver = nil
        NotificationCenter.default.remove(observer: pairingRequestObserver)
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        listenCellular(drone)
        listenSecureElement(drone)
    }

    // MARK: - Internal Funcs
    /// Retry pairing process if there is an error.
    func retryPairingProcess() {
        updateProcessError(error: .noError)

        guard state.value.isUserLogged else {
            startPairingProcess()
            return
        }

        switch state.value.pairingProcessStep {
        case .challengeRequestSuccess,
             .processing:
            guard state.value.challenge != nil else {
                updateProcessError(error: .unableToConnect)
                return
            }

            signChallenge(with: state.value.challenge)
        case .challengeSignSuccess:
            guard let token = state.value.token,
                  !token.isEmpty else {
                updateProcessError(error: .unableToConnect)
                return
            }

            performAssociationRequest(with: token)
        default:
            startPairingProcess()
        }
    }
}

// MARK: - Private Funcs
private extension CellularPairingProcessViewModel {
    /// Observes notification on pairing process request.
    func listenPairingProcessRequest() {
        pairingRequestObserver = NotificationCenter.default.addObserver(forName: .requestCellularPairingProcess,
                                                                        object: nil,
                                                                        queue: nil) { [weak self] _ in
            self?.startPairingProcess()
        }
    }

    /// Starts the entire pairing process.
    func startPairingProcess() {
        guard reachability?.isConnected == true else {
            updateProcessError(error: .connectionUnreachable)
            return
        }

        guard state.value.isUserLogged else {
            createTemporaryAccount()
            return
        }

        performChallengeRequest()
    }

    /// Creates a temporary account in order to pair the drone without a real MyParrot account.
    func createTemporaryAccount() {
        guard reachability?.isConnected == true else {
            updateProcessError(error: .connectionUnreachable)
            return
        }

        apcAPIManager.createTemporaryAccount(completion: { (isAccountCreated, token, error) in
            guard error == nil,
                  isAccountCreated == true,
                  let token = token,
                  !token.isEmpty else {
                self.updateProcessError(error: .serverError)
                return
            }

            self.updateProcessError(error: .noError)
            SecureKeyStorage.current.temporaryToken = token
            self.updateLoggingState()
            self.startPairingProcess()
        })
    }

    /// Starts watcher for Cellular.
    func listenCellular(_ drone: Drone) {
        cellularRef = drone.getPeripheral(Peripherals.cellular) { [weak self] _ in
            self?.updateCellularState()
        }
        updateCellularState()
    }

    /// Starts watcher for Secure Element.
    func listenSecureElement(_ drone: Drone) {
        secureElementRef = drone.getPeripheral(Peripherals.secureElement) { [weak self] _ in
            self?.updateSecureElementState()
        }
        updateSecureElementState()
    }

    /// Performs challenge AcademyV request.
    /// Notes: First step of the pairing process.
    func performChallengeRequest() {
        academyAPIManager.performChallengeRequest { challenge, error in
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

    /// Signs the challenge by the drone.
    /// Notes: Second step of the pairing process.
    ///
    /// - Parameters:
    ///     - challenge: challenge string given by Academy
    func signChallenge(with challenge: String?) {
        guard let chalEncoded = challenge,
              let secureElement = drone?.getPeripheral(Peripherals.secureElement),
              drone?.isConnected == true else {
            updateProcessError(error: .unableToConnect)
            return
        }

        secureElement.sign(challenge: chalEncoded, with: .associate)
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

        academyAPIManager.performAssociationRequest(token: token) { isCompleted in
            guard isCompleted else {
                self.updateProcessError(error: .unableToConnect)
                return
            }

            self.updateProcessStep(step: .pairingProcessSuccess)

            guard let uid = self.drone?.uid else { return }

            var dronePairedListSet = Set(Defaults.cellularPairedDronesList)
            dronePairedListSet.insert(uid)
            Defaults.cellularPairedDronesList = Array(dronePairedListSet)
        }
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

    /// Updates cellular sim status.
    func updateCellularState() {
        let isSimLocked: Bool = drone?.getPeripheral(Peripherals.cellular)?.simStatus == .locked
        let copy = state.value.copy()
        copy.isSimLocked = isSimLocked
        state.set(copy)
    }

    /// Updates secure element state.
    func updateSecureElementState() {
        guard state.value.pairingProcessStep == .challengeRequestSuccess
                || state.value.pairingProcessStep == .processing else {
            return
        }

        let state = drone?.getPeripheral(Peripherals.secureElement)?.challengeRequestState

        switch state {
        case .processing:
            updateProcessStep(step: .processing)
            updateProcessError(error: .noError)
        case .success(challenge: _, token: let token):
            updateToken(with: token)
            updateProcessError(error: .noError)
            updateProcessStep(step: .challengeSignSuccess)
            performAssociationRequest(with: token)
        default:
            updateProcessError(error: .unableToConnect)
        }
    }

    /// Updates pairing state with the current process step.
    ///
    /// - Parameters:
    ///     - step: new step to update
    func updateProcessStep(step: PairingProcessStep) {
        let copy = state.value.copy()
        copy.pairingProcessStep = step
        state.set(copy)
    }

    /// Updates pairing error which could occur during the process.
    ///
    /// - Parameters:
    ///     - error: new error
    func updateProcessError(error: PairingProcessError) {
        let copy = state.value.copy()
        copy.pairingProcessError = error
        state.set(copy)
    }

    /// Updates challenge.
    ///
    /// - Parameters:
    ///     - challenge: the challenge string to give to the drone
    func updateChallenge(with challenge: String?) {
        let copy = state.value.copy()
        copy.challenge = challenge
        state.set(copy)
    }

    /// Updates token signature.
    ///
    /// - Parameters:
    ///     - signature: the signed token given by the drone
    func updateToken(with signature: String?) {
        let copy = state.value.copy()
        copy.token = signature
        state.set(copy)
    }

    /// Updates user login state.
    func updateLoggingState() {
        let copy = state.value.copy()
        copy.isUserLogged = Defaults.isUserConnected
            || SecureKeyStorage.current.isTemporaryAccountCreated
        state.set(copy)
    }
}
