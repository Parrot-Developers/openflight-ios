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
    @IBOutlet private weak var widthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var trailingConstraint: NSLayoutConstraint!
    @IBOutlet private var actionWidgetBottomConstraint: NSLayoutConstraint!

    public var splitControls: SplitControls?

    // MARK: - Private Properties
    // TODO wrong injection
    private var currentMissionManager = Services.hub.currentMissionManager
    private var cancellables = Set<AnyCancellable>()
    private var panelWidth: CGFloat {
        Layout.sidePanelWidth(rightPanelContainerView.isRegularSizeClass)
    }

    // MARK: - Internal Funcs
    /// Sets up view model's callback.
    /// Should be called inside viewWillAppear.
    func start() {
        currentMissionManager.modePublisher.sink { [weak self] mode in
            self?.updateConstraints(show: mode.isRightPanelRequired)
        }
        .store(in: &cancellables)

        setupUI()
    }

    /// Stops view model's callback if needed.
    func stop() {
        cancellables = Set()
    }

    /// Sets up UI.
    func setupUI() {
        // Align action widget container with bottom bar level1.
        let isRegularSizeClass = stackView.isRegularSizeClass
        actionWidgetBottomConstraint.constant = Layout.buttonIntrinsicHeight(isRegularSizeClass) + 2 * Layout.mainPadding(isRegularSizeClass)
        widthConstraint.constant = panelWidth
        trailingConstraint.constant = -panelWidth
        rightPanelContainerView.backgroundColor = ColorName.defaultBgcolor.color
    }

}

// MARK: - Private Funcs
private extension RightPanelContainerControls {
    /// Shows panel.
    func show() {
        updateConstraints(show: true)
    }

    /// Hides panel.
    func hide() {
        updateConstraints(show: false)
    }

    /// Updates panel constraint for showing/hiding.
    func updateConstraints(show: Bool) {
        if !show {
            // Add a temporary snapshot of current side panel for a cleaner dismissal animation,
            // as its content is unconditionnally removed at each `mode` update.
            rightPanelContainerView.addTransitionSnapshot()
        }

        // Right panel content refresh is also triggered by mission manager `mode` publisher update,
        // so we need to dispatch show/hide constraint animation in order to avoid unwanted panel
        // content animation.
        DispatchQueue.main.async {
            // Action widget follows bottom bar level1 (goes up if bottom bar is expanded)
            // onlly if side panel is not visible.
            self.actionWidgetBottomConstraint.isActive = !show
            self.trailingConstraint.constant = show ? 0 : -self.panelWidth
        }
    }
}
