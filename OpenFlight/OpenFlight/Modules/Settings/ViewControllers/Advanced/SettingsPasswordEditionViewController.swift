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
import GroundSdk

/// Dedicated view controller to edit drone wifi password.
final class SettingsPasswordEditionViewController: UIViewController, StoryboardBased {
    // MARK: _ Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var warningLabel: UILabel!
    @IBOutlet private weak var passwordTextField: POFTextField!
    @IBOutlet private weak var confirmPasswordTextField: POFTextField!
    @IBOutlet private weak var passwordWarningLabel: UILabel!
    @IBOutlet private weak var changePasswordButton: ActionButton!
    @IBOutlet private weak var cancelButton: ActionButton!
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var contentScrollView: UIScrollView!
    @IBOutlet private weak var textfieldsContainer: UIView!
    @IBOutlet private weak var scrollViewBottomConstraint: NSLayoutConstraint!

    // MARK: _ Private Properties
    private var coordinator: Coordinator?
    private var viewModel: SettingsNetworkViewModel?
    private var isValidPassword: Bool {
        var isValid = false
        if let password = passwordTextField.text,
           WifiPasswordUtil.isValid(password),
           password.count >= 10 {
            let patterns = ["[a-z]", "[A-Z]", "[0-9]", "[!@#$%&/=?_.,:;\\-]"]
            var count = 0
            for pattern in patterns {
                if password.range(of: pattern, options: .regularExpression) != nil {
                    count += 1
                }
            }
            isValid = count >= 3
        }
        passwordWarningLabel.text = L10n.settingsEditPasswordSecurityDescription
        passwordWarningLabel.textColor = isValid ? ColorName.defaultTextColor.color : ColorName.errorColor.color

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
            passwordWarningLabel.textColor = ColorName.errorColor.color
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
        setupUI()
        setupKeyboardNotifications()
        setupTapGesture()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupBackgroundOverlayAnimation()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    // MARK: - UI
    /// Setup UI
    private func setupUI() {
        // Labels
        titleLabel.text = L10n.settingsEditPasswordTitle
        warningLabel.text = L10n.settingsEditPasswordWarning
        passwordWarningLabel.text = L10n.settingsEditPasswordSecurityDescription

        // Colors
        view.backgroundColor = ColorName.clear.color
        backgroundView.backgroundColor = ColorName.clear.color
        contentScrollView.backgroundColor = ColorName.white.color
        passwordTextField.backgroundColor = ColorName.whiteAlbescent.color
        confirmPasswordTextField.backgroundColor = ColorName.whiteAlbescent.color

        // Custom
        contentScrollView.customCornered(
            corners: [.topLeft, .topRight],
            radius: Style.largeCornerRadius)

        // Setup textfields
        passwordTextField.delegate = self
        passwordTextField.secureEntryDelegate = self
        passwordTextField.setPlaceholderTitle(L10n.settingsEditPasswordTitle)
        confirmPasswordTextField.delegate = self
        confirmPasswordTextField.secureEntryDelegate = self
        confirmPasswordTextField.setPlaceholderTitle(L10n.settingsEditPasswordConfirmPassword)

        // Buttons
        changePasswordButton.model = ActionButtonModel(title: L10n.settingsEditPasswordChangePassword,
                                                       style: .action1)

        cancelButton.model = ActionButtonModel(title: L10n.cancel,
                                               style: .default2)
    }

    /// Register for keyboard notifications display
    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardNotificationHandler(sender:)),
            name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardNotificationHandler(sender:)),
            name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    /// Setup tap gesture
    private func setupTapGesture() {
        // Dismiss keyboard on tap view
        let tapGestureDismissKeyboard = UITapGestureRecognizer.init(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGestureDismissKeyboard)

        // Dismiss VC on tap backgroundView
        let tapGestureDismissVC = UITapGestureRecognizer.init(target: self, action: #selector(dismissTapHandlers))
        backgroundView.addGestureRecognizer(tapGestureDismissVC)
    }

    /// Present VC overlay animation
    private func setupBackgroundOverlayAnimation() {
        UIView.animate(
            withDuration: Style.shortAnimationDuration,
            delay: Style.shortAnimationDuration,
            animations: {
                self.view.backgroundColor = ColorName.nightRider80.color
            })
    }

    // MARK: _ Handlers
    /// Dismiss view controller
    private func dismissVC() {
        view.backgroundColor = ColorName.clear.color
        coordinator?.dismiss()
    }

    /// Handle dismiss tap backgroundView
    @objc func dismissTapHandlers() {
        if passwordTextField.isFirstResponder || confirmPasswordTextField.isFirstResponder {
            dismissKeyboard()
        } else {
            dismissVC()
        }
    }

    /// Dismiss keyboard
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    /// Handle keyboard notification display
    @objc private func keyboardNotificationHandler(sender notification: Notification) {
        var animationDuration = 0.30

        // get the animation duration
        if let animationDurationVal = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval {
            animationDuration = animationDurationVal
        }

        // keyboard will display
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            scrollViewBottomConstraint.constant = keyboardFrame.cgRectValue.size.height
        }

        // keyboard will dismiss
        if notification.name == UIResponder.keyboardWillHideNotification {
            scrollViewBottomConstraint.constant = 0.0
        }

        UIView.animate(withDuration: animationDuration, animations: {
            self.view.layoutIfNeeded()
        })
    }
}

// MARK: - Actions
private extension SettingsPasswordEditionViewController {
    /// Close action.
    @IBAction func closeButtonTouchedUpInside(_ sender: Any) {
        LogEvent.log(.simpleButton(LogEvent.LogKeyCommonButton.cancel))
        dismissVC()
    }

    /// Change password action.
    @IBAction func changeButtonTouchedUpInside(_ sender: Any) {
        LogEvent.log(.button(item: LogEvent.LogKeyWifiPasswordEdition.changePassword,
                             value: isValidPassword.description))
        guard isValidPassword,
              isValidConfirmPassword,
              let password = passwordTextField.text else {
                  return
              }

        view.endEditing(true)
        let validateAction = AlertAction(title: L10n.settingsEditPasswordValidateChange, actionHandler: { [weak self] in
            if self?.viewModel?.changePassword(password) ?? false {
                self?.dismissVC()
            }
        })
        showAlert(title: L10n.commonWarning,
                  message: L10n.settingsEditPasswordDescription,
                  validateAction: validateAction)
    }
}

// MARK: - UITextField Delegate
extension SettingsPasswordEditionViewController: UITextFieldDelegate, POFTextFieldDelegate {
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

    func didTapToggleSecureEntry(sender: POFTextField, isSecure: Bool) {
        if passwordTextField.isFirstResponder {
            confirmPasswordTextField.toggleSecureEntry(force: isSecure)
        } else {
            passwordTextField.toggleSecureEntry(force: isSecure)
        }
    }
}
