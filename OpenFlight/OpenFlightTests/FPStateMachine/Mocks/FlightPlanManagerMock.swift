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
import Combine

@testable import OpenFlight

/// Mock of the FlightplanManager (FlightPlanManager)
class FlightPlanManagerMock: FlightPlanManager {
    let flightPlantoDelete = UUID().uuidString

    @Published public var currentFlightPlan: FlightPlanModell?
    var editableFPInTheProject: Bool = false

    var currentFlightPlanPublisher: AnyPublisher<FlightPlanModell?, Never> {
        $currentFlightPlan.eraseToAnyPublisher()
    }

    var flightplanList: [FlightPlanModell]?

    init() {
        let editFlightPlan = FlightPlanModell(type: "",
                                              uuid: flightPlantoDelete,
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

        let fliying = FlightPlanModell(type: "",
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
        flightplanList = [editFlightPlan, fliying]
    }

    func editableFlightPlansFor(projectId: String) -> [FlightPlanModell] {
        if editableFPInTheProject {
            if case let fpl? = flightplanList {
                return fpl.filter { $0.state == .editable }
            }
        }
        return []
    }

    func reinitialize(flightPlan: FlightPlanModell) -> FlightPlanModell {
        var duplicate = self.duplicate(flightPlan: flightPlan)
        duplicate.lastMissionItemExecuted = 0
        duplicate.uploadedMediaCount = 0
        duplicate.mediaCount = 0
        return duplicate
    }

    func duplicate(flightPlan: FlightPlanModell) -> FlightPlanModell {
        // duplicate means creating a new FlightPlanModell with:
        // * a new uuid
        // * same parameters as for the duplicated flightPlan
        let duplicateFP = FlightPlanModell(type: "",
                                       uuid: UUID().uuidString,
                                       version: "",
                                       customTitle: flightPlan.customTitle,
                                       thumbnailUuid: nil,
                                       projectUuid: flightPlan.projectUuid,
                                       dataStringType: "",
                                       dataString: "",
                                       pgyProjectId: nil,
                                       mediaCustomId: nil,
                                       state: .editable,
                                       lastMissionItemExecuted: flightPlan.lastMissionItemExecuted,
                                       recoveryId: nil,
                                       mediaCount: 0,
                                       uploadedMediaCount: 0,
                                       lastUpdate: Date(),
                                       thumbnail: nil)
        return duplicateFP
    }

    func delete(flightPlan: FlightPlanModell) {
        // this method should be called only when a flightplan as the deletedUUID
        XCTAssertTrue(flightPlan.uuid == flightPlantoDelete)
        if let state = flightPlan.state {
            XCTAssertTrue(state == .editable, "\(state) FP only can be deleted")
        }
    }

    func updateFlightplan(state: FlightPlanModell.FlightPlanState) {

    }

    func update(flightplan: FlightPlanModell, with state: FlightPlanModell.FlightPlanState) -> FlightPlanModell {
        var copy = flightplan
        copy.state = state
        return copy
    }

    func saveExecutionProgress(for flightPlan: FlightPlanModell, at waypoint: Int) -> FlightPlanModell {
        var updatedFlightPlan = flightPlan
        updatedFlightPlan.lastMissionItemExecuted = Int64(waypoint)
        return updatedFlightPlan
    }

    func appendUndoStack(with flightPlan: FlightPlanModell?) {

    }

    func updateGlobalSettings(with flightPlan: FlightPlanModell?) {

    }

    /// Reset undo stack.
    func resetUndoStack() {

    }

    /// Undo.
    func undo() {

    }

    /// Can undo.
    func canUndo() -> Bool {
        true
    }
}
