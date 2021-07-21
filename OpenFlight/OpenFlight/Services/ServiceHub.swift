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

/// Service hub that presents services through their protocols
///
/// Architecture rules:
/// - View Controllers should never access anything else than their respective View Models
/// - View Models should be injected with service and manager protocols, but never access implementations or this hub
/// - Coordinators are the only one that may be injected with this hub, only when relevant
/// - Services and managers should be injected with service and manager protocols they depend on, this should be done in this hub implementation
/// in most cases
/// - This hub should be instantiated and retained by the app delegate
///
/// While refactoring for this to be possible, we keep a singleton of this hub, but any new code should use proper injection as much as possible
public protocol ServiceHub: AnyObject {

    /// Store of available flight plan types
    var flightPlanTypeStore: FlightPlanTypeStore { get }
    /// Store of available missions
    var missionsStore: MissionsStore { get }
    /// Current mission manager
    var currentMissionManager: CurrentMissionManager { get }
    /// Access to the connected drone if any
    var connectedDroneHolder: ConnectedDroneHolder { get }
    /// Access to the current drone that may or may not be connected or a concrete drone
    var currentDroneHolder: CurrentDroneHolder { get }
    /// OpenFlight wrapper over Obstacle Avoidance peripheral
    var obstacleAvoidanceMonitor: ObstacleAvoidanceMonitor { get }
    /// Access to camera exposure lock feature
    var exposureLockService: ExposureLockService { get }
    /// Access to the current remote control if any
    var currentRemoteControlHolder: CurrentRemoteControlHolder { get }
    /// Access to the connected remote control if any
    var connectedRemoteControlHolder: ConnectedRemoteControlHolder { get }
    /// Access to the active flight plan watcher
    var activeFlightPlanWatcher: ActiveFlightPlanExecutionWatcher { get }
    /// Access to the flight plan camera settings handler
    var flightPlanCameraSettingsHandler: FlightPlanCameraSettingsHandler { get }
    /// Access to locations tracking
    var locationsTracker: LocationsTracker { get }
    /// Access to the Data Repositories
    var repos: Repositories { get }
    /// Access to UI services
    var ui: UIServices { get }
    /// Access to drone peripherals and instruments services
    var drone: DroneServices { get }
}

/// Namespace to present the service hub (until refactor is complete)
public enum Services {
    /// The service hub
    public private(set) static var hub: ServiceHub!

    public static func createInstance(variableAssetsService: VariableAssetsService) {
        hub = ServiceHubImpl(variableAssetsService: variableAssetsService)
    }
}

/// Data Repositories
public struct Repositories {

    public let user: UserRepository
    public let drone: DroneDataRepository
    public let challengeSecure: ChallengeSecureElementRepository
    public let project: ProjectRepository
    public let flight: FlightRepository
    public let flightPlanFlight: FlightPlanFlightsRepository
    public let flightPlan: FlightPlanRepository
    public let thumbnail: ThumbnailRepository
    public let pgyProject: PgyProjectsRepository
}

/// UI services
public struct UIServices {
    /// Joysticks availability service
    let joysticksAvailabilityService: JoysticksAvailabilityService
    /// Variable assets service
    let variableAssetsService: VariableAssetsService
}

/// Drone services (instruments and peripherals related)
public struct DroneServices {
    /// Gimbal zoom service
    let zoomService: ZoomService
    /// Gimbal tilt service
    let gimbalTiltService: GimbalTiltService
}

/// Implementation of the service hub
private class ServiceHubImpl: ServiceHub {

    let flightPlanTypeStore: FlightPlanTypeStore
    let missionsStore: MissionsStore
    let currentMissionManager: CurrentMissionManager
    let connectedDroneHolder: ConnectedDroneHolder
    let currentDroneHolder: CurrentDroneHolder
    let obstacleAvoidanceMonitor: ObstacleAvoidanceMonitor
    let exposureLockService: ExposureLockService
    let currentRemoteControlHolder: CurrentRemoteControlHolder
    let connectedRemoteControlHolder: ConnectedRemoteControlHolder
    let activeFlightPlanWatcher: ActiveFlightPlanExecutionWatcher
    let flightPlanCameraSettingsHandler: FlightPlanCameraSettingsHandler
    let locationsTracker: LocationsTracker
    let repos: Repositories
    let ui: UIServices
    let drone: DroneServices

    /// Legacy drone store, implements some side effects of current drone change
    private let legacyCurrentDroneStore: LegacyCurrentDroneStore

    fileprivate init(variableAssetsService: VariableAssetsService) {

        flightPlanTypeStore = FlightPlanTypeStoreImpl()

        missionsStore = MissionsStoreImpl()

        currentMissionManager = CurrentMissionManagerImpl(store: missionsStore)

        connectedDroneHolder = ConnectedDroneHolderImpl()

        currentDroneHolder = CurrentDroneHolderImpl(connectedDroneHolder: connectedDroneHolder)

        legacyCurrentDroneStore = LegacyCurrentDroneStore(droneHolder: currentDroneHolder,
                                                          currentMissionManager: currentMissionManager)

        connectedRemoteControlHolder = ConnectedRemoteControlHolderImpl()

        currentRemoteControlHolder = CurrentRemoteControlHolderImpl(connectedRemoteControlHolder: connectedRemoteControlHolder)

        // TODO: Rework on Singleton
        let coreDataManager = CoreDataManager.shared
        repos = Repositories(user: coreDataManager,
                             drone: coreDataManager,
                             challengeSecure: coreDataManager,
                             project: coreDataManager,
                             flight: coreDataManager,
                             flightPlanFlight: coreDataManager,
                             flightPlan: coreDataManager,
                             thumbnail: coreDataManager,
                             pgyProject: coreDataManager)

        // TODO change flight plan repository with new model's repository
        activeFlightPlanWatcher = ActiveFlightPlanExecutionWatcherImpl(currentDroneHolder: currentDroneHolder,
                                                                       flightPlanRepository: CoreDataManager.shared,
                                                                       flightPlanExecutionRepository: CoreDataManager.shared)

        obstacleAvoidanceMonitor = ObstacleAvoidanceMonitorImpl(currentDroneHolder: currentDroneHolder,
                                                                activeFlightPlanWatcher: activeFlightPlanWatcher)

        exposureLockService = ExposureLockServiceImpl(currentDroneHolder: currentDroneHolder)

        flightPlanCameraSettingsHandler = FlightPlanCameraSettingsHandlerImpl(activeFlightPlanWatcher: activeFlightPlanWatcher,
                                                                              currentDroneHolder: currentDroneHolder)
        locationsTracker = LocationsTrackerImpl(connectedDroneHolder: connectedDroneHolder,
                                                connectedRcHolder: connectedRemoteControlHolder)
        let joysticksAvailabilityService = JoysticksAvailabilityServiceImpl(currentMissionManager: currentMissionManager,
                                                                            connectedDroneHolder: connectedDroneHolder,
                                                                            connectedRemoteControlHolder: connectedRemoteControlHolder)
        ui = UIServices(joysticksAvailabilityService: joysticksAvailabilityService, variableAssetsService: variableAssetsService)
        let zoomService = ZoomServiceImpl(currentDroneHolder: currentDroneHolder,
                                          activeFlightPlanWatcher: activeFlightPlanWatcher)
        let gimbalTiltService = GimbalTiltServiceImpl(connectedDroneHolder: connectedDroneHolder,
                                                      activeFlightPlanWatcher: activeFlightPlanWatcher)
        drone = DroneServices(zoomService: zoomService, gimbalTiltService: gimbalTiltService)
    }
}
