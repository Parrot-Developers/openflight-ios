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

/// View model for obstacle avoidance indicator
public class ObstacleAvoidanceViewModel {

    /// State for obstacle avoidance display.
    public enum State: Equatable {
        case disconnected
        case unwanted
        case wanted(ObstacleAvoidanceState)
    }

    // MARK: - Public Properties
    @Published private(set) var state = State.disconnected

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var obstacleAvoidanceRef: Ref<ObstacleAvoidance>?

    /// Constructor.
    ///
    /// - Parameter connectedDroneHolder: the connected drone holder
    init(connectedDroneHolder: ConnectedDroneHolder) {
        connectedDroneHolder.dronePublisher.sink { [unowned self] in
            if let drone = $0 {
                // if there's a connected drone, directly listen its OA state
                listenObstacleAvoidanceState(drone: drone)
            } else {
                // stop listening for OA on previously connected drone if any
                obstacleAvoidanceRef = nil
                state = .disconnected
            }
        }
        .store(in: &cancellables)
    }
}

// MARK: - Private Funcs
private extension ObstacleAvoidanceViewModel {

    /// Listens to obstacle avoidance on drone.
    func listenObstacleAvoidanceState(drone: Drone) {
        obstacleAvoidanceRef = drone.getPeripheral(Peripherals.obstacleAvoidance) { [unowned self] in
            guard let obstacleAvoidance = $0 else {
                // not having access to the peripheral is like being disconnected from the OA indicator point of view
                state = .disconnected
                return
            }
            switch obstacleAvoidance.mode.preferredValue {
            case .disabled:
                state = .unwanted
            case .standard:
                state = .wanted(obstacleAvoidance.state)
            }
        }
    }
}
