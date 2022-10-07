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

import CoreData

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

    /// The apc API manager
    var apcApiManager: APCApiManager { get }
    /// User Service
    var userService: UserService { get }
    /// Synchronise API calls
    var apiRequestQueue: ApiRequestQueue { get }
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
    /// OpenFlight wrapper over Return Home Piloting Interface
    var rthSettingsMonitor: RthSettingsMonitor { get }
    /// Access to the current remote control if any
    var currentRemoteControlHolder: CurrentRemoteControlHolder { get }
    /// Access to the connected remote control if any
    var connectedRemoteControlHolder: ConnectedRemoteControlHolder { get }
    /// Manual or automatic update of remote control settings
    var remoteControlUpdater: RemoteControlUpdater { get }
    /// Access to locations tracking
    var locationsTracker: LocationsTracker { get }
    /// Access to the Data Repositories
    var repos: Repositories { get }
    /// Access to UI services
    // swiftlint:disable:next identifier_name
    var ui: UIServices { get }
    /// Access to drone peripherals and instruments services
    var drone: DroneServices { get }
    /// Access to flight plan services
    var flightPlan: FlightPlanServices { get }
    /// Access to flight services
    var flight: FlightServices { get }
    /// Access to Academy API service
    var academyApiService: AcademyApiService { get }
    /// Watch pending synchro process with cloud
    var cloudSynchroWatcher: CloudSynchroWatcher? { get set }
    /// Panorama capture mode service
    var panoramaService: PanoramaService { get }
    /// Touch and fly service
    var touchAndFly: TouchAndFlyService { get }
    /// Update service
    var update: UpdateService { get }
    /// System service
    var systemServices: SystemServices { get }
    /// Banner alert manager service
    var bamService: BannerAlertManagerService { get }
    /// Preset service
    var presetService: PresetsService { get }
    /// Database update service
    var databaseUpdateService: DatabaseUpdateService { get }
    /// Start active services
    func start()
}

/// Namespace to expose the service hub (until refactor is complete)
public enum Services {
    /// The service hub
    public private(set) static var hub: ServiceHub!

    public static func createInstance(variableAssetsService: VariableAssetsService,
                                      persistentContainer: NSPersistentContainer,
                                      missionsToLoadAtStart: [AirSdkMissionSignature],
                                      dashboardUiProvider: DashboardUiProvider) -> ServiceHub {
        hub = ServiceHubImpl(variableAssetsService: variableAssetsService,
                             persistentContainer: persistentContainer,
                             missionsToLoadAtStart: missionsToLoadAtStart,
                             dashboardUiProvider: dashboardUiProvider)
        return hub
    }
}

/// Data Repositories
public struct Repositories {

    public let repoServices: CoreDataService
    public let user: UserRepository
    public let drone: DroneDataRepository
    public let project: ProjectRepository
    public let flight: FlightRepository
    public let flightPlanFlight: FlightPlanFlightsRepository
    public let flightPlan: FlightPlanRepository
    public let thumbnail: ThumbnailRepository
    public let pgyProject: PgyProjectRepository

}

/// UI services
public struct UIServices {
    /// Joysticks availability service
    public let joysticksAvailabilityService: JoysticksAvailabilityService
    /// Variable assets service
    public let variableAssetsService: VariableAssetsService
    /// HUD top bar service
    public let hudTopBarService: HudTopBarService
    public let hudBottomBarService: HudBottomBarService
    /// UI components display reporter
    public let uiComponentsDisplayReporter: UIComponentsDisplayReporter
    /// Flight plan UI state provider
    public var flightPlanUiStateProvider: FlightPlanUiStateProvider
    /// Flight plan execution details settings provider
    public let flightPlanExecutionDetailsSettingsProvider: FlightPlanExecutionDetailsSettingsProvider
    /// Project manager views UI provider
    public let projectManagerUiProvider: ProjectManagerUiProvider
    /// Dashboard UI provider
    public let dashboardUiProvider: DashboardUiProvider
    /// Navigation Stack Service
    public let navigationStack: NavigationStackService
    /// Touch and fly ui service
    public let touchAndFly: TouchAndFlyUiService
    /// Critical alert service
    public let criticalAlert: CriticalAlertService
}

/// Drone services (instruments and peripherals related)
public struct DroneServices {
    /// RTH service
    public let rthService: RthService
    /// Gimbal zoom service
    public let zoomService: ZoomService
    /// Gimbal tilt service
    public let gimbalTiltService: GimbalTiltService
    /// Cellular Service
    public let cellularService: CellularService
    /// Cellular Session Service
    public let cellularSessionService: CellularSessionService
    /// Cellular pairing service
    public let cellularPairingService: CellularPairingService
    /// Cellular pairing availability service
    public let cellularPairingAvailabilityService: CellularPairingAvailabilityService
    /// Camera exposure service
    public let exposureService: ExposureService
    /// Camera exposure lock service
    public let exposureLockService: ExposureLockService
    /// AirSdk mission listener service
    public let airsdkMissionsManager: AirSdkMissionsManager
    /// AirSdk mission manager service
    public let airsdkMissionsListener: AirSdkMissionsListener
    /// Pin code handler
    public let pinCodeService: PinCodeService
    /// Ophtalmo mission service
    let ophtalmoService: OphtalmoService
    /// Camera recording service
    let cameraRecordingService: CameraRecordingService
    /// Camera photo capture service
    let cameraPhotoCaptureService: CameraPhotoCaptureService
    /// Camera configuration watcher.
    let cameraConfigWatcher: CameraConfigWatcher
    /// Gpslapse capture restart service.
    let gpslapseRestartService: GpslapseRestartService
    /// Timelapse capture restart service.
    let timelapseRestartService: TimelapseRestartService
    /// Removable user storage service
    let removableUserStorageService: RemovableUserStorageService
    /// Hand launch service.
    let handLaunchService: HandLaunchService
}

/// Flight plan services
public struct FlightPlanServices {
    /// Access to the project manager
    public var projectManager: ProjectManager
    /// Access to the flight plan manager
    public var manager: FlightPlanManager
    /// Flight plan state machine
    public var stateMachine: FlightPlanStateMachine
    /// Access to the active flight plan watcher
    public var activeFlightPlanWatcher: ActiveFlightPlanExecutionWatcher
    /// Access to the flight plan camera settings handler
    public var cameraSettingsHandler: FlightPlanCameraSettingsHandler
    /// Store of available flight plan types
    public var typeStore: FlightPlanTypeStore
    /// Edition of flight plan
    public var edition: FlightPlanEditionService
    /// Run Manager of flight plan
    public var run: FlightPlanRunManager
    /// Mavlink generator
    public var mavlinkGenerator: MavlinkGenerator
    /// Mavlink sender
    public var mavlinkSender: MavlinkDroneSender
    /// Flight plan start availability watcher
    public var startAvailabilityWatcher: FlightPlanStartAvailabilityWatcher
    /// Flight plan files manager
    public var filesManager: FlightPlanFilesManager
    /// Flight plan recovery information service.
    public var recoveryInfoService: FlightPlanRecoveryInfoService
}

/// Flight services
public struct FlightServices {
    /// Access to gutma watcher
    public let gutmaWatcher: GutmaWatcher
    /// Access to flight service
    public let service: FlightService
}

/// System services
public struct SystemServices {
    /// Access to network service
    public let networkService: NetworkService
}

/// Implementation of the service hub
private class ServiceHubImpl: ServiceHub {
    let apcApiManager: APCApiManager
    let userService: UserService
    let apiRequestQueue: ApiRequestQueue
    let flightPlanTypeStore: FlightPlanTypeStore
    let missionsStore: MissionsStore
    let currentMissionManager: CurrentMissionManager
    let connectedDroneHolder: ConnectedDroneHolder
    let currentDroneHolder: CurrentDroneHolder
    let obstacleAvoidanceMonitor: ObstacleAvoidanceMonitor
    let rthSettingsMonitor: RthSettingsMonitor
    let currentRemoteControlHolder: CurrentRemoteControlHolder
    let connectedRemoteControlHolder: ConnectedRemoteControlHolder
    let remoteControlUpdater: RemoteControlUpdater
    let locationsTracker: LocationsTracker
    let repos: Repositories
    // swiftlint:disable:next identifier_name
    let ui: UIServices
    let drone: DroneServices
    let flightPlan: FlightPlanServices
    let flight: FlightServices
    let academyApiService: AcademyApiService
    var cloudSynchroWatcher: CloudSynchroWatcher?
    let panoramaService: PanoramaService
    var touchAndFly: TouchAndFlyService
    let update: UpdateService
    let systemServices: SystemServices
    let bamService: BannerAlertManagerService
    let alertMonitorManager: AlertsMonitor
    let presetService: PresetsService
    let databaseUpdateService: DatabaseUpdateService

    /// Legacy drone store, implements some side effects of current drone change
    private let legacyCurrentDroneStore: LegacyCurrentDroneStore

    // swiftlint:disable:next function_body_length
    fileprivate init(variableAssetsService: VariableAssetsService,
                     persistentContainer: NSPersistentContainer,
                     missionsToLoadAtStart: [AirSdkMissionSignature],
                     dashboardUiProvider: DashboardUiProvider) {

        apcApiManager = APCApiManager()

        let userServiceImpl = UserServiceImpl(apcApiManager: apcApiManager)

        let coredataService = CoreDataServiceImpl(with: persistentContainer,
                                                  and: userServiceImpl)
        userServiceImpl.setup(userRepo: coredataService)
        userService = userServiceImpl

        repos = Repositories(repoServices: coredataService,
                             user: coredataService,
                             drone: coredataService,
                             project: coredataService,
                             flight: coredataService,
                             flightPlanFlight: coredataService,
                             flightPlan: coredataService,
                             thumbnail: coredataService,
                             pgyProject: coredataService)

        apiRequestQueue = ApiRequestQueueImpl()

        flightPlanTypeStore = FlightPlanTypeStoreImpl()

        connectedDroneHolder = ConnectedDroneHolderImpl()

        currentDroneHolder = CurrentDroneHolderImpl(connectedDroneHolder: connectedDroneHolder)

        let airsdkMissionsManagerService = AirSdkMissionsManagerImpl(connectedDroneHolder: connectedDroneHolder,
                                                                     missionsToLoadAtDroneConnection: missionsToLoadAtStart)
        missionsStore = MissionsStoreImpl(connectedDroneHolder: connectedDroneHolder,
                                          missionsManager: airsdkMissionsManagerService)

        currentMissionManager = CurrentMissionManagerImpl(store: missionsStore)

        legacyCurrentDroneStore = LegacyCurrentDroneStore(droneHolder: currentDroneHolder)

        let academySessionProvider = AcademySessionProviderImpl(userService: userService,
                                                                xApiKey: ServicesConstants.academySecretKey)

        academyApiService = AcademyApiServiceImpl(requestQueue: apiRequestQueue,
                                                  academySession: academySessionProvider,
                                                  userService: userService)

        connectedRemoteControlHolder = ConnectedRemoteControlHolderImpl()

        currentRemoteControlHolder = CurrentRemoteControlHolderImpl(connectedRemoteControlHolder: connectedRemoteControlHolder)

        remoteControlUpdater = RemoteControlUpdaterImpl(currentRemoteControlHolder: currentRemoteControlHolder)

        let activeFlightPlanWatcher = ActiveFlightPlanExecutionWatcherImpl(flightPlanRepository: repos.flightPlan)

        obstacleAvoidanceMonitor = ObstacleAvoidanceMonitorImpl(currentDroneHolder: currentDroneHolder,
                                                                activeFlightPlanWatcher: activeFlightPlanWatcher)
        rthSettingsMonitor = RthSettingsMonitorImpl(currentDroneHolder: currentDroneHolder,
                                                    activeFlightPlanWatcher: activeFlightPlanWatcher)

        locationsTracker = LocationsTrackerImpl(connectedDroneHolder: connectedDroneHolder,
                                                connectedRcHolder: connectedRemoteControlHolder)
        let joysticksAvailabilityService = JoysticksAvailabilityServiceImpl(currentMissionManager: currentMissionManager,
                                                                            connectedDroneHolder: connectedDroneHolder,
                                                                            connectedRemoteControlHolder: connectedRemoteControlHolder)

        bamService = BannerAlertManagerServiceImpl()

        let rthService = RthServiceImpl(currentDroneHolder: currentDroneHolder,
                                        bamService: bamService)
        let zoomService = ZoomServiceImpl(currentDroneHolder: currentDroneHolder,
                                          activeFlightPlanWatcher: activeFlightPlanWatcher)
        let gimbalTiltService = GimbalTiltServiceImpl(connectedDroneHolder: connectedDroneHolder,
                                                      activeFlightPlanWatcher: activeFlightPlanWatcher)
        let networkService = NetworkServiceImpl()
        systemServices = SystemServices(networkService: networkService)

        let cellularService = CellularServiceImpl(connectedDroneHolder: connectedDroneHolder)
        let cellularSessionService = CellularSessionServiceImpl(connectedDroneHolder: connectedDroneHolder,
                                                                connectedRemoteControlHolder: connectedRemoteControlHolder)
        let cellularPairingService = CellularPairingServiceImpl(currentDroneHolder: currentDroneHolder,
                                                                apcApiManager: apcApiManager,
                                                                connectedDroneHolder: connectedDroneHolder,
                                                                academyApiService: academyApiService,
                                                                networkService: systemServices.networkService,
                                                                userService: userService,
                                                                cellularService: cellularService)
        let cellularPairingAvailabilityService = CellularPairingAvailabilityServiceImpl(currentDroneHolder: currentDroneHolder,
                                                                                        connectedDroneHolder: connectedDroneHolder,
                                                                                        academyApiService: academyApiService,
                                                                                        cellularPairingService: cellularPairingService,
                                                                                        cellularService: cellularService)
        let exposureService = ExposureServiceImpl(currentDroneHolder: currentDroneHolder)
        let exposureLockService = ExposureLockServiceImpl(currentDroneHolder: currentDroneHolder)
        let airSdkMissionListenerService = AirSdkMissionListenerImpl(currentMissionManager: currentMissionManager,
                                                                     airSdkMissionManager: airsdkMissionsManagerService)
        let pinCodeService = PinCodeServiceImpl(connectedDroneHolder: connectedDroneHolder)
        let ophtalmoService = OphtalmoServiceImpl(connectedDroneHolder: connectedDroneHolder,
                                                  airSdkMissionManager: airsdkMissionsManagerService,
                                                  airsdkMissionsListener: airSdkMissionListenerService)
        let cameraRecordingService = CameraRecordingServiceImpl(currentDroneHolder: currentDroneHolder)
        let cameraPhotoCaptureService = CameraPhotoCaptureServiceImpl(currentDroneHolder: currentDroneHolder)
        let cameraConfigWatcher = CameraConfigWatcherImpl(currentDroneHolder: currentDroneHolder)
        let gpslapseRestartService = GpslapseRestartServiceImpl(connectedDroneHolder: connectedDroneHolder,
                                                                cameraPhotoCaptureService: cameraPhotoCaptureService,
                                                                cameraConfigWatcher: cameraConfigWatcher,
                                                                activeFlightPlanWatcher: activeFlightPlanWatcher)
        let timelapseRestartService = TimelapseRestartServiceImpl(connectedDroneHolder: connectedDroneHolder,
                                                                  cameraPhotoCaptureService: cameraPhotoCaptureService,
                                                                  cameraConfigWatcher: cameraConfigWatcher,
                                                                  activeFlightPlanWatcher: activeFlightPlanWatcher)
        let removableUserStorageService = RemovableUserStorageServiceImpl(currentDroneHolder: currentDroneHolder)
        let handLaunchService = HandLaunchServiceImpl(currentDroneHolder: currentDroneHolder)
        drone = DroneServices(rthService: rthService,
                              zoomService: zoomService,
                              gimbalTiltService: gimbalTiltService,
                              cellularService: cellularService,
                              cellularSessionService: cellularSessionService,
                              cellularPairingService: cellularPairingService,
                              cellularPairingAvailabilityService: cellularPairingAvailabilityService,
                              exposureService: exposureService,
                              exposureLockService: exposureLockService,
                              airsdkMissionsManager: airsdkMissionsManagerService,
                              airsdkMissionsListener: airSdkMissionListenerService,
                              pinCodeService: pinCodeService,
                              ophtalmoService: ophtalmoService,
                              cameraRecordingService: cameraRecordingService,
                              cameraPhotoCaptureService: cameraPhotoCaptureService,
                              cameraConfigWatcher: cameraConfigWatcher,
                              gpslapseRestartService: gpslapseRestartService,
                              timelapseRestartService: timelapseRestartService,
                              removableUserStorageService: removableUserStorageService,
                              handLaunchService: handLaunchService)

        update = UpdateServiceImpl(currentDroneHolder: currentDroneHolder,
                                   currentRemoteControlHolder: currentRemoteControlHolder)
        let criticalAlert = CriticalAlertServiceImpl(connectedDroneHolder: connectedDroneHolder,
                                                     updateService: update,
                                                     removableUserStorageService: removableUserStorageService)

        let flightPlanStartAvailabilityWatcher = FlightPlanStartAvailabilityWatcherImpl(currentDroneHolder: currentDroneHolder,
                                                                                        rthService: rthService)

        let flightPlanFilesManager = FlightPlanFilesManagerImpl()

        let flightPlanManager = FlightPlanManagerImpl(persistenceFlightPlan: repos.flightPlan,
                                                      userService: userService,
                                                      filesManager: flightPlanFilesManager,
                                                      pgyProjectRepo: repos.pgyProject)

        let flightPlanEditionService = FlightPlanEditionServiceImpl(flightPlanRepo: repos.flightPlan,
                                                                    flightPlanManager: flightPlanManager,
                                                                    typeStore: flightPlanTypeStore,
                                                                    currentMissionManager: currentMissionManager,
                                                                    userService: userService,
                                                                    cloudSynchroWatcher: cloudSynchroWatcher)

        let flightPlanRunManager = FlightPlanRunManagerImpl(typeStore: flightPlanTypeStore,
                                                            projectRepo: repos.project,
                                                            currentDroneHolder: currentDroneHolder,
                                                            activeFlightPlanWatcher: activeFlightPlanWatcher,
                                                            flightPlanManager: flightPlanManager,
                                                            startAvailabilityWatcher: flightPlanStartAvailabilityWatcher,
                                                            criticalAlertService: criticalAlert)

        let projectManager = ProjectManagerImpl(missionsStore: missionsStore,
                                                flightPlanTypeStore: flightPlanTypeStore,
                                                persistenceProject: repos.project,
                                                flightPlanRepo: repos.flightPlan,
                                                editionService: flightPlanEditionService,
                                                currentMissionManager: currentMissionManager,
                                                userService: userService,
                                                filesManager: flightPlanFilesManager,
                                                flightPlanManager: flightPlanManager,
                                                flightPlanRunManager: flightPlanRunManager,
                                                cloudSynchroWatcher: cloudSynchroWatcher)
        flightPlanEditionService.updateProjectManager(projectManager)

        let flightPlanCameraSettingsHandler = FlightPlanCameraSettingsHandlerImpl(activeFlightPlanWatcher: activeFlightPlanWatcher,
                                                                                  currentDroneHolder: currentDroneHolder,
                                                                                  projectManager: projectManager,
                                                                                  cameraConfigWatcher: cameraConfigWatcher)

        let mavlinkGenerator = MavlinkGeneratorImpl(typeStore: flightPlanTypeStore,
                                                    filesManager: flightPlanFilesManager,
                                                    repo: repos.flightPlan)

        let mavlinkSender = MavlinkDroneSenderImpl(typeStore: flightPlanTypeStore, currentDroneHolder: currentDroneHolder)

        let flightPlanStateMachine = FlightPlanStateMachineImpl(manager: flightPlanManager,
                                                                projectManager: projectManager,
                                                                runManager: flightPlanRunManager,
                                                                mavlinkGenerator: mavlinkGenerator,
                                                                mavlinkSender: mavlinkSender,
                                                                startAvailabilityWatcher: flightPlanStartAvailabilityWatcher,
                                                                edition: flightPlanEditionService,
                                                                cloudSynchroWatcher: cloudSynchroWatcher)
        let flightPlanUiStateProvider = FlightPlanUiStateProviderImpl(stateMachine: flightPlanStateMachine,
                                                                      startAvailabilityWatcher: flightPlanStartAvailabilityWatcher,
                                                                      projectManager: projectManager)
        let flightPlanRecoveryInfo = FlightPlanRecoveryInfoServiceImpl(connectedDroneHolder: connectedDroneHolder,
                                                                       currentDroneHolder: currentDroneHolder,
                                                                       flightPlanManager: flightPlanManager,
                                                                       projectService: projectManager,
                                                                       missionsStore: missionsStore,
                                                                       currentMissionManager: currentMissionManager)
        let flightPlanExecutionDetailsSettingsProvider = FlightPlanExecutionDetailsSettingsProviderImpl()
        flightPlan = FlightPlanServices(projectManager: projectManager,
                                        manager: flightPlanManager,
                                        stateMachine: flightPlanStateMachine,
                                        activeFlightPlanWatcher: activeFlightPlanWatcher,
                                        cameraSettingsHandler: flightPlanCameraSettingsHandler,
                                        typeStore: flightPlanTypeStore,
                                        edition: flightPlanEditionService,
                                        run: flightPlanRunManager,
                                        mavlinkGenerator: mavlinkGenerator,
                                        mavlinkSender: mavlinkSender,
                                        startAvailabilityWatcher: flightPlanStartAvailabilityWatcher,
                                        filesManager: flightPlanFilesManager,
                                        recoveryInfoService: flightPlanRecoveryInfo)

        let uiComponentsDisplayReporter = UIComponentsDisplayReporterImpl()

        let navigationStack = NavigationStackServiceImpl()

        let hudTopBarService = HudTopBarServiceImpl(navigationStackService: navigationStack)
        let hudBottomBarService = HudBottomBarServiceImpl()

        let projectManagerUiProvider = ProjectManagerUiProviderImpl()

        touchAndFly = TouchAndFlyServiceImpl(connectedDroneHolder: connectedDroneHolder,
                                             locationsTracker: locationsTracker,
                                             currentMissionManager: currentMissionManager)
        let touchAndFlyUi = TouchAndFlyUiServiceImpl(service: touchAndFly,
                                                     locations: locationsTracker,
                                                     currentMissionManager: currentMissionManager)

        ui = UIServices(joysticksAvailabilityService: joysticksAvailabilityService,
                        variableAssetsService: variableAssetsService,
                        hudTopBarService: hudTopBarService,
                        hudBottomBarService: hudBottomBarService,
                        uiComponentsDisplayReporter: uiComponentsDisplayReporter,
                        flightPlanUiStateProvider: flightPlanUiStateProvider,
                        flightPlanExecutionDetailsSettingsProvider: flightPlanExecutionDetailsSettingsProvider,
                        projectManagerUiProvider: projectManagerUiProvider,
                        dashboardUiProvider: dashboardUiProvider,
                        navigationStack: navigationStack,
                        touchAndFly: touchAndFlyUi,
                        criticalAlert: criticalAlert)

        let flightService = FlightServiceImpl(repo: repos.flight,
                                              fpFlightRepo: repos.flightPlanFlight,
                                              thumbnailRepo: repos.thumbnail,
                                              userService: userService,
                                              cloudSynchroWatcher: cloudSynchroWatcher,
                                              flightPlanRunManager: flightPlanRunManager)

        let gutmaWatcher = GutmaWatcherImpl(userService: userService,
                                            service: flightService,
                                            currentDroneHolder: currentDroneHolder)

        flight = FlightServices(gutmaWatcher: gutmaWatcher, service: flightService)

        panoramaService = PanoramaServiceImpl(currentDroneHolder: currentDroneHolder,
                                              bamService: bamService)

        alertMonitorManager = AlertsMonitor(connectedDroneHolder: connectedDroneHolder,
                                            bamService: bamService)
        presetService = PresetsServiceImpl(currentDroneHolder: currentDroneHolder)

        databaseUpdateService = DatabaseUpdateServiceImpl(repositories: repos)
    }

    func start() {
        presetService.start()
    }
}
