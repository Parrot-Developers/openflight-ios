// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

// swiftlint:disable sorted_imports
import Foundation
import UIKit

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length implicit_return

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

    internal static let cellularAccessCardPin = SceneType<OpenFlight.CellularAccessCardPinViewController>(storyboard: CellularAccessCardPin.self, identifier: "CellularAccessCardPin")
  }
  internal enum CellularConfiguration: StoryboardType {
    internal static let storyboardName = "CellularConfiguration"

    internal static let initialScene = InitialSceneType<OpenFlight.CellularConfigurationViewController>(storyboard: CellularConfiguration.self)

    internal static let cellularConfiguration = SceneType<OpenFlight.CellularConfigurationViewController>(storyboard: CellularConfiguration.self, identifier: "CellularConfiguration")
  }
  internal enum CellularPairingSuccess: StoryboardType {
    internal static let storyboardName = "CellularPairingSuccess"

    internal static let initialScene = InitialSceneType<OpenFlight.CellularPairingSuccessViewController>(storyboard: CellularPairingSuccess.self)

    internal static let cellularPairingSuccess = SceneType<OpenFlight.CellularPairingSuccessViewController>(storyboard: CellularPairingSuccess.self, identifier: "CellularPairingSuccess")
  }
  internal enum Dashboard: StoryboardType {
    internal static let storyboardName = "Dashboard"

    internal static let initialScene = InitialSceneType<OpenFlight.DashboardViewController>(storyboard: Dashboard.self)

    internal static let dashboardViewController = SceneType<OpenFlight.DashboardViewController>(storyboard: Dashboard.self, identifier: "DashboardViewController")
  }
  internal enum DashboardMyAccount: StoryboardType {
    internal static let storyboardName = "DashboardMyAccount"

    internal static let initialScene = InitialSceneType<OpenFlight.DashboardMyAccountViewController>(storyboard: DashboardMyAccount.self)

    internal static let dashboardMyAccountViewController = SceneType<OpenFlight.DashboardMyAccountViewController>(storyboard: DashboardMyAccount.self, identifier: "DashboardMyAccountViewController")
  }
  internal enum DevToolbox: StoryboardType {
    internal static let storyboardName = "DevToolbox"

    internal static let initialScene = InitialSceneType<OpenFlight.DevToolboxViewController>(storyboard: DevToolbox.self)

    internal static let devToolboxViewController = SceneType<OpenFlight.DevToolboxViewController>(storyboard: DevToolbox.self, identifier: "DevToolboxViewController")
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

    internal static let droneDetailsViewController = SceneType<OpenFlight.DroneDetailsViewController>(storyboard: DroneDetails.self, identifier: "DroneDetailsViewController")
  }
  internal enum DroneDetailsButtons: StoryboardType {
    internal static let storyboardName = "DroneDetailsButtons"

    internal static let initialScene = InitialSceneType<OpenFlight.DroneDetailsButtonsViewController>(storyboard: DroneDetailsButtons.self)

    internal static let droneDetailsButtons = SceneType<OpenFlight.DroneDetailsButtonsViewController>(storyboard: DroneDetailsButtons.self, identifier: "DroneDetailsButtons")
  }
  internal enum DroneDetailsCellular: StoryboardType {
    internal static let storyboardName = "DroneDetailsCellular"

    internal static let initialScene = InitialSceneType<OpenFlight.DroneDetailsCellularViewController>(storyboard: DroneDetailsCellular.self)

    internal static let droneDetailsCellularViewController = SceneType<OpenFlight.DroneDetailsCellularViewController>(storyboard: DroneDetailsCellular.self, identifier: "DroneDetailsCellularViewController")
  }
  internal enum DroneDetailsDevice: StoryboardType {
    internal static let storyboardName = "DroneDetailsDevice"

    internal static let initialScene = InitialSceneType<OpenFlight.DroneDetailsDeviceViewController>(storyboard: DroneDetailsDevice.self)

    internal static let droneDetailsDevice = SceneType<OpenFlight.DroneDetailsDeviceViewController>(storyboard: DroneDetailsDevice.self, identifier: "DroneDetailsDevice")
  }
  internal enum DroneDetailsFirmware: StoryboardType {
    internal static let storyboardName = "DroneDetailsFirmware"

    internal static let initialScene = InitialSceneType<OpenFlight.DroneDetailsFirmwareViewController>(storyboard: DroneDetailsFirmware.self)

    internal static let droneDetailsFirmwareViewController = SceneType<OpenFlight.DroneDetailsFirmwareViewController>(storyboard: DroneDetailsFirmware.self, identifier: "DroneDetailsFirmwareViewController")
  }
  internal enum DroneDetailsFirmwares: StoryboardType {
    internal static let storyboardName = "DroneDetailsFirmwares"

    internal static let initialScene = InitialSceneType<OpenFlight.DroneDetailsFirmwaresViewController>(storyboard: DroneDetailsFirmwares.self)

    internal static let droneDetailsFirmwares = SceneType<OpenFlight.DroneDetailsFirmwaresViewController>(storyboard: DroneDetailsFirmwares.self, identifier: "DroneDetailsFirmwares")
  }
  internal enum DroneDetailsInformations: StoryboardType {
    internal static let storyboardName = "DroneDetailsInformations"

    internal static let initialScene = InitialSceneType<OpenFlight.DroneDetailsInformationsViewController>(storyboard: DroneDetailsInformations.self)

    internal static let droneDetailsInformations = SceneType<OpenFlight.DroneDetailsInformationsViewController>(storyboard: DroneDetailsInformations.self, identifier: "DroneDetailsInformations")
  }
  internal enum DroneDetailsMap: StoryboardType {
    internal static let storyboardName = "DroneDetailsMap"

    internal static let initialScene = InitialSceneType<OpenFlight.DroneDetailsMapViewController>(storyboard: DroneDetailsMap.self)

    internal static let droneDetailsMapViewController = SceneType<OpenFlight.DroneDetailsMapViewController>(storyboard: DroneDetailsMap.self, identifier: "droneDetailsMapViewController")
  }
  internal enum FirmwareAndMissionsUpdate: StoryboardType {
    internal static let storyboardName = "FirmwareAndMissionsUpdate"

    internal static let initialScene = InitialSceneType<OpenFlight.FirmwareAndMissionsUpdateViewController>(storyboard: FirmwareAndMissionsUpdate.self)

    internal static let firmwareAndMissionsUpdate = SceneType<OpenFlight.FirmwareAndMissionsUpdateViewController>(storyboard: FirmwareAndMissionsUpdate.self, identifier: "FirmwareAndMissionsUpdate")
  }
  internal enum FirmwareUpdatingViewController: StoryboardType {
    internal static let storyboardName = "FirmwareUpdatingViewController"

    internal static let initialScene = InitialSceneType<OpenFlight.FirmwareUpdatingViewController>(storyboard: FirmwareUpdatingViewController.self)

    internal static let firmwareUpdatingViewController = SceneType<OpenFlight.FirmwareUpdatingViewController>(storyboard: FirmwareUpdatingViewController.self, identifier: "FirmwareUpdatingViewController")
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
  internal enum FlightPlanListHeaderViewController: StoryboardType {
    internal static let storyboardName = "FlightPlanListHeaderViewController"

    internal static let initialScene = InitialSceneType<OpenFlight.FlightPlanListHeaderViewController>(storyboard: FlightPlanListHeaderViewController.self)

    internal static let flightPlanListHeaderViewController = SceneType<OpenFlight.FlightPlanListHeaderViewController>(storyboard: FlightPlanListHeaderViewController.self, identifier: "FlightPlanListHeaderViewController")
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
  internal enum HUDCriticalAlert: StoryboardType {
    internal static let storyboardName = "HUDCriticalAlert"

    internal static let initialScene = InitialSceneType<OpenFlight.HUDCriticalAlertViewController>(storyboard: HUDCriticalAlert.self)

    internal static let hudCriticalAlert = SceneType<OpenFlight.HUDCriticalAlertViewController>(storyboard: HUDCriticalAlert.self, identifier: "HUDCriticalAlert")
  }
  internal enum HUDIndicator: StoryboardType {
    internal static let storyboardName = "HUDIndicator"

    internal static let initialScene = InitialSceneType<OpenFlight.HUDIndicatorViewController>(storyboard: HUDIndicator.self)

    internal static let hudIndicator = SceneType<OpenFlight.HUDIndicatorViewController>(storyboard: HUDIndicator.self, identifier: "HUDIndicator")
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
  internal enum Missions: StoryboardType {
    internal static let storyboardName = "Missions"

    internal static let initialScene = InitialSceneType<OpenFlight.MissionProviderSelectorViewController>(storyboard: Missions.self)

    internal static let missionProviderSelectorViewController = SceneType<OpenFlight.MissionProviderSelectorViewController>(storyboard: Missions.self, identifier: "MissionProviderSelectorViewController")
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
  internal enum OnboardingLocalizationViewController: StoryboardType {
    internal static let storyboardName = "OnboardingLocalizationViewController"

    internal static let initialScene = InitialSceneType<OpenFlight.OnboardingLocalizationViewController>(storyboard: OnboardingLocalizationViewController.self)

    internal static let onboardingLocalizationViewController = SceneType<OpenFlight.OnboardingLocalizationViewController>(storyboard: OnboardingLocalizationViewController.self, identifier: "OnboardingLocalizationViewController")
  }
  internal enum OnboardingPairing: StoryboardType {
    internal static let storyboardName = "OnboardingPairing"

    internal static let initialScene = InitialSceneType<OpenFlight.OnboardingPairingViewController>(storyboard: OnboardingPairing.self)

    internal static let onboardingPairingViewController = SceneType<OpenFlight.OnboardingPairingViewController>(storyboard: OnboardingPairing.self, identifier: "OnboardingPairingViewController")
  }
  internal enum OnboardingTermsOfUse: StoryboardType {
    internal static let storyboardName = "OnboardingTermsOfUse"

    internal static let initialScene = InitialSceneType<OpenFlight.OnboardingTermsOfUseViewController>(storyboard: OnboardingTermsOfUse.self)

    internal static let onboardingToUViewController = SceneType<OpenFlight.OnboardingTermsOfUseViewController>(storyboard: OnboardingTermsOfUse.self, identifier: "OnboardingToUViewController")
  }
  internal enum Pairing: StoryboardType {
    internal static let storyboardName = "Pairing"

    internal static let initialScene = InitialSceneType<OpenFlight.PairingViewController>(storyboard: Pairing.self)

    internal static let pairingViewController = SceneType<OpenFlight.PairingViewController>(storyboard: Pairing.self, identifier: "PairingViewController")
  }
  internal enum PairingConnectDrone: StoryboardType {
    internal static let storyboardName = "PairingConnectDrone"

    internal static let initialScene = InitialSceneType<OpenFlight.PairingConnectDroneViewController>(storyboard: PairingConnectDrone.self)

    internal static let pairingConnectDroneViewController = SceneType<OpenFlight.PairingConnectDroneViewController>(storyboard: PairingConnectDrone.self, identifier: "PairingConnectDroneViewController")
  }
  internal enum PairingConnectDroneDetails: StoryboardType {
    internal static let storyboardName = "PairingConnectDroneDetails"

    internal static let initialScene = InitialSceneType<OpenFlight.PairingConnectDroneDetailViewController>(storyboard: PairingConnectDroneDetails.self)

    internal static let pairingConnectDroneDetailViewController = SceneType<OpenFlight.PairingConnectDroneDetailViewController>(storyboard: PairingConnectDroneDetails.self, identifier: "PairingConnectDroneDetailViewController")
  }
  internal enum PairingDroneNotDetected: StoryboardType {
    internal static let storyboardName = "PairingDroneNotDetected"

    internal static let initialScene = InitialSceneType<OpenFlight.PairingDroneNotDetectedViewController>(storyboard: PairingDroneNotDetected.self)

    internal static let pairingDroneNotDetectedViewController = SceneType<OpenFlight.PairingDroneNotDetectedViewController>(storyboard: PairingDroneNotDetected.self, identifier: "PairingDroneNotDetectedViewController")
  }
  internal enum PairingRemoteNotRecognized: StoryboardType {
    internal static let storyboardName = "PairingRemoteNotRecognized"

    internal static let initialScene = InitialSceneType<OpenFlight.PairingRemoteNotRecognizedViewController>(storyboard: PairingRemoteNotRecognized.self)

    internal static let pairingRemoteNotRecognizedViewController = SceneType<OpenFlight.PairingRemoteNotRecognizedViewController>(storyboard: PairingRemoteNotRecognized.self, identifier: "PairingRemoteNotRecognizedViewController")
  }
  internal enum PairingWhereIsWifi: StoryboardType {
    internal static let storyboardName = "PairingWhereIsWifi"

    internal static let initialScene = InitialSceneType<OpenFlight.PairingWhereIsWifiViewController>(storyboard: PairingWhereIsWifi.self)

    internal static let pairingWhereIsWifiViewController = SceneType<OpenFlight.PairingWhereIsWifiViewController>(storyboard: PairingWhereIsWifi.self, identifier: "PairingWhereIsWifiViewController")
  }
  internal enum ParrotDebug: StoryboardType {
    internal static let storyboardName = "ParrotDebug"

    internal static let initialScene = InitialSceneType<OpenFlight.ParrotDebugViewController>(storyboard: ParrotDebug.self)

    internal static let parrotDebugViewController = SceneType<OpenFlight.ParrotDebugViewController>(storyboard: ParrotDebug.self, identifier: "ParrotDebugViewController")
  }
  internal enum ProtobufMissionsUpdating: StoryboardType {
    internal static let storyboardName = "ProtobufMissionsUpdating"

    internal static let initialScene = InitialSceneType<OpenFlight.ProtobufMissionsUpdatingViewController>(storyboard: ProtobufMissionsUpdating.self)

    internal static let protobufMissionsUpdating = SceneType<OpenFlight.ProtobufMissionsUpdatingViewController>(storyboard: ProtobufMissionsUpdating.self, identifier: "ProtobufMissionsUpdating")
  }
  internal enum RemoteCalibration: StoryboardType {
    internal static let storyboardName = "RemoteCalibration"

    internal static let initialScene = InitialSceneType<OpenFlight.RemoteCalibrationViewController>(storyboard: RemoteCalibration.self)

    internal static let remoteCalibration = SceneType<OpenFlight.RemoteCalibrationViewController>(storyboard: RemoteCalibration.self, identifier: "RemoteCalibration")
  }
  internal enum RemoteDetails: StoryboardType {
    internal static let storyboardName = "RemoteDetails"

    internal static let initialScene = InitialSceneType<OpenFlight.RemoteDetailsViewController>(storyboard: RemoteDetails.self)

    internal static let remoteDetailsViewController = SceneType<OpenFlight.RemoteDetailsViewController>(storyboard: RemoteDetails.self, identifier: "RemoteDetailsViewController")
  }
  internal enum RemoteDetailsButtons: StoryboardType {
    internal static let storyboardName = "RemoteDetailsButtons"

    internal static let initialScene = InitialSceneType<OpenFlight.RemoteDetailsButtonsViewController>(storyboard: RemoteDetailsButtons.self)

    internal static let remoteDetailsButtons = SceneType<OpenFlight.RemoteDetailsButtonsViewController>(storyboard: RemoteDetailsButtons.self, identifier: "RemoteDetailsButtons")
  }
  internal enum RemoteDetailsDevice: StoryboardType {
    internal static let storyboardName = "RemoteDetailsDevice"

    internal static let initialScene = InitialSceneType<OpenFlight.RemoteDetailsDeviceViewController>(storyboard: RemoteDetailsDevice.self)

    internal static let remoteDetailsDevice = SceneType<OpenFlight.RemoteDetailsDeviceViewController>(storyboard: RemoteDetailsDevice.self, identifier: "RemoteDetailsDevice")
  }
  internal enum RemoteDetailsInformations: StoryboardType {
    internal static let storyboardName = "RemoteDetailsInformations"

    internal static let initialScene = InitialSceneType<OpenFlight.RemoteDetailsInformationsViewController>(storyboard: RemoteDetailsInformations.self)

    internal static let remoteDetailsInformations = SceneType<OpenFlight.RemoteDetailsInformationsViewController>(storyboard: RemoteDetailsInformations.self, identifier: "RemoteDetailsInformations")
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

    internal static let settingsControlsViewController = SceneType<OpenFlight.SettingsControlsViewController>(storyboard: SettingsControlsViewController.self, identifier: "SettingsControlsViewController")
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

  @available(iOS 13.0, tvOS 13.0, *)
  internal func instantiate(creator block: @escaping (NSCoder) -> T?) -> T {
    return storyboard.storyboard.instantiateViewController(identifier: identifier, creator: block)
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

  @available(iOS 13.0, tvOS 13.0, *)
  internal func instantiate(creator block: @escaping (NSCoder) -> T?) -> T {
    guard let controller = storyboard.storyboard.instantiateInitialViewController(creator: block) else {
      fatalError("Storyboard \(storyboard.storyboardName) does not have an initial scene.")
    }
    return controller
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
