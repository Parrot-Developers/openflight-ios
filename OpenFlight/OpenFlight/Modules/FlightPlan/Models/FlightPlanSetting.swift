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

/// Class that defines a setting in a flight plan.
public class FlightPlanSetting: FlightPlanSettingType {
    // MARK: - Public Properties
    public var title: String
    public var shortTitle: String?
    public var allValues: [Int]
    public var valueDescriptions: [String]?
    public var currentValue: Int?
    public var type: FlightPlanSettingCellType
    public var key: String
    public var unit: UnitType
    public var step: Double
    public var isDisabled: Bool

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - title: title of the setting
    ///    - shortTitle: setting short title
    ///    - allValues: array of edition setting values
    ///    - valueDescriptions: custom descriptions for values
    ///    - currentValue: current value of the setting
    ///    - type: type of the setting
    ///    - key: key of the setting
    ///    - unit: unit of the setting
    ///    - step: step between values of the setting
    ///    - isDisabled: Tells if the setting must be disabled
    init(title: String,
         shortTitle: String?,
         allValues: [Int],
         valueDescriptions: [String]?,
         currentValue: Int?,
         type: FlightPlanSettingCellType,
         key: String,
         unit: UnitType,
         step: Double,
         isDisabled: Bool) {
        self.title = title
        self.shortTitle = shortTitle
        self.allValues = allValues
        self.valueDescriptions = valueDescriptions
        self.currentValue = currentValue
        self.type = type
        self.key = key
        self.unit = unit
        self.step = step
        self.isDisabled = isDisabled
    }
}

/// Array extension for Flight Plan Setting.
extension Array where Element == FlightPlanSetting {
    /// Returns an array of Flight Plan Light Settings.
    public func toLightSettings() -> [FlightPlanLightSetting] {
        return self.map({ $0.toLightSetting() })
    }
}

/// Class that defines a light setting stored in core data in a flight plan.
public class FlightPlanLightSetting: Codable, Equatable {
    // MARK: - Public Properties
    public var key: String
    public var currentValue: Int?
    public var longValue: Int64?

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - key: key of the setting
    ///    - currentValue: current value of the setting
    public init(key: String, currentValue: Int? = nil) {
        self.key = key
        self.currentValue = currentValue
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - key: key of the setting
    ///    - longValue: current value of the setting as Int64
    public init(key: String, longValue: Int64? = nil) {
        self.key = key
        self.longValue = longValue
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.key = try container.decode(String.self, forKey: .key)
        self.currentValue = try container.decodeIfPresent(Int.self, forKey: .currentValue)
        self.longValue = try container.decodeIfPresent(Int64.self, forKey: .longValue)
    }

    // MARK: - Coding Keys
    private enum CodingKeys: String, CodingKey {
        case key
        case currentValue
        case longValue
    }

    // MARK: - Equatable
    public static func == (lhs: FlightPlanLightSetting, rhs: FlightPlanLightSetting) -> Bool {
        return lhs.key == rhs.key
            && lhs.currentValue == rhs.currentValue
            && lhs.longValue == rhs.longValue
    }
}

/// Array extension for Flight Plan Light Setting.
extension Array where Element == FlightPlanLightSetting {
    /// Returns a value for a key if it exists.
    ///
    /// - Parameters:
    ///    - key: key of the setting
    /// - Returns: The value of the setting if it exists.
    public func value(for key: String) -> Int? {
        if let value = self.first(where: { $0.key == key })?.currentValue {
            return Int(value)
        } else {
            return nil
        }
    }

    /// Returns an Int64 value for a key if it exists.
    ///
    /// - Parameters:
    ///    - key: key of the setting
    /// - Returns: The value as Int64 of the setting if it exists.
    public func longValue(for key: String) -> Int64? {
        if let value = self.first(where: { $0.key == key })?.longValue {
            return Int64(value)
        } else {
            return nil
        }
    }
}
