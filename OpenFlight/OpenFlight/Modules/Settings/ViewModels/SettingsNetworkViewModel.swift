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

/// View model used in `SettingsNetworkViewModel`.
final class SettingsNetworkState: DeviceConnectionState {
    // MARK: - Internal Properties
    fileprivate(set) var channelsOccupations: [WifiChannel: Int] = [:]
    fileprivate(set) var currentChannel: WifiChannel?
    /// Tells if user is editing 4G or wifi name settings textfield.
    fileprivate(set) var isEditing: Bool = false
    fileprivate(set) var ssidName: String?
    fileprivate(set) var isNotFlying: Bool = false
    fileprivate(set) var channelSelectionMode: SettingsWifiRange = SettingsNetworkPreset.defaultWifiRange
    fileprivate(set) var channelUpdating: Bool = false
    fileprivate(set) var directConnectionMode = SettingsDirectConnection.disabled
    fileprivate(set) var directConnectionModeUpdating: Bool = false
    fileprivate(set) var driMode: Bool = false
    fileprivate(set) var driModeUpdating: Bool = false
    fileprivate(set) var driId: String?

    // Tells if the wifi channel choice is enabled
    var channelsIsEnabled: Bool {
        isConnected() && !channelUpdating
    }

    // Tells if the channels occupation is enabled
    var channelsOccupationIsEnabled: Bool {
        channelsIsEnabled && channelSelectionMode == .manual
    }

    // Tells if the ssid name cell is enabled
    var ssidNameIsEnabled: Bool { isNotFlying && isConnected() }

    // MARK: - Init
    required init() {
        super.init()
    }

    override init(connectionState: DeviceState.ConnectionState) {
        super.init(connectionState: connectionState)
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? SettingsNetworkState else { return false }

        return isConnected() == other.isConnected() &&
            currentChannel == other.currentChannel &&
            ssidName == other.ssidName &&
            isNotFlying == other.isNotFlying &&
            isEditing == other.isEditing &&
            channelUpdating == other.channelUpdating &&
            directConnectionMode == other.directConnectionMode &&
            directConnectionModeUpdating == other.directConnectionModeUpdating &&
            driMode == other.driMode &&
            driModeUpdating == other.driModeUpdating &&
            driId == other.driId &&
            channelSelectionMode == other.channelSelectionMode &&
            // Compare channelsOccupations arrays.
            zip(channelsOccupations, other.channelsOccupations)
            .enumerated()
            .filter { $1.0 != $1.1 }
            .map { $0 }
            .isEmpty
    }

    override func copy() -> SettingsNetworkState {
        let copy = SettingsNetworkState(connectionState: connectionState)
        copy.channelsOccupations = channelsOccupations
        copy.currentChannel = currentChannel
        copy.isEditing = isEditing
        copy.ssidName = ssidName
        copy.isNotFlying = isNotFlying
        copy.channelUpdating = channelUpdating
        copy.directConnectionMode = directConnectionMode
        copy.directConnectionModeUpdating = directConnectionModeUpdating
        copy.driMode = driMode
        copy.driModeUpdating = driModeUpdating
        copy.driId = driId
        copy.channelSelectionMode = channelSelectionMode
        return copy
    }
}

/// Network settings view model.

final class SettingsNetworkViewModel: DroneStateViewModel<SettingsNetworkState> {
    // MARK: - Private Properties
    private var wifiAccessPointRef: Ref<WifiAccessPoint>?
    private var wifiScannerRef: Ref<WifiScanner>?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?
    private var networkControlRef: Ref<NetworkControl>?
    private var driRef: Ref<Dri>?

    // MARK: - Internal Properties
    var infoHandler: ((SettingMode.Type) -> Void)?
    var settingEntries: [SettingEntry] {
        let hasChannelsOccupation = state.value.channelsOccupations.isEmpty == false
        let channelsIsEnabled = state.value.channelsIsEnabled
        let wifiAccessPoint = drone?.getPeripheral(Peripherals.wifiAccessPoint)
        var entries: [SettingEntry] = []

        entries = [SettingEntry(setting: SettingsCellType.title,
                                title: L10n.settingsConnectionCellularData),
                   SettingEntry(setting: SettingsCellType.cellularData),
                   SettingEntry(setting: SettingsCellType.title,
                                title: L10n.settingsConnectionWifiLabel),
                   SettingEntry(setting: SettingsCellType.networkName),
                   SettingEntry(setting: wifiRangeModeModel(wifiAccessPoint: wifiAccessPoint),
                                title: L10n.settingsConnectionWifiChannel,
                                isEnabled: channelsIsEnabled,
                                itemLogKey: LogEvent.LogKeyAdvancedSettings.wifiBand)]

        if hasChannelsOccupation {
            entries.append(SettingEntry(setting: SettingsCellType.wifiChannels))
        }

        guard let networkControl = drone?.getPeripheral(Peripherals.networkControl) else {
            return entries
        }

        entries.append(SettingEntry(setting: directConnectionModel(networkControl: networkControl),
                                    title: L10n.settingsConnectionDirectConnection))

        guard let dri = drone?.getPeripheral(Peripherals.dri) else {
            // do not display dri settings if not supported by the drone
            return entries
        }

        var subtitle: String?
        if let droneId = state.value.driId,
           state.value.driMode {
            subtitle = L10n.settingsConnectionDriName
                + Style.whiteSpace
                + droneId
        }
        entries.append(SettingEntry(setting: driModeModel(dri: dri),
                                    title: L10n.settingsConnectionBroadcastDri,
                                    subtitle: subtitle,
                                    isEnabled: dri.mode != nil,
                                    showInfo: showDRIPage,
                                    infoText: L10n.settingsConnectionDriLearnMore,
                                    itemLogKey: LogEvent.LogKeyAdvancedSettings.driSetting))

        return entries
    }

    // MARK: - Deinit
    deinit {
        wifiScannerRef = nil
        wifiAccessPointRef = nil
        flyingIndicatorsRef = nil
        networkControlRef = nil
        driRef = nil
        drone?.getPeripheral(Peripherals.wifiScanner)?.stopScan()
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)

        listenFlyingIndicators(drone)
        listenWifiScanner(drone)
        listenWifiAccessPoint(drone)
        listenNetworkControl(drone)
        listenDri(drone)
    }

    override func droneConnectionStateDidChange() {
        if state.value.isConnected() && drone?.getPeripheral(Peripherals.wifiScanner)?.scanning == false {
            drone?.getPeripheral(Peripherals.wifiScanner)?.startScan()
        }
    }

    // MARK: - Internal Funcs
    /// Change wifi channel.
    ///
    /// - Parameters:
    ///     - channel: Wifi channel
    func changeChannel(_ channel: WifiChannel) {
        let wifiAccessPoint = drone?.getPeripheral(Peripherals.wifiAccessPoint)
        wifiAccessPoint?.channel.select(channel: channel)
    }

    /// Change password.
    ///
    /// - Parameters:
    ///     - password: new password
    func changePassword(_ password: String) -> Bool {
        return drone?.getPeripheral(Peripherals.wifiAccessPoint)?.security.secureWithWpa2(password: password) ?? false
    }

    /// Change Ssid name.
    ///
    /// - Parameters:
    ///     - name: Ssid name
    func changeSsidName(_ name: String) {
        let wifiAccessPoint = drone?.getPeripheral(Peripherals.wifiAccessPoint)
        guard wifiAccessPoint?.ssid.value != name else { return }

        wifiAccessPoint?.ssid.value = name
    }

    /// Tells if the user is currently editing textfields.
    ///
    /// - Parameters:
    ///     - isEditing: is editing
    func isEditing(_ isEditing: Bool) {
        let copy = state.value.copy()
        copy.isEditing = isEditing
        state.set(copy)
    }

    /// Reset wifi channel settings to default.
    func resetSettings() {
        guard state.value.isNotFlying else { return }

        let wifiAccessPoint = drone?.getPeripheral(Peripherals.wifiAccessPoint)
        wifiAccessPoint?.channel.autoSelect()

        driRef?.value?.mode?.value = SettingsNetworkPreset.defaultDriMode
    }
}

// MARK: - Private Funcs
private extension SettingsNetworkViewModel {
    /// Helper to update occupation rate array.
    ///
    /// - Parameters:
    ///     - wifiAccessPoint: WifiAccessPoint used to build occupation rate array
    ///     - drone: current drone
    /// - Returns: Occupation rate array.
    func updateOccupationRate(wifiAccessPoint: WifiAccessPoint?, drone: Drone) -> [WifiChannel: Int]? {
        let wifiScanner = drone.getPeripheral(Peripherals.wifiScanner)
        return wifiAccessPoint?.channel.availableChannels.reduce([WifiChannel: Int](), { (dict, channel) -> [WifiChannel: Int] in
            var dict = dict
            dict[channel] = wifiScanner?.getOccupationRate(forChannel: channel)
            return dict
        })
    }

    /// Listen flying indicators.
    func listenFlyingIndicators(_ drone: Drone) {
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [unowned self] flyingIndicators in
            let flyingState = flyingIndicators?.state ?? .landed
            let copy = state.value.copy()
            copy.isNotFlying = flyingState != .flying
            state.set(copy)
        }
    }

    /// Listen wifi scanner.
    func listenWifiScanner(_ drone: Drone) {
        wifiScannerRef = drone.getPeripheral(Peripherals.wifiScanner) { [unowned self] _ in
            guard let wifiAccessPoint = drone.getPeripheral(Peripherals.wifiAccessPoint) else {
                return
            }
            let copy = state.value.copy()
            copy.channelsOccupations = updateOccupationRate(wifiAccessPoint: wifiAccessPoint, drone: drone) ?? [WifiChannel: Int]()
            state.set(copy)
        }
    }

    /// Listen wifi access point.
    func listenWifiAccessPoint(_ drone: Drone) {
        wifiAccessPointRef = drone.getPeripheral(Peripherals.wifiAccessPoint) { [unowned self] wifiAccessPoint in
            let copy = state.value.copy()
            copy.channelsOccupations = updateOccupationRate(wifiAccessPoint: wifiAccessPoint, drone: drone) ?? [WifiChannel: Int]()
            copy.currentChannel = wifiAccessPoint?.channel.channel
            copy.ssidName = wifiAccessPoint?.ssid.value
            copy.channelUpdating = wifiAccessPoint?.channel.updating ?? false

            if let selectionMode = wifiAccessPoint?.channel.selectionMode {
                copy.channelSelectionMode = selectionMode == .manual ? SettingsWifiRange.manual : SettingsWifiRange.auto
            }

            state.set(copy)
        }
    }

    /// Listens to network control.
    ///
    /// - Parameter drone: current drone
    func listenNetworkControl(_ drone: Drone) {
        networkControlRef = drone.getPeripheral(Peripherals.networkControl) { [unowned self] networkControl in
            let copy = state.value.copy()
            copy.directConnectionMode = networkControl?.directConnection.mode == .legacy ? .enabled : .disabled
            copy.directConnectionModeUpdating = networkControl?.directConnection.updating ?? false
            state.set(copy)
        }
    }

    /// Listens DRI.
    ///
    /// - Parameters:
    ///     - drone: current drone
    func listenDri(_ drone: Drone) {
        driRef = drone.getPeripheral(Peripherals.dri) { [unowned self] dri in
            let copy = state.value.copy()
            copy.driMode = dri?.mode?.value ?? false
            copy.driModeUpdating = dri?.mode?.updating ?? false
            copy.driId = dri?.droneId?.id
            state.set(copy)
        }
    }

    /// Show explanatory DRI page.
    func showDRIPage() {
        infoHandler?(BroadcastDRISettings.self)
    }

    /// Dedicated Model to match SettingEntry.
    ///
    /// - Parameters:
    ///     - wifiAccessPoint: WifiAccessPoint used to build occupation rate array
    /// - Returns: Model for wifi range setting.
    func wifiRangeModeModel(wifiAccessPoint: WifiAccessPoint?) -> DroneSettingModel? {
        return DroneSettingModel(allValues: SettingsWifiRange.allValues,
                                 supportedValues: SettingsWifiRange.allValues,
                                 currentValue: self.state.value.channelSelectionMode,
                                 isUpdating: wifiAccessPoint?.channel.updating ?? false) { [weak self] _ in
            guard let mode = self?.state.value.channelSelectionMode else { return }

            switch mode {
            case .auto:
                guard let channel = wifiAccessPoint?.channel.channel else { return }

                wifiAccessPoint?.channel.select(channel: channel)
            case .manual:
                wifiAccessPoint?.channel.autoSelect()
            }
        }
    }

    /// Returns a setting model for direct connection.
    ///
    /// - Parameter networkControl: network control peripheral
    /// - Returns: setting model for direct connection
    func directConnectionModel(networkControl: NetworkControl) -> DroneSettingModel {
        return DroneSettingModel(allValues: SettingsDirectConnection.allValues,
                                 supportedValues: SettingsDirectConnection.allValues,
                                 currentValue: networkControl.directConnection.mode == .legacy ?
                                 SettingsDirectConnection.enabled : SettingsDirectConnection.disabled,
                                 isUpdating: networkControl.directConnection.updating) { setting in
            guard let directConnectionSetting = setting as? SettingsDirectConnection else { return }

            networkControl.directConnection.mode = directConnectionSetting == .enabled ? .legacy : .secure
        }
    }

    /// Returns a setting model for broadcast DRI. It can be ON showing drone PI, or OFF.
    ///
    /// - Parameter dri: DRI drone peripheral
    /// - Returns: setting model for DRI
    func driModeModel(dri: Dri) -> DroneSettingModel {
        return DroneSettingModel(allValues: BroadcastDRISettings.allValues,
                                 supportedValues: BroadcastDRISettings.allValues,
                                 currentValue: dri.mode?.value == true ? BroadcastDRISettings.driOn : BroadcastDRISettings.driOff,
                                 isUpdating: dri.mode?.updating ?? false) { setting in
            guard let driSetting = setting as? BroadcastDRISettings else { return }

            dri.mode?.value = driSetting == .driOn
        }
    }
}
