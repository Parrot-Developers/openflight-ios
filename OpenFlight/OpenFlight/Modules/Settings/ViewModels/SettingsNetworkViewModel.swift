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

/// View model used in `SettingsNetworkViewModel`.
final class SettingsNetworkState: DeviceConnectionState {
    // MARK: - Internal Properties
    fileprivate(set) var channelsOccupations: [WifiChannel: Int] = [:]
    fileprivate(set) var currentChannel: WifiChannel?
    /// Tells if user is editing 4G or wifi name settings textfield.
    fileprivate(set) var isEditing: Bool = false
    fileprivate(set) var ssidName: String?
    fileprivate(set) var isLanded: Bool = false
    fileprivate(set) var channelSelectionMode: SettingsWifiRange = SettingsWifiRangePreset.defaultWifiRange
    fileprivate(set) var isUpdating: Bool = false

    var isEnabled: Bool {
        return channelsOccupations.isEmpty == false && isLanded
    }

    // MARK: - Init
    required init() {
        super.init()
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? SettingsNetworkState else { return false }

        return currentChannel == other.currentChannel &&
            ssidName == other.ssidName &&
            isLanded == other.isLanded &&
            isEditing == other.isEditing &&
            isUpdating == other.isUpdating &&
            channelSelectionMode == other.channelSelectionMode &&
            // Compare channelsOccupations arrays.
            zip(channelsOccupations, other.channelsOccupations)
            .enumerated()
            .filter { $1.0 != $1.1 }
            .map { $0 }
            .isEmpty
    }

    override func copy() -> SettingsNetworkState {
        let copy = SettingsNetworkState()
        copy.channelsOccupations = self.channelsOccupations
        copy.currentChannel = self.currentChannel
        copy.isEditing = self.isEditing
        copy.ssidName = self.ssidName
        copy.isLanded = self.isLanded
        copy.isUpdating = self.isUpdating
        copy.channelSelectionMode = self.channelSelectionMode

        return copy
    }
}

/// Network settings view model.

final class SettingsNetworkViewModel: DroneStateViewModel<SettingsNetworkState> {
    // MARK: - Private Properties
    private var wifiAccessPointRef: Ref<WifiAccessPoint>?
    private var wifiScannerRef: Ref<WifiScanner>?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?
    private var cellularRef: Ref<Cellular>?

    // MARK: - Internal Properties
    var infoHandler: ((SettingMode.Type) -> Void)?
    var settingEntries: [SettingEntry] {
        let isEnabled = self.state.value.isEnabled
        let wifiAccessPoint = drone?.getPeripheral(Peripherals.wifiAccessPoint)
        var entries: [SettingEntry] = []

        entries = [SettingEntry(setting: SettingsCellType.title,
                                title: L10n.settingsConnectionCellularData),
                   SettingEntry(setting: SettingsCellType.cellularData),
                   SettingEntry(setting: SettingsCellType.title,
                                title: L10n.settingsConnectionWifiLabel),
                   SettingEntry(setting: SettingsCellType.networkName),
                   SettingEntry(setting: wifiRangeModeModel(wifiAccessPoint: wifiAccessPoint),
                                title: L10n.settingsConnectionWifiRange,
                                isEnabled: isEnabled,
                                itemLogKey: LogEvent.LogKeyAdvancedSettings.wifiBand)]

        if isEnabled {
            entries.append(SettingEntry(setting: SettingsCellType.wifiChannels))
        }

        guard let dri = drone?.getPeripheral(Peripherals.dri) else { return entries }

        var subtitle: String?
        if dri.mode?.value == true && dri.droneId?.id != nil {
            subtitle = L10n.settingsConnectionDriName
                + Style.whiteSpace
                + (dri.droneId?.id ?? Defaults.lastDriId ?? Style.dash)
        }
        entries.append(SettingEntry(setting: driModeModel(),
                                    title: L10n.settingsConnectionBroadcastDri,
                                    subtitle: subtitle,
                                    isEnabled: drone?.isConnected == true,
                                    showInfo: showDRIPage,
                                    infoText: L10n.settingsConnectionDriLearnMore,
                                    itemLogKey: LogEvent.LogKeyAdvancedSettings.driSetting))

        return entries
    }

    // MARK: - Deinit
    deinit {
        drone?.getPeripheral(Peripherals.wifiScanner)?.stopScan()
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)

        listenFlyingIndicators(drone)
        listenWifiScanner(drone)
        listenWifiAccessPoint(drone)
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
        let copy = self.state.value.copy()
        copy.isEditing = isEditing
        self.state.set(copy)
    }

    /// Reset wifi channel settings to default.
    func resetSettings() {
        guard self.state.value.isEnabled else { return }

        let wifiAccessPoint = drone?.getPeripheral(Peripherals.wifiAccessPoint)
        wifiAccessPoint?.channel.autoSelect()
    }
}

// MARK: - Drone Setting Model helpers
extension SettingsNetworkViewModel {
    /// Updates manual selection with saved datas.
    func updateApnConfigurationIfNeeded() {
        guard Defaults.isManualApnRequested == true,
              let apnUrl = Defaults.networkUrl,
              let apnUsername = Defaults.networkUsername,
              let apnPassword = Defaults.networkPassword else { return }

        _ = drone?.getPeripheral(Peripherals.cellular)?.apnConfigurationSetting.setToManual(url: apnUrl,
                                                                                            username: apnUsername,
                                                                                            password: apnPassword)
        Defaults.isManualApnRequested = false
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
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [weak self] flyingState in
            let copy = self?.state.value.copy()
            copy?.isLanded = flyingState?.state == .landed
            self?.state.set(copy)
        }
    }

    /// Listen wifi scanner.
    func listenWifiScanner(_ drone: Drone) {
        wifiScannerRef = drone.getPeripheral(Peripherals.wifiScanner) { [weak self] _ in
            guard let copy = self?.state.value.copy(),
                  let wifiAccessPoint = self?.drone?.getPeripheral(Peripherals.wifiAccessPoint) else {
                return
            }

            copy.channelsOccupations = self?.updateOccupationRate(wifiAccessPoint: wifiAccessPoint, drone: drone) ?? [WifiChannel: Int]()
            self?.state.set(copy)
        }
        drone.getPeripheral(Peripherals.wifiScanner)?.startScan()
    }

    /// Listen wifi access point.
    func listenWifiAccessPoint(_ drone: Drone) {
        wifiAccessPointRef = drone.getPeripheral(Peripherals.wifiAccessPoint) { [weak self] wifiAccessPoint in
            guard let copy = self?.state.value.copy() else { return }

            copy.channelsOccupations = self?.updateOccupationRate(wifiAccessPoint: wifiAccessPoint, drone: drone) ?? [WifiChannel: Int]()
            copy.currentChannel = wifiAccessPoint?.channel.channel
            copy.ssidName = wifiAccessPoint?.ssid.value
            copy.isUpdating = wifiAccessPoint?.channel.updating ?? false

            if let selectionMode = wifiAccessPoint?.channel.selectionMode {
                copy.channelSelectionMode = selectionMode == .manual ? SettingsWifiRange.manual : SettingsWifiRange.auto
            }

            self?.state.set(copy)
        }
    }

    /// Show explanatory DRI page.
    func showDRIPage() {
        self.infoHandler?(BroadcastDRISettings.self)
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

    /// Returns a setting model for broadcast DRI. It can be ON showing drone PI, or OFF.
    func driModeModel() -> DroneSettingModel {
        guard let currentDri = drone?.getPeripheral(Peripherals.dri) else {
            return DroneSettingModel(allValues: BroadcastDRISettings.allValues,
                                     supportedValues: BroadcastDRISettings.allValues,
                                     currentValue: BroadcastDRISettings.driOff,
                                     isUpdating: false)
        }

        return DroneSettingModel(allValues: BroadcastDRISettings.allValues,
                                 supportedValues: BroadcastDRISettings.allValues,
                                 currentValue: currentDri.mode?.value == true ? BroadcastDRISettings.driOn : BroadcastDRISettings.driOff,
                                 isUpdating: currentDri.mode?.updating) { dri in
            guard let strongDRI = dri as? BroadcastDRISettings else { return }

            currentDri.mode?.value = strongDRI == .driOn
        }
    }
}
