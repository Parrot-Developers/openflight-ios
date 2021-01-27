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

/// Confirm the success or the error of the cellular configuration login.
final class CellularPairingProcessViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var panelView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var okButton: UIButton!
    @IBOutlet private weak var closeButton: UIButton!

    // MARK: - Private Properties
    private weak var coordinator: HUDCoordinator?
    private var viewModel: CellularPairingProcessViewModel?

    // MARK: - Setup
    /// Instantiates the view controller.
    ///
    /// - Parameters:
    ///     - coordinator: the HUD coordinator
    /// - Returns: The drone cellular pairing process view controller.
    static func instantiate(coordinator: HUDCoordinator) -> CellularPairingProcessViewController {
        let viewController = StoryboardScene.CellularPairingProcess.initialScene.instantiate()
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
private extension CellularPairingProcessViewController {
    @IBAction func closeButtonTouchedUpInside(_ sender: Any) {
        coordinator?.dismiss()
    }

    @IBAction func backgroundButtonTouchedUpInside(_ sender: Any) {
        coordinator?.dismiss()
    }

    @IBAction func okButtonTouchedUpInside(_ sender: Any) {
        coordinator?.dismiss {
            if self.viewModel?.isPinCodeRequested == true {
                self.coordinator?.displayCellularPinCode()
            }
        }
    }
}

// MARK: - Private Funcs
private extension CellularPairingProcessViewController {
    /// Inits the view.
    func initView() {
        panelView.addBlurEffect()
        panelView.isHidden = true
        closeButton.setImage(Asset.Common.Icons.icClose.image,
                             for: .normal)
        titleLabel.makeUp(with: .huge)
        titleLabel.text = L10n.cellularConfigurationSucceed
        descriptionLabel.text = L10n.cellularConfigurationSucceedReadyToUse
        descriptionLabel.makeUp(with: .large)
        okButton.makeup(with: .large)
        okButton.cornerRadiusedWith(backgroundColor: ColorName.greenPea.color,
                                    radius: Style.largeCornerRadius)
        okButton.setTitle(L10n.ok,
                          for: .normal)
    }

    /// Inits view model.
    func initViewModel() {
        viewModel = CellularPairingProcessViewModel(stateDidUpdate: { [weak self] state in
            self?.updateView(pairingState: state)
        })
    }

    /// Updates the view according to the current process state.
    ///
    /// - Parameters:
    ///     - pairingState: current pairing process state
    func updateView(pairingState: CellularPairingProcessState) {
        guard pairingState.pairingProcessStep == .pairingProcessSuccess else {
            switch pairingState.pairingProcessError {
            case .connectionUnreachable,
                 .unableToConnect,
                 .unauthorizedUser,
                 .serverError:
                DispatchQueue.main.async { [weak self] in
                    self?.showAlert(error: pairingState.pairingProcessError)
                }
            default:
                break
            }

            return
        }

        showPanel()
    }

    /// Shows configuration success panel.
    func showPanel() {
        UIView.animate(withDuration: Style.shortAnimationDuration, animations: {
            self.panelView.isHidden = false
        })
    }

    /// Shows an alert when pairing process fails.
    ///
    /// - Parameters:
    ///     - error: error of the alert
    func showAlert(error: PairingProcessError?) {
        let validateAction = AlertAction(title: L10n.commonRetry, actionHandler: { [weak self] in
            self?.viewModel?.retryPairingProcess()
        })

        let cancelAction = AlertAction(title: L10n.cancel, actionHandler: { [weak self] in
            self?.coordinator?.dismiss()
        })

        self.showCustomAlert(title: L10n.cellularConnectionFailedToConnect,
                             message: error?.alertMessage ?? L10n.cellularConnectionServerError,
                             cancelAction: cancelAction,
                             validateAction: validateAction)
    }

    /// Show an alert view controller.
    ///
    /// - Parameters:
    ///     - title: alert title
    ///     - message: alert message
    ///     - cancelAction: alert cancel action
    ///     - validateAction: alert validate action
    func showCustomAlert(title: String,
                         message: String,
                         cancelAction: AlertAction = AlertAction(title: L10n.cancel),
                         validateAction: AlertAction? = nil) {
        let alert = AlertViewController.instantiate(title: title,
                                                    message: message,
                                                    cancelAction: cancelAction,
                                                    validateAction: validateAction)

        self.present(alert, animated: true)
    }
}
