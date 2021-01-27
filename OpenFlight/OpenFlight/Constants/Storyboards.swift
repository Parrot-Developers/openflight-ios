// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

// swiftlint:disable sorted_imports
import Foundation
import UIKit

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// MARK: - Storyboard Scenes

// swiftlint:disable explicit_type_interface identifier_name line_length type_body_length type_name
internal enum StoryboardScene {
  internal enum AlertViewController: StoryboardType {
    internal static let storyboardName = "AlertViewController"

    internal static let initialScene = InitialSceneType<OpenFlight.AlertViewController>(storyboard: AlertViewController.self)

    internal static let alertViewController = SceneType<OpenFlight.AlertViewController>(storyboard: AlertViewController.self, identifier: "AlertViewController")
  }
  internal enum BehavioursViewController: StoryboardType {
    internal static let storyboardName = "BehavioursViewController"

    internal static let initialScene = InitialSceneType<OpenFlight.BehavioursViewController>(storyboard: BehavioursViewController.self)

    internal static let behavioursViewController = SceneType<OpenFlight.BehavioursViewController>(storyboard: BehavioursViewController.self, identifier: "BehavioursViewController")
  }
  internal enum BottomBar: StoryboardType {
    internal static let storyboardName = "BottomBar"

    internal static let initialScene = InitialSceneType<OpenFlight.BottomBarContainerViewController>(storyboard: BottomBar.self)
  }
  internal enum CameraSliders: StoryboardType {
    internal static let storyboardName = "CameraSliders"

    internal static let initialScene = InitialSceneType<OpenFlight.CameraSlidersViewController>(storyboard: CameraSliders.self)
  }
  internal enum CellularAccessCardPin: StoryboardType {
    internal static let storyboardName = "CellularAccessCardPin"

    internal static let initialScene = InitialSceneType<OpenFlight.CellularAccessCardPinViewController>(storyboard: CellularAccessCardPin.self)

    internal static let cellularAccessCardPinViewcontrollerViewController = SceneType<OpenFlight.CellularAccessCardPinViewController>(storyboard: CellularAccessCardPin.self, identifier: "CellularAccessCardPinViewcontrollerViewController")
  }
  internal enum CellularAvailable: StoryboardType {
    internal static let storyboardName = "CellularAvailable"

    internal static let initialScene = InitialSceneType<OpenFlight.CellularAvailableViewController>(storyboard: CellularAvailable.self)

    internal static let cellularConnectionAvailableViewController = SceneType<OpenFlight.CellularAvailableViewController>(storyboard: CellularAvailable.self, identifier: "CellularConnectionAvailableViewController")
  }
  internal enum CellularPairingProcess: StoryboardType {
    internal static let storyboardName = "CellularPairingProcess"

    internal static let initialScene = InitialSceneType<OpenFlight.CellularPairingProcessViewController>(storyboard: CellularPairingProcess.self)

    internal static let cellularLoginSucceedViewController = SceneType<OpenFlight.CellularPairingProcessViewController>(storyboard: CellularPairingProcess.self, identifier: "CellularLoginSucceedViewController")
  }
  internal enum Dashboard: StoryboardType {
    internal static let storyboardName = "Dashboard"

    internal static let initialScene = InitialSceneType<OpenFlight.DashboardViewController>(storyboard: Dashboard.self)

    internal static let dashboardViewController = SceneType<OpenFlight.DashboardViewController>(storyboard: Dashboard.self, identifier: "DashboardViewController")
  }
  internal enum DeviceUpdate: StoryboardType {
    internal static let storyboardName = "DeviceUpdate"

    internal static let deviceConfirmUpdate = SceneType<OpenFlight.DeviceConfirmUpdateViewController>(storyboard: DeviceUpdate.self, identifier: "DeviceConfirmUpdate")

    internal static let deviceUpdate = SceneType<OpenFlight.DeviceUpdateViewController>(storyboard: DeviceUpdate.self, identifier: "DeviceUpdate")
  }
  internal enum DroneCalibration: StoryboardType {
    internal static let storyboardName = "DroneCalibration"

    internal static let initialScene = InitialSceneType<OpenFlight.DroneCalibrationViewController>(storyboard: DroneCalibration.self)

    internal static let droneCalibrationViewController = SceneType<OpenFlight.DroneCalibrationViewController>(storyboard: DroneCalibration.self, identifier: "DroneCalibrationViewController")

    internal static let droneGimbalCalibrationViewController = SceneType<OpenFlight.DroneGimbalCalibrationViewController>(storyboard: DroneCalibration.self, identifier: "DroneGimbalCalibrationViewController")

    internal static let magnetometerCalibrationViewController = SceneType<OpenFlight.MagnetometerCalibrationViewController>(storyboard: DroneCalibration.self, identifier: "MagnetometerCalibrationViewController")
  }
  internal enum DroneDetails: StoryboardType {
    internal static let storyboardName = "DroneDetails"

    internal static let initialScene = InitialSceneType<OpenFlight.DroneDetailsViewController>(storyboard: DroneDetails.self)

    internal static let droneDetailsCellularViewController = SceneType<OpenFlight.DroneDetailsCellularViewController>(storyboard: DroneDetails.self, identifier: "DroneDetailsCellularViewController")

    internal static let droneDetailsFirmwareViewController = SceneType<OpenFlight.DroneDetailsFirmwareViewController>(storyboard: DroneDetails.self, identifier: "DroneDetailsFirmwareViewController")

    internal static let droneDetailsInformationsViewController = SceneType<OpenFlight.DroneDetailsInformationsViewController>(storyboard: DroneDetails.self, identifier: "DroneDetailsInformationsViewController")

    internal static let droneDetailsViewController = SceneType<OpenFlight.DroneDetailsViewController>(storyboard: DroneDetails.self, identifier: "DroneDetailsViewController")

    internal static let droneDetailsMapViewController = SceneType<OpenFlight.DroneDetailsMapViewController>(storyboard: DroneDetails.self, identifier: "droneDetailsMapViewController")
  }
  internal enum FlightPlanDashboardViewController: StoryboardType {
    internal static let storyboardName = "FlightPlanDashboardViewController"

    internal static let initialScene = InitialSceneType<OpenFlight.FlightPlanDashboardViewController>(storyboard: FlightPlanDashboardViewController.self)

    internal static let flightPlanDashboardViewController = SceneType<OpenFlight.FlightPlanDashboardViewController>(storyboard: FlightPlanDashboardViewController.self, identifier: "FlightPlanDashboardViewController")

    internal static let flightPlanFullHistoryViewController = SceneType<OpenFlight.FlightPlanFullHistoryViewController>(storyboard: FlightPlanDashboardViewController.self, identifier: "FlightPlanFullHistoryViewController")

    internal static let flightPlanHistoryViewController = SceneType<OpenFlight.FlightPlanHistoryViewController>(storyboard: FlightPlanDashboardViewController.self, identifier: "FlightPlanHistoryViewController")
  }
  internal enum FlightPlanEdition: StoryboardType {
    internal static let storyboardName = "FlightPlanEdition"

    internal static let initialScene = InitialSceneType<OpenFlight.FlightPlanEditionViewController>(storyboard: FlightPlanEdition.self)
  }
  internal enum FlightPlanPanel: StoryboardType {
    internal static let storyboardName = "FlightPlanPanel"

    internal static let initialScene = InitialSceneType<OpenFlight.FlightPlanPanelViewController>(storyboard: FlightPlanPanel.self)

    internal static let missionModeSelectorViewController = SceneType<OpenFlight.FlightPlanPanelViewController>(storyboard: FlightPlanPanel.self, identifier: "MissionModeSelectorViewController")
  }
  internal enum FlightPlansList: StoryboardType {
    internal static let storyboardName = "FlightPlansList"

    internal static let initialScene = InitialSceneType<OpenFlight.FlightPlansListViewController>(storyboard: FlightPlansList.self)

    internal static let flightPlansListViewController = SceneType<OpenFlight.FlightPlansListViewController>(storyboard: FlightPlansList.self, identifier: "FlightPlansListViewController")
  }
  internal enum FlightReport: StoryboardType {
    internal static let storyboardName = "FlightReport"

    internal static let flightReportViewController = SceneType<OpenFlight.FlightReportViewController>(storyboard: FlightReport.self, identifier: "FlightReportViewController")
  }
  internal enum FlightsViewController: StoryboardType {
    internal static let storyboardName = "FlightsViewController"

    internal static let initialScene = InitialSceneType<OpenFlight.FlightsViewController>(storyboard: FlightsViewController.self)

    internal static let flightDetailsViewController = SceneType<OpenFlight.FlightDetailsViewController>(storyboard: FlightsViewController.self, identifier: "FlightDetailsViewController")

    internal static let flightsViewController = SceneType<OpenFlight.FlightsViewController>(storyboard: FlightsViewController.self, identifier: "FlightsViewController")
  }
  internal enum GalleryComponentsViewController: StoryboardType {
    internal static let storyboardName = "GalleryComponentsViewController"

    internal static let galleryFiltersViewController = SceneType<OpenFlight.GalleryFiltersViewController>(storyboard: GalleryComponentsViewController.self, identifier: "GalleryFiltersViewController")

    internal static let galleryMediaViewController = SceneType<OpenFlight.GalleryMediaViewController>(storyboard: GalleryComponentsViewController.self, identifier: "GalleryMediaViewController")

    internal static let gallerySourcesViewController = SceneType<OpenFlight.GallerySourcesViewController>(storyboard: GalleryComponentsViewController.self, identifier: "GallerySourcesViewController")
  }
  internal enum GalleryFormatSDCard: StoryboardType {
    internal static let storyboardName = "GalleryFormatSDCard"

    internal static let initialScene = InitialSceneType<OpenFlight.GalleryFormatSDCardViewController>(storyboard: GalleryFormatSDCard.self)

    internal static let droneCalibrationViewController = SceneType<OpenFlight.GalleryFormatSDCardViewController>(storyboard: GalleryFormatSDCard.self, identifier: "DroneCalibrationViewController")
  }
  internal enum GalleryMediaPlayerViewController: StoryboardType {
    internal static let storyboardName = "GalleryMediaPlayerViewController"

    internal static let initialScene = InitialSceneType<OpenFlight.GalleryMediaPlayerViewController>(storyboard: GalleryMediaPlayerViewController.self)

    internal static let galleryImageViewController = SceneType<OpenFlight.GalleryImageViewController>(storyboard: GalleryMediaPlayerViewController.self, identifier: "GalleryImageViewController")

    internal static let galleryMediaPlayerViewController = SceneType<OpenFlight.GalleryMediaPlayerViewController>(storyboard: GalleryMediaPlayerViewController.self, identifier: "GalleryMediaPlayerViewController")

    internal static let galleryPanoramaViewController = SceneType<OpenFlight.GalleryPanoramaViewController>(storyboard: GalleryMediaPlayerViewController.self, identifier: "GalleryPanoramaViewController")

    internal static let galleryVideoViewController = SceneType<OpenFlight.GalleryVideoViewController>(storyboard: GalleryMediaPlayerViewController.self, identifier: "GalleryVideoViewController")
  }
  internal enum GalleryPanorama: StoryboardType {
    internal static let storyboardName = "GalleryPanorama"

    internal static let initialScene = InitialSceneType<OpenFlight.GalleryPanoramaChoiceTypeViewController>(storyboard: GalleryPanorama.self)

    internal static let galleryPanoramaChooseTypeViewController = SceneType<OpenFlight.GalleryPanoramaChoiceTypeViewController>(storyboard: GalleryPanorama.self, identifier: "GalleryPanoramaChooseTypeViewController")

    internal static let galleryPanoramaDownloadViewController = SceneType<OpenFlight.GalleryPanoramaDownloadViewController>(storyboard: GalleryPanorama.self, identifier: "GalleryPanoramaDownloadViewController")

    internal static let galleryPanoramaGenerationViewController = SceneType<OpenFlight.GalleryPanoramaGenerationViewController>(storyboard: GalleryPanorama.self, identifier: "GalleryPanoramaGenerationViewController")

    internal static let galleryPanoramaQuality = SceneType<OpenFlight.GalleryPanoramaQualityViewController>(storyboard: GalleryPanorama.self, identifier: "GalleryPanoramaQuality")
  }
  internal enum GalleryViewController: StoryboardType {
    internal static let storyboardName = "GalleryViewController"

    internal static let initialScene = InitialSceneType<OpenFlight.GalleryViewController>(storyboard: GalleryViewController.self)

    internal static let galleryViewController = SceneType<OpenFlight.GalleryViewController>(storyboard: GalleryViewController.self, identifier: "GalleryViewController")
  }
  internal enum Hud: StoryboardType {
    internal static let storyboardName = "HUD"

    internal static let initialScene = InitialSceneType<OpenFlight.HUDViewController>(storyboard: Hud.self)

    internal static let hudViewController = SceneType<OpenFlight.HUDViewController>(storyboard: Hud.self, identifier: "HUDViewController")
  }
  internal enum HUDAlertBanner: StoryboardType {
    internal static let storyboardName = "HUDAlertBanner"

    internal static let initialScene = InitialSceneType<OpenFlight.HUDAlertBannerViewController>(storyboard: HUDAlertBanner.self)

    internal static let hudAlertBannerViewController = SceneType<OpenFlight.HUDAlertBannerViewController>(storyboard: HUDAlertBanner.self, identifier: "HUDAlertBannerViewController")
  }
  internal enum HUDAlertPanel: StoryboardType {
    internal static let storyboardName = "HUDAlertPanel"

    internal static let initialScene = InitialSceneType<OpenFlight.HUDAlertPanelViewController>(storyboard: HUDAlertPanel.self)
  }
  internal enum HUDCameraStreaming: StoryboardType {
    internal static let storyboardName = "HUDCameraStreaming"

    internal static let initialScene = InitialSceneType<OpenFlight.HUDCameraStreamingViewController>(storyboard: HUDCameraStreaming.self)
  }
  internal enum HUDIndicator: StoryboardType {
    internal static let storyboardName = "HUDIndicator"

    internal static let initialScene = InitialSceneType<OpenFlight.HUDIndicatorViewController>(storyboard: HUDIndicator.self)

    internal static let hudIndicator = SceneType<OpenFlight.HUDIndicatorViewController>(storyboard: HUDIndicator.self, identifier: "HUDIndicator")
  }
  internal enum HUDTakeOffAlert: StoryboardType {
    internal static let storyboardName = "HUDTakeOffAlert"

    internal static let initialScene = InitialSceneType<OpenFlight.HUDCriticalAlertViewController>(storyboard: HUDTakeOffAlert.self)

    internal static let takeOffAlertViewController = SceneType<OpenFlight.HUDCriticalAlertViewController>(storyboard: HUDTakeOffAlert.self, identifier: "TakeOffAlertViewController")
  }
  internal enum HUDTopBanner: StoryboardType {
    internal static let storyboardName = "HUDTopBanner"

    internal static let initialScene = InitialSceneType<OpenFlight.HUDTopBannerViewController>(storyboard: HUDTopBanner.self)
  }
  internal enum HUDTopBar: StoryboardType {
    internal static let storyboardName = "HUDTopBar"

    internal static let initialScene = InitialSceneType<OpenFlight.HUDTopBarViewController>(storyboard: HUDTopBar.self)

    internal static let controllerInfoViewController = SceneType<OpenFlight.HUDControllerInfoViewController>(storyboard: HUDTopBar.self, identifier: "ControllerInfoViewController")

    internal static let droneInfoViewController = SceneType<OpenFlight.HUDDroneInfoViewController>(storyboard: HUDTopBar.self, identifier: "DroneInfoViewController")

    internal static let telemetryBarViewController = SceneType<OpenFlight.TelemetryBarViewController>(storyboard: HUDTopBar.self, identifier: "TelemetryBarViewController")

    internal static let topBarViewController = SceneType<OpenFlight.HUDTopBarViewController>(storyboard: HUDTopBar.self, identifier: "TopBarViewController")
  }
  internal enum HorizonCorrection: StoryboardType {
    internal static let storyboardName = "HorizonCorrection"

    internal static let horizonCorrectionViewController = SceneType<OpenFlight.HorizonCorrectionViewController>(storyboard: HorizonCorrection.self, identifier: "HorizonCorrectionViewController")
  }
  internal enum ImagingSettingsBar: StoryboardType {
    internal static let storyboardName = "ImagingSettingsBar"

    internal static let initialScene = InitialSceneType<OpenFlight.ImagingSettingsBarViewController>(storyboard: ImagingSettingsBar.self)

    internal static let imagingSettingsBarViewController = SceneType<OpenFlight.ImagingSettingsBarViewController>(storyboard: ImagingSettingsBar.self, identifier: "ImagingSettingsBarViewController")
  }
  internal enum LiveStreaming: StoryboardType {
    internal static let storyboardName = "LiveStreaming"

    internal static let liveStreamingViewController = SceneType<OpenFlight.LiveStreamingViewController>(storyboard: LiveStreaming.self, identifier: "LiveStreamingViewController")
  }
  internal enum LockAETargetZone: StoryboardType {
    internal static let storyboardName = "LockAETargetZone"

    internal static let initialScene = InitialSceneType<OpenFlight.LockAETargetZoneViewController>(storyboard: LockAETargetZone.self)

    internal static let lockAETargetZoneViewController = SceneType<OpenFlight.LockAETargetZoneViewController>(storyboard: LockAETargetZone.self, identifier: "LockAETargetZoneViewController")
  }
  internal enum LoveBlended: StoryboardType {
    internal static let storyboardName = "LoveBlended"

    internal static let initialScene = InitialSceneType<OpenFlight.StereoVisionBlendedViewController>(storyboard: LoveBlended.self)

    internal static let loveBlendedViewController = SceneType<OpenFlight.StereoVisionBlendedViewController>(storyboard: LoveBlended.self, identifier: "LoveBlendedViewController")
  }
  internal enum ManagePlans: StoryboardType {
    internal static let storyboardName = "ManagePlans"

    internal static let initialScene = InitialSceneType<OpenFlight.ManagePlansViewController>(storyboard: ManagePlans.self)
  }
  internal enum Map: StoryboardType {
    internal static let storyboardName = "Map"

    internal static let initialScene = InitialSceneType<OpenFlight.MapViewController>(storyboard: Map.self)

    internal static let mapViewController = SceneType<OpenFlight.MapViewController>(storyboard: Map.self, identifier: "MapViewController")
  }
  internal enum MarketingViewController: StoryboardType {
    internal static let storyboardName = "MarketingViewController"

    internal static let marketingViewController = SceneType<OpenFlight.MarketingViewController>(storyboard: MarketingViewController.self, identifier: "MarketingViewController")
  }
  internal enum Missions: StoryboardType {
    internal static let storyboardName = "Missions"

    internal static let initialScene = InitialSceneType<OpenFlight.MissionProviderSelectorViewController>(storyboard: Missions.self)

    internal static let missionProviderSelectorViewController = SceneType<OpenFlight.MissionProviderSelectorViewController>(storyboard: Missions.self, identifier: "MissionProviderSelectorViewController")

    internal static let missionSelectorViewController = SceneType<OpenFlight.MissionSelectorViewController>(storyboard: Missions.self, identifier: "MissionSelectorViewController")
  }
  internal enum MyFlightsViewController: StoryboardType {
    internal static let storyboardName = "MyFlightsViewController"

    internal static let initialScene = InitialSceneType<OpenFlight.MyFlightsViewController>(storyboard: MyFlightsViewController.self)

    internal static let myFlightsViewController = SceneType<OpenFlight.MyFlightsViewController>(storyboard: MyFlightsViewController.self, identifier: "MyFlightsViewController")
  }
  internal enum Occupancy: StoryboardType {
    internal static let storyboardName = "Occupancy"

    internal static let initialScene = InitialSceneType<OpenFlight.OccupancyViewController>(storyboard: Occupancy.self)

    internal static let occupancyViewController = SceneType<OpenFlight.OccupancyViewController>(storyboard: Occupancy.self, identifier: "OccupancyViewController")
  }
  internal enum Pairing: StoryboardType {
    internal static let storyboardName = "Pairing"

    internal static let initialScene = InitialSceneType<OpenFlight.PairingViewController>(storyboard: Pairing.self)

    internal static let pairingConnectDroneDetailViewController = SceneType<OpenFlight.PairingConnectDroneDetailViewController>(storyboard: Pairing.self, identifier: "PairingConnectDroneDetailViewController")

    internal static let pairingConnectDroneViewController = SceneType<OpenFlight.PairingConnectDroneViewController>(storyboard: Pairing.self, identifier: "PairingConnectDroneViewController")

    internal static let pairingDroneNotDetectedViewController = SceneType<OpenFlight.PairingDroneNotDetectedViewController>(storyboard: Pairing.self, identifier: "PairingDroneNotDetectedViewController")

    internal static let pairingRemoteNotRecognizedViewController = SceneType<OpenFlight.PairingRemoteNotRecognizedViewController>(storyboard: Pairing.self, identifier: "PairingRemoteNotRecognizedViewController")

    internal static let pairingViewController = SceneType<OpenFlight.PairingViewController>(storyboard: Pairing.self, identifier: "PairingViewController")

    internal static let pairingWhereIsWifiViewController = SceneType<OpenFlight.PairingWhereIsWifiViewController>(storyboard: Pairing.self, identifier: "PairingWhereIsWifiViewController")
  }
  internal enum ParrotDebug: StoryboardType {
    internal static let storyboardName = "ParrotDebug"

    internal static let parrotDebugViewController = SceneType<OpenFlight.ParrotDebugViewController>(storyboard: ParrotDebug.self, identifier: "ParrotDebugViewController")
  }
  internal enum RemoteDetails: StoryboardType {
    internal static let storyboardName = "RemoteDetails"

    internal static let initialScene = InitialSceneType<OpenFlight.RemoteDetailsViewController>(storyboard: RemoteDetails.self)

    internal static let remoteCalibrationViewController = SceneType<OpenFlight.RemoteCalibrationViewController>(storyboard: RemoteDetails.self, identifier: "RemoteCalibrationViewController")

    internal static let remoteDetailsViewController = SceneType<OpenFlight.RemoteDetailsViewController>(storyboard: RemoteDetails.self, identifier: "RemoteDetailsViewController")
  }
  internal enum RemoteShutdownAlertViewController: StoryboardType {
    internal static let storyboardName = "RemoteShutdownAlertViewController"

    internal static let initialScene = InitialSceneType<OpenFlight.RemoteShutdownAlertViewController>(storyboard: RemoteShutdownAlertViewController.self)

    internal static let remoteShutdownAlertViewController = SceneType<OpenFlight.RemoteShutdownAlertViewController>(storyboard: RemoteShutdownAlertViewController.self, identifier: "RemoteShutdownAlertViewController")
  }
  internal enum Settings: StoryboardType {
    internal static let storyboardName = "Settings"

    internal static let initialScene = InitialSceneType<OpenFlight.SettingsViewController>(storyboard: Settings.self)

    internal static let settingsViewController = SceneType<OpenFlight.SettingsViewController>(storyboard: Settings.self, identifier: "SettingsViewController")
  }
  internal enum SettingsCameraViewController: StoryboardType {
    internal static let storyboardName = "SettingsCameraViewController"

    internal static let initialScene = InitialSceneType<OpenFlight.SettingsCameraViewController>(storyboard: SettingsCameraViewController.self)

    internal static let settingsCameraViewController = SceneType<OpenFlight.SettingsCameraViewController>(storyboard: SettingsCameraViewController.self, identifier: "SettingsCameraViewController")
  }
  internal enum SettingsControlsViewController: StoryboardType {
    internal static let storyboardName = "SettingsControlsViewController"

    internal static let initialScene = InitialSceneType<OpenFlight.SettingsControlsViewController>(storyboard: SettingsControlsViewController.self)

    internal static let setttingsControlsViewController = SceneType<OpenFlight.SettingsControlsViewController>(storyboard: SettingsControlsViewController.self, identifier: "SetttingsControlsViewController")
  }
  internal enum SettingsDRIViewController: StoryboardType {
    internal static let storyboardName = "SettingsDRIViewController"

    internal static let initialScene = InitialSceneType<OpenFlight.SettingsDRIViewController>(storyboard: SettingsDRIViewController.self)

    internal static let settingsDRIViewController = SceneType<OpenFlight.SettingsDRIViewController>(storyboard: SettingsDRIViewController.self, identifier: "SettingsDRIViewController")
  }
  internal enum SettingsGeofenceViewController: StoryboardType {
    internal static let storyboardName = "SettingsGeofenceViewController"

    internal static let initialScene = InitialSceneType<OpenFlight.SettingsGeofenceViewController>(storyboard: SettingsGeofenceViewController.self)

    internal static let settingsGeofenceViewController = SceneType<OpenFlight.SettingsGeofenceViewController>(storyboard: SettingsGeofenceViewController.self, identifier: "SettingsGeofenceViewController")
  }
  internal enum SettingsInfoViewController: StoryboardType {
    internal static let storyboardName = "SettingsInfoViewController"

    internal static let initialScene = InitialSceneType<OpenFlight.SettingsInfoViewController>(storyboard: SettingsInfoViewController.self)

    internal static let settingsInfoViewController = SceneType<OpenFlight.SettingsInfoViewController>(storyboard: SettingsInfoViewController.self, identifier: "SettingsInfoViewController")
  }
  internal enum SettingsInterfaceViewController: StoryboardType {
    internal static let storyboardName = "SettingsInterfaceViewController"

    internal static let initialScene = InitialSceneType<OpenFlight.SettingsInterfaceViewController>(storyboard: SettingsInterfaceViewController.self)

    internal static let settingsInterfaceViewController = SceneType<OpenFlight.SettingsInterfaceViewController>(storyboard: SettingsInterfaceViewController.self, identifier: "SettingsInterfaceViewController")
  }
  internal enum SettingsNetworkViewController: StoryboardType {
    internal static let storyboardName = "SettingsNetworkViewController"

    internal static let initialScene = InitialSceneType<OpenFlight.SettingsNetworkViewController>(storyboard: SettingsNetworkViewController.self)

    internal static let settingsInterfaceViewController = SceneType<OpenFlight.SettingsNetworkViewController>(storyboard: SettingsNetworkViewController.self, identifier: "SettingsInterfaceViewController")

    internal static let settingsPasswordEditionViewController = SceneType<OpenFlight.SettingsPasswordEditionViewController>(storyboard: SettingsNetworkViewController.self, identifier: "SettingsPasswordEditionViewController")
  }
  internal enum SettingsQuickViewController: StoryboardType {
    internal static let storyboardName = "SettingsQuickViewController"

    internal static let initialScene = InitialSceneType<OpenFlight.SettingsQuickViewController>(storyboard: SettingsQuickViewController.self)

    internal static let settingsQuickViewController = SceneType<OpenFlight.SettingsQuickViewController>(storyboard: SettingsQuickViewController.self, identifier: "SettingsQuickViewController")
  }
  internal enum SettingsRTHViewController: StoryboardType {
    internal static let storyboardName = "SettingsRTHViewController"

    internal static let initialScene = InitialSceneType<OpenFlight.SettingsRTHViewController>(storyboard: SettingsRTHViewController.self)

    internal static let settingsRTHViewController = SceneType<OpenFlight.SettingsRTHViewController>(storyboard: SettingsRTHViewController.self, identifier: "SettingsRTHViewController")
  }
  internal enum StereoVisionBlended: StoryboardType {
    internal static let storyboardName = "StereoVisionBlended"

    internal static let initialScene = InitialSceneType<OpenFlight.StereoVisionBlendedViewController>(storyboard: StereoVisionBlended.self)

    internal static let stereoVisionBlendedViewController = SceneType<OpenFlight.StereoVisionBlendedViewController>(storyboard: StereoVisionBlended.self, identifier: "StereoVisionBlendedViewController")
  }
  internal enum StereoVisionCalibration: StoryboardType {
    internal static let storyboardName = "StereoVisionCalibration"

    internal static let stereoVisionCalibrationResultViewController = SceneType<OpenFlight.StereoVisionCalibResultViewController>(storyboard: StereoVisionCalibration.self, identifier: "StereoVisionCalibrationResultViewController")

    internal static let stereoVisionCalibrationStepsViewController = SceneType<OpenFlight.StereoVisionCalibStepsViewController>(storyboard: StereoVisionCalibration.self, identifier: "StereoVisionCalibrationStepsViewController")

    internal static let stereoVisionCalibrationViewController = SceneType<OpenFlight.StereoVisionCalibViewController>(storyboard: StereoVisionCalibration.self, identifier: "StereoVisionCalibrationViewController")
  }
}
// swiftlint:enable explicit_type_interface identifier_name line_length type_body_length type_name

// MARK: - Implementation Details

internal protocol StoryboardType {
  static var storyboardName: String { get }
}

internal extension StoryboardType {
  static var storyboard: UIStoryboard {
    let name = self.storyboardName
    return UIStoryboard(name: name, bundle: BundleToken.bundle)
  }
}

internal struct SceneType<T: UIViewController> {
  internal let storyboard: StoryboardType.Type
  internal let identifier: String

  internal func instantiate() -> T {
    let identifier = self.identifier
    guard let controller = storyboard.storyboard.instantiateViewController(withIdentifier: identifier) as? T else {
      fatalError("ViewController '\(identifier)' is not of the expected class \(T.self).")
    }
    return controller
  }
}

internal struct InitialSceneType<T: UIViewController> {
  internal let storyboard: StoryboardType.Type

  internal func instantiate() -> T {
    guard let controller = storyboard.storyboard.instantiateInitialViewController() as? T else {
      fatalError("ViewController is not of the expected class \(T.self).")
    }
    return controller
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    Bundle(for: BundleToken.self)
  }()
}
// swiftlint:enable convenience_type
