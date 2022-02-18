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

import XCTest
import Combine

@testable import OpenFlight
@testable import GroundSdk

class FlightPlanRunMock: FlightPlanRunManager {

    // for testing only
    enum RunningStatus {
        case play
        case pause
        case stop
    }

    var status: RunningStatus = .stop

    private var waypointProgress = PassthroughSubject<Int, FlightPlanRunInterruption>()

    var numberOfWayPoint = 0
    var interruptionAtWayPoint = 0

    override var waypointProgressPublisher: AnyPublisher<Int, FlightPlanRunInterruption> {
        waypointProgress.eraseToAnyPublisher()
    }

    override var totalNumberWayPoint: Int {
        return numberOfWayPoint
    }

    override var captureMode: FlightPlanRunCaptureMode {
        .photo
    }

    public override func play() {
        status = .play

        var item: Int64 = 0
        if let lastItem = self.flightplan?.lastMissionItemExecuted {
            item = lastItem
        }

        for item in Int(item)...self.totalNumberWayPoint {
            waypointProgress.send(item)
            if interruptionAtWayPoint > 0 && item == interruptionAtWayPoint {
                waypointProgress.send(completion: .failure(.GPS))
            }

            if status == .stop {
                return
            }
        }
    }

    override func pause() {
        status = .pause
    }
    
    override func stop() {
        status = .stop
        waypointProgress.send(completion: .finished)
    }
}

class DroneHolderMock: CurrentDroneHolder {
    var drone: Drone

    var dronePublisher: AnyPublisher<Drone, Never>

    init() {
        drone = DroneMock()
        dronePublisher = PassthroughSubject<Drone, Never>().eraseToAnyPublisher()
    }

    func clearCurrentDroneOnMatch(uid: String) {

    }
}

class DroneMock: Drone {
    init() {
        super.init(droneCore: DroneCore(uid: "", model: .anafi2, name: "", delegate: DeviceDelegate()))
    }
}

class DeviceDelegate: DeviceCoreDelegate {
    func forget() -> Bool {
        false
    }

    func connect(connector: DeviceConnector, password: String?) -> Bool {
        false
    }

    func disconnect() -> Bool {
        false
    }
}
