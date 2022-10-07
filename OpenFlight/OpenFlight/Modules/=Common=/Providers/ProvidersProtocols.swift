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

import GroundSdk
import UIKit
import Combine

// MARK: - Protocols
/// AccountProvider protocol
public protocol AccountProvider {
    /// Returns an image to show when needed (ie: on dashboard tile).
    var icon: UIImage { get }
    /// Returns a coordinator to start for the account details.
    var destinationCoordinator: Coordinator? { get }
    /// Returns a user avatar, if a user is connected.
    var userAvatar: String { get }
    /// Returns a user name, if a user is connected.
    var userName: String? { get }
    /// Returns if current user is connected or not.
    var isConnected: Bool { get }
    /// Returns custom dashboard account view.
    var dashboardAccountView: DashboardAccountView { get }
    /// Custom account view to display in MyFlightsVC.
    var myFlightsAccountView: MyFlightsAccountView? { get }
    /// Start a specific view from coordinator when clicking on MyFlightsAccountView.
    func startMyFlightsAccountView()
}

/// MissionProvider protocol, dedicated to provide Mission content.
public protocol MissionProvider {
    /// Returns mission description.
    var mission: Mission { get }
    /// Returns mission signature
    var signature: AirSdkMissionSignature { get }

    /// Check if given the drone active mission uid, this mission should be activated in the app
    /// - Parameter missionUid: the drone active mission uid
    func isCompatibleWith(missionUid: String) -> Bool
}

public extension MissionProvider {
    func isCompatibleWith(missionUid: String) -> Bool { signature.missionUID == missionUid }
}

// MARK: Flight Plan Provider

public struct CustomFlightPlanProgress {
    public let color: UIColor
    public let progress: Double
    public let label: String

    public init(color: UIColor, progress: Double, label: String) {
        self.color = color
        self.progress = progress
        self.label = label
    }
}

/// FlightPlanProvider protocol, dedicated to provide Flight Plan specific content.
public protocol FlightPlanProvider {
    /// Project type
    var projectType: ProjectType { get }
    /// Project title.
    var projectTitle: String { get }
    /// New button title.
    var newButtonTitle: String { get }
    /// Create first title.
    var createFirstTitle: String { get }
    /// Default project name.
    var defaultProjectName: String { get }
    /// Default capture mode.
    var defaultCaptureMode: FlightPlanCaptureMode { get }
    /// Flight Plan type.
    var typeKey: String { get }
    /// Predicate to filter stored Flight Plan, if needed.
    var filterPredicate: NSPredicate? { get }
    /// Edition type related to the Flight Plan.
    var settingsProvider: FlightPlanSettingsProvider? { get }
    /// Indicate if the settings view is always visible in edition mode.
    var settingsAlwaysDisplayed: Bool { get }
    /// Returns graphic items to diplay a Flight Plan.
    ///
    /// - Parameters:
    ///    - flightPlan: Flight Plan model
    ///    - mapMode: map mode in which the Flight Plan will be displayed
    /// - Returns: Flight Plan Graphic array
    func graphicsWithFlightPlan(_ flightPlan: FlightPlanModel, mapMode: MapMode) -> [FlightPlanGraphic]
    /// Check if this provider manages a given flight plan type
    /// - Parameter type: the flight plan type
    func hasFlightPlanType(_ type: String) -> Bool
    /// Status view to be added to the FP panel
    var statusView: UIView? { get }
    /// Indicates if the video recording time indicator can be displayed.
    var canShowVideoRecordingIndicator: Bool { get }
    /// Custom progress to take over classic progress when not nil
    var customProgressPublisher: AnyPublisher<CustomFlightPlanProgress?, Never> { get }
    /// Flight Plan execution title.
    var executionTitle: String { get }
}

/// Provides Flight Plan types.
public protocol FlightPlanSettingsProvider {
    /// Get current type.
    var currentType: FlightPlanType? { get }

    /// Returns all Flight Plan types.
    var allTypes: [FlightPlanType] { get }

    /// Returns all Flight Plan edition settings.
    var settings: [FlightPlanSetting] { get }

    /// Returns all Flight Plan edition settings categories.
    var settingsCategories: [FlightPlanSettingCategory] { get }

    /// Update the current type.
    ///
    /// - Parameters:
    ///     - tag: tag of the selected type
    func updateType(tag: Int)

    /// Update the current type.
    ///
    /// - Parameters:
    ///     - key: key of the selected type
    func updateType(key: String)

    /// Updates current settings value.
    ///
    /// - Parameters:
    ///     - key: current key for setting
    ///     - value: new value for setting
    func updateSettingValue(for key: String, value: Int)

    /// Updates current settings choice value.
    ///
    /// - Parameters:
    ///     - key: current choice key for setting
    ///     - value: current value for setting
    func updateChoiceSetting(for key: String, value: Bool)

    /// Returns the settings for a specific flight plan.
    ///
    /// - Parameters:
    ///     - flightPlan: The flight plan which we want the settings from
    /// - Returns: The settings of the flight plan
    func settings(for flightPlan: FlightPlanModel) -> [FlightPlanSetting]

    /// Returns the settings for a specific type of flight plan.
    ///
    /// - Parameters:
    ///     - type: The type of flight plan which we want the settings from
    /// - Returns: The settings for the type of flight plan
    func settings(for type: FlightPlanType) -> [FlightPlanSetting]

    /// Returns the type for a specific type of flight plan.
    ///
    /// - Parameters:
    ///     - flightPlan: The flight plan which we want the type from
    /// - Returns: The type of the flight plan
    func type(for flightPlan: FlightPlanModel) -> FlightPlanType?
}

/// `FlightPlanSettingsProvider` utility extension.
extension FlightPlanSettingsProvider {
    /// Returns true if currrent Flight Plan has a custom type.
    var hasCustomType: Bool {
        if let type = currentType, type.key != ClassicFlightPlanType.standard.key {
            return true
        }
        return false
    }
}

/// Provides a Flight Plan setting.
public protocol FlightPlanSettingType {
    /// Provides flight plan setting title.
    var title: String { get }
    /// Provides flight plan setting short title.
    var shortTitle: String? { get }
    /// Provides flight plan setting left icon.
    var leftIconImage: UIImage? { get }
    /// Provides flight plan setting right icon.
    var rightIconImage: UIImage? { get }
    /// Provides all flight plan setting values.
    var allValues: [Int] { get }
    /// Provides custom descriptions for values.
    var valueDescriptions: [String]? { get }
    /// Provides images for values.
    var valueImages: [UIImage]? { get }
    /// Provides current flight plan setting value.
    var currentValue: Int? { get }
    /// Provides cell type of the current flight plan setting.
    var type: FlightPlanSettingCellType { get }
    /// Provides flight plan setting key.
    var key: String { get }
    /// Provides setting unit.
    var unit: UnitType { get }
    /// Provides setting step between values.
    var step: Double { get }
    /// Provides if values needs to be divided.
    var divider: Double { get }
    /// Tells if the setting must be disabled.
    var isDisabled: Bool { get }
    /// Provides cell category of the current flight plan setting.
    var category: FlightPlanSettingCategory { get }
}

/// Flight plan settings type utility extension.
extension FlightPlanSettingType {
    /// Returns the value with its unit.
    func valueToDisplay() -> String {
        return self.title + self.unit.unit
    }

    public var shortTitle: String? {
        return nil
    }

    public var leftIconImage: UIImage? {
        return nil
    }

    public var rightIconImage: UIImage? {
        return nil
    }

    var currentValueDescription: String? {
        switch self.type {
        case .choice:
            return currentValue == 1 ? L10n.commonNo : L10n.commonYes
        case .centeredRuler:
            guard let value = currentValue else { return nil }

            switch unit {
            case .distance:
                return UnitHelper.stringDistanceWithDouble(Double(value), spacing: false)
            case .speed:
                var doubleValue = Double(value)
                if divider <= 1.0 {
                    doubleValue *= divider
                }

                return UnitHelper.stringSpeedWithDouble(doubleValue, spacing: false)
            default:
                return "\(value)" + unit.unit
            }
        case .adjustement:
            guard let value = currentValue else { return nil }

            if step >= 1.0 {
                return String(format: "%d %@",
                              value,
                              unit.unit)
            } else {
                return String(format: "%.1f %@",
                              Double(value) * step,
                              unit.unit)
            }
        case .fixed:
            guard let value = currentValue else { return nil }
            return "\(value)" + unit.unit
        }
    }

    /// Returns a Flight Plan Setting.
    public func toFlightPlanSetting() -> FlightPlanSetting {
        return FlightPlanSetting(title: title,
                                 shortTitle: shortTitle,
                                 leftIconImage: leftIconImage,
                                 rightIconImage: rightIconImage,
                                 allValues: allValues,
                                 valueDescriptions: valueDescriptions,
                                 valueImages: valueImages,
                                 currentValue: currentValue,
                                 type: type,
                                 key: key,
                                 unit: unit,
                                 step: step,
                                 divider: divider,
                                 isDisabled: isDisabled,
                                 category: category)
    }

    /// Returns a Flight Plan Light Setting.
    public func toLightSetting() -> FlightPlanLightSetting {
        return FlightPlanLightSetting(key: self.key,
                                      currentValue: self.currentValue)
    }
}

/// Array extension for Flight Plan Light Setting.
extension Array where Element == FlightPlanSettingType {
    /// Returns an array of Flight Plan Light Settings.
    public func toLightSettings() -> [FlightPlanLightSetting] {
        return self.map({ $0.toLightSetting() })
    }

    /// Returns an array of Flight Plan Settings.
    public func toFlightPlanSettings() -> [FlightPlanSetting] {
        return self.map({ $0.toFlightPlanSetting() })
    }
}

/// Describes a Flight Plan type.
public protocol FlightPlanType {
    /// Type's title.
    var title: String { get }
    /// Type's icon.
    var icon: UIImage { get }
    /// Type's tag.
    var tag: Int { get }
    /// Type's key.
    var key: String { get }
    /// Allow generating MAVlink from Flight Plan.
    var canGenerateMavlink: Bool { get }
    /// Specify the type of the mavlink generation.
    var mavLinkType: FlightPlanInterpreter { get }
    /// Mission provider
    var missionProvider: MissionProvider { get }
    /// Mission mode
    var missionMode: MissionMode { get }
}

/// Protocols used to provide mission activation methods.
public protocol MissionActivationModel {
    /// Starts a Mission.
    func startMission()
    /// Stops a Mission if needed.
    func stopMissionIfNeeded()
    /// Whether the mission can be stop.
    func canStopMission() -> Bool
    /// Whether the mission can be start.
    func canStartMission() -> Bool
    /// Show failed activation message.
    func showFailedActivationMessage()
    /// Show failed deactivation message.
    func showFailedDectivationMessage()
    /// Is mission active
    func isActive() -> Bool
    /// Priority of mission
    func getPriority() -> MissionPriority
}

/// Protocols used to provide camera configuration restrictions for a mission.
public protocol MissionCameraRestrictionsModel {
    /// Camera capture modes supported by the mission.
    var supportedModes: [CameraCaptureMode] { get }
    /// Camera recording framerates supported by the mission, by recording resolution.
    var supportedFrameratesByResolution: [Camera2RecordingResolution: Set<Camera2RecordingFramerate>]? { get }
}

// MARK: - Structs

/// Mission description.
public struct Mission: Equatable {
    /// Returns mission key.
    var key: String
    /// Returns mission name.
    var name: String
    /// Returns mission icon.
    var icon: UIImage
    /// Log name.
    var logName: String

    /// Returns default mission mode.
    /// Mission have usually only one mode.
    public var defaultMode: MissionMode

    /// Default struct init, as public.
    public init(key: String,
                name: String,
                icon: UIImage,
                logName: String,
                mode: MissionMode) {
        self.key = key
        self.name = name
        self.icon = icon
        self.logName = logName
        self.defaultMode = mode
    }

    /// Init with one mission mode, as public.
    public init(mode: MissionMode) {
        self.init(key: mode.key,
                  name: mode.name,
                  icon: mode.icon,
                  logName: mode.logName,
                  mode: mode)
    }

    public static func == (lhs: Mission, rhs: Mission) -> Bool {
        lhs.key == rhs.key
        && lhs.name == rhs.name
        && lhs.icon == rhs.icon
        && lhs.logName == rhs.logName
        && lhs.defaultMode == rhs.defaultMode
    }
}

/// Configurator for primary items of a MissionMode.
public struct MissionModeConfigurator {
    /// Returns mode key.
    var key: String
    /// Returns mode name.
    var name: String
    /// Returns mode icon.
    var icon: UIImage
    /// Log name.
    var logName: String
    /// Returns SplitScreenMode for this mode.
    var preferredSplitMode: SplitScreenMode
    /// Returns if map should always be visible instead of other right panel components.
    var isMapRequired: Bool
    /// Returns if FlightPlan panel is requiered for this mode.
    var isRightPanelRequired: Bool
    /// Returns true if this mode supports AE Lock.
    var isAeLockEnabled: Bool
    /// Returns the RTH title to show.
    var rthTitle: (ReturnHomeTarget?) -> String
    /// Returns if this mode is a Tracking one.
    var isTrackingMode: Bool
    /// Returns if this mode requires that the mission is installed.
    var isInstallationRequired: Bool
    /// Returns true if the camera shutter button is enabled
    var isCameraShutterButtonEnabled: Bool
    /// Returns true if the target is on stream
    var isTargetOnStream: Bool

    /// Default struct init, as public.
    public init(key: String,
                name: String,
                icon: UIImage,
                logName: String,
                preferredSplitMode: SplitScreenMode,
                isMapRequired: Bool,
                isRightPanelRequired: Bool,
                rthTitle: ((ReturnHomeTarget?) -> String)? = nil,
                isTrackingMode: Bool,
                isAeLockEnabled: Bool,
                isInstallationRequired: Bool,
                isCameraShutterButtonEnabled: Bool,
                isTargetOnStream: Bool) {
        self.key = key
        self.name = name
        self.icon = icon
        self.logName = logName
        self.preferredSplitMode = preferredSplitMode
        self.isMapRequired = isMapRequired
        self.isRightPanelRequired = isRightPanelRequired
        self.rthTitle = rthTitle ?? { target in
            switch target {
            case .controllerPosition:
                return L10n.alertReturnPilotTitle
            case .takeOffPosition:
                return L10n.alertReturnHomeTitle
            default:
                return L10n.alertReturnHomeTitle
            }
        }
        self.isTrackingMode = isTrackingMode
        self.isAeLockEnabled = isAeLockEnabled
        self.isInstallationRequired = isInstallationRequired
        self.isCameraShutterButtonEnabled = isCameraShutterButtonEnabled
        self.isTargetOnStream = isTargetOnStream
    }
}

public typealias HudRightPanelContentProvider = (_ services: ServiceHub,
                                                 _ splitControls: SplitControls,
                                                 _ rightPanelContainerControls: RightPanelContainerControls) -> Coordinator?
/// Mission Mode description.
public struct MissionMode: Equatable {
    /// Returns mission item key.
    public var key: String
    /// Returns mission item name.
    var name: String
    /// Returns mission item icon.
    var icon: UIImage
    /// Log name.
    var logName: String
    /// Returns preferred split screen mode.
    var preferredSplitMode: SplitScreenMode
    /// Returns if map should always be visible instead of other right panel components.
    var isMapRequired: Bool
    /// Returns if mission installation is required to display this mode
    var isInstallationRequired: Bool
    /// Returns true if HUD right panel is needed for this mode.
    var isRightPanelRequired: Bool
    /// Return a coordinator that should be inserted in the right panel if any
    var hudRightPanelContentProvider: HudRightPanelContentProvider
    /// Returns true if the camera shutter button is enabled
    var isCameraShutterButtonEnabled: Bool
    /// Default map mode for this mission
    public var mapMode: MapMode
    /// Returns Flight Plan provider.
    public var flightPlanProvider: FlightPlanProvider? // TODO: make it smarter by directly handling current mission mode
    /// Returns a model for mission activation.
    public var missionActivationModel: MissionActivationModel
    /// Provides Return to Home Target type title.
    var rthTitle: (ReturnHomeTarget?) -> String
    /// Returns true if this mode is a tracking one.
    var isTrackingMode: Bool
    /// Returns true if this mode supports AE Lock.
    var isAeLockEnabled: Bool
    /// Returns true if this mode supports touch in stream
    var isTargetOnStream: Bool
    /// Returns an array of elements to display in the right stack of the bottom bar.
    var bottomBarRightStack: [ImagingStackElement]
    /// State machine
    public var stateMachine: FlightPlanStateMachine?
    /// Camera restrictions model for this mission, `nil` if there is no restrictions.
    public var cameraRestrictions: MissionCameraRestrictionsModel?

    // MARK: Completion handler properties
    /// Using completion handler properties to create variable only when they are called and not when instantiating the struct.
    /// Returns map view controller to show for this mission mode.
    public var customMapProvider: (() -> UIViewController?)?
    /// Returns custom coordinator to present at mode entry.
    public var entryCoordinatorProvider: (() -> Coordinator)?
    /// Returns an array of views to display in the left stackView on the bottom bar.
    var bottomBarLeftStack: (() -> [UIView])?

    /// Default struct init, as public.
    public init(configurator: MissionModeConfigurator,
                flightPlanProvider: FlightPlanProvider? = nil,
                missionActivationModel: MissionActivationModel = DefaultMissionActivationModel(),
                mapMode: MapMode = .standard,
                customMapProvider: (() -> UIViewController)? = nil,
                entryCoordinatorProvider: (() -> Coordinator)? = nil,
                bottomBarLeftStack: (() -> [UIView])?,
                bottomBarRightStack: [ImagingStackElement],
                stateMachine: FlightPlanStateMachine? = nil,
                hudRightPanelContentProvider: HudRightPanelContentProvider? = nil,
                cameraRestrictions: MissionCameraRestrictionsModel? = nil) {
        self.key = configurator.key
        self.name = configurator.name
        self.icon = configurator.icon
        self.logName = configurator.logName
        self.preferredSplitMode = configurator.preferredSplitMode
        self.isMapRequired = configurator.isMapRequired
        self.isRightPanelRequired = configurator.isRightPanelRequired
        self.rthTitle = configurator.rthTitle
        self.isTrackingMode = configurator.isTrackingMode
        self.mapMode = mapMode
        self.flightPlanProvider = flightPlanProvider
        self.missionActivationModel = missionActivationModel
        self.customMapProvider = customMapProvider
        self.entryCoordinatorProvider = entryCoordinatorProvider
        self.bottomBarLeftStack = bottomBarLeftStack
        self.bottomBarRightStack = bottomBarRightStack
        self.stateMachine = stateMachine
        self.hudRightPanelContentProvider = hudRightPanelContentProvider ?? { _, _, _ in nil }
        self.cameraRestrictions = cameraRestrictions
        self.isAeLockEnabled = configurator.isAeLockEnabled
        self.isInstallationRequired = configurator.isInstallationRequired
        self.isCameraShutterButtonEnabled = configurator.isCameraShutterButtonEnabled
        self.isTargetOnStream = configurator.isTargetOnStream
    }

    // MARK: - Equatable Implementation
    public static func == (lhs: MissionMode, rhs: MissionMode) -> Bool {
        return lhs.key == rhs.key
    }
}

// MARK: - Public Enums
/// Provides a view type for a Flight plan setting.
/// In a few words, it stores each type of display for a setting value.
public enum FlightPlanSettingCellType {
    case choice
    case adjustement
    case centeredRuler
    case fixed
}

/// Flight plan settings categories.
public enum FlightPlanSettingCategory: Hashable {
    case common
    case image
    case rth
    case custom(String)

    /// Returns title category settings.
    var title: String {
        switch self {
        case .common:
            return L10n.flightPlanSettingsTitle
        case .image:
            return L10n.flightPlanMenuImage
        case .custom(let title):
            return title
        case .rth:
            return L10n.flightPlanSettingsRthTitle
        }
    }
}
