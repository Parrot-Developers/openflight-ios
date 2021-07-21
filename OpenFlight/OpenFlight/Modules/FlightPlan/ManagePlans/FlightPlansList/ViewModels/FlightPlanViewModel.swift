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

import UIKit
import CoreLocation
import ArcGIS

// MARK: - GraphicTapListener
/// Listener for ArcGIS graphic taps from map.
final class GraphicTapListener: NSObject {
    let didChange: GraphicTapListenerClosure

    init(didChange: @escaping GraphicTapListenerClosure) {
        self.didChange = didChange
    }
}

/// Alias for `GraphicTapListener` closure.
typealias GraphicTapListenerClosure = (FlightPlanGraphic?) -> Void

// MARK: - FlightPlanCourseModificationListener
/// Listener for Flight Plan's course modification.
final class FlightPlanCourseModificationListener: NSObject {
    let didChange: () -> Void

    init(didChange: @escaping () -> Void) {
        self.didChange = didChange
    }
}

// MARK: - FlightPlanPointOfViewModificationListener
/// Listener for Flight Plan's POI and waypoint orientation modification.
final class FlightPlanPointOfViewModificationListener: NSObject {
    let didChange: () -> Void

    init(didChange: @escaping () -> Void) {
        self.didChange = didChange
    }
}

// MARK: - FlightPlanState
/// State for `FlightPlanViewModel`.
public class FlightPlanState: ViewModelState, EquatableState, Copying, FlightStateProtocol {
    // MARK: - Internal Properties
    /// Flight Plan uuid.
    public fileprivate(set) var uuid: String?
    /// Flight Plan title.
    public fileprivate(set) var title: String?
    /// Flight Plan custom type.
    public fileprivate(set) var type: FlightPlanType?
    /// Flight Plan date.
    fileprivate(set) var date: Date?
    /// Flight Plan last modification date.
    public fileprivate(set) var lastModified: Date?
    /// Flight Plan location.
    fileprivate(set) var location: CLLocationCoordinate2D?
    /// Flight Plan thumbnail.
    fileprivate(set) var thumbnail: UIImage?
    /// Flight Plan settings.
    fileprivate(set) var settings: [FlightPlanLightSetting] = []
    /// Flight Plan polygon points.
    fileprivate(set) var polygonPoints: [PolygonPoint] = []
    /// Observable for Flight Plan's waypoint orientation edition.
    fileprivate(set) var wayPointOrientationEditionObservable: Observable<Bool> = Observable(false)

    // MARK: - Public Properties
    public var cloudStatus: String?
    public var savedFlightPlan: SavedFlightPlan? {
        guard let uuid = self.uuid else { return nil }

        return CoreDataManager.shared.savedFlightPlan(for: uuid)
    }

    // MARK: - Init
    public required init() { }

    /// Init.
    ///
    /// - Parameters:
    ///    - title: Flight Plan title
    ///    - type: Flight Plan type
    ///    - uuid: Flight Plan uuid
    ///    - date: Flight Plan date
    ///    - lastModified: Flight Plan last modification date
    ///    - location: Flight Plan location
    ///    - thumbnail: Flight Plan thumbnail
    ///    - settings: Flight Plan settings
    ///    - polygonPoints: Flight Plan polygon points
    init(title: String?,
         type: FlightPlanType?,
         uuid: String?,
         date: Date?,
         lastModified: Date?,
         location: CLLocationCoordinate2D?,
         thumbnail: UIImage?,
         settings: [FlightPlanLightSetting] = [],
         polygonPoints: [PolygonPoint] = []) {
        self.uuid = uuid
        self.title = title
        self.type = type
        self.date = date
        self.lastModified = lastModified
        self.location = location
        self.thumbnail = thumbnail
        self.settings = settings
        self.polygonPoints = polygonPoints
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - flightPlan: Flight Plan object
    ///    - type: Flight Plan type
    public init(flightPlan: SavedFlightPlan, type: FlightPlanType) {
        self.uuid = flightPlan.uuid
        self.title = flightPlan.title
        self.type = type
        self.date = flightPlan.savedDate
        self.lastModified = flightPlan.lastModifiedDate
        self.location = flightPlan.coordinate
        self.settings = flightPlan.settings
        self.polygonPoints = flightPlan.polygonPoints
    }

    // MARK: - Public Funcs
    /// Returns updated Flight Plan state.
    ///
    /// - Parameters:
    ///    - flightPlan: Flight Plan object
    ///    - type: Flight Plan type
    /// - Returns: copy of self, updated.
    func updated(flightPlan: SavedFlightPlan, type: FlightPlanType) -> FlightPlanState {
        let copy = self.copy()
        copy.uuid = flightPlan.uuid
        copy.title = flightPlan.title
        copy.type = type
        copy.date = flightPlan.savedDate
        copy.lastModified = flightPlan.lastModifiedDate
        copy.location = flightPlan.coordinate
        copy.settings = flightPlan.settings
        copy.polygonPoints = flightPlan.polygonPoints
        return copy
    }

    // MARK: - Equatable
    public func isEqual(to other: FlightPlanState) -> Bool {
        return location == other.location
            && thumbnail == other.thumbnail
            && title == other.title
            && type?.key == other.type?.key
            && date == other.date
            && lastModified == other.lastModified
            && uuid == other.uuid
            && cloudStatus == other.cloudStatus
            && settings == other.settings
            && polygonPoints == other.polygonPoints
    }

    // MARK: - Copying
    public func copy() -> Self {
        if let copy = FlightPlanState() as? Self {
            copy.title = title
            copy.type = type
            copy.date = date
            copy.lastModified = lastModified
            copy.thumbnail = thumbnail
            copy.location = location
            copy.uuid = uuid
            copy.cloudStatus = cloudStatus
            copy.settings = settings
            copy.polygonPoints = polygonPoints
            return copy
        } else {
            fatalError("Must override")
        }
    }
}

// MARK: - FlightPlanViewModel
/// View model for Flight Plan.
public class FlightPlanViewModel: BaseViewModel<FlightPlanState>, FlightViewModelProtocol {
    // MARK: - Public Properties
    /// Returns full flight plan object.
    /// Prefer use state values as much as possible intead of this object.
    public lazy var flightPlan: SavedFlightPlan? = {
        // Get persisted data if needed.
        guard let uuid = self.state.value.uuid,
              let persistedFlightPlan = CoreDataManager.shared.savedFlightPlan(for: uuid),
              let type = flightPlanTypeStore.typeForKey(persistedFlightPlan.type) else {
            return nil
        }

        points = persistedFlightPlan.plan.wayPoints.compactMap({ $0.coordinate })
        let state = self.state.value.updated(flightPlan: persistedFlightPlan, type: type)
        // Set state to update content if needed.
        self.state.set(state)

        return persistedFlightPlan
    }()

    lazy var runFlightPlanViewModel: RunFlightPlanViewModel = {
        hasRunViewModel = true
        let runFlightPlanViewModel = RunFlightPlanViewModel(flightPlanViewModel: self)
        runFlightPlanViewModel.state.valueChanged = { [weak self] state in
            self?.runFlightPlanListeners.forEach { $0.didChange(state) }
        }

        return runFlightPlanViewModel
    }()

    // MARK: - FlightViewModelProtocol Properties
    public var location: CLLocationCoordinate2D? {
        return self.state.value.location
    }

    var shouldRequestThumbnail: Bool {
        guard self.state.value.thumbnail == nil else { return false }

        // Update points to make the thumbnail with the right values.
        points = flightPlan?.plan.wayPoints.compactMap({ $0.coordinate }) ?? []

        return true
    }

    var shouldRequestPlacemark: Bool {
        guard self.state.value.title == nil else { return false }

        return true
    }

    var points: [CLLocationCoordinate2D] = []

    var isEmpty: Bool {
        return self.state.value.polygonPoints.isEmpty && points.isEmpty
    }

    public var executions: [FlightPlanExecution] {
        guard let flightPlanId = self.state.value.uuid else { return [] }

        return CoreDataManager.shared.executions(forFlightplanIds: [flightPlanId])
    }

    /// Flight Plan estimations.
    /// Updated only on init and after explicit user's save to prevent form useless extra computing.
    public var estimations = FlightPlanEstimationsModel()

    // MARK: - Private Properties
    // Prevent from useless RunViewModel extra use.
    private var hasRunViewModel: Bool = false
    private var runFlightPlanListeners: Set<RunFlightPlanListener> = []
    private var graphicTapListeners: Set<GraphicTapListener> = []
    private var courseModificationListeners: Set<FlightPlanCourseModificationListener> = []
    private var povModificationListeners: Set<FlightPlanPointOfViewModificationListener> = []
    private unowned var flightPlanTypeStore: FlightPlanTypeStore

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///     - flightPlan: Flight Plan object
    public init(flightPlan: SavedFlightPlan?) {
        // TODO wrong injection
        self.flightPlanTypeStore = Services.hub.flightPlanTypeStore
        super.init()

        if let data = flightPlan,
           let type = flightPlanTypeStore.typeForKey(data.type) {
            self.flightPlan = data
            self.state.set(FlightPlanState(flightPlan: data, type: type))
        }
        updateEstimations()
    }

    /// Init.
    ///
    /// - Parameters:
    ///     - state: Flight Plan state
    public init(state: FlightPlanState) {
        // TODO wrong injection
        self.flightPlanTypeStore = Services.hub.flightPlanTypeStore
        super.init()

        self.state.set(state)
        updateEstimations()
    }

    // MARK: - Public Funcs
    /// Persist flight plan.
    ///
    /// - Parameters:
    ///     - copy: Optional Flight Plan state
    public func save(_ copy: FlightPlanState? = nil) {
        let now = Date()
        // Save date in file.
        flightPlan?.savedDate = now
        flightPlan?.lastModifiedDate = now

        // Update points so open map stays accurate.
        points = flightPlan?.plan.wayPoints.compactMap({ $0.coordinate }) ?? []

        // Save date in state.
        let finalCopy: FlightPlanState = copy ?? self.state.value.copy()
        finalCopy.date = now
        finalCopy.lastModified = now
        self.state.set(finalCopy)
        // Save Flight Plan.
        CoreDataManager.shared.saveOrUpdate(state: self.state.value, flightPlan: self.flightPlan)
        if hasRunViewModel {
            // Reset MAVLink commands on Flight Plan update.
            runFlightPlanViewModel.resetMavlinkCommands()
        }
    }

    /// Set Flight Plan as last used.
    public func setAsLastUsed() {
        save()
    }

    /// Tells if flight Plan should be cleared.
    public func shouldClearFlightPlan() -> Bool {
        return self.flightPlan?.plan.wayPoints.isEmpty == false ||
            self.flightPlan?.plan.pois.isEmpty == false
    }

    /// Clears Flight Plan, removing MAVLink file if
    /// any and deleting all waypoints and points of interest.
    ///
    /// - Note: calling this preserves uuid & settings.
    public func clearFlightPlan() {
        self.flightPlan?.plan.clearPoints()

        if let mavlinkPath = self.flightPlan?.mavlinkDefaultUrl?.path,
           FileManager.default.fileExists(atPath: mavlinkPath) {
            try? FileManager.default.removeItem(atPath: mavlinkPath)
        }
    }

    /// Add or update flight plan execution.
    ///
    /// - Parameters:
    ///    - execution: flight plan execution
    public func saveExecution(_ execution: FlightPlanExecution) {
        guard execution.flightId != nil else {
            return
        }

        CoreDataManager.shared.saveOrUpdate(execution: execution)
    }

    /// Deletes flight plan executions.
    func deleteExecutions() {
        CoreDataManager.shared.delete(executions: self.executions)
    }

    /// Resumes flight plan execution.
    ///
    /// - Parameters:
    ///    - execution: flight plan execution
    /// - Returns: if resume will happen or not.
    func resumeExecution(_ execution: FlightPlanExecution) -> Bool {
        guard execution.flightPlanId == state.value.uuid else { return false }

        return runFlightPlanViewModel.resume(execution)
    }

    /// Update the polygon points for the current flight plan.
    ///
    /// - Parameters:
    ///     - points: Polygon points
    public func updatePolygonPoints(points: [AGSPoint]) {
        let polygonPoints: [PolygonPoint] = points.map({
            return PolygonPoint(coordinate: $0.toCLLocationCoordinate2D())
        })

        self.flightPlan?.polygonPoints = polygonPoints
        let copy = self.state.value.copy()
        copy.polygonPoints = polygonPoints
        self.save(copy)
        didChangeCourse()
    }

    /// Update Flight Plan Extra Data.
    func updateFlightPlanExtraData(/*_ flightPlan: SavedFlightPlan*/) {
        // TODO: to be continued + Check if changed else return.

        // Update estimations.
        updateEstimations()

        // Reset thumbnail.
        let copy = self.state.value.copy()
        copy.thumbnail = nil
        save(copy)
    }

    /// Update estimations.
    func updateEstimations() {
        self.estimations = flightPlan?.plan.estimations ?? FlightPlanEstimationsModel()
    }

    /// Remove Flight Plan.
    func removeFlightPlan() {
        if let uuid = self.state.value.uuid {
            // Remote remove if exists.
            if let flightPlanId = flightPlan?.remoteFlightPlanId,
               let account = AccountManager.shared.currentAccount {
                account.removeSynchronizedFlightPlan(flightPlanId: flightPlanId,
                                                     completion: { _, _ in })
            }
            // Local remove, regardless of the sync result to prevent from network issues.
            CoreDataManager.shared.removeFlightPlans(for: [uuid])
        }
    }

    // MARK: - FlightViewModelProtocol
    /// Update thumbnail.
    ///
    /// - Parameters:
    ///     - image: new thumbnail image
    func updateThumbnail(_ image: UIImage?) {
        DispatchQueue.main.async { [weak self] in
            // Update DispatchQueue to be sure the UI will be updated in main thread.
            guard let strongSelf = self,
                  let image = image else { return }

            let copy = strongSelf.state.value.copy()
            copy.thumbnail = image
            strongSelf.state.set(copy)

            // Use dedicated method to persist thumbnail.
            // Do not use save() method because flight plan date should not be changed
            // to prevent from flight plan list display mess.
            CoreDataManager.shared.saveThumbnail(state: strongSelf.state.value)
        }
    }

    /// Update placemark.
    ///
    /// - Parameters:
    ///     - placemark: new placemark
    func updatePlacemark(_ placemark: CLPlacemark?) {
        guard self.state.value.title == nil,
              let addressDescription = placemark?.addressDescription
        else { return }
        rename(addressDescription)
    }

    /// Change Flight Plan type.
    ///
    /// - Parameters:
    ///    - typeKey: new type key
    public func updateType(_ typeKey: String?) {
        guard self.state.value.type?.key != typeKey, let type = flightPlanTypeStore.typeForKey(typeKey) else { return }

        flightPlan?.type = typeKey
        let copy = self.state.value.copy()
        copy.type = type

        // Clear points from Flight Plan to avoid issues if
        // new type doesn't trigger a generation immediately.
        clearFlightPlan()

        self.save(copy)
    }

    /// Change Flight Plan settings.
    ///
    /// - Parameters:
    ///    - settings: new settings
    public func updateSettings(_ settings: [FlightPlanLightSetting]) {
        flightPlan?.settings = settings
        let copy = self.state.value.copy()
        copy.settings = settings
        self.save(copy)
    }

    /// Notifies listeners when a tap on a selected graphic occurs.
    ///
    /// - Parameters:
    ///    - item: item to select
    func didTapGraphicalItem(_ item: FlightPlanGraphic?) {
        self.graphicTapListeners.forEach { $0.didChange(item) }
    }

    /// Notifies listeners when Flight Plan's course is modified.
    func didChangeCourse() {
        self.courseModificationListeners.forEach { $0.didChange() }
    }

    /// Notifies listeners when a Flight Plan's point of view is modified.
    func didChangePointOfView() {
        self.povModificationListeners.forEach { $0.didChange() }
    }

    /// Starts waypoint orientation edition.
    func startWayPointOrientationEdition() {
        self.state.value.wayPointOrientationEditionObservable.set(true)
    }

    /// Stops waypoint orientation edition.
    func stopWayPointOrientationEdition() {
        self.state.value.wayPointOrientationEditionObservable.set(false)
    }

    /// Renames Flight Plan.
    ///
    /// - Parameters:
    ///    - newName: new name
    func rename(_ newName: String) {
        if newName.isEmpty == false,
           self.state.value.title != newName {
            flightPlan?.title = newName
            let copy = self.state.value.copy()
            copy.title = newName
            self.save(copy)
        }
    }
}

// MARK: - RunFlightPlanListeners
extension FlightPlanViewModel {
    /// Registers a listener for `RunFlightPlanViewModel`.
    ///
    /// - Parameters:
    ///    - didChange: listener's closure
    /// - Returns: registered listener
    func registerRunListener(didChange: @escaping RunFlightPlanListenerClosure) -> RunFlightPlanListener {
        let listener = RunFlightPlanListener(didChange: didChange)
        runFlightPlanListeners.insert(listener)
        // Initial notification.
        listener.didChange(runFlightPlanViewModel.state.value)
        return listener
    }

    /// Removes previously registered `RunFlightPlanListener`.
    ///
    /// - Parameters:
    ///    - listener: listener to remove
    func unregisterRunListener(_ listener: RunFlightPlanListener?) {
        guard let listener = listener else { return }

        self.runFlightPlanListeners.remove(listener)
    }
}

// MARK: - GraphicTapListeners
extension FlightPlanViewModel {
    /// Registers a listener for graphic selection.
    ///
    /// - Parameters:
    ///    - didChange: listener's closure
    /// - Returns: registered listener
    func registerGraphicTapListener(didChange: @escaping GraphicTapListenerClosure) -> GraphicTapListener {
        let listener = GraphicTapListener(didChange: didChange)
        graphicTapListeners.insert(listener)

        return listener
    }

    /// Removes previously registered `RunFlightPlanListener`.
    ///
    /// - Parameters:
    ///    - listener: listener to remove
    func unregisterGraphicTapListener(_ listener: GraphicTapListener?) {
        guard let listener = listener else { return }

        self.graphicTapListeners.remove(listener)
    }
}

// MARK: - FlightPlanCourseModificationListeners
extension FlightPlanViewModel {
    /// Registers a listener for course modification.
    ///
    /// - Parameters:
    ///    - didChange: listener's closure
    /// - Returns: registered listener
    func registerCourseModificationListener(didChange: @escaping () -> Void) -> FlightPlanCourseModificationListener {
        let listener = FlightPlanCourseModificationListener(didChange: didChange)
        courseModificationListeners.insert(listener)

        return listener
    }

    /// Removes previously registered `FlightPlanCourseModificationListener`.
    ///
    /// - Parameters:
    ///    - listener: listener to remove
    func unregisterCourseModificationListener(_ listener: FlightPlanCourseModificationListener?) {
        guard let listener = listener else { return }

        self.courseModificationListeners.remove(listener)
    }
}

// MARK: - FlightPlanPOIModificationListeners
extension FlightPlanViewModel {
    /// Registers a listener for point of view modification.
    ///
    /// - Parameters:
    ///    - didChange: listener's closure
    /// - Returns: registered listener
    func registerPOVModificationListener(didChange: @escaping () -> Void) -> FlightPlanPointOfViewModificationListener {
        let listener = FlightPlanPointOfViewModificationListener(didChange: didChange)
        povModificationListeners.insert(listener)

        return listener
    }

    /// Removes previously registered `FlightPlanPointOfViewModificationListener`.
    ///
    /// - Parameters:
    ///    - listener: listener to remove
    func unregisterPOVModificationListener(_ listener: FlightPlanPointOfViewModificationListener?) {
        guard let listener = listener else { return }

        self.povModificationListeners.remove(listener)
    }
}
