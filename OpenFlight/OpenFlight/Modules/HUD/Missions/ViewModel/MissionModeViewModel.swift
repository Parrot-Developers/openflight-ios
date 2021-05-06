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

import UIKit
import SwiftyUserDefaults

/// State for `MissionModeViewModel`.

public class MissionProviderState: ViewModelState, EquatableState, Copying {
    // MARK: - Public Properties
    /// Mission provider
    public var provider: MissionProvider?
    /// Title representing mission
    /// Mission mode
    public var mode: MissionMode?
    public var title: String? {
        return provider?.mission.name
    }
    /// Image representing mission
    public var image: UIImage? {
        return provider?.mission.icon
    }

    // MARK: - Init
    required public init() {
        provider = MissionsManager.shared.missionFor(key: Defaults.userMissionProvider)
        mode = MissionsManager.shared.missionSubModeFor(key: Defaults.userMissionMode)
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - provider: mission provider
    init(provider: MissionProvider?, mode: MissionMode?) {
        self.provider = provider
        self.mode = mode
    }

    // MARK: - Public Funcs
    public func isEqual(to other: MissionProviderState) -> Bool {
        return self.provider?.mission.key == other.provider?.mission.key
            && self.mode?.key == other.mode?.key
    }

    /// Returns a copy of the object.
    public func copy() -> Self {
        if let copy = MissionProviderState(provider: provider, mode: mode) as? Self {
            return copy
        } else {
            fatalError("Must override...")
        }
    }
}

/// View model to listen mission mode updates.

final class MissionProviderViewModel: BaseViewModel<MissionProviderState> {

    // MARK: - Private Properties
    private var defaultsDisposable: DefaultsDisposable?

    // MARK: - Init
    override init() {
        super.init()

        listenDefaults()
    }

    // MARK: - Deinit
    deinit {
        defaultsDisposable?.dispose()
        defaultsDisposable = nil
    }
}

// MARK: - Private Funcs
private extension MissionProviderViewModel {

    /// Listen updates on user defaults to detect mission mode changes.
    func listenDefaults() {
        defaultsDisposable = Defaults.observe(\.userMissionMode) { [weak self] _ in
            DispatchQueue.userDefaults.async {
                let stateCopy = self?.state.value.copy()
                let newProvider = MissionsManager.shared.missionFor(key: Defaults.userMissionProvider)
                let newMode = MissionsManager.shared.missionSubModeFor(key: Defaults.userMissionMode)
                stateCopy?.provider = newProvider
                stateCopy?.mode = newMode
                self?.state.set(stateCopy)
            }
        }
    }
}
