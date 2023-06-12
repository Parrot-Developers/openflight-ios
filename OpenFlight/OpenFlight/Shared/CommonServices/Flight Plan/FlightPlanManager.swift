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

import Foundation
import Combine
import SdkCore
import Pictor

public protocol FlightPlanManager {

    /// Creates a new Flight Plan with the same title, type, version, flightPlanType, dataSetting.
    ///
    /// - Parameters:
    ///     - flightPlan: flight plan to be based on
    /// - Returns: a new flight plan. The duplicated flight plan is in `.editable` state has
    ///            a new uuid & thumbnail and has the following fields cleared:
    ///            `lastMissionItemExecuted`,
    ///            `recoveryResourceId`,
    ///            `pgyProjectId`,
    ///            `uploadedMediaCount`,
    ///            `mediaCount`,
    ///            `parrotCloudId`,
    ///            `parrotCloudToBeDeleted`,
    ///            `parrotCloudUploadUrl`,
    ///            `synchroDate`
    ///            `synchroStatus`
    ///            `fileSynchroStatus`
    ///            `fileSynchroDate`
    func newFlightPlan(basedOn flightPlan: FlightPlanModel) -> FlightPlanModel

    /// Deletes a flightPlan.
    ///
    /// - Parameters:
    ///     - flightPlan: flight plan to delete
    func delete(flightPlan: FlightPlanModel)

    /// Updates flightplan state and saves it in CoreData
    ///
    /// - Parameters:
    ///     - flightplan: flight plan to update
    ///     - state: update the flightplan with this new state
    func update(flightplan: FlightPlanModel, with state: FlightPlanState) -> FlightPlanModel

    /// Updates flightplan lastMissionItemExecuted
    /// - Parameters:
    ///   - flightPlan: flight plan
    ///   - lastMissionItemExecuted: last item executed
    ///   - recoveryResourceId: first resource identifier of media captured after the latest reached waypoint
    /// - Returns: the updated flight pan
    func update(flightPlan: FlightPlanModel, lastMissionItemExecuted: Int, recoveryResourceId: String?) -> FlightPlanModel

    /// Updates flightplan lastMissionItemExecuted
    /// - Parameters:
    ///   - flightPlan: flight plan
    ///   - lastMissionItemExecuted: last item executed
    ///   - recoveryResourceId: first resource identifier of media captured after the latest reached waypoint
    ///   - databaseUpdateCompletion: the completion block called when data base has been updated
    /// - Returns: the updated flight pan
    ///
    /// - Description: This method can be used, instead of the one without completion, to perform some actions (e.g. clear recoveryinfo)
    ///                only when the database has been correctly updated.
    func update(flightPlan: FlightPlanModel,
                lastMissionItemExecuted: Int,
                recoveryResourceId: String?,
                databaseUpdateCompletion: ((_ status: Bool) -> Void)?) -> FlightPlanModel

    /// Updates flightplan `customTitle` and saves it in CoreData.
    ///
    /// - Parameters:
    ///    - flightplan: flight plan to update.
    ///    - customTitle: the new `customTitle` value.
    func update(flightplan: FlightPlanModel, with customTitle: String) -> FlightPlanModel

    /// Get all Editable flightplans linked to a specific project
    ///
    /// - parameters:
    ///     - projectId: project to consider
    /// - Returns: List of flight plans ordered by lastUpdate
    func editableFlightPlansFor(projectId: String) -> [FlightPlanModel]

    /// Updates a flight plan with **lastUploadAttempt** set to today date and **uploadAttemptCount** incremented
    ///
    /// - Parameter flightplan: flight plan to be updated
    /// - Returns: Flight plan updated
    func updateWithUploadAttempt(flightplan: FlightPlanModel) -> FlightPlanModel

    /// Gets a flight plan given its uuid
    /// - Parameter uuid: uuid of the flight plan
    func flightPlan(uuid: String) -> FlightPlanModel?

    /// Gets a flight plan given its pgyId
    /// - Parameter pgyId: pgyId of a project
    func flightPlanWith(pgyId: Int64) -> FlightPlanModel?

    /// Gets all flight plans according to a specific state
    /// - Parameter state: state to filter
    func flightPlansForState(_ state: FlightPlanState) -> [FlightPlanModel]

    /// Get the last flight date of a flight plan if any
    /// - Parameter flightPlan: flight plan
    func lastFlightDate(_ flightPlan: FlightPlanModel) -> Date?

    /// Get the first FlightPlan's Flight date.
    /// - Parameter flightPlanModel: the Flight Plan
    /// - Returns: the `Date` if exists or `nil`
    func firstFlightDate(of flightPlan: FlightPlanModel) -> Date?

    /// Returns the formatted start date of the first FlightPlan's Flight.
    ///
    /// - Parameters:
    ///  - flightPlan: the Flight Plan
    /// - Returns: formatted date or dash if formatting failed
    ///
    /// - Description:
    /// Following scenarios are possible:
    ///   • An execution is linked to one Flight.
    ///     (when only one FP is executed between the take-off and the landing).
    ///   • Several executions are linked to the same Flight.
    ///     (when several FPs are executed between the take-off and the landing).
    ///   • An execution is linked to several Flights.
    ///     (when FP is paused then resumed with landing between them).
    /// Note: An execution is an FP which is not in editable mode.
    ///
    /// This method searches for the first FlightPlan's Flight and gets its start date (representing the Drone's take-off date).
    ///  If not found, we fallback into the execution's date which represents the moment when the FP has ben launched.
    func firstFlightFormattedDate(of flightPlan: FlightPlanModel) -> String

    /// Get the latest related flight run date from a specified flight plan UUIDs.
    /// - Parameter byFlightPlanUuids
    /// - Returns: latest flight run date if any
    func getLatestFlightRunDate(byFlightPlanUuids: [String]) -> Date?
}

private extension ULogTag {
    static let tag = ULogTag(name: "FPManager")
}

public class FlightPlanManagerImpl: FlightPlanManager {
    private let flightPlanRepository: PictorFlightPlanRepository!
    private let gutmaLinkRepository: PictorGutmaLinkRepository!
    private let userService: PictorUserService!
    private let filesManager: FlightPlanFilesManager!
    private let pgyProjectRepo: PictorProjectPix4dRepository!

    public init(flightPlanRepository: PictorFlightPlanRepository,
                gutmaLinkRepository: PictorGutmaLinkRepository,
                userService: PictorUserService,
                filesManager: FlightPlanFilesManager,
                pgyProjectRepo: PictorProjectPix4dRepository) {
        self.flightPlanRepository = flightPlanRepository
        self.gutmaLinkRepository = gutmaLinkRepository
        self.userService = userService
        self.filesManager = filesManager
        self.pgyProjectRepo = pgyProjectRepo
    }

    // MARK: - Private Functions

    private func persist(_ flightPlan: FlightPlanModel,
                         toSynchro: Bool) {
        let pictorContext = PictorContext.new()
        if toSynchro {
            pictorContext.create([flightPlan.pictorModel])
        } else {
            pictorContext.createLocal([flightPlan.pictorModel])
        }
        pictorContext.commit()
    }

    // MARK: - Public Functions

    public func newFlightPlan(basedOn flightPlan: FlightPlanModel) -> FlightPlanModel {
        return FlightPlanModel.new(from: flightPlan)
    }

    public func delete(flightPlan: FlightPlanModel) {
        let pictorContext = PictorContext.new()

        ULog.i(.tag, "Deleting flightPlan '\(flightPlan.uuid)'")
        if flightPlan.pgyProjectId > 0 {
            if let project = pgyProjectRepo.get(byUuid: "\(flightPlan.pgyProjectId)") {
                pictorContext.delete([project])
            }
        }
        filesManager.deleteMavlink(of: flightPlan)

        pictorContext.delete([flightPlan.pictorModel])
        pictorContext.commit()
    }

    public func editableFlightPlansFor(projectId: String) -> [FlightPlanModel] {
        let pictorModels = flightPlanRepository.get(uuids: nil,
                                                    excludedUuids: nil,
                                                    projectUuids: [projectId],
                                                    projectPix4dUuids: nil,
                                                    states: [FlightPlanState.editable],
                                                    excludedStates: nil,
                                                    types: nil,
                                                    excludedTypes: nil,
                                                    hasReachedFirstWaypoint: nil)

        ULog.i(.tag, "editableFlightPlansFor for projectId \(projectId): \(pictorModels)")
        return pictorModels.map { $0.flightPlanModel }
    }

    public func flightPlansForState(_ state: FlightPlanState) -> [FlightPlanModel] {
        let pictorModels = flightPlanRepository.get(uuids: nil,
                                                    excludedUuids: nil,
                                                    projectUuids: nil,
                                                    projectPix4dUuids: nil,
                                                    states: [state],
                                                    excludedStates: nil,
                                                    types: nil,
                                                    excludedTypes: ["default"],
                                                    hasReachedFirstWaypoint: nil)
        return pictorModels.map { $0.flightPlanModel }
    }

    public func updateWithUploadAttempt(flightplan: FlightPlanModel) -> FlightPlanModel {
        var updatedFlightplan = flightplan
        updatedFlightplan.lastUploadAttempt = Date()
        updatedFlightplan.uploadAttemptCount += 1
        persist(updatedFlightplan,
                toSynchro: false)
        ULog.i(.tag, "Update flightPlan '\(updatedFlightplan.uuid)' uploadAttempt to \(updatedFlightplan.uploadAttemptCount)")
        return updatedFlightplan
    }

    public func update(flightplan: FlightPlanModel, with state: FlightPlanState) -> FlightPlanModel {
        var newStateFlightPlan = flightplan
        newStateFlightPlan.pictorModel.lastUpdated = Date()
        newStateFlightPlan.pictorModel.state = state
        persist(newStateFlightPlan,
                toSynchro: true)
        ULog.i(.tag, "Update flightPlan '\(newStateFlightPlan.uuid)' state to '\(state)'")
        return newStateFlightPlan
    }

    public func update(flightplan: FlightPlanModel, with customTitle: String) -> FlightPlanModel {
        var newFlightPlan = flightplan
        newFlightPlan.pictorModel.name = customTitle
        persist(newFlightPlan,
                toSynchro: true)
        ULog.i(.tag, "Update flightPlan '\(newFlightPlan.uuid)' customTitle to '\(customTitle)'")
        return newFlightPlan
    }

    public func update(flightPlan: FlightPlanModel,
                       lastMissionItemExecuted: Int,
                       recoveryResourceId: String?) -> FlightPlanModel {
        update(flightPlan: flightPlan,
               lastMissionItemExecuted: lastMissionItemExecuted,
               recoveryResourceId: recoveryResourceId,
               databaseUpdateCompletion: nil)
    }

    public func update(flightPlan: FlightPlanModel,
                       lastMissionItemExecuted: Int,
                       recoveryResourceId: String?,
                       databaseUpdateCompletion: ((_ status: Bool) -> Void)?) -> FlightPlanModel {
        guard lastMissionItemExecuted >= flightPlan.pictorModel.lastMissionItemExecuted else {
            // update flightplan only if new value of `last mission item executed` is greater or equal to current value
            return flightPlan
        }
        var newFlightPlan = flightPlan
        // The `lastMissionItemExecuted` must be set before checking hasReachedLastWayPoint
        newFlightPlan.pictorModel.lastMissionItemExecuted = lastMissionItemExecuted

        // Update flight plan completion state.
        // The `state` field will be updated by the State Machine / Run Manager.
        if let mavlinkCommands = flightPlan.mavlinkCommands {
            newFlightPlan.hasReachedFirstWayPoint = mavlinkCommands.hasReachedFirstWayPoint(index: lastMissionItemExecuted)
            newFlightPlan.hasReachedLastWayPoint = mavlinkCommands.hasReachedLastWayPoint(index: lastMissionItemExecuted)
            newFlightPlan.lastPassedWayPointIndex = mavlinkCommands.lastPassedWayPointIndex(for: lastMissionItemExecuted)
            let percentCompleted = mavlinkCommands.percentCompleted(for: lastMissionItemExecuted, flightPlan: newFlightPlan)
            newFlightPlan.percentCompleted = percentCompleted
        }

        newFlightPlan.recoveryResourceId = recoveryResourceId

        let pictorContext = PictorContext.new()
        pictorContext.updateLocal([newFlightPlan.pictorModel])
        pictorContext.commit()
        databaseUpdateCompletion?(true)

        return newFlightPlan
    }

    public func flightPlan(uuid: String) -> FlightPlanModel? {
        flightPlanRepository.get(byUuid: uuid)?.flightPlanModel
    }

    public func flightPlanWith(pgyId: Int64) -> FlightPlanModel? {
        let pictorModels = flightPlanRepository.get(uuids: nil,
                                                    excludedUuids: nil,
                                                    projectUuids: nil,
                                                    projectPix4dUuids: ["\(pgyId)"],
                                                    states: nil,
                                                    excludedStates: nil,
                                                    types: nil,
                                                    excludedTypes: nil,
                                                    hasReachedFirstWaypoint: nil)
        return pictorModels.first?.flightPlanModel
    }

    public func lastFlightDate(_ flightPlan: FlightPlanModel) -> Date? {
        gutmaLinkRepository.getLastFlight(byFlightPlanUuid: flightPlan.uuid)?.runDate
    }

    public func firstFlightDate(of flightPlan: FlightPlanModel) -> Date? {
        gutmaLinkRepository.getFirstFlight(byFlightPlanUuid: flightPlan.uuid)?.runDate
    }

    public func firstFlightFormattedDate(of flightPlan: FlightPlanModel) -> String {
        // If not found, return the execution date.
        guard let flightDate = firstFlightDate(of: flightPlan) else {
            return L10n.flightPlanHistoryExecutionNotSynchronized
        }
        // Format the date.
        return flightDate.commonFormattedString
    }

    public func getLatestFlightRunDate(byFlightPlanUuids: [String]) -> Date? {
        gutmaLinkRepository.getLatestFlightRunDate(byFlightPlanUuids: byFlightPlanUuids)
    }
}
