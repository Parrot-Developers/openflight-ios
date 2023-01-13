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

/// Cellular data settings view model.
final class SettingsCellularDataViewModel {

    // MARK: - Published Properties
    /// Tells if the current network selection is manual or auto.
    @Published private(set) var cellularSelectionMode: SettingsCellularSelection?
    /// Current cellular network url
    @Published private(set) var cellularNetworkUrl: String = ""
    /// Current cellular network username
    @Published private(set) var cellularNetworkUsername: String = ""
    /// Current cellular network password
    @Published private(set) var cellularNetworkPassword: String = ""

    private(set) var cellularPublisher = CurrentValueSubject<Cellular?, Never>(nil)
    private(set) var networkControlPublisher = CurrentValueSubject<NetworkControl?, Never>(nil)
    private(set) var flyingIndicatorPublisher = CurrentValueSubject<FlyingIndicators?, Never>(nil)
    private(set) var cellularAccessEntryPublisher = CurrentValueSubject<SettingEntry?, Never>(nil)
    private(set) var connectionNetworkModeEntryPublisher = CurrentValueSubject<SettingEntry?, Never>(nil)
    private(set) var connectionNetworkSelectionEntryPublisher = CurrentValueSubject<SettingEntry?, Never>(nil)

    // MARK: - Private Properties
    private var currentDroneHolder: CurrentDroneHolder
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Ground SDK References

    private var cellularRef: Ref<Cellular>?
    private var droneStateRef: Ref<DeviceState>?
    private var networkControlRef: Ref<NetworkControl>?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?

    init(currentDroneHolder: CurrentDroneHolder) {
        self.currentDroneHolder = currentDroneHolder

        currentDroneHolder.dronePublisher
            .sink { [weak self] drone in
                guard let self = self else { return }
                self.listenConnectionState(drone)
                self.listenCellular(drone)
                self.listenNetworkControl(drone)
                self.listenFlyingIndicators(drone)
            }
            .store(in: &cancellables)

        cellularPublisher
            .combineLatest(flyingIndicatorPublisher)
            .sink { [weak self] (cellular, flyingIndicator) in
                guard let self = self else { return }
                let cellularAvailability = cellular?.cellularAvailability ?? .cellularOff
                let cellularAvailabilityEnabled = !(flyingIndicator?.flyingState == .flying
                                                    && cellularAvailability == .cellularOn)
                self.cellularAccessEntryPublisher.send(SettingEntry(setting: self.cellularAvailabilityModel(with: cellular),
                                                               title: L10n.droneDetailsCellularAccess,
                                                               isEnabled: cellularAvailabilityEnabled,
                                                               itemLogKey: LogEvent.LogKeyAdvancedSettings.cellularAccess))
            }
            .store(in: &cancellables)

        cellularPublisher
            .combineLatest(networkControlPublisher)
            .sink { [weak self] (cellular, networkControl) in
                guard let self = self else { return }
                let isEnabled = cellular?.cellularAvailability == .cellularOn
                self.connectionNetworkModeEntryPublisher.send(SettingEntry(setting: self.networkModeModel(with: networkControl),
                                                                           title: L10n.settingsConnectionNetworkMode,
                                                                           isEnabled: isEnabled,
                                                                           itemLogKey: LogEvent.LogKeyAdvancedSettings.networkPreferences))
            }
            .store(in: &cancellables)

        cellularPublisher
            .sink { [weak self] cellular in
                guard let self = self else { return }
                let cellularSelectionModeEnabled = cellular?.isSimCardInserted == true
                self.connectionNetworkSelectionEntryPublisher.send(SettingEntry(setting: self.selectionModel(with: cellular),
                                                                                title: L10n.settingsConnectionNetworkSelection,
                                                                                isEnabled: cellularSelectionModeEnabled,
                                                                                itemLogKey: LogEvent.LogKeyAdvancedSettings.wifiBand))
            }
            .store(in: &cancellables)
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
        _ = currentDroneHolder.drone.getPeripheral(Peripherals.cellular)?.apnConfigurationSetting.setToManual(url: url,
                                                                                                              username: username,
                                                                                                              password: password)
    }
}

// MARK: - Private Funcs
private extension SettingsCellularDataViewModel {
    /// Starts watcher for cellular.
    func listenCellular(_ drone: Drone) {
        cellularRef = drone.getPeripheral(Peripherals.cellular) { [unowned self] cellular in
            updateCellularNetwork()
            cellularPublisher.send(cellular)
        }
    }

    /// Starts watcher for drone state.
    func listenConnectionState(_ drone: Drone) {
        droneStateRef = drone.getState { [unowned self] _ in
            updateCellularNetwork()
        }
    }

    /// Starts watcher for network control.
    func listenNetworkControl(_ drone: Drone) {
        networkControlRef = drone.getPeripheral(Peripherals.networkControl) { [unowned self] networkControl in
            networkControlPublisher.send(networkControl)
        }
    }

    /// Starts watcher for flying indicators.
    func listenFlyingIndicators(_ drone: Drone) {
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [unowned self] flyingIndicator in
            flyingIndicatorPublisher.send(flyingIndicator)
        }
    }

    /// Updates cellular network informations.
    func updateCellularNetwork() {
        let drone = currentDroneHolder.drone
        let cellular = drone.getPeripheral(Peripherals.cellular)
        if drone.isConnected {
            cellularSelectionMode = cellular?.apnConfigurationSetting.isManual == true ? .manual : .auto
        } else {
            cellularSelectionMode = nil
        }
        cellularNetworkUrl = cellular?.apnConfigurationSetting.url ?? ""
        cellularNetworkUsername = cellular?.apnConfigurationSetting.username ?? ""
        cellularNetworkPassword = cellular?.apnConfigurationSetting.password ?? ""

    }

    /// Updates cellular network selection mode.
    ///
    /// - Parameters:
    ///     - selectionMode: the selection mode
    func updateSelectionMode(selectionMode: SettingsCellularSelection) {
        let cellular = currentDroneHolder.drone.getPeripheral(Peripherals.cellular)
        if selectionMode == .manual {
            _ = cellular?.apnConfigurationSetting.setToManual(url: cellularNetworkUrl,
                                                              username: cellularNetworkUsername,
                                                              password: cellularNetworkPassword)
        } else {
            _ = cellular?.apnConfigurationSetting.setToAuto()
        }
    }

    /// Returns a setting model for 4G availability. User can disable cellular access with this setting.
    ///
    /// - Parameters:
    ///     - cellular: current cellular
    /// - Returns: Model for cellular availability setting.
    func cellularAvailabilityModel(with cellular: Cellular?) -> DroneSettingModel {
        let isCellularAvailabilityUpdating = cellular?.mode.updating == true
        let cellularAvailability = cellular?.cellularAvailability ?? .cellularOff

        return DroneSettingModel(allValues: SettingsCellularAvailability.allValues,
                                 supportedValues: SettingsCellularAvailability.allValues,
                                 currentValue: cellularAvailability,
                                 isUpdating: isCellularAvailabilityUpdating) { [weak self] mode in
            guard let mode = mode as? SettingsCellularAvailability else { return }

            switch mode {
            case .cellularOn:
                cellular?.mode.value = .data
                guard let uid = self?.currentDroneHolder.drone.uid,
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
        let cellularSelectionMode: SettingsCellularSelection = cellular?.apnConfigurationSetting.isManual == true ? .manual : .auto
        let isCellularSelectionModeUpdating = cellular?.apnConfigurationSetting.updating == true

        return DroneSettingModel(allValues: SettingsCellularSelection.allValues,
                                 supportedValues: SettingsCellularSelection.allValues,
                                 currentValue: cellularSelectionMode,
                                 isUpdating: isCellularSelectionModeUpdating) { [weak self] selectionMode in
            guard let selectionMode = selectionMode as? SettingsCellularSelection else { return }

            self?.updateSelectionMode(selectionMode: selectionMode)
        }
    }

    /// Returns a setting model for 4G network policy. It can be Auto, Cellular or Wi-fi priority.
    ///
    /// - Parameter networkControl: network control peripheral
    /// - Returns: A drone setting model.
    func networkModeModel(with networkControl: NetworkControl?) -> DroneSettingModel {
        let routingPolicy = networkControl?.routingPolicy.policy ?? .automatic
        let isRoutingPolicyUpdating = networkControl?.routingPolicy.updating == true

        return DroneSettingModel(allValues: NetworkControlRoutingPolicy.allValues,
                                 supportedValues: NetworkControlRoutingPolicy.allValues,
                                 currentValue: routingPolicy,
                                 isUpdating: isRoutingPolicyUpdating) { policy in
            guard let strongPolicy = policy as? NetworkControlRoutingPolicy else { return }

            networkControl?.routingPolicy.policy = strongPolicy
        }
    }
}
