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

/// Displays remote shutdown alert on the HUD.
final class RemoteShutdownAlertViewController: UIViewController, DelayedTaskProvider {
    // MARK: - Outlets
    @IBOutlet private weak var panelView: UIView!
    @IBOutlet private weak var alertInfosLabel: UILabel!
    @IBOutlet private weak var bgSlider: UIView!
    @IBOutlet private weak var sliderStepView: UIView!
    @IBOutlet private weak var sliderStepLabel: UILabel!
    @IBOutlet private weak var sliderShutdownImage: UIImageView!
    @IBOutlet private weak var remoteShutdownProcessDoneImage: UIImageView!
    @IBOutlet private weak var sliderStepViewDefaultConstraint: NSLayoutConstraint!

    // MARK: - Internal Properties
    var delayedTaskComponents = DelayedTaskComponents()

    // MARK: - Private Properties
    private var viewModel: RemoteShutdownAlertViewModel?
    private weak var coordinator: Coordinator?
    private var firstTimeButtonPressed: Bool = true
    private var isShutdownProcessDone: Bool = false
    private var isShutdownButtonPressed: Bool {
        return self.viewModel?.state.value.durationBeforeShutDown == 0.0
            && self.firstTimeButtonPressed == false
            && self.viewModel?.state.value.isConnected() == true
    }

    // MARK: - Private Enums
    private enum Constants {
        static var timer: Int = 2
        static var dismissRemoteShutdownAlertTaskKey: String = "DimissRemoteShutdownAlert"
    }

    // MARK: - Setup
    /// Instantiate the alert view controller.
    ///
    /// - Parameters:
    ///     - coordinator: coordinator of the view controller
    /// - Returns: The remote alert shutdown controller.
    static func instantiate(coordinator: Coordinator) -> RemoteShutdownAlertViewController {
        let viewController = StoryboardScene.RemoteShutdownAlertViewController.initialScene.instantiate()
        viewController.coordinator = coordinator

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        initViewModel()

        self.addCloseButton(onTapAction: #selector(closeButtonTouchedUpInside(_:)),
                            targetView: panelView,
                            style: .cross)
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
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

    // Called when user touches the close button.
    @objc func closeButtonTouchedUpInside(_ sender: UIButton) {
        dismissRemoteAlertShutdown()
    }
}

// MARK: - Private Funcs
private extension RemoteShutdownAlertViewController {
    /// Inits panel view.
    func initView() {
        alertInfosLabel.makeUp()
        alertInfosLabel.text = L10n.mpp4AlertShutdown
        sliderStepLabel.text = String(Constants.timer)
        panelView.addBlurEffect()
        bgSlider.roundCorneredWith(backgroundColor: OpenFlight.ColorName.redTorch.color)
        sliderStepView.roundCornered()
    }

    /// Init remote shutdown alert ViewModel.
    func initViewModel() {
        viewModel = RemoteShutdownAlertViewModel(stateDidUpdate: { [weak self] state in
            guard let strongSelf = self else { return }

            // Check if remote is disconnected or if remote shutdown button is unpressed.
            if state.isConnected() == false || strongSelf.isShutdownButtonPressed {
                if strongSelf.isShutdownProcessDone {
                    strongSelf.updateView(shouldHide: true)
                    strongSelf.setupDelayedTask(strongSelf.dismissRemoteAlertShutdown,
                                                delay: Double(Constants.timer),
                                                key: Constants.dismissRemoteShutdownAlertTaskKey)
                } else {
                    strongSelf.sliderStepView.layer.removeAllAnimations()
                    strongSelf.updateView(shouldHide: false)
                    strongSelf.dismissRemoteAlertShutdown()
                }

                return
            }

            // Start animation.
            if state.isConnected() == true && state.durationBeforeShutDown != 0.0 {
                strongSelf.animateSlider(timer: Constants.timer)
                strongSelf.firstTimeButtonPressed = false
            }
        })
    }

    /// Animates remote slider shutdown view.
    ///
    /// - Parameters:
    ///     - timer: Animation duration
    func animateSlider(timer: Int) {
        UIView.animate(withDuration: Style.longAnimationDuration, delay: 0.0, options: .curveLinear) { () in
            self.sliderStepView.center.x += (self.sliderStepView.bounds.width / 2.0)
                + self.sliderStepViewDefaultConstraint.constant
                + (self.bgSlider.bounds.width / 4.0)
        } completion: { _ in
            let newTimerValue = timer - 1

            // Check if animation is ended or not.
            if self.isShutdownButtonPressed {
                self.dismissRemoteAlertShutdown()
                return
            }

            if newTimerValue > 0 {
                self.sliderStepLabel.text = String(newTimerValue)
                self.animateSlider(timer: newTimerValue)
            } else {
                self.isShutdownProcessDone = true
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
        self.sliderStepView.isHidden = shouldHide
        self.sliderShutdownImage.isHidden = shouldHide
        self.bgSlider.isHidden = shouldHide
        self.remoteShutdownProcessDoneImage.isHidden = !shouldHide
        self.sliderStepLabel.text = String(Constants.timer)
    }

    /// Dismiss remote shutdown alert after 2 seconds.
    func dismissRemoteAlertShutdown() {
        self.coordinator?.dismiss()
    }
}
