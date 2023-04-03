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

private extension ULogTag {
    static let tag = ULogTag(name: "drone+Rth")
}

/// Utility extension for `Drone` Return Home Piloting Interface.
public extension Drone {
    // MARK: - Public Properties

    /// Returns true if drone is Returning Home.
    var isReturningHome: Bool {
        let rth = getPilotingItf(PilotingItfs.returnHome)
        return rth?.state == .active
    }

    // MARK: - Internal Funcs
    /// Triggers RTH.
    @discardableResult
    func performReturnHome() -> Bool? {
        // deactivate onboard tracker if necessary to stop look at / follow from starting again
        if let onboard = getPeripheral(Peripherals.onboardTracker), onboard.trackingEngineState == .activated {
            onboard.removeAllTargets()
            onboard.stopTrackingEngine()
        }
        return getPilotingItf(PilotingItfs.returnHome)?.activate()
    }

    /// Cancels RTH.
    @discardableResult
    func cancelReturnHome() -> Bool {
        guard let returnHome = getPilotingItf(PilotingItfs.returnHome) else {
            ULog.e(.tag, "PilotingItfs.returnHome is nil")
            return false
        }
        let deactivated = returnHome.deactivate()
        ULog.i(.tag, "Rth piloting interface deactivated: \(deactivated)")
        return deactivated
    }

    /// Cancels Auto trigger RTH.
    func cancelAutoTriggerReturnHome() {
        getPilotingItf(PilotingItfs.returnHome)?.cancelAutoTrigger()
    }

    /// Returns true if drone is in a force landing
    ///
    ///  - Parameters:
    ///     - alarms: alarms intrument
    ///     - flyingIndicators: flying indicators intrument
    func isForceLanding(alarms: Alarms?, flyingIndicators: FlyingIndicators?) -> Bool {
        guard let alarms = alarms, let flyingIndicators = flyingIndicators else { return false }

        let isDroneEmergencyLanding = flyingIndicators.state == .emergencyLanding
        let isDroneFlying = flyingIndicators.state == .flying

        let isAutolandingAlarmOn = alarms.level(.automaticLandingBatteryIssue) == .critical
        || alarms.level(.automaticLandingBatteryTooHot) == .critical
        || alarms.level(.automaticLandingBatteryTooCold) == .critical
        || alarms.level(.automaticLandingPropellerIcingIssue) == .critical
        let isDelayElapsed = alarms.automaticLandingDelay == 0

        return (isDroneFlying || isDroneEmergencyLanding) && isAutolandingAlarmOn && isDelayElapsed
    }
}
