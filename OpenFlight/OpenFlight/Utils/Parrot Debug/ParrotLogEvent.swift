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
import SwiftyUserDefaults

/// Class which provides log methods.
public class LogEvent {
    // MARK: - Public Enums
    /// Enumerates all logs type in the app.
    public enum LogType {
        case button
        case screen

        /// Log name according to event type.
        var logName: String {
            switch self {
            case .button:
                return "BUTTON"
            case .screen:
                return "SCREEN"
            }
        }
    }

    /// Log info when user do actions on an item or displays a new screen.
    ///
    /// - Parameters:
    ///     - screen: name of the screen to log
    ///     - itemName: name of the item taped to log
    ///     - newValue: item new value to log
    ///     - logType: Determines type of log
    public static func logAppEvent(screen: String,
                                   itemName: String?,
                                   newValue: String?,
                                   logType: LogType) {
        let gsdk: GroundSdk = GroundSdk()
        let peripheral = gsdk.getFacility(Facilities.eventLogger)
        var message: String = ""

        switch logType {
        case .screen:
            message = "EVT:\(logType.logName);name='\(screen)'"
        default:
            message = "EVT:\(logType.logName);name='\(itemName ?? "")';value='\(newValue ?? "")'"
        }

        peripheral?.log(message.trimmingCharacters(in: .whitespaces))
    }

    /// Get new value of setting for logs according to setting type.
    ///
    /// - Parameters:
    ///     - settingEntry: setting entry for current setting cell
    ///     - index: setting index
    /// - Returns: New formatted value of the settings.
    static func formatNewValue(settingEntry: SettingEntry, index: Int) -> String {
        var newValue: String = ""

        if settingEntry.itemLogKey == LogKeyQuickSettings.streamType
            || settingEntry.itemLogKey == LogKeyQuickSettings.interfaceGrid {
            return String(settingEntry.isEnabled.logValue)
        }

        // BoolSetting.
        if let setting = settingEntry.setting as? BoolSetting {
            newValue = (!setting.value).description
        }
        // DefaultsKey<Bool?>.
        else if (settingEntry.setting as? DefaultsKey<Bool?>) != nil {
            newValue = index == 0 ? false.description : true.description
        }
        // SettingEnum.Type.
        else if let setting = settingEntry.setting as? SettingEnum.Type {
            newValue = setting.allValues[index].rawValue
        }
        // SpecialSettingModel.
        else if let setting = settingEntry.setting as? DroneSettingModel {
            newValue = setting.allValues[index].key
        }

        return newValue
    }
}
