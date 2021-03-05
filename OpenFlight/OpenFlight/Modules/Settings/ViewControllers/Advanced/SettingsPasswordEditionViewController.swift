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
import GroundSdk

/// Dedicated view controller to edit drone wifi password.
final class SettingsPasswordEditionViewController: UIViewController, StoryboardBased {
    // MARK: - Outlets
    @IBOutlet private weak var bgView: UIView! {
        didSet {
            bgView.backgroundColor = ColorName.white10.color
        }
    }
    @IBOutlet private weak var titleLabel: UILabel! {
        didSet {
            titleLabel.makeUp(with: .huge)
            titleLabel.text = L10n.settingsEditPasswordTitle
        }
    }
    @IBOutlet private weak var warningLabel: UILabel! {
        didSet {
            warningLabel.makeUp(with: .big, and: .orangePeel)
            warningLabel.text = L10n.settingsEditPasswordWarning
        }
    }
    @IBOutlet private weak var passwordTextField: UITextField! {
        didSet {
            passwordTextField.makeUp(style: .large, bgColor: .white20)
            passwordTextField.attributedPlaceholder = NSAttributedString(
                string: L10n.settingsEditPasswordTitle,
                attributes: [NSAttributedString.Key.foregroundColor: ColorName.white50.color])
        }
    }
    @IBOutlet private weak var passwordWarningLabel: UILabel! {
        didSet {
            passwordWarningLabel.makeUp()
            passwordWarningLabel.text = L10n.settingsEditPasswordSecurityDescription
        }
    }
    @IBOutlet private weak var confirmPasswordTextField: UITextField! {
        didSet {
            confirmPasswordTextField.makeUp(style: .large, bgColor: .white20)
            confirmPasswordTextField.attributedPlaceholder = NSAttributedString(
                string: L10n.settingsEditPasswordConfirmPassword,
                attributes: [NSAttributedString.Key.foregroundColor: ColorName.white50.color])
        }
    }
    @IBOutlet private weak var changePasswordButton: UIButton! {
        didSet {
            changePasswordButton.makeup(with: .large)
            changePasswordButton.cornerRadiusedWith(backgroundColor: ColorName.greenSpring20.color,
                                                    borderColor: ColorName.greenSpring20.color,
                                                    radius: Style.mediumCornerRadius)
            changePasswordButton.setTitle(L10n.settingsEditPasswordChangePassword, for: .normal)
        }
    }
    @IBOutlet private weak var cancelButton: UIButton! {
        didSet {
            cancelButton.makeup(with: .large)
            cancelButton.cornerRadiusedWith(backgroundColor: .clear,
                                            borderColor: ColorName.white.color,
                                            radius: Style.mediumCornerRadius,
                                            borderWidth: Style.largeBorderWidth)
            cancelButton.setTitle(L10n.cancel, for: .normal)
        }
    }
    @IBOutlet private weak var toggleConfirmVisibilityButton: UIButton!
    @IBOutlet private weak var togglePasswordVisibilityButton: UIButton!
    @IBOutlet private weak var contentScrollView: UIScrollView!
    @IBOutlet private weak var textfieldsContainer: UIView!
    @IBOutlet private weak var scrollViewBottomConstraint: NSLayoutConstraint!

    // MARK: - Private Properties
    private var coordinator: Coordinator?
    private var viewModel: SettingsNetworkViewModel?
    private var isValidPassword: Bool {
        var isValid = false
        if let password = passwordTextField.text, WifiPasswordUtil.isValid(password) {
            isValid = true
        }
        passwordWarningLabel.text = L10n.settingsEditPasswordSecurityDescription
        passwordWarningLabel.textColor = isValid ? ColorName.white50.color : ColorName.redTorch50.color

        return isValid
    }
    private var isValidConfirmPassword: Bool {
        var isValid = false
        if let password = passwordTextField.text,
           let confirm = confirmPasswordTextField.text,
           password == confirm {
            passwordWarningLabel.text = ""
            isValid = true
        } else {
            passwordWarningLabel.text = L10n.settingsEditPasswordMatchError
            passwordWarningLabel.textColor = ColorName.redTorch50.color
        }
        return isValid
    }
    private var orientation: UIInterfaceOrientationMask = .landscape

    // MARK: - Init
    /// Inits view controller.
    ///
    /// - Parameters:
    ///     - coordinator: coordinator
    ///     - viewModel: Network view model
    ///     - orientation: interface orientation
    /// - Returns: The drone password edition view controller.
    static func instantiate(coordinator: Coordinator,
                            viewModel: SettingsNetworkViewModel?,
                            orientation: UIInterfaceOrientationMask = .landscape) -> SettingsPasswordEditionViewController {
        let viewController = StoryboardScene.SettingsNetworkViewController.settingsPasswordEditionViewController.instantiate()
        viewController.coordinator = coordinator
        viewController.orientation = orientation
        viewController.viewModel = viewModel

        return viewController
    }

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = ColorName.black.color

        // Setup textfields.
        passwordTextField.delegate = self
        passwordTextField.rightView = togglePasswordVisibilityButton
        passwordTextField.rightViewMode = .always
        confirmPasswordTextField.rightView = toggleConfirmVisibilityButton
        confirmPasswordTextField.rightViewMode = .always
        confirmPasswordTextField.delegate = self

        // Manage keyboard appearance.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(sender:)),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(sender:)),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return orientation
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension SettingsPasswordEditionViewController {
    /// Close action.
    @IBAction func closeButtonTouchedUpInside(_ sender: Any) {
        LogEvent.logAppEvent(itemName: LogEvent.LogKeyCommonButton.cancel,
                             newValue: nil,
                             logType: .button)
        self.coordinator?.back()
    }

    /// Toggle password visibility action.
    @IBAction func toggleButtonTouchedUpInside(_ sender: Any) {
        passwordTextField.toggleVisibility()
        togglePasswordVisibilityButton.setImage(passwordTextField.isSecureTextEntry ?
                                                    Asset.Common.Icons.icPasswordShow.image :
                                                    Asset.Common.Icons.icPasswordHide.image, for: .normal)
    }

    /// Toggle confirm password visibility action.
    @IBAction func toggleConfirmButtonTouchedUpInside(_ sender: Any) {
        confirmPasswordTextField.toggleVisibility()
        toggleConfirmVisibilityButton.setImage(confirmPasswordTextField.isSecureTextEntry ?
                                                Asset.Common.Icons.icPasswordShow.image :
                                                Asset.Common.Icons.icPasswordHide.image, for: .normal)
    }

    /// Change password action.
    @IBAction func changeButtonTouchedUpInside(_ sender: Any) {
        LogEvent.logAppEvent(itemName: LogEvent.LogKeyWifiPasswordEdition.changePassword,
                             newValue: isValidPassword.description,
                             logType: .button)
        guard isValidPassword,
              isValidConfirmPassword,
              let password = passwordTextField.text else {
            return
        }

        self.view.endEditing(true)
        let validateAction = AlertAction(title: L10n.settingsEditPasswordValidateChange, actionHandler: { [weak self] in
            if self?.viewModel?.changePassword(password) ?? false {
                self?.coordinator?.back()
            }
        })
        self.showAlert(title: L10n.commonWarning,
                       message: L10n.settingsEditPasswordDescription,
                       validateAction: validateAction)
    }
}

// MARK: - Private Funcs
private extension SettingsPasswordEditionViewController {
    /// Manages view display when keyboard is displayed.
    @objc func keyboardWillShow(sender: NSNotification) {
        if let userInfo = sender.userInfo,
           let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            // Move view upward.
            scrollViewBottomConstraint.constant = keyboardFrame.size.height
        }
    }

    /// Manages view display after keyboard was displayed.
    @objc func keyboardWillHide(sender: NSNotification) {
        // Move view to original position.
        scrollViewBottomConstraint.constant = 0.0
    }
}

// MARK: - UITextField Delegate
extension SettingsPasswordEditionViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Handle responder + tooltip message (passwordWarningLabel).
        if textField == passwordTextField, isValidPassword {
            confirmPasswordTextField.becomeFirstResponder()
        } else if textField == confirmPasswordTextField, isValidConfirmPassword {
            textField.resignFirstResponder()
        } else {
            // Make sure passwordWarningLabel is visible.
            var frame = textfieldsContainer.convert(passwordWarningLabel.frame, to: view)
            frame = CGRect(x: frame.origin.x,
                           // Modify frame to make passwordWarningLabel displayed properly.
                           y: frame.origin.y + frame.height*2.0,
                           width: frame.width,
                           height: frame.height)
            contentScrollView.scrollRectToVisible(frame, animated: true)
        }

        return true
    }
}
