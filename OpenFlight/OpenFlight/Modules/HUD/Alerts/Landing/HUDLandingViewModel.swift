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

/// State for `HUDLandingViewModel`.
final class HUDLandingState: DeviceConnectionState {
    // MARK: - Internal Properties
    /// Tells if the drone is returning home.
    var isReturnHomeActive: Bool = false
    /// Tells if the drone is landing.
    var isLanding: Bool = false
    /// Is landing.
    var isLandingOrRth: Bool {
        return isReturnHomeActive || isLanding
    }
    var image: UIImage? {
        if isReturnHomeActive {
            return Asset.Alertes.Rth.icRthHUD.image
        } else if isLanding {
            return Asset.Common.Icons.landing.image
        } else {
            return nil
        }
    }

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - connectionState: device connection state
    ///    - isReturnHomeActive: tells if drone is returning to home
    ///    - isLanding: tells if drone is landing
    init(connectionState: DeviceState.ConnectionState,
         isReturnHomeActive: Bool,
         isManualLanding: Bool) {
        super.init(connectionState: connectionState)

        self.isReturnHomeActive = isReturnHomeActive
        self.isLanding = isManualLanding
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? HUDLandingState else { return false }

        return super.isEqual(to: other)
            && self.isReturnHomeActive == other.isReturnHomeActive
            && self.isLanding == other.isLanding
    }

    override func copy() -> HUDLandingState {
        return HUDLandingState(connectionState: connectionState,
                               isReturnHomeActive: isReturnHomeActive,
                               isManualLanding: isLanding)
    }
}

/// View model which observes landing state.
final class HUDLandingViewModel: DroneStateViewModel<HUDLandingState> {
    // MARK: - Private Properties
    private var returnHomeRef: Ref<ReturnHomePilotingItf>?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?

    // MARK: - Deinit
    deinit {
        returnHomeRef = nil
        flyingIndicatorsRef = nil
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)

        listenReturnHome(drone: drone)
        listenFlyingIndicators(drone: drone)
    }
}

// MARK: - Private Funcs
private extension HUDLandingViewModel {
    /// Starts watcher for flying indicators.
    func listenFlyingIndicators(drone: Drone) {
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [weak self] _ in
            self?.updateLandingState()
        }
        updateLandingState()
    }

    /// Starts watcher for Return Home.
    func listenReturnHome(drone: Drone) {
        returnHomeRef = drone.getPilotingItf(PilotingItfs.returnHome) { [weak self] _ in
            self?.updateReturnHomeState()
        }
        updateReturnHomeState()
    }

    /// Updates return home state.
    func updateReturnHomeState() {
        let copy = state.value.copy()
        copy.isReturnHomeActive = drone?.isReturningHome == true
        state.set(copy)
    }

    /// Updates landing state.
    func updateLandingState() {
        let copy = state.value.copy()
        copy.isLanding = drone?.isLanding == true
        state.set(copy)
    }
}
