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

    // MARK: - Private Properties
    private var isBlinking: Bool = false
    private var timer: Timer?
    private var countdown: TimeInterval = Constants.animationDuration
    private var isCountdownStarted: Bool {
        return timer != nil
    }

    // MARK: - Private Enums
    private enum Constants {
        static let firstColor: UIColor = UIColor(named: .blueDodger).withAlphaComponent(0.8)
        static let secondColor: UIColor = UIColor(named: .blueDodger).withAlphaComponent(0.2)
        static let alpha20: CGFloat = 0.2
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
        circleProgressView.bgStokeColor = ColorName.white20.color
        circleProgressView.strokeColor = state.subtitleColor ?? .white
    }

    /// Starts button animation.
    ///
    /// - Parameters:
    ///     - state: current alert panel type
    func startAnimation(state: AlertPanelState) {
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
    ///     - delay: delay used for the timer and the progress
    ///     - countdownMessage: func which provides a countdown message for the alert
    func startProgressAnimation(delay: TimeInterval, countdownMessage: ((Int) -> String)?) {
        stopProgress()
        countdown = delay == 0.0 ? Constants.animationDuration : delay
        self.circleProgressView.isHidden = false
        self.circleProgressView.delegate = self
        self.actionLabel.isHidden = false
        self.startCountdown(delay: countdown, countdownMessage: countdownMessage)
        DispatchQueue.main.asyncAfter(deadline: .now() + Style.mediumAnimationDuration) {
            self.circleProgressView.setProgress(1.0,
                                                duration: self.countdown)
        }
    }

    /// Starts countdown.
    ///
    /// - Parameters:
    ///     - delay: delay user for the timer
    ///     - countdownMessage: func which provides a countdown message for the alert
    func startCountdown(delay: TimeInterval, countdownMessage: ((Int) -> String)?) {
        guard !isCountdownStarted else { return }

        timer = Timer.scheduledTimer(withTimeInterval: Style.longAnimationDuration, repeats: true) { [weak self] _ in
            self?.updateTimerLabel(with: countdownMessage)
        }
    }

    /// Stops progress animation.
    func stopProgress() {
        circleProgressView.resetProgress()
        circleProgressView.isHidden = true
        actionLabel.isHidden = true
        countdown = 0.0
    }
}

// MARK: - Private Funcs
private extension HUDAlertPanelActionButton {
    /// Common init.
    func commonInitHUDAlertPanelActionButton() {
        self.loadNibContent()
        circleProgressView.isHidden = true
        actionLabel.makeUp()
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
            actionLabel.text = countdownMessage?(Int(countdown))
        } else {
            timer?.invalidate()
            timer = nil
            countdown = 0.0
        }
    }
}

// MARK: - CircleProgressViewDelegate
extension HUDAlertPanelActionButton: CircleProgressViewDelegate {
    func animationProgressFinished() {
        delegate?.startAction()
    }
}
