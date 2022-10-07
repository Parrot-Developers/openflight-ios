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
import Combine

/// Network settings view model.
final class SettingsNetworkViewModel {
    // MARK: - Published properties

    @Published private(set) var isLoadingDri: Bool = false
    @Published private(set) var errorMessageDri: String?
    @Published private(set) var isNotFlying: Bool = false
    @Published private(set) var channelsOccupations: [WifiChannel: Int] = [:]
    @Published private(set) var currentChannel: WifiChannel?
    @Published private(set) var channelUpdating: Bool = false
    @Published private(set) var isEditing: Bool = false
    @Published private(set) var channelsOccupationIsEnabled = false

    private(set) var wifiScannerPublisher = CurrentValueSubject<WifiScanner?, Never>(nil)
    private(set) var wifiAccessPointPublisher = CurrentValueSubject<WifiAccessPoint?, Never>(nil)
    private(set) var driPublisher = CurrentValueSubject<Dri?, Never>(nil)
    private var droneIsConnectedSubject = CurrentValueSubject<Bool, Never>(false)
    private var droneIsConnectedPublisher: AnyPublisher<Bool, Never> {
        droneIsConnectedSubject.eraseToAnyPublisher()
    }
    private(set) var isChannelsEnabledPublisher = CurrentValueSubject<Bool, Never>(false)

    // MARK: - Private Properties

    private var currentDroneHolder: CurrentDroneHolder
    private var dismissDriAlertSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()

    private(set) var ssidName: String?
    private var channelSelectionMode: SettingsWifiRange = SettingsNetworkPreset.defaultWifiRange
    private var driMode: Bool = false
    private var driModeUpdating: Bool = false
    private var driId: String?
    private var driOperatorId: String?
    private var driKey: String?
    private var isChannelsEnabled: Bool {
        isChannelsEnabledPublisher.value
    }

    // MARK: Ground SDK References

    private var wifiAccessPointRef: Ref<WifiAccessPoint>?
    private var wifiScannerRef: Ref<WifiScanner>?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?
    private var driRef: Ref<Dri>?
    private var connectionStateRef: Ref<DeviceState>?

    init(currentDroneHolder: CurrentDroneHolder) {
        self.currentDroneHolder = currentDroneHolder

        currentDroneHolder.dronePublisher
            .sink { [weak self] drone in
                guard let self = self else { return }

                self.listenConnectionState(drone)
                self.listenFlyingIndicators(drone)
                self.listenWifiScanner(drone)
                self.listenWifiAccessPoint(drone)
                self.listenDri(drone)
                self.updateScanning(drone)
            }
            .store(in: &cancellables)

        wifiScannerPublisher
            .combineLatest(wifiAccessPointPublisher)
            .sink { [weak self] (wifiScanner, wifiAccessPoint) in
                guard let self = self else { return }
                self.channelsOccupations = self.updateOccupationRate(wifiAccessPoint: wifiAccessPoint, wifiScanner: wifiScanner) ?? [WifiChannel: Int]()
            }
            .store(in: &cancellables)

        droneIsConnectedPublisher
            .removeDuplicates()
            .combineLatest($channelUpdating.removeDuplicates())
            .sink { [weak self] in
                guard let self = self else { return }
                let isChannelsEnabled = $0 && !$1
                self.isChannelsEnabledPublisher.value = isChannelsEnabled
                self.channelsOccupationIsEnabled = isChannelsEnabled && self.channelSelectionMode == .manual
            }
            .store(in: &cancellables)
    }

    // MARK: - Computed Properties

    var isSsidNameEnabledPublisher: AnyPublisher<Bool, Never> {
        droneIsConnectedPublisher
            .removeDuplicates()
            .combineLatest($isNotFlying.removeDuplicates())
            .map { $0 && $1 }
            .eraseToAnyPublisher()
    }

    var dismissDriAlertPublisher: AnyPublisher<Void, Never> {
        return dismissDriAlertSubject.eraseToAnyPublisher()
    }

    var driOperatorFullId: String {
        guard let operatorId = driOperatorId,
              let key = driKey
        else { return L10n.settingsConnectionDriOperatorPlaceholder }
        return "\(operatorId) \(key)"
    }

    var driOperatorColor: UIColor {
        guard driOperatorId != nil,
              driKey != nil
        else { return ColorName.disabledTextColor.color }
        return ColorName.secondaryTextColor.color
    }

    var infoHandler: ((SettingMode.Type) -> Void)?
    var editionHandler: (() -> Void)?

    var settingEntries: [SettingEntry] {
        let hasChannelsOccupation = channelsOccupations.isEmpty == false
        var entries: [SettingEntry] = []

        entries = [SettingEntry(setting: SettingsCellType.title,
                                title: L10n.settingsConnectionCellularData),
                   SettingEntry(setting: SettingsCellType.cellularData),
                   SettingEntry(setting: SettingsCellType.title,
                                title: L10n.settingsConnectionWifiLabel),
                   SettingEntry(setting: SettingsCellType.networkName),
                   SettingEntry(setting: wifiRangeModeModel(wifiAccessPoint: wifiAccessPointPublisher.value),
                                title: L10n.settingsConnectionWifiChannel,
                                isEnabled: isChannelsEnabled,
                                itemLogKey: LogEvent.LogKeyAdvancedSettings.wifiBand)]

        if hasChannelsOccupation {
            entries.append(SettingEntry(setting: SettingsCellType.wifiChannels))
        }

        guard let dri = currentDroneHolder.drone.getPeripheral(Peripherals.dri) else {
            // do not display dri settings if not supported by the drone
            return entries
        }

        var subtitle: String?
        if let droneId = driId,
           driMode {
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
        driRef = nil
        connectionStateRef = nil
        currentDroneHolder.drone.getPeripheral(Peripherals.wifiScanner)?.stopScan()
    }

    // MARK: - Internal Funcs
    /// Change wifi channel.
    ///
    /// - Parameters:
    ///     - channel: Wifi channel
    func changeChannel(_ channel: WifiChannel) {
        let wifiAccessPoint = currentDroneHolder.drone.getPeripheral(Peripherals.wifiAccessPoint)
        wifiAccessPoint?.channel.select(channel: channel)
    }

    /// Change password.
    ///
    /// - Parameters:
    ///     - password: new password
    func changePassword(_ password: String) -> Bool {
        return currentDroneHolder.drone.getPeripheral(Peripherals.wifiAccessPoint)?.security.secureWithWpa2(password: password) ?? false
    }

    /// Change Ssid name.
    ///
    /// - Parameters:
    ///     - name: Ssid name
    func changeSsidName(_ name: String) {
        let wifiAccessPoint = currentDroneHolder.drone.getPeripheral(Peripherals.wifiAccessPoint)
        guard wifiAccessPoint?.ssid.value != name else { return }

        wifiAccessPoint?.ssid.value = name
    }

    /// Tells if the user is currently editing textfields.
    ///
    /// - Parameters:
    ///     - isEditing: is editing
    func isEditing(_ isEditing: Bool) {
        self.isEditing = isEditing
    }

    /// Reset wifi channel settings to default.
    func resetSettings() {
        guard isNotFlying else { return }

        let wifiAccessPoint = currentDroneHolder.drone.getPeripheral(Peripherals.wifiAccessPoint)
        wifiAccessPoint?.channel.autoSelect()

        let driMode = currentDroneHolder.drone.getPeripheral(Peripherals.dri)
        driMode?.mode?.value = SettingsNetworkPreset.defaultDriMode
    }
}

// MARK: - Private Funcs
private extension SettingsNetworkViewModel {

    /// Uodates scanning if a drone is conected
    func updateScanning(_ drone: Drone) {
        if drone.isConnected && drone.getPeripheral(Peripherals.wifiScanner)?.scanning == false {
            drone.getPeripheral(Peripherals.wifiScanner)?.startScan()
        }
    }

    /// Helper to update occupation rate array.
    ///
    /// - Parameters:
    ///     - wifiAccessPoint: WifiAccessPoint used to build occupation rate array
    ///     - drone: current drone
    /// - Returns: Occupation rate array.
    func updateOccupationRate(wifiAccessPoint: WifiAccessPoint?, wifiScanner: WifiScanner?) -> [WifiChannel: Int]? {
        return wifiAccessPoint?.channel.availableChannels.reduce([WifiChannel: Int](), { (dict, channel) -> [WifiChannel: Int] in
            var dict = dict
            dict[channel] = wifiScanner?.getOccupationRate(forChannel: channel)
            return dict
        })
    }

    /// Listen flying indicators.
    ///
    /// - Parameter drone: the current drone
    func listenFlyingIndicators(_ drone: Drone) {
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [unowned self] flyingIndicators in
            let flyingState = flyingIndicators?.state ?? .landed
            isNotFlying = flyingState != .flying
        }
    }

    /// Starts watcher for drone's connection state.
    ///
    /// - Parameter drone: the current drone
    func listenConnectionState(_ drone: Drone) {
        connectionStateRef = drone.getState { [weak self] state in
            self?.droneIsConnectedSubject.value = state?.connectionState == .connected
        }
    }

    /// Listen wifi scanner.
    ///
    /// - Parameter drone: the current drone
    func listenWifiScanner(_ drone: Drone) {
        wifiScannerRef = drone.getPeripheral(Peripherals.wifiScanner) { [unowned self] wifiScanner in
            wifiScannerPublisher.send(wifiScanner)
        }
    }

    /// Listen wifi access point.
    ///
    /// - Parameter drone: the current drone
    func listenWifiAccessPoint(_ drone: Drone) {
        wifiAccessPointRef = drone.getPeripheral(Peripherals.wifiAccessPoint) { [unowned self] wifiAccessPoint in
            currentChannel = wifiAccessPoint?.channel.channel
            ssidName = wifiAccessPoint?.ssid.value
            channelUpdating = wifiAccessPoint?.channel.updating ?? false

            if let selectionMode = wifiAccessPoint?.channel.selectionMode {
                channelSelectionMode = selectionMode == .manual ? SettingsWifiRange.manual : SettingsWifiRange.auto
            }
            wifiAccessPointPublisher.send(wifiAccessPoint)
        }
    }

    /// Listens DRI.
    ///
    /// - Parameter drone: the current drone
    func listenDri(_ drone: Drone) {
        driRef = drone.getPeripheral(Peripherals.dri) { [weak self] dri in
            guard let self = self else { return }
            self.driMode = dri?.mode?.value ?? false
            self.driModeUpdating = dri?.mode?.updating ?? false
            self.driId = dri?.droneId?.id
            self.driOperatorId = dri?.type.type?.driId
            self.driKey = dri?.type.type?.key
            switch dri?.type.state {
            case .updating:
                self.driPublisher.send(dri)
            case .failure,
                 .invalid_operator_id:
                guard self.isLoadingDri else {
                    self.driPublisher.send(dri)
                    return
                }
                self.isLoadingDri = false
                self.errorMessageDri = L10n.settingsEditDriErrorInvalidId
                self.driPublisher.send(dri)
            case .configured,
                 .none:
                guard self.isLoadingDri else {
                    self.driPublisher.send(dri)
                    return
                }
                self.dismissDriEdition()
                self.driPublisher.send(dri)
            }
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
                                 currentValue: channelSelectionMode,
                                 isUpdating: wifiAccessPoint?.channel.updating ?? false) { [weak self] _ in
            guard let mode = self?.channelSelectionMode else { return }

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
    ///
    /// - Parameter dri: DRI drone peripheral
    /// - Returns: setting model for DRI
    func driModeModel(dri: Dri) -> DriSettingModel {
        return DriSettingModel(allValues: BroadcastDRISettings.allValues,
                                 supportedValues: BroadcastDRISettings.allValues,
                                 currentValue: dri.mode?.value == true ? BroadcastDRISettings.driOn : BroadcastDRISettings.driOff,
                                 isUpdating: dri.mode?.updating ?? false) { setting in
            guard let driSetting = setting as? BroadcastDRISettings else { return }

            dri.mode?.value = driSetting == .driOn
        }
    }
}

// MARK: - DRI Edition
extension SettingsNetworkViewModel {
    /// Dismisses the DRI edition
    func dismissDriEdition() {
        isLoadingDri = false
        errorMessageDri = nil
        dismissDriAlertSubject.send()
    }

    /// Submits the DRI operator id and the key
    ///
    /// - Parameters:
    ///    - driId: DRI operator id
    ///    - driKey: DRI key
    ///    - driIdLength: DRI operator id length
    ///    - driKeyLength: DRI key length
    func submitDRI(driId: String?, driKey: String?, driIdLength: Int, driKeyLength: Int) {
        guard let dri = currentDroneHolder.drone.getPeripheral(Peripherals.dri),
              let config = validateUserEntries(driId: driId,
                                               driKey: driKey,
                                               driIdLength: driIdLength,
                                               driKeyLength: driKeyLength)
        else { return }
        isLoadingDri = true
        dri.type.type = config
    }

    /// Checks user entries validity and creates a DRI type config with them.
    ///
    /// - Parameters:
    ///    - driId: DRI operator id
    ///    - driKey: DRI key
    ///    - driIdLength: DRI operator id length
    ///    - driKeyLength: DRI key length
    /// - Returns: DRI type config, nil if user entries or config are invalid.
    private func validateUserEntries(driId: String?, driKey: String?, driIdLength: Int, driKeyLength: Int) -> DriTypeConfig? {
        guard let driId = driId,
              driId.count == driIdLength else {
                  errorMessageDri = L10n.settingsEditDriErrorOperatorIdLength
            return nil
        }

        guard let driKey = driKey,
              driKey.count == driKeyLength else {
            errorMessageDri = L10n.settingsEditDriErrorKeyLength
            return nil
        }

        guard let config = validConfig(for: driId, and: driKey) else {
            errorMessageDri = L10n.settingsEditDriErrorInvalidId
            return nil
        }

        return config
    }

    /// Creates valid config with given id and key.
    ///
    /// - Parameters:
    ///    - driId: DRI operator id
    ///    - driKey: DRI key
    /// - Returns: DRI type config if valid, nil otherwise
    private func validConfig(for driId: String, and driKey: String) -> DriTypeConfig? {
        let operatorId = String(format: "%@-%@", driId, driKey)
        let config = DriTypeConfig.en4709_002(operatorId: operatorId)
        return config.isValid ? config : nil
    }
}
