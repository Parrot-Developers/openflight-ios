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
import SwiftyUserDefaults

// MARK: - Internal Enums
/// Describes different fields for network manual selection which can be edited by user.
enum NetworkManualSelectionField {
    case apnUrl
    case password
    case username

    /// Returns the key of the corresponding default.
    var key: DefaultsKey<String?> {
        switch self {
        case .apnUrl:
            return DefaultsKeys.networkUrlKey
        case .password:
            return DefaultsKeys.networkPasswordKey
        case .username:
            return DefaultsKeys.networkUsernameKey
        }
    }
}

/// State for in `SettingsNetworkSelectionViewModel`.
final class SettingsNetworkSelectionState: DeviceConnectionState {
    // MARK: - Internal Properties
    /// Tell if the current network selection is manual.
    fileprivate(set) var isSelectionManual: Bool = false
    /// Tell if the current network selection mode is updating.
    fileprivate(set) var isSelectionUpdating: Bool = false

    /// Retrieves the network username.
    var username: String? {
        return Defaults.networkUsername
    }

    /// Retrieves the network password.
    var password: String? {
        return Defaults.networkPassword
    }

    /// Retrieves the network custom url.
    var networkUrl: String? {
        return Defaults.networkUrl
    }

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///     - connectionState: drone connection state
    ///     - isSelectionManual: tell if the network selection is auto or manual
    ///     - isSelectionUpdating: tell if the network selection is updating
    init(connectionState: DeviceState.ConnectionState,
         isSelectionManual: Bool,
         isSelectionUpdating: Bool) {
        super.init(connectionState: connectionState)
        self.isSelectionManual = isSelectionManual
        self.isSelectionUpdating = isSelectionUpdating
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? SettingsNetworkSelectionState else {
            return false
        }
        return isSelectionManual == other.isSelectionManual
            && isSelectionUpdating == other.isSelectionUpdating
    }

    override func copy() -> SettingsNetworkSelectionState {
        return SettingsNetworkSelectionState(connectionState: self.connectionState,
                                             isSelectionManual: self.isSelectionManual,
                                             isSelectionUpdating: self.isSelectionUpdating)
    }
}

/// Network cellular selection settings view model.
final class SettingsNetworkSelectionViewModel: DroneStateViewModel<SettingsNetworkSelectionState> {
    // MARK: - Private Properties
    private var cellularRef: Ref<Cellular>?

    // MARK: - Internal Properties
    var settingEntry: SettingEntry {
        return SettingEntry(setting: cellularRef?.value?.apnConfigurationSetting.isApnManual,
                            title: L10n.settingsConnectionNetworkSelection,
                            itemLogKey: LogEvent.LogKeyAdvancedSettings.wifiBand,
                            settingsBoolChoice: SettingsBoolChoice(firstChoiceName: L10n.commonAuto,
                                                                   secondChoiceName: L10n.commonManual))
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)

        listenCellular(drone)
    }

    // MARK: - Internal Funcs
    /// Updates a selected value for manual network. It can be username, password or url.
    ///
    /// - Parameters:
    ///     - value: new value for manual selection.
    ///     - manualSelectionField: the current edited field
    func updateManualValue(value: String?,
                           manualSelectionField: NetworkManualSelectionField) {
        Defaults[key: manualSelectionField.key] = value
        Defaults.isManualApnRequested = true
    }

    /// Switch to auto or manual network selection mode.
    func switchSelectionMode() {
        let selectionNetwork = cellularRef?.value?.apnConfigurationSetting
        selectionNetwork?.isApnManual.value.toggle()
        Defaults.isManualApnRequested = selectionNetwork?.isApnManual.value
    }
}

// MARK: - Private Funcs
private extension SettingsNetworkSelectionViewModel {
    /// Starts watcher for cellular.
    func listenCellular(_ drone: Drone) {
        cellularRef = drone.getPeripheral(Peripherals.cellular) { [weak self] _ in
            self?.updateSelectionMode()
        }
        updateSelectionMode()
    }

    /// Updates selection mode. Can be manual or auto.
    func updateSelectionMode() {
        let selectionNetworkState = cellularRef?.value?.apnConfigurationSetting.isApnManual
        let copy = state.value.copy()
        copy.isSelectionUpdating = selectionNetworkState?.updating == true
        copy.isSelectionManual = selectionNetworkState?.value == true
        state.set(copy)
    }
}
