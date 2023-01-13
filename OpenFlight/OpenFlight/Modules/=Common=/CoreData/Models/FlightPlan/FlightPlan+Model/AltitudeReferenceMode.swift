//    Copyright (C) 2022 Parrot Drones SAS
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

import Foundation

/// The altitude reference modes.
public enum AltitudeReferenceMode: Int {
    /// Above take off.
    case ato
    /// Above mean sea level.
    case amsl

    /// The mode index.
    public var index: Int { rawValue }
}

/// `CaseIterable` support.
extension AltitudeReferenceMode: CaseIterable {}

// MARK: Public properties.
extension AltitudeReferenceMode {
    /// The default value.
    static var defaultValue: AltitudeReferenceMode { .ato }

    /// The altitude reference mode title.
    public var title: String {
        switch self {
        case .ato:
            return L10n.flightPlanAltitudeReferenceAtoTitle
        case .amsl:
            return L10n.flightPlanAltitudeReferenceAglTitle
        }
    }

    /// The altitude reference mode short title.
    public var shortTitle: String {
        switch self {
        case .ato:
            return L10n.flightPlanAltitudeReferenceAtoShortTitle
        case .amsl:
            return L10n.flightPlanAltitudeReferenceAglShortTitle
        }
    }
}

// MARK: Helpers.
extension AltitudeReferenceMode {

    /// Returns the mode for the flight plan passed in parameter.
    ///
    /// - Parameter flightPlan: the flight plan
    /// - Returns: the flight plan's `AltitudeReferenceMode`
    public static func value(for flightPlan: FlightPlanModel?) -> Self {
        flightPlan?.isAMSL == true ? .amsl : .ato
    }
}
