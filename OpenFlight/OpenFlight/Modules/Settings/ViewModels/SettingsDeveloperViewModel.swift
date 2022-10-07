//    Copyright (C) 2022 Parrot Drones SAS
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

/// Developer settings view model.
final class SettingsDeveloperViewModel {

    // MARK: - Published properties
    @Published private(set) var isNotFlying: Bool = false
    @Published private(set) var isEditing: Bool = false
    @Published private(set) var isLoadingPublicKey: Bool = false
    @Published private(set) var errorMessagePublicKey: String?
    @Published private(set) var publicKeyEditionAsk: Bool = false

    // MARK: - Private Properties
    private var currentDroneHolder: CurrentDroneHolder
    private var cancellables = Set<AnyCancellable>()
    private var publicKey: String?
    private var dismissPublicKeyAlertSubject = PassthroughSubject<Void, Never>()
    private var networkControlSubject = CurrentValueSubject<NetworkControl?, Never>(nil)
    private var debugShellSubject = CurrentValueSubject<DebugShell?, Never>(nil)
    private var logControlSubject = CurrentValueSubject<LogControl?, Never>(nil)

    // MARK: Ground SDK References
    private var networkControlRef: Ref<NetworkControl>?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?
    private var debugShellRef: Ref<DebugShell>?
    private var logControlRef: Ref<LogControl>?

    init(currentDroneHolder: CurrentDroneHolder) {
        self.currentDroneHolder = currentDroneHolder

        currentDroneHolder.dronePublisher
            .sink { [weak self] drone in
                guard let self = self else { return }

                self.listenFlyingIndicators(drone)
                self.listenNetworkControl(drone)
                self.listenDebugShell(drone)
                self.listenLogControl(drone)
            }
            .store(in: &cancellables)
    }

    // MARK: - Computed Properties
    var infoHandler: ((SettingMode.Type) -> Void)?
    var editionHandler: (() -> Void)?

    var settingEntries: [SettingEntry] {
        [SettingEntry(setting: directConnectionModel(networkControl: networkControlSubject.value),
                      title: L10n.settingsConnectionDirectConnection,
                      isEnabled: networkControlSubject.value != nil,
                      itemLogKey: LogEvent.LogKeyAdvancedSettings.directConnectionSetting),
         SettingEntry(setting: shellAccessModel(debugShell: debugShellSubject.value),
                      title: L10n.settingsDeveloperShellAccess,
                      isEnabled: debugShellSubject.value != nil,
                      itemLogKey: LogEvent.LogKeyAdvancedSettings.shellAccessSetting),
         SettingEntry(setting: missionLogModel(logControl: logControlSubject.value),
                      title: L10n.settingsDeveloperMissionLog,
                      isEnabled: logControlSubject.value != nil,
                      itemLogKey: LogEvent.LogKeyAdvancedSettings.missionLogsSetting)]
    }

    var dismissPublicKeyAlertPublisher: AnyPublisher<Void, Never> {
        return dismissPublicKeyAlertSubject.eraseToAnyPublisher()
    }

    var networkControlPublisher: AnyPublisher<NetworkControl?, Never> {
        return networkControlSubject.eraseToAnyPublisher()
    }

    var debugShellPublisher: AnyPublisher<DebugShell?, Never> {
        return debugShellSubject.eraseToAnyPublisher()
    }

    var logControlPublisher: AnyPublisher<LogControl?, Never> {
        return logControlSubject.eraseToAnyPublisher()
    }

    var publicFullKey: String {
        guard let key = publicKey else {
            return L10n.settingsDeveloperPublicKeyPlaceholder
        }
        return key
    }

    var isPublicKeyIsHidden: Bool {
        switch debugShellSubject.value?.state.value {
        case .enabled:
            return false
        default:
            return true
        }
    }

    /// Tells if the user is currently editing textfields.
    ///
    /// - Parameters:
    ///     - isEditing: is editing
    func isEditing(_ isEditing: Bool) {
        self.isEditing = isEditing
    }

    /// Reset developer settings to default.
    func resetSettings() {
        networkControlSubject.value?.directConnection.mode = DeveloperPreset.defaultDirectConnection.mode
        debugShellSubject.value?.state.value = DeveloperPreset.defaultShellAccess.toState(publicKey: self.publicKey)
        logControlSubject.value?.missionLogs?.value = DeveloperPreset.defaultMissionLog == .missionLogOn
    }

    /// Submits the public key
    ///
    /// - Parameters:
    ///    - publicKey: Public key
    func submitPublicKey(publicKey: String?) {
        guard let publicKey = publicKey,
                validateUserEntries(publicKey: publicKey) else {
            return
        }

        isLoadingPublicKey = true
        debugShellSubject.value?.state.value = .enabled(publicKey: publicKey)
        dismissPublicKeyEdition()
    }

    /// Dismisses the public key edition
    func dismissPublicKeyEdition() {
        publicKeyEditionAsk = false
        isLoadingPublicKey = false
        errorMessagePublicKey = nil
        dismissPublicKeyAlertSubject.send()
    }

    // MARK: - Deinit
    deinit {
        flyingIndicatorsRef = nil
        networkControlRef = nil
        debugShellRef = nil
        logControlRef = nil
    }
}

// MARK: - Private Funcs
private extension SettingsDeveloperViewModel {

    /// Listens flying indicators.
    ///
    /// - Parameter drone: current drone
    func listenFlyingIndicators(_ drone: Drone) {
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [unowned self] flyingIndicators in
            let flyingState = flyingIndicators?.state ?? .landed
            isNotFlying = flyingState != .flying
        }
    }

    /// Listens to network control.
    ///
    /// - Parameter drone: current drone
    func listenNetworkControl(_ drone: Drone) {
        networkControlRef = drone.getPeripheral(Peripherals.networkControl) { [unowned self] in
            networkControlSubject.value = $0
        }
    }

    /// Listens DebugShell.
    ///
    /// - Parameters:
    ///     - drone: current drone
    func listenDebugShell(_ drone: Drone) {
        debugShellRef = drone.getPeripheral(Peripherals.debugShell) { [unowned self] in
            debugShellSubject.value = $0
        }
    }

    /// Listens LogControl.
    ///
    /// - Parameters:
    ///     - drone: current drone
    func listenLogControl(_ drone: Drone) {
        logControlRef = drone.getPeripheral(Peripherals.logControl) { [unowned self] in
            logControlSubject.value = $0
        }
    }

    /// Checks user entries validity.
    ///
    /// - Parameters:
    ///    - publicKey: Public key
    /// - Returns: true if user entries is valid, otherwise false.
    private func validateUserEntries(publicKey: String?) -> Bool {
        guard let publicKey = publicKey,
              Data(base64Encoded: publicKey) != nil else {
            errorMessagePublicKey = L10n.settingsEditPublicKeyErrorBadFormat
            return false
        }
        return true
    }

    /// Returns a setting model for direct connection.
    ///
    /// - Parameter networkControl: network control peripheral
    /// - Returns: setting model for direct connection
    func directConnectionModel(networkControl: NetworkControl?) -> DroneSettingModel {
        let isUpdating = networkControl?.directConnection.updating == true
        let currentMode = networkControl?.directConnection.mode ?? DeveloperPreset.defaultDirectConnection.mode
        return DroneSettingModel(allValues: SettingsDirectConnection.allValues,
                                 supportedValues: SettingsDirectConnection.allValues,
                                 currentValue: SettingsDirectConnection.from(currentMode),
                                 isUpdating: isUpdating) { setting in
            guard let directConnectionSetting = setting as? SettingsDirectConnection else { return }

            networkControl?.directConnection.mode = directConnectionSetting.mode
        }
    }

    /// Returns a setting model for mission logs.
    ///
    /// - Parameter logControl: log control peripheral
    /// - Returns: setting model for mission logs
    func missionLogModel(logControl: LogControl?) -> DroneSettingModel {
        let isUpdating = logControl?.missionLogs?.updating == true
        var currentValue = DeveloperPreset.defaultMissionLog
        if let value = logControl?.missionLogs?.value {
            currentValue = value ? .missionLogOn : .missionLogOff
        }
        return DroneSettingModel(allValues: SettingsMissionLog.allValues,
                                 supportedValues: SettingsMissionLog.allValues,
                                 currentValue: currentValue,
                                 isUpdating: isUpdating) { setting in
            guard let missionLogsSetting = setting as? SettingsMissionLog else { return }

            logControl?.missionLogs?.value = missionLogsSetting == .missionLogOn
        }
    }

    /// Returns a setting model for shell access. It can be ON showing drone public key, or OFF.
    ///
    /// - Parameter debugShell: DebugShell drone peripheral
    /// - Returns: setting model for shell access
    func shellAccessModel(debugShell: DebugShell?) -> ShellAccessSettingModel {
        let isUpdating = debugShell?.state.updating == true
        var currentValue = DeveloperPreset.defaultShellAccess
        if let value = debugShell?.state.value {
            switch value {
            case .enabled(let publicKey):
                currentValue = SettingsShellAccess.shellAccessOn
                self.publicKey = publicKey
            default:
                currentValue = SettingsShellAccess.shellAccessOff
            }
        }
        return ShellAccessSettingModel(allValues: SettingsShellAccess.allValues,
                                              supportedValues: SettingsShellAccess.allValues,
                                              currentValue: currentValue,
                                              isUpdating: isUpdating) { setting in
            guard let shellAccessSetting = setting as? SettingsShellAccess else { return }

            var state: DebugShellState = .disabled

            switch shellAccessSetting {
            case .shellAccessOn:
                guard let publicKey = self.publicKey else {
                    self.publicKeyEditionAsk = true
                    return
                }

                self.publicKeyEditionAsk = false
                state = .enabled(publicKey: publicKey)
            case .shellAccessOff:
                self.publicKeyEditionAsk = false
            }

            debugShell?.state.value = state
        }
    }
}
