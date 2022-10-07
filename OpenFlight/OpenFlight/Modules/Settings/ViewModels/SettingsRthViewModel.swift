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
import Combine

/// Return to home settings view model.
final class SettingsRthViewModel: SettingsViewModelProtocol {
    // MARK: - Published Properties

    private(set) var notifyChangePublisher = CurrentValueSubject<Void, Never>(())

    // MARK: - Private Properties

    private var currentDroneHolder: CurrentDroneHolder
    private var rthSettingsMonitor: RthSettingsMonitor
    private var cancellables = Set<AnyCancellable>()
    private var returnHomePilotingRef: Ref<ReturnHomePilotingItf>?
    private var rth: ReturnHomePilotingItf?

    // MARK: - Internal Properties
    var settingEntries: [SettingEntry] {
        var entries = [SettingEntry(setting: rthTargetModel(returnHome: rth),
                                    title: L10n.settingsRthTypeTitle,
                                    itemLogKey: LogEvent.LogKeyAdvancedSettings.returnHome)]

        entries.append(SettingEntry(setting: SettingsCellType.endHovering))
        entries.append(SettingEntry(setting: SettingsCellType.rth))

        return entries
    }

    var infoHandler: ((SettingMode.Type) -> Void)?

    var isUpdating: Bool? {
        return false
    }

    // MARK: - Internal Funcs
    /// Inits.
    ///
    ///  - Parameters:
    ///         - currentDroneHolder: drone holder
    ///         - rthSettingsMonitor: return home settings manager
    init(currentDroneHolder: CurrentDroneHolder, rthSettingsMonitor: RthSettingsMonitor) {
        self.currentDroneHolder = currentDroneHolder
        self.rthSettingsMonitor = rthSettingsMonitor

        currentDroneHolder.dronePublisher
            .sink { [weak self] drone in
                guard let self = self else { return }
                self.listenReturnHome(drone)
            }
            .store(in: &cancellables)
    }

    // MARK: - Deinit
    deinit {
        returnHomePilotingRef = nil
    }

    /// Resets Return Home settings to default.
    func resetSettings() {
        let rthSettings = RthSettings(rthReturnTarget: RthPreset.rthType,
                                      rthHeight: RthPreset.defaultAltitude,
                                      rthEndBehaviour: RthPreset.defaultEndingBehavior,
                                      rthHoveringHeight: RthPreset.defaultHoveringAltitude)
        rthSettingsMonitor.updateUserRthSettings(rthSettings: rthSettings)
    }
}

// MARK: - Private Funcs
private extension SettingsRthViewModel {
    /// Starts watcher for Return Home.
    func listenReturnHome(_ drone: Drone) {
        returnHomePilotingRef = drone.getPilotingItf(PilotingItfs.returnHome) { [weak self] returnHome in
            guard let self = self else { return }
            self.rth = returnHome
            self.notifyChangePublisher.send()
        }
    }

    /// Returns a RTH preferred target model.
    func rthTargetModel(returnHome: ReturnHomePilotingItf?) -> DroneSettingModel? {
        let userPreferredRthSettings = rthSettingsMonitor.getUserRthSettings()
        let homeTarget = returnHome?.preferredTarget
        let currentValue = homeTarget?.target.isHomeAvailable == true
            ? userPreferredRthSettings.rthReturnTarget
            : RthPreset.rthType
        let isUpdating = homeTarget?.target.isHomeAvailable == true
            ? homeTarget?.updating ?? false
            : false

        return DroneSettingModel(allValues: ReturnHomeTarget.allValues,
                                 supportedValues: ReturnHomeTarget.allValues,
                                 currentValue: currentValue,
                                 isUpdating: isUpdating) { [weak self] settingMode in
            guard let self = self, let rthTarget = settingMode as? ReturnHomeTarget
            else { return }
            let rthSettings = RthSettings(rthReturnTarget: rthTarget,
                                          rthHeight: userPreferredRthSettings.rthHeight,
                                          rthEndBehaviour: userPreferredRthSettings.rthEndBehaviour,
                                          rthHoveringHeight: userPreferredRthSettings.rthHoveringHeight)
            self.rthSettingsMonitor.updateUserRthSettings(rthSettings: rthSettings)
        }
    }
}
