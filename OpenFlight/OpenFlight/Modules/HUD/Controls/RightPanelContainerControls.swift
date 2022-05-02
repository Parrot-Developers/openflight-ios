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

/// Class that manages flight plan panel on HUD.
public class RightPanelContainerControls: NSObject {
    // MARK: - Outlets
    @IBOutlet weak var rightPanelContainerView: UIView!
    @IBOutlet private weak var stackView: UIView!
    @IBOutlet private weak var rightPanelContainerWidthConstraint: NSLayoutConstraint!
    @IBOutlet private var actionWidgetBottomConstraint: NSLayoutConstraint!

    public var splitControls: SplitControls?

    // MARK: - Internal Properties
    let viewModel = RightPanelContainerControlsViewModel()

    // MARK: - Private Properties
    // TODO wrong injection
    private var currentMissionManager = Services.hub.currentMissionManager
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Internal Funcs
    /// Sets up view model's callback.
    /// Should be called inside viewWillAppear.
    func start() {
        viewModel.state.valueChanged = { [weak self] state in
            if state.shouldDisplayRightPanel {
                self?.showFlightPlanPanel()
            } else {
                self?.hideFlightPlanPanel()
            }
        }
        currentMissionManager.modePublisher.sink { [unowned self] mode in
            if mode.isRightPanelRequired {
                viewModel.forceHidePanel(false)
                self.showFlightPlanPanel()
            }
        }
        .store(in: &cancellables)

        setupConstraint()
    }

    /// Stops view model's callback if needed.
    func stop() {
        viewModel.state.valueChanged = nil
        cancellables = Set()
    }
}

// MARK: - Private Funcs
private extension RightPanelContainerControls {
    // Sets up action widget bottom constraint.
    func setupConstraint() {
        // Align action widget container with bottom bar level1.
        let isRegularSizeClass = stackView.isRegularSizeClass
        actionWidgetBottomConstraint.constant = Layout.buttonIntrinsicHeight(isRegularSizeClass) + 2 * Layout.mainPadding(isRegularSizeClass)
    }

    /// Shows HUD's flight plan right panel.
    func showFlightPlanPanel() {

        let isRegularSizeClass = UIViewController().isRegularSizeClass
        splitControls?.adaptSecondaryContainerTrailing(width: Layout.sidePanelWidth(isRegularSizeClass))
        rightPanelContainerWidthConstraint.constant = Layout.sidePanelWidth(isRegularSizeClass)
        // Action widget container does not follow bottom bar level1 and remains at the right bottom.
        actionWidgetBottomConstraint.isActive = false
        stackView.layoutIfNeeded()
    }

    /// Hides HUD's flight plan right panel.
    ///
    /// - Parameters:
    ///    - completion: optional completion block
    func hideFlightPlanPanel(completion: (() -> Void)? = nil) {
        splitControls?.adaptSecondaryContainerTrailing(width: 0)
        rightPanelContainerWidthConstraint.constant = 0.0
        // Action widget follows bottom bar level1 (needs to go up if bottom bar is expanded).
        actionWidgetBottomConstraint.isActive = true
        stackView.layoutIfNeeded()
    }
}
