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

    /// Store and load current user information in Keychain
    var userInformation: UserInformation { get }
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
    /// Access to the current remote control if any
    var currentRemoteControlHolder: CurrentRemoteControlHolder { get }
    /// Access to the connected remote control if any
    var connectedRemoteControlHolder: ConnectedRemoteControlHolder { get }
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
    /// Access to mission catch up service
    var missionCatchUp: MissionCatchUpService { get }
    /// Access to Academy API service
    var academyApiService: AcademyApiService { get }
    /// Watch pending synchro process with cloud
    var cloudSynchroWatcher: CloudSynchroWatcher? { get set }
    /// Panorama capture mode service
    var panoramaService: PanoramaService { get }
    /// Watch data confidentiality share level
    var dataConfidentialityWatcher: DataConfidentialityWatcher? { get set }
}

/// Namespace to expose the service hub (until refactor is complete)
public enum Services {
    /// The service hub
    public private(set) static var hub: ServiceHub!

    public static func createInstance(variableAssetsService: VariableAssetsService,
                                      persistentContainer: NSPersistentContainer,
                                      missionsToLoadAtStart: [ProtobufMissionSignature]) -> ServiceHub {
        hub = ServiceHubImpl(variableAssetsService: variableAssetsService,
                             persistentContainer: persistentContainer,
                             missionsToLoadAtStart: missionsToLoadAtStart)
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
    /// UI components display reporter
    public let uiComponentsDisplayReporter: UIComponentsDisplayReporter
    /// Flight plan UI state provider
    public var flightPlanUiStateProvider: FlightPlanUiStateProvider
    /// Flight plan execution details settings provider
    public let flightPlanExecutionDetailsSettingsProvider: FlightPlanExecutionDetailsSettingsProvider
    /// Project manager views UI provider
    public let projectManagerUiProvider: ProjectManagerUiProvider
}

/// Drone services (instruments and peripherals related)
public struct DroneServices {
    /// Gimbal zoom service
    public let zoomService: ZoomService
    /// Gimbal tilt service
    public let gimbalTiltService: GimbalTiltService
    /// Cellular pairing service
    public let cellularPairingService: CellularPairingService
    /// Cellular pairing availability service
    public let cellularPairingAvailabilityService: CellularPairingAvailabilityService
    /// Camera exposure service
    public let exposureService: ExposureService
    /// Camera exposure lock service
    public let exposureLockService: ExposureLockService
    /// Protobuf mission listener service
    public let protobufMissionsManager: ProtobufMissionsManager
    /// Protobuf mission manager service
    public let protobufMissionsListener: ProtobufMissionsListener
    /// Ophtalmo mission service
    let ophtalmoService: OphtalmoService
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
}

/// Flight services
public struct FlightServices {
    /// Access to gutma watcher
    public let gutmaWatcher: GutmaWatcher
    /// Access to flight service
    public let service: FlightService
}

/// Implementation of the service hub
private class ServiceHubImpl: ServiceHub {

    let userInformation: UserInformation
    let apiRequestQueue: ApiRequestQueue
    let flightPlanTypeStore: FlightPlanTypeStore
    let missionsStore: MissionsStore
    let currentMissionManager: CurrentMissionManager
    let connectedDroneHolder: ConnectedDroneHolder
    let currentDroneHolder: CurrentDroneHolder
    let obstacleAvoidanceMonitor: ObstacleAvoidanceMonitor
    let currentRemoteControlHolder: CurrentRemoteControlHolder
    let connectedRemoteControlHolder: ConnectedRemoteControlHolder
    let locationsTracker: LocationsTracker
    let repos: Repositories
    // swiftlint:disable:next identifier_name
    let ui: UIServices
    let drone: DroneServices
    let flightPlan: FlightPlanServices
    let missionCatchUp: MissionCatchUpService
    let flight: FlightServices
    let academyApiService: AcademyApiService
    var cloudSynchroWatcher: CloudSynchroWatcher?
    let panoramaService: PanoramaService
    var dataConfidentialityWatcher: DataConfidentialityWatcher?

    /// Legacy drone store, implements some side effects of current drone change
    private let legacyCurrentDroneStore: LegacyCurrentDroneStore

    fileprivate init(variableAssetsService: VariableAssetsService,
                     persistentContainer: NSPersistentContainer,
                     missionsToLoadAtStart: [ProtobufMissionSignature]) {

        userInformation = UserInformationImpl()

        apiRequestQueue = ApiRequestQueueImpl()

        flightPlanTypeStore = FlightPlanTypeStoreImpl()

        missionsStore = MissionsStoreImpl()

        currentMissionManager = CurrentMissionManagerImpl(store: missionsStore)

        connectedDroneHolder = ConnectedDroneHolderImpl()

        currentDroneHolder = CurrentDroneHolderImpl(connectedDroneHolder: connectedDroneHolder)

        legacyCurrentDroneStore = LegacyCurrentDroneStore(droneHolder: currentDroneHolder,
                                                          currentMissionManager: currentMissionManager)

        academyApiService = AcademyApiServiceImpl(requestQueue: apiRequestQueue,
                                                  userInformation: userInformation)

        connectedRemoteControlHolder = ConnectedRemoteControlHolderImpl()

        currentRemoteControlHolder = CurrentRemoteControlHolderImpl(connectedRemoteControlHolder: connectedRemoteControlHolder)

        let coredataService = CoreDataServiceImpl(with: persistentContainer,
                                                  userInformation: userInformation)
        repos = Repositories(repoServices: coredataService,
                             user: coredataService,
                             drone: coredataService,
                             project: coredataService,
                             flight: coredataService,
                             flightPlanFlight: coredataService,
                             flightPlan: coredataService,
                             thumbnail: coredataService,
                             pgyProject: coredataService)

        let activeFlightPlanWatcher = ActiveFlightPlanExecutionWatcherImpl(flightPlanRepository: repos.flightPlan)

        obstacleAvoidanceMonitor = ObstacleAvoidanceMonitorImpl(currentDroneHolder: currentDroneHolder,
                                                                activeFlightPlanWatcher: activeFlightPlanWatcher)

        locationsTracker = LocationsTrackerImpl(connectedDroneHolder: connectedDroneHolder,
                                                connectedRcHolder: connectedRemoteControlHolder)
        let joysticksAvailabilityService = JoysticksAvailabilityServiceImpl(currentMissionManager: currentMissionManager,
                                                                            connectedDroneHolder: connectedDroneHolder,
                                                                            connectedRemoteControlHolder: connectedRemoteControlHolder)

        let uiComponentsDisplayReporter = UIComponentsDisplayReporterImpl()

        let hudTopBarService = HudTopBarServiceImpl(uiComponentsDisplayReporter: uiComponentsDisplayReporter)

        let zoomService = ZoomServiceImpl(currentDroneHolder: currentDroneHolder,
                                          activeFlightPlanWatcher: activeFlightPlanWatcher)
        let gimbalTiltService = GimbalTiltServiceImpl(connectedDroneHolder: connectedDroneHolder,
                                                      activeFlightPlanWatcher: activeFlightPlanWatcher)
        let cellularPairingService = CellularPairingServiceImpl(currentDroneHolder: currentDroneHolder,
                                                                userRepo: repos.user,
                                                                connectedDroneHolder: connectedDroneHolder,
                                                                academyApiService: academyApiService)
        let cellularPairingAvailabilityService = CellularPairingAvailabilityServiceImpl(currentDroneHolder: currentDroneHolder,
                                                                                        connectedDroneHolder: connectedDroneHolder,
                                                                                        academyApiService: academyApiService,
                                                                                        cellularPairingService: cellularPairingService)
        let exposureService = ExposureServiceImpl(currentDroneHolder: currentDroneHolder)
        let exposureLockService = ExposureLockServiceImpl(currentDroneHolder: currentDroneHolder)
        let protobufMissionsManagerService = ProtobufMissionsManagerImpl(connectedDroneHolder: connectedDroneHolder,
                                                                         missionsToLoadAtDroneConnection: missionsToLoadAtStart)
        let protobufMissionListenerService = ProtobufMissionListenerImpl(currentMissionManager: currentMissionManager,
                                                                         protobufMissionManager: protobufMissionsManagerService)
        let ophtalmoService = OphtalmoServiceImpl(connectedDroneHolder: connectedDroneHolder,
                                                  protobufMissionManager: protobufMissionsManagerService,
                                                  protobufMissionsListener: protobufMissionListenerService)
        drone = DroneServices(zoomService: zoomService,
                              gimbalTiltService: gimbalTiltService,
                              cellularPairingService: cellularPairingService,
                              cellularPairingAvailabilityService: cellularPairingAvailabilityService,
                              exposureService: exposureService,
                              exposureLockService: exposureLockService,
                              protobufMissionsManager: protobufMissionsManagerService,
                              protobufMissionsListener: protobufMissionListenerService,
                              ophtalmoService: ophtalmoService)

        let flightPlanStartAvailabilityWatcher = FlightPlanStartAvailabilityWatcherImpl(currentDroneHolder: currentDroneHolder)

        let flightPlanFilesManager = FlightPlanFilesManagerImpl()

        let flightPlanManager = FlightPlanManagerImpl(persistenceFlightPlan: repos.flightPlan,
                                                      currentUser: userInformation,
                                                      filesManager: flightPlanFilesManager,
                                                      pgyProjectRepo: repos.pgyProject)

        let flightPlanEditionService = FlightPlanEditionServiceImpl(flightPlanRepo: repos.flightPlan,
                                                                    typeStore: flightPlanTypeStore,
                                                                    currentMissionManager: currentMissionManager,
                                                                    currentUser: userInformation)

        let projectManager = ProjectManagerImpl(missionsStore: missionsStore,
                                                flightPlanTypeStore: flightPlanTypeStore,
                                                persistenceProject: repos.project,
                                                flightPlanRepo: repos.flightPlan,
                                                editionService: flightPlanEditionService,
                                                currentMissionManager: currentMissionManager,
                                                currentUser: userInformation,
                                                filesManager: flightPlanFilesManager,
                                                flightPlanManager: flightPlanManager)

        let flightPlanCameraSettingsHandler = FlightPlanCameraSettingsHandlerImpl(activeFlightPlanWatcher: activeFlightPlanWatcher,
                                                                                  currentDroneHolder: currentDroneHolder,
                                                                                  projectManager: projectManager)

        let mavlinkGenerator = MavlinkGeneratorImpl(typeStore: flightPlanTypeStore,
                                                    filesManager: flightPlanFilesManager,
                                                    repo: repos.flightPlan)

        let mavlinkSender = MavlinkDroneSenderImpl(typeStore: flightPlanTypeStore, currentDroneHolder: currentDroneHolder)

        let flightPlanRunManager = FlightPlanRunManagerImpl(typeStore: flightPlanTypeStore,
                                                            projectRepo: repos.project,
                                                            currentDroneHolder: currentDroneHolder,
                                                            activeFlightPlanWatcher: activeFlightPlanWatcher,
                                                            flightPlanManager: flightPlanManager,
                                                            startAvailabilityWatcher: flightPlanStartAvailabilityWatcher)

        let flightPlanStateMachine = FlightPlanStateMachineImpl(manager: flightPlanManager,
                                                                runManager: flightPlanRunManager,
                                                                mavlinkGenerator: mavlinkGenerator,
                                                                mavlinkSender: mavlinkSender,
                                                                startAvailabilityWatcher: flightPlanStartAvailabilityWatcher,
                                                                edition: flightPlanEditionService)
        let flightPlanUiStateProvider = FlightPlanUiStateProviderImpl(stateMachine: flightPlanStateMachine,
                                                                      projectManager: projectManager)
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
                                        filesManager: flightPlanFilesManager)
        missionCatchUp = MissionCatchUpServiceImpl(connectedDroneHolder: connectedDroneHolder,
                                                   flightPlanManager: flightPlanManager,
                                                   projectService: projectManager,
                                                   missionsStore: missionsStore,
                                                   currentMissionManager: currentMissionManager,
                                                   mavlinkGenerator: mavlinkGenerator)

        let projectManagerUiProvider = ProjectManagerUiProviderImpl()

        ui = UIServices(joysticksAvailabilityService: joysticksAvailabilityService,
                        variableAssetsService: variableAssetsService,
                        hudTopBarService: hudTopBarService,
                        uiComponentsDisplayReporter: uiComponentsDisplayReporter,
                        flightPlanUiStateProvider: flightPlanUiStateProvider,
                        flightPlanExecutionDetailsSettingsProvider: flightPlanExecutionDetailsSettingsProvider,
                        projectManagerUiProvider: projectManagerUiProvider)

        let flightService = FlightServiceImpl(repo: repos.flight,
                                              fpFlightRepo: repos.flightPlanFlight,
                                              thumbnailRepo: repos.thumbnail,
                                              userInformation: userInformation,
                                              cloudSynchroWatcher: cloudSynchroWatcher)

        let gutmaWatcher = GutmaWatcherImpl(userInfo: userInformation,
                                            service: flightService,
                                            currentDroneHolder: currentDroneHolder)

        flight = FlightServices(gutmaWatcher: gutmaWatcher, service: flightService)

        panoramaService = PanoramaServiceImpl()
    }
}
