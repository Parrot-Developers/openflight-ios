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

/// Utility extension for `CameraEv2Compensation`.
extension Camera2EvCompensation: BarItemMode, RulerDisplayable, Sortable {
    // MARK: - BarItemMode
    public var title: String {
        return String(format: "%@ %@", shortTitle, L10n.unitEv)
    }

    var shortTitle: String {
        switch self {
        case .evMinus3_00:
            return "-3.0"
        case .evMinus2_67:
            return "-2.7"
        case .evMinus2_33:
            return "-2.3"
        case .evMinus2_00:
            return "-2.0"
        case .evMinus1_67:
            return "-1.7"
        case .evMinus1_33:
            return "-1.3"
        case .evMinus1_00:
            return "-1.0"
        case .evMinus0_67:
            return "-0.7"
        case .evMinus0_33:
            return "-0.3"
        case .ev0_00:
            return "0.0"
        case .ev0_33:
            return "+0.3"
        case .ev0_67:
            return "+0.7"
        case .ev1_00:
            return "+1.0"
        case .ev1_33:
            return "+1.3"
        case .ev1_67:
            return "+1.7"
        case .ev2_00:
            return "+2.0"
        case .ev2_33:
            return "+2.3"
        case .ev2_67:
            return "+2.7"
        case .ev3_00:
            return "+3.0"
        }
    }

    public var image: UIImage? {
        return nil
    }

    public var key: String {
        return description
    }

    public static var allValues: [BarItemMode] {
        return allCases.sorted()
    }

    public var subModes: [BarItemSubMode]? {
        return nil
    }

    // MARK: - RulerDisplayable
    var rulerText: String? {
        switch self {
        case .evMinus3_00, .evMinus2_00, .evMinus1_00, .ev1_00, .ev2_00, .ev3_00:
            return shortTitle
        case .ev0_00:
            return "0"
        default:
            return Style.pipe
        }
    }

    var rulerBackgroundColor: UIColor? {
        switch self {
        case .ev0_00:
            return ColorName.defaultTextColor.color
        default:
            return nil
        }
    }

    public var logKey: String {
        return LogEvent.LogKeyHUDBottomBarButton.evCompensationSetting.name
    }

    /// Returns compensation for an index, based on all compensations available.
    public static func compensationForIndex(_ index: Int) -> Camera2EvCompensation {
        guard index < sortedCases.count else { return defaultValue }

        return availableValues[index]
    }

    /// List of available Values.
    public static var availableValues: [Camera2EvCompensation] {
        return sortedCases
    }

    /// Default value.
    public static var defaultValue: Camera2EvCompensation {
        .ev0_00
    }

    // MARK: - Sortable
    public static var sortedCases: [Camera2EvCompensation] {
        return [.evMinus3_00, .evMinus2_67, .evMinus2_33, .evMinus2_00, .evMinus1_67, .evMinus1_33,
                .evMinus1_00, .evMinus0_67, .evMinus0_33, .ev0_00, .ev0_33, .ev0_67, .ev1_00,
                .ev1_33, .ev1_67, .ev2_00, .ev2_33, .ev2_67, .ev3_00]
    }
}
