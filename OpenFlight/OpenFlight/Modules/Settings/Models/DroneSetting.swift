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

import Foundation
import GroundSdk

/// Protocol to normalize settings mode.
protocol SettingMode {
    // MARK: - Internal Properties
    /// Setting name.
    var localized: String { get }
    /// Setting key.
    var key: String { get }
    /// Setting image.
    var image: UIImage? { get }
    /// Tells if the setting is used as boolean.
    var usedAsBool: Bool { get }
}

extension SettingMode {
    /// Default usedAsBool is false.
    var usedAsBool: Bool {
        return false
    }
    /// Default image in nil.
    var image: UIImage? {
        nil
    }
}

/// SettingMode helper for Bool type.
extension Bool: SettingMode {
    var usedAsBool: Bool {
        return true
    }

    var localized: String {
        switch self {
        case true:
            return L10n.commonYes
        case false:
            return L10n.commonNo
        }
    }

    var key: String {
        switch self {
        case true:
            return "true"
        case false:
            return "false"
        }
    }
}

/// Dedicated model for drone settings when value changed.
struct DroneSettingModel {
    var allValues: [SettingMode]
    var supportedValues: [SettingMode]
    var currentValue: SettingMode?
    var isUpdating = false
    var forceDisabling = false
    var onSelect: ((SettingMode) -> Void )?
    var selectedIndex: Int {
        return self.allValues.firstIndex(where: {$0.key == self.currentValue?.key}) ?? -1
    }
}
