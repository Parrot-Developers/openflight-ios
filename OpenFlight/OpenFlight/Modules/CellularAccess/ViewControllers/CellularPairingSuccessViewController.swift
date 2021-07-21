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

/// Confirms the success of the cellular configuration login.
final class CellularPairingSuccessViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var panelView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var okButton: UIButton!
    @IBOutlet private weak var closeButton: UIButton!

    // MARK: - Private Properties
    private weak var coordinator: HUDCoordinator?

    // MARK: - Setup
    static func instantiate(coordinator: HUDCoordinator) -> CellularPairingSuccessViewController {
        let viewController = StoryboardScene.CellularPairingSuccess.initialScene.instantiate()
        viewController.coordinator = coordinator
        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension CellularPairingSuccessViewController {
    @IBAction func closeButtonTouchedUpInside(_ sender: Any) {
        coordinator?.dismiss()
    }

    @IBAction func backgroundButtonTouchedUpInside(_ sender: Any) {
        coordinator?.dismiss()
    }

    @IBAction func okButtonTouchedUpInside(_ sender: Any) {
        coordinator?.dismiss()
    }
}

// MARK: - Private Funcs
private extension CellularPairingSuccessViewController {
    /// Inits the view.
    func initView() {
        panelView.customCornered(corners: [.topLeft, .topRight], radius: Style.largeCornerRadius)
        closeButton.setImage(Asset.Common.Icons.icClose.image, for: .normal)
        titleLabel.text = L10n.cellularConfigurationSucceed
        descriptionLabel.text = L10n.cellularConfigurationSucceedReadyToUse
        okButton.cornerRadiusedWith(backgroundColor: ColorName.greenMediumSea.color,
                                    radius: Style.largeCornerRadius)
        okButton.setTitle(L10n.ok, for: .normal)
    }
}
