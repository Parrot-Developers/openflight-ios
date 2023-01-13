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

/// State for in `SettingsEndHoveringViewModel`.
final class SettingsEndHoveringState: ViewModelState, EquatableState, Copying {
    // MARK: - Internal Properties
    fileprivate(set) var isHovering: Bool?
    fileprivate(set) var hoveringAltitude: Double?

    // MARK: - Init
    required init() { }

    /// Init.
    ///
    /// - Parameters:
    ///     - isHovering: tell if drone is hovering
    ///     - hoveringAltitude: drone hovering altitude value
    init(isHovering: Bool?,
         hoveringAltitude: Double?) {
        self.isHovering = isHovering
        self.hoveringAltitude = hoveringAltitude
    }

    // MARK: - Override Funcs
    func isEqual(to other: SettingsEndHoveringState) -> Bool {
        return isHovering == other.isHovering
            && hoveringAltitude == other.hoveringAltitude
    }

    func copy() -> SettingsEndHoveringState {
        return SettingsEndHoveringState(isHovering: isHovering,
                                        hoveringAltitude: hoveringAltitude)
    }
}

/// End hovering setting.
final class SettingsEndHoveringViewModel: DroneWatcherViewModel<SettingsEndHoveringState> {
    // MARK: - Internal Properties
    /// Returns the setting entry for end Hovering mode.
    var endHoveringModeEntry: SettingEntry {
        return SettingEntry(setting: endHoveringModel(),
                            title: L10n.settingsRthEndByTitle)
    }
    /// Returns the setting entry for end Hovering altitude.
    var endHoveringAltitudeEntry: SettingEntry {
        let isHovering = state.value.isHovering == true

        let endHoveringAltitudeModel = endHoveringAltitudeModel()
        return SettingEntry(setting: endHoveringAltitudeModel,
                            title: L10n.commonHovering,
                            unit: UnitType.distance,
                            defaultValue: Float(RthPreset.defaultHoveringAltitude),
                            isEnabled: isHovering,
                            itemLogKey: LogEvent.LogKeyAdvancedSettings.endHoveringAltitude.description,
                            settingStepperSlider: SettingStepperSlider(limitIntervalChange: Float(endHoveringAltitudeModel.min),
                                                                       leftIntervalStep: 1,
                                                                       rightIntervalStep: 1))
    }

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var returnHomePilotingRef: Ref<ReturnHomePilotingItf>?
    private var returnHome: ReturnHomePilotingItf?
    var rthSettingsMonitor: RthSettingsMonitor

    // MARK: - Internal Funcs
    /// Init.
    ///
    /// - Parameters:
    ///     - rthSettingsMonitor: return home settings manager
    init(rthSettingsMonitor: RthSettingsMonitor) {
        self.rthSettingsMonitor = rthSettingsMonitor
        super.init()
    }

    // MARK: - Deinit
    deinit {
        returnHomePilotingRef = nil
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        listenReturnHome(drone)
        listenUserRthSettings()
    }
}

// MARK: - Private Funcs
private extension SettingsEndHoveringViewModel {
    /// Starts watcher for Return Home.
    func listenReturnHome(_ drone: Drone) {
        returnHomePilotingRef = drone.getPilotingItf(PilotingItfs.returnHome) { [weak self] returnHome in
            guard let self = self else { return }
            self.returnHome = returnHome
        }
    }

    /// Watches user rth settings
    func listenUserRthSettings() {
        rthSettingsMonitor.userPreferredRthSettingsPublisher.sink { [weak self] rthSettings in
            guard let self = self else { return }
            let copy = self.state.value.copy()
            copy.hoveringAltitude = rthSettings.rthHoveringHeight
            copy.isHovering = rthSettings.rthEndBehaviour == .hovering
            self.state.set(copy)
        }
        .store(in: &cancellables)
    }

    /// Returns a setting model for end Hovering mode.
    func endHoveringModel() -> DroneSettingModel {
        let userSettings = rthSettingsMonitor.getUserRthSettings()

        return DroneSettingModel(allValues: ReturnHomeEndingBehavior.allValues,
                                 supportedValues: ReturnHomeEndingBehavior.allValues,
                                 currentValue: userSettings.rthEndBehaviour,
                                 isUpdating: false) { [weak self] mode in
            guard let self = self,
                  let mode = mode as? ReturnHomeEndingBehavior
            else { return }

            let rthSettings = RthSettings(rthReturnTarget: userSettings.rthReturnTarget,
                                          rthHeight: userSettings.rthHeight,
                                          rthEndBehaviour: mode,
                                          rthHoveringHeight: userSettings.rthHoveringHeight)
            self.rthSettingsMonitor.updateUserRthSettings(rthSettings: rthSettings)
        }
    }

    func endHoveringAltitudeModel() -> HoveringAltitudeModel {
        let userSettings = rthSettingsMonitor.getUserRthSettings()
        let endingHoveringAltitude = returnHome?.endingHoveringAltitude
        return HoveringAltitudeModel(min: endingHoveringAltitude?.min ?? RthPreset.minAltitude,
                                     max: endingHoveringAltitude?.max ?? RthPreset.maxAltitude,
                                     value: userSettings.rthHoveringHeight)
    }
}

/// Dedicated model for hovering altitude settings.
class HoveringAltitudeModel: DoubleSetting {
    var updating: Bool
    /// Setting minimum value.
    var min: Double
    /// Setting maximum value.
    var max: Double
    /// Setting current value.
    var value: Double

    init(min: Double, max: Double, value: Double, updating: Bool = false) {
        self.min = min
        self.max = max
        self.value = value
        self.updating = updating
    }
}
