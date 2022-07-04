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
  internal enum ActionWidgetContainer: StoryboardType {
    internal static let storyboardName = "ActionWidgetContainer"

    internal static let initialScene = InitialSceneType<OpenFlight.ActionWidgetContainerViewController>(storyboard: ActionWidgetContainer.self)
  }
  internal enum AirSdkMissionsUpdating: StoryboardType {
    internal static let storyboardName = "AirSdkMissionsUpdating"

    internal static let initialScene = InitialSceneType<OpenFlight.AirSdkMissionsUpdatingViewController>(storyboard: AirSdkMissionsUpdating.self)

    internal static let airSdkMissionsUpdatingViewController = SceneType<OpenFlight.AirSdkMissionsUpdatingViewController>(storyboard: AirSdkMissionsUpdating.self, identifier: "AirSdkMissionsUpdatingViewController")
  }
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
  internal enum CellularDebugLogs: StoryboardType {
    internal static let storyboardName = "CellularDebugLogs"

    internal static let initialScene = InitialSceneType<OpenFlight.CellularDebugLogsViewController>(storyboard: CellularDebugLogs.self)

    internal static let cellularDebugLogsViewController = SceneType<OpenFlight.CellularDebugLogsViewController>(storyboard: CellularDebugLogs.self, identifier: "CellularDebugLogsViewController")
  }
  internal enum CustomMissionDebug: StoryboardType {
    internal static let storyboardName = "CustomMissionDebug"

    internal static let initialScene = InitialSceneType<OpenFlight.CustomMissionDebugViewController>(storyboard: CustomMissionDebug.self)
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
  internal enum DroneCalibration: StoryboardType {
    internal static let storyboardName = "DroneCalibration"

    internal static let initialScene = InitialSceneType<OpenFlight.DroneCalibrationViewController>(storyboard: DroneCalibration.self)

    internal static let droneCalibrationViewController = SceneType<OpenFlight.DroneCalibrationViewController>(storyboard: DroneCalibration.self, identifier: "DroneCalibrationViewController")

    internal static let droneGimbalCalibrationViewController = SceneType<OpenFlight.DroneGimbalCalibrationViewController>(storyboard: DroneCalibration.self, identifier: "DroneGimbalCalibrationViewController")

    internal static let magnetometerCalibrationViewController = SceneType<OpenFlight.MagnetometerCalibrationViewController>(storyboard: DroneCalibration.self, identifier: "MagnetometerCalibrationViewController")
  }
  internal enum DroneDetailCellularViewController: StoryboardType {
    internal static let storyboardName = "DroneDetailCellularViewController"

    internal static let initialScene = InitialSceneType<OpenFlight.DroneDetailsCellularViewController>(storyboard: DroneDetailCellularViewController.self)

    internal static let droneDetailsCellularViewController = SceneType<OpenFlight.DroneDetailsCellularViewController>(storyboard: DroneDetailCellularViewController.self, identifier: "DroneDetailsCellularViewController")
  }
  internal enum DroneDetails: StoryboardType {
    internal static let storyboardName = "DroneDetails"

    internal static let initialScene = InitialSceneType<OpenFlight.DroneDetailsViewController>(storyboard: DroneDetails.self)

    internal static let droneDetailsViewController = SceneType<OpenFlight.DroneDetailsViewController>(storyboard: DroneDetails.self, identifier: "DroneDetailsViewController")
  }
  internal enum DroneDetailsBatteryViewController: StoryboardType {
    internal static let storyboardName = "DroneDetailsBatteryViewController"

    internal static let initialScene = InitialSceneType<OpenFlight.DroneDetailsBatteryViewController>(storyboard: DroneDetailsBatteryViewController.self)
  }
  internal enum DroneDetailsButtons: StoryboardType {
    internal static let storyboardName = "DroneDetailsButtons"

    internal static let initialScene = InitialSceneType<OpenFlight.DroneDetailsButtonsViewController>(storyboard: DroneDetailsButtons.self)

    internal static let droneDetailsButtons = SceneType<OpenFlight.DroneDetailsButtonsViewController>(storyboard: DroneDetailsButtons.self, identifier: "DroneDetailsButtons")
  }
  internal enum DroneDetailsDevice: StoryboardType {
    internal static let storyboardName = "DroneDetailsDevice"

    internal static let initialScene = InitialSceneType<OpenFlight.DroneDetailsDeviceViewController>(storyboard: DroneDetailsDevice.self)

    internal static let droneDetailsDevice = SceneType<OpenFlight.DroneDetailsDeviceViewController>(storyboard: DroneDetailsDevice.self, identifier: "DroneDetailsDevice")
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
  internal enum DroneFirmwares: StoryboardType {
    internal static let storyboardName = "DroneFirmwares"

    internal static let initialScene = InitialSceneType<OpenFlight.DroneFirmwaresViewController>(storyboard: DroneFirmwares.self)

    internal static let droneFirmwares = SceneType<OpenFlight.DroneFirmwaresViewController>(storyboard: DroneFirmwares.self, identifier: "DroneFirmwares")
  }
  internal enum EditionDRIViewController: StoryboardType {
    internal static let storyboardName = "EditionDRIViewController"

    internal static let initialScene = InitialSceneType<OpenFlight.EditionDRIViewController>(storyboard: EditionDRIViewController.self)

    internal static let editionDRIViewController = SceneType<OpenFlight.EditionDRIViewController>(storyboard: EditionDRIViewController.self, identifier: "EditionDRIViewController")
  }
  internal enum ExecutionsListViewController: StoryboardType {
    internal static let storyboardName = "ExecutionsListViewController"

    internal static let initialScene = InitialSceneType<OpenFlight.ExecutionsListViewController>(storyboard: ExecutionsListViewController.self)

    internal static let executionsListViewController = SceneType<OpenFlight.ExecutionsListViewController>(storyboard: ExecutionsListViewController.self, identifier: "ExecutionsListViewController")
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
  internal enum FlightDetailsViewController: StoryboardType {
    internal static let storyboardName = "FlightDetailsViewController"

    internal static let flightDetailsViewController = SceneType<OpenFlight.FlightDetailsViewController>(storyboard: FlightDetailsViewController.self, identifier: "FlightDetailsViewController")
  }
  internal enum FlightPlanEdition: StoryboardType {
    internal static let storyboardName = "FlightPlanEdition"

    internal static let initialScene = InitialSceneType<OpenFlight.FlightPlanEditionViewController>(storyboard: FlightPlanEdition.self)

    internal static let buildingHeightMenuViewController = SceneType<OpenFlight.BuildingHeightMenuViewController>(storyboard: FlightPlanEdition.self, identifier: "BuildingHeightMenuViewController")
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
  internal enum FlightPlansDashboardList: StoryboardType {
    internal static let storyboardName = "FlightPlansDashboardList"

    internal static let flightPlanDashboardListViewController = SceneType<OpenFlight.FlightPlanDashboardListViewController>(storyboard: FlightPlansDashboardList.self, identifier: "FlightPlanDashboardListViewController")
  }
  internal enum FlightsViewController: StoryboardType {
    internal static let storyboardName = "FlightsViewController"

    internal static let initialScene = InitialSceneType<OpenFlight.FlightsViewController>(storyboard: FlightsViewController.self)

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

    internal static let galleryPanoramaGenerationViewController = SceneType<OpenFlight.GalleryPanoramaGenerationViewController>(storyboard: GalleryPanorama.self, identifier: "GalleryPanoramaGenerationViewController")
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
  internal enum LayoutGridManager: StoryboardType {
    internal static let storyboardName = "LayoutGridManager"

    internal static let initialScene = InitialSceneType<OpenFlight.LayoutGridManagerViewController>(storyboard: LayoutGridManager.self)
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
  internal enum ProjectManager: StoryboardType {
    internal static let storyboardName = "ProjectManager"

    internal static let projectManagerViewController = SceneType<OpenFlight.ProjectManagerViewController>(storyboard: ProjectManager.self, identifier: "ProjectManagerViewController")
  }
  internal enum ProjectsList: StoryboardType {
    internal static let storyboardName = "ProjectsList"

    internal static let initialScene = InitialSceneType<OpenFlight.ProjectsListViewController>(storyboard: ProjectsList.self)

    internal static let projectsListViewController = SceneType<OpenFlight.ProjectsListViewController>(storyboard: ProjectsList.self, identifier: "ProjectsListViewController")
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
  internal enum RemoteUpdate: StoryboardType {
    internal static let storyboardName = "RemoteUpdate"

    internal static let remoteUpdate = SceneType<OpenFlight.RemoteUpdateViewController>(storyboard: RemoteUpdate.self, identifier: "RemoteUpdate")
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
  internal enum StereoCalibration: StoryboardType {
    internal static let storyboardName = "StereoCalibration"

    internal static let stereoCalibrationViewController = SceneType<OpenFlight.StereoCalibrationViewController>(storyboard: StereoCalibration.self, identifier: "StereoCalibrationViewController")
  }
  internal enum StereoVisionBlended: StoryboardType {
    internal static let storyboardName = "StereoVisionBlended"

    internal static let initialScene = InitialSceneType<OpenFlight.StereoVisionBlendedViewController>(storyboard: StereoVisionBlended.self)

    internal static let stereoVisionBlendedViewController = SceneType<OpenFlight.StereoVisionBlendedViewController>(storyboard: StereoVisionBlended.self, identifier: "StereoVisionBlendedViewController")
  }
  internal enum TouchAndFlyPanel: StoryboardType {
    internal static let storyboardName = "TouchAndFlyPanel"

    internal static let touchAndFlyPanel = SceneType<OpenFlight.TouchAndFlyPanelViewController>(storyboard: TouchAndFlyPanel.self, identifier: "TouchAndFlyPanel")
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
