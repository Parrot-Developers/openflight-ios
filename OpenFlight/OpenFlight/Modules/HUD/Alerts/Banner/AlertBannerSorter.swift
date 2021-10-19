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

/// Used to sort top alerts by priority.
open class AlertBannerSorter {
    // MARK: - Public Properties
    /// Returns whole list ofsorted alerts.
    public var sortedAlerts: [HUDAlertType]?

    /// Returns only critical alerts.
    public var sortedCriticalAlerts: [HUDBannerCriticalAlertType] = [
        .motorCutout,
        // Components_Motor    Motors cutout    The engines of the drone have cut out.
        .motorCutoutTemperature,
        // Components_Motor    Motors cutout temperature issue    The engines of the drone have cut out.
        .motorCutoutPowerSupply,
        // Components_Motor    Motors cutout power supply issue    The engines of the drone have cut out.
        .forceLandingTemperature,
        // Auto landing    Force Landing High/Low °C    Auto Landing
        .forceLandingLowBattery,
        // Auto landing    Force Landing Low battery    Auto Landing
        .wontReachHome,
        //        RTH    Very Low Battery will RTH    Can’t reach Home
        .takeoffUnavailable,
        // Takeoff    Default takeoff issue    Take off is unavailable
        .obstacleAvoidanceComputationalError,
        // Obstacle avoidance    Computational error    Obstacle avoidance disabled - Internal error
        .obstacleAvoidanceSensorsFailure,
        // Obstacle avoidance    Stereo images unavailable + OA activated    Obstacle avoidance disabled - Stereo camera failure.
        .obstacleAvoidanceTooDark,
        // Obstacle avoidance    Too dark + OA activated    Obstacle avoidance disabled - Environment too dark
        .obstacleAvoidanceSensorsNotCalibrated,
        // Obstacle avoidance    Stereo calibration requiresd    Obstacle avoidance disabled - Stereo sensors calibration required
        .obstacleAvoidanceDeteriorated,
        // Obstacle avoidance    Manual piloting + No GPS    Obstacle avoidance deteriorated – Poor GPS quality
        .obstacleAvoidanceStrongWind,
        // Obstacle avoidance    Strong wind + OA activated    Obstacle avoidance deteriorated – Strong winds
        .cameraError,
        // Components_Camera    Camera critical alert    Check that nothing is blocking the camera.
        .noGpsTooDark,
        // Conditions    No GPS + Too dark    Flight quality is not optimal – environment is too dark.
        .noGpsTooHigh,
        // Conditions    No GPS + Too high    Flight quality is not optimal - decrease the drone's altitude.
        .noGps,
        // Conditions    No GPS    Poor GPS quality - autonomous flights are unavailable.
        .headingLockedKoPerturbationMagnetic,
        // Conditions    Heading Locked KO    Magnetic perturbations - autonomous flights are unavailable.
        .noGpsLapse,
        // Conditions    No GPS - GPS lapse    Flight quality is not optimal - GPS lapse is unavailable.
        .tooMuchWind,
        // Conditions_Wind    Too much wind    Strong winds
        .strongImuVibration,
        // Components_IMU    Strong IMU Vibration    Strong vibrations detected . Check that propellers are tightly screwed.
        .internalMemoryFull,
        // SD card    Internal memory full    Internal memory full
        .sdError,
        // SD card    SD error    SD Error - Switching to internal memory
        .sdFull,
        // SD card    SD full     SD Full - Switching to internal memory
        .sdTooSlow,
        // SD card    SD too slow    SD too slow - Switching to internal memory
        .geofenceAltitudeAndDistance,
        // Geofence    Geofencing altitude et distance    Geofence reached
        .geofenceAltitude,
        // Geofence    Geofencing altitude    Geofence reached
        .geofenceDistance]
        // Geofence    Geofencing distance    Geofence reached

    /// Returns only warning alerts.
    public var sortedWarningAlerts: [HUDBannerWarningAlertType] = [
        .lowAndPerturbedWifi,
        // Wi-Fi    No 4G - Low and Perturbed Wi-Fi    Weak Wi-Fi signal. Strong interferences
        .obstacleAvoidanceBlindMotionDirection,
        // Obstacle avoidance    Blind motion direction    Obstacle avoidance - Drone blind in this direction.
        .highDeviation,
        // Obstacle avoidance    High deviation    Obstacle avoidance - High deviation
        .obstacleAvoidanceDroneStucked,
        // Obstacle avoidance    Drone stuck    Obstacle avoidance  - Drone was not able to find a path.
        .imuVibration,
        // Components_IMU    IMU Saturation    Vibrations detected . Check that propellers are tightly screwed.
        .targetLost,
        // Animations    Target lost    Subject lost
        .droneGpsKo,
        // Animations    Drone GPS KO    GPS tracking connection lost
        .userDeviceGpsKo,
        // Animations    Smartphone GPS KO    GPS tracking connection lost
        .unauthorizedFlightZone,
        .unauthorizedFlightZoneWithMission]

    /// Returns only tutorial related alerts.
    public var sortedTutorialAlerts: [HUDBannerTutorialAlertType] = [
        .takeOff,
        .takeOffWaypoint,
        .takeOffPoi,
        .selectSubject]

    // MARK: - Init
    public init() {
        self.sortedAlerts = sortedCriticalAlerts
            + sortedWarningAlerts
            + sortedTutorialAlerts
    }

    // MARK: - Public Funcs
    /// Returns the first sorted alert which matches with the current alert (if one).
    ///
    /// - Parameters:
    ///     - currentAlerts: current alerts which needs to be displayed
    open func highestPriority(in currentAlerts: [HUDAlertType]) -> HUDAlertType? {
        return sortedAlerts?.first(where: { sortedAlert in
            if let criticalType = sortedAlert as? HUDBannerCriticalAlertType {
                return currentAlerts.contains(criticalType)
            } else if let warningType = sortedAlert as? HUDBannerWarningAlertType {
                return currentAlerts.contains(warningType)
            } else if let tutorialType = sortedAlert as? HUDBannerTutorialAlertType {
                return currentAlerts.contains(tutorialType)
            } else {
                return false
            }
        })
    }
}
