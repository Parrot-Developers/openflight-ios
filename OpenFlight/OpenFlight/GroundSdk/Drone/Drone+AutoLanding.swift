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

// [Banner Alerts] Legacy code is temporarily kept for validation purpose only.
// TODO: Remove file.

import GroundSdk

/// Utility extension for auto landing.
extension Drone {
    // MARK: - Internal Properties
    /// Returns current auto landing alerts.
    var autoLandingAlerts: [HUDAlertType] {
        guard let alarms = getInstrument(Instruments.alarms),
            let flyingIndicators = getInstrument(Instruments.flyingIndicators),
            let returnHome = getPilotingItf(PilotingItfs.returnHome)
            else {
                return []
        }
        var alerts = [HUDAlertType]()
        let tooHotAlarm = alarms.getAlarm(kind: .batteryTooHot)
        let tooColdAlarm = alarms.getAlarm(kind: .batteryTooCold)
        let autoLandingAlarm = alarms.getAlarm(kind: .automaticLandingBatteryIssue)
        if flyingIndicators.state == .emergencyLanding
            && (tooHotAlarm.level == .critical
                || tooColdAlarm.level == .critical) {
            alerts.append(HUDBannerCriticalAlertType.forceLandingTemperature)
        }
        // Display forceLanding banner only when landing.
        if flyingIndicators.state != .landed,
           autoLandingAlarm.level == .critical,
           alarms.automaticLandingDelay == 0 {
            alerts.append(HUDBannerCriticalAlertType.forceLandingLowBattery)
        }
        if flyingIndicators.state == .flying,
           returnHome.homeReachability == .notReachable {
            alerts.append(HUDBannerCriticalAlertType.wontReachHome)
        }
        return alerts
    }

    /// Whether a forceLanding alert is active. Used to be able to ignore RTH events during autoLanding.
    /// (Can not simply check `autoLandingAlerts.isEmpty` or `HUDBannerCriticalAlertType.category`,
    /// as `.wontReachHome` is considered as an autoLanding alert.)
    var isForceLandingInProgress: Bool {
        autoLandingAlerts.first?.isSameAlert(as: HUDBannerCriticalAlertType.forceLandingTemperature) == true ||
        autoLandingAlerts.first?.isSameAlert(as: HUDBannerCriticalAlertType.forceLandingLowBattery) == true
    }
}
