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
import SwiftyUserDefaults

/// Class which provides log methods.
public class LogEvent {
    // MARK: - Public Enums
    /// Enumerates all log events types.
    public enum Event {
        /// Button press event with only name and no value.
        case simpleButton(_ itemName: String)
        /// Button press event with name and value.
        case button(item: String, value: String)
        /// A screen open event.
        case screen(_ screenName: String)
        /// App lifecycle event.
        case lifecycle(_ event: String, info: [String: String]? = nil)
        /// Corrupted data sanitizer event
        case sanityCheck(_ event: String, info: [String: String]? = nil)
        /// 3rd party integrations event.
        case thirdParty(event: String, party: String, info: [String: String]? = nil)
        /// Alert event.
        case alert(type: String, info: [String: String]? = nil)

        /// Log name according to event type.
        var name: String {
            switch self {
            case .button, .simpleButton:
                return "BUTTON"
            case .screen:
                return "SCREEN"
            case .lifecycle:
                return "LIFECYCLE"
            case .sanityCheck:
                return "SANITY_CHECK"
            case .thirdParty:
                return "3RD_PARTY"
            case .alert:
                return "ALERT"
            }
        }
    }

    /// Log event when user do actions on an item or displays a new screen.
    ///
    /// - Parameters:
    ///     - event: Determines type of event to be logged.
    public static func log(_ event: Event) {
        let gsdk: GroundSdk = GroundSdk()
        let peripheral = gsdk.getFacility(Facilities.eventLogger)
        let message: String

        switch event {
        case .screen(let screen):
            message = "EVT:\(event.name);name='\(screen)'"
        case .simpleButton(let item):
            message = "EVT:\(event.name);name='\(item)'"
        case let .lifecycle(lifecycleEvent, info):
            message = "EVT:\(event.name);event='\(lifecycleEvent)'" + formatInfo(info)
        case let .button(item, value):
            message = "EVT:\(event.name);name='\(item)';value='\(value)'"
        case let .sanityCheck(dataSanityEvent, info):
            message = "EVT:\(event.name);event='\(dataSanityEvent)'" + formatInfo(info)
        case let .thirdParty(event: kind, party: party, info: info):
            message = "EVT:\(event.name);name='\(kind)';value='\(party)'" + formatInfo(info)
        case let .alert(type, info):
            message = "EVT:\(event.name);type='\(type)'" + formatInfo(info)
        }
        peripheral?.log(message.trimmingCharacters(in: .whitespaces))
    }

    /// Formats optional info values.
    ///
    /// - Parameter info: values to format
    private static func formatInfo(_ info: [String: String]?) -> String {
        if let info = info {
            return info
                .map { tuple in ";\(tuple.key)='\(tuple.value)'" }
                .joined()
        } else {
            return ""
        }
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
        else if let setting = settingEntry.setting as? SettingEnum.Type,
                (0...setting.allValues.count - 1).contains(index) {
            newValue = setting.allValues[index].rawValue
        }
        // SpecialSettingModel.
        else if let setting = settingEntry.setting as? DroneSettingModel,
                (0...setting.allValues.count - 1).contains(index) {
            newValue = setting.allValues[index].key
        }

        return newValue
    }
}
