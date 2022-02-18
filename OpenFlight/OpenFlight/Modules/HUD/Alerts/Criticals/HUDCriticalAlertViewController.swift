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

// MARK: Protocols
/// Handles alert buttons logic.
protocol HUDCriticalAlertDelegate: AnyObject {
    /// Called when user dimisses the alert.
    func dismissAlert()

    /// Called when user taps on the action button.
    ///
    /// - Parameters:
    ///     - alert: current alert type
    func performAlertAction(alert: HUDCriticalAlertType?)
}

/// Displays a critical alert on the HUD.
final class HUDCriticalAlertViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var panelView: UIView!
    @IBOutlet private weak var topView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var topImageView: UIImageView!
    @IBOutlet private weak var mainImageView: UIImageView!
    @IBOutlet private weak var buttonsStackView: UIView!
    @IBOutlet private weak var cancelButton: ActionButton!
    @IBOutlet private weak var actionButton: ActionButton!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var closeButton: UIButton!

    // MARK: - Internal Properties
    weak var delegate: HUDCriticalAlertDelegate?
    var currentAlert: HUDCriticalAlertType?

    // MARK: - Setup
    /// Instantiate the alert view controller.
    ///
    /// - Parameters:
    ///     - alert: alert type to present
    /// - Returns: The critical alert view controller.
    static func instantiate(with alert: HUDCriticalAlertType) -> HUDCriticalAlertViewController {
        let viewController = StoryboardScene.HUDCriticalAlert.initialScene.instantiate()
        viewController.currentAlert = alert

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()

        guard let strongModel = currentAlert else { return }

        setupView(alertModel: strongModel)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        UIView.animate(withDuration: Style.shortAnimationDuration,
                       delay: Style.shortAnimationDuration,
                       animations: {
            self.view.backgroundColor = ColorName.nightRider80.color
        })
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        view.backgroundColor = .clear
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension HUDCriticalAlertViewController {
    func dismissAlert() {
        delegate?.dismissAlert()
    }

    @IBAction func backgroundButtonTouchedUpInside(_ sender: Any) {
        dismissAlert()
    }

    @IBAction func cancelButtonTouchedUpInside(_ sender: Any) {
        dismissAlert()
    }

    @IBAction func actionButtonTouchedUpInside(_ sender: Any) {
        delegate?.performAlertAction(alert: currentAlert)
    }

    /// Called when user touches the close button.
    @IBAction func closeButtonTouchedUpInside(_ sender: Any) {
        dismissAlert()
    }
}

// MARK: - Private Funcs
private extension HUDCriticalAlertViewController {
    /// Inits panel view.
    func initView() {
        panelView.customCornered(corners: [.topLeft, .topRight], radius: Style.largeCornerRadius)
        topView.cornerRadiusedWith(backgroundColor: .white, radius: Style.mediumCornerRadius)
        topView.addShadow(shadowColor: ColorName.whiteAlbescent.color)
        descriptionLabel.font = FontStyle.readingText.font(isRegularSizeClass)
        cancelButton.setup(title: L10n.cancel, style: .default2)
        cancelButton.customCornered(corners: .allCorners, radius: Style.largeCornerRadius)
        actionButton.customCornered(corners: .allCorners, radius: Style.largeCornerRadius)
        actionButton.backgroundColor = ActionButtonStyle.validate.backgroundColor
    }

    /// Updates the view according to model value.
    ///
    /// - Parameters:
    ///     - alertModel: current alert to display
    func setupView(alertModel: HUDCriticalAlertType) {
        titleLabel.text = alertModel.topTitle
        titleLabel.textColor = alertModel.topTitleColor?.color
        topImageView.image = alertModel.topIcon
        topImageView.tintColor = alertModel.topIconTintColor?.color
        topImageView.isHidden = alertModel.topIcon == nil
        topView.backgroundColor = alertModel.topBackgroundColor?.color
        mainImageView.image = alertModel.mainImage
        mainImageView.isHidden = alertModel.mainImage == nil
        descriptionLabel.text = alertModel.mainDescription
        cancelButton.isHidden = alertModel.showCancelButton == false
        if alertModel.addCancelButtonShadow == true { cancelButton.addShadow() }
        actionButton.setTitle(alertModel.actionButtonTitle, for: .normal)
        actionButton.setTitleColor(alertModel.actionButtonTitleColor?.color, for: .normal)
        actionButton.backgroundColor = alertModel.actionButtonBackgroundColor?.color
        if alertModel.addActionButtonShadow == true { actionButton.addShadow() }
    }
}
