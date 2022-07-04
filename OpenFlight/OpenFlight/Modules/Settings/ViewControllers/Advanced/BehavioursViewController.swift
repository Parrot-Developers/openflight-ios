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

import UIKit
import Combine

/// Settings content sub class dedicated to behaviours settings.
final class BehavioursViewController: SettingsContentViewController {
    // MARK: - Outlets
    @IBOutlet private weak var presetView: SettingsPresetsView!
    @IBOutlet private weak var presetViewHeightConstraint: NSLayoutConstraint!

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        setupViewModel()
    }

    /// Reset to default settings.
    override func resetSettings() {
        var itemName = ""

        switch SettingsBehavioursMode.current {
        case .video:
            itemName = LogEvent.LogKeyAdvancedSettings.resetFilmSettings
        default:
            itemName = LogEvent.LogKeyAdvancedSettings.resetSportSettings
        }

        LogEvent.log(.simpleButton(itemName))

        viewModel?.resetSettings()
    }
}

// MARK: - Private Funcs
private extension BehavioursViewController {

    /// Inits view.
    func initView() {
        presetViewHeightConstraint.constant = Layout.buttonIntrinsicHeight(isRegularSizeClass)
        resetCellLabel = L10n.settingsBehaviourReset(SettingsBehavioursMode.current.title)

        // Setup preset view.
        if let items =  SettingsBehavioursMode.allValues as? [SettingsBehavioursMode] {
            presetView.setup(items: items,
                             selectedMode: SettingsBehavioursMode.current,
                             delegate: self)
        }
    }

    /// Sets up view model.
    func setupViewModel() {
        // Setup view model.
        viewModel = BehavioursViewModel(currentDroneHolder: Services.hub.currentDroneHolder, presetService: Services.hub.presetService)
        guard let viewModel = viewModel as? BehavioursViewModel else { return }

        viewModel.notifyChangePublisher
            .combineLatest(viewModel.resetSettingPublisher)
            .sink { [weak self] (_, _) in
                guard let self = self else { return }
                self.updateDataSource()
            }
            .store(in: &cancellables)

        viewModel.infoHandler = { [weak self] modeType in
            guard let self = self else { return }
            self.showInfo(modeType)
        }
    }

    /// Show info related to setting type.
    func showInfo(_ modeType: SettingMode.Type) {
        switch modeType {
        case is InclinedRoll.Type:
            coordinator?.startSettingInfoHorizontal()
        case is BankedTurn.Type:
            coordinator?.startSettingInfoBankedTurn()
        default:
            break
        }
    }
}

// MARK: - Settings Preset View Delegate
extension BehavioursViewController: SettingsPresetViewDelegate {
    func settingsPresetViewSelectionDidChange(selectedMode: SettingsBehavioursMode) {
        guard let behavioursViewModel = viewModel as? BehavioursViewModel else { return }

        behavioursViewModel.switchBehavioursMode(mode: selectedMode)
        resetCellLabel = L10n.settingsBehaviourReset(SettingsBehavioursMode.current.title)
    }
}
