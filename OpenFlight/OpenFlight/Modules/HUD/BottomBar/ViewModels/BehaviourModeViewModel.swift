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

/// State for `BehaviourModeViewModel`.

final class BehaviourModeButtonState: BarButtonState, EquatableState, Copying {
    // MARK: - Internal Properties
    var isSelected: Observable<Bool> = Observable(false)
    var title: String?
    var subtext: String? {
        return mode?.title
    }
    var image: UIImage? {
        return nil
    }
    var mode: BarItemMode?
    var supportedModes: [BarItemMode]?
    var showUnsupportedModes: Bool = false
    var subMode: BarItemSubMode?
    var subtitle: String?
    var enabled: Bool = true
    var unavailableReason: [String: String] = [:]
    var maxItems: Int?

    // MARK: - Init
    required init() { }

    /// Init.
    ///
    /// - Parameters:
    ///    - title: mode title
    ///    - mode: current mode
    ///    - enabled: availability of the mode
    ///    - isSelected: observable for item selection
    init(title: String? = nil,
         mode: BarItemMode?,
         enabled: Bool,
         isSelected: Observable<Bool>) {
        self.title = title
        self.mode = mode
        self.enabled = enabled
        self.isSelected = isSelected
    }

    // MARK: - Internal Funcs
    func isEqual(to other: BehaviourModeButtonState) -> Bool {
        return self.mode?.key == other.mode?.key
    }

    /// Returns a copy of the object.
    func copy() -> BehaviourModeButtonState {
        let copy = BehaviourModeButtonState(title: self.title,
                                      mode: self.mode,
                                      enabled: self.enabled,
                                      isSelected: self.isSelected)
        return copy
    }
}

/// ViewModel to manage behaviour mode in HUD bottom bar.

final class BehaviourModeViewModel: BarButtonViewModel<BehaviourModeButtonState> {
    // MARK: - Private Properties
    private var behaviourModeObserver: DefaultsDisposable?

    // MARK: - Init
    init() {
        super.init(barId: "BehaviourMode")

        state.value.title = L10n.commonSpeed.uppercased()
        listenBehaviourModeDefault()
        updateState()
    }

    // MARK: - Deinit
    deinit {
        behaviourModeObserver?.dispose()
        behaviourModeObserver = nil
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) { }

    /// Update behaviour model.
    ///
    /// - Parameters:
    ///    - new behaviour mode
    override func update(mode: BarItemMode) {
        guard let mode = mode as? SettingsBehavioursMode else {
            return
        }
        let behavioursViewModel = BehavioursViewModel()
        behavioursViewModel.switchBehavioursMode(mode: mode)
    }

    override func update(subMode: BarItemSubMode) { }
}

// MARK: - Private Funcs
private extension BehaviourModeViewModel {
    /// Start behaviour default watcher.
    func listenBehaviourModeDefault() {
        behaviourModeObserver = Defaults.observe(\.userPilotingPreset) { [weak self] _ in
            DispatchQueue.userDefaults.async {
                self?.updateState()
            }
        }
    }

    /// Update state with current behaviour mode.
    func updateState() {
        let copy = self.state.value.copy()
        copy.mode = SettingsBehavioursMode.current
        self.state.set(copy)
    }
}
