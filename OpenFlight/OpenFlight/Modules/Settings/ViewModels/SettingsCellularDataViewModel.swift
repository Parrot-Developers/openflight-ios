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

/// State for in `SettingsCellularDataViewModel`.
final class SettingsCellularDataState: DeviceConnectionState {
    // MARK: - Internal Properties
    /// Tells if the cellular is available or not.
    fileprivate(set) var cellularAvailability: SettingsCellularAvailability = .cellularOff
    /// Tells if the cellular is activated or not.
    fileprivate(set) var isCellularActivated: Bool = true
    /// Tells if the current network selection is manual or auto.
    fileprivate(set) var selectionMode: SettingsCellularSelection = .auto
    /// Tells if the current network selection mode is updating.
    fileprivate(set) var isSelectionUpdating: Bool = false
    /// Tells if the current sim card is inserted or not.
    fileprivate(set) var isSimCardInserted: Bool = false

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
    ///     - selectionMode: tells if the network selection is auto or manual
    ///     - isSelectionUpdating: tells if the network selection is updating
    ///     - isSimCardInserted: tells if the sim card status is inserted
    init(connectionState: DeviceState.ConnectionState,
         selectionMode: SettingsCellularSelection,
         isSelectionUpdating: Bool,
         isSimCardInserted: Bool,
         isCellularActivated: Bool) {
        super.init(connectionState: connectionState)

        self.selectionMode = selectionMode
        self.isSelectionUpdating = isSelectionUpdating
        self.isSimCardInserted = isSimCardInserted
        self.isCellularActivated = isCellularActivated
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? SettingsCellularDataState else { return false }

        return selectionMode == other.selectionMode
            && isSelectionUpdating == other.isSelectionUpdating
            && isSimCardInserted == other.isSimCardInserted
            && isCellularActivated == other.isCellularActivated
    }

    override func copy() -> SettingsCellularDataState {
        return SettingsCellularDataState(connectionState: self.connectionState,
                                         selectionMode: self.selectionMode,
                                         isSelectionUpdating: self.isSelectionUpdating,
                                         isSimCardInserted: self.isSimCardInserted,
                                         isCellularActivated: self.isCellularActivated)
    }
}

/// Cellular data settings view model.
final class SettingsCellularDataViewModel: DroneStateViewModel<SettingsCellularDataState> {
    // MARK: - Private Properties
    private var cellularRef: Ref<Cellular>?

    // MARK: - Internal Properties
    /// Returns the setting entry for cellular access.
    var cellularAccessEntry: SettingEntry {
        return SettingEntry(setting: cellularAvailabilityModel(with: drone?.getPeripheral(Peripherals.cellular)),
                            title: L10n.droneDetailsCellularAccess,
                            itemLogKey: LogEvent.LogKeyAdvancedSettings.cellularAccess)
    }
    /// Returns the setting entry for connection network mode.
    var connectionNetworkModeEntry: SettingEntry {
        return SettingEntry(setting: networkModeModel(),
                            title: L10n.settingsConnectionNetworkMode,
                            itemLogKey: LogEvent.LogKeyAdvancedSettings.networkPreferences)
    }
    /// Returns the setting entry for connection network selection.
    var connectionNetworkSelectionEntry: SettingEntry {
        return SettingEntry(setting: selectionModel(with: drone?.getPeripheral(Peripherals.cellular)),
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
        let copy = state.value.copy()
        if copy.selectionMode == .auto {
            copy.selectionMode = .manual
            state.set(copy)
            guard let apnUrl = Defaults.networkUrl,
                  let apnUsername = Defaults.networkUsername,
                  let apnPassword = Defaults.networkPassword else { return }

            _ = self.drone?.getPeripheral(Peripherals.cellular)?.apnConfigurationSetting.setToManual(url: apnUrl,
                                                                                                     username: apnUsername,
                                                                                                     password: apnPassword)
        } else {
            copy.selectionMode = .auto
            state.set(copy)
            _ = self.drone?.getPeripheral(Peripherals.cellular)?.apnConfigurationSetting.setToAuto()
        }
    }
}

// MARK: - Private Funcs
private extension SettingsCellularDataViewModel {
    /// Starts watcher for cellular.
    func listenCellular(_ drone: Drone) {
        cellularRef = drone.getPeripheral(Peripherals.cellular) { [weak self] cellular in
            self?.updateCellularDataValues(cellular: cellular)
        }
        updateCellularDataValues(cellular: drone.getPeripheral(Peripherals.cellular))
    }
    /// Updates cellular data values if sim card is inserted.
    func updateCellularDataValues(cellular: Cellular?) {
        let copy = state.value.copy()
        copy.isSimCardInserted = cellular?.isSimCardInserted == true
        copy.cellularAvailability = cellular?.cellularAvailability ?? .cellularOff
        copy.isCellularActivated = cellular?.isActivated == true
        copy.isSelectionUpdating = cellular?.apnConfigurationSetting.updating == true
        copy.selectionMode = cellular?.apnConfigurationSetting.isManual == true ? .manual : .auto
        state.set(copy)
    }

    /// Returns a setting model for 4G availability. User can disable cellular access with this setting.
    ///
    /// - Parameters:
    ///     - cellular: current cellular
    /// - Returns: Model for cellular availability setting.
    func cellularAvailabilityModel(with cellular: Cellular?) -> DroneSettingModel {
        return DroneSettingModel(allValues: SettingsCellularAvailability.allValues,
                                 supportedValues: SettingsCellularAvailability.allValues,
                                 currentValue: state.value.cellularAvailability,
                                 isUpdating: cellular?.mode.updating ?? false) { mode in
            guard let mode = mode as? SettingsCellularAvailability else { return }

            switch mode {
            case .cellularOn:
                cellular?.mode.value = .data
                guard let uid = self.drone?.uid,
                      Defaults.dronesListPairingProcessHidden.contains(uid) else {
                    return
                }

                Defaults.dronesListPairingProcessHidden.removeAll(where: { $0 == uid})
            case .cellularOff:
                cellular?.mode.value = .disabled
            }
        }
    }

    /// Creates a model for network selection.
    ///
    /// - Parameters:
    ///     - cellular: cellular peripheral
    /// - Returns: A drone setting model.
    func selectionModel(with cellular: Cellular?) -> DroneSettingModel {
        return DroneSettingModel(allValues: SettingsCellularSelection.allValues,
                                 supportedValues: SettingsCellularSelection.allValues,
                                 currentValue: state.value.selectionMode,
                                 isUpdating: cellular?.apnConfigurationSetting.updating ?? false)
    }

    /// Returns a setting model for 4G network policy. It can be Auto, Cellular or Wi-fi priority.
    func networkModeModel() -> DroneSettingModel {
        guard let currentNetworkMode = drone?.getPeripheral(Peripherals.networkControl) else {
            return DroneSettingModel(allValues: NetworkControlRoutingPolicy.allValues,
                                     supportedValues: NetworkControlRoutingPolicy.allValues,
                                     currentValue: NetworkControlRoutingPolicy.automatic,
                                     isUpdating: false)
        }

        return DroneSettingModel(allValues: NetworkControlRoutingPolicy.allValues,
                                 supportedValues: NetworkControlRoutingPolicy.allValues,
                                 currentValue: currentNetworkMode.routingPolicy.policy,
                                 isUpdating: currentNetworkMode.routingPolicy.updating) { policy in
            guard let strongPolicy = policy as? NetworkControlRoutingPolicy else { return }

            currentNetworkMode.routingPolicy.policy = strongPolicy
        }
    }
}
