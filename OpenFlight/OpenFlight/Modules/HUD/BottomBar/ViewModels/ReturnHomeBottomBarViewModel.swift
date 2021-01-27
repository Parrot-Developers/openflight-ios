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
import SwiftyUserDefaults

/// State for `ReturnHomeBottomBarState`.

final class ReturnHomeBottomBarState: ViewModelState, EquatableState, Copying {
    // MARK: - Internal Properties
    /// Provides rth type description. Depends on the mission mode.
    fileprivate(set) var rthTypeDescription: Observable<String> = Observable(String())

    // MARK: - Init
    required init() { }

    /// Init.
    ///
    /// - Parameters:
    ///    - rthTypeDescription: rth title to display
    init(rthTypeDescription: Observable<String>) {
        self.rthTypeDescription = rthTypeDescription
    }

    // MARK: - Copying
    func copy() -> ReturnHomeBottomBarState {
        return ReturnHomeBottomBarState(rthTypeDescription: rthTypeDescription)
    }

    // MARK: - Equatable
    func isEqual(to other: ReturnHomeBottomBarState) -> Bool {
        return self.rthTypeDescription.value == other.rthTypeDescription.value
    }
}

/// View model which observes Return to Home state.

final class ReturnHomeBottomBarViewModel: DroneWatcherViewModel<ReturnHomeBottomBarState> {
    // MARK: - Private Properties
    private var returnHomeRef: Ref<ReturnHomePilotingItf>?
    private var defaultsDisposable: DefaultsDisposable?

    // MARK: - Init
    init() {
        super.init()

        listenDefaults()
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) { }

    // MARK: - Internal Funcs
    /// Stops Return Home.
    func stopReturnHome() {
        _ = drone?.getPilotingItf(PilotingItfs.returnHome)?.deactivate()
    }
}

// MARK: - Private Funcs
private extension ReturnHomeBottomBarViewModel {
    /// Listen updates on user defaults to detect mission mode changes.
    func listenDefaults() {
        defaultsDisposable = Defaults.observe(\.userMissionMode, options: [.new]) { [weak self] _ in
            DispatchQueue.userDefaults.async {
                self?.updateRthTypeDescription()
            }
        }
        updateRthTypeDescription()
    }

    /// Updates Rth description.
    func updateRthTypeDescription() {
        let currentMode = MissionsManager.shared.missionSubModeFor(key: Defaults.userMissionMode)
        guard let rthTitle = currentMode?.rthTypeTitle else { return }
        state.value.rthTypeDescription.set(rthTitle)
    }
}