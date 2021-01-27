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

// MARK: - BehaviourModeView
/// Custom view used to display behaviours.
public final class BehaviourModeView: BarButtonView {
    // MARK: - Internal Properties
    var viewModel = BehaviourModeViewModel()
    weak var delegate: BottomBarContainerDelegate?
    weak var deselectAllViewModelsDelegate: DeselectAllViewModelsDelegate?

    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initBehaviourMode()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initBehaviourMode()
    }

    // MARK: - Deinit
    deinit {
        self.removeTarget()
    }
}

// MARK: - Private Funcs
private extension BehaviourModeView {
    /// Basic init.
    func initBehaviourMode() {
        self.model = self.viewModel.state.value
        self.addTarget()
        self.observeViewModels()
    }

    /// Add a target when user touch the view.
    func addTarget() {
        self.addTarget(self, action: #selector(viewTouchedUpInside), for: .touchUpInside)
    }

    /// Removes the target when user touch the view.
    func removeTarget() {
        self.removeTarget(self, action: #selector(viewTouchedUpInside), for: .touchUpInside)
    }

    /// Setup all view models.
    func observeViewModels() {
        self.viewModel.state.valueChanged = { [weak self] state in
            self?.model = state
        }

        self.viewModel.state.value.isSelected.valueChanged = { [weak self] isSelected in
            guard let strongViewModel = self?.viewModel else { return }

            if isSelected {
                self?.delegate?.showLevelOne(viewModel: strongViewModel)
                self?.model = strongViewModel.state.value
                self?.deselectAllViewModelsDelegate?.deselectAllViewModels(except: type(of: strongViewModel))
            } else {
                self?.delegate?.hideLevelOne(viewModel: strongViewModel)
                self?.model = strongViewModel.state.value
            }
        }
    }
}

// MARK: - Actions
private extension BehaviourModeView {
    @objc func viewTouchedUpInside() {
        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.bottomBarHUD.name,
                             itemName: LogEvent.LogKeyHUDBottomBarButton.speedMode.name,
                             newValue: (!self.viewModel.state.value.isSelected.value).logValue,
                             logType: .button)
        self.viewModel.toggleSelectionState()
    }
}
