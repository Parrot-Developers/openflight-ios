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
import Reusable

/// Drone action custom view used in the top bar.
final class DroneActionView: UIView, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var returnHomeButton: UIButton! {
        didSet {
            returnHomeButton.cornerRadiusedWith(backgroundColor: UIColor(named: .black60),
                                                radius: Style.mediumCornerRadius)
        }
    }
    @IBOutlet private weak var actionButton: UIButton! {
        didSet {
            actionButton.cornerRadiusedWith(backgroundColor: UIColor(named: .takeoffIndicatorColor),
                                            radius: Style.mediumCornerRadius)
        }
    }

    // MARK: - Private Properties
    private let viewModel = DroneActionViewModel()

    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInitDroneActionView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInitDroneActionView()
    }
}

// MARK: - Actions
private extension DroneActionView {
    @IBAction func actionButtonTouchedUpInside(_ sender: Any) {
        viewModel.startAction()
    }

    @IBAction func returnHomeButtonTouchedUpInside(_ sender: Any) {
        viewModel.startReturnToHome()
    }
}

// MARK: - Private Funcs
private extension DroneActionView {
    func commonInitDroneActionView() {
        loadNibContent()
        observeViewModel()
        updateDroneActionButtons()
    }

    /// Observes drone action view model.
    func observeViewModel() {
        viewModel.state.valueChanged = { [weak self] _ in
            self?.updateDroneActionButtons()
        }
        updateDroneActionButtons()
    }

    /// Updates drone action buttons.
    func updateDroneActionButtons() {
        updateTakeOffButton()
        updateReturnHomeButton()
    }

    /// Updates return to home button view.
    func updateReturnHomeButton() {
        let state = viewModel.state.value
        let image = state.isRthAvailable == true
            ? Asset.DroneAction.icRthAvailableIndicator.image
            : Asset.DroneAction.icRthUnavailableIndicator.image
        returnHomeButton.setImage(image, for: .normal)
        returnHomeButton.isEnabled = state.isRthAvailable == true
    }

    /// Updates takeoff button view.
    func updateTakeOffButton() {
        let state = viewModel.state.value
        actionButton.backgroundColor = state.backgroundColor
        actionButton.setImage(state.buttonImage, for: .normal)
        actionButton.isEnabled = state.connectionState == .connected
            && state.isTakeOffButtonEnabled == true
        actionButton.isHidden = state.shouldHideActionButton == true
    }
}
