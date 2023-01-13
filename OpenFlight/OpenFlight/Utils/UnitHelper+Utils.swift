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

import SwiftyUserDefaults

public final class UnitHelper: NSObject {

    // MARK: - Private Properties
    /// Gets current user setting for measurement system.
    private static var unitSetting: UserMeasurementSetting {
        let userUnitString = Defaults.userMeasurementSetting ?? ""
        return UserMeasurementSetting(rawValue: userUnitString) ?? UserMeasurementSetting.auto
    }
    /// Returns true if app is currently using metric system.
    private static var isMetric: Bool {
        switch unitSetting {
        case .auto where Locale.current.usesMetricSystem, .metric:
            return true
        case .imperial, .auto:
            return false
        }
    }

    // MARK: - Private Enums
    private enum Constants {
        // Basic conversion factors.
        static let meterToFeet: Double = 3.2808399
        static let mileToFeet: Double = 5280.0
        static let kilometerToMeter: Double = 1000.0

        // Maximum meter value before switching to kilometer.
        static let meterCutoff: Double = 1000.0
        // Maximum feet value before switching to mile.
        static let feetCutoff: Double = 3168.0
    }

    /// This is used to get parameters that are associated with a specific distance unit.
    private enum DistanceType {
        case meter
        case kilometer
        case feet
        case mile

        /// Returns a factor for converting from meter to target distance unit.
        var conversionFactor: Double {
            switch self {
            case .meter:
                return 1.0
            case .kilometer:
                return 1.0 / Constants.kilometerToMeter
            case .feet:
                return Constants.meterToFeet
            case .mile:
                return Constants.meterToFeet / Constants.mileToFeet
            }
        }

        /// Returns a string containing target distance unit.
        var stringUnit: String {
            switch self {
            case .meter:
                return "m"
            case .kilometer:
                return "km"
            case .feet:
                return "f"
            case .mile:
                return "mi"
            }
        }

        /// Returns whether a fraction digit should be displayed or not.
        var useFractionDigit: Bool {
            switch self {
            case .meter, .feet:
                return false
            case .kilometer, .mile:
                return true
            }
        }

        /// Returns preferred unit for a distance according to preferences and given value.
        static func type(for distance: Double) -> DistanceType {
            if isMetric {
                let distanceRounded = round(distance)
                if distanceRounded < Constants.meterCutoff {
                    return .meter
                } else {
                    return .kilometer
                }
            } else { // Imperial.
                let resultDistance = distance * Constants.meterToFeet
                let distanceRounded = round(resultDistance)
                if distanceRounded < Constants.feetCutoff {
                    return .feet
                } else {
                    return .mile
                }
            }
        }
    }

    /// This is used to get parameters that are associated with a specific speed unit.
    private enum SpeedType {
        case meterPerSecond
        case feetPerSecond

        /// Returns a factor for converting from meter per second to target speed unit.
        var conversionFactor: Double {
            switch self {
            case .meterPerSecond:
                return 1
            case .feetPerSecond:
                return Constants.meterToFeet
            }
        }

        /// Returns a string containing target speed unit.
        var stringUnit: String {
            switch self {
            case .meterPerSecond:
                return "m/s"
            case .feetPerSecond:
                return "f/s"
            }
        }

        /// Returns preferred unit for speed according to preferences.
        static func type() -> SpeedType {
            if isMetric {
                return .meterPerSecond
            } else {
                return .feetPerSecond
            }
        }
    }

    // MARK: - Distance Funcs
    /// Converts a distance value from meter to current display unit and displays its unit.
    ///
    /// - Parameters:
    ///    - distance: distance in meter (Float)
    /// - Returns: a string containing the value and the unit, seperated by a whitespace
    static func stringDistanceWithFloat(_ distance: Float) -> String {
        return stringDistanceWithDouble(Double(distance))
    }

    /// Converts a distance value from meter to current display unit and displays its unit.
    ///
    /// - Parameters:
    ///    - distance: distance in meter (Double)
    ///    - spacing: boolean to add or remove spacing between value and unit
    ///    - useFractionDigit: `true` to allow 1 fraction digit, `false` to disable fraction digit,
    ///    `nil` to automatically enable or disable fraction digit
    /// - Returns: a string containing the value and the unit, seperated by a whitespace
    public static func stringDistanceWithDouble(_ distance: Double,
                                                spacing: Bool = true,
                                                useFractionDigit: Bool? = nil) -> String {
        var convertedDistance = NSNumber(value: doubleDistanceWithDouble(distance))
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        switch unitSetting {
        case .auto:
            numberFormatter.locale = Locale.current
        case .metric:
            numberFormatter.groupingSeparator = Style.whiteSpace
        case .imperial:
            numberFormatter.groupingSeparator = Style.comma
        }
        if useFractionDigit ?? DistanceType.type(for: distance).useFractionDigit {
            numberFormatter.decimalSeparator = Style.dot
            numberFormatter.maximumFractionDigits = 1
        } else {
            numberFormatter.maximumFractionDigits = 0
            convertedDistance = NSNumber(value: Int(convertedDistance.doubleValue.rounded()))
        }
        let formattedValue = numberFormatter.string(from: convertedDistance) ?? Style.dash

        return String(format: spacing ? "%@ %@" : "%@%@",
                      formattedValue,
                      stringDistanceUnitWithDouble(distance))
    }

    /// Rounds a distance to a new distance from current unit.
    ///
    /// - Parameters:
    ///    - distance: distance in meter (Double)
    /// - Returns: a distance rounded
    static func roundedDistanceWithDouble(_ distance: Double) -> Double {
        let type = DistanceType.type(for: distance)
        return UnitHelper.doubleDistanceWithDouble(distance).rounded(toPlaces: type.useFractionDigit ? 1 : 0) / type.conversionFactor
    }

    /// Converts a distance value from meter to current display unit (with formatting).
    /// (used for FP / T&F slider)
    ///
    /// - Parameters:
    ///    - distance: distance in meter (Double)
    /// - Returns: String containing the formatted value
    static func formattedStringDistanceWithDouble(_ distance: Double) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        switch unitSetting {
        case .auto:
            numberFormatter.locale = Locale.current
        case .metric:
            numberFormatter.groupingSeparator = Style.whiteSpace
        case .imperial:
            numberFormatter.groupingSeparator = Style.comma
        }
        if DistanceType.type(for: distance).useFractionDigit {
            numberFormatter.decimalSeparator = Style.dot
            numberFormatter.minimumFractionDigits = 2
            numberFormatter.maximumFractionDigits = 2
        } else {
            numberFormatter.maximumFractionDigits = 0
        }
        return numberFormatter.string(from: NSNumber(value: doubleDistanceWithDouble(distance))) ?? Style.dash
    }

    /// Converts a distance value from meter to current display unit.
    ///
    /// - Parameters:
    ///    - distance: distance in meter (Double)
    /// - Returns: Double containing the value for current display unit
    static func doubleDistanceWithDouble(_ distance: Double) -> Double {
        return distance * DistanceType.type(for: distance).conversionFactor
    }

    /// Returns the ideal unit for given distance.
    ///
    /// - Parameters:
    ///    - distance: distance in meter
    /// - Returns: string containing ideal unit
    static func stringDistanceUnitWithDouble(_ distance: Double) -> String {
        return DistanceType.type(for: distance).stringUnit
    }

    /// Returns current common display unit for distance.
    ///
    /// - Returns: string containing unit
    public static func stringDistanceUnit() -> String {
        return isMetric ? "m": "f"
    }

    // MARK: - Speed Funcs
    /// Converts a speed value from meter per second to current display unit.
    ///
    /// - Parameters:
    ///    - speed: speed in meter per second (Double)
    /// - Returns: Double containing the result value
    static func doubleSpeedWithDouble(_ speed: Double) -> Double {
        return speed * SpeedType.type().conversionFactor
    }

    /// Converts a speed value from meter per second to current display unit and displays its unit.
    ///
    /// - Parameters:
    ///    - speed: speed in meter per second (Float)
    /// - Returns: a string containing the value and the unit, seperated by a whitespace
    static func stringSpeedWithFloat(_ speed: Float) -> String {
        return stringSpeedWithDouble(Double(speed))
    }

    /// Converts a speed value from meter per second to current display unit and displays its unit.
    ///
    /// - Parameters:
    ///    - speed: speed in meter per second (Float)
    /// - Returns: a string containing the value and the unit, seperated by a whitespace
    static func stringSpeedWithFloat2f(_ speed: Float) -> String {
        return stringSpeedWithDouble2f(Double(speed))
    }

    /// Converts a speed value from meter per second to current display unit and displays its unit.
    ///
    /// - Parameters:
    ///    - speed: speed in meter per second (Double)
    ///    - spacing: boolean to add or remove spacing between value and unit
    ///    - minimumFractionDigits: the minimum number of decimals (if not `nil`)
    ///    - maximumFractionDigits: the maximum number of decimals (1 by default)
    /// - Returns: a string containing the value and the unit, seperated by a whitespace
    static func stringSpeedWithDouble(_ speed: Double,
                                      spacing: Bool = true,
                                      minimumFractionDigits: Int? = nil,
                                      maximumFractionDigits: Int = 1) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale.current
        numberFormatter.numberStyle = .decimal
        if let minimumFractionDigits = minimumFractionDigits {
            numberFormatter.minimumFractionDigits = minimumFractionDigits
        }
        numberFormatter.maximumFractionDigits = maximumFractionDigits
        let formattedValue = numberFormatter.string(from: NSNumber(value: doubleSpeedWithDouble(speed))) ?? Style.dash
        return String(format: spacing ? "%@ %@" : "%@%@",
                      formattedValue,
                      stringSpeedUnit())
    }

    /// Converts a speed value from meter per second to current display unit and displays its unit containing two decimal.
    ///
    /// - Parameters:
    ///    - speed: speed in meter per second (Double)
    ///    - spacing: boolean to add or remove spacing between value and unit
    /// - Returns: a string containing the value and the unit, seperated by a whitespace
    static func stringSpeedWithDouble2f(_ speed: Double, spacing: Bool = true) -> String {
        let valueString = String(format: "%.2f", doubleSpeedWithDouble(speed))
        return String(format: spacing ? "%@ %@": "%@%@", valueString, stringSpeedUnit())
    }

    /// Returns current common display unit for speed.
    ///
    /// - Returns: string containing unit
    public static func stringSpeedUnit() -> String {
        return SpeedType.type().stringUnit
    }

    /// Creates a string to display a time duration in seconds.
    ///
    /// - Parameters:
    ///    - seconds: value in seconds
    /// - Returns: a string containing the value and the unit
    static func formatSeconds(_ seconds: Double) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale.current
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 1
        let formattedValue = numberFormatter.string(from: NSNumber(value: seconds)) ?? Style.dash
        return String(format: "%@%@",
                      formattedValue,
                      L10n.unitSecond)
    }
}
