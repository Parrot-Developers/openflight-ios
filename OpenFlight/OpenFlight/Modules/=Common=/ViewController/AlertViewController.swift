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
    /// Action handler.
    var actionHandler: (() -> Void)?
    /// Action style.
    var style: UIAlertAction.Style?

    /// Init.
    ///
    /// - Parameters:
    ///     - title: action title
    ///     - style: action style
    ///     - actionHandler: action handler
    public init(title: String,
                style: UIAlertAction.Style? = nil,
                actionHandler: (() -> Void)? = nil) {
        self.title = title
        self.style = style
        self.actionHandler = actionHandler
    }
}

/// Custom alert view controller.
public final class AlertViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var alertBackground: UIView! {
        didSet {
            alertBackground.backgroundColor = ColorName.black.color
            alertBackground.applyCornerRadius(Constants.cornerRadius)
        }
    }
    @IBOutlet private weak var alertTitle: UILabel! {
        didSet {
            alertTitle.makeUp(with: .huge)
        }
    }
    @IBOutlet private weak var alertMessage: UILabel! {
        didSet {
            alertMessage.makeUp(with: .big)
        }
    }
    @IBOutlet private weak var cancelButton: UIButton! {
        didSet {
            cancelButton.makeup(with: .large, color: .white)
            cancelButton.cornerRadiusedWith(backgroundColor: .clear,
                                            borderColor: ColorName.white.color,
                                            radius: Style.mediumCornerRadius,
                                            borderWidth: Constants.cancelButtonBorderWidth)
            cancelButton.setTitle(L10n.cancel, for: .normal)
        }
    }
    @IBOutlet private weak var validateButton: UIButton! {
        didSet {
            validateButton.makeup(with: .large, color: .white)
            validateButton.titleLabel?.adjustsFontSizeToFitWidth = true
            validateButton.cornerRadiusedWith(backgroundColor: ColorName.greenSpring20.color,
                                              borderColor: ColorName.greenSpring20.color,
                                              radius: Style.mediumCornerRadius)
            validateButton.setTitle(L10n.commonYes, for: .normal)
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

    // MARK: - Private Properties
    private var message: String?
    private var cancelAction: AlertAction?
    private var validateAction: AlertAction?

    // MARK: - Private Enums
    internal enum Constants {
        static let cancelButtonBorderWidth: CGFloat = 2.0
        static let cornerRadius: CGFloat = 18.0
        static let horizontalSpacing: CGFloat = 40.0
        static let verticalSpacing: CGFloat = 16.0
    }

    // MARK: - Setup
    /// Instantiate View controller.
    ///
    /// - Parameters:
    ///     - title: Alert title
    ///     - message: Alert message
    ///     - cancelAction: Cancel action
    ///     - validateAction: Validate action
    public static func instantiate(title: String,
                                   message: String,
                                   cancelAction: AlertAction,
                                   validateAction: AlertAction?) -> AlertViewController {
        let viewController = StoryboardScene.AlertViewController.initialScene.instantiate()
        viewController.title = title
        viewController.message = message
        viewController.cancelAction = cancelAction
        viewController.validateAction = validateAction
        viewController.modalPresentationStyle = .overFullScreen

        return viewController
    }

    // MARK: - Override Funcs
    public override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .clear

        alertTitle.text = title
        alertMessage.text = message

        cancelButton.setTitle(cancelAction?.title ?? L10n.cancel, for: .normal)
        setupButton(cancelButton, with: cancelAction?.style ?? .cancel)

        if let validateTitle = validateAction?.title {
            validateButton.setTitle(validateTitle, for: .normal)
        } else {
            validateButton.isHidden = true
        }

        setupButton(validateButton, with: validateAction?.style ?? .default)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        UIView.animate(withDuration: Style.shortAnimationDuration,
                       delay: Style.shortAnimationDuration,
                       animations: {
                        self.view.backgroundColor = ColorName.white50.color
                       })
    }

    public override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }

    /// Handle orientation.
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        buttonsStackView.axis = UIApplication.isLandscape ? .horizontal : .vertical
        buttonsStackView.spacing = UIApplication.isLandscape ? Constants.horizontalSpacing : Constants.verticalSpacing
    }

    // MARK: - Public Funcs
    /// Dismiss alert.
    ///
    /// - Parameters:
    ///     - animated: animated dismiss
    ///     - completion: completion block
    func dismissAlert(animated: Bool = true, completion: (() -> Void)? = nil) {
        self.view.backgroundColor = .clear
        self.dismiss(animated: animated, completion: completion)
    }
}

// MARK: - Actions
private extension AlertViewController {
    /// Background button touched.
    @IBAction func backgroundButtonTouchedUpInside(_ sender: Any) {
        cancel()
        dismissAlert { [weak self] in
            self?.cancel()
        }
    }

    /// Cancel button touched.
    @IBAction func cancelButtonTouchedUpInside(_ sender: Any) {
        cancelAction?.actionHandler?()
        dismissAlert { [weak self] in
            self?.cancelAction?.actionHandler?()
        }
    }

    /// Confirm button touched.
    @IBAction func confirmButtonTouchedUpInside(_ sender: Any) {
        validateAction?.actionHandler?()
        dismissAlert { [weak self] in
            self?.validateAction?.actionHandler?()
        }
    }
}

// MARK: - Private Funcs
private extension AlertViewController {
    /// Cancel.
    /// Call cancel handler only if it is a cancel action style.
    func cancel() {
        guard cancelAction?.style == .cancel else { return }

        cancelAction?.actionHandler?()
    }

    /// Setup button regarding style.
    ///
    /// - Parameters:
    ///    - button: button to customize
    ///    - style: style to apply
    func setupButton(_ button: UIButton, with style: UIAlertAction.Style?) {
        guard let style = style else { return }

        var color: UIColor = .clear
        var borderWidth: CGFloat = 0.0

        switch style {
        case .destructive:
            color = ColorName.redTorch25.color
        case .cancel:
            color = .clear
            borderWidth = Constants.cancelButtonBorderWidth
        case .default:
            color = ColorName.greenSpring20.color
        @unknown default:
            break
        }

        button.cornerRadiusedWith(backgroundColor: color,
                                  borderColor: ColorName.white.color,
                                  radius: Style.mediumCornerRadius,
                                  borderWidth: borderWidth)
    }
}
