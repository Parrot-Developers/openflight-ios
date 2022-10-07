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

/// Return to home action settings view model used to handle Grid cell management.
final class SettingsRthActionViewModel {

    // MARK: - Published Properties

    @Published private(set) var altitude: Double = RthPreset.defaultAltitude
    @Published private(set) var maxAltitude: Double = RthPreset.maxAltitude
    @Published private(set) var minAltitude: Double = RthPreset.minAltitude

    // MARK: - Private Properties

    private var rthSettingsMonitor: RthSettingsMonitor
    private var currentDroneHolder: CurrentDroneHolder
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Ground SDK references

    private var returnHomePilotingRef: Ref<ReturnHomePilotingItf>?

    // MARK: - Deinit
    deinit {
        returnHomePilotingRef = nil
    }

    // MARK: - Internal Funcs
    /// Inits.
    ///
    ///  - Parameters:
    ///         - currentDroneHolder: drone holder
    ///         - rthSettingsMonitor: return home settings manager
    init(currentDroneHolder: CurrentDroneHolder,
         rthSettingsMonitor: RthSettingsMonitor) {
        self.currentDroneHolder = currentDroneHolder
        self.rthSettingsMonitor = rthSettingsMonitor

        currentDroneHolder.dronePublisher
            .sink { [weak self] drone in
                guard let self = self else { return }
                self.listenReturnHome(drone)
                self.listenUserRthSettings()
            }
            .store(in: &cancellables)
    }

    /// Saves Return Home in drone.
    ///
    /// - Parameters:
    ///     - altitude: altitude to save
    func saveRth(altitude: Double) {
        let userSettings = rthSettingsMonitor.getUserRthSettings()
        let rthSettings = RthSettings(rthReturnTarget: userSettings.rthReturnTarget,
                                      rthHeight: altitude,
                                      rthEndBehaviour: userSettings.rthEndBehaviour,
                                      rthHoveringHeight: userSettings.rthHoveringHeight)
        rthSettingsMonitor.updateUserRthSettings(rthSettings: rthSettings)
    }
}

// MARK: - Private Funcs
private extension SettingsRthActionViewModel {
    /// Starts watcher for Return Home.
    func listenReturnHome(_ drone: Drone) {
        returnHomePilotingRef = drone.getPilotingItf(PilotingItfs.returnHome) { [unowned self] rth in
            guard let rth = rth,
                  let currentMinAltitude = rth.minAltitude else { return }

            minAltitude = currentMinAltitude.min
            maxAltitude = currentMinAltitude.max
        }
    }

    func listenUserRthSettings() {
        rthSettingsMonitor.userPreferredRthSettingsPublisher.sink { [weak self] rthSettings in
            guard let self = self else { return }
            self.altitude = rthSettings.rthHeight
        }
        .store(in: &cancellables)
    }
}
