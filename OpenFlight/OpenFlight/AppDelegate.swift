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

// MARK: - Internal Enums
/// Constants for all missions.
enum MissionsConstants {
    static let classicMissionManualKey: String = "classicManual"
    static let classicMissionTouchAndFlyKey: String = "classicTouchAndFly"
}

public extension ULogTag {
    static let appDelegate = ULogTag(name: "AppDelegate")
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    // MARK: - Public Properties
    var window: UIWindow?

    lazy var persistentContainer: NSPersistentContainer = {
        let container = PersistentContainer(name: "Model")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        return container
    }()

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

        // Enable gsdk system log
        ULog.redirectToSystemLog(enabled: true)

        // Setup GroundSdk and retain it
        groundSdk = AppDelegateSetup.sdkSetup()

        ULog.i(.appDelegate, "Application start \(AppUtils.version)")

        // Create instance of services
        let missionsToLoadAtStart: [AirSdkMissionSignature] = [OFMissionSignatures.defaultMission,
                                                               OFMissionSignatures.helloWorld]

        let services = Services.createInstance(variableAssetsService: VariableAssetsServiceImpl(),
                                               persistentContainer: persistentContainer,
                                               missionsToLoadAtStart: missionsToLoadAtStart,
                                               dashboardUiProvider: DashboardUiProviderImpl())
        self.services = services
        services.start()
        // TODO move to service hub
        addMissionsToHUDPanel()

        // Sets up grabber view model
        grabberViewModel = RemoteControlGrabberViewModel(zoomService: services.drone.zoomService,
                                                         gimbalTiltService: services.drone.gimbalTiltService)

        setupFirmwareAndMissionsInteractor()

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
    /// Sets up `FirmwareAndMissionsInteractor`
    func setupFirmwareAndMissionsInteractor() {
        FirmwareAndMissionsInteractor.shared.setup()
    }

    /// Add AirSdk missions to the HUD Panel.
    func addMissionsToHUDPanel() {
        services.missionsStore.add(missions: [FlightPlanMission(),
                                              HelloWorldMission()])
    }
}

// MARK: - Setup
/// This class groups AppDelegate setups in a public static function
///  to prevent from missing changes in other targets.

public class AppDelegateSetup {
    /// Setup GroundSDK.
    public static func sdkSetup() -> GroundSdk {
        // Set optional config BEFORE starting GroundSdk
        #if DEBUG
        setenv("ULOG_LEVEL", "D", 1)
        #else
        if Bundle.main.isInHouseBuild {
            setenv("ULOG_LEVEL", "D", 1)
        }
        #endif
        ParrotDebug.smartStartLog()

        // Activate DevToolbox.
        GroundSdkConfig.sharedInstance.enableDevToolbox = true

        if Defaults.debugC == true {
            GroundSdkConfig.sharedInstance.autoSelectWifiCountry = false
        }
        return GroundSdk()
    }

}
