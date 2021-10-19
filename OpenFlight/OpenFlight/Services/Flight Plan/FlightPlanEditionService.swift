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

import Combine
import ArcGIS
import GroundSdk

// TODO appendUndoStack à private
// TODO state machine
public protocol FlightPlanEditionService {

    // MARK: - Read
    var canUpdatePolygon: Bool { get set }
    /// Value of waypoint orientation edition
    var wayPointOrientationEditionValue: Bool { get }
    /// WayPoint orientation edition state
    var wayPointOrientationEditionPublisher: AnyPublisher<Bool, Never> { get }

    /// Current flight plan publisher
    var currentFlightPlanPublisher: AnyPublisher<FlightPlanModel?, Never> { get }

    /// Current flight plan
    var currentFlightPlanValue: FlightPlanModel? { get }

    /// Can undo.
    func canUndo() -> Bool

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

    /// Reset undo stack.
    func resetUndoStack()

    // MARK: - Commands

    /// - Parameters:
    ///    - mapPoint: location of the new waypoint
    ///    - index: index at which waypoint should be inserted
    /// - Returns: new waypoint, nil if index is invalid
    func insertWayPoint(with mapPoint: AGSPoint, at index: Int) -> WayPoint?

    /// Add flight plan in the undo stack.
    ///
    /// - Parameters:
    ///     - setting: flight plan data setting to backup at some moment
    func appendUndoStack(with dataSetting: FlightPlanDataSetting?)

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
    func updateCurrentFlightPlan(type: String)

    /// Removes waypoint at given index.
    ///
    /// - Parameters:
    ///    - index: waypoint index
    /// - Returns: removed waypoint, if any
    @discardableResult
    func removeWaypoint(at index: Int) -> WayPoint?

    /// Undo.
    func undo()

    /// Starts waypoint orientation edition.
    func startWayPointOrientationEdition()

    /// Stops waypoint orientation edition.
    func stopWayPointOrientationEdition()

    /// Resets current thumbnail to request new one
    func resetThumbnail(completion: @escaping (Bool) -> Void)

    /// Change Flight Plan settings.
    ///
    /// - Parameters:
    ///    - settings: new settings
    func updateSettings(_ settings: [FlightPlanLightSetting])

    // MARK: - Public Funcs
    /// Sets up global continue mode.
    ///
    /// - Parameters:
    ///    - shouldContinue: whether global continue mode should be activated
    func setShouldContinue(_ shouldContinue: Bool)

    /// Sets up return to home on last point setting.
    ///
    /// - Parameters:
    ///    - lastPointRth: whether drone should land on last waypoint
    func setLastPointRth(_ lastPointRth: Bool)

    func setShouldObstacleAvoidance(_ obstacle: Bool)

    func endEdition()

    func rename(_ flightPlan: FlightPlanModel, title: String)

    func freeSettingDidChange(key: String, value: String)

    // MARK: TODO move this somewhere relevant
    /// Updates current Flight Plan with new Mavlink.
    ///
    /// - Parameters:
    ///     - url: Mavlink url
    ///     - type: Flight Plan type
    ///     - createCopy: To force create copy
    ///     - settings: Flight plan settings
    ///     - polygonPoints: List of polygon points
    func updateCurrentFlightPlanWithMavlink(url: URL,
                                            type: FlightPlanType,
                                            settings: [FlightPlanLightSetting],
                                            polygonPoints: [PolygonPoint]?)
}

public class FlightPlanEditionServiceImpl {

    private var undoStack: [String] = []
    private let requester: FlightPlanThumbnailRequester = FlightPlanThumbnailRequester()
    private let repo: FlightPlanRepository
    private let typeStore: FlightPlanTypeStore
    private let currentMissionManager: CurrentMissionManager
    private let currentUser: UserInformation

    public var canUpdatePolygon: Bool = true
    private var currentFlightPlanSubject = CurrentValueSubject<FlightPlanModel?, Never>(nil)
    private var currentFlightPlan: FlightPlanModel? {
        get {
            currentFlightPlanSubject.value
        }
        set {
            let oldValue = currentFlightPlanSubject.value
            currentFlightPlanSubject.send(newValue)
            canUpdatePolygon = true
            if currentFlightPlan?.uuid != oldValue?.uuid {
                resetUndoStack()
            }
            if var flightPlan = newValue {
                flightPlan.lastUpdate = Date()
                repo.persist(flightPlan, true)
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

    public var wayPointOrientationEditionValue: Bool {
        wayPointOrientationEdition
    }

    public var wayPointOrientationEditionPublisher: AnyPublisher<Bool, Never> {
        $wayPointOrientationEdition.eraseToAnyPublisher()
    }

    public var currentFlightPlanValue: FlightPlanModel? {
        currentFlightPlan
    }

    public var currentFlightPlanPublisher: AnyPublisher<FlightPlanModel?, Never> {
        currentFlightPlanSubject.eraseToAnyPublisher()
    }

    /// Starts waypoint orientation edition.
    public func startWayPointOrientationEdition() {
        self.wayPointOrientationEdition = true
    }

    /// Stops waypoint orientation edition.
    public func stopWayPointOrientationEdition() {
        self.wayPointOrientationEdition = false
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
        self.currentFlightPlan = flightPlan
    }

    public func setShouldObstacleAvoidance(_ obstacle: Bool) {
        guard let flightPlan = currentFlightPlan else { return }
        flightPlan.dataSetting?.obstacleAvoidanceActivated = obstacle
        updateGlobalSettings(with: flightPlan.dataSetting)
        // Just triggering
        currentFlightPlan = flightPlan
    }

    public func setShouldContinue(_ shouldContinue: Bool) {
        guard let flightPlan = currentFlightPlan else { return }
        flightPlan.dataSetting?.shouldContinue = shouldContinue
        // FIXME: for now, specific continue mode for each segment is not supported.
        flightPlan.dataSetting?.wayPoints.forEach { $0.shouldContinue = shouldContinue }
        updateGlobalSettings(with: flightPlan.dataSetting)
        // Just triggering
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

    /// Clear all waypoints and points of interest.
    public func clearPoints() {
        let flightPlan = currentFlightPlan
        flightPlan?.dataSetting?.wayPoints.removeAll()
        flightPlan?.dataSetting?.pois.removeAll()
        currentFlightPlan = flightPlan
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
        let polygonPoints: [PolygonPoint] = points.map({
            return PolygonPoint(coordinate: $0.toCLLocationCoordinate2D())
        })
        guard let flightPlan = currentFlightPlan else { return }
        flightPlan.dataSetting?.polygonPoints = polygonPoints
        repo.persist(flightPlan, true)
        // Don't trigger currentFlightPlan change because it would loop recursively with the mapVC that is responsible for the points update
    }
}

extension  FlightPlanEditionServiceImpl: FlightPlanEditionService {
    public func appendUndoStack(with dataSetting: FlightPlanDataSetting?) {
        guard let dataSetting = dataSetting?.toJSONString() else { return }

        // Store flight plan as data to make a copy.
        // FlightPlan's currentFlightPlan must not point on undo stack.
        if undoStack.count >= Constants.maximumUndoStack {
            undoStack.removeFirst()
        }

        undoStack.append(dataSetting)
    }

    // MARK: - Private Enums
    private enum Constants {
        // Maximum items in undo stack.
        static let maximumUndoStack: Int = 30
    }

    public func updateCurrentFlightPlan(type: String) {
        guard var flightPlan = currentFlightPlan else { return }
        flightPlan.type = type
        currentFlightPlan = flightPlan
        resetUndoStack()
    }

    /// Reset undo stack.
    public  func resetUndoStack() {
        undoStack.removeAll()
        appendUndoStack(with: currentFlightPlan?.dataSetting)
    }

    /// Can undo.
    public func canUndo() -> Bool {
        return undoStack.count > 1
    }

    /// Undo.
    public func undo() {
        guard canUndo() else { return }

        // get setting from last and apply them.
        let oldDataSetting = FlightPlanDataSetting.instantiate(with: undoStack.last)
        // Dump last.
        undoStack.removeLast()

        // Restore flight plan from data to make another copy.
        // FlightPlan's currentFlightPlan must not point on undo stack.
        if var dataSetting = FlightPlanDataSetting.instantiate(with: undoStack.last),
           let flighType = typeStore.typeForKey(currentFlightPlan?.type) {
            // copying all the settings from last in undostack
            if let oldDataSetting = oldDataSetting {
                // copy settings of the deleted flight plan in the new one.
                dataSetting = copySettings(oldDataSetting: oldDataSetting, actualDataSetting: dataSetting)

                // replace flight plan in stack.
                undoStack.removeLast()
                if let string = dataSetting.toJSONString() {
                    undoStack.append(string)
                }
            }
            var flightplan = currentFlightPlan
            flightplan?.dataSetting = dataSetting
            currentFlightPlan = flightplan
        }
    }

    /// Copy settings from an old flight plan to another one.
    ///
    /// - Parameters:
    ///     - oldFlightPlan: flight plan  to copy.
    ///     - flightPlan: flight plan  to update.
    /// - Returns flight plan updated.
    private func copySettings(oldDataSetting: FlightPlanDataSetting, actualDataSetting: FlightPlanDataSetting) -> FlightPlanDataSetting {
        let newSetting = actualDataSetting
        newSetting.isBuckled = oldDataSetting.isBuckled
        newSetting.shouldContinue = oldDataSetting.shouldContinue
        newSetting.lastPointRth = oldDataSetting.lastPointRth
        newSetting.captureMode = oldDataSetting.captureMode
        newSetting.captureSettings = oldDataSetting.captureSettings

        newSetting.captureModeEnum = oldDataSetting.captureModeEnum
        newSetting.resolution = oldDataSetting.resolution
        newSetting.whiteBalanceMode = oldDataSetting.whiteBalanceMode
        newSetting.framerate = oldDataSetting.framerate
        newSetting.photoResolution = oldDataSetting.photoResolution
        newSetting.exposure = oldDataSetting.exposure

        newSetting.timeLapseCycle = oldDataSetting.timeLapseCycle
        newSetting.gpsLapseDistance = oldDataSetting.gpsLapseDistance
        newSetting.obstacleAvoidanceActivated = oldDataSetting.obstacleAvoidanceActivated
        newSetting.settings = oldDataSetting.settings
        newSetting.freeSettings = oldDataSetting.freeSettings

        newSetting.disablePhotoSignature = oldDataSetting.disablePhotoSignature
        return newSetting
    }

    /// Update only global settings of current flight plan and replace it in stack
    ///
    /// - Parameters:
    ///     - flightPlan: flight plan  to update.
    public func updateGlobalSettings(with dataSetting: FlightPlanDataSetting?) {
        guard let dataSetting = dataSetting?.toJSONString() else { return }
        if !undoStack.isEmpty {
            undoStack.removeLast()
        }
        undoStack.append(dataSetting)
    }

    public func resetThumbnail(completion: @escaping (Bool) -> Void) {
        updateThumbnail(completion: completion)
    }

    private func updateThumbnail(completion: @escaping (Bool) -> Void) {
        guard let flightPlan = currentFlightPlan else { completion(false) ; return }
        requester.requestThumbnail(flightPlan: flightPlan, thumbnailSize: FlightViewModelConstants.thumbnailSize) { [weak self] thumbnail in
            // Ensure the service is still on the same plan
            // Also make sure we save the up to date plan and not the parameter one that may have change since
            guard let currentUser = self?.currentUser,
                  var upToDateFlightPlan = self?.currentFlightPlan,
                  upToDateFlightPlan.uuid == flightPlan.uuid else { return }
            let thumbnail: UIImage? = thumbnail
            let uuid = upToDateFlightPlan.thumbnailUuid ?? UUID().uuidString
            upToDateFlightPlan.thumbnail = ThumbnailModel(apcId: currentUser.apcId,
                                                          uuid: uuid,
                                                          thumbnailImage: thumbnail)
            upToDateFlightPlan.thumbnailUuid = uuid
            self?.repo.persist(upToDateFlightPlan, true)
            self?.currentFlightPlan = upToDateFlightPlan
            completion(true)
        }
    }

    /// Change Flight Plan settings.
    ///
    /// - Parameters:
    ///    - settings: new settings
    public func updateSettings(_ settings: [FlightPlanLightSetting]) {
        let flightPlan = currentFlightPlan
        flightPlan?.dataSetting?.settings = settings
        currentFlightPlan = flightPlan
    }

    /// Change Flight Plan type.
    ///
    /// - Parameters:
    ///    - typeKey: new type key
    public func updateType(_ typeKey: String?, flightPlanTypeStore: FlightPlanTypeStore) {
        var flightPlan = currentFlightPlan
        guard
            let typeKey = typeKey,
            flightPlan?.type != typeKey
        else { return }

        flightPlan?.type = typeKey

        flightPlan?.dataSetting?.mavlinkDataFile = nil

        currentFlightPlan = flightPlan
    }

    public func clearFlightPlan() {
        let flightPlan = currentFlightPlan
        flightPlan?.dataSetting?.wayPoints.removeAll()
        flightPlan?.dataSetting?.pois.removeAll()
        flightPlan?.dataSetting?.mavlinkDataFile = nil
        currentFlightPlan = flightPlan
    }

    public func resetFlightPlan() {
        currentFlightPlan = nil
    }

    public func endEdition() {
        guard let flightPlan = currentFlightPlan else { return }
        currentMissionManager.mode.stateMachine?.flightPlanWasEdited(flightPlan: flightPlan)
        // Hack to make the map reload the FP properly in some cases
        currentFlightPlan = nil
        currentFlightPlan = flightPlan
    }

    public func rename(_ flightPlan: FlightPlanModel, title: String) {
        var flightPlan = flightPlan
        flightPlan.customTitle = title
        repo.persist(flightPlan, true)
        if flightPlan.uuid == currentFlightPlan?.uuid {
            currentFlightPlan?.customTitle = title
        }
    }

    public func updateCurrentFlightPlanWithMavlink(url: URL,
                                                   type: FlightPlanType,
                                                   settings: [FlightPlanLightSetting],
                                                   polygonPoints: [PolygonPoint]? = nil) {
        guard let currentFP = currentFlightPlan else {
            // Create new FP.
            
            // Generate flightPlanData from mavlink.
            var flightPlanData: FlightPlanModel?
            if let currentFlightPlan = currentFlightPlan, let data = try? Data(contentsOf: url) {
                flightPlanData = type.mavLinkType.generateFlightPlanFromMavlink(
                    url: url,
                    mavlinkString: nil,
                    flightPlan: currentFlightPlan)
                // Save Mavlink into the intended Mavlink url if needed.
                if let flightPlan = flightPlanData, !type.canGenerateMavlink {
                    flightPlan.dataSetting?.mavlinkDataFile = data
                    repo.persist(flightPlan, true)
                }
            }
            currentFlightPlan = flightPlanData
            canUpdatePolygon = false
            return
        }
        
        // Generate flightPlanData from mavlink.
        let flightPlanData = type.mavLinkType.generateFlightPlanFromMavlink(url: url,
                                                                            mavlinkString: nil,
                                                                            flightPlan: currentFP)
        // Save Mavlink into the intended Mavlink url if needed.
        if !type.canGenerateMavlink,
           let flightPlan = flightPlanData,
           let data = try? Data(contentsOf: url) {
            flightPlan.dataSetting?.mavlinkDataFile = data
            repo.persist(flightPlan, true)
        }

        // Backup OA settings.
        flightPlanData?.dataSetting?.obstacleAvoidanceActivated = currentFP.dataSetting?.obstacleAvoidanceActivated ?? true

        // Backup capture settings.
        let captureSettings = currentFP.dataSetting?.captureSettings
        flightPlanData?.dataSetting?.captureSettings = captureSettings

        // Update flight plan view model points.
        // TODO why update points ?
//        flightPlanData?.points = flightPlanData?.dataSetting?.wayPoints.compactMap({ $0.coordinate }) ?? []

        // Update FP data.
        currentFlightPlan = flightPlanData
        canUpdatePolygon = false
    }

    public func freeSettingDidChange(key: String, value: String) {
        currentFlightPlan?.dataSetting?.freeSettings[key] = value
    }
}

private extension FlightPlanInterpreter {
    /// Generates FlightPlan from MAVLink file at given URL or MAVLink string.
    ///
    /// - Parameters:
    ///    - url: url of MAVLink file to parse
    ///    - mavlinkString: MAVLink string to parse
    ///    - title: title of FlightPlan to generate
    ///    - type: Flight Plan type
    ///    - uuid: Flight Plan ID
    ///    - settings: Flight Plan settings
    ///    - polygonPoints:Flight Plan polygon points
    ///    - version: version of FlightPlan
    ///    - model: model of drone for generated FlightPlan
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
