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
import Pictor
import SwiftyUserDefaults

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

    /// User Service
    var userService: PictorUserService { get }
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
    /// OpenFlight wrapper over Return Home Piloting Interface
    var fixedLocationMonitor: FixedLocationMonitor { get }
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
    /// Thumbnail generator service
    var thumbnailGeneratorService: ThumbnailGeneratorService { get }
    /// Access to Academy API drone service
    var academyApiDroneService: AcademyApiDroneService { get }
    /// Watch pending synchro process with cloud
    var synchroService: SynchroService { get set }
    /// Panorama capture mode service
    var panoramaService: PanoramaService { get }
    /// Touch and fly service
    var touchAndFly: TouchAndFlyService { get }
    /// Touch and fly service
    var touchAndFlyUi: TouchAndFlyUiService { get }
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
    /// Media services
    var media: MediaServices { get }
    /// Start active services
    func start()
}

/// Namespace to expose the service hub (until refactor is complete)
public enum Services {
    /// The service hub
    public private(set) static var hub: ServiceHub!

    public static func createInstance(variableAssetsService: VariableAssetsService,
                                      missionsToLoadAtStart: [AirSdkMissionSignature],
                                      dashboardUiProvider: DashboardUiProvider) -> ServiceHub {
        hub = ServiceHubImpl(variableAssetsService: variableAssetsService,
                             missionsToLoadAtStart: missionsToLoadAtStart,
                             dashboardUiProvider: dashboardUiProvider)
        return hub
    }
}

/// Data Repositories
public struct Repositories {
    public let session: PictorSessionRepository
    public let project: PictorProjectRepository
    public let flight: PictorFlightRepository
    public let flightPlan: PictorFlightPlanRepository
    public let thumbnail: PictorThumbnailRepository
    public let pgyProject: PictorProjectPix4dRepository
    public let gutmaLink: PictorGutmaLinkRepository
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

/// The media services.
public struct MediaServices {
    /// The media store service.
    public let mediaStoreService: MediaStoreService
    /// The user storage service.
    public let userStorageService: UserStorageService
    /// The media list service.
    public let mediaListService: MediaListService
    /// The stream replay service.
    public let streamReplayService: StreamReplayService
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
    /// AirSdk mission manager service
    public let airsdkMissionsManager: AirSdkMissionsManager
    /// AirSdk mission updater service
    public let airsdkMissionsUpdaterService: AirSdkMissionsUpdaterService
    /// AirSdk mission listener service
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
    /// Hand launch service.
    let handLaunchService: HandLaunchService
    /// Firmware update service.
    let firmwareUpdateService: FirmwareUpdateService
    /// Battery gauge updater service.
    let batteryGaugeUpdaterService: BatteryGaugeUpdaterService
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
    /// Store of available flight plan types
    public var typeStore: FlightPlanTypeStore
    /// Edition of flight plan
    public var edition: FlightPlanEditionService
    /// Run Manager of flight plan
    public var run: FlightPlanRunManager
    /// Plan file generator
    public var planFileGenerator: PlanFileGenerator
    /// Plan file sender
    public var planFileSender: PlanFileDroneSender
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
    /// Memory Pressure Monitor.
    public let memoryPressureMonitor: MemoryPressureMonitorService
    /// Metric Kit Service.
    public let metricKitService: MetricKitService
    /// Disk space service.
    public let diskSpaceService: DiskSpaceService
}

/// Implementation of the service hub
private class ServiceHubImpl: ServiceHub {
    let userService: PictorUserService
    let flightPlanTypeStore: FlightPlanTypeStore
    let missionsStore: MissionsStore
    let currentMissionManager: CurrentMissionManager
    let connectedDroneHolder: ConnectedDroneHolder
    let currentDroneHolder: CurrentDroneHolder
    let obstacleAvoidanceMonitor: ObstacleAvoidanceMonitor
    let rthSettingsMonitor: RthSettingsMonitor
    let fixedLocationMonitor: FixedLocationMonitor
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
    let thumbnailGeneratorService: ThumbnailGeneratorService
    let academyApiDroneService: AcademyApiDroneService
    var synchroService: SynchroService
    let databaseMigrationService: PictorDatabaseMigrationService
    let panoramaService: PanoramaService
    var touchAndFly: TouchAndFlyService
    var touchAndFlyUi: TouchAndFlyUiService
    let update: UpdateService
    let systemServices: SystemServices
    let bamService: BannerAlertManagerService
    let alertMonitorManager: AlertsMonitor
    let presetService: PresetsService
    let databaseUpdateService: DatabaseUpdateService
    let media: MediaServices

    /// Legacy drone store, implements some side effects of current drone change
    private let legacyCurrentDroneStore: LegacyCurrentDroneStore

    // swiftlint:disable:next function_body_length
    fileprivate init(variableAssetsService: VariableAssetsService,
                     missionsToLoadAtStart: [AirSdkMissionSignature],
                     dashboardUiProvider: DashboardUiProvider) {

        let networkService = NetworkServiceImpl()
        let memoryPressureMonitor = MemoryPressureMonitorServiceImpl()
        let metricKitService = MetricKitServiceImpl(autoStart: Defaults.isMetricKitEnabled)
        let diskSpaceService = DiskSpaceServiceImpl()
        systemServices = SystemServices(networkService: networkService,
                                        memoryPressureMonitor: memoryPressureMonitor,
                                        metricKitService: metricKitService,
                                        diskSpaceService: diskSpaceService)

        if let oldPersistentContainer = PictorConfiguration.shared.oldPersistentContainer {
            Pictor.shared.service.databaseMigration.setup(withOldPersistentContainer: oldPersistentContainer)
        }

        userService = Pictor.shared.service.user
        repos = Repositories(session: Pictor.shared.repository.session,
                             project: Pictor.shared.repository.project,
                             flight: Pictor.shared.repository.flight,
                             flightPlan: Pictor.shared.repository.flightPlan,
                             thumbnail: Pictor.shared.repository.thumbnail,
                             pgyProject: Pictor.shared.repository.projectPix4d,
                             gutmaLink: Pictor.shared.repository.gutmaLink)

        synchroService = Pictor.shared.service.synchroService

        databaseMigrationService = Pictor.shared.service.databaseMigration

        flightPlanTypeStore = FlightPlanTypeStoreImpl()

        thumbnailGeneratorService = ThumbnailGeneratorServiceImpl(userService: userService,
                                                                  flightRepository: Pictor.shared.repository.flight,
                                                                  flightPlanRepository: Pictor.shared.repository.flightPlan,
                                                                  metricKitService: metricKitService)

        connectedDroneHolder = ConnectedDroneHolderImpl()

        currentDroneHolder = CurrentDroneHolderImpl(connectedDroneHolder: connectedDroneHolder)

        let airsdkMissionsManagerService = AirSdkMissionsManagerImpl(connectedDroneHolder: connectedDroneHolder,
                                                                     missionsToLoadAtDroneConnection: missionsToLoadAtStart)
        let airsdkMissionsUpdaterService = AirSdkMissionsUpdaterServiceImpl(
            connectedDroneHolder: connectedDroneHolder,
            airSdkMissionsManager: airsdkMissionsManagerService)
        missionsStore = MissionsStoreImpl(
            connectedDroneHolder: connectedDroneHolder,
            missionsManager: airsdkMissionsManagerService)

        currentMissionManager = CurrentMissionManagerImpl(store: missionsStore)

        legacyCurrentDroneStore = LegacyCurrentDroneStore(droneHolder: currentDroneHolder)

        connectedRemoteControlHolder = ConnectedRemoteControlHolderImpl()

        currentRemoteControlHolder = CurrentRemoteControlHolderImpl(connectedRemoteControlHolder: connectedRemoteControlHolder)

        remoteControlUpdater = RemoteControlUpdaterImpl(currentRemoteControlHolder: currentRemoteControlHolder,
                                                        currentDroneHolder: currentDroneHolder)

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
                                        locationsTracker: locationsTracker,
                                        bamService: bamService)
        let zoomService = ZoomServiceImpl(currentDroneHolder: currentDroneHolder,
                                          activeFlightPlanWatcher: activeFlightPlanWatcher)
        let gimbalTiltService = GimbalTiltServiceImpl(connectedDroneHolder: connectedDroneHolder,
                                                      activeFlightPlanWatcher: activeFlightPlanWatcher)

        fixedLocationMonitor = FixedLocationMonitorImpl(currentDroneHolder: currentDroneHolder,
                                                        locationsTracker: locationsTracker,
                                                        networkService: networkService)

        academyApiDroneService = Pictor.shared.service.academyApi.drone

        let cellularService = CellularServiceImpl(connectedDroneHolder: connectedDroneHolder)
        let cellularSessionService = CellularSessionServiceImpl(connectedDroneHolder: connectedDroneHolder,
                                                                connectedRemoteControlHolder: connectedRemoteControlHolder,
                                                                cellularService: cellularService)
        let cellularPairingService = CellularPairingServiceImpl(currentDroneHolder: currentDroneHolder,
                                                                connectedDroneHolder: connectedDroneHolder,
                                                                academyApiDroneService: academyApiDroneService,
                                                                networkService: systemServices.networkService,
                                                                userService: userService,
                                                                cellularService: cellularService)
        let cellularPairingAvailabilityService = CellularPairingAvailabilityServiceImpl(currentDroneHolder: currentDroneHolder,
                                                                                        connectedDroneHolder: connectedDroneHolder,
                                                                                        academyApiDroneService: academyApiDroneService,
                                                                                        cellularPairingService: cellularPairingService,
                                                                                        cellularService: cellularService)
        let exposureService = ExposureServiceImpl(currentDroneHolder: currentDroneHolder)
        let exposureLockService = ExposureLockServiceImpl(currentDroneHolder: currentDroneHolder)
        let airSdkMissionListenerService = AirSdkMissionListenerImpl(currentMissionManager: currentMissionManager,
                                                                     airSdkMissionManager: airsdkMissionsManagerService)
        let pinCodeService = PinCodeServiceImpl(connectedDroneHolder: connectedDroneHolder)
        let handLaunchService = HandLaunchServiceImpl(currentDroneHolder: currentDroneHolder)
        let ophtalmoService = OphtalmoServiceImpl(connectedDroneHolder: connectedDroneHolder,
                                                  handLaunchService: handLaunchService,
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
        let firmwareUpdateService = FirmwareUpdateServiceImpl(currentDroneHolder: currentDroneHolder)
        let batteryGaugeUpdaterService = BatteryGaugeUpdaterServiceImpl(currentDroneHolder: currentDroneHolder)
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
                              airsdkMissionsUpdaterService: airsdkMissionsUpdaterService,
                              airsdkMissionsListener: airSdkMissionListenerService,
                              pinCodeService: pinCodeService,
                              ophtalmoService: ophtalmoService,
                              cameraRecordingService: cameraRecordingService,
                              cameraPhotoCaptureService: cameraPhotoCaptureService,
                              cameraConfigWatcher: cameraConfigWatcher,
                              gpslapseRestartService: gpslapseRestartService,
                              timelapseRestartService: timelapseRestartService,
                              handLaunchService: handLaunchService,
                              firmwareUpdateService: firmwareUpdateService,
                              batteryGaugeUpdaterService: batteryGaugeUpdaterService)

        let userStorageService = UserStorageServiceImpl(currentDroneHolder: currentDroneHolder)
        update = UpdateServiceImpl(currentDroneHolder: currentDroneHolder,
                                   currentRemoteControlHolder: currentRemoteControlHolder)
        let criticalAlert = CriticalAlertServiceImpl(connectedDroneHolder: connectedDroneHolder,
                                                     updateService: update,
                                                     userStorageService: userStorageService)

        let flightPlanStartAvailabilityWatcher = FlightPlanStartAvailabilityWatcherImpl(currentDroneHolder: currentDroneHolder,
                                                                                        rthService: rthService)

        let flightPlanFilesManager = FlightPlanFilesManagerImpl()

        let flightPlanManager = FlightPlanManagerImpl(flightPlanRepository: repos.flightPlan,
                                                      gutmaLinkRepository: repos.gutmaLink,
                                                      userService: userService,
                                                      filesManager: flightPlanFilesManager,
                                                      pgyProjectRepo: repos.pgyProject)

        let flightPlanEditionService = FlightPlanEditionServiceImpl(flightPlanRepository: repos.flightPlan,
                                                                    flightPlanManager: flightPlanManager,
                                                                    typeStore: flightPlanTypeStore,
                                                                    currentMissionManager: currentMissionManager,
                                                                    userService: userService,
                                                                    thumbnailGeneratorService: thumbnailGeneratorService)

        let flightPlanRunManager = FlightPlanRunManagerImpl(typeStore: flightPlanTypeStore,
                                                            projectRepository: repos.project,
                                                            currentDroneHolder: currentDroneHolder,
                                                            activeFlightPlanWatcher: activeFlightPlanWatcher,
                                                            flightPlanManager: flightPlanManager,
                                                            startAvailabilityWatcher: flightPlanStartAvailabilityWatcher,
                                                            criticalAlertService: criticalAlert)

        let planFileSender = PlanFileDroneSenderImpl(typeStore: flightPlanTypeStore, currentDroneHolder: currentDroneHolder)

        let projectManager = ProjectManagerImpl(missionsStore: missionsStore,
                                                flightPlanTypeStore: flightPlanTypeStore,
                                                projectRepository: repos.project,
                                                flightPlanRepository: repos.flightPlan,
                                                gutmaLinkRepository: repos.gutmaLink,
                                                editionService: flightPlanEditionService,
                                                currentMissionManager: currentMissionManager,
                                                userService: userService,
                                                filesManager: flightPlanFilesManager,
                                                flightPlanManager: flightPlanManager,
                                                flightPlanRunManager: flightPlanRunManager)

        flightPlanEditionService.updateProjectManager(projectManager)

        let planFileGenerator = PlanFileGeneratorImpl(typeStore: flightPlanTypeStore,
                                                      filesManager: flightPlanFilesManager,
                                                      projectManager: projectManager,
                                                      currentDroneHolder: currentDroneHolder)

        let flightPlanStateMachine = FlightPlanStateMachineImpl(manager: flightPlanManager,
                                                                projectManager: projectManager,
                                                                flightPlanRepository: repos.flightPlan,
                                                                runManager: flightPlanRunManager,
                                                                planFileGenerator: planFileGenerator,
                                                                planFileSender: planFileSender,
                                                                filesManager: flightPlanFilesManager,
                                                                startAvailabilityWatcher: flightPlanStartAvailabilityWatcher,
                                                                edition: flightPlanEditionService,
                                                                locationTracker: locationsTracker)
        let flightPlanUiStateProvider = FlightPlanUiStateProviderImpl(stateMachine: flightPlanStateMachine,
                                                                      startAvailabilityWatcher: flightPlanStartAvailabilityWatcher,
                                                                      projectManager: projectManager)
        let flightPlanRecoveryInfo = FlightPlanRecoveryInfoServiceImpl(connectedDroneHolder: connectedDroneHolder,
                                                                       currentDroneHolder: currentDroneHolder,
                                                                       flightPlanManager: flightPlanManager,
                                                                       runManager: flightPlanRunManager,
                                                                       projectService: projectManager,
                                                                       missionsStore: missionsStore,
                                                                       currentMissionManager: currentMissionManager)
        let flightPlanExecutionDetailsSettingsProvider = FlightPlanExecutionDetailsSettingsProviderImpl()
        flightPlan = FlightPlanServices(projectManager: projectManager,
                                        manager: flightPlanManager,
                                        stateMachine: flightPlanStateMachine,
                                        activeFlightPlanWatcher: activeFlightPlanWatcher,
                                        typeStore: flightPlanTypeStore,
                                        edition: flightPlanEditionService,
                                        run: flightPlanRunManager,
                                        planFileGenerator: planFileGenerator,
                                        planFileSender: planFileSender,
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
                                             currentMissionManager: currentMissionManager,
                                             bamService: bamService)
        touchAndFlyUi = TouchAndFlyUiServiceImpl(service: touchAndFly,
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

        let flightService = FlightServiceImpl(flightRepository: repos.flight,
                                              gutmaLinkRepository: repos.gutmaLink,
                                              userService: userService,
                                              flightPlanRunManager: flightPlanRunManager)

        let gutmaWatcher = GutmaWatcherImpl(userService: userService,
                                            service: flightService,
                                            currentDroneHolder: currentDroneHolder)

        flight = FlightServices(gutmaWatcher: gutmaWatcher, service: flightService)

        panoramaService = PanoramaServiceImpl(currentDroneHolder: currentDroneHolder,
                                              bamService: bamService)

        let mediaStoreService = MediaStoreServiceImpl(currentDroneHolder: currentDroneHolder)
        alertMonitorManager = AlertsMonitor(connectedDroneHolder: connectedDroneHolder,
                                            bamService: bamService,
                                            mediaStoreService: mediaStoreService,
                                            flightPlanEditionService: flightPlanEditionService)
        presetService = PresetsServiceImpl(currentDroneHolder: currentDroneHolder)

        databaseUpdateService = DatabaseUpdateServiceImpl(repositories: repos,
                                                          userService: userService,
                                                          synchroService: synchroService,
                                                          databaseMigrationService: databaseMigrationService,
                                                          thumbnailGeneratorService: thumbnailGeneratorService)

        let mediaListService = MediaListServiceImpl(mediaStoreService: mediaStoreService)
        let streamReplayService = StreamReplayServiceImpl(currentDroneHolder: currentDroneHolder,
                                                          cameraRecordingService: cameraRecordingService,
                                                          mediaStoreService: mediaStoreService)
        media = MediaServices(mediaStoreService: mediaStoreService,
                              userStorageService: userStorageService,
                              mediaListService: mediaListService,
                              streamReplayService: streamReplayService)
    }

    func start() {
        presetService.start()
    }
}
