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

// MARK: - Protocol
/// Action button delegate when an animation is finished.
public protocol HUDAlertPanelActionButtonDelegate: AnyObject {
    /// Starts an action at the end of the animation.
    func startAction()
}

/// Custom action button for HUD's alert panel.
public final class HUDAlertPanelActionButton: HighlightableUIControl, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var alertImageView: UIImageView!
    @IBOutlet private weak var actionLabel: UILabel!
    @IBOutlet private weak var circleProgressView: CircleProgressView!

    // MARK: - Public Properties
    public weak var delegate: HUDAlertPanelActionButtonDelegate?
    public var rthAlertType: RthAlertType?

    // MARK: - Private Properties
    private var isBlinking: Bool = false
    private var timer: Timer?
    private var initialCountdown: TimeInterval? // Used for non-continuous progress animation.
    private var countdown: TimeInterval = Constants.animationDuration
    private var startProgress: Float {
        min(1, Float(countdown) / Float(initialCountdown ?? 1))
    }
    private var isCountdownStarted: Bool {
        initialCountdown != nil
    }

    // MARK: - Private Enums
    private enum Constants {
        static let firstColor: UIColor = UIColor(named: .blueDodger).withAlphaComponent(0.8)
        static let secondColor: UIColor = UIColor(named: .blueDodger).withAlphaComponent(0.2)
        static let animationDuration: TimeInterval = 10.0
    }

    // MARK: - Override Funcs
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInitHUDAlertPanelActionButton()
    }
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInitHUDAlertPanelActionButton()
    }

    // MARK: - Deinit
    deinit {
        stopProgress()
    }
}

// MARK: - Public Funcs
public extension HUDAlertPanelActionButton {
    /// Setups the button view.
    ///
    /// - Parameters:
    ///     - state: current alert panel type
    ///     - showActionLabel: tells if we need to show action label
    ///     - actionLabelText: text of the action label
    func setupView(state: AlertPanelState,
                   showActionLabel: Bool = false,
                   withText actionLabelText: String?) {
        // Stop current animation if one.
        alertImageView.stopAnimating()
        alertImageView.image = state.icon
        actionLabel.isHidden = !showActionLabel
        actionLabel.text = actionLabelText
        circleProgressView.borderWidth = Style.largeBorderWidth
        circleProgressView.bgStokeColor = ColorName.whiteAlbescent.color
        circleProgressView.strokeColor = state.subtitleColor ?? ColorName.defaultTextColor.color
    }

    /// Starts button animation.
    ///
    /// - Parameters:
    ///     - state: current alert panel type
    func startAnimation(state: AlertPanelState) {
        circleProgressView.isHidden = true
        guard let animationImages = state.animationImages else {
            alertImageView.image = state.icon
            return
        }

        startImagesAnimation(images: animationImages)
    }

    /// Stops current button animation.
    ///
    /// - Parameters:
    ///     - state: current alert panel type
    func stopAnimation(state: AlertPanelState) {
        alertImageView.image = state.icon
        isBlinking = false
    }

    /// Starts progress animation.
    ///
    /// - Parameters:
    ///    - initialCountdown: countdown initial value
    ///    - delay: delay used for the timer and the progress
    ///    - countdownMessage: func which provides a countdown message for the alert
    func startProgressAnimation(initialCountdown: TimeInterval?, delay: TimeInterval, countdownMessage: ((Int) -> String)?) {
        initProgressAnimation(initialCountdown: initialCountdown, delay: delay, countdownMessage: countdownMessage)
        startCountdown(delay: delay, countdownMessage: countdownMessage)
    }

    /// Launches automatic countdown animation.
    ///
    /// - Parameters:
    ///    - delay: countdown duration (`Constants.animationDuration` if nil)
    ///    - countdownMessage: countdown message displayed below progressView (inactive for now)
    func launchCountdownAnimation(delay: TimeInterval? = nil, countdownMessage: ((Int) -> String)? = nil) {
        initProgressAnimation(delay: delay ?? Constants.animationDuration, countdownMessage: countdownMessage)

        // Delay countdown as progressView first needs to be rendered at 100 % before being animated.
        DispatchQueue.main.asyncAfter(deadline: .now() + Style.shortAnimationDuration) {
            self.animateProgress(delay: delay ?? Constants.animationDuration, countdownMessage: countdownMessage)
        }
    }

    /// Starts countdown.
    ///
    /// - Parameters:
    ///     - delay: delay user for the timer
    ///     - countdownMessage: func which provides a countdown message for the alert
    func startCountdown(delay: TimeInterval, countdownMessage: ((Int) -> String)?) {
        // Update progress view only if countdown is actually decreasing.
        // (Avoids erratic progress behavior in case of delay re-calculations.)
        guard delay <= countdown else { return }
        countdown = delay
        circleProgressView.setProgress(Float(startProgress))
    }

    /// Stops progress animation.
    func stopProgress() {
        guard isCountdownStarted else { return }

        initialCountdown = nil
        circleProgressView.resetProgress()
        circleProgressView.isHidden = true
        actionLabel.alphaHidden(actionLabel.isHidden)
        countdown = 0.0
    }
}

// MARK: - Private Funcs
private extension HUDAlertPanelActionButton {
    /// Common init.
    func commonInitHUDAlertPanelActionButton() {
        self.loadNibContent()
        circleProgressView.isHidden = true
    }

    /// Starts an animation between several images.
    ///
    /// - Parameters:
    ///     - images: set of images for the animation
    func startImagesAnimation(images: [UIImage]) {
        alertImageView.image = UIImage.animatedImage(with: images,
                                                     duration: Style.longAnimationDuration)
        alertImageView?.startAnimating()
    }

    /// Updates timer label.
    ///
    /// - Parameters:
    ///     - countdownMessage: func which provides a countdown message for the alert
    @objc func updateTimerLabel(with countdownMessage: ((Int) -> String)?) {
        if countdown > 0.0 {
            countdown -= 1.0
        } else {
            timer?.invalidate()
            timer = nil
            countdown = 0.0
        }
        refreshCountdownLabel(with: countdownMessage)
    }

    /// Refreshes countdownLabel content according to countdown value.
    ///
    /// - Parameters:
    ///     - countdownMessage: Func which provides a countdown message for the alert.
    func refreshCountdownLabel(with countdownMessage: ((Int) -> String)?) {
        guard let countdownMessage = countdownMessage else {
            actionLabel.alphaHidden(true)
            return
        }

        actionLabel.text = countdownMessage(Int(countdown))
        actionLabel.alphaHidden(countdown == 0)
        layoutIfNeeded()
    }

    /// Inits countdown animation by setting initial counter value and UI states.
    ///
    /// - Parameters:
    ///    - initialCountdown: countdown initial value
    ///    - delay: delay used for the timer and the progress
    ///    - countdownMessage: func which provides a countdown message for the alert
    func initProgressAnimation(initialCountdown: TimeInterval? = nil, delay: TimeInterval, countdownMessage: ((Int) -> String)?) {
        guard !isCountdownStarted else {
            // Update initial value even if countdown is started in case current update
            // overrides a previously on-going alert.
            updateInitialCountdown(initialCountdown, delay: delay)
            return
        }

        stopProgress()
        circleProgressView.isHidden = false
        circleProgressView.delegate = self

        countdown = delay
        updateInitialCountdown(initialCountdown, delay: delay)

        DispatchQueue.main.async {
            self.refreshCountdownLabel(with: countdownMessage)
            self.circleProgressView.setProgress(self.startProgress)
        }
    }

    /// Updates initial countdown value.
    ///
    /// - Parameters:
    ///    - countdown: countdown initial value (if provided)
    ///    - delay: current countdown value
    func updateInitialCountdown(_ countdown: TimeInterval?, delay: TimeInterval) {
        initialCountdown = countdown ?? delay
    }

    /// Launches actual countdown animation.
    ///
    /// - Parameters:
    ///     - delay: Delay used for the timer and the progress.
    ///     - countdownMessage: Func which provides a countdown message for the alert.
    func animateProgress(delay: TimeInterval, countdownMessage: ((Int) -> String)?) {
        startCountdown(delay: countdown, countdownMessage: countdownMessage)
        actionLabel.alphaHidden(false)
        circleProgressView.setProgress(0, duration: countdown)
    }
}

// MARK: - CircleProgressViewDelegate
extension HUDAlertPanelActionButton: CircleProgressViewDelegate {
    func animationProgressFinished() {
        delegate?.startAction()
    }
}
