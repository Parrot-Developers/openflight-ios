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
import GameKit
import Combine

@testable import OpenFlight

class StartedNotFlyingTests: XCTestCase {

    var sut: FlightPlanStateMachineImpl!
    var cancellables = Set<AnyCancellable>()
    
    override func setUpWithError() throws {
        sut = FlightPlanStateMachineImpl()

        let startednotflyingState = StartedNotFlyingState(flightPlanManager: FlightPlanManagerMock(), stateMachineManager: sut)

        let states = [startednotflyingState]
        sut.stateMachine = GKStateMachine(states: states)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        sut = nil
    }

    func testStart() throws {
        // given
        // a FP already open
        let identifier = UUID().uuidString
        let title = "editedFP"
        let openFP = FlightPlanModell(type: "",
                                      uuid: identifier,
                                      version: "",
                                      customTitle: "title",
                                      thumbnailUuid: nil,
                                      projectUuid: UUID().uuidString,
                                      dataStringType: "",
                                      dataString: "",
                                      pgyProjectId: nil,
                                      state: .editable,
                                      lastMissionItemExecuted: 0,
                                      recoveryId: nil,
                                      mediaCount: 0,
                                      uploadedMediaCount: 0,
                                      lastUpdate: Date(),
                                      thumbnail: nil)

        sut.currentFlightPlan = openFP

        // when
        // user edits the flightplan
        let editedFP = FlightPlanModell(type: "",
                                        uuid: identifier,
                                        version: "",
                                        customTitle: title,
                                        thumbnailUuid: nil,
                                        projectUuid: UUID().uuidString,
                                        dataStringType: "",
                                        dataString: "",
                                        pgyProjectId: nil,
                                        state: .editable,
                                        lastMissionItemExecuted: 0,
                                        recoveryId: nil,
                                        mediaCount: 0,
                                        uploadedMediaCount: 0,
                                        lastUpdate: Date(),
                                        thumbnail: nil)
        sut.start(flightPlan: editedFP)

        // then
        // flightplan to start is the edited one
        XCTAssertTrue(sut.currentFlightPlan?.uuid == editedFP.uuid)
        XCTAssertTrue(sut.currentFlightPlan?.customTitle == title)
    }

    func testNextPossibleState() throws {
        let flyingState = sut.stateMachine.state(forClass: StartedNotFlyingState.self)
        if let flyingState = flyingState {
            // Possible next state
            XCTAssertTrue(flyingState.isValidNextState(StartedFlyingState.self))

            // Impossible state
            XCTAssertFalse(flyingState.isValidNextState(EditableState.self))
            XCTAssertFalse(flyingState.isValidNextState(EndedState.self))
            XCTAssertFalse(flyingState.isValidNextState(InitializingState.self))

        } else {
            XCTAssert(false)
        }
    }
}
