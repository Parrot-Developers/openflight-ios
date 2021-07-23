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

/// Class responsible of connection between the remote and a selected drone.

final class PairingConnectDroneDetailViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var connectButton: UIButton!
    @IBOutlet private weak var connectionStateLabel: UILabel!
    @IBOutlet private weak var connectionStateImageView: UIImageView!
    @IBOutlet private weak var passwordView: UIView!
    @IBOutlet private weak var passwordField: UITextField!
    @IBOutlet private weak var passwordErrorView: UIView!
    @IBOutlet private weak var passwordErrorLabel: UILabel!
    @IBOutlet private weak var passwordDescriptionView: UIView!
    @IBOutlet private weak var passwordSecurityButton: UIButton!
    @IBOutlet private weak var passwordDescriptionLabel: UILabel!

    // MARK: - Private Properties
    private weak var coordinator: PairingCoordinator?
    private var password: String = String()
    private let viewModel = PairingConnectDroneViewModel()
    private var droneModel: RemoteConnectDroneModel?
    private var isBadPwd: Bool = false

    // MARK: - Setup
    static func instantiate(coordinator: Coordinator, droneModel: RemoteConnectDroneModel) -> PairingConnectDroneDetailViewController {
        let viewController = StoryboardScene.PairingConnectDroneDetails.initialScene.instantiate()
        viewController.droneModel = droneModel
        viewController.coordinator = coordinator as? PairingCoordinator
        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        // Listen state from the view model.
        viewModel.state.valueChanged = {[weak self] state in
            self?.updatePairingConnectDroneState(state)
        }

        initView()
        updatePairingConnectDroneState(viewModel.state.value)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.pairingDroneFinderConnection, logType: .screen)
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }

    /// Change button style when orientation changed.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        updateConnectButton()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension PairingConnectDroneDetailViewController {
    @IBAction func backButtonTouchedUpInside(_ sender: Any) {
        coordinator?.back()
        // Stop connection if we come back to the list.
        viewModel.resetDroneConnectionStateRef()
    }

    @IBAction func passwordSecurityButtonTouchedUpInside(_ sender: Any) {
        passwordField.toggleVisibility()
        passwordSecurityButton.setImage(passwordField.isSecureTextEntry ?
            Asset.Common.Icons.icPasswordShow.image :
            Asset.Common.Icons.icPasswordHide.image, for: .normal)
    }

    @IBAction func connectButtonTouchedUpInside(_ sender: Any) {
        viewModel.connectDrone(uid: droneModel?.droneUid ?? "", password: self.password)
        LogEvent.logAppEvent(itemName: LogEvent.LogKeyPairingButton.connectToDroneUsingPassword.name,
                             newValue: nil,
                             logType: .button)
    }
}

// MARK: - Private Funcs
private extension PairingConnectDroneDetailViewController {
    /// Init the view.
    func initView() {
        passwordView.cornerRadiusedWith(backgroundColor: .white,
                                        borderColor: .clear,
                                        radius: Style.largeCornerRadius)
        passwordView.addShadow(shadowColor: ColorName.whiteAlbescent.color)
        passwordField.attributedPlaceholder = NSAttributedString(string: L10n.commonPassword,
                                                                 attributes: [NSAttributedString.Key.foregroundColor: ColorName.defaultTextColor.color])
        passwordField.delegate = self
        passwordDescriptionLabel.text = L10n.pairingRemoteDroneForgotPassword
        passwordErrorLabel.text = L10n.pairingRemoteDronePasswordIncorrect
        titleLabel.text = L10n.pairingRemoteDroneConnectTo(droneModel?.droneName ?? "")

        // Connection state visibility.
        connectButton.setTitle(L10n.pairingRemoteDroneConnect, for: .normal)
        connectButton.isHidden = false
        connectButton.applyCornerRadius(Style.largeCornerRadius)
        connectionStateImageView.isHidden = true
        connectionStateLabel.isHidden = true
        updateConnectButton()
        enabledButtonInteraction()
    }

    /// Update with pairing connect drone state.
    ///
    /// - Parameters:
    ///    - state: pairing connect drone state
    func updatePairingConnectDroneState(_ state: PairingConnectDroneState) {
        // Come back to pairing menu if the remote is disconnected or if the remote is connected to a drone.
        if state.remoteControlConnectionState?.isConnected() == false ||
            state.droneConnectionState?.isConnected() == true {
            coordinator?.dismissRemoteConnectDrone()
        } else {
            updateConnectionView()
        }
    }

    /// Update connection view with label error and connection state.
    func updateConnectionView() {
        connectButton.isHidden = true
        connectionStateLabel.text = nil
        connectionStateLabel.isHidden = true
        connectionStateImageView.isHidden = true
        passwordErrorView.isHidden = true
        connectionStateImageView.stopRotate()
        isBadPwd = false

        if viewModel.state.value.connectionState == PairingDroneConnectionState.connecting {
            connectionStateLabel.isHidden = false
            connectionStateImageView.isHidden = false
            connectionStateLabel.text = L10n.connecting
            // Launch connection indicator animation.
            connectionStateImageView.startRotate()
        } else if viewModel.state.value.connectionState == PairingDroneConnectionState.incorrectPassword {
            viewModel.resetDroneConnectionStateRef()
            passwordErrorView.isHidden = false
            connectButton.isHidden = false
        } else if viewModel.state.value.connectionState == PairingDroneConnectionState.connected {
            // Come back to pairing menu when drone is connected.
            coordinator?.dismissRemoteConnectDrone()
        } else {
            connectButton.isHidden = false
        }
    }

    /// Enable user interaction on button.
    func enabledButtonInteraction() {
        // We need to disable user interaction if the field is empty.
        if password.isEmpty {
            connectButton.isEnabled = false
        } else {
            connectButton.isEnabled = true
        }
    }

    /// Update the connecting button
    func updateConnectButton() {
        connectButton.cornerRadiusedWith(backgroundColor: UIApplication.isLandscape ? .clear : ColorName.highlightColor.color,
                                         borderColor: .clear,
                                         radius: Style.largeCornerRadius)
        connectButton.makeup(with: .large, color: UIApplication.isLandscape ? .highlightColor : .white, and: .normal)
        connectButton.makeup(with: .large, color: UIApplication.isLandscape ? .disabledHighlightColor : .white20, and: .disabled)
    }
}

// MARK: - PairingConnectDroneDetailViewController TextField Delegate
extension PairingConnectDroneDetailViewController: UITextFieldDelegate {
    /// Func used to notify controller when user enter character in the password field.
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text as NSString? {
            password = text.replacingCharacters(in: range, with: string)
        }
        enabledButtonInteraction()
        return true
    }

    /// Callback used to dismiss the keyboard when we press return key on keyboard.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
