//    Copyright (C) 2020 Parrot Drones SAS
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

// MARK: - Protocol
/// Protocol for navigation of the horizon correction.
protocol HorizonCorrectionCoordinator: AnyObject {

    /// The calibration did stop.
    func calibrationDidStop()
}

/// ViewModel for horizon correction.
final class HorizonCorrectionViewModel {
    // MARK: - Private Properties
    /// Current gimbal offset correction process
    @Published private(set) var offsetsCorrectionProcess: GimbalOffsetsCorrectionProcess?

    private var gimbalRef: Ref<Gimbal>?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?
    private var cancellables = Set<AnyCancellable>()
    private weak var coordinator: HorizonCorrectionCoordinator?

    // MARK: - Init
    init(coordinator: HorizonCorrectionCoordinator, droneHolder: ConnectedDroneHolder) {
        self.coordinator = coordinator
        bind(droneHolder: droneHolder)
    }

    func bind(droneHolder: ConnectedDroneHolder) {
        droneHolder.dronePublisher
            .removeDuplicates()
            .sink { [unowned self] drone in
                guard let drone = drone else {
                    stopCalibration()
                    return
                }
                self.listenGimbal(drone)
                self.listenFlyingIndicators(drone)
            }
            .store(in: &cancellables)
    }

    func userDidTapBack() {
        stopCalibration()
    }
}

// MARK: - Private Funcs
private extension HorizonCorrectionViewModel {
    /// Starts calibration
    func startCalibration() {
        gimbalRef?.value?.startOffsetsCorrectionProcess()
    }

    /// Stops calibration
    func stopCalibration() {
        gimbalRef?.value?.stopOffsetsCorrectionProcess()
        coordinator?.calibrationDidStop()
    }

    /// Listens the drone gimbal.
    func listenGimbal(_ drone: Drone) {
        gimbalRef = drone.getPeripheral(Peripherals.gimbal) { [weak self] gimbal in
            self?.offsetsCorrectionProcess = gimbal?.offsetsCorrectionProcess
        }
    }

    /// Listens the drone flying indicators.
    func listenFlyingIndicators(_ drone: Drone) {
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [unowned self] flyingIndicators in
            if flyingIndicators?.state != .flying {
                startCalibration()
            } else {
                stopCalibration()
            }
        }
    }
}
