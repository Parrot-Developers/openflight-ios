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

import Foundation

/// Defines units.
public enum UnitType {
    case distance
    case speed
    case degree
    case degreePerSecond
    case percent
    case centimeterPerpixel
    case noUnitInt
    case none

    // MARK: - helpers
    var unit: String {
        switch self {
        case .distance:
            return UnitHelper.stringDistanceUnit()
        case .speed:
            return UnitHelper.stringSpeedUnit()
        case .degree:
            return L10n.unitDegree
        case .degreePerSecond:
            return L10n.unitDegreePerSecond
        case .percent:
            return L10n.unitPercentIos
        case .centimeterPerpixel:
            return L10n.unitCentimeterPerPixel
        case .none, .noUnitInt:
            return ""
        }
    }

    /// Convert a float value to string regarding type.
    ///
    /// - Parameters:
    ///     - value: value to use
    func value(withFloat value: Float) -> String {
        guard !value.isNaN
            else {
                return "0.0 \(unit)"
        }
        switch self {
        case .distance:
            return UnitHelper.stringDistanceWithFloat(ceilf(value))
        case .speed:
            return UnitHelper.stringSpeedWithFloat(value)
        case .degree, .degreePerSecond, .percent:
            return String(format: "%.0f", value) + " \(unit)"
        case .noUnitInt:
            return String(format: "%.0f", value)
        default:
            return String(format: "%.1f", value) + " \(unit)"
        }
    }
    /// Convert a float value with 2 decimal to string regarding type.
    ///
    /// - Parameters:
    ///     - value: value to use
    func value2f(withFloat value: Float) -> String {
        guard !value.isNaN
        else {
            return "0.0 \(unit)"
        }
        switch self {
        case .distance:
            return UnitHelper.stringDistanceWithFloat(ceilf(value))
        case .speed:
            return UnitHelper.stringSpeedWithFloat2f(value)
        case .degree, .degreePerSecond, .percent:
            return String(format: "%.2f", value) + " \(unit)"
        case .noUnitInt:
            return String(format: "%.0f", value)
        default:
            return String(format: "%.2f", value) + " \(unit)"
        }
    }
}
