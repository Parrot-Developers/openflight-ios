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

/// State for `SettingsRthActionViewModel`.
final class SettingsRthActionState: DeviceConnectionState {
    // MARK: - Internal Properties
    fileprivate(set) var altitude: Double = RthPreset.defaultAltitude
    fileprivate(set) var maxAltitude: Double = RthPreset.maxAltitude
    fileprivate(set) var minAltitude: Double = RthPreset.minAltitude

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Inits.
    ///
    /// - Parameters:
    ///     - connectionState: drone connection state
    ///     - altitude: rth altitude
    ///     - maxAltitude: rth max altitude
    ///     - minAltitude: rth min altitude
    init(connectionState: DeviceState.ConnectionState,
         altitude: Double,
         maxAltitude: Double,
         minAltitude: Double) {
        super.init(connectionState: connectionState)

        self.altitude = altitude
        self.maxAltitude = maxAltitude
        self.minAltitude = minAltitude
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? SettingsRthActionState else { return false }

        return self.altitude == other.altitude
            && self.maxAltitude == other.maxAltitude
            && self.minAltitude == other.minAltitude
    }

    override func copy() -> SettingsRthActionState {
        return SettingsRthActionState(connectionState: self.connectionState,
                                      altitude: self.altitude,
                                      maxAltitude: self.maxAltitude,
                                      minAltitude: self.minAltitude)
    }
}

/// Return to home action settings view model used to handle Grid cell management.
final class SettingsRthActionViewModel: DroneStateViewModel<SettingsRthActionState> {
    // MARK: - Private Properties
    private var returnHomePilotingRef: Ref<ReturnHomePilotingItf>?

    // MARK: - Deinit
    deinit {
        returnHomePilotingRef = nil
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)

        listenReturnHome(drone)
    }

    // MARK: - Internal Funcs
    /// Saves Return Home in drone.
    ///
    /// - Parameters:
    ///     - altitude: altitude to save
    func saveRth(altitude: Double) {
        drone?.getPilotingItf(PilotingItfs.returnHome)?.minAltitude?.value = altitude
    }
}

// MARK: - Private Funcs
private extension SettingsRthActionViewModel {
    /// Starts watcher for Return Home.
    func listenReturnHome(_ drone: Drone) {
        returnHomePilotingRef = drone.getPilotingItf(PilotingItfs.returnHome) { [weak self] rth in
            guard let safeSelf = self,
                  let rth = rth,
                  let minAltitude = rth.minAltitude else { return }

            let copy = safeSelf.state.value.copy()
            copy.altitude = minAltitude.value
            copy.minAltitude = minAltitude.min
            copy.maxAltitude = minAltitude.max
            safeSelf.state.set(copy)
        }
    }
}
