//    Copyright (C) 2021 Parrot Drones SAS
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

/// Utility extension for `FlightPlanUnavailabilityReason`.
extension FlightPlanUnavailabilityReason {
    /// Returns associated text for error display.
    var errorText: String? {
        switch self {
        case .droneGpsInfoInaccurate:
            return L10n.flightPlanAlertDroneGpsKo
        case .droneNotCalibrated:
            return L10n.flightPlanAlertDroneMagnetometerKo
        case .missingFlightPlanFile:
            // Not treated as a real error.
            return nil
        case .cannotTakeOff:
            return L10n.flightPlanAlertCannotTakeOff
        case .cameraUnavailable:
            return L10n.flightPlanAlertCameraUnavailable
        case .insufficientBattery:
            return L10n.flightPlanAlertInsufficientBattery
        case .droneInvalidState:
            // Do not display any error message if drone state is invalid.
            return ""
        }
    }
}

/// Utility extension for set of `FlightPlanUnavailabilityReason`.
extension Set where Element == FlightPlanUnavailabilityReason {
    /// Returns text to display for the highest priority unavailability reason.
    var errorText: String? {
        // TODO: wait specs to see if Comparable should be implemented to handle priority.
        return sorted(by: { $0.rawValue < $1.rawValue }).first?.errorText
    }
}
