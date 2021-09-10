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

import XCTest
import GameKit
import Combine

@testable import OpenFlight

class StartedFlyingTests: XCTestCase {

    var sut: FlightPlanStateMachineImpl!
    var flightPlanRun: FlightPlanRunMock!
    var fpManagerMock: FlightPlanManagerMock!
    var cancellables = Set<AnyCancellable>()

    override func setUpWithError() throws {
        sut = FlightPlanStateMachineImpl()
        flightPlanRun = FlightPlanRunMock(currentDroneHolder: DroneHolderMock())
        fpManagerMock = FlightPlanManagerMock()

        let startedflying = StartedFlyingState(flightPlanRun: flightPlanRun, stateMachineManager: sut, flightPlanManager: FlightPlanManagerMock())

        let states = [startedflying]
        sut.stateMachine = GKStateMachine(states: states)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        sut = nil
        flightPlanRun = nil
    }

    func testResumeAction() throws {
        // given
        sut.stateMachine.enter(StartedFlyingState.self)
        flightPlanRun.pause()

        // when
        sut.resume()

        // then
        XCTAssertTrue(flightPlanRun.status == .play)
    }

    func testProgress() throws {
        // given
        // number of waypoint for this FP
        flightPlanRun.numberOfWayPoint = 10
        var openFP = FlightPlanModell(type: "",
                                         uuid: UUID().uuidString,
                                         version: "",
                                         customTitle: "title",
                                         thumbnailUuid: nil,
                                         projectUuid: UUID().uuidString,
                                         dataStringType: "",
                                         dataString: "",
                                         pgyProjectId: nil,
                                         mediaCustomId: nil,
                                         state: .editable,
                                         lastMissionItemExecuted: 0,
                                         recoveryId: nil,
                                         mediaCount: 0,
                                         uploadedMediaCount: 0,
                                         lastUpdate: Date(),
                                         thumbnail: nil)
        openFP.lastMissionItemExecuted = 0
        sut.currentFlightPlan = openFP

        // When
        sut.stateMachine.enter(StartedFlyingState.self)

        // Start the Flightplan and move item by item
        flightPlanRun.play()

        // Then
        if let flightplan = sut.currentFlightPlan {
            // flightplan went until the last waypoint
            XCTAssertTrue(flightplan.lastMissionItemExecuted == flightPlanRun.numberOfWayPoint)
        } else {
            XCTAssert(false)
        }
    }

    // TODO: review resume + restart
    func testResumeProgress() throws {
        // given
        flightPlanRun.numberOfWayPoint = 10
        var openFP = FlightPlanModell(type: "",
                                         uuid: UUID().uuidString,
                                         version: "",
                                         customTitle: "title",
                                         thumbnailUuid: nil,
                                         projectUuid: UUID().uuidString,
                                         dataStringType: "",
                                         dataString: "",
                                         pgyProjectId: nil,
                                         mediaCustomId: nil,
                                         state: .flying,
                                         lastMissionItemExecuted: 0,
                                         recoveryId: nil,
                                         mediaCount: 0,
                                         uploadedMediaCount: 0,
                                         lastUpdate: Date(),
                                         thumbnail: nil)

        openFP.lastMissionItemExecuted = 5

        // When
        // Start the Flightplan from the interrupted waypoint
        sut.resume()

        // Then
        // last waypoint should be the last saved: flightplanrun.numberOfWayPoint
        if let flightplan = sut.currentFlightPlan {
            XCTAssertTrue(flightplan.lastMissionItemExecuted == flightPlanRun.numberOfWayPoint)
        }
    }

    func testResume() throws {
        // given
        flightPlanRun.numberOfWayPoint = 10
        var openFP = FlightPlanModell(type: "",
                                         uuid: UUID().uuidString,
                                         version: "",
                                         customTitle: "title",
                                         thumbnailUuid: nil,
                                         projectUuid: UUID().uuidString,
                                         dataStringType: "",
                                         dataString: "",
                                         pgyProjectId: nil,
                                         mediaCustomId: nil,
                                         state: .flying,
                                         lastMissionItemExecuted: 0,
                                         recoveryId: nil,
                                         mediaCount: 0,
                                         uploadedMediaCount: 0,
                                         lastUpdate: Date(),
                                         thumbnail: nil)

        openFP.lastMissionItemExecuted = 5
        sut.currentFlightPlan = openFP

        // When
        // an interruption occured
        sut.stateMachine.enter(StartedFlyingState.self)

        // Then
        // last waypoint should be the last saved: flightplanrun.numberOfWayPoint
        if let flightplan = sut.currentFlightPlan {
            XCTAssertTrue(flightplan.lastMissionItemExecuted == flightPlanRun.numberOfWayPoint)
        }
    }

    func testNextPossibleState() throws {
        let startedFlyingState = sut.stateMachine.state(forClass: StartedFlyingState.self)
        if let startedFlying = startedFlyingState {
            // Possible next state
            XCTAssertTrue(startedFlying.isValidNextState(EndedState.self))
            XCTAssertTrue(startedFlying.isValidNextState(InitializingState.self))

            // Impossible states
            XCTAssertFalse(startedFlying.isValidNextState(EditableState.self))
            XCTAssertFalse(startedFlying.isValidNextState(StartedNotFlyingState.self))
        } else {
            XCTAssert(false)
        }
    }
}
