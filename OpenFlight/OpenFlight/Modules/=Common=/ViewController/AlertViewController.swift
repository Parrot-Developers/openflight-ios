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

/// Custom alert action where the action handler is public.
public final class AlertAction {
    /// Action title.
    var title: String?
    /// Action style.
    var style: UIAlertAction.Style?
    /// Custom background color for cancel button.
    var cancelCustomColor: ColorName?
    /// Action handler.
    var actionHandler: (() -> Void)?

    /// Init.
    ///
    /// - Parameters:
    ///     - title: action title
    ///     - style: action style
    ///     - cancelCustomColor: custom color for cancel button
    ///     - actionHandler: action handler
    public init(title: String,
                style: UIAlertAction.Style? = nil,
                cancelCustomColor: ColorName? = nil,
                actionHandler: (() -> Void)? = nil) {
        self.title = title
        self.style = style
        self.actionHandler = actionHandler
        self.cancelCustomColor = cancelCustomColor
    }
}

/// Custom alert view controller.
public final class AlertViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var alertBackground: UIView! {
        didSet {
            alertBackground.backgroundColor = ColorName.white.color
            alertBackground.applyCornerRadius(Constants.cornerRadius)
        }
    }
    @IBOutlet private weak var alertTitle: UILabel!
    @IBOutlet private weak var alertMessage: UILabel!
    @IBOutlet private weak var cancelButton: UIButton! {
        didSet {
            cancelButton.cornerRadiusedWith(backgroundColor: ColorName.whiteAlbescent.color,
                                            borderColor: .clear,
                                            radius: Style.mediumCornerRadius,
                                            borderWidth: Style.noBorderWidth)
            cancelButton.setTitle(L10n.cancel, for: .normal)
            cancelButton.setTitleColor(ColorName.defaultTextColor.color, for: .normal)
        }
    }
    @IBOutlet private weak var validateButton: UIButton! {
        didSet {
            validateButton.titleLabel?.adjustsFontSizeToFitWidth = true
            validateButton.titleLabel?.minimumScaleFactor = Constants.minimumFontScale
            validateButton.cornerRadiusedWith(backgroundColor: ColorName.highlightColor.color,
                                              borderColor: .clear,
                                              radius: Style.mediumCornerRadius,
                                              borderWidth: Style.noBorderWidth)
            validateButton.setTitle(L10n.commonYes, for: .normal)
            validateButton.setTitleColor(.white, for: .normal)
        }
    }
    @IBOutlet private weak var bgContentBottomConstraint: NSLayoutConstraint! {
        didSet {
            bgContentBottomConstraint.constant -= Constants.cornerRadius
        }
    }
    @IBOutlet private weak var buttonsStackView: UIStackView!
    @IBOutlet private weak var contentStackViewBottomConstraint: NSLayoutConstraint! {
        didSet {
            contentStackViewBottomConstraint.constant += Constants.cornerRadius
        }
    }
    @IBOutlet private weak var closeButton: UIButton!

    // MARK: - Private Properties
    private var message: String?
    private var closeButtonStyle: CloseButtonStyle?
    private var messageColor: ColorName = .defaultTextColor
    private var cancelAction: AlertAction?
    private var validateAction: AlertAction?

    // MARK: - Private Enums
    internal enum Constants {
        static let cornerRadius: CGFloat = 18.0
        static let horizontalSpacing: CGFloat = 40.0
        static let verticalSpacing: CGFloat = 16.0
        static let minimumFontScale: CGFloat = 0.7
    }

    // MARK: - Setup
    /// Instantiate View controller.
    ///
    /// - Parameters:
    ///     - title: Alert title
    ///     - message: Alert message
    ///     - messageColor: Alert message color
    ///     - closeButtonStyle: Style of potential close button
    ///     - cancelAction: Cancel action
    ///     - validateAction: Validate action
    public static func instantiate(title: String,
                                   message: String,
                                   messageColor: ColorName = .defaultTextColor,
                                   closeButtonStyle: CloseButtonStyle? = nil,
                                   cancelAction: AlertAction? = nil,
                                   validateAction: AlertAction?) -> AlertViewController {
        let viewController = StoryboardScene.AlertViewController.initialScene.instantiate()
        viewController.title = title
        viewController.message = message
        viewController.cancelAction = cancelAction
        viewController.validateAction = validateAction
        viewController.closeButtonStyle = closeButtonStyle
        viewController.messageColor = messageColor
        viewController.modalPresentationStyle = .overFullScreen

        return viewController
    }

    // MARK: - Override Funcs
    public override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        UIView.animate(withDuration: Style.shortAnimationDuration,
                       delay: Style.shortAnimationDuration,
                       animations: {
                        self.view.backgroundColor = ColorName.nightRider80.color
                       })
    }

    public override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }

    /// Handles orientation.
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        updateButtonsStackView()
    }

    // MARK: - Public Funcs
    /// Dismisses alert.
    ///
    /// - Parameters:
    ///     - animated: animated dismiss
    ///     - completion: completion block
    func dismissAlert(animated: Bool = true, completion: (() -> Void)? = nil) {
        self.view.backgroundColor = .clear
        self.dismiss(animated: animated, completion: completion)
    }
    @IBAction func closeButtonTouchedUpInside(_ sender: Any) {
        dismissAlert { [weak self] in
            self?.cancel()
        }
    }
}

// MARK: - Actions
private extension AlertViewController {
    /// Background button touched.
    @IBAction func backgroundButtonTouchedUpInside(_ sender: Any) {
        dismissAlert { [weak self] in
            self?.cancel()
        }
    }

    /// Cancel button touched.
    @IBAction func cancelButtonTouchedUpInside(_ sender: Any) {
        dismissAlert { [weak self] in
            self?.cancelAction?.actionHandler?()
        }
    }

    /// Confirm button touched.
    @IBAction func confirmButtonTouchedUpInside(_ sender: Any) {
        dismissAlert { [weak self] in
            self?.validateAction?.actionHandler?()
        }
    }
}

// MARK: - Private Funcs
private extension AlertViewController {
    /// Sets up the alert view.
    func setupView() {
        self.view.backgroundColor = .clear

        alertTitle.text = title
        alertMessage.text = message
        alertMessage.textColor = messageColor.color

        if cancelAction != nil {
            cancelButton.setTitle(cancelAction?.title ?? L10n.cancel, for: .normal)
            setupButton(cancelButton,
                        with: cancelAction?.style ?? .cancel,
                        cancelCustomColor: cancelAction?.cancelCustomColor)
        } else {
            cancelButton.isHidden = true
        }

        if let validateTitle = validateAction?.title {
            validateButton.setTitle(validateTitle, for: .normal)
        } else {
            validateButton.isHidden = true
        }

        if let closeStyle = closeButtonStyle {
            closeButton.setImage(closeStyle.image.withRenderingMode(.alwaysTemplate), for: .normal)
        }
        closeButton.isHidden = closeButtonStyle == nil

        setupButton(validateButton, with: validateAction?.style ?? .default)
        updateButtonsStackView()
    }

    /// Updates buttons stack view.
    func updateButtonsStackView() {
        buttonsStackView.axis = UIApplication.isLandscape ? .horizontal : .vertical
        buttonsStackView.spacing = UIApplication.isLandscape ? Constants.horizontalSpacing : Constants.verticalSpacing
    }

    /// Cancels action.
    func cancel() {
        // Call cancel handler only if it is a cancel action style.
        guard cancelAction?.style == .cancel else { return }

        cancelAction?.actionHandler?()
    }

    /// Sets up button regarding style.
    ///
    /// - Parameters:
    ///    - button: button to customize
    ///    - style: style to apply
    ///    - cancelCustomColor: custom color to apply
    func setupButton(_ button: UIButton,
                     with style: UIAlertAction.Style?,
                     cancelCustomColor: ColorName? = nil) {
        guard let style = style else { return }

        var color: UIColor = ColorName.highlightColor.color
        var textColor: UIColor = .white

        switch style {
        case .destructive:
            color = ColorName.errorColor.color
            textColor = .white
        case .cancel:
            if let backgroundColor = cancelCustomColor {
                color = backgroundColor.color
            } else {
                color = ColorName.whiteAlbescent.color
                textColor = ColorName.defaultTextColor.color
            }
        case .default:
            color = ColorName.highlightColor.color
            textColor = .white
        @unknown default:
            break
        }

        button.cornerRadiusedWith(backgroundColor: color,
                                  borderColor: .clear,
                                  radius: Style.mediumCornerRadius,
                                  borderWidth: Style.noBorderWidth)
        button.setTitleColor(textColor, for: .normal)
    }
}
