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

/// Custom alert action where the action handler is public.
public final class AlertAction {
    /// Action title.
    var title: String?
    /// Action style.
    var style: ActionButtonStyle?
    /// Action border width. Will layout a bordered action button with .clear bkg if defined.
    var borderWidth: CGFloat?
    /// Action handler.
    var actionHandler: (() -> Void)?
    /// Specifies whether `actionHandler` needs to wait for alert dismissal before being triggered.
    var isActionDelayedAfterDismissal: Bool

    /// Init.
    ///
    /// - Parameters:
    ///     - title: Action title.
    ///     - style: Action style.
    ///     - cancelCustomColor: Custom color for cancel button.
    ///     - isActionDelayedAfterDismissal: Whether `actionHandler` needs to wait for alert dismissal before being triggered.
    ///     - actionHandler: Action handler.
    public init(title: String,
                style: ActionButtonStyle? = nil,
                borderWidth: CGFloat? = nil,
                isActionDelayedAfterDismissal: Bool = true,
                actionHandler: (() -> Void)? = nil) {
        self.title = title
        self.style = style
        self.borderWidth = borderWidth
        self.actionHandler = actionHandler
        self.isActionDelayedAfterDismissal = isActionDelayedAfterDismissal
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
    @IBOutlet private weak var cancelButton: ActionButton! {
        didSet {
            cancelButton.cornerRadiusedWith(backgroundColor: ColorName.whiteAlbescent.color,
                                            borderColor: .clear,
                                            radius: Style.mediumCornerRadius,
                                            borderWidth: Style.noBorderWidth)
            cancelButton.setTitle(L10n.cancel, for: .normal)
            cancelButton.setTitleColor(ColorName.defaultTextColor.color, for: .normal)
        }
    }
    @IBOutlet private weak var validateButton: ActionButton! {
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

    @IBOutlet private weak var secondaryActionButton: ActionButton! {
        didSet {
            secondaryActionButton.titleLabel?.adjustsFontSizeToFitWidth = true
            secondaryActionButton.titleLabel?.minimumScaleFactor = Constants.minimumFontScale
            secondaryActionButton.cornerRadiusedWith(backgroundColor: ColorName.highlightColor.color,
                                                     borderColor: .clear,
                                                     radius: Style.mediumCornerRadius,
                                                     borderWidth: Style.noBorderWidth)
            secondaryActionButton.setTitle(L10n.commonYes, for: .normal)
            secondaryActionButton.setTitleColor(.white, for: .normal)
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
    override public var shouldAutorotate: Bool {
        return false
    }
    public var supportedOrientation: UIInterfaceOrientationMask = .landscapeRight
    public var preferredOrientation: UIInterfaceOrientation = .unknown
    override public var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return preferredOrientation
    }

    // MARK: - Private Properties
    private var message: String?
    private var closeButtonStyle: CloseButtonStyle?
    private var messageColor: ColorName = .defaultTextColor
    private var cancelAction: AlertAction?
    private var validateAction: AlertAction?
    private var secondaryAction: AlertAction?

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
    ///     - secondaryAction: Secondary action (add a vertically stacked button below validate if not `nil`).
    public static func instantiate(title: String,
                                   message: String,
                                   messageColor: ColorName = .defaultTextColor,
                                   closeButtonStyle: CloseButtonStyle? = nil,
                                   cancelAction: AlertAction? = nil,
                                   validateAction: AlertAction?,
                                   secondaryAction: AlertAction? = nil) -> AlertViewController {
        let viewController = StoryboardScene.AlertViewController.initialScene.instantiate()
        viewController.title = title
        viewController.message = message
        viewController.cancelAction = cancelAction
        viewController.validateAction = validateAction
        viewController.secondaryAction = secondaryAction
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
    public func dismissAlert(animated: Bool = true, completion: (() -> Void)? = nil) {
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
        guard cancelAction?.isActionDelayedAfterDismissal ?? false else {
            cancel()
            dismissAlert()
            return
        }

        dismissAlert { [weak self] in
            self?.cancel()
        }
    }

    /// Cancel button touched.
    @IBAction func cancelButtonTouchedUpInside(_ sender: Any) {
        guard cancelAction?.isActionDelayedAfterDismissal ?? false else {
            cancelAction?.actionHandler?()
            dismissAlert()
            return
        }

        dismissAlert { [weak self] in
            self?.cancelAction?.actionHandler?()
        }
    }

    /// Confirm button touched.
    @IBAction func confirmButtonTouchedUpInside(_ sender: Any) {
        guard validateAction?.isActionDelayedAfterDismissal ?? false else {
            validateAction?.actionHandler?()
            dismissAlert()
            return
        }

        dismissAlert { [weak self] in
            self?.validateAction?.actionHandler?()
        }
    }

    /// Secondary action button touched.
    @IBAction func secondaryActionButtonTouchedUpInside(_ sender: Any) {
        guard secondaryAction?.isActionDelayedAfterDismissal ?? false else {
            secondaryAction?.actionHandler?()
            dismissAlert()
            return
        }

        dismissAlert { [weak self] in
            self?.secondaryAction?.actionHandler?()
        }
    }
}

// MARK: - Private Funcs
private extension AlertViewController {
    /// Sets up the alert view.
    func setupView() {
        self.view.backgroundColor = .clear
        alertTitle.text = title
        alertTitle.font = FontStyle.title.font(isRegularSizeClass)
        alertMessage.text = message
        alertMessage.font = FontStyle.readingText.font(isRegularSizeClass)
        alertMessage.textColor = messageColor.color

        // MARK: - Cancel action
        if cancelAction != nil {
            setupButtonAction(cancelButton,
                              withStyle: cancelAction?.style ?? .default2,
                              titleButton: cancelAction?.title ?? L10n.cancel,
                              borderWidth: cancelAction?.borderWidth)
        } else {
            cancelButton.isHidden = true
        }

        // MARK: - Validate action
        if let validateActionTitle = validateAction?.title {
            setupButtonAction(validateButton,
                              withStyle: validateAction?.style ?? .validate,
                              titleButton: validateActionTitle,
                              borderWidth: validateAction?.borderWidth)
        } else {
            validateButton.isHidden = true
        }

        // MARK: - Secondary action
        if let secondaryActiontitle = secondaryAction?.title {
            setupButtonAction(secondaryActionButton,
                              withStyle: secondaryAction?.style ?? .validate,
                              titleButton: secondaryActiontitle,
                              borderWidth: secondaryAction?.borderWidth)
        } else {
            secondaryActionButton.isHidden = true
        }

        if let closeStyle = closeButtonStyle {
            closeButton.setImage(closeStyle.image.withRenderingMode(.alwaysTemplate), for: .normal)
        }
        closeButton.isHidden = closeButtonStyle == nil
    }

    /// Updates buttons stack view.
    func updateButtonsStackView() {
        buttonsStackView.axis = UIApplication.isLandscape ? .horizontal : .vertical
        buttonsStackView.spacing = UIApplication.isLandscape ? Constants.horizontalSpacing : Constants.verticalSpacing
    }

    /// Cancels action.
    func cancel() {
        // Call cancel handler only if it is a cancel action style.
        guard cancelAction?.style == .default2 else { return }

        cancelAction?.actionHandler?()
    }

    /// Sets up button regarding style.
    ///
    /// - Parameters:
    ///    - button: button to customize
    ///    - style: style to apply
    ///    - titleButton: title of the button
    ///    - borderWidth: layout a bordered button if not `nil`, plain button otherwise.
    ///    - cancelCustomColor: custom color to apply
    func setupButtonAction(_ button: ActionButton,
                           withStyle style: ActionButtonStyle,
                           titleButton: String,
                           borderWidth: CGFloat? = nil) {
        button.setup(title: titleButton, style: style)

        // MARK: - Set border width
        if borderWidth != nil {
            button.cornerRadiusedWith(backgroundColor: .clear,
                                      borderColor: style.backgroundColor,
                                      radius: Style.mediumCornerRadius,
                                      borderWidth: borderWidth ?? Style.noBorderWidth)
            button.layer.shadowOpacity = 0
            button.setTitleColor(style.backgroundColor, for: .normal)
        }
    }
}
