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

import UIKit
import GroundSdk
import SwiftyUserDefaults
import CoreData
import ArcGIS
import Combine
import Pictor

// MARK: - Internal Enums
/// Constants for all missions.
enum MissionsConstants {
    static let classicMissionManualKey: String = "classicManual"
    static let classicMissionTouchAndFlyKey: String = "classicTouchAndFly"
    static let classicMissionCameramanKey: String = "classicCameraman"
}

public extension ULogTag {
    static let appDelegate = ULogTag(name: "AppDelegate")
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    // MARK: - Public Properties
    var window: UIWindow?

    // MARK: - Private Properties
    /// Main coordinator of the application.
    private var appCoordinator: AppCoordinator!
    /// Service hub.
    private var services: ServiceHub!
    /// Inits Grab view model.
    private var grabberViewModel: RemoteControlGrabberViewModel!
    /// Retain a GroundSdk session opened during all application lifecycle.
    private var groundSdk: GroundSdk!

    // MARK: - Public Funcs
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Enable device battery monitoring.
        UIDevice.current.isBatteryMonitoringEnabled = true
        // ARCGIS KEY - Openflight
        AGSArcGISRuntimeEnvironment.apiKey = "put-your-Arcgis-key-here"

        // Enable gsdk system log
        ULog.redirectToSystemLog(enabled: true)

        // Setup GroundSdk and retain it
        groundSdk = AppDelegateSetup.sdkSetup()

        ULog.i(.appDelegate, "Application start \(AppUtils.version)")
        Defaults.applicationVersion = AppUtils.version

        // Sets up Pictor
        AppDelegateSetup.pictorSetup()

        // Create instance of services
        let missionsToLoadAtStart: [AirSdkMissionSignature] = [OFMissionSignatures.defaultMission,
                                                               OFMissionSignatures.helloWorld]

        let services = Services.createInstance(variableAssetsService: VariableAssetsServiceImpl(),
                                               missionsToLoadAtStart: missionsToLoadAtStart,
                                               dashboardUiProvider: DashboardUiProviderImpl())
        self.services = services
        services.start()
        // TODO move to service hub
        addMissionsToHUDPanel()

        // Sets up grabber view model
        grabberViewModel = RemoteControlGrabberViewModel(zoomService: services.drone.zoomService,
                                                         gimbalTiltService: services.drone.gimbalTiltService)

        // Start AppCoordinator.
        self.appCoordinator = AppCoordinator(services: services)
        self.appCoordinator.start()

        /// Configure Main Window of the App.
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.backgroundColor = ColorName.defaultBgcolor.color
        self.window?.rootViewController = self.appCoordinator.navigationController
        self.window?.makeKeyAndVisible()

        // Keep screen on while app is running (Enable).
        application.isIdleTimerDisabled = true

        // Check for database update
        self.services.databaseUpdateService.checkForUpdate()

        NSSetUncaughtExceptionHandler { exception in
            ULog.e(.appDelegate, "Uncaught exception \(exception). Backtrace: \(exception.callStackSymbols)")
        }
        return true
    }

    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        guard services.flightPlan.filesManager.isMavlinkUrl(url) else { return false }

        services.flightPlan.projectManager.newProjectFromMavlinkFile(url) { [unowned self] project in
            if let project = project {
                services.flightPlan.projectManager.loadEverythingAndOpen(project: project)
            }
        }

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        grabberViewModel.ungrabAll()
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.landscapeRight
    }
}

// MARK: - AirSdkMissionsSetupProtocol
extension AppDelegate: AirSdkMissionsSetupProtocol {
    /// Add AirSdk missions to the HUD Panel.
    func addMissionsToHUDPanel() {
        services.missionsStore.add(missions: [FlightPlanMission(),
                                              CameramanMission(),
                                              TouchAndFlyMission(),
                                              HelloWorldMission()])
    }
}

// MARK: - Setup
/// This class groups AppDelegate setups in a public static function
///  to prevent from missing changes in other targets.

public class AppDelegateSetup {
    static var cancellables = Set<AnyCancellable>()

    /// Setup GroundSDK.
    public static func sdkSetup() -> GroundSdk {
        // Set optional config BEFORE starting GroundSdk
        AppUtils.setLogLevel()
        ParrotDebug.smartStartLog()

        // Activate DevToolbox.
        GroundSdkConfig.sharedInstance.enableDevToolbox = true

        if Defaults.debugC == true {
            GroundSdkConfig.sharedInstance.autoSelectWifiCountry = false
        }
        return GroundSdk()
    }

    public static func pictorSetup() {
        PictorConfiguration.shared.userAgent = "\(AppInfoCore.appBundle)/\(AppInfoCore.appVersion) " +
        "(\(UIDevice.current.systemName); \(UIDevice.identifier); \(UIDevice.current.systemVersion)) " +
        "\(AppInfoCore.sdkBundle)/\(AppInfoCore.sdkVersion)"

        let container = PersistentContainer(name: "Model")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        PictorConfiguration.shared.oldPersistentContainer = container

        Pictor.shared.logPublisher
            .sink { log in
                switch log.level {
                case .warning:
                    ULog.w(ULogTag(name: log.tag), log.message)
                case .info:
                    ULog.i(ULogTag(name: log.tag), log.message)
                case .debug:
                    ULog.d(ULogTag(name: log.tag), log.message)
                case .error:
                    ULog.e(ULogTag(name: log.tag), log.message)
                }
            }
            .store(in: &cancellables)
    }
}
