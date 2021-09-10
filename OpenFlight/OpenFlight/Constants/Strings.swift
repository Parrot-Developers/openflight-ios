// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  /// Land
  internal static let actionLand = L10n.tr("Localizable", "action_land")
  /// Take-off
  internal static let actionTakeOff = L10n.tr("Localizable", "action_take_off")
  /// AE
  internal static let ae = L10n.tr("Localizable", "ae")
  /// Auto landing
  internal static let alertAutoLanding = L10n.tr("Localizable", "alert_auto_landing")
  /// Autolanding in %d s
  internal static func alertAutolandingRemainingTime(_ p1: Int) -> String {
    return L10n.tr("Localizable", "alert_autolanding_remaining_time", p1)
  }
  /// Obstacle avoidance deteriorated - Poor GPS quality
  internal static let alertAvoidanceDeteriorated = L10n.tr("Localizable", "alert_avoidance_deteriorated")
  /// Check that nothing is blocking the camera
  internal static let alertCameraError = L10n.tr("Localizable", "alert_camera_error")
  /// Obstacle avoidance deteriorated – Strong winds
  internal static let alertDeterioratedAvoidanceStrongWinds = L10n.tr("Localizable", "alert_deteriorated_avoidance_strong_winds")
  /// Obstacle avoidance - Drone was not able to find a path
  internal static let alertDroneStuck = L10n.tr("Localizable", "alert_drone_stuck")
  /// Geofence reached
  internal static let alertGeofenceReached = L10n.tr("Localizable", "alert_geofence_reached")
  /// GPS tracking connection lost
  internal static let alertGpsKo = L10n.tr("Localizable", "alert_gps_ko")
  /// Hand detected
  internal static let alertHandLandHandDetected = L10n.tr("Localizable", "alert_hand_land_hand_detected")
  /// Hand lost
  internal static let alertHandLandHandLost = L10n.tr("Localizable", "alert_hand_land_hand_lost")
  /// Landing…
  internal static let alertHandLandLanding = L10n.tr("Localizable", "alert_hand_land_landing")
  /// Replacing
  internal static let alertHandLandReplacing = L10n.tr("Localizable", "alert_hand_land_replacing")
  /// Waiting
  internal static let alertHandLandWaiting = L10n.tr("Localizable", "alert_hand_land_waiting")
  /// Hand detected. Do you want to hand launch your drone ?
  internal static let alertHandLaunch = L10n.tr("Localizable", "alert_hand_launch")
  /// Launch
  internal static let alertHandLaunchLaunch = L10n.tr("Localizable", "alert_hand_launch_launch")
  /// Champ magnétique terrestre trop faible - vols autonomes indisponibles
  internal static let alertHeadingLockKoEarthMagnetic = L10n.tr("Localizable", "alert_heading_lock_ko_earth_magnetic")
  /// Perturbations magnétiques - vols autonomes indisponibles
  internal static let alertHeadingLockKoPerturbationMagnetic = L10n.tr("Localizable", "alert_heading_lock_ko_perturbation_magnetic")
  /// Obstacle avoidance - High deviation
  internal static let alertHighDeviation = L10n.tr("Localizable", "alert_high_deviation")
  /// Vibrations detected . Check that propellers are tightly screwed.
  internal static let alertImuVibrations = L10n.tr("Localizable", "alert_imu_vibrations")
  /// Internal memory full
  internal static let alertInternalMemoryFull = L10n.tr("Localizable", "alert_internal_memory_full")
  /// Weak Wi-Fi signal. Strong interferences.
  internal static let alertLowAndPerturbedWifi = L10n.tr("Localizable", "alert_low_and_perturbed_wifi")
  /// The engines of the drone have cut out
  internal static let alertMotorCutout = L10n.tr("Localizable", "alert_motor_cutout")
  /// Motors power supply issue. The engines of the drone have cut out.
  internal static let alertMotorCutoutPowerSupply = L10n.tr("Localizable", "alert_motor_cutout_power_supply")
  /// Motors temperature issue. The engines of the drone have cut out.
  internal static let alertMotorCutoutTemperature = L10n.tr("Localizable", "alert_motor_cutout_temperature")
  /// Obstacle avoidance disabled - Poor GPS quality
  internal static let alertNoAvoidanceNoGps = L10n.tr("Localizable", "alert_no_avoidance_no_gps")
  /// Obstacle avoidance disabled - Stereo camera failure
  internal static let alertNoAvoidanceSensorsFailure = L10n.tr("Localizable", "alert_no_avoidance_sensors_failure")
  /// Obstacle avoidance disabled - Stereo sensors calibration required
  internal static let alertNoAvoidanceSensorsNotCalibrated = L10n.tr("Localizable", "alert_no_avoidance_sensors_not_calibrated")
  /// Obstacle avoidance disabled - Environment too dark
  internal static let alertNoAvoidanceTooDark = L10n.tr("Localizable", "alert_no_avoidance_too_dark")
  /// Flight quality is not optimal - autonomous flights are unavailable
  internal static let alertNoGps = L10n.tr("Localizable", "alert_no_gps")
  /// Flight quality is not optimal - GPS lapse is unavailable
  internal static let alertNoGpsGpslapse = L10n.tr("Localizable", "alert_no_gps_gpslapse")
  /// Flight quality is not optimal – environment is too dark
  internal static let alertNoGpsTooDark = L10n.tr("Localizable", "alert_no_gps_too_dark")
  /// Flight quality is not optimal - decrease the drone's altitude
  internal static let alertNoGpsTooHigh = L10n.tr("Localizable", "alert_no_gps_too_high")
  /// Low Controller's battery
  internal static let alertReturnHomeControllerLowBattery = L10n.tr("Localizable", "alert_return_home_controller_low_battery")
  /// Very Low Controller's battery
  internal static let alertReturnHomeControllerVeryLowBattery = L10n.tr("Localizable", "alert_return_home_controller_very_low_battery")
  /// Low Device's battery
  internal static let alertReturnHomeDeviceLowBattery = L10n.tr("Localizable", "alert_return_home_device_low_battery")
  /// Very Low Device's battery
  internal static let alertReturnHomeDeviceVeryLowBattery = L10n.tr("Localizable", "alert_return_home_device_very_low_battery")
  /// Low Drone's battery
  internal static let alertReturnHomeDroneLowBattery = L10n.tr("Localizable", "alert_return_home_drone_low_battery")
  /// Very Low Drone's battery
  internal static let alertReturnHomeDroneVeryLowBattery = L10n.tr("Localizable", "alert_return_home_drone_very_low_battery")
  /// Starting in %d s
  internal static func alertReturnHomeRemainingTime(_ p1: Int) -> String {
    return L10n.tr("Localizable", "alert_return_home_remaining_time", p1)
  }
  /// Returning Home
  internal static let alertReturnHomeTitle = L10n.tr("Localizable", "alert_return_home_title")
  /// Returning to Pilot
  internal static let alertReturnPilotTitle = L10n.tr("Localizable", "alert_return_pilot_title")
  /// Returning to Vehicle
  internal static let alertReturnVehicleTitle = L10n.tr("Localizable", "alert_return_vehicle_title")
  /// SD Error 
  internal static let alertSdError = L10n.tr("Localizable", "alert_sd_error")
  /// SD Full
  internal static let alertSdFull = L10n.tr("Localizable", "alert_sd_full")
  /// SD Slow
  internal static let alertSdSlow = L10n.tr("Localizable", "alert_sd_slow")
  /// SD too slow
  internal static let alertSdcardTooSlow = L10n.tr("Localizable", "alert_sdcard_too_slow")
  /// Select a subject
  internal static let alertSelectSubject = L10n.tr("Localizable", "alert_select_subject")
  /// Calibrate sensors for a better experience.
  internal static let alertSensorCalibrationRecommended = L10n.tr("Localizable", "alert_sensor_calibration_recommended")
  /// Strong vibrations detected . Check that propellers are tightly screwed.
  internal static let alertStrongImuVibrations = L10n.tr("Localizable", "alert_strong_imu_vibrations")
  /// Take off
  internal static let alertTakeOff = L10n.tr("Localizable", "alert_take_off")
  /// Take off to create a POI
  internal static let alertTakeOffPoi = L10n.tr("Localizable", "alert_take_off_poi")
  /// Take off to create a waypoint
  internal static let alertTakeOffWaypoint = L10n.tr("Localizable", "alert_take_off_waypoint")
  /// Subject lost
  internal static let alertTargetLost = L10n.tr("Localizable", "alert_target_lost")
  /// Too much angle
  internal static let alertTooMuchAngle = L10n.tr("Localizable", "alert_too_much_angle")
  /// Put your drone on its four feet to take off.
  internal static let alertTooMuchAngleDescription = L10n.tr("Localizable", "alert_too_much_angle_description")
  /// Strong winds
  internal static let alertTooMuchWind = L10n.tr("Localizable", "alert_too_much_wind")
  /// You are not allowed to fly here
  internal static let alertUnauthorizedFlightZone = L10n.tr("Localizable", "alert_unauthorized_flight_zone")
  /// The drone will soon land
  internal static let alertVeryLowBattery = L10n.tr("Localizable", "alert_very_low_battery")
  /// Alt.
  internal static let altitudeRulerTitle = L10n.tr("Localizable", "altitude_ruler_title")
  /// OpenFlight
  internal static let appName = L10n.tr("Localizable", "app_name")
  /// OpenFlight
  internal static let appNameNoVersion = L10n.tr("Localizable", "app_name_no_version")
  /// Authorizations
  internal static let authorizationsTitle = L10n.tr("Localizable", "authorizations_title")
  /// HDR
  internal static let cameraHdr = L10n.tr("Localizable", "camera_hdr")
  /// Unavailable in %@
  internal static func cameraHdrUnavailable(_ p1: Any) -> String {
    return L10n.tr("Localizable", "camera_hdr_unavailable", String(describing: p1))
  }
  /// Unavailable for framerates above 30 fps
  internal static let cameraHdrUnavailableFramerates = L10n.tr("Localizable", "camera_hdr_unavailable_framerates")
  /// Unavailable in DNG mode
  internal static let cameraHdrUnavailablePhotoFormat = L10n.tr("Localizable", "camera_hdr_unavailable_photo_format")
  /// Unavailable for 48 Mp resolution
  internal static let cameraHdrUnavailablePhotoResolution = L10n.tr("Localizable", "camera_hdr_unavailable_photo_resolution")
  /// Bracketing
  internal static let cameraModeBracketing = L10n.tr("Localizable", "camera_mode_bracketing")
  /// Burst
  internal static let cameraModeBurst = L10n.tr("Localizable", "camera_mode_burst")
  /// GPS Lapse
  internal static let cameraModeGpslapse = L10n.tr("Localizable", "camera_mode_gpslapse")
  /// Panorama
  internal static let cameraModePanorama = L10n.tr("Localizable", "camera_mode_panorama")
  /// Photo
  internal static let cameraModePhoto = L10n.tr("Localizable", "camera_mode_photo")
  /// Single
  internal static let cameraModeSingle = L10n.tr("Localizable", "camera_mode_single")
  /// Timelapse
  internal static let cameraModeTimelapse = L10n.tr("Localizable", "camera_mode_timelapse")
  /// Video
  internal static let cameraModeVideo = L10n.tr("Localizable", "camera_mode_video")
  /// Unavailable in photo mode
  internal static let cameraPlogUnavailable = L10n.tr("Localizable", "camera_plog_unavailable")
  /// HDR Off
  internal static let cameraRangeHdrOff = L10n.tr("Localizable", "camera_range_hdr_off")
  /// HDR On
  internal static let cameraRangeHdrOn = L10n.tr("Localizable", "camera_range_hdr_on")
  /// P-Log
  internal static let cameraRangePlog = L10n.tr("Localizable", "camera_range_plog")
  /// %d photos
  internal static func cameraSubModeBracketingPhotoCount(_ p1: Int) -> String {
    return L10n.tr("Localizable", "camera_sub_mode_bracketing_photo_count", p1)
  }
  /// Pano %@
  internal static func cameraSubModePanorama(_ p1: Any) -> String {
    return L10n.tr("Localizable", "camera_sub_mode_panorama", String(describing: p1))
  }
  /// 360
  internal static let cameraSubModePanorama360 = L10n.tr("Localizable", "camera_sub_mode_panorama_360")
  /// Horizontal
  internal static let cameraSubModePanoramaHorizontal = L10n.tr("Localizable", "camera_sub_mode_panorama_horizontal")
  /// Super Wide
  internal static let cameraSubModePanoramaSuperWide = L10n.tr("Localizable", "camera_sub_mode_panorama_super_wide")
  /// Vertical
  internal static let cameraSubModePanoramaVertical = L10n.tr("Localizable", "camera_sub_mode_panorama_vertical")
  /// WB
  internal static let cameraWhiteBalance = L10n.tr("Localizable", "camera_white_balance")
  /// Cloudy
  internal static let cameraWhiteBalanceCloudy = L10n.tr("Localizable", "camera_white_balance_cloudy")
  /// Custom
  internal static let cameraWhiteBalanceCustom = L10n.tr("Localizable", "camera_white_balance_custom")
  /// Fluo
  internal static let cameraWhiteBalanceFluo = L10n.tr("Localizable", "camera_white_balance_fluo")
  /// Incandescent
  internal static let cameraWhiteBalanceIncandescent = L10n.tr("Localizable", "camera_white_balance_incandescent")
  /// Shaded
  internal static let cameraWhiteBalanceShaded = L10n.tr("Localizable", "camera_white_balance_shaded")
  /// Sunny
  internal static let cameraWhiteBalanceSunny = L10n.tr("Localizable", "camera_white_balance_sunny")
  /// Cancel
  internal static let cancel = L10n.tr("Localizable", "cancel")
  /// E
  internal static let cardinalDirectionEast = L10n.tr("Localizable", "cardinal_direction_east")
  /// N
  internal static let cardinalDirectionNorth = L10n.tr("Localizable", "cardinal_direction_north")
  /// NE
  internal static let cardinalDirectionNorthEast = L10n.tr("Localizable", "cardinal_direction_north_east")
  /// NW
  internal static let cardinalDirectionNorthWest = L10n.tr("Localizable", "cardinal_direction_north_west")
  /// S
  internal static let cardinalDirectionSouth = L10n.tr("Localizable", "cardinal_direction_south")
  /// SE
  internal static let cardinalDirectionSouthEast = L10n.tr("Localizable", "cardinal_direction_south_east")
  /// SW
  internal static let cardinalDirectionSouthWest = L10n.tr("Localizable", "cardinal_direction_south_west")
  /// W
  internal static let cardinalDirectionWest = L10n.tr("Localizable", "cardinal_direction_west")
  /// Configuration success
  internal static let cellularConfigurationSucceed = L10n.tr("Localizable", "cellular_configuration_succeed")
  /// You can now use cellular network to fly your drone.
  internal static let cellularConfigurationSucceedReadyToUse = L10n.tr("Localizable", "cellular_configuration_succeed_ready_to_use")
  /// Connecting...
  internal static let cellularConnection = L10n.tr("Localizable", "cellular_connection")
  /// Activate
  internal static let cellularConnectionActivate = L10n.tr("Localizable", "cellular_connection_activate")
  /// Cellular connection available
  internal static let cellularConnectionAvailable = L10n.tr("Localizable", "cellular_connection_available")
  /// Configure
  internal static let cellularConnectionAvailableConfigure = L10n.tr("Localizable", "cellular_connection_available_configure")
  /// Do you want to configure cellular connection now?
  internal static let cellularConnectionAvailableConfigureNow = L10n.tr("Localizable", "cellular_connection_available_configure_now")
  /// A SIM card has been detected.
  internal static let cellularConnectionAvailableSimDetected = L10n.tr("Localizable", "cellular_connection_available_sim_detected")
  /// Connected: %@
  internal static func cellularConnectionConnectedOperator(_ p1: Any) -> String {
    return L10n.tr("Localizable", "cellular_connection_connected_operator", String(describing: p1))
  }
  /// Failed to connect
  internal static let cellularConnectionFailedToConnect = L10n.tr("Localizable", "cellular_connection_failed_to_connect")
  /// Please check your internet connection
  internal static let cellularConnectionInternetError = L10n.tr("Localizable", "cellular_connection_internet_error")
  /// Server error
  internal static let cellularConnectionServerError = L10n.tr("Localizable", "cellular_connection_server_error")
  /// Sim card locked, please contact your provider
  internal static let cellularConnectionSimCardLocked = L10n.tr("Localizable", "cellular_connection_sim_card_locked")
  /// Unable to connect
  internal static let cellularConnectionUnableToConnect = L10n.tr("Localizable", "cellular_connection_unable_to_connect")
  /// Unauthorized user
  internal static let cellularConnectionUnauthorizedUser = L10n.tr("Localizable", "cellular_connection_unauthorized_user")
  /// Disabled
  internal static let cellularDetailsDataDisabled = L10n.tr("Localizable", "cellular_details_data_disabled")
  /// Enter PIN code to unlock
  internal static let cellularDetailsEnterPin = L10n.tr("Localizable", "cellular_details_enter_pin")
  /// Please insert SIM card
  internal static let cellularDetailsInsertSimCard = L10n.tr("Localizable", "cellular_details_insert_sim_card")
  /// Internal error
  internal static let cellularDetailsInternalError = L10n.tr("Localizable", "cellular_details_internal_error")
  /// No connection
  internal static let cellularDetailsNoConnection = L10n.tr("Localizable", "cellular_details_no_connection")
  /// No SIM card
  internal static let cellularDetailsNoSimCard = L10n.tr("Localizable", "cellular_details_no_sim_card")
  /// Not paired
  internal static let cellularDetailsNotPaired = L10n.tr("Localizable", "cellular_details_not_paired")
  /// Pair this device to the drone
  internal static let cellularDetailsPairDevice = L10n.tr("Localizable", "cellular_details_pair_device")
  /// Please contact Parrot
  internal static let cellularDetailsPleaseContact = L10n.tr("Localizable", "cellular_details_please_contact")
  /// SIM card blocked
  internal static let cellularDetailsSimBlocked = L10n.tr("Localizable", "cellular_details_sim_blocked")
  /// SIM error
  internal static let cellularDetailsSimCardError = L10n.tr("Localizable", "cellular_details_sim_card_error")
  /// SIM card not recognized
  internal static let cellularDetailsSimCardNotRecognized = L10n.tr("Localizable", "cellular_details_sim_card_not_recognized")
  /// SIM card locked
  internal static let cellularDetailsSimLocked = L10n.tr("Localizable", "cellular_details_sim_locked")
  /// User not paired
  internal static let cellularDetailsUserNotPaired = L10n.tr("Localizable", "cellular_details_user_not_paired")
  /// Unable to establish a connection with the drone
  internal static let cellularErrorConnectionFailedMessage = L10n.tr("Localizable", "cellular_error_connection_failed_message")
  /// Connection failed
  internal static let cellularErrorConnectionFailedTitle = L10n.tr("Localizable", "cellular_error_connection_failed_title")
  /// No internet connection, please try again later
  internal static let cellularErrorInternetTryAgain = L10n.tr("Localizable", "cellular_error_internet_try_again")
  /// No internet connection. Unable to unpair 4G
  internal static let cellularErrorInternetUnpair = L10n.tr("Localizable", "cellular_error_internet_unpair")
  /// Please check your cellular data or turn airplane mode off
  internal static let cellularErrorNoInternetMessage = L10n.tr("Localizable", "cellular_error_no_internet_message")
  /// No internet on your device
  internal static let cellularErrorNoInternetTitle = L10n.tr("Localizable", "cellular_error_no_internet_title")
  /// Please contact your provider
  internal static let cellularErrorSimBlockedMessage = L10n.tr("Localizable", "cellular_error_sim_blocked_message")
  /// SIM card PIN
  internal static let cellularErrorSimBlockedTitle = L10n.tr("Localizable", "cellular_error_sim_blocked_title")
  /// Unable to connect to LTE network
  internal static let cellularErrorUnableConnectNetwork = L10n.tr("Localizable", "cellular_error_unable_connect_network")
  /// Access
  internal static let cellularInfoAccess = L10n.tr("Localizable", "cellular_info_access")
  /// Unable to forget drone
  internal static let cellularPairingDetailsForgotError = L10n.tr("Localizable", "cellular_pairing_details_forgot_error")
  /// Unable to forget drone. There was an error while trying to forget the drone, please try again later.
  internal static let cellularPairingDiscoveryForgotError = L10n.tr("Localizable", "cellular_pairing_discovery_forgot_error")
  /// Forget the drone
  internal static let cellularPairingForgetDrone = L10n.tr("Localizable", "cellular_pairing_forget_drone")
  /// 4G connection and Wi-FI password will be forget. \nDo you want to continue ?
  internal static let cellularPairingForgetDroneDescription = L10n.tr("Localizable", "cellular_pairing_forget_drone_description")
  /// Action
  internal static let commonAction = L10n.tr("Localizable", "common_action")
  /// Active
  internal static let commonActive = L10n.tr("Localizable", "common_active")
  /// App
  internal static let commonApp = L10n.tr("Localizable", "common_app")
  /// Arcade
  internal static let commonArcade = L10n.tr("Localizable", "common_arcade")
  /// Auto
  internal static let commonAuto = L10n.tr("Localizable", "common_auto")
  /// Available
  internal static let commonAvailable = L10n.tr("Localizable", "common_available")
  /// Change
  internal static let commonChange = L10n.tr("Localizable", "common_change")
  /// Checking…
  internal static let commonChecking = L10n.tr("Localizable", "common_checking")
  /// Choose
  internal static let commonChoose = L10n.tr("Localizable", "common_choose")
  /// Classic
  internal static let commonClassic = L10n.tr("Localizable", "common_classic")
  /// Connection State
  internal static let commonConnectionState = L10n.tr("Localizable", "common_connection_state")
  /// Contact
  internal static let commonContact = L10n.tr("Localizable", "common_contact")
  /// Continue
  internal static let commonContinue = L10n.tr("Localizable", "common_continue")
  /// Controller
  internal static let commonController = L10n.tr("Localizable", "common_controller")
  /// Default
  internal static let commonDefault = L10n.tr("Localizable", "common_default")
  /// Delete
  internal static let commonDelete = L10n.tr("Localizable", "common_delete")
  /// Discard
  internal static let commonDiscard = L10n.tr("Localizable", "common_discard")
  /// Distance
  internal static let commonDistance = L10n.tr("Localizable", "common_distance")
  /// Done
  internal static let commonDone = L10n.tr("Localizable", "common_done")
  /// Download
  internal static let commonDownload = L10n.tr("Localizable", "common_download")
  /// Downloaded
  internal static let commonDownloaded = L10n.tr("Localizable", "common_downloaded")
  /// Downloading...
  internal static let commonDownloading = L10n.tr("Localizable", "common_downloading")
  /// Drone
  internal static let commonDrone = L10n.tr("Localizable", "common_drone")
  /// Drone not connected
  internal static let commonDroneNotConnected = L10n.tr("Localizable", "common_drone_not_connected")
  /// Duration
  internal static let commonDuration = L10n.tr("Localizable", "common_duration")
  /// Edit
  internal static let commonEdit = L10n.tr("Localizable", "common_edit")
  /// Email
  internal static let commonEmail = L10n.tr("Localizable", "common_email")
  /// Export
  internal static let commonExport = L10n.tr("Localizable", "common_export")
  /// Flight Plan
  internal static let commonFlightPlan = L10n.tr("Localizable", "common_flight_plan")
  /// Fly
  internal static let commonFly = L10n.tr("Localizable", "common_fly")
  /// Forget
  internal static let commonForget = L10n.tr("Localizable", "common_forget")
  /// free
  internal static let commonFree = L10n.tr("Localizable", "common_free")
  /// Go
  internal static let commonGo = L10n.tr("Localizable", "common_go")
  /// Handland
  internal static let commonHandland = L10n.tr("Localizable", "common_handland")
  /// Handlaunch
  internal static let commonHandlaunch = L10n.tr("Localizable", "common_handlaunch")
  /// Hovering
  internal static let commonHovering = L10n.tr("Localizable", "common_hovering")
  /// Info
  internal static let commonInfos = L10n.tr("Localizable", "common_infos")
  /// Keep
  internal static let commonKeep = L10n.tr("Localizable", "common_keep")
  /// Landing
  internal static let commonLanding = L10n.tr("Localizable", "common_landing")
  /// Later
  internal static let commonLater = L10n.tr("Localizable", "common_later")
  /// Log in
  internal static let commonLogIn = L10n.tr("Localizable", "common_log_in")
  /// Manual
  internal static let commonManual = L10n.tr("Localizable", "common_manual")
  /// Max
  internal static let commonMax = L10n.tr("Localizable", "common_max")
  /// Memory
  internal static let commonMemory = L10n.tr("Localizable", "common_memory")
  /// Min
  internal static let commonMin = L10n.tr("Localizable", "common_min")
  /// Start mission
  internal static let commonMissionStart = L10n.tr("Localizable", "common_mission_start")
  /// Mode
  internal static let commonMode = L10n.tr("Localizable", "common_mode")
  /// No
  internal static let commonNo = L10n.tr("Localizable", "common_no")
  /// No GPS
  internal static let commonNoGps = L10n.tr("Localizable", "common_no_gps")
  /// No internet connection
  internal static let commonNoInternetConnection = L10n.tr("Localizable", "common_no_internet_connection")
  /// Not connected
  internal static let commonNotConnected = L10n.tr("Localizable", "common_not_connected")
  /// Not specified
  internal static let commonNotSpecified = L10n.tr("Localizable", "common_not_specified")
  /// Off
  internal static let commonOff = L10n.tr("Localizable", "common_off")
  /// Offline
  internal static let commonOffline = L10n.tr("Localizable", "common_offline")
  /// On
  internal static let commonOn = L10n.tr("Localizable", "common_on")
  /// Options
  internal static let commonOptions = L10n.tr("Localizable", "common_options")
  /// or
  internal static let commonOr = L10n.tr("Localizable", "common_or")
  /// Password
  internal static let commonPassword = L10n.tr("Localizable", "common_password")
  /// %@ photo
  internal static func commonPhotoPlaceholder(_ p1: Any) -> String {
    return L10n.tr("Localizable", "common_photo_placeholder", String(describing: p1))
  }
  /// %@ photos
  internal static func commonPhotoPlaceholderPlural(_ p1: Any) -> String {
    return L10n.tr("Localizable", "common_photo_placeholder_plural", String(describing: p1))
  }
  /// Piloting
  internal static let commonPiloting = L10n.tr("Localizable", "common_piloting")
  /// POI
  internal static let commonPoi = L10n.tr("Localizable", "common_poi")
  /// Presets
  internal static let commonPresets = L10n.tr("Localizable", "common_presets")
  /// Pro
  internal static let commonPro = L10n.tr("Localizable", "common_pro")
  /// Ready
  internal static let commonReady = L10n.tr("Localizable", "common_ready")
  /// Recommended
  internal static let commonRecommended = L10n.tr("Localizable", "common_recommended")
  /// Rename
  internal static let commonRename = L10n.tr("Localizable", "common_rename")
  /// Required
  internal static let commonRequired = L10n.tr("Localizable", "common_required")
  /// Reset
  internal static let commonReset = L10n.tr("Localizable", "common_reset")
  /// Retry
  internal static let commonRetry = L10n.tr("Localizable", "common_retry")
  /// Return Home
  internal static let commonReturnHome = L10n.tr("Localizable", "common_return_home")
  /// SD Error
  internal static let commonSdError = L10n.tr("Localizable", "common_sd_error")
  /// SD busy
  internal static let commonSdErrorBusy = L10n.tr("Localizable", "common_sd_error_busy")
  /// SD full
  internal static let commonSdErrorFull = L10n.tr("Localizable", "common_sd_error_full")
  /// Select
  internal static let commonSelect = L10n.tr("Localizable", "common_select")
  /// %@ selected
  internal static func commonSelected(_ p1: Any) -> String {
    return L10n.tr("Localizable", "common_selected", String(describing: p1))
  }
  /// %@ selected
  internal static func commonSelectedPlural(_ p1: Any) -> String {
    return L10n.tr("Localizable", "common_selected_plural", String(describing: p1))
  }
  /// Share
  internal static let commonShare = L10n.tr("Localizable", "common_share")
  /// Share to support
  internal static let commonShareSupport = L10n.tr("Localizable", "common_share_support")
  /// Speed
  internal static let commonSpeed = L10n.tr("Localizable", "common_speed")
  /// Start
  internal static let commonStart = L10n.tr("Localizable", "common_start")
  /// Start tutorial
  internal static let commonStartTutorial = L10n.tr("Localizable", "common_start_tutorial")
  /// Stop
  internal static let commonStop = L10n.tr("Localizable", "common_stop")
  /// Style
  internal static let commonStyle = L10n.tr("Localizable", "common_style")
  /// Test
  internal static let commonTest = L10n.tr("Localizable", "common_test")
  /// Today
  internal static let commonToday = L10n.tr("Localizable", "common_today")
  /// Unavailable
  internal static let commonUnavailable = L10n.tr("Localizable", "common_unavailable")
  /// Undo
  internal static let commonUndo = L10n.tr("Localizable", "common_undo")
  /// %@ video
  internal static func commonVideoPlaceholder(_ p1: Any) -> String {
    return L10n.tr("Localizable", "common_video_placeholder", String(describing: p1))
  }
  /// %@ videos
  internal static func commonVideoPlaceholderPlural(_ p1: Any) -> String {
    return L10n.tr("Localizable", "common_video_placeholder_plural", String(describing: p1))
  }
  /// Warning
  internal static let commonWarning = L10n.tr("Localizable", "common_warning")
  /// Waypoint
  internal static let commonWaypoint = L10n.tr("Localizable", "common_waypoint")
  /// Yes
  internal static let commonYes = L10n.tr("Localizable", "common_yes")
  /// Yesterday
  internal static let commonYesterday = L10n.tr("Localizable", "common_yesterday")
  /// Configure now
  internal static let configurationConfigureNow = L10n.tr("Localizable", "configuration_configure_now")
  /// You are all set to use %@ and start flying Anafi Ai
  internal static func configurationConfigureText(_ p1: Any) -> String {
    return L10n.tr("Localizable", "configuration_configure_text", String(describing: p1))
  }
  /// Do you want to configure your drone now ?
  internal static let configurationConfigureYourDrone = L10n.tr("Localizable", "configuration_configure_your_drone")
  /// Connect
  internal static let connect = L10n.tr("Localizable", "connect")
  /// Connect drone
  internal static let connectDrone = L10n.tr("Localizable", "connect_drone")
  /// Connected
  internal static let connected = L10n.tr("Localizable", "connected")
  /// Connecting
  internal static let connecting = L10n.tr("Localizable", "connecting")
  /// Account
  internal static let dashboardAccount = L10n.tr("Localizable", "dashboard_account")
  /// Add my account
  internal static let dashboardAddMyAccount = L10n.tr("Localizable", "dashboard_add_my_account")
  /// Add services
  internal static let dashboardAddServices = L10n.tr("Localizable", "dashboard_add_services")
  /// Map preload
  internal static let dashboardConditionsMapPreload = L10n.tr("Localizable", "dashboard_conditions_map_preload")
  /// Conditions
  internal static let dashboardConditionsTitle = L10n.tr("Localizable", "dashboard_conditions_title")
  /// Connected accounts
  internal static let dashboardConnectedAccounts = L10n.tr("Localizable", "dashboard_connected_accounts")
  /// Flight zone
  internal static let dashboardFlightZoneTitle = L10n.tr("Localizable", "dashboard_flight_zone_title")
  /// Data Confidentiality
  internal static let dashboardFooterDataConfidentiality = L10n.tr("Localizable", "dashboard_footer_data_confidentiality")
  /// Insert link to your account here
  internal static let dashboardLinkAccount = L10n.tr("Localizable", "dashboard_link_account")
  /// Medias
  internal static let dashboardMediasTitle = L10n.tr("Localizable", "dashboard_medias_title")
  /// Delete flight
  internal static let dashboardMyFlightDeleteFlight = L10n.tr("Localizable", "dashboard_my_flight_delete_flight")
  /// Flight log
  internal static let dashboardMyFlightFlightLog = L10n.tr("Localizable", "dashboard_my_flight_flight_log")
  /// Share flight
  internal static let dashboardMyFlightShareFlight = L10n.tr("Localizable", "dashboard_my_flight_share_flight")
  /// Unknown location
  internal static let dashboardMyFlightUnknownLocation = L10n.tr("Localizable", "dashboard_my_flight_unknown_location")
  /// Can't synchronize
  internal static let dashboardMyFlightsCannotSynchronize = L10n.tr("Localizable", "dashboard_my_flights_cannot_synchronize")
  /// Connect to sync flights
  internal static let dashboardMyFlightsConnectToSync = L10n.tr("Localizable", "dashboard_my_flights_connect_to_sync")
  /// Connect to Parrot Cloud to sync all your flights and flight plans. 
  internal static let dashboardMyFlightsEmptyListDesc = L10n.tr("Localizable", "dashboard_my_flights_empty_list_desc")
  /// No flight for the moment
  internal static let dashboardMyFlightsEmptyListTitle = L10n.tr("Localizable", "dashboard_my_flights_empty_list_title")
  /// Last flight time
  internal static let dashboardMyFlightsLastFlightTime = L10n.tr("Localizable", "dashboard_my_flights_last_flight_time")
  /// Not connected
  internal static let dashboardMyFlightsNotConnected = L10n.tr("Localizable", "dashboard_my_flights_not_connected")
  /// Plan execution
  internal static let dashboardMyFlightsPlanExecution = L10n.tr("Localizable", "dashboard_my_flights_plan_execution")
  /// All flights
  internal static let dashboardMyFlightsSectionCompleted = L10n.tr("Localizable", "dashboard_my_flights_section_completed")
  /// Plan executions
  internal static let dashboardMyFlightsSectionPlans = L10n.tr("Localizable", "dashboard_my_flights_section_plans")
  /// Last flight
  internal static let dashboardMyFlightsSubtitle = L10n.tr("Localizable", "dashboard_my_flights_subtitle")
  /// Synchronisation %d/%d
  internal static func dashboardMyFlightsSynchronization(_ p1: Int, _ p2: Int) -> String {
    return L10n.tr("Localizable", "dashboard_my_flights_synchronization", p1, p2)
  }
  /// Synchronised
  internal static let dashboardMyFlightsSynchronized = L10n.tr("Localizable", "dashboard_my_flights_synchronized")
  /// My flights
  internal static let dashboardMyFlightsTitle = L10n.tr("Localizable", "dashboard_my_flights_title")
  /// %d flights to sync.
  internal static func dashboardMyFlightsToSync(_ p1: Int) -> String {
    return L10n.tr("Localizable", "dashboard_my_flights_to_sync", p1)
  }
  /// Total distance
  internal static let dashboardMyFlightsTotalDistance = L10n.tr("Localizable", "dashboard_my_flights_total_distance")
  /// Total time
  internal static let dashboardMyFlightsTotalTime = L10n.tr("Localizable", "dashboard_my_flights_total_time")
  /// services
  internal static let dashboardServices = L10n.tr("Localizable", "dashboard_services")
  /// Fly
  internal static let dashboardStartButtonFly = L10n.tr("Localizable", "dashboard_start_button_fly")
  /// Piloting
  internal static let dashboardStartButtonPiloting = L10n.tr("Localizable", "dashboard_start_button_piloting")
  /// Suggestions
  internal static let dashboardSuggestionsTitle = L10n.tr("Localizable", "dashboard_suggestions_title")
  /// Report an issue or suggest an idea
  internal static let dashboardSupportSubtitle = L10n.tr("Localizable", "dashboard_support_subtitle")
  /// Support
  internal static let dashboardSupportTitle = L10n.tr("Localizable", "dashboard_support_title")
  /// Discover the full potential of your Parrot
  internal static let dashboardTutorialsSubtitle = L10n.tr("Localizable", "dashboard_tutorials_subtitle")
  /// Tutorials
  internal static let dashboardTutorialsTitle = L10n.tr("Localizable", "dashboard_tutorials_title")
  /// Update
  internal static let dashboardUpdate = L10n.tr("Localizable", "dashboard_update")
  /// Active Log
  internal static let debugLogActivateLog = L10n.tr("Localizable", "debug_log_activate_log")
  /// Build DEBUG
  internal static let debugLogBuildDebug = L10n.tr("Localizable", "debug_log_build_debug")
  /// Build RELEASE
  internal static let debugLogBuildRelease = L10n.tr("Localizable", "debug_log_build_release")
  /// Rename Log File
  internal static let debugLogRenameFile = L10n.tr("Localizable", "debug_log_rename_file")
  /// Restart application to activate stream record
  internal static let debugLogRestartApp = L10n.tr("Localizable", "debug_log_restart_app")
  /// Stream Record
  internal static let debugLogStreamRecord = L10n.tr("Localizable", "debug_log_stream_record")
  /// Stream Record Enabled
  internal static let debugLogStreamRecordEnabled = L10n.tr("Localizable", "debug_log_stream_record_enabled")
  /// Firmware version
  internal static let deviceDetailsFirmwareVersion = L10n.tr("Localizable", "device_details_firmware_version")
  /// Software version
  internal static let deviceDetailsSoftwareVersion = L10n.tr("Localizable", "device_details_software_version")
  /// It seems that the internet connection has been interrupted. Please verify that you have internet access.
  internal static let deviceUpdateConnectionInterruptedDescription = L10n.tr("Localizable", "device_update_connection_interrupted_description")
  /// Internet connection interrupted
  internal static let deviceUpdateConnectionInterruptedTitle = L10n.tr("Localizable", "device_update_connection_interrupted_title")
  /// Your drone is currently in flight. It must be placed on the ground to perform the update safely
  internal static let deviceUpdateDroneFlying = L10n.tr("Localizable", "device_update_drone_flying")
  /// Update impossible
  internal static let deviceUpdateImpossible = L10n.tr("Localizable", "device_update_impossible")
  /// It seems that you are not connected to the internet
  internal static let deviceUpdateInternetUnreachableTitle = L10n.tr("Localizable", "device_update_internet_unreachable_title")
  /// One motor seems broken. Please contact support.
  internal static let diagnosticsDashboardBrokenMotor = L10n.tr("Localizable", "diagnostics_dashboard_broken_motor")
  /// Please calibrate the drone's camera.
  internal static let diagnosticsDashboardCameraCalibrationRequired = L10n.tr("Localizable", "diagnostics_dashboard_camera_calibration_required")
  /// Camera error detected. Please contact support.
  internal static let diagnosticsDashboardCameraError = L10n.tr("Localizable", "diagnostics_dashboard_camera_error")
  /// The battery temperature is very high, please check the battery state.
  internal static let diagnosticsDashboardHighBatteryTemperature = L10n.tr("Localizable", "diagnostics_dashboard_high_battery_temperature")
  /// The motors temperature is very high, please check the motors state.
  internal static let diagnosticsDashboardHighMotorTemperature = L10n.tr("Localizable", "diagnostics_dashboard_high_motor_temperature")
  /// The drone didn't complete the Fligth Plan. You can start where you left off.
  internal static let diagnosticsDashboardIncompleteFlightPlan = L10n.tr("Localizable", "diagnostics_dashboard_incomplete_flight_plan")
  /// Please calibrate the detection cameras.
  internal static let diagnosticsDashboardLoveCalibrationRequired = L10n.tr("Localizable", "diagnostics_dashboard_love_calibration_required")
  /// Detection camera error detected. Please contact support.
  internal static let diagnosticsDashboardLoveKo = L10n.tr("Localizable", "diagnostics_dashboard_love_ko")
  /// Low battery level. Change battery before your next flight.
  internal static let diagnosticsDashboardLowBatteryLevel = L10n.tr("Localizable", "diagnostics_dashboard_low_battery_level")
  /// The motors temperature is very low, please check the battery state.
  internal static let diagnosticsDashboardLowBatteryTemperature = L10n.tr("Localizable", "diagnostics_dashboard_low_battery_temperature")
  /// The motors temperature is very low, please check the motors state.
  internal static let diagnosticsDashboardLowMotorTemperature = L10n.tr("Localizable", "diagnostics_dashboard_low_motor_temperature")
  /// One motor seems to have stopped, please check the motors state.
  internal static let diagnosticsDashboardMotorCutout = L10n.tr("Localizable", "diagnostics_dashboard_motor_cutout")
  /// A propeller seems broken. Please check the propellers state.
  internal static let diagnosticsDashboardPropellerBroken = L10n.tr("Localizable", "diagnostics_dashboard_propeller_broken")
  /// A propeller seems unscrewed. Please check the propoellers state.
  internal static let diagnosticsDashboardPropellerUnscrewed = L10n.tr("Localizable", "diagnostics_dashboard_propeller_unscrewed")
  /// Your SD card is almost full, please make space before your next flight.
  internal static let diagnosticsDashboardSdAlmostFull = L10n.tr("Localizable", "diagnostics_dashboard_sd_almost_full")
  /// Your SD card is full, please make space before your next flight.
  internal static let diagnosticsDashboardSdFull = L10n.tr("Localizable", "diagnostics_dashboard_sd_full")
  /// Your battery seems to be used. Please read the battery advice page.
  internal static let diagnosticsDashboardUsedBattery = L10n.tr("Localizable", "diagnostics_dashboard_used_battery")
  /// Vertical camera error detected. Please contact support.
  internal static let diagnosticsDashboardVcamError = L10n.tr("Localizable", "diagnostics_dashboard_vcam_error")
  /// Damaged motor.
  internal static let diagnosticsFlightReportBrokenMotor = L10n.tr("Localizable", "diagnostics_flight_report_broken_motor")
  /// Camera calibration required
  internal static let diagnosticsFlightReportCameraCalibrationRequired = L10n.tr("Localizable", "diagnostics_flight_report_camera_calibration_required")
  /// Camera error
  internal static let diagnosticsFlightReportCameraError = L10n.tr("Localizable", "diagnostics_flight_report_camera_error")
  /// Everything is ok.
  internal static let diagnosticsFlightReportEverythingOk = L10n.tr("Localizable", "diagnostics_flight_report_everything_ok")
  /// High battery temperature
  internal static let diagnosticsFlightReportHighBatteryTemperature = L10n.tr("Localizable", "diagnostics_flight_report_high_battery_temperature")
  /// High motor temperature
  internal static let diagnosticsFlightReportHighMotorTemperature = L10n.tr("Localizable", "diagnostics_flight_report_high_motor_temperature")
  /// Incomplete Flight Plan.
  internal static let diagnosticsFlightReportIncompleteFlightPlan = L10n.tr("Localizable", "diagnostics_flight_report_incomplete_flight_plan")
  /// Obstacle sensors calibration required.
  internal static let diagnosticsFlightReportLoveCalibrationRequired = L10n.tr("Localizable", "diagnostics_flight_report_love_calibration_required")
  /// Obstacle sensors error
  internal static let diagnosticsFlightReportLoveKo = L10n.tr("Localizable", "diagnostics_flight_report_love_ko")
  /// Low battery level
  internal static let diagnosticsFlightReportLowBatteryLevel = L10n.tr("Localizable", "diagnostics_flight_report_low_battery_level")
  /// Low battery temperature
  internal static let diagnosticsFlightReportLowBatteryTemperature = L10n.tr("Localizable", "diagnostics_flight_report_low_battery_temperature")
  /// Low motor temperature
  internal static let diagnosticsFlightReportLowMotorTemperature = L10n.tr("Localizable", "diagnostics_flight_report_low_motor_temperature")
  /// Motor cutout
  internal static let diagnosticsFlightReportMotorCutout = L10n.tr("Localizable", "diagnostics_flight_report_motor_cutout")
  /// Check propellers
  internal static let diagnosticsFlightReportPropellerBroken = L10n.tr("Localizable", "diagnostics_flight_report_propeller_broken")
  /// Check propellers
  internal static let diagnosticsFlightReportPropellerUnscrewed = L10n.tr("Localizable", "diagnostics_flight_report_propeller_unscrewed")
  /// SD card almost full
  internal static let diagnosticsFlightReportSdAlmostFull = L10n.tr("Localizable", "diagnostics_flight_report_sd_almost_full")
  /// SD card full
  internal static let diagnosticsFlightReportSdFull = L10n.tr("Localizable", "diagnostics_flight_report_sd_full")
  /// Used battery detected
  internal static let diagnosticsFlightReportUsedBattery = L10n.tr("Localizable", "diagnostics_flight_report_used_battery")
  /// Vertical camera error
  internal static let diagnosticsFlightReportVcamError = L10n.tr("Localizable", "diagnostics_flight_report_vcam_error")
  /// Disconnected
  internal static let disconnected = L10n.tr("Localizable", "disconnected")
  /// Disconnecting
  internal static let disconnecting = L10n.tr("Localizable", "disconnecting")
  /// %dm
  internal static func distanceInMeters(_ p1: Int) -> String {
    return L10n.tr("Localizable", "distance_in_meters", p1)
  }
  /// Cellular access is active
  internal static let drone4gCellularAccessActive = L10n.tr("Localizable", "drone_4g_cellular_access_active")
  /// Connection debug
  internal static let drone4gConnectionDebug = L10n.tr("Localizable", "drone_4g_connection_debug")
  /// Enter PIN
  internal static let drone4gEnterPin = L10n.tr("Localizable", "drone_4g_enter_pin")
  /// Reinitialize connections
  internal static let drone4gReinitializeConnections = L10n.tr("Localizable", "drone_4g_reinitialize_connections")
  /// Show debug
  internal static let drone4gShowDebug = L10n.tr("Localizable", "drone_4g_show_debug")
  /// SIM blocked
  internal static let drone4gSimBlocked = L10n.tr("Localizable", "drone_4g_sim_blocked")
  /// SIM card is locked
  internal static let drone4gSimIsLocked = L10n.tr("Localizable", "drone_4g_sim_is_locked")
  /// SIM locked
  internal static let drone4gSimLocked = L10n.tr("Localizable", "drone_4g_sim_locked")
  /// %d users can access that drone through cellular network
  internal static func drone4gUserAccessPlural(_ p1: Int) -> String {
    return L10n.tr("Localizable", "drone_4g_user_access_plural", p1)
  }
  /// %d user can access that drone through cellular network
  internal static func drone4gUserAccessSingular(_ p1: Int) -> String {
    return L10n.tr("Localizable", "drone_4g_user_access_singular", p1)
  }
  /// Drone calibration
  internal static let droneCalibrationDrone = L10n.tr("Localizable", "drone_calibration_drone")
  /// Calibration failed
  internal static let droneCalibrationFailed = L10n.tr("Localizable", "drone_calibration_failed")
  /// Please make sure that the points below are respected:
  internal static let droneCalibrationFailureDescription = L10n.tr("Localizable", "drone_calibration_failure_description")
  /// Please keep your drone away from metallic objects.
  internal static let droneCalibrationFailureInstruction = L10n.tr("Localizable", "drone_calibration_failure_instruction")
  /// All four drone's feet are opened.
  internal static let droneCalibrationFailureItem1 = L10n.tr("Localizable", "drone_calibration_failure_item1")
  /// You are in an open area without metallic structures or close by.
  internal static let droneCalibrationFailureItem2 = L10n.tr("Localizable", "drone_calibration_failure_item2")
  /// You are not wearing a metallic object like a watch.
  internal static let droneCalibrationFailureItem3 = L10n.tr("Localizable", "drone_calibration_failure_item3")
  /// There are not electronic devices close by.
  internal static let droneCalibrationFailureItem4 = L10n.tr("Localizable", "drone_calibration_failure_item4")
  /// Gimbal calibration
  internal static let droneCalibrationGimbal = L10n.tr("Localizable", "drone_calibration_gimbal")
  /// (follow the animation)
  internal static let droneCalibrationInstructionComplement = L10n.tr("Localizable", "drone_calibration_instruction_complement")
  /// You are going to calibrate your drone. This short
  internal static let droneCalibrationIntroduction = L10n.tr("Localizable", "drone_calibration_introduction")
  /// operation will allow you to fly outside
  internal static let droneCalibrationIntroductionComplement = L10n.tr("Localizable", "drone_calibration_introduction_complement")
  /// Please turn the drone around its Y axe
  internal static let droneCalibrationPitchInstruction = L10n.tr("Localizable", "drone_calibration_pitch_instruction")
  /// Axe Y (Pitch)
  internal static let droneCalibrationPitchLabel = L10n.tr("Localizable", "drone_calibration_pitch_label")
  /// Your drone is ready to fly.
  internal static let droneCalibrationReadyToFly = L10n.tr("Localizable", "drone_calibration_ready_to_fly")
  /// Drone calibration recommended
  internal static let droneCalibrationRecommended = L10n.tr("Localizable", "drone_calibration_recommended")
  /// Try again
  internal static let droneCalibrationRedo = L10n.tr("Localizable", "drone_calibration_redo")
  /// Calibration required
  internal static let droneCalibrationRequired = L10n.tr("Localizable", "drone_calibration_required")
  /// Please turn the drone around its X axe
  internal static let droneCalibrationRollInstruction = L10n.tr("Localizable", "drone_calibration_roll_instruction")
  /// Axe X (Roll)
  internal static let droneCalibrationRollLabel = L10n.tr("Localizable", "drone_calibration_roll_label")
  /// Please turn the drone around its Z axe
  internal static let droneCalibrationYawInstruction = L10n.tr("Localizable", "drone_calibration_yaw_instruction")
  /// Axe Z (Yaw)
  internal static let droneCalibrationYawLabel = L10n.tr("Localizable", "drone_calibration_yaw_label")
  /// Gimbal calibration recommended
  internal static let droneDetailsCalibrationGimbalRecommended = L10n.tr("Localizable", "drone_details_calibration_gimbal_recommended")
  /// Gimbal calibration required
  internal static let droneDetailsCalibrationGimbalRequired = L10n.tr("Localizable", "drone_details_calibration_gimbal_required")
  /// Sensors calibration required
  internal static let droneDetailsCalibrationLoveRequired = L10n.tr("Localizable", "drone_details_calibration_love_required")
  /// All ok
  internal static let droneDetailsCalibrationOk = L10n.tr("Localizable", "drone_details_calibration_ok")
  /// Drone calibration required
  internal static let droneDetailsCalibrationRequired = L10n.tr("Localizable", "drone_details_calibration_required")
  /// Cellular access
  internal static let droneDetailsCellularAccess = L10n.tr("Localizable", "drone_details_cellular_access")
  /// Drone's information
  internal static let droneDetailsDroneInfo = L10n.tr("Localizable", "drone_details_drone_info")
  /// Hardware version
  internal static let droneDetailsHardwareVersion = L10n.tr("Localizable", "drone_details_hardware_version")
  /// IMEI
  internal static let droneDetailsImei = L10n.tr("Localizable", "drone_details_imei")
  /// Informations
  internal static let droneDetailsInformations = L10n.tr("Localizable", "drone_details_informations")
  /// Last known position
  internal static let droneDetailsLastKnownPosition = L10n.tr("Localizable", "drone_details_last_known_position")
  /// Not connected
  internal static let droneDetailsNotConnected = L10n.tr("Localizable", "drone_details_not_connected")
  /// Number of flights
  internal static let droneDetailsNumberFlights = L10n.tr("Localizable", "drone_details_number_flights")
  /// Product type
  internal static let droneDetailsProductType = L10n.tr("Localizable", "drone_details_product_type")
  /// Reinitiating your drone will erase the list of associated controllers, reinitiate the name of the drone and the Wi-Fi password. Are you sure you want to continue ?
  internal static let droneDetailsResetDescription = L10n.tr("Localizable", "drone_details_reset_description")
  /// Drone reinitialization
  internal static let droneDetailsResetTitle = L10n.tr("Localizable", "drone_details_reset_title")
  /// Total flight time
  internal static let droneDetailsTotalFlightTime = L10n.tr("Localizable", "drone_details_total_flight_time")
  /// Update to %@
  internal static func droneDetailsUpdateTo(_ p1: Any) -> String {
    return L10n.tr("Localizable", "drone_details_update_to", String(describing: p1))
  }
  /// Wi-Fi password
  internal static let droneDetailsWifiPassword = L10n.tr("Localizable", "drone_details_wifi_password")
  /// Gimbal
  internal static let droneGimbalTitle = L10n.tr("Localizable", "drone_gimbal_title")
  /// Correct horizon
  internal static let droneHorizonCalibration = L10n.tr("Localizable", "drone_horizon_calibration")
  /// Correction
  internal static let droneHorizonCalibrationCorrection = L10n.tr("Localizable", "drone_horizon_calibration_correction")
  /// You are about to calibrate your drone.
  internal static let droneMagnetometerCalibrationInstruction = L10n.tr("Localizable", "drone_magnetometer_calibration_instruction")
  /// Please make sure to unfold the drone's feets.
  internal static let droneMagnetometerCalibrationInstructionComplement = L10n.tr("Localizable", "drone_magnetometer_calibration_instruction_complement")
  /// Please reproduce this movement with your drone.
  internal static let droneMagnetometerCalibrationMessage = L10n.tr("Localizable", "drone_magnetometer_calibration_message")
  /// Magnetometer calibration required
  internal static let droneMagnetometerCalibrationRequired = L10n.tr("Localizable", "drone_magnetometer_calibration_required")
  /// Magnetometer
  internal static let droneMagnetometerTitle = L10n.tr("Localizable", "drone_magnetometer_title")
  /// Obstacle detection
  internal static let droneObstacleDetectionTitle = L10n.tr("Localizable", "drone_obstacle_detection_title")
  /// In order to optimize your flight experience, we will update your drone.
  internal static let droneUpdateConfirmDescription = L10n.tr("Localizable", "drone_update_confirm_description")
  /// Drone update
  internal static let droneUpdateControllerUpdate = L10n.tr("Localizable", "drone_update_controller_update")
  /// The battery level of your drone is below %@. This is too weak to safely perform the update.
  internal static func droneUpdateInsufficientBatteryDescription(_ p1: Any) -> String {
    return L10n.tr("Localizable", "drone_update_insufficient_battery_description", String(describing: p1))
  }
  /// Insufficient drone’s battery
  internal static let droneUpdateInsufficientBatteryTitle = L10n.tr("Localizable", "drone_update_insufficient_battery_title")
  /// You need an internet connection to download the drone’s firmware. Please check your connection or try again later.
  internal static let droneUpdateInternetUnreachableDescription = L10n.tr("Localizable", "drone_update_internet_unreachable_description")
  /// The drone is being updated, please leave it on until the end of the procedure.
  internal static let droneUpdateRebootingError = L10n.tr("Localizable", "drone_update_rebooting_error")
  /// Sending to the drone
  internal static let droneUpdateSendingStep = L10n.tr("Localizable", "drone_update_sending_step")
  /// Error
  internal static let error = L10n.tr("Localizable", "error")
  /// Your controller is currently being updated, this operation can not be cancelled. You can leave the screen, the drone will finish updating.
  internal static let firmwareAndMissionQuitRebootControllerMessage = L10n.tr("Localizable", "firmware_and_mission_quit_reboot_controller_message")
  /// Your drone is currently being updated, this operation can not be cancelled. You can leave the screen, the drone will finish updating.
  internal static let firmwareAndMissionQuitRebootDroneMessage = L10n.tr("Localizable", "firmware_and_mission_quit_reboot_drone_message")
  /// Update ongoing
  internal static let firmwareAndMissionQuitRebootTitle = L10n.tr("Localizable", "firmware_and_mission_quit_reboot_title")
  /// Leave screen
  internal static let firmwareAndMissionQuitRebootValidateAction = L10n.tr("Localizable", "firmware_and_mission_quit_reboot_validate_action")
  /// The controller update has been cancelled.
  internal static let firmwareAndMissionUpdateCancelledControllerMessage = L10n.tr("Localizable", "firmware_and_mission_update_cancelled_controller_message")
  /// The drone update has been cancelled.
  internal static let firmwareAndMissionUpdateCancelledDroneMessage = L10n.tr("Localizable", "firmware_and_mission_update_cancelled_drone_message")
  /// Update cancelled
  internal static let firmwareAndMissionUpdateCancelledTitle = L10n.tr("Localizable", "firmware_and_mission_update_cancelled_title")
  /// An error occurred. Please try again later.
  internal static let firmwareMissionUpdateAlertCommonMessage = L10n.tr("Localizable", "firmware_mission_update_alert_common_message")
  /// Your drone is currently flying. Please land the drone to proceed safely with the update
  internal static let firmwareMissionUpdateAlertDroneFlyingMessage = L10n.tr("Localizable", "firmware_mission_update_alert_drone_flying_message")
  /// Drone flying
  internal static let firmwareMissionUpdateAlertDroneFlyingTitle = L10n.tr("Localizable", "firmware_mission_update_alert_drone_flying_title")
  /// There is not enough space to install or update missions. Do you want to erase the internal memory ? This will remove all currently installed missions and media.
  internal static let firmwareMissionUpdateAlertMemoryFullMessage = L10n.tr("Localizable", "firmware_mission_update_alert_memory_full_message")
  /// Erase internal memory
  internal static let firmwareMissionUpdateAlertMemoryFullValidateAction = L10n.tr("Localizable", "firmware_mission_update_alert_memory_full_validate_action")
  /// Controller %@
  internal static func firmwareMissionUpdateControllerVersion(_ p1: Any) -> String {
    return L10n.tr("Localizable", "firmware_mission_update_controller_version", String(describing: p1))
  }
  /// Download %@
  internal static func firmwareMissionUpdateDownloadFirmware(_ p1: Any) -> String {
    return L10n.tr("Localizable", "firmware_mission_update_download_firmware", String(describing: p1))
  }
  /// Downloading firmware
  internal static let firmwareMissionUpdateDownloadingFirmware = L10n.tr("Localizable", "firmware_mission_update_downloading_firmware")
  /// You need an internet connection to download the drone’s firmware. Please check your connection.\nDo you want to upload the missions to the drone anyway?
  internal static let firmwareMissionUpdateDroneAlertNoInternetDescription = L10n.tr("Localizable", "firmware_mission_update_drone_alert_no_internet_description")
  /// Drone %@
  internal static func firmwareMissionUpdateDroneVersion(_ p1: Any) -> String {
    return L10n.tr("Localizable", "firmware_mission_update_drone_version", String(describing: p1))
  }
  /// Error: %@
  internal static func firmwareMissionUpdateError(_ p1: Any) -> String {
    return L10n.tr("Localizable", "firmware_mission_update_error", String(describing: p1))
  }
  /// bad info file
  internal static let firmwareMissionUpdateErrorBadInfoFile = L10n.tr("Localizable", "firmware_mission_update_error_bad_info_file")
  /// malformed mission file
  internal static let firmwareMissionUpdateErrorBadMission = L10n.tr("Localizable", "firmware_mission_update_error_bad_mission")
  /// bad request
  internal static let firmwareMissionUpdateErrorBadRequest = L10n.tr("Localizable", "firmware_mission_update_error_bad_request")
  /// other upload in progress
  internal static let firmwareMissionUpdateErrorBusy = L10n.tr("Localizable", "firmware_mission_update_error_busy")
  /// update cancelled
  internal static let firmwareMissionUpdateErrorCancelled = L10n.tr("Localizable", "firmware_mission_update_error_cancelled")
  /// connection error
  internal static let firmwareMissionUpdateErrorConnection = L10n.tr("Localizable", "firmware_mission_update_error_connection")
  /// corrupted file
  internal static let firmwareMissionUpdateErrorCorruptedFile = L10n.tr("Localizable", "firmware_mission_update_error_corrupted_file")
  /// incorrect method
  internal static let firmwareMissionUpdateErrorIncorrectMethod = L10n.tr("Localizable", "firmware_mission_update_error_incorrect_method")
  /// installation failed
  internal static let firmwareMissionUpdateErrorInstallationFailed = L10n.tr("Localizable", "firmware_mission_update_error_installation_failed")
  /// invalid signature
  internal static let firmwareMissionUpdateErrorInvalidSignature = L10n.tr("Localizable", "firmware_mission_update_error_invalid_signature")
  /// mission already installed
  internal static let firmwareMissionUpdateErrorMissionAlreadyExists = L10n.tr("Localizable", "firmware_mission_update_error_mission_already_exists")
  /// model mismatch
  internal static let firmwareMissionUpdateErrorModelMismatch = L10n.tr("Localizable", "firmware_mission_update_error_model_mismatch")
  /// no space left in internal storage
  internal static let firmwareMissionUpdateErrorNoSpaceLeft = L10n.tr("Localizable", "firmware_mission_update_error_no_space_left")
  /// server error
  internal static let firmwareMissionUpdateErrorServer = L10n.tr("Localizable", "firmware_mission_update_error_server")
  /// version mismatch
  internal static let firmwareMissionUpdateErrorVersionMismatch = L10n.tr("Localizable", "firmware_mission_update_error_version_mismatch")
  /// Firmware download failed
  internal static let firmwareMissionUpdateFirmwareDownloadFailed = L10n.tr("Localizable", "firmware_mission_update_firmware_download_failed")
  /// Firmware installation failed
  internal static let firmwareMissionUpdateFirmwareInstallFailed = L10n.tr("Localizable", "firmware_mission_update_firmware_install_failed")
  /// Anafi Ai Firmware
  internal static let firmwareMissionUpdateFirmwareName = L10n.tr("Localizable", "firmware_mission_update_firmware_name")
  /// Firmware Update
  internal static let firmwareMissionUpdateFirmwareUpdate = L10n.tr("Localizable", "firmware_mission_update_firmware_update")
  /// Firmware versions
  internal static let firmwareMissionUpdateFirmwareVersionPlural = L10n.tr("Localizable", "firmware_mission_update_firmware_version_plural")
  /// Firmware version
  internal static let firmwareMissionUpdateFirmwareVersionSingular = L10n.tr("Localizable", "firmware_mission_update_firmware_version_singular")
  /// Install all
  internal static let firmwareMissionUpdateInstallAll = L10n.tr("Localizable", "firmware_mission_update_install_all")
  /// Install %@
  internal static func firmwareMissionUpdateInstallOne(_ p1: Any) -> String {
    return L10n.tr("Localizable", "firmware_mission_update_install_one", String(describing: p1))
  }
  /// The battery level of your drone is below %@. This is too weak to safely perform the update.\nDo you want to upload the missions to the drone anyway?
  internal static func firmwareMissionUpdateInsufficientBatteryDescription(_ p1: Any) -> String {
    return L10n.tr("Localizable", "firmware_mission_update_insufficient_battery_description", String(describing: p1))
  }
  /// Not installed
  internal static let firmwareMissionUpdateMissionNotInstalled = L10n.tr("Localizable", "firmware_mission_update_mission_not_installed")
  /// Upload missions
  internal static let firmwareMissionUpdateMissionUploadMissions = L10n.tr("Localizable", "firmware_mission_update_mission_upload_missions")
  /// Missions
  internal static let firmwareMissionUpdateMissions = L10n.tr("Localizable", "firmware_mission_update_missions")
  /// %d file(s)
  internal static func firmwareMissionUpdateNumberOfFile(_ p1: Int) -> String {
    return L10n.tr("Localizable", "firmware_mission_update_number_of_file", p1)
  }
  /// %d files
  internal static func firmwareMissionUpdateNumberOfFilePlural(_ p1: Int) -> String {
    return L10n.tr("Localizable", "firmware_mission_update_number_of_file_plural", p1)
  }
  /// %d file
  internal static func firmwareMissionUpdateNumberOfFileSingular(_ p1: Int) -> String {
    return L10n.tr("Localizable", "firmware_mission_update_number_of_file_singular", p1)
  }
  /// cancelled
  internal static let firmwareMissionUpdateOperationCancel = L10n.tr("Localizable", "firmware_mission_update_operation_cancel")
  /// bad file format
  internal static let firmwareMissionUpdateOperationFailedBadFileFormat = L10n.tr("Localizable", "firmware_mission_update_operation_failed_bad_file_format")
  /// never started
  internal static let firmwareMissionUpdateOperationFailedNeverStarted = L10n.tr("Localizable", "firmware_mission_update_operation_failed_never_started")
  /// unknown reason
  internal static let firmwareMissionUpdateOperationFailedUnknownReason = L10n.tr("Localizable", "firmware_mission_update_operation_failed_unknown_reason")
  /// Some installations failed:
  internal static let firmwareMissionUpdateProcessesFailed = L10n.tr("Localizable", "firmware_mission_update_processes_failed")
  /// Installation successfully executed
  internal static let firmwareMissionUpdateProcessesSucceeded = L10n.tr("Localizable", "firmware_mission_update_processes_succeeded")
  /// Keep updating
  internal static let firmwareMissionUpdateQuitInstallationCancelAction = L10n.tr("Localizable", "firmware_mission_update_quit_installation_cancel_action")
  /// Your controller is currently being updated, are you sure you want to quit the procedure?
  internal static let firmwareMissionUpdateQuitInstallationControllerMessage = L10n.tr("Localizable", "firmware_mission_update_quit_installation_controller_message")
  /// Your drone is currently being updated, are you sure you want to quit the procedure?
  internal static let firmwareMissionUpdateQuitInstallationDroneMessage = L10n.tr("Localizable", "firmware_mission_update_quit_installation_drone_message")
  /// Cancel update?
  internal static let firmwareMissionUpdateQuitInstallationTitle = L10n.tr("Localizable", "firmware_mission_update_quit_installation_title")
  /// Quit
  internal static let firmwareMissionUpdateQuitInstallationValidateAction = L10n.tr("Localizable", "firmware_mission_update_quit_installation_validate_action")
  /// Reboot
  internal static let firmwareMissionUpdateReboot = L10n.tr("Localizable", "firmware_mission_update_reboot")
  /// Reboot and update
  internal static let firmwareMissionUpdateRebootAndUpdate = L10n.tr("Localizable", "firmware_mission_update_reboot_and_update")
  /// Sending firmware to the drone
  internal static let firmwareMissionUpdateSendingToDrone = L10n.tr("Localizable", "firmware_mission_update_sending_to_drone")
  /// Sending firmware to the controller
  internal static let firmwareMissionUpdateSendingToRemoteControl = L10n.tr("Localizable", "firmware_mission_update_sending_to_remote_control")
  /// Up to date
  internal static let firmwareMissionUpdateUpToDate = L10n.tr("Localizable", "firmware_mission_update_up_to_date")
  /// Updating firmware
  internal static let firmwareMissionUpdateUpdatingFirmware = L10n.tr("Localizable", "firmware_mission_update_updating_firmware")
  /// Updating %@
  internal static func firmwareMissionUpdateUpdatingMission(_ p1: Any) -> String {
    return L10n.tr("Localizable", "firmware_mission_update_updating_mission", String(describing: p1))
  }
  /// Battery used
  internal static let flightInfoBatteryUsed = L10n.tr("Localizable", "flight_info_battery_used")
  /// Flight time
  internal static let flightInfoFlightTime = L10n.tr("Localizable", "flight_info_flight_time")
  /// Flight name
  internal static let flightInfoName = L10n.tr("Localizable", "flight_info_name")
  /// Total distance
  internal static let flightInfoTotalDistance = L10n.tr("Localizable", "flight_info_total_distance")
  /// Camera unavailable
  internal static let flightPlanAlertCameraUnavailable = L10n.tr("Localizable", "flight_plan_alert_camera_unavailable")
  /// Cannot take off
  internal static let flightPlanAlertCannotTakeOff = L10n.tr("Localizable", "flight_plan_alert_cannot_take_off")
  /// Corrupted Flight Plan file
  internal static let flightPlanAlertCorrupted = L10n.tr("Localizable", "flight_plan_alert_corrupted")
  /// Drone's GPS unavailable
  internal static let flightPlanAlertDroneGpsKo = L10n.tr("Localizable", "flight_plan_alert_drone_gps_ko")
  /// Magnetic perturbations
  internal static let flightPlanAlertDroneMagnetometerKo = L10n.tr("Localizable", "flight_plan_alert_drone_magnetometer_ko")
  /// Flight Plan error
  internal static let flightPlanAlertError = L10n.tr("Localizable", "flight_plan_alert_error")
  /// Insufficient battery
  internal static let flightPlanAlertInsufficientBattery = L10n.tr("Localizable", "flight_plan_alert_insufficient_battery")
  /// Insufficient space on SD
  internal static let flightPlanAlertInsufficientMemory = L10n.tr("Localizable", "flight_plan_alert_insufficient_memory")
  /// Stopped at %@
  internal static func flightPlanAlertStoppedAt(_ p1: Any) -> String {
    return L10n.tr("Localizable", "flight_plan_alert_stopped_at", String(describing: p1))
  }
  /// Create your first flight plan.
  internal static let flightPlanCreateFirst = L10n.tr("Localizable", "flight_plan_create_first")
  /// Current project
  internal static let flightPlanCurrent = L10n.tr("Localizable", "flight_plan_current")
  /// New project (%d)
  internal static func flightPlanDefaultNewProject(_ p1: Int) -> String {
    return L10n.tr("Localizable", "flight_plan_default_new_project", p1)
  }
  /// Flight Plan (%d)
  internal static func flightPlanDefaultTitle(_ p1: Int) -> String {
    return L10n.tr("Localizable", "flight_plan_default_title", p1)
  }
  /// Delete %@ ?
  internal static func flightPlanDelete(_ p1: Any) -> String {
    return L10n.tr("Localizable", "flight_plan_delete", String(describing: p1))
  }
  /// You are about to delete this %@ locally and on the cloud.\nDo you wish to continue ?
  internal static func flightPlanDeleteDescription(_ p1: Any) -> String {
    return L10n.tr("Localizable", "flight_plan_delete_description", String(describing: p1))
  }
  /// Duplicate
  internal static let flightPlanDuplicate = L10n.tr("Localizable", "flight_plan_duplicate")
  /// As you are connected, all plans and flights will be saved in Parrot Cloud
  internal static let flightPlanEmptyListDesc = L10n.tr("Localizable", "flight_plan_empty_list_desc")
  /// No plan for the moment
  internal static let flightPlanEmptyListTitle = L10n.tr("Localizable", "flight_plan_empty_list_title")
  /// Estimations
  internal static let flightPlanEstimations = L10n.tr("Localizable", "flight_plan_estimations")
  /// %d executed flights
  internal static func flightPlanExecutedFlightPlural(_ p1: Int) -> String {
    return L10n.tr("Localizable", "flight_plan_executed_flight_plural", p1)
  }
  /// %d executed flight
  internal static func flightPlanExecutedFlightSingular(_ p1: Int) -> String {
    return L10n.tr("Localizable", "flight_plan_executed_flight_singular", p1)
  }
  /// %d executions
  internal static func flightPlanExecutionPlural(_ p1: Int) -> String {
    return L10n.tr("Localizable", "flight_plan_execution_plural", p1)
  }
  /// %d execution
  internal static func flightPlanExecutionSingular(_ p1: Int) -> String {
    return L10n.tr("Localizable", "flight_plan_execution_singular", p1)
  }
  /// History
  internal static let flightPlanHistory = L10n.tr("Localizable", "flight_plan_history")
  /// Drone ready
  internal static let flightPlanInfoDroneReady = L10n.tr("Localizable", "flight_plan_info_drone_ready")
  /// Uploading…
  internal static let flightPlanInfoUploading = L10n.tr("Localizable", "flight_plan_info_uploading")
  /// Interpolation
  internal static let flightPlanInterpolationSettingsTitle = L10n.tr("Localizable", "flight_plan_interpolation_settings_title")
  /// Image parameters
  internal static let flightPlanMenuImage = L10n.tr("Localizable", "flight_plan_menu_image")
  /// Project
  internal static let flightPlanMenuProject = L10n.tr("Localizable", "flight_plan_menu_project")
  /// New
  internal static let flightPlanNew = L10n.tr("Localizable", "flight_plan_new")
  /// New Flight Plan
  internal static let flightPlanNewFlightPlan = L10n.tr("Localizable", "flight_plan_new_flight_plan")
  /// New project
  internal static let flightPlanNewProject = L10n.tr("Localizable", "flight_plan_new_project")
  /// This plan has never been executed
  internal static let flightPlanNoExecuted = L10n.tr("Localizable", "flight_plan_no_executed")
  /// Open Flight Plan
  internal static let flightPlanOpen = L10n.tr("Localizable", "flight_plan_open")
  /// Open
  internal static let flightPlanOpenLabel = L10n.tr("Localizable", "flight_plan_open_label")
  /// Open project
  internal static let flightPlanOpenProject = L10n.tr("Localizable", "flight_plan_open_project")
  /// Open recent project
  internal static let flightPlanOpenRecent = L10n.tr("Localizable", "flight_plan_open_recent")
  /// Altitude
  internal static let flightPlanPointSettingsAltitude = L10n.tr("Localizable", "flight_plan_point_settings_altitude")
  /// Camera angle
  internal static let flightPlanPointSettingsCameraAngle = L10n.tr("Localizable", "flight_plan_point_settings_camera_angle")
  /// Point
  internal static let flightPlanPointSettingsTitle = L10n.tr("Localizable", "flight_plan_point_settings_title")
  /// Type
  internal static let flightPlanPointSettingsType = L10n.tr("Localizable", "flight_plan_point_settings_type")
  /// Project
  internal static let flightPlanProject = L10n.tr("Localizable", "flight_plan_project")
  /// Project name
  internal static let flightPlanProjectName = L10n.tr("Localizable", "flight_plan_project_name")
  /// Projects
  internal static let flightPlanProjects = L10n.tr("Localizable", "flight_plan_projects")
  /// Completed
  internal static let flightPlanRunCompleted = L10n.tr("Localizable", "flight_plan_run_completed")
  /// Failed
  internal static let flightPlanRunFailed = L10n.tr("Localizable", "flight_plan_run_failed")
  /// Resume
  internal static let flightPlanRunResume = L10n.tr("Localizable", "flight_plan_run_resume")
  /// Running…
  internal static let flightPlanRunRunning = L10n.tr("Localizable", "flight_plan_run_running")
  /// Stopped
  internal static let flightPlanRunStopped = L10n.tr("Localizable", "flight_plan_run_stopped")
  /// See all
  internal static let flightPlanSeeAll = L10n.tr("Localizable", "flight_plan_see_all")
  /// Segment
  internal static let flightPlanSegmentSettingsTitle = L10n.tr("Localizable", "flight_plan_segment_settings_title")
  /// Obstacle avoidance
  internal static let flightPlanSettingsAvoidance = L10n.tr("Localizable", "flight_plan_settings_avoidance")
  /// Avoidance
  internal static let flightPlanSettingsAvoidanceShort = L10n.tr("Localizable", "flight_plan_settings_avoidance_short")
  /// Exposure
  internal static let flightPlanSettingsExposure = L10n.tr("Localizable", "flight_plan_settings_exposure")
  /// Framerate
  internal static let flightPlanSettingsFramerate = L10n.tr("Localizable", "flight_plan_settings_framerate")
  /// Global
  internal static let flightPlanSettingsGlobal = L10n.tr("Localizable", "flight_plan_settings_global")
  /// Last waypoint
  internal static let flightPlanSettingsLastWaypoint = L10n.tr("Localizable", "flight_plan_settings_last_waypoint")
  /// Last WP
  internal static let flightPlanSettingsLastWp = L10n.tr("Localizable", "flight_plan_settings_last_wp")
  /// Automatic progressive race
  internal static let flightPlanSettingsProgressiveRace = L10n.tr("Localizable", "flight_plan_settings_progressive_race")
  /// Progressive race
  internal static let flightPlanSettingsProgressiveRaceLabel = L10n.tr("Localizable", "flight_plan_settings_progressive_race_label")
  /// Progressive race
  internal static let flightPlanSettingsProgressiveRaceShort = L10n.tr("Localizable", "flight_plan_settings_progressive_race_short")
  /// Resolution
  internal static let flightPlanSettingsResolution = L10n.tr("Localizable", "flight_plan_settings_resolution")
  /// RTH
  internal static let flightPlanSettingsRthOnLastPoint = L10n.tr("Localizable", "flight_plan_settings_rth_on_last_point")
  /// RTH
  internal static let flightPlanSettingsRthOnLastPointShort = L10n.tr("Localizable", "flight_plan_settings_rth_on_last_point_short")
  /// Flight parameters
  internal static let flightPlanSettingsTitle = L10n.tr("Localizable", "flight_plan_settings_title")
  /// White balance
  internal static let flightPlanSettingsWhiteBalance = L10n.tr("Localizable", "flight_plan_settings_white_balance")
  /// flight plan
  internal static let flightPlanTitle = L10n.tr("Localizable", "flight_plan_title")
  /// Get Support
  internal static let flightReportGetSupport = L10n.tr("Localizable", "flight_report_get_support")
  /// Flight report
  internal static let flightReportTitle = L10n.tr("Localizable", "flight_report_title")
  /// Bracketing
  internal static let galleryBracketingPathComponent = L10n.tr("Localizable", "gallery_bracketing_path_component")
  /// Burst
  internal static let galleryBurstPathComponent = L10n.tr("Localizable", "gallery_burst_path_component")
  /// Are you sure you want to delete this media from %@ ?
  internal static func galleryConfirmDelete(_ p1: Any) -> String {
    return L10n.tr("Localizable", "gallery_confirm_delete", String(describing: p1))
  }
  /// DNG
  internal static let galleryDngPathComponent = L10n.tr("Localizable", "gallery_dng_path_component")
  /// Download complete
  internal static let galleryDownloadComplete = L10n.tr("Localizable", "gallery_download_complete")
  /// Do you want to keep original file?
  internal static let galleryDownloadKeep = L10n.tr("Localizable", "gallery_download_keep")
  /// Do you want to keep original files?
  internal static let galleryDownloadKeepPlural = L10n.tr("Localizable", "gallery_download_keep_plural")
  /// Format SD Card
  internal static let galleryFormat = L10n.tr("Localizable", "gallery_format")
  /// Formatting complete
  internal static let galleryFormatComplete = L10n.tr("Localizable", "gallery_format_complete")
  /// Creating new partition
  internal static let galleryFormatCreatingPartition = L10n.tr("Localizable", "gallery_format_creating_partition")
  /// All datas will be erased
  internal static let galleryFormatDataErased = L10n.tr("Localizable", "gallery_format_data_erased")
  /// Erasing partition
  internal static let galleryFormatErasingPartition = L10n.tr("Localizable", "gallery_format_erasing_partition")
  /// Formatting
  internal static let galleryFormatFormatting = L10n.tr("Localizable", "gallery_format_formatting")
  /// Full
  internal static let galleryFormatFull = L10n.tr("Localizable", "gallery_format_full")
  /// Quick
  internal static let galleryFormatQuick = L10n.tr("Localizable", "gallery_format_quick")
  /// Recommended
  internal static let galleryFormatRecommended = L10n.tr("Localizable", "gallery_format_recommended")
  /// Resetting SD memory
  internal static let galleryFormatResetting = L10n.tr("Localizable", "gallery_format_resetting")
  /// Format SD
  internal static let galleryFormatSdCard = L10n.tr("Localizable", "gallery_format_sd_card")
  /// Format succeeded
  internal static let galleryFormatSucceeded = L10n.tr("Localizable", "gallery_format_succeeded")
  /// If writing problems
  internal static let galleryFormatWritingProblems = L10n.tr("Localizable", "gallery_format_writing_problems")
  /// Generating panorama
  internal static let galleryGeneratingPanorama = L10n.tr("Localizable", "gallery_generating_panorama")
  /// GPSLaspe
  internal static let galleryGpslapsePathComponent = L10n.tr("Localizable", "gallery_gpslapse_path_component")
  /// PanoramaHorizontal
  internal static let galleryHorizontalPathComponent = L10n.tr("Localizable", "gallery_horizontal_path_component")
  /// Please land the drone
  internal static let galleryMediaFormatSdCardLandDrone = L10n.tr("Localizable", "gallery_media_format_sd_card_land_drone")
  /// Please land the drone to format SD card
  internal static let galleryMediaFormatSdCardLandDroneInstructions = L10n.tr("Localizable", "gallery_media_format_sd_card_land_drone_instructions")
  /// Selected
  internal static let galleryMediaSelected = L10n.tr("Localizable", "gallery_media_selected")
  /// Please land the drone to replay this video
  internal static let galleryMediaVideoLandDrone = L10n.tr("Localizable", "gallery_media_video_land_drone")
  /// GB free
  internal static let galleryMemoryFree = L10n.tr("Localizable", "gallery_memory_free")
  /// GB
  internal static let galleryMemoryFreeCompact = L10n.tr("Localizable", "gallery_memory_free_compact")
  /// No media
  internal static let galleryNoMedia = L10n.tr("Localizable", "gallery_no_media")
  /// We need to download files before generating the panorama
  internal static let galleryPanoramaDownloadWarning = L10n.tr("Localizable", "gallery_panorama_download_warning")
  /// Downloading files
  internal static let galleryPanoramaDownloadingFiles = L10n.tr("Localizable", "gallery_panorama_downloading_files")
  /// Fast generation
  internal static let galleryPanoramaFastGeneration = L10n.tr("Localizable", "gallery_panorama_fast_generation")
  /// Generate
  internal static let galleryPanoramaGenerate = L10n.tr("Localizable", "gallery_panorama_generate")
  /// What do you want to generate?
  internal static let galleryPanoramaGenerateQuestion = L10n.tr("Localizable", "gallery_panorama_generate_question")
  /// Generating custom
  internal static let galleryPanoramaGeneratingCustom = L10n.tr("Localizable", "gallery_panorama_generating_custom")
  /// Generating horizontal
  internal static let galleryPanoramaGeneratingHorizontal = L10n.tr("Localizable", "gallery_panorama_generating_horizontal")
  /// Generating sphere
  internal static let galleryPanoramaGeneratingSphere = L10n.tr("Localizable", "gallery_panorama_generating_sphere")
  /// Generating superwide
  internal static let galleryPanoramaGeneratingSuperwide = L10n.tr("Localizable", "gallery_panorama_generating_superwide")
  /// Generating tiny planet
  internal static let galleryPanoramaGeneratingTinyPlanet = L10n.tr("Localizable", "gallery_panorama_generating_tiny_planet")
  /// Generating tunnel
  internal static let galleryPanoramaGeneratingTunnel = L10n.tr("Localizable", "gallery_panorama_generating_tunnel")
  /// Generating vertical
  internal static let galleryPanoramaGeneratingVertical = L10n.tr("Localizable", "gallery_panorama_generating_vertical")
  /// High quality
  internal static let galleryPanoramaHighQuality = L10n.tr("Localizable", "gallery_panorama_high_quality")
  /// Not available for your device
  internal static let galleryPanoramaNotAvailable = L10n.tr("Localizable", "gallery_panorama_not_available")
  /// Sphere
  internal static let galleryPanoramaSphere = L10n.tr("Localizable", "gallery_panorama_sphere")
  /// Tiny planet
  internal static let galleryPanoramaTinyPlanet = L10n.tr("Localizable", "gallery_panorama_tiny_planet")
  /// Tunnel
  internal static let galleryPanoramaTunnel = L10n.tr("Localizable", "gallery_panorama_tunnel")
  /// Photo
  internal static let galleryPhotoPathComponent = L10n.tr("Localizable", "gallery_photo_path_component")
  /// Are you sure you want to delete this file from the SD card?
  internal static let galleryRemoveSdConfirm = L10n.tr("Localizable", "gallery_remove_sd_confirm")
  /// Cloud
  internal static let gallerySourceCloud = L10n.tr("Localizable", "gallery_source_cloud")
  /// Internal
  internal static let gallerySourceDroneInternal = L10n.tr("Localizable", "gallery_source_drone_internal")
  /// SD Card
  internal static let gallerySourceDroneSd = L10n.tr("Localizable", "gallery_source_drone_sd")
  /// Phone
  internal static let gallerySourceMobile = L10n.tr("Localizable", "gallery_source_mobile")
  /// PanoramaSpherical
  internal static let gallerySphericalPathComponent = L10n.tr("Localizable", "gallery_spherical_path_component")
  /// PanoramaSuperWide
  internal static let gallerySuperwidePathComponent = L10n.tr("Localizable", "gallery_superwide_path_component")
  /// TimeLapse
  internal static let galleryTimelapsePathComponent = L10n.tr("Localizable", "gallery_timelapse_path_component")
  /// Gallery
  internal static let galleryTitle = L10n.tr("Localizable", "gallery_title")
  /// PanoramaVertical
  internal static let galleryVerticalPathComponent = L10n.tr("Localizable", "gallery_vertical_path_component")
  /// Video
  internal static let galleryVideoPathComponent = L10n.tr("Localizable", "gallery_video_path_component")
  /// 8k camera calibration
  internal static let gimbalCalibration8kCameraMessage = L10n.tr("Localizable", "gimbal_calibration_8k_camera_message")
  /// Calibrating…
  internal static let gimbalCalibrationCalibrating = L10n.tr("Localizable", "gimbal_calibration_calibrating")
  /// Place the drone on a plane surface then tap start.
  internal static let gimbalCalibrationDescription = L10n.tr("Localizable", "gimbal_calibration_description")
  /// Gimbal: error
  internal static let gimbalCalibrationError = L10n.tr("Localizable", "gimbal_calibration_error")
  /// Calibration failed. Check that nothing is blocking the gimbal
  internal static let gimbalCalibrationFailed = L10n.tr("Localizable", "gimbal_calibration_failed")
  /// LOVE camera calibration
  internal static let gimbalCalibrationLoveCameraMessage = L10n.tr("Localizable", "gimbal_calibration_love_camera_message")
  /// Calibration succeed!
  internal static let gimbalCalibrationSucceed = L10n.tr("Localizable", "gimbal_calibration_succeed")
  /// Gimbal calibration
  internal static let gimbalCalibrationTitle = L10n.tr("Localizable", "gimbal_calibration_title")
  /// Hello!
  internal static let helloFeedback = L10n.tr("Localizable", "hello_feedback")
  /// Say Hello!
  internal static let helloSayHello = L10n.tr("Localizable", "hello_say_hello")
  /// Add new
  internal static let liveStreamingAddConf = L10n.tr("Localizable", "live_streaming_add_conf")
  /// Connect
  internal static let liveStreamingConnect = L10n.tr("Localizable", "live_streaming_connect")
  /// Encrypted stream
  internal static let liveStreamingEncryptedStream = L10n.tr("Localizable", "live_streaming_encrypted_stream")
  /// Enter URL
  internal static let liveStreamingEnterUrl = L10n.tr("Localizable", "live_streaming_enter_url")
  /// Connection failed. Please chack the URL or try again later.
  internal static let liveStreamingError = L10n.tr("Localizable", "live_streaming_error")
  /// Priority on latency
  internal static let liveStreamingLatencyPriority = L10n.tr("Localizable", "live_streaming_latency_priority")
  /// Live streaming
  internal static let liveStreamingLiveStreaming = L10n.tr("Localizable", "live_streaming_live_streaming")
  /// Priority on quality
  internal static let liveStreamingQualityPriority = L10n.tr("Localizable", "live_streaming_quality_priority")
  /// Lock AE
  internal static let lockAe = L10n.tr("Localizable", "lock_ae")
  /// Reaching %@m
  internal static func loveCalibrationAscending(_ p1: Any) -> String {
    return L10n.tr("Localizable", "love_calibration_ascending", String(describing: p1))
  }
  /// Reaching ground
  internal static let loveCalibrationDescending = L10n.tr("Localizable", "love_calibration_descending")
  /// Finish
  internal static let loveCalibrationFinish = L10n.tr("Localizable", "love_calibration_finish")
  /// Please update the drone before taking off.
  internal static let loveCalibrationFirmware = L10n.tr("Localizable", "love_calibration_firmware")
  /// Drone is currently flying. Please land the drone to start the calibration.
  internal static let loveCalibrationFlying = L10n.tr("Localizable", "love_calibration_flying")
  /// GPS signal too weak to start the calibration.
  internal static let loveCalibrationGps = L10n.tr("Localizable", "love_calibration_gps")
  /// Hold position
  internal static let loveCalibrationHoldPosition = L10n.tr("Localizable", "love_calibration_hold_position")
  /// Hold the Smart Board above the drone with the pattern facing downward
  internal static let loveCalibrationHoldSmartboardMessage = L10n.tr("Localizable", "love_calibration_hold_smartboard_message")
  /// Waiting
  internal static let loveCalibrationIdle = L10n.tr("Localizable", "love_calibration_idle")
  /// Calibration failed
  internal static let loveCalibrationKo = L10n.tr("Localizable", "love_calibration_ko")
  /// Please try again in a different area or with a clear weather. Make sure that the avoidance sensors cameras are clean. 
  internal static let loveCalibrationKoAdvice = L10n.tr("Localizable", "love_calibration_ko_advice")
  /// Move the board around to get started
  internal static let loveCalibrationMoveBoardAround = L10n.tr("Localizable", "love_calibration_move_board_around")
  /// Move the board to fill the empty frame
  internal static let loveCalibrationMoveBoardToFillEmptyFrame = L10n.tr("Localizable", "love_calibration_move_board_to_fill_empty_frame")
  /// Move the board to fill the frame
  internal static let loveCalibrationMoveBoardToFillFrame = L10n.tr("Localizable", "love_calibration_move_board_to_fill_frame")
  /// Calibration completed
  internal static let loveCalibrationOk = L10n.tr("Localizable", "love_calibration_ok")
  /// Please make sure you are in an open area before starting the calibration.
  internal static let loveCalibrationReady = L10n.tr("Localizable", "love_calibration_ready")
  /// required
  internal static let loveCalibrationRequired = L10n.tr("Localizable", "love_calibration_required")
  /// Please, try again
  internal static let loveCalibrationRetry = L10n.tr("Localizable", "love_calibration_retry")
  /// To calibrate the obstacle avoidance sensors, the drone will take off and fly up to 
  internal static let loveCalibrationSetupMessage = L10n.tr("Localizable", "love_calibration_setup_message")
  /// Before you start put your Anafi Ai on a leveled ground
  internal static let loveCalibrationStartMessage = L10n.tr("Localizable", "love_calibration_start_message")
  /// Taking off
  internal static let loveCalibrationTakeoff = L10n.tr("Localizable", "love_calibration_takeoff")
  /// Target partially hidden
  internal static let loveCalibrationTargetPartiallyHidden = L10n.tr("Localizable", "love_calibration_target_partially_hidden")
  /// Executing rotation
  internal static let loveCalibrationTurning = L10n.tr("Localizable", "love_calibration_turning")
  /// Mission
  internal static let mission = L10n.tr("Localizable", "mission")
  /// Please land the drone to enter %@ mission
  internal static func missionAlertEnter(_ p1: Any) -> String {
    return L10n.tr("Localizable", "mission_alert_enter", String(describing: p1))
  }
  /// Please land the drone to stop %@ mission
  internal static func missionAlertExit(_ p1: Any) -> String {
    return L10n.tr("Localizable", "mission_alert_exit", String(describing: p1))
  }
  /// Piloting
  internal static let missionClassic = L10n.tr("Localizable", "mission_classic")
  /// Hello World
  internal static let missionHello = L10n.tr("Localizable", "mission_hello")
  /// Manual
  internal static let missionModeManual = L10n.tr("Localizable", "mission_mode_manual")
  /// Missions
  internal static let missionSelectLabel = L10n.tr("Localizable", "mission_select_label")
  /// Ok
  internal static let ok = L10n.tr("Localizable", "ok")
  /// Connect automaticaly to drone’s Wi-Fi
  internal static let pairingConnectAutomaticalyDroneWifi = L10n.tr("Localizable", "pairing_connect_automaticaly_drone_wifi")
  /// Connect to the controller
  internal static let pairingConnectToTheController = L10n.tr("Localizable", "pairing_connect_to_the_controller")
  /// Controller not recognized?
  internal static let pairingControllerNotRecognized = L10n.tr("Localizable", "pairing_controller_not_recognized")
  /// Connect to the drone’s Wi-Fi
  internal static let pairingDroneConnectToWifi = L10n.tr("Localizable", "pairing_drone_connect_to_wifi")
  /// Go to iPhone's settings
  internal static let pairingDroneGoToWifiSettings = L10n.tr("Localizable", "pairing_drone_go_to_wifi_settings")
  /// Drone not detected?
  internal static let pairingDroneNotDetected = L10n.tr("Localizable", "pairing_drone_not_detected")
  /// Show available Wi-Fis
  internal static let pairingDroneShowAvailableWifi = L10n.tr("Localizable", "pairing_drone_show_available_wifi")
  /// Waiting for drone connection
  internal static let pairingDroneWaitingConnection = L10n.tr("Localizable", "pairing_drone_waiting_connection")
  /// Where is the drone's Wi-Fi password ?
  internal static let pairingDroneWhereIsWifiPassword = L10n.tr("Localizable", "pairing_drone_where_is_wifi_password")
  /// Enter Wi-Fi password
  internal static let pairingEnterWifiPassword = L10n.tr("Localizable", "pairing_enter_wifi_password")
  /// How to connect to a drone ?
  internal static let pairingHowToConnectDroneTitle = L10n.tr("Localizable", "pairing_how_to_connect_drone_title")
  /// How to connect to the controller ?
  internal static let pairingHowToConnectRemote = L10n.tr("Localizable", "pairing_how_to_connect_remote")
  /// How to connect ?
  internal static let pairingHowToConnectTitle = L10n.tr("Localizable", "pairing_how_to_connect_title")
  /// Looking for a drone
  internal static let pairingLookingForDrone = L10n.tr("Localizable", "pairing_looking_for_drone")
  /// 2. Make sure the controller's battery is charged.
  internal static let pairingMakeSureBatteryCharged = L10n.tr("Localizable", "pairing_make_sure_battery_charged")
  /// By plugging USB cable from remote controller to drone, you will pair them automatically.
  internal static let pairingPairAutomaticallyWithUsb = L10n.tr("Localizable", "pairing_pair_automatically_with_usb")
  /// If you are not able to use this method, you can enter manually the Wi-Fi password.
  internal static let pairingPairManuallyWithPassword = L10n.tr("Localizable", "pairing_pair_manually_with_password")
  /// Pilot !
  internal static let pairingPilot = L10n.tr("Localizable", "pairing_pilot")
  /// 1. Try unplugging and plugging again the USB cable.
  internal static let pairingPlugUsbCable = L10n.tr("Localizable", "pairing_plug_usb_cable")
  /// Refresh list
  internal static let pairingRefreshDroneList = L10n.tr("Localizable", "pairing_refresh_drone_list")
  /// Connect
  internal static let pairingRemoteDroneConnect = L10n.tr("Localizable", "pairing_remote_drone_connect")
  /// Connect to %@
  internal static func pairingRemoteDroneConnectTo(_ p1: Any) -> String {
    return L10n.tr("Localizable", "pairing_remote_drone_connect_to", String(describing: p1))
  }
  /// Failed to connect to the drone
  internal static let pairingRemoteDroneFailedConnectDrone = L10n.tr("Localizable", "pairing_remote_drone_failed_connect_drone")
  /// If you have forgot the drone’s Wifi password, you can reinitiate it by making a long press on the  power button. The initial password can be found under the drone’s battery.
  internal static let pairingRemoteDroneForgotPassword = L10n.tr("Localizable", "pairing_remote_drone_forgot_password")
  /// Failed to connect: password incorrect
  internal static let pairingRemoteDronePasswordIncorrect = L10n.tr("Localizable", "pairing_remote_drone_password_incorrect")
  /// Scan the QR code in the box to connect automatically to the drone. The drone's Wi-Fi password can be found in the box
  internal static let pairingScanQrCode = L10n.tr("Localizable", "pairing_scan_qr_code")
  /// Searching for a drone
  internal static let pairingSearchingForADrone = L10n.tr("Localizable", "pairing_searching_for_a_drone")
  /// Select your drone
  internal static let pairingSelectYourDrone = L10n.tr("Localizable", "pairing_select_your_drone")
  /// 3. Try using a different cable.
  internal static let pairingTryDifferentCable = L10n.tr("Localizable", "pairing_try_different_cable")
  /// Turn on the drone
  internal static let pairingTurnOnDrone = L10n.tr("Localizable", "pairing_turn_on_drone")
  /// Where is the Wi-Fi password?
  internal static let pairingWhereIsWifiPassword = L10n.tr("Localizable", "pairing_where_is_wifi_password")
  /// I have a controller
  internal static let pairingWithController = L10n.tr("Localizable", "pairing_with_controller")
  /// I don't have a controller
  internal static let pairingWithoutController = L10n.tr("Localizable", "pairing_without_controller")
  /// Share your device GPS location to improve your flight experience and enable autonomous flights features.
  internal static let permissionGpsPositionContent = L10n.tr("Localizable", "permission_gps_position_content")
  ///  GPS position
  internal static let permissionGpsPositionTitle = L10n.tr("Localizable", "permission_gps_position_title")
  /// Recommended
  internal static let permissionLevelRecommended = L10n.tr("Localizable", "permission_level_recommended")
  /// Required
  internal static let permissionLevelRequired = L10n.tr("Localizable", "permission_level_required")
  /// Allow access to your device storage to store media the gallery, or to import Flight Plan.
  internal static let permissionStorageContent = L10n.tr("Localizable", "permission_storage_content")
  /// Device storage
  internal static let permissionStorageTitle = L10n.tr("Localizable", "permission_storage_title")
  /// DNG+JPEG WIDE
  internal static let photoSettingsFormatDngJpeg = L10n.tr("Localizable", "photo_settings_format_dng_jpeg")
  /// DNG+JPEG RECT
  internal static let photoSettingsFormatDngJpegRect = L10n.tr("Localizable", "photo_settings_format_dng_jpeg_rect")
  /// JPEG RECT
  internal static let photoSettingsFormatJpegRect = L10n.tr("Localizable", "photo_settings_format_jpeg_rect")
  /// JPEG WIDE
  internal static let photoSettingsFormatJpegWide = L10n.tr("Localizable", "photo_settings_format_jpeg_wide")
  /// PIN incorrect. The SIM card is blocked.
  internal static let pinErrorLocked = L10n.tr("Localizable", "pin_error_locked")
  /// PIN incorrect. %d attemps remaining.
  internal static func pinErrorRemainingAttemptsPlural(_ p1: Int) -> String {
    return L10n.tr("Localizable", "pin_error_remaining_attempts_plural", p1)
  }
  /// PIN incorrect. %d attempt remaining.
  internal static func pinErrorRemainingAttemptsSingular(_ p1: Int) -> String {
    return L10n.tr("Localizable", "pin_error_remaining_attempts_singular", p1)
  }
  /// SIM card PIN
  internal static let pinModalSimCardPin = L10n.tr("Localizable", "pin_modal_sim_card_pin")
  /// Unlocking…
  internal static let pinModalUnlocking = L10n.tr("Localizable", "pin_modal_unlocking")
  /// Precise home set
  internal static let preciseHome = L10n.tr("Localizable", "precise_home")
  /// Precise landing
  internal static let preciseLanding = L10n.tr("Localizable", "precise_landing")
  /// Precise RTH
  internal static let preciseRth = L10n.tr("Localizable", "precise_rth")
  /// Switching the controller off...
  internal static let remoteAlertShutdownInstruction = L10n.tr("Localizable", "remote_alert_shutdown_instruction")
  /// The controller has been switched off
  internal static let remoteAlertShutdownSuccess = L10n.tr("Localizable", "remote_alert_shutdown_success")
  /// Calibrate
  internal static let remoteCalibrationCalibrate = L10n.tr("Localizable", "remote_calibration_calibrate")
  /// Please reproduce this movement with your controller.
  internal static let remoteCalibrationDescription = L10n.tr("Localizable", "remote_calibration_description")
  /// Axe Y (pitch)
  internal static let remoteCalibrationPitchAxe = L10n.tr("Localizable", "remote_calibration_pitch_axe")
  /// Ready to fly
  internal static let remoteCalibrationReadyToFly = L10n.tr("Localizable", "remote_calibration_ready_to_fly")
  /// Calibration required
  internal static let remoteCalibrationRequired = L10n.tr("Localizable", "remote_calibration_required")
  /// Axe X (roll)
  internal static let remoteCalibrationRollAxe = L10n.tr("Localizable", "remote_calibration_roll_axe")
  /// Magnetometer calibration
  internal static let remoteCalibrationTitle = L10n.tr("Localizable", "remote_calibration_title")
  /// Axe Z (yaw)
  internal static let remoteCalibrationYawAxe = L10n.tr("Localizable", "remote_calibration_yaw_axe")
  /// Calibration
  internal static let remoteDetailsCalibration = L10n.tr("Localizable", "remote_details_calibration")
  /// Connect to a drone
  internal static let remoteDetailsConnectToADrone = L10n.tr("Localizable", "remote_details_connect_to_a_drone")
  /// Controller's information
  internal static let remoteDetailsControllerInfos = L10n.tr("Localizable", "remote_details_controller_infos")
  /// Hardware
  internal static let remoteDetailsHardware = L10n.tr("Localizable", "remote_details_hardware")
  /// Model
  internal static let remoteDetailsModel = L10n.tr("Localizable", "remote_details_model")
  /// Reinitiate
  internal static let remoteDetailsReset = L10n.tr("Localizable", "remote_details_reset")
  /// Reinitiating your controller will erase the list of associated drones. Are you sure you want to continue ?
  internal static let remoteDetailsResetDescription = L10n.tr("Localizable", "remote_details_reset_description")
  /// Controller reset
  internal static let remoteDetailsResetTitle = L10n.tr("Localizable", "remote_details_reset_title")
  /// Serial number
  internal static let remoteDetailsSerialNumber = L10n.tr("Localizable", "remote_details_serial_number")
  /// Software
  internal static let remoteDetailsSoftware = L10n.tr("Localizable", "remote_details_software")
  /// up to date
  internal static let remoteDetailsUpToDate = L10n.tr("Localizable", "remote_details_up_to_date")
  /// In order to optimize your flight experience, we will update your Parrot Skycontroller 4.
  internal static let remoteUpdateConfirmDescription = L10n.tr("Localizable", "remote_update_confirm_description")
  /// Controller update
  internal static let remoteUpdateControllerUpdate = L10n.tr("Localizable", "remote_update_controller_update")
  /// This operation takes a few minutes
  internal static let remoteUpdateDescription = L10n.tr("Localizable", "remote_update_description")
  /// Software download
  internal static let remoteUpdateDownloadStep = L10n.tr("Localizable", "remote_update_download_step")
  /// The battery level of your controller is below %@. This is too weak to safely perform the update.
  internal static func remoteUpdateInsufficientBatteryDescription(_ p1: Any) -> String {
    return L10n.tr("Localizable", "remote_update_insufficient_battery_description", String(describing: p1))
  }
  /// Insufficient controller’s battery
  internal static let remoteUpdateInsufficientBatteryTitle = L10n.tr("Localizable", "remote_update_insufficient_battery_title")
  /// You need an internet connection to download the controller’s firmware. Please check your connection or try again later.
  internal static let remoteUpdateInternetUnreachableDescription = L10n.tr("Localizable", "remote_update_internet_unreachable_description")
  /// Update and reboot
  internal static let remoteUpdateRebootStep = L10n.tr("Localizable", "remote_update_reboot_step")
  /// Your controller is currently being updated, this operation can not be cancelled. You can leave the screen, the controller will finish updating.
  internal static let remoteUpdateRebootingError = L10n.tr("Localizable", "remote_update_rebooting_error")
  /// Sending to Skycontroller
  internal static let remoteUpdateSendingStep = L10n.tr("Localizable", "remote_update_sending_step")
  /// RTH position set
  internal static let rthPositionSet = L10n.tr("Localizable", "rth_position_set")
  /// Calibration completed
  internal static let sensorCalibrationCompleted = L10n.tr("Localizable", "sensor_calibration_completed")
  /// Calibration failed
  internal static let sensorCalibrationFailed = L10n.tr("Localizable", "sensor_calibration_failed")
  /// Fill the frame
  internal static let sensorCalibrationFillFrame = L10n.tr("Localizable", "sensor_calibration_fill_frame")
  /// Hold
  internal static let sensorCalibrationHold = L10n.tr("Localizable", "sensor_calibration_hold")
  /// Move the board down
  internal static let sensorCalibrationMoveDown = L10n.tr("Localizable", "sensor_calibration_move_down")
  /// Move the board to the left
  internal static let sensorCalibrationMoveLeft = L10n.tr("Localizable", "sensor_calibration_move_left")
  /// Move the board to the right
  internal static let sensorCalibrationMoveRight = L10n.tr("Localizable", "sensor_calibration_move_right")
  /// Move the board up
  internal static let sensorCalibrationMoveUp = L10n.tr("Localizable", "sensor_calibration_move_up")
  /// Board out of frame
  internal static let sensorCalibrationOutFrame = L10n.tr("Localizable", "sensor_calibration_out_frame")
  /// Rotate the board to the left
  internal static let sensorCalibrationRotateLeft = L10n.tr("Localizable", "sensor_calibration_rotate_left")
  /// Rotate the board to the right
  internal static let sensorCalibrationRotateRight = L10n.tr("Localizable", "sensor_calibration_rotate_right")
  /// Place the aim in the circle
  internal static let sensorCalibrationTiltBackwards = L10n.tr("Localizable", "sensor_calibration_tilt_backwards")
  /// Place the aim in the circle
  internal static let sensorCalibrationTiltLeft = L10n.tr("Localizable", "sensor_calibration_tilt_left")
  /// Place the aim in the circle
  internal static let sensorCalibrationTiltRight = L10n.tr("Localizable", "sensor_calibration_tilt_right")
  /// Place the aim in the circle
  internal static let sensorCalibrationTiltTowards = L10n.tr("Localizable", "sensor_calibration_tilt_towards")
  /// Move the board away from the drone
  internal static let sensorCalibrationTooClose = L10n.tr("Localizable", "sensor_calibration_too_close")
  /// Bring the board toward the drone
  internal static let sensorCalibrationTooFar = L10n.tr("Localizable", "sensor_calibration_too_far")
  /// Place the drone and device on a flat surface
  internal static let sensorCalibrationTutorialDesc1 = L10n.tr("Localizable", "sensor_calibration_tutorial_desc_1")
  /// Hold the calibration board facing the drone
  internal static let sensorCalibrationTutorialDesc2 = L10n.tr("Localizable", "sensor_calibration_tutorial_desc_2")
  /// Move the calibration board to fill the frame displayed on the device
  internal static let sensorCalibrationTutorialDesc3 = L10n.tr("Localizable", "sensor_calibration_tutorial_desc_3")
  /// I’m ready
  internal static let sensorCalibrationTutorialReady = L10n.tr("Localizable", "sensor_calibration_tutorial_ready")
  /// Sensors calibration
  internal static let sensorCalibrationTutorialTitle = L10n.tr("Localizable", "sensor_calibration_tutorial_title")
  /// Behaviour
  internal static let settingsAdvancedCategoryBehaviour = L10n.tr("Localizable", "settings_advanced_category_behaviour")
  /// Recording
  internal static let settingsAdvancedCategoryCamera = L10n.tr("Localizable", "settings_advanced_category_camera")
  /// Connection
  internal static let settingsAdvancedCategoryConnection = L10n.tr("Localizable", "settings_advanced_category_connection")
  /// Geocage
  internal static let settingsAdvancedCategoryGeofence = L10n.tr("Localizable", "settings_advanced_category_geofence")
  /// Interface
  internal static let settingsAdvancedCategoryInterface = L10n.tr("Localizable", "settings_advanced_category_interface")
  /// RTH
  internal static let settingsAdvancedCategoryRth = L10n.tr("Localizable", "settings_advanced_category_rth")
  /// Banked turn
  internal static let settingsBehaviourBankedTurn = L10n.tr("Localizable", "settings_behaviour_banked_turn")
  /// Horizon
  internal static let settingsBehaviourCameraStabilization = L10n.tr("Localizable", "settings_behaviour_camera_stabilization")
  /// Fixed
  internal static let settingsBehaviourCameraStabilizationLocked = L10n.tr("Localizable", "settings_behaviour_camera_stabilization_locked")
  /// Dynamic
  internal static let settingsBehaviourCameraStabilizationRelative = L10n.tr("Localizable", "settings_behaviour_camera_stabilization_relative")
  /// Camera tilt speed
  internal static let settingsBehaviourCameraTilt = L10n.tr("Localizable", "settings_behaviour_camera_tilt")
  /// Cinematic
  internal static let settingsBehaviourCinematic = L10n.tr("Localizable", "settings_behaviour_cinematic")
  /// Info : Banked turn
  internal static let settingsBehaviourInfosBankedTurn = L10n.tr("Localizable", "settings_behaviour_infos_banked_turn")
  /// The drone will make a turn if it’s moving forward and rotating simultaneously
  internal static let settingsBehaviourInfosBankedTurnDescription = L10n.tr("Localizable", "settings_behaviour_infos_banked_turn_description")
  /// Info : Horizon line
  internal static let settingsBehaviourInfosHorizonLine = L10n.tr("Localizable", "settings_behaviour_infos_horizon_line")
  /// Horizon line : Fixed
  internal static let settingsBehaviourInfosHorizonLineFixed = L10n.tr("Localizable", "settings_behaviour_infos_horizon_line_fixed")
  /// Allow camera to follow the drone’s rolling moves.
  internal static let settingsBehaviourInfosHorizonLineFixedDescription = L10n.tr("Localizable", "settings_behaviour_infos_horizon_line_fixed_description")
  /// Horizon line : Follow
  internal static let settingsBehaviourInfosHorizonLineFollow = L10n.tr("Localizable", "settings_behaviour_infos_horizon_line_follow")
  /// The gimbal follows the drone's movement when the drone rolls.
  internal static let settingsBehaviourInfosHorizonLineFollowDescription = L10n.tr("Localizable", "settings_behaviour_infos_horizon_line_follow_description")
  /// Inclination
  internal static let settingsBehaviourMaxInclination = L10n.tr("Localizable", "settings_behaviour_max_inclination")
  /// Max speed
  internal static let settingsBehaviourMaxSpeed = L10n.tr("Localizable", "settings_behaviour_max_speed")
  /// Modes
  internal static let settingsBehaviourMode = L10n.tr("Localizable", "settings_behaviour_mode")
  /// Racing
  internal static let settingsBehaviourRacing = L10n.tr("Localizable", "settings_behaviour_racing")
  /// Reset %@ settings
  internal static func settingsBehaviourReset(_ p1: Any) -> String {
    return L10n.tr("Localizable", "settings_behaviour_reset", String(describing: p1))
  }
  /// Rotation speed
  internal static let settingsBehaviourRotationSpeed = L10n.tr("Localizable", "settings_behaviour_rotation_speed")
  /// Flight
  internal static let settingsBehaviourSectionFlight = L10n.tr("Localizable", "settings_behaviour_section_flight")
  /// Gimbal
  internal static let settingsBehaviourSectionGimbal = L10n.tr("Localizable", "settings_behaviour_section_gimbal")
  /// Sport
  internal static let settingsBehaviourSport = L10n.tr("Localizable", "settings_behaviour_sport")
  /// Vertical speed
  internal static let settingsBehaviourVerticalSpeed = L10n.tr("Localizable", "settings_behaviour_vertical_speed")
  /// Film
  internal static let settingsBehaviourVideo = L10n.tr("Localizable", "settings_behaviour_video")
  /// Anti-flickering
  internal static let settingsCameraAntiFlickering = L10n.tr("Localizable", "settings_camera_anti_flickering")
  /// Auto
  internal static let settingsCameraAntiFlickeringAuto = L10n.tr("Localizable", "settings_camera_anti_flickering_auto")
  /// 50 Hz
  internal static let settingsCameraAntiFlickeringHz50 = L10n.tr("Localizable", "settings_camera_anti_flickering_hz50")
  /// 60 Hz
  internal static let settingsCameraAntiFlickeringHz60 = L10n.tr("Localizable", "settings_camera_anti_flickering_hz60")
  /// Auto-record
  internal static let settingsCameraAutoRecord = L10n.tr("Localizable", "settings_camera_auto_record")
  /// H264
  internal static let settingsCameraH264 = L10n.tr("Localizable", "settings_camera_h264")
  /// H265
  internal static let settingsCameraH265 = L10n.tr("Localizable", "settings_camera_h265")
  /// HDR-10
  internal static let settingsCameraHdr10 = L10n.tr("Localizable", "settings_camera_hdr10")
  /// HDR-10 is only available with H265
  internal static let settingsCameraHdr10Availability = L10n.tr("Localizable", "settings_camera_hdr10_availability")
  /// HDR-8
  internal static let settingsCameraHdr8 = L10n.tr("Localizable", "settings_camera_hdr8")
  /// Lossless zoom only
  internal static let settingsCameraLossyZoom = L10n.tr("Localizable", "settings_camera_lossy_zoom")
  /// Display overexposure
  internal static let settingsCameraOverExposure = L10n.tr("Localizable", "settings_camera_over_exposure")
  /// Sign pictures
  internal static let settingsCameraPhotoDigitalSignature = L10n.tr("Localizable", "settings_camera_photo_digital_signature")
  /// Reinitiate camera settings
  internal static let settingsCameraReset = L10n.tr("Localizable", "settings_camera_reset")
  /// Video encoding
  internal static let settingsCameraVideoEncoding = L10n.tr("Localizable", "settings_camera_video_encoding")
  /// Video HDR mode
  internal static let settingsCameraVideoHdrMode = L10n.tr("Localizable", "settings_camera_video_hdr_mode")
  /// Advanced
  internal static let settingsCategoryAdvanced = L10n.tr("Localizable", "settings_category_advanced")
  /// Controls
  internal static let settingsCategoryControls = L10n.tr("Localizable", "settings_category_controls")
  /// Quick
  internal static let settingsCategoryQuick = L10n.tr("Localizable", "settings_category_quick")
  /// Enable 4G
  internal static let settingsConnection4gEnable = L10n.tr("Localizable", "settings_connection_4g_enable")
  /// 4G priority
  internal static let settingsConnection4gOnly = L10n.tr("Localizable", "settings_connection_4g_only")
  /// Access point name
  internal static let settingsConnectionApn = L10n.tr("Localizable", "settings_connection_apn")
  /// Broadcast DRI
  internal static let settingsConnectionBroadcastDri = L10n.tr("Localizable", "settings_connection_broadcast_dri")
  /// Cellular data
  internal static let settingsConnectionCellularData = L10n.tr("Localizable", "settings_connection_cellular_data")
  /// Direct Remote Identification (DRI) system makes your drone locally broadcast information about itself for regulatory compliance (where applicable). The DRI message is transmitted in real time during the whole duration of the flight, and through an open and documented transmission protocol. When the DRI function is activated, the drone identification number broadcasted is the one displayed below the activation button.\nSome countries may ask you to register this identification number as well as other information. Please check the local legislation of the country in which you fly.
  internal static let settingsConnectionDriDialogText = L10n.tr("Localizable", "settings_connection_dri_dialog_text")
  /// Direct Remote Identification (DRI)
  internal static let settingsConnectionDriDialogTitle = L10n.tr("Localizable", "settings_connection_dri_dialog_title")
  /// Learn more
  internal static let settingsConnectionDriLearnMore = L10n.tr("Localizable", "settings_connection_dri_learn_more")
  /// DRI
  internal static let settingsConnectionDriName = L10n.tr("Localizable", "settings_connection_dri_name")
  /// Mobile network
  internal static let settingsConnectionMobileNetwork = L10n.tr("Localizable", "settings_connection_mobile_network")
  /// Network preference
  internal static let settingsConnectionNetworkMode = L10n.tr("Localizable", "settings_connection_network_mode")
  /// Wi-Fi network name
  internal static let settingsConnectionNetworkName = L10n.tr("Localizable", "settings_connection_network_name")
  /// APN selection
  internal static let settingsConnectionNetworkSelection = L10n.tr("Localizable", "settings_connection_network_selection")
  /// Reset Wi-Fi preferences
  internal static let settingsConnectionReset = L10n.tr("Localizable", "settings_connection_reset")
  /// User name
  internal static let settingsConnectionUserName = L10n.tr("Localizable", "settings_connection_user_name")
  /// Wi-Fi
  internal static let settingsConnectionWifiLabel = L10n.tr("Localizable", "settings_connection_wifi_label")
  /// Wi-Fi network’s name
  internal static let settingsConnectionWifiName = L10n.tr("Localizable", "settings_connection_wifi_name")
  /// Wi-Fi priority
  internal static let settingsConnectionWifiPriority = L10n.tr("Localizable", "settings_connection_wifi_priority")
  /// Wi-Fi band
  internal static let settingsConnectionWifiRange = L10n.tr("Localizable", "settings_connection_wifi_range")
  /// Wifi type
  internal static let settingsConnectionWifiType = L10n.tr("Localizable", "settings_connection_wifi_type")
  /// A controller is needed to activate Arcade mode.
  internal static let settingsControlsArcadeHelpRemoteNeeded = L10n.tr("Localizable", "settings_controls_arcade_help_remote_needed")
  /// Take-off to use Arcade mode
  internal static let settingsControlsArcadeHelpTakeoffNeeded = L10n.tr("Localizable", "settings_controls_arcade_help_takeoff_needed")
  /// Acceleration\nand rotation
  internal static let settingsControlsMappingAccelerationRotation = L10n.tr("Localizable", "settings_controls_mapping_acceleration_rotation")
  /// Camera
  internal static let settingsControlsMappingCamera = L10n.tr("Localizable", "settings_controls_mapping_camera")
  /// Camera tilt\nLateral
  internal static let settingsControlsMappingCameraLateral = L10n.tr("Localizable", "settings_controls_mapping_camera_lateral")
  /// Camera tilt\nRotation
  internal static let settingsControlsMappingCameraRotation = L10n.tr("Localizable", "settings_controls_mapping_camera_rotation")
  /// Directions
  internal static let settingsControlsMappingDirections = L10n.tr("Localizable", "settings_controls_mapping_directions")
  /// Elevation
  internal static let settingsControlsMappingElevation = L10n.tr("Localizable", "settings_controls_mapping_elevation")
  /// Elevation\nand lateral
  internal static let settingsControlsMappingElevationLateral = L10n.tr("Localizable", "settings_controls_mapping_elevation_lateral")
  /// Elevation\nand rotation
  internal static let settingsControlsMappingElevationRotation = L10n.tr("Localizable", "settings_controls_mapping_elevation_rotation")
  /// Exposure
  internal static let settingsControlsMappingExposure = L10n.tr("Localizable", "settings_controls_mapping_exposure")
  /// Record
  internal static let settingsControlsMappingRecord = L10n.tr("Localizable", "settings_controls_mapping_record")
  /// Reset
  internal static let settingsControlsMappingReset = L10n.tr("Localizable", "settings_controls_mapping_reset")
  /// Zoom
  internal static let settingsControlsMappingZoom = L10n.tr("Localizable", "settings_controls_mapping_zoom")
  /// EV Trigger
  internal static let settingsControlsOptionEvTrigger = L10n.tr("Localizable", "settings_controls_option_ev_trigger")
  /// Inverse joys
  internal static let settingsControlsOptionInverseJoys = L10n.tr("Localizable", "settings_controls_option_inverse_joys")
  /// Joystick mode
  internal static let settingsControlsOptionJoystickMode = L10n.tr("Localizable", "settings_controls_option_joystick_mode")
  /// Mode %d
  internal static func settingsControlsOptionJoystickModeNumber(_ p1: Int) -> String {
    return L10n.tr("Localizable", "settings_controls_option_joystick_mode_number", p1)
  }
  /// Reverse tilt
  internal static let settingsControlsOptionReverseTilt = L10n.tr("Localizable", "settings_controls_option_reverse_tilt")
  /// Special
  internal static let settingsControlsOptionSpecial = L10n.tr("Localizable", "settings_controls_option_special")
  /// Piloting style
  internal static let settingsControlsPilotingStyle = L10n.tr("Localizable", "settings_controls_piloting_style")
  /// Arcade
  internal static let settingsControlsPilotingStyleArcade = L10n.tr("Localizable", "settings_controls_piloting_style_arcade")
  /// Classic
  internal static let settingsControlsPilotingStyleClassic = L10n.tr("Localizable", "settings_controls_piloting_style_classic")
  /// Change password
  internal static let settingsEditPasswordChangePassword = L10n.tr("Localizable", "settings_edit_password_change_password")
  /// Confirm password
  internal static let settingsEditPasswordConfirmPassword = L10n.tr("Localizable", "settings_edit_password_confirm_password")
  /// You can edit Anafi's Wi-Fi password. Be careful, the drone will automatically disconnect. Please remember your password, as you'll need it next time you connect.
  internal static let settingsEditPasswordDescription = L10n.tr("Localizable", "settings_edit_password_description")
  /// Wi-Fi password
  internal static let settingsEditPasswordLabel = L10n.tr("Localizable", "settings_edit_password_label")
  /// Passwords do not match
  internal static let settingsEditPasswordMatchError = L10n.tr("Localizable", "settings_edit_password_match_error")
  /// The password must contain between 8 and 63 characters
  internal static let settingsEditPasswordSecurityDescription = L10n.tr("Localizable", "settings_edit_password_security_description")
  /// Edit Wi-Fi password
  internal static let settingsEditPasswordTitle = L10n.tr("Localizable", "settings_edit_password_title")
  /// I remember my password
  internal static let settingsEditPasswordValidateChange = L10n.tr("Localizable", "settings_edit_password_validate_change")
  /// If you forget the Wi-Fi password, hold the drone's power button for 10 seconds to reset and reinitiate the password.
  internal static let settingsEditPasswordWarning = L10n.tr("Localizable", "settings_edit_password_warning")
  /// Reset geocage preferences
  internal static let settingsGeofenceReset = L10n.tr("Localizable", "settings_geofence_reset")
  /// Measurement system
  internal static let settingsInterfaceMeasurementSystem = L10n.tr("Localizable", "settings_interface_measurement_system")
  /// Imperial
  internal static let settingsInterfaceMeasurementSystemImperial = L10n.tr("Localizable", "settings_interface_measurement_system_imperial")
  /// Metric
  internal static let settingsInterfaceMeasurementSystemMetric = L10n.tr("Localizable", "settings_interface_measurement_system_metric")
  /// Auto
  internal static let settingsInterfaceMeasurementsSystemAuto = L10n.tr("Localizable", "settings_interface_measurements_system_auto")
  /// Map type
  internal static let settingsInterfaceMinimapType = L10n.tr("Localizable", "settings_interface_minimap_type")
  /// Reset interface settings
  internal static let settingsInterfaceReset = L10n.tr("Localizable", "settings_interface_reset")
  /// Secondary screen
  internal static let settingsInterfaceSecondaryScreen = L10n.tr("Localizable", "settings_interface_secondary_screen")
  /// 3D view
  internal static let settingsInterfaceSecondaryScreen3dView = L10n.tr("Localizable", "settings_interface_secondary_screen_3d_view")
  /// Map
  internal static let settingsInterfaceSecondaryScreenMap = L10n.tr("Localizable", "settings_interface_secondary_screen_map")
  /// Hybrid
  internal static let settingsInterfaceTypeHybrid = L10n.tr("Localizable", "settings_interface_type_hybrid")
  /// Roadmap
  internal static let settingsInterfaceTypeRoadmap = L10n.tr("Localizable", "settings_interface_type_roadmap")
  /// Satellite
  internal static let settingsInterfaceTypeSatellite = L10n.tr("Localizable", "settings_interface_type_satellite")
  /// Audio OFF
  internal static let settingsQuickAudioOff = L10n.tr("Localizable", "settings_quick_audio_off")
  /// Audio ON
  internal static let settingsQuickAudioOn = L10n.tr("Localizable", "settings_quick_audio_on")
  /// Audio
  internal static let settingsQuickAudioRec = L10n.tr("Localizable", "settings_quick_audio_rec")
  /// Obstacle avoidance
  internal static let settingsQuickAvoidance = L10n.tr("Localizable", "settings_quick_avoidance")
  /// Extra zoom
  internal static let settingsQuickExtraZoom = L10n.tr("Localizable", "settings_quick_extra_zoom")
  /// Hand land
  internal static let settingsQuickHandland = L10n.tr("Localizable", "settings_quick_handland")
  /// Hand launch
  internal static let settingsQuickHandlaunch = L10n.tr("Localizable", "settings_quick_handlaunch")
  /// Love blended
  internal static let settingsQuickLoveBlended = L10n.tr("Localizable", "settings_quick_love_blended")
  /// Occupancy
  internal static let settingsQuickOccupancy = L10n.tr("Localizable", "settings_quick_occupancy")
  /// End by
  internal static let settingsRthEndByTitle = L10n.tr("Localizable", "settings_rth_end_by_title")
  /// Reset RTH preferences
  internal static let settingsRthReset = L10n.tr("Localizable", "settings_rth_reset")
  /// Pilot position
  internal static let settingsRthTypePilot = L10n.tr("Localizable", "settings_rth_type_pilot")
  /// Take-off point
  internal static let settingsRthTypeTakeOff = L10n.tr("Localizable", "settings_rth_type_takeOff")
  /// Return to
  internal static let settingsRthTypeTitle = L10n.tr("Localizable", "settings_rth_type_title")
  /// Spot AE
  internal static let spotAe = L10n.tr("Localizable", "spot_ae")
  /// Please calibrate your drone before flying.
  internal static let takeoffAlertCalibrationDescription = L10n.tr("Localizable", "takeoff_alert_calibration_description")
  /// You need to update your drone and controller before taking off.
  internal static let takeoffAlertDroneRemoteUpdateDescription = L10n.tr("Localizable", "takeoff_alert_drone_remote_update_description")
  /// Drone and controller update required
  internal static let takeoffAlertDroneRemoteUpdateTitle = L10n.tr("Localizable", "takeoff_alert_drone_remote_update_title")
  /// You need to update your drone before taking off.
  internal static let takeoffAlertDroneUpdateDescription = L10n.tr("Localizable", "takeoff_alert_drone_update_description")
  /// Drone update required
  internal static let takeoffAlertDroneUpdateTitle = L10n.tr("Localizable", "takeoff_alert_drone_update_title")
  /// The battery temperature is too high to take off.
  internal static let takeoffAlertHighTemperatureDescription = L10n.tr("Localizable", "takeoff_alert_high_temperature_description")
  /// Battery temperature too high
  internal static let takeoffAlertHighTemperatureTitle = L10n.tr("Localizable", "takeoff_alert_high_temperature_title")
  /// The battery temperature is too low to take off.
  internal static let takeoffAlertLowTemperatureDescription = L10n.tr("Localizable", "takeoff_alert_low_temperature_description")
  /// Battery temperature too cold
  internal static let takeoffAlertLowTemperatureTitle = L10n.tr("Localizable", "takeoff_alert_low_temperature_title")
  /// Update
  internal static let takeoffAlertUpdate = L10n.tr("Localizable", "takeoff_alert_update")
  /// The drone uses the vertical camera for a stable flight, it won’t be able to take-off without it. Please contact Parrot customer service.
  internal static let takeoffAlertVerticalCameraDescription = L10n.tr("Localizable", "takeoff_alert_vertical_camera_description")
  /// Vertical camera failure
  internal static let takeoffAlertVerticalCameraTitle = L10n.tr("Localizable", "takeoff_alert_vertical_camera_title")
  /// I accept
  internal static let termsOfUseAccept = L10n.tr("Localizable", "terms_of_use_accept")
  /// Scroll to the bottom to continue.
  internal static let termsOfUseScroll = L10n.tr("Localizable", "terms_of_use_scroll")
  /// Terms of use
  internal static let termsOfUseTitle = L10n.tr("Localizable", "terms_of_use_title")
  /// Max tilt
  internal static let tiltMaxReached = L10n.tr("Localizable", "tilt_max_reached")
  /// %ds
  internal static func timeInSeconds(_ p1: Int) -> String {
    return L10n.tr("Localizable", "time_in_seconds", p1)
  }
  /// °C
  internal static let unitCelsius = L10n.tr("Localizable", "unit_celsius")
  /// cm/px
  internal static let unitCentimeterPerPixel = L10n.tr("Localizable", "unit_centimeter_per_pixel")
  /// °
  internal static let unitDegree = L10n.tr("Localizable", "unit_degree")
  /// °/s
  internal static let unitDegreePerSecond = L10n.tr("Localizable", "unit_degree_per_second")
  /// EV
  internal static let unitEv = L10n.tr("Localizable", "unit_ev")
  /// °F
  internal static let unitFahrenheit = L10n.tr("Localizable", "unit_fahrenheit")
  /// ft
  internal static let unitFeet = L10n.tr("Localizable", "unit_feet")
  /// ft/s
  internal static let unitFeetPerSecond = L10n.tr("Localizable", "unit_feet_per_second")
  /// fps
  internal static let unitFps = L10n.tr("Localizable", "unit_fps")
  /// Gb
  internal static let unitGigabyte = L10n.tr("Localizable", "unit_gigabyte")
  /// ISO
  internal static let unitIso = L10n.tr("Localizable", "unit_iso")
  /// K
  internal static let unitKelvin = L10n.tr("Localizable", "unit_kelvin")
  /// km
  internal static let unitKilometer = L10n.tr("Localizable", "unit_kilometer")
  /// km/h
  internal static let unitKilometerPerHour = L10n.tr("Localizable", "unit_kilometer_per_hour")
  /// m/s
  internal static let unitMPerSecond = L10n.tr("Localizable", "unit_m_per_second")
  /// Mb
  internal static let unitMegabyte = L10n.tr("Localizable", "unit_megabyte")
  /// Mp
  internal static let unitMegapixel = L10n.tr("Localizable", "unit_megapixel")
  /// m
  internal static let unitMeter = L10n.tr("Localizable", "unit_meter")
  /// mi
  internal static let unitMiles = L10n.tr("Localizable", "unit_miles")
  /// mph
  internal static let unitMilesPerHour = L10n.tr("Localizable", "unit_miles_per_hour")
  /// min
  internal static let unitMin = L10n.tr("Localizable", "unit_min")
  /// %
  internal static let unitPercent = L10n.tr("Localizable", "unit_percent")
  /// %%
  internal static let unitPercentIos = L10n.tr("Localizable", "unit_percent_ios")
  /// sec
  internal static let unitSec = L10n.tr("Localizable", "unit_sec")
  /// s
  internal static let unitSecond = L10n.tr("Localizable", "unit_second")
  /// sec
  internal static let unitSecondLongFormat = L10n.tr("Localizable", "unit_second_long_format")
  /// 1080p
  internal static let videoSettingsResolution1080p = L10n.tr("Localizable", "video_settings_resolution_1080p")
  /// 1080p-SD
  internal static let videoSettingsResolution1080pSD = L10n.tr("Localizable", "video_settings_resolution_1080p_SD")
  /// 2.7K
  internal static let videoSettingsResolution27k = L10n.tr("Localizable", "video_settings_resolution_27k")
  /// 480p
  internal static let videoSettingsResolution480p = L10n.tr("Localizable", "video_settings_resolution_480p")
  /// 4K
  internal static let videoSettingsResolution4k = L10n.tr("Localizable", "video_settings_resolution_4k")
  /// 4K Cinema
  internal static let videoSettingsResolution4kCinema = L10n.tr("Localizable", "video_settings_resolution_4k_cinema")
  /// 5K
  internal static let videoSettingsResolution5k = L10n.tr("Localizable", "video_settings_resolution_5k")
  /// 6K
  internal static let videoSettingsResolution6k = L10n.tr("Localizable", "video_settings_resolution_6k")
  /// 720p
  internal static let videoSettingsResolution720p = L10n.tr("Localizable", "video_settings_resolution_720p")
  /// 720p-SD
  internal static let videoSettingsResolution720pSD = L10n.tr("Localizable", "video_settings_resolution_720p_SD")
  /// 8K
  internal static let videoSettingsResolution8k = L10n.tr("Localizable", "video_settings_resolution_8k")
  /// 2.4 GHz
  internal static let wifiBand24 = L10n.tr("Localizable", "wifi_band_2_4")
  /// 5 GHz
  internal static let wifiBand5 = L10n.tr("Localizable", "wifi_band_5")
  /// Maximum zoom
  internal static let zoomMaxReached = L10n.tr("Localizable", "zoom_max_reached")
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: nil, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
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
