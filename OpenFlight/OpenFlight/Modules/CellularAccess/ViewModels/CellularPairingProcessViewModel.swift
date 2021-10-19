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
import Combine

/// Describes and manages current drone pairing configuration.
final class CellularPairingProcessViewModel {
    // MARK: - Internal Properties

    private weak var coordinator: HUDCoordinator?
    private var pairingService = Services.hub.drone.cellularPairingService
    private var currentDrone = Services.hub.currentDroneHolder
    private var connectedDrone = Services.hub.connectedDroneHolder
    private var cancellables = Set<AnyCancellable>()

    /// Returns true if a pin code is needed.
    @Published private(set) var isPinCodeRequested: Bool = false
    @Published private(set) var pairingStep: PairingProcessStep?
    @Published private(set) var pairingError: PairingProcessError?

    func pinCodeRequested(drone: Drone?) {
        let droneCellular = drone?.getPeripheral(Peripherals.cellular)

        if droneCellular?.isSimCardInserted == false
            || droneCellular?.isActivated == false
            || (droneCellular?.simStatus == .locked && droneCellular?.pinRemainingTries == 0) {
            isPinCodeRequested = false
        } else {
            isPinCodeRequested = droneCellular?.isPinCodeRequested == true
        }
    }

    // MARK: - Init
    init() {
        connectedDrone.dronePublisher
            .sink { [unowned self] drone in
                pinCodeRequested(drone: drone)
            }
            .store(in: &cancellables)

        pairingService.pairingProcessStepPublisher
            .sink { [unowned self] pairingProcessStep in
                pairingStep = pairingProcessStep
            }
            .store(in: &cancellables)

        pairingService.pairingProcessErrorPublisher
            .sink { [unowned self] pairingProcessError in
                pairingError = pairingProcessError
            }
            .store(in: &cancellables)
    }

    // MARK: - Funcs
    /// Retry pairing process if there is an error.
    func retryPairingProcess() {
        pairingService.retryPairingProcess()
    }

    /// Start pairing process.
    func startPairingProcess() {
        pairingService.startPairingProcessRequest()
    }
}
