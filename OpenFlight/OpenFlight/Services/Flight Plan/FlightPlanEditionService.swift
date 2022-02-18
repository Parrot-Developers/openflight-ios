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

import Combine
import ArcGIS
import GroundSdk

private extension ULogTag {
    static let tag = ULogTag(name: "FPEditionService")
}

public protocol FlightPlanEditionService {

    // MARK: - Read
    var settingsChanged: [FlightPlanLightSetting] { get }

    /// Current flight plan publisher
    var currentFlightPlanPublisher: AnyPublisher<FlightPlanModel?, Never> { get }

    /// Current flight plan
    var currentFlightPlanValue: FlightPlanModel? { get }

    // MARK: - High level management
    /// Sets up flight plan modell
    func setupFlightPlan(_ flightPlan: FlightPlanModel?)

    /// Resets fligh plan
    func resetFlightPlan()

    /// Clears Flight Plan, removing MAVLink file if
    /// any and deleting all waypoints and points of interest.
    ///
    /// - Note: calling this preserves uuid & settings.
    func clearFlightPlan()

    // MARK: - Undo management

    /// Can undo.
    func canUndo() -> Bool

    /// Undo.
    func undo()

    /// Forget the latest flight plan setting in the undo stack.
    func popUndoStack()

    /// Reset undo stack.
    func resetUndoStack()

    /// Add current flight plan setting in the undo stack.
    func appendCurrentStateToUndoStack()

    // MARK: - Commands

    /// - Parameters:
    ///    - mapPoint: location of the new waypoint
    ///    - index: index at which waypoint should be inserted
    /// - Returns: new waypoint, nil if index is invalid
    func insertWayPoint(with mapPoint: AGSPoint, at index: Int) -> WayPoint?

    /// Removes point of interest at given index.
    ///
    /// - Parameters:
    ///    - index: point of interest index
    /// - Returns: removed point of interest, if any
    @discardableResult
    func removePoiPoint(at index: Int) -> PoiPoint?

    /// Update only global settings of current flight plan and replace it in stack
    ///
    /// - Parameters:
    ///     - dataSetting: flight plan data setting to update.
    func updateGlobalSettings(with dataSetting: FlightPlanDataSetting?)

    /// Update the polygon points for the current flight plan.
    ///
    /// - Parameters:
    ///     - points: Polygon points
    func updatePolygonPoints(points: [AGSPoint])

    /// Update the current flight plan's type
    /// - Parameters:
    ///   - type: flight plan type
    ///   - resetPolygonPoints: whether to reset the polygon points
    ///   - settings: default settings related to new type
    func updateFlightPlanType(_ type: String,
                              resetPolygonPoints: Bool,
                              settings: [FlightPlanLightSetting]?)

    /// Removes waypoint at given index.
    ///
    /// - Parameters:
    ///    - index: waypoint index
    /// - Returns: removed waypoint, if any
    @discardableResult
    func removeWaypoint(at index: Int) -> WayPoint?

    /// Change Flight Plan settings.
    ///
    /// - Parameters:
    ///    - settings: new settings
    func updateSettings(_ settings: [FlightPlanLightSetting])

    /// Sets up return to home on last point setting.
    ///
    /// - Parameters:
    ///    - lastPointRth: whether drone should land on last waypoint
    func setLastPointRth(_ lastPointRth: Bool)

    func endEdition(completion: @escaping () -> Void)

    func rename(_ flightPlan: FlightPlanModel, title: String)

    func freeSettingDidChange(key: String, value: String)

    // MARK: TODO move this somewhere relevant
    /// Updates current Flight Plan with new Mavlink.
    ///
    /// - Parameters:
    ///     - mavlinkData: Mavlink data
    ///     - type: Flight Plan type
    ///     - settings: Flight plan settings
    func updateFlightPlan(withMavlinkData mavlinkData: Data,
                          type: FlightPlanType,
                          settings: [FlightPlanLightSetting])

    func updateProjectManager(_ projectManager: ProjectManager)

    var hasChanges: Bool { get }
}

public class FlightPlanEditionServiceImpl {

    private var undoStack: [String] = []
    private let requester: FlightPlanThumbnailRequester = FlightPlanThumbnailRequester()
    private let repo: FlightPlanRepository
    private let typeStore: FlightPlanTypeStore
    private let currentMissionManager: CurrentMissionManager
    private let currentUser: UserInformation
    private var projectManager: ProjectManager?

    public private(set) var hasChanges: Bool = true
    public var settingsChanged: [FlightPlanLightSetting] = []
    private var currentFlightPlanSubject = CurrentValueSubject<FlightPlanModel?, Never>(nil)
    private var currentFlightPlan: FlightPlanModel? {
        get {
            currentFlightPlanSubject.value
        }
        set {
            let oldValue = currentFlightPlanSubject.value
            currentFlightPlanSubject.send(newValue)
            if currentFlightPlan?.uuid != oldValue?.uuid {
                resetUndoStack()
            }
        }
    }

    @Published public var wayPointOrientationEdition = false

    init(flightPlanRepo: FlightPlanRepository,
         typeStore: FlightPlanTypeStore,
         currentMissionManager: CurrentMissionManager,
         currentUser: UserInformation) {
        repo = flightPlanRepo
        self.typeStore = typeStore
        self.currentMissionManager = currentMissionManager
        self.currentUser = currentUser
    }
}

extension FlightPlanEditionServiceImpl {

    public var currentFlightPlanValue: FlightPlanModel? {
        currentFlightPlan
    }

    public var currentFlightPlanPublisher: AnyPublisher<FlightPlanModel?, Never> {
        currentFlightPlanSubject.eraseToAnyPublisher()
    }

    /// - Parameters:
    ///    - mapPoint: location of the new waypoint
    ///    - index: index at which waypoint should be inserted
    /// - Returns: new waypoint, nil if index is invalid
    public func insertWayPoint(with mapPoint: AGSPoint,
                               at index: Int) -> WayPoint? {
        guard let flightPlan = currentFlightPlan,
              let dataSettings = flightPlan.dataSetting,
              index > 0,
              index < dataSettings.wayPoints.count,
              let previousWayPoint = dataSettings.wayPoints.elementAt(index: index - 1),
              let nextWayPoint = dataSettings.wayPoints.elementAt(index: index) else { return nil }

        let tilt = (previousWayPoint.tilt + nextWayPoint.tilt) / 2.0

        // Create new waypoint.
        let wayPoint = WayPoint(coordinate: mapPoint.toCLLocationCoordinate2D(),
                                altitude: mapPoint.z.rounded(),
                                speed: nextWayPoint.speed,
                                shouldContinue: dataSettings.shouldContinue ?? true,
                                tilt: tilt.rounded())

        // Associate waypoints.
        previousWayPoint.nextWayPoint = wayPoint
        nextWayPoint.previousWayPoint = wayPoint
        wayPoint.previousWayPoint = previousWayPoint
        wayPoint.nextWayPoint = nextWayPoint

        // Insert in array.
        dataSettings.wayPoints.insert(wayPoint, at: index)

        // Update yaws.
        previousWayPoint.updateYaw()
        nextWayPoint.updateYaw()
        wayPoint.updateYaw()
        // Just triggering
        currentFlightPlan = flightPlan

        return wayPoint
    }

    public func setupFlightPlan(_ flightPlan: FlightPlanModel?) {
        currentFlightPlan = flightPlan
    }

    public func setLastPointRth(_ lastPointRth: Bool) {
        let flightplan = currentFlightPlan
        flightplan?.dataSetting?.lastPointRth = lastPointRth
        currentFlightPlan = flightplan
    }

    /// Adds a waypoint at the end of the Flight Plan.
    func addWaypoint(_ wayPoint: WayPoint) {
        let flightplan = currentFlightPlan
        let previous = flightplan?.dataSetting?.wayPoints.last
        flightplan?.dataSetting?.wayPoints.append(wayPoint)
        wayPoint.previousWayPoint = previous
        previous?.nextWayPoint = wayPoint
        wayPoint.updateYawAndRelations()
        currentFlightPlan = flightplan
    }

    /// Adds a point of interest to the Flight Plan.
    func addPoiPoint(_ poiPoint: PoiPoint) {
        let flightplan = currentFlightPlan
        flightplan?.dataSetting?.pois.append(poiPoint)
        currentFlightPlan = flightplan
    }

    /// Removes waypoint at given index.
    ///
    /// - Parameters:
    ///    - index: waypoint index
    /// - Returns: removed waypoint, if any
    @discardableResult
    public func removeWaypoint(at index: Int) -> WayPoint? {
        let flightplan = currentFlightPlan
        guard
            let dataSetting = flightplan?.dataSetting,
            index < dataSetting.wayPoints.count else { return nil }
        let wayPoint = flightplan?.dataSetting?.wayPoints.remove(at: index)
        // Update previous and next waypoint yaw.
        let previous = wayPoint?.previousWayPoint
        let next = wayPoint?.nextWayPoint
        previous?.nextWayPoint = next
        next?.previousWayPoint = previous
        previous?.updateYaw()
        next?.updateYaw()
        currentFlightPlan =  flightplan
        return wayPoint
    }

    /// Removes point of interest at given index.
    ///
    /// - Parameters:
    ///    - index: point of interest index
    /// - Returns: removed point of interest, if any
    @discardableResult
    public func removePoiPoint(at index: Int) -> PoiPoint? {
        let flightplan = currentFlightPlan
        guard
            let dataSetting = flightplan?.dataSetting,
            index < dataSetting.pois.count else {
            return nil
        }
        flightplan?.dataSetting?.wayPoints.forEach {
            guard let poiIndex = $0.poiIndex else { return }

            switch poiIndex {
            case index:
                $0.poiIndex = nil
                $0.poiPoint = nil
            case let supIdx where supIdx > index:
                $0.poiIndex = poiIndex - 1
            default:
                break
            }
        }
        let pois = flightplan?.dataSetting?.pois.remove(at: index)
        currentFlightPlan = flightplan
        return pois
    }

    /// Updates capture setting.
    ///
    /// - Parameters:
    ///     - type: setting's type
    ///     - value: setting's value
    public func updateCaptureSetting(type: ClassicFlightPlanSettingType, value: String?) {
        guard let value = value else { return }
        let flightPlan = currentFlightPlan
        // Init captureSettings if needed.
        if flightPlan?.dataSetting?.captureSettings == nil { flightPlan?.dataSetting?.captureSettings = [:] }
        // Save value.
        flightPlan?.dataSetting?.captureSettings?[type.rawValue] = value
        currentFlightPlan = flightPlan
    }

    /// Update the polygon points for the current flight plan.
    ///
    /// - Parameters:
    ///     - points: Polygon points
    public func updatePolygonPoints(points: [AGSPoint]) {
        guard let flightPlan = currentFlightPlan else { return }
        flightPlan.updatePolygonPoints(points: points)
        // Don't trigger currentFlightPlan change because it would loop recursively with the mapVC that is responsible for the points update
    }
}

extension  FlightPlanEditionServiceImpl: FlightPlanEditionService {

    // MARK: - Private Enums
    private enum Constants {
        // Maximum items in undo stack.
        static let maximumUndoStack: Int = 30
    }

    public func updateFlightPlanType(_ type: String,
                                     resetPolygonPoints: Bool,
                                     settings: [FlightPlanLightSetting]?) {
        guard var flightPlan = currentFlightPlan else { return }
        guard flightPlan.type != type else { return }

        flightPlan.type = type
        if resetPolygonPoints {
            clear(flightPlan: flightPlan)
        }
        if let lightSettings = settings {
            flightPlan.dataSetting?.settings = lightSettings
        }
        resetUndoStack()
        currentFlightPlan = flightPlan
    }

    // MARK: - Undo management

    /// Can undo.
    public func canUndo() -> Bool {
        return undoStack.count > 1
    }

    /// Undo.
    public func undo() {
        guard canUndo() else { return }

        // Dump last.
        popUndoStack()

        // Restore flight plan from data to make another copy.
        // FlightPlan's currentFlightPlan must not point on undo stack.
        if let dataSetting = FlightPlanDataSetting.instantiate(with: undoStack.last),
           var flightPlan = currentFlightPlan {
            flightPlan.dataSetting = dataSetting
            currentFlightPlan = flightPlan
        }
    }

    /// Forget the latest flight plan setting in the undo stack.
    public func popUndoStack() {
        guard !undoStack.isEmpty else { return }

        undoStack.removeLast()
    }

    /// Reset undo stack.
    public func resetUndoStack() {
        undoStack.removeAll()
        appendUndoStack(with: currentFlightPlan?.dataSetting)
    }

    public func appendCurrentStateToUndoStack() {
        appendUndoStack(with: currentFlightPlan?.dataSetting)
    }

    private func appendUndoStack(with setting: FlightPlanDataSetting?) {
        guard let dataSettingString = setting?.toJSONString() else { return }

        // Store flight plan as data to make a copy.
        // FlightPlan's currentFlightPlan must not point on undo stack.
        if undoStack.count >= Constants.maximumUndoStack {
            undoStack.removeFirst()
        }

        undoStack.append(dataSettingString)
    }

    /// Update only global settings of current flight plan and replace it in stack
    ///
    /// - Parameters:
    ///     - dataSetting: data setting to update.
    public func updateGlobalSettings(with dataSetting: FlightPlanDataSetting?) {
        guard let dataSetting = dataSetting?.toJSONString() else { return }
        popUndoStack()
        undoStack.append(dataSetting)
    }

    private func updateThumbnail(flightPlan: FlightPlanModel, completion: @escaping (ThumbnailModel) -> Void) {
        requester.requestThumbnail(flightPlan: flightPlan,
                                   thumbnailSize: FlightPlanThumbnailRequesterConstants.thumbnailSize) { [unowned self] thumbnailImage in
            let uuid = flightPlan.thumbnailUuid ?? UUID().uuidString
            let thumbnail = ThumbnailModel(apcId: currentUser.apcId,
                                           uuid: uuid,
                                           flightUuid: nil,
                                           thumbnailImage: thumbnailImage)
            completion(thumbnail)
        }
    }

    /// Change Flight Plan settings.
    ///
    /// - Parameters:
    ///    - settings: new settings
    public func updateSettings(_ settings: [FlightPlanLightSetting]) {
        guard let flightPlan = currentFlightPlan else { return }

        if let oldSettings = flightPlan.dataSetting?.settings {
            let diff = zip(oldSettings, settings)
                .filter { $0.0 != $0.1 }
            // use the old setting as flightPlan.dataSteting.settings will contain the updated setting
                .map { $0.0 }
            settingsChanged = diff
        }
        flightPlan.dataSetting?.settings = settings
        currentFlightPlan = flightPlan
        settingsChanged = []
    }

    public func clearFlightPlan() {
        let flightPlan = currentFlightPlan
        clear(flightPlan: flightPlan)
        currentFlightPlan = flightPlan
    }

    private func clear(flightPlan: FlightPlanModel?) {
        flightPlan?.dataSetting?.polygonPoints = []
        flightPlan?.dataSetting?.wayPoints = []
        flightPlan?.dataSetting?.pois = []
        flightPlan?.dataSetting?.mavlinkDataFile = nil
        flightPlan?.dataSetting?.freeSettings = [:]
    }

    public func resetFlightPlan() {
        if currentFlightPlan != nil {
            currentFlightPlan = nil
        }
    }

    public func endEdition(completion: @escaping () -> Void) {
        guard var flightPlan = currentFlightPlan else { return }
        flightPlan.lastUpdate = Date()

        // clear mavlink data if the data can be generated for this type.
        // mavlink generation is done by FPRunManager > StartedNotFlyingState > MavlinkGenerator
        let type = typeStore.typeForKey(flightPlan.type)
        let canGenerateMavlink = type?.canGenerateMavlink ?? false
        if canGenerateMavlink {
            flightPlan.dataSetting?.mavlinkDataFile = nil
        }
        updateThumbnail(flightPlan: flightPlan) { [unowned self] thumbnail in
            flightPlan.thumbnail = thumbnail
            ULog.i(.tag, "Updated thumbnail '\(thumbnail.uuid)' of flightPlan '\(flightPlan.uuid)'")
            currentMissionManager.mode.stateMachine?.flightPlanWasEdited(flightPlan: flightPlan)
            currentFlightPlan = flightPlan
            repo.saveOrUpdateFlightPlan(flightPlan,
                                        byUserUpdate: true,
                                        toSynchro: true,
                                        withFileUploadNeeded: false)
            if let project = projectManager?.project(for: flightPlan),
               project.title != flightPlan.customTitle {
                projectManager?.rename(project, title: flightPlan.customTitle)
            }
            ULog.i(.tag, "Ended edition of flightPlan '\(flightPlan.uuid)'")
            completion()
            resetUndoStack()
        }
    }

    public func rename(_ flightPlan: FlightPlanModel, title: String) {
        if flightPlan.uuid == currentFlightPlan?.uuid {
            currentFlightPlan?.customTitle = title
        }
    }

    public func updateFlightPlan(withMavlinkData mavlinkData: Data,
                                 type: FlightPlanType,
                                 settings: [FlightPlanLightSetting]) {
        guard let currentFP = currentFlightPlan,
              let flightPlan = type.mavLinkType
                .generateFlightPlanFromMavlink(url: nil,
                                               mavlinkString: String(data: mavlinkData, encoding: .utf8),
                                               flightPlan: currentFP),
              flightPlan.state == .editable else {
                  return
              }
        if currentFP.type != flightPlan.type {
            ULog.w(.tag, "Unexpected flightPlan type '\(flightPlan.type)' current '\(currentFP.type)'")
        }
        // Save Mavlink into the intended Mavlink url if needed.
        if !type.canGenerateMavlink {
            flightPlan.dataSetting?.mavlinkDataFile = mavlinkData
        }

        // Backup OA settings.
        flightPlan.dataSetting?.obstacleAvoidanceActivated = currentFP.dataSetting?.obstacleAvoidanceActivated ?? true
        // Backup capture settings.
        let captureSettings = currentFP.dataSetting?.captureSettings
        flightPlan.dataSetting?.captureSettings = captureSettings

        // Update FP data.
        currentFlightPlan = flightPlan
    }

    public func freeSettingDidChange(key: String, value: String) {
        currentFlightPlan?.dataSetting?.freeSettings[key] = value
    }

    public func updateProjectManager(_ projectManager: ProjectManager) {
        self.projectManager = projectManager
    }
}

private extension FlightPlanInterpreter {
    /// Generates FlightPlan from MAVLink file at given URL or MAVLink string.
    ///
    /// - Parameters:
    ///    - url: url of MAVLink file to parse
    ///    - mavlinkString: MAVLink string to parse
    ///    - flightPlan: the existing flight plan.
    ///
    /// - Returns: generated `FlightPlanModel` is operation succeeded, `nil` otherwise
    func generateFlightPlanFromMavlink(url: URL? = nil,
                                       mavlinkString: String? = nil,
                                       flightPlan: FlightPlanModel?) -> FlightPlanModel? {
        guard let flightPlan = flightPlan else { return nil }
        switch self {
        case .legacy:
            return MavlinkToFlightPlanParser.generateFlightPlanFromMavlinkLegacy(url: url,
                                                                                 mavlinkString: mavlinkString,
                                                                                 flightPlan: flightPlan)
        case .standard:
            return MavlinkToFlightPlanParser.generateFlightPlanFromMavlinkStandard(url: url,
                                                                                   mavlinkString: mavlinkString,
                                                                                   flightPlan: flightPlan)
        }
    }
}
