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

/// Displays a suggestion screen to tell that cellular connection is available.
final class CellularConfigurationViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var laterButton: UIButton!
    @IBOutlet private weak var configureButton: UIButton!
    @IBOutlet private weak var panelView: UIView!
    @IBOutlet private weak var closeButton: UIButton!

    // MARK: - Private Properties
    private weak var coordinator: HUDCoordinator?
    private var viewModel: CellularConfigurationViewModel = CellularConfigurationViewModel()

    // MARK: - Setup
    static func instantiate(coordinator: HUDCoordinator) -> CellularConfigurationViewController {
        let viewController = StoryboardScene.CellularConfiguration.initialScene.instantiate()
        viewController.coordinator = coordinator

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        initViewModel()
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
private extension CellularConfigurationViewController {
    @IBAction func backgroundButtonTouchedUpInside(_ sender: Any) {
        dismissPairing()
    }

    @IBAction func laterButtonTouchedUpInside(_ sender: Any) {
        dismissPairing()
    }

    @IBAction func configureButtonTouchedUpInside(_ sender: Any) {
        coordinator?.dismissConfigurationScreen()
    }

    @IBAction func closeButtonTouchedUpInside(_ sender: Any) {
        dismissPairing()
    }
}

// MARK: - Private Funcs
private extension CellularConfigurationViewController {
    /// Inits the view.
    func initView() {
        panelView.addBlurEffect()
        closeButton.setImage(Asset.Common.Icons.icClose.image,
                             for: .normal)
        laterButton.setTitle(L10n.commonLater,
                             for: .normal)
        configureButton.setTitle(L10n.cellularConnectionAvailableConfigure,
                                 for: .normal)
        descriptionLabel.text = L10n.cellularConnectionAvailableSimDetected
            + Style.newLine
            + L10n.cellularConnectionAvailableConfigureNow
        titleLabel.text = L10n.cellularConnectionAvailable
        titleLabel.makeUp(with: .huge)
        descriptionLabel.makeUp(with: .large)
        laterButton.makeup(with: .large)
        configureButton.makeup(with: .large)
        configureButton.cornerRadiusedWith(backgroundColor: ColorName.greenPea.color,
                                           radius: Style.largeCornerRadius)
        laterButton.cornerRadiusedWith(backgroundColor: ColorName.white20.color,
                                       radius: Style.largeCornerRadius)
    }

    /// Inits the view model.
    func initViewModel() {
        viewModel.state.valueChanged = { [weak self] state in
            self?.updateView(state: state)
        }
    }

    /// Updates view.
    ///
    /// - Parameters:
    ///     - state: device connection state
    func updateView(state: DeviceConnectionState) {
        guard !state.isConnected() else { return }

        coordinator?.dismiss()
    }

    /// Dismisses pairing process screens.
    func dismissPairing() {
        viewModel.dismissPairingScreen()
        coordinator?.dismiss()
    }
}
