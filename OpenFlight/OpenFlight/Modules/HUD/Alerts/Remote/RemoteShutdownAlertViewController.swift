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
import Combine

/// Displays remote shutdown alert on the HUD.
final class RemoteShutdownAlertViewController: UIViewController, DelayedTaskProvider {
    // MARK: - Outlets
    @IBOutlet private weak var panelView: UIView!
    @IBOutlet private weak var bgSlider: UIView!
    @IBOutlet private weak var sliderStepView: UIView!
    @IBOutlet private weak var sliderStepLabel: UILabel!
    @IBOutlet private weak var sliderShutdownImage: UIImageView!
    @IBOutlet private weak var remoteShutdownProcessDoneImage: UIImageView!
    @IBOutlet private weak var alertInstructionLabel: UILabel!
    @IBOutlet private weak var sliderStepViewDefaultConstraint: NSLayoutConstraint!

    // MARK: - Internal Properties
    var delayedTaskComponents = DelayedTaskComponents()

    // MARK: - Private Properties
    private let viewModel = RemoteShutdownAlertViewModel()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Private Enums
    private enum Constants {
        static var timer: Int = 3
        static var dismissRemoteShutdownAlertTaskKey: String = "DimissRemoteShutdownAlert"
    }

    // MARK: - Setup
    /// Instantiate the alert view controller.
    ///
    /// - Returns: The remote alert shutdown controller.
    static func instantiate() -> RemoteShutdownAlertViewController {
        let viewController = StoryboardScene.RemoteShutdownAlertViewController.initialScene.instantiate()
        viewController.modalPresentationStyle = .overFullScreen
        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        bindViewModel()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension RemoteShutdownAlertViewController {
    @IBAction func backgroundButtonTouchedUpInside(_ sender: Any) {
        dismissRemoteAlertShutdown()
    }

    @IBAction func closeButtonTouchedUpInside(_ sender: UIButton) {
        dismissRemoteAlertShutdown()
    }
}

// MARK: - Private Funcs
private extension RemoteShutdownAlertViewController {
    /// Inits panel view.
    func initView() {
        alertInstructionLabel.text = L10n.remoteAlertShutdownInstruction
        sliderStepLabel.text = String(Constants.timer)
        panelView.customCornered(corners: [.topLeft, .topRight], radius: Style.largeCornerRadius)
        panelView.layer.masksToBounds = true
        bgSlider.roundCorneredWith(backgroundColor: OpenFlight.ColorName.errorColor.color)
        sliderStepView.roundCornered()
    }

    /// Binds the view model to the views.
    func bindViewModel() {
        viewModel.$connectionState
            .combineLatest(viewModel.$isShutdownProcessDone, viewModel.$durationBeforeShutDown, viewModel.$isShutdownButtonPressed)
            .sink { [unowned self] (connectionState, isShutdownProcessDone, durationBeforeShutdown, isShutdownButtonPressed) in
                if connectionState != .connected || viewModel.isShutdownButtonPressed {
                    if isShutdownProcessDone {
                        updateView(shouldHide: true)
                        setupDelayedTask(dismissRemoteAlertShutdown,
                                         delay: Double(Constants.timer),
                                         key: Constants.dismissRemoteShutdownAlertTaskKey)
                    } else {
                        sliderStepView.layer.removeAllAnimations()
                        updateView(shouldHide: false)
                        dismissRemoteAlertShutdown()
                    }
                    return
                }

                if connectionState == .connected && durationBeforeShutdown != 0.0 {
                    animateSlider(timer: Constants.timer)
                    viewModel.updateFirstTimeButton()
                } else {
                    self.dismissRemoteAlertShutdown()
                    return
                }
            }
            .store(in: &cancellables)
    }

    /// Animates remote slider shutdown view.
    ///
    /// - Parameters:
    ///     - timer: Animation duration
    func animateSlider(timer: Int) {
        // Check if animation is ended or not.
        if viewModel.isShutdownButtonPressed {
            dismissRemoteAlertShutdown()
            return
        }

        UIView.animate(withDuration: Style.longAnimationDuration, delay: 0.0, options: .curveLinear) { () in
            self.sliderStepView.center.x += (self.sliderStepView.bounds.width / 2.0)
                + self.sliderStepViewDefaultConstraint.constant
                + (self.bgSlider.bounds.width / 4.0)
        } completion: { _ in
            let newTimerValue = timer - 1

            if newTimerValue > 0 {
                self.sliderStepLabel.text = String(newTimerValue)
                self.animateSlider(timer: newTimerValue)
            } else {
                self.viewModel.updateShutdownProcess()
                self.updateView(shouldHide: true)
            }
        }
    }

    /// Update remote shutdown alert process  view.
    ///
    /// - Parameters:
    ///     - shouldHide: Determines if we should hide or not shutdown slider view
    func updateView(shouldHide: Bool) {
        self.sliderStepView.center.x = (self.sliderStepView.bounds.width / 2.0)
            + self.sliderStepViewDefaultConstraint.constant
        self.alertInstructionLabel.text  = shouldHide
            ? L10n.remoteAlertShutdownSuccess
            : L10n.remoteAlertShutdownInstruction
        self.sliderStepView.isHidden = shouldHide
        self.sliderShutdownImage.isHidden = shouldHide
        self.bgSlider.isHidden = shouldHide
        self.remoteShutdownProcessDoneImage.isHidden = !shouldHide
        self.sliderStepLabel.text = String(Constants.timer)
    }

    /// Dismiss remote shutdown alert after 2 seconds.
    func dismissRemoteAlertShutdown() {
        dismiss(animated: true)
    }
}
