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
import CoreLocation

/// State for `DroneDetailsMapViewModel`.

final class DroneDetailsMapState: DeviceConnectionState {
    // MARK: - Internal Properties
    /// Current drone location.
    fileprivate(set) var location: CLLocation?
    /// Tells if beeper is playing.
    fileprivate(set) var beeperIsPlaying: Bool?

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - connectionState: drone connection state
    ///    - location: drone location
    ///    - beeperIsPlaying: tells if beeper is playing
    init(connectionState: DeviceState.ConnectionState,
         location: CLLocation?,
         beeperIsPlaying: Bool?) {
        super.init(connectionState: connectionState)
        self.location = location
        self.beeperIsPlaying = beeperIsPlaying
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? DroneDetailsMapState else {
            return false
        }
        return super.isEqual(to: other)
            && self.location == other.location
            && self.beeperIsPlaying == other.beeperIsPlaying
    }

    override func copy() -> DroneDetailsMapState {
        return DroneDetailsMapState(connectionState: connectionState,
                                    location: location,
                                    beeperIsPlaying: beeperIsPlaying)
    }
}

/// View Model for map which is displayed in the drone details screen.

final class DroneDetailsMapViewModel: DroneStateViewModel<DroneDetailsMapState> {
    // MARK: - Private Properties
    private var gpsRef: Ref<Gps>?
    private var beeper: Beeper? {
        return drone?.getPeripheral(Peripherals.beeper)
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)
        listenGps(drone)
    }

    // MARK: - Internal Funcs
    /// Starts or stops drone beeper.
    func startOrStopBeeper() {
        let copy = state.value.copy()
        if beeper?.alertSoundPlaying == false {
            copy.beeperIsPlaying = beeper?.startAlertSound() == true
        } else {
            copy.beeperIsPlaying = beeper?.stopAlertSound() == false
        }
        state.set(copy)
    }
}

// MARK: - Private Funcs
private extension DroneDetailsMapViewModel {
    /// Starts watcher for drone gps.
    func listenGps(_ drone: Drone) {
        gpsRef = drone.getInstrument(Instruments.gps) { [weak self] gps in
            let copy = self?.state.value.copy()
            copy?.location = gps?.lastKnownLocation
            self?.state.set(copy)
        }
    }
}
