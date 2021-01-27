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
import Reusable

/// View dedicated to manage piloting style mode change.
final class PilotingModeView: UIView, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var backgroundView: UIView! {
        didSet {
            backgroundView.backgroundColor = ColorName.black80.color
            backgroundView.applyCornerRadius(Style.largeCornerRadius)
        }
    }
    @IBOutlet private weak var pilotingStyleLabel: UILabel! {
        didSet {
            pilotingStyleLabel.makeUp(with: .tiny, and: .white)
            pilotingStyleLabel.text = L10n.settingsControlsPilotingStyle.uppercased()
        }
    }
    @IBOutlet private weak var classicButton: UIButton! {
        didSet {
            classicButton.applyCornerRadius(Style.largeCornerRadius)
            classicButton.setTitle(L10n.settingsControlsPilotingStyleClassic, for: .normal)
        }
    }
    @IBOutlet private weak var arcadeButton: UIButton! {
        didSet {
            arcadeButton.applyCornerRadius(Style.largeCornerRadius)
            arcadeButton.setTitle(L10n.settingsControlsPilotingStyleArcade, for: .normal)
        }
    }

    // MARK: - Private Properties
    private var viewModel: ControlsViewModel?

    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInitPilotingModeView()
    }

    // MARK: - Override Funcs
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInitPilotingModeView()
    }

    // MARK: - Internal Funcs
    /// Setup view regarding view model.
    ///
    /// - Parameters:
    ///     - viewModel: Controls view model
    func setup(with viewModel: ControlsViewModel) {
        self.viewModel = viewModel
        allowArcadeMode(viewModel.state.value.isArcadeModeAvailable)
        updateDisplay(with: viewModel.state.value.currentPilotingStyle)
    }
}

// MARK: - Actions
private extension PilotingModeView {
    /// Classic button clicked.
    @IBAction func classicButtonTouchedUpInside(_ sender: Any) {
        setPilotingStyle(.classical)
    }

    /// Arcade button clicked.
    @IBAction func arcadeButtonTouchedUpInside(_ sender: Any) {
        setPilotingStyle(.arcade)
    }
}

// MARK: - Private Funcs
private extension PilotingModeView {
    /// Init view.
    func commonInitPilotingModeView() {
        self.loadNibContent()

        // Disable view by default.
        allowArcadeMode(false)

        // Setup default style.
        updateDisplay()

        // FIXME: Temporary disable arcade mode. / Force classical mode.
        setPilotingStyle()
    }

    /// Allow arcade mode.
    ///
    /// - Parameters:
    ///     - isAllowed: Arcade is allowed
    func allowArcadeMode(_ isAllowed: Bool) {
        if isAllowed {
            self.classicButton.isUserInteractionEnabled = true
            self.arcadeButton.isUserInteractionEnabled = true
            self.alpha = 1
        } else {
            self.classicButton.isUserInteractionEnabled = false
            self.arcadeButton.isUserInteractionEnabled = false
            self.alpha = 0.5
        }
    }

    /// Update display regarding piloting style.
    ///
    /// - Parameters:
    ///     - style: Piloting style
    func updateDisplay(with style: PilotingStyle = .classical) {
        switch style {
        case .arcade where viewModel?.state.value.isArcadeModeAvailable ?? false:
            applyDisableStyle(classicButton)
            applyEnableStyle(arcadeButton)
        default:
            applyEnableStyle(classicButton)
            applyDisableStyle(arcadeButton)
        }
    }

    /// Set piloting style.
    ///
    /// - Parameters:
    ///     - style: Piloting style
    func setPilotingStyle(_ style: PilotingStyle = .classical) {
        self.updateDisplay(with: style)
        // Update view model.
        self.viewModel?.switchToPilotingStyle(style)
    }

    /// Apply disable style to button.
    ///
    /// - Parameters:
    ///     - button: Button to apply style
    func applyDisableStyle(_ button: UIButton) {
        button.backgroundColor = ColorName.black80.color
        button.makeup(with: .regular, color: .white50, and: .normal)
    }

    /// Apply enable style to button.
    ///
    /// - Parameters:
    ///     - button: Button to apply style
    func applyEnableStyle(_ button: UIButton) {
        button.backgroundColor = .white
        button.makeup(with: .regular, color: .black, and: .normal)
    }
}
