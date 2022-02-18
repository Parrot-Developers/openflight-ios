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
import GroundSdk
import SwiftyUserDefaults

/// State for in `SettingsCellularDataViewModel`.
final class SettingsCellularDataState: DeviceConnectionState {
    // MARK: - Internal Properties
    /// Tells if the cellular is available or not.
    fileprivate(set) var cellularAvailability: SettingsCellularAvailability = .cellularOff
    /// Whether cellular availability setting is enabled.
    fileprivate(set) var isCellularAvailabilityEnabled: Bool = true
    /// Whether cellular availability setting is updating.
    fileprivate(set) var isCellularAvailabilityUpdating: Bool = false
    /// Tells if the current network selection is manual or auto.
    fileprivate(set) var cellularSelectionMode: SettingsCellularSelection = .auto
    /// Whether cellular network selection setting is enabled.
    fileprivate(set) var isCellularSelectionModeEnabled: Bool = false
    /// Tells if the current network selection mode is updating.
    fileprivate(set) var isCellularSelectionModeUpdating: Bool = false
    /// Current routing policy.
    fileprivate(set) var routingPolicy: NetworkControlRoutingPolicy = .automatic
    /// Whether routing policy setting is updating.
    fileprivate(set) var isRoutingPolicyUpdating: Bool = false
    /// Current cellular network url
    fileprivate(set) var cellularNetworkUrl: String = ""
    /// Current cellular network username
    fileprivate(set) var cellularNetworkUsername: String = ""
    /// Current cellular network password
    fileprivate(set) var cellularNetworkPassword: String = ""

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///     - connectionState: drone connection state
    ///     - cellularAvailability: tells if cellular data are enabled
    ///     - isCellularAvailabilityEnabled: whether cellular availability setting is enabled
    ///     - isCellularAvailabilityUpdating: whether cellular availability setting is updating
    ///     - cellularSelectionMode: tells if the network selection is auto or manual
    ///     - isCellularSelectionModeEnabled: tells if the network selection mode is enabled
    ///     - isCellularSelectionModeUpdating: tells if the network selection is updating
    ///     - routingPolicy: routing policy
    ///     - routingPolicyUpdating: whether routing policy setting is updating
    init(connectionState: DeviceState.ConnectionState,
         cellularAvailability: SettingsCellularAvailability,
         isCellularAvailabilityEnabled: Bool,
         isCellularAvailabilityUpdating: Bool,
         cellularSelectionMode: SettingsCellularSelection,
         isCellularSelectionModeEnabled: Bool,
         isCellularSelectionModeUpdating: Bool,
         routingPolicy: NetworkControlRoutingPolicy,
         isRoutingPolicyUpdating: Bool,
         cellularNetworkUrl: String,
         cellularNetworkUsername: String,
         cellularNetworkPassword: String
    ) {
        super.init(connectionState: connectionState)

        self.cellularAvailability = cellularAvailability
        self.isCellularAvailabilityEnabled = isCellularAvailabilityEnabled
        self.isCellularAvailabilityUpdating = isCellularAvailabilityUpdating
        self.cellularSelectionMode = cellularSelectionMode
        self.isCellularSelectionModeEnabled = isCellularSelectionModeEnabled
        self.isCellularSelectionModeUpdating = isCellularSelectionModeUpdating
        self.routingPolicy = routingPolicy
        self.isRoutingPolicyUpdating = isRoutingPolicyUpdating
        self.cellularNetworkUrl = cellularNetworkUrl
        self.cellularNetworkUsername = cellularNetworkUsername
        self.cellularNetworkPassword = cellularNetworkPassword
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? SettingsCellularDataState else { return false }

        return cellularAvailability == other.cellularAvailability
            && isCellularAvailabilityEnabled == other.isCellularAvailabilityEnabled
            && isCellularAvailabilityUpdating == other.isCellularAvailabilityUpdating
            && cellularSelectionMode == other.cellularSelectionMode
            && isCellularSelectionModeEnabled == other.isCellularSelectionModeEnabled
            && isCellularSelectionModeUpdating == other.isCellularSelectionModeUpdating
            && routingPolicy == other.routingPolicy
            && isRoutingPolicyUpdating == other.isRoutingPolicyUpdating
            && cellularNetworkUrl == other.cellularNetworkUrl
            && cellularNetworkUsername == other.cellularNetworkUsername
            && cellularNetworkPassword == other.cellularNetworkPassword
    }

    override func copy() -> SettingsCellularDataState {
        return SettingsCellularDataState(connectionState: connectionState,
                                         cellularAvailability: cellularAvailability,
                                         isCellularAvailabilityEnabled: isCellularAvailabilityEnabled,
                                         isCellularAvailabilityUpdating: isCellularAvailabilityUpdating,
                                         cellularSelectionMode: cellularSelectionMode,
                                         isCellularSelectionModeEnabled: isCellularSelectionModeEnabled,
                                         isCellularSelectionModeUpdating: isCellularSelectionModeUpdating,
                                         routingPolicy: routingPolicy,
                                         isRoutingPolicyUpdating: isRoutingPolicyUpdating,
                                         cellularNetworkUrl: cellularNetworkUrl,
                                         cellularNetworkUsername: cellularNetworkUsername,
                                         cellularNetworkPassword: cellularNetworkPassword)
    }
}

/// Cellular data settings view model.
final class SettingsCellularDataViewModel: DroneStateViewModel<SettingsCellularDataState> {
    // MARK: - Private Properties
    private var cellularRef: Ref<Cellular>?
    private var networkControlRef: Ref<NetworkControl>?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?

    // MARK: - Internal Properties
    /// Returns the setting entry for cellular access.
    var cellularAccessEntry: SettingEntry {
        return SettingEntry(setting: cellularAvailabilityModel(with: drone?.getPeripheral(Peripherals.cellular)),
                            title: L10n.droneDetailsCellularAccess,
                            isEnabled: state.value.isCellularAvailabilityEnabled,
                            itemLogKey: LogEvent.LogKeyAdvancedSettings.cellularAccess)
    }
    /// Returns the setting entry for connection network mode.
    var connectionNetworkModeEntry: SettingEntry {
        let isEnabled = state.value.cellularAvailability == .cellularOn
        return SettingEntry(setting: networkModeModel(with: drone?.getPeripheral(Peripherals.networkControl)),
                            title: L10n.settingsConnectionNetworkMode,
                            isEnabled: isEnabled,
                            itemLogKey: LogEvent.LogKeyAdvancedSettings.networkPreferences)
    }
    /// Returns the setting entry for connection network selection.
    var connectionNetworkSelectionEntry: SettingEntry {
        return SettingEntry(setting: selectionModel(with: drone?.getPeripheral(Peripherals.cellular)),
                            title: L10n.settingsConnectionNetworkSelection,
                            isEnabled: state.value.isCellularSelectionModeEnabled,
                            itemLogKey: LogEvent.LogKeyAdvancedSettings.wifiBand)
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)

        listenCellular(drone)
        listenNetworkControl(drone)
        listenFlyingIndicators(drone)
    }

    // MARK: - Internal Funcs
    /// Updates all manual values.
    ///
    /// - Parameters:
    ///     - url: the cellular network url
    ///     - username: the cellular network username
    ///     - password: the cellular network password
    func updateAllManualValues(url: String,
                               username: String,
                               password: String) {
        _ = drone?.getPeripheral(Peripherals.cellular)?.apnConfigurationSetting.setToManual(url: url,
                                                                                            username: username,
                                                                                            password: password)
    }
}

// MARK: - Private Funcs
private extension SettingsCellularDataViewModel {

    /// Starts watcher for cellular.
    func listenCellular(_ drone: Drone) {
        cellularRef = drone.getPeripheral(Peripherals.cellular) { [unowned self] cellular in
            let copy = state.value.copy()
            copy.cellularAvailability = cellular?.cellularAvailability ?? .cellularOff
            copy.isCellularAvailabilityUpdating = cellular?.mode.updating == true
            copy.isCellularSelectionModeUpdating = cellular?.apnConfigurationSetting.updating == true
            copy.cellularSelectionMode = cellular?.apnConfigurationSetting.isManual == true ? .manual : .auto
            copy.isCellularSelectionModeEnabled = cellular?.isSimCardInserted == true
            copy.cellularNetworkUrl = cellular?.apnConfigurationSetting.url ?? ""
            copy.cellularNetworkUsername = cellular?.apnConfigurationSetting.username ?? ""
            copy.cellularNetworkPassword = cellular?.apnConfigurationSetting.password ?? ""
            state.set(copy)
            updateCellularAvailabilityEnabled()
        }
    }

    /// Starts watcher for network control.
    func listenNetworkControl(_ drone: Drone) {
        networkControlRef = drone.getPeripheral(Peripherals.networkControl) { [unowned self] networkControl in
            let copy = state.value.copy()
            copy.routingPolicy = networkControl?.routingPolicy.policy ?? .automatic
            copy.isRoutingPolicyUpdating = networkControl?.routingPolicy.updating == true
            state.set(copy)
        }
    }

    /// Starts watcher for flying indicators.
    func listenFlyingIndicators(_ drone: Drone) {
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [unowned self] _ in
            updateCellularAvailabilityEnabled()
        }
    }

    /// Updates availability of cellular availability setting.
    func updateCellularAvailabilityEnabled() {
        let copy = state.value.copy()
        copy.isCellularAvailabilityEnabled = !(drone?.isStateFlying ?? false
                                             && copy.cellularAvailability == .cellularOn)
        state.set(copy)
    }

    /// Updates cellular network selection mode.
    ///
    /// - Parameters:
    ///     - selectionMode: the selection mode
    func updateSelectionMode(selectionMode: SettingsCellularSelection) {
        if selectionMode == .manual {
            _ = drone?.getPeripheral(Peripherals.cellular)?.apnConfigurationSetting.setToManual(url: state.value.cellularNetworkUrl,
                                                                                                username: state.value.cellularNetworkUsername,
                                                                                                password: state.value.cellularNetworkPassword)
        } else {
            _ = drone?.getPeripheral(Peripherals.cellular)?.apnConfigurationSetting.setToAuto()
        }
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
                                 isUpdating: state.value.isCellularAvailabilityUpdating) { [weak self] mode in
            guard let mode = mode as? SettingsCellularAvailability else { return }

            switch mode {
            case .cellularOn:
                cellular?.mode.value = .data
                guard let uid = self?.drone?.uid,
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
                                 currentValue: state.value.cellularSelectionMode,
                                 isUpdating: state.value.isCellularSelectionModeUpdating) { [weak self] selectionMode in
            guard let selectionMode = selectionMode as? SettingsCellularSelection else { return }

            self?.updateSelectionMode(selectionMode: selectionMode)
        }
    }

    /// Returns a setting model for 4G network policy. It can be Auto, Cellular or Wi-fi priority.
    ///
    /// - Parameter networkControl: network control peripheral
    /// - Returns: A drone setting model.
    func networkModeModel(with networkControl: NetworkControl?) -> DroneSettingModel {
        return DroneSettingModel(allValues: NetworkControlRoutingPolicy.allValues,
                                 supportedValues: NetworkControlRoutingPolicy.allValues,
                                 currentValue: state.value.routingPolicy,
                                 isUpdating: state.value.isRoutingPolicyUpdating) { policy in
            guard let strongPolicy = policy as? NetworkControlRoutingPolicy else { return }

            networkControl?.routingPolicy.policy = strongPolicy
        }
    }
}
