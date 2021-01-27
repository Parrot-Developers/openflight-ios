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

/// State for `HorizonCorrectionViewModel`.
final class HorizonCorrectionState: DeviceConnectionState {
    // MARK: - Internal Properties
    fileprivate(set) var flyingState: FlyingIndicatorsState?
    fileprivate(set) var offsetCorrectionProcess: GimbalOffsetsCorrectionProcess?

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - connectionState: connection state of the drone.
    ///    - flyingState: flying state of the drone.
    ///    - offsetCorrectionProcess: Correction gimbal offset.
    init(connectionState: DeviceState.ConnectionState,
         flyingState: FlyingIndicatorsState?,
         offsetCorrectionProcess: GimbalOffsetsCorrectionProcess?) {
        super.init(connectionState: connectionState)

        self.flyingState = flyingState
        self.offsetCorrectionProcess = offsetCorrectionProcess
    }

    // MARK: - Internal Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? HorizonCorrectionState else { return false }

        return super.isEqual(to: other)
            && self.flyingState == other.flyingState
            && self.offsetCorrectionProcess == other.offsetCorrectionProcess
    }

    /// Returns a copy of the object.
    override func copy() -> HorizonCorrectionState {
        let copy = HorizonCorrectionState(connectionState: connectionState,
                                          flyingState: self.flyingState,
                                          offsetCorrectionProcess: self.offsetCorrectionProcess)
        return copy
    }
}

/// ViewModel for horizon correction.
final class HorizonCorrectionViewModel: DroneStateViewModel<HorizonCorrectionState> {
    // MARK: - Private Properties
    private var gimbalRef: Ref<Gimbal>?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?

    // MARK: - Deinit
    deinit {
        self.gimbalRef = nil
        self.flyingIndicatorsRef = nil
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)

        self.listenGimbal(for: drone)
        self.listenFlyingIndicators(for: drone)
    }
}

// MARK: - Internal Funcs
extension HorizonCorrectionViewModel {
    /// Start horizon correction.
    func startCalibration() {
        self.drone?.getPeripheral(Peripherals.gimbal)?.startOffsetsCorrectionProcess()
    }

    /// Stop horizon correction.
    func cancelCalibration() {
        self.drone?.getPeripheral(Peripherals.gimbal)?.stopOffsetsCorrectionProcess()
    }
}

// MARK: - Private Funcs
private extension HorizonCorrectionViewModel {
    /// Listen the drone gimbal.
    func listenGimbal(for drone: Drone) {
        gimbalRef = drone.getPeripheral(Peripherals.gimbal) { [weak self] _ in
            self?.updateOffsetCorrectionProcess()
        }
    }

    /// Listen the drone flying indicators.
    func listenFlyingIndicators(for drone: Drone) {
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [weak self] flyingIndicators in
            guard let flyingState = flyingIndicators?.state else { return }

            let copy = self?.state.value.copy()
            copy?.flyingState = flyingState
            self?.state.set(copy)
        }
    }

    /// Updates gimbal's offset correction process.
    func updateOffsetCorrectionProcess() {
        guard let drone = drone,
              let gimbal = drone.getPeripheral(Peripherals.gimbal) else {
            return
        }

        let copy = self.state.value.copy()
        copy.offsetCorrectionProcess = gimbal.offsetsCorrectionProcess
        self.state.set(copy)
    }
}
