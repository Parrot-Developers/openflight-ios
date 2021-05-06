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
        .motorCutoutTemperature,
        .motorCutoutPowerSupply,
        .forceLandingFlyAway,
        .forceLandingLowBattery,
        .forceLandingTemperature,
        .veryLowBatteryLanding,
        .veryLowBattery,
        .noGpsTooDark,
        .noGpsTooHigh,
        .noGps,
        .headingLockedKo,
        .noGpsLapse,
        .tooMuchWind,
        .strongImuVibration,
        .internalMemoryFull,
        .sdError,
        .sdFull,
        .sdTooSlow,
        .geofenceAltitudeAndDistance,
        .geofenceAltitude,
        .geofenceDistance,
        .obstacleAvoidanceDroneStucked,
        .obstacleAvoidanceNoGpsTooHigh,
        .obstacleAvoidanceNoGpsTooDark,
        .obstacleAvoidanceTooDark,
        .obstacleAvoidanceSensorsFailure,
        .obstacleAvoidanceSensorsNotCalibrated,
        .obstacleAvoidanceDeteriorated]

    /// Returns only warning alerts.
    public var sortedWarningAlerts: [HUDBannerWarningAlertType] = [
        .cameraError,
        .lowAndPerturbedWifi,
        .obstacleAvoidanceDroneStucked,
        .imuVibration,
        .targetLost,
        .droneGpsKo,
        .userDeviceGpsKo,
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
