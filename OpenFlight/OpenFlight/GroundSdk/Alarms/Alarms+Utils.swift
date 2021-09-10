//
//  Copyright (C) 2020 Parrot Drones SAS.
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

/// Utility extension for `Alarms`.

extension Alarms {
    /// Computes current conditions alerts.
    ///
    /// - Parameters:
    ///    - drone: current drone
    /// - Returns: an array containing current conditions alerts
    func conditionsAlerts(drone: Drone) -> [HUDAlertType] {
        var alerts = [HUDAlertType]()
        if getAlarm(kind: .hoveringDifficultiesNoGpsTooDark).hasError {
            alerts.append(HUDBannerCriticalAlertType.noGpsTooDark)
        }

        if getAlarm(kind: .hoveringDifficultiesNoGpsTooHigh).hasError {
            alerts.append(HUDBannerCriticalAlertType.noGpsTooHigh)
        }

        if drone.getInstrument(Instruments.gps)?.fixed == false,
            drone.isStateFlying {
            if drone.currentCamera?.isGpsLapseStarted == true {
                alerts.append(HUDBannerCriticalAlertType.noGpsLapse)
            } else {
                alerts.append(HUDBannerCriticalAlertType.noGps)
            }
        }

        if getAlarm(kind: .magnetometerPertubation).hasError {
            alerts.append(HUDBannerCriticalAlertType.headingLockedKoPerturbationMagnetic)
        }

        if getAlarm(kind: .magnetometerLowEarthField).hasError {
            alerts.append(HUDBannerCriticalAlertType.headingLockedKoEarthMagnetic)
        }

        if getAlarm(kind: .wind).hasError {
            alerts.append(HUDBannerCriticalAlertType.tooMuchWind)
        }

        return alerts
    }

    /// Computes current obstacle avoidance alerts.
    ///
    /// - Parameters:
    ///    - drone: current drone
    /// - Returns: an array containing current obstacle avoidance alerts
    func obastacleAvoidanceAlerts(drone: Drone) -> [HUDAlertType] {
        var alerts = [HUDAlertType]()

        // Checks alert for sensors failure.
        if getAlarm(kind: Alarm.Kind.obstacleAvoidanceDisabledStereoFailure).hasError
            || getAlarm(kind: Alarm.Kind.obstacleAvoidanceDisabledStereoLensFailure).hasError
            || getAlarm(kind: Alarm.Kind.obstacleAvoidanceDisabledGimbalFailure).hasError {
            alerts.append(HUDBannerCriticalAlertType.obstacleAvoidanceSensorsFailure)
        }

        // Checks alert for stereo sensors calibration.
        if getAlarm(kind: Alarm.Kind.obstacleAvoidanceDisabledCalibrationFailure).hasError {
            alerts.append(HUDBannerCriticalAlertType.obstacleAvoidanceSensorsNotCalibrated)
        }

        // Checks alert for environnement too dark.
        if getAlarm(kind: Alarm.Kind.obstacleAvoidanceDisabledTooDark).hasError {
            alerts.append(HUDBannerCriticalAlertType.obstacleAvoidanceTooDark)
        }

        // Check alert for manual piloting with poor gps quality
        // and with obstacle avoidance in degraded mode.
        if getAlarm(kind: Alarm.Kind.obstacleAvoidancePoorGps).hasError {
            alerts.append(HUDBannerCriticalAlertType.obstacleAvoidanceDeteriorated)
        }

        // Checks alert for drone stuck.
        if getAlarm(kind: Alarm.Kind.droneStuck).hasError {
            alerts.append(HUDBannerWarningAlertType.obstacleAvoidanceDroneStucked)
        }

        // Check alert for high deviation
        if getAlarm(kind: .highDeviation).hasError {
            alerts.append(HUDBannerWarningAlertType.highDeviation)
        }

        // Check alert for strong wind with obstacle avoidance
        if getAlarm(kind: .obstacleAvoidanceStrongWind).hasError {
            alerts.append(HUDBannerCriticalAlertType.obstacleAvoidanceStrongWind)
        }

        return alerts
    }

    /// Computes current Imu saturation alerts.
    ///
    /// - Parameters:
    ///    - drone: current drone
    /// - Returns: current imu saturation alert if any
    func imuSaturationAlerts(drone: Drone) -> HUDAlertType? {
        guard drone.isTakingOff || drone.isLanding else {
            return nil
        }
        let imuSaturationAlarm = getAlarm(kind: .strongVibrations)
        switch imuSaturationAlarm.level {
        case .warning:
            return HUDBannerWarningAlertType.imuVibration
        case .critical:
            return HUDBannerCriticalAlertType.strongImuVibration
        default:
            return nil
        }
    }

    /// Computes current motor alerts.
    ///
    /// - Parameters:
    ///    - drone: current drone
    /// - Returns: an array containing current motor alerts
    func motorAlerts(drone: Drone) -> [HUDAlertType] {
        let isCutout = getAlarm(kind: .motorCutOut).hasError
        let hasError = getAlarm(kind: .motorError).hasError
        if isCutout || hasError {
            return drone.getPeripheral(Peripherals.copterMotors)?
                .currentErrors ?? [HUDBannerCriticalAlertType.motorCutout]
        } else {
            return []
        }
    }
}
