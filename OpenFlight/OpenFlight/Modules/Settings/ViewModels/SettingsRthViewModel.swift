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

import GroundSdk

/// Return to home settings view model.
final class SettingsRthViewModel: DroneStateViewModel<DeviceConnectionState>, SettingsViewModelProtocol {
    // MARK: - Internal Properties
    var settingEntries: [SettingEntry] {
        var entries = [SettingEntry(setting: rthTargetModel,
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

    // MARK: - Private Properties
    private var returnHomePilotingRef: Ref<ReturnHomePilotingItf>?

    // MARK: - Deinit
    deinit {
        returnHomePilotingRef = nil
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        listenReturnHome(drone)
    }

    /// Resets Return Home settings to default.
    func resetSettings() {
        guard let returnHome = returnHomePilotingRef?.value else { return }

        returnHome.minAltitude?.value = RthPreset.defaultAltitude
        returnHome.endingBehavior.behavior = RthPreset.defaultEndingBehavior
        returnHome.endingHoveringAltitude?.value = RthPreset.defaultHoveringAltitude
        returnHome.preferredTarget.target = RthPreset.rthType
    }
}

// MARK: - Private Funcs
private extension SettingsRthViewModel {
    /// Starts watcher for Return Home.
    func listenReturnHome(_ drone: Drone) {
        returnHomePilotingRef = drone.getPilotingItf(PilotingItfs.returnHome) { [weak self] _ in
            self?.notifyChange()
        }
    }

    /// Returns a RTH preferred target model.
    var rthTargetModel: DroneSettingModel? {
        let homeTarget = drone?.getPilotingItf(PilotingItfs.returnHome)?.preferredTarget
        guard homeTarget?.target.isHomeAvailable == true else {
            return DroneSettingModel(allValues: ReturnHomeTarget.allValues,
                                     supportedValues: ReturnHomeTarget.allValues,
                                     currentValue: RthPreset.rthType,
                                     isUpdating: false) { rthTarget in
                if let strongRthTarget = rthTarget as? ReturnHomeTarget {
                    homeTarget?.target = strongRthTarget
                }
            }
        }

        return DroneSettingModel(allValues: ReturnHomeTarget.allValues,
                                 supportedValues: ReturnHomeTarget.allValues,
                                 currentValue: homeTarget?.target,
                                 isUpdating: homeTarget?.updating ?? false) { rthTarget in
            if let strongRthTarget = rthTarget as? ReturnHomeTarget {
                homeTarget?.target = strongRthTarget
            }
        }
    }
}
