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

/// View controller that manages gimbal tilt and zoom components.

final class CameraSlidersViewController: UIViewController, DelayedTaskProvider {
    // MARK: - Outlets
    @IBOutlet private weak var tiltButton: TiltButton!
    @IBOutlet private weak var tiltSliderView: TiltSliderView!
    @IBOutlet private weak var tiltSliderContainerView: UIView!
    @IBOutlet private weak var zoomButton: UIButton!
    @IBOutlet private weak var zoomSliderView: ZoomSliderView!
    @IBOutlet private weak var overzoomLabel: UILabel!
    @IBOutlet private weak var maxTiltLabel: UILabel!
    @IBOutlet private weak var joysticksButton: UIButton!
    @IBOutlet private var overzoomLabelOpenConstraints: [NSLayoutConstraint]!
    @IBOutlet private var overzoomLabelClosedConstraints: [NSLayoutConstraint]!
    @IBOutlet private var maxTiltLabelClosedConstraints: [NSLayoutConstraint]!
    @IBOutlet private weak var maxTiltLabelOpenLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var maxTiltLabelOpenPositiveVerticalConstraint: NSLayoutConstraint!
    @IBOutlet private weak var maxTiltLabelOpenNegativeVerticalConstraint: NSLayoutConstraint!

    // MARK: - Internal Properties
    var delayedTaskComponents = DelayedTaskComponents()

    // MARK: - Private Properties
    private var gimbalTiltViewModel: GimbalTiltViewModel!
    private var cameraZoomViewModel: CameraZoomViewModel!
    private let joysticksAvailabilityViewModel = JoysticksAvailabilityViewModel()

    private var currentMaxTiltVerticalConstraint: NSLayoutConstraint {
        switch gimbalTiltViewModel.state.value.current {
        case ...0.0:
            return maxTiltLabelOpenNegativeVerticalConstraint
        default:
            return maxTiltLabelOpenPositiveVerticalConstraint
        }
    }

    // MARK: - Private Enums
    private enum Constants {
        static let zoomDisabledTitleColor = UIColor.white.withAlphaComponent(0.3)
        static let hideSliderTaskKey: String = "hideSlider"
        static let hideInfoLabelTaskKey: String = "hideInfoLabel"
        static let hideTiltMaxLabelTaskKey: String = "hideTiltMaxLabel"
        static let autoHideDelay: TimeInterval = 3.0
        static let maxReachedNotificationDuration: TimeInterval = 1.0
        static let defaultZoomVelocity: Double = 1.0
        static let defaultDezoomVelocity: Double = -1.0
        static let defaultAnimationDuration: TimeInterval = 0.2
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        zoomSliderView.delegate = self
        tiltSliderView.delegate = self
        setupView()
        setupViewModels()
    }
}

// MARK: - Actions
private extension CameraSlidersViewController {
    /// Called when user taps the zoom button.
    @IBAction func zoomButtonTouchedUpInside(_ sender: Any) {
        cameraZoomViewModel?.toggleSliderVisibility()
    }

    /// Called when user taps the tilt button.
    @IBAction func tiltButtonTouchedUpInside(_ sender: Any) {
        gimbalTiltViewModel?.toggleSliderVisibility()
    }

    /// Called when user touch jogs button.
    @IBAction func joysticksButtonTouchedUpInside(_ sender: Any) {
        joysticksAvailabilityViewModel.toggleJogsButtonVisibility()
    }
}

// MARK: - Private Funcs
private extension CameraSlidersViewController {
    /// Sets up basic UI elements of the view.
    func setupView() {
        self.view.translatesAutoresizingMaskIntoConstraints = false
        tiltButton.roundCornered()
        zoomButton.roundCornered()
        joysticksButton.roundCornered()
        zoomButton.setTitleColor(Constants.zoomDisabledTitleColor, for: .disabled)
        overzoomLabel.applyCornerRadius(Style.largeCornerRadius)
        maxTiltLabel.applyCornerRadius(Style.largeCornerRadius)
        overzoomLabel.text = L10n.zoomMaxReached
        maxTiltLabel.text = L10n.tiltMaxReached
    }

    /// Sets up view models associated with the view.
    func setupViewModels() {
        gimbalTiltViewModel = GimbalTiltViewModel(sliderVisibilityDidUpdate: onTiltSliderVisibilityUpdate,
                                                  isOverTiltingDidUpdate: onIsOvertiltingUpdate,
                                                  tiltVisibilityDidUpdate: tiltVisibilityDidUpdate)
        cameraZoomViewModel = CameraZoomViewModel(sliderVisibilityDidUpdate: onZoomSliderVisibilityUpdate,
                                                  isOverzoomingDidUpdate: onIsOverzoomingUpdate,
                                                  zoomVisibilityDidUpdate: zoomVisibilityDidUpdate)

        // Setup callbacks.
        gimbalTiltViewModel.state.valueChanged = { [weak self] state in
            self?.onGimbalTiltUpdate(state)
        }
        cameraZoomViewModel.state.valueChanged = { [weak self] state in
            self?.onCameraZoomUpdate(state)
        }
        joysticksAvailabilityViewModel.state.valueChanged = { [weak self] state in
            self?.onJoysticksUpdate(state)
        }

        // Set inital view model state.
        onGimbalTiltUpdate(gimbalTiltViewModel.state.value)
        onCameraZoomUpdate(cameraZoomViewModel.state.value)
        onJoysticksUpdate(joysticksAvailabilityViewModel.state.value)
    }

    /// Update jogs button view.
    ///
    /// - Parameters:
    ///     - state: joysticks availability state
    func onJoysticksUpdate(_ state: JoysticksAvailabilityState?) {
        joysticksButton.isHidden = state?.allowingJoysticks == false || state?.isBottomBarOpened == true
        if state?.allowingJoysticks == true {
            let image = state?.shouldHideJoysticks == true ? Asset.Joysticks.icJogsShow.image : Asset.Joysticks.icJogsHide.image
            joysticksButton.setImage(image, for: .normal)
        }
    }

    /// Called when camera zoom gets updated.
    func onCameraZoomUpdate(_ state: CameraZoomState) {
        zoomSliderView.zoomState = state
        zoomButton.setTitle(state.formattedTitle, for: .normal)
        zoomButton.setTitleColor(state.color, for: .normal)
        zoomButton.isEnabled = state.isAvailable
    }

    /// Called when zoom slider visibility should be updated.
    func onZoomSliderVisibilityUpdate(_ shouldOpenSlider: Bool) {
        shouldOpenSlider ? showZoomSliderView() : hideZoomSliderView()
    }

    /// Called when zoom visibility should be updated.
    func zoomVisibilityDidUpdate(_ shouldHideZoom: Bool) {
        zoomButton.isHidden = shouldHideZoom
    }

    /// Called when isOverzooming gets updated.
    func onIsOverzoomingUpdate(_ isOverzooming: Bool) {
        if isOverzooming {
            setupDelayedTask(hideOverzoomLabel,
                             delay: Constants.maxReachedNotificationDuration,
                             key: Constants.hideInfoLabelTaskKey)
            overzoomLabel.isHidden = false
        }
    }

    /// Hides the overzoom information label.
    func hideOverzoomLabel() {
        overzoomLabel.isHidden = true
    }

    /// Called when gimbal tilt gets updated.
    func onGimbalTiltUpdate(_ state: GimbalTiltState) {
        tiltSliderView.tiltState = state
        tiltButton.tiltState = state
        tiltButton.isEnabled = state.isAvailable
    }

    /// Called when tilt slider visibility should be updated.
    func onTiltSliderVisibilityUpdate(_ shouldOpenSlider: Bool) {
        shouldOpenSlider ? showTiltSliderView() : hideTiltSliderView()
    }

    /// Called when isOvertilting gets updated.
    func onIsOvertiltingUpdate(_ isOvertilting: Bool) {
        if isOvertilting {
            if gimbalTiltViewModel.state.value.shouldOpenSlider.value {
                maxTiltLabelOpenNegativeVerticalConstraint.isActive = false
                maxTiltLabelOpenPositiveVerticalConstraint.isActive = false
                currentMaxTiltVerticalConstraint.isActive = true
            }
            setupDelayedTask(hideMaxTiltLabel,
                             delay: Constants.maxReachedNotificationDuration,
                             key: Constants.hideTiltMaxLabelTaskKey)
            maxTiltLabel.isHidden = false
        }
    }

    /// Called when tilt visibility should be updated.
    func tiltVisibilityDidUpdate(_ shouldHideTilt: Bool) {
        tiltButton.isHidden = shouldHideTilt
    }

    /// Hides the max tilt information label.
    func hideMaxTiltLabel() {
        maxTiltLabel.isHidden = true
    }

    /// Animates the opening or closing of a slider.
    /// Button controlling the other setting is shown or hidden.
    ///
    /// - Parameters:
    ///    - viewToShow: the view to show
    ///    - viewToHide: the view to hide
    ///    - completion: completion block called after the animation finishes
    func animate(viewToShow: UIView,
                 viewToHide: UIView,
                 constraintsToRemove: [NSLayoutConstraint]? = nil,
                 constraintsToActivate: [NSLayoutConstraint]? = nil,
                 completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: {
            viewToShow.isHidden = false
            viewToHide.alpha = 0
        }, completion: { _ in
            UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: {
                viewToShow.alpha = 1
                viewToHide.isHidden = true
                constraintsToRemove?.forEach({ $0.isActive = false })
                constraintsToActivate?.forEach({ $0.isActive = true })
            }, completion: { _ in
                completion?()
            })
        })
    }

    /// Shows the tilt slider view.
    func showTiltSliderView() {
        animate(viewToShow: tiltSliderContainerView,
                viewToHide: zoomButton,
                constraintsToRemove: maxTiltLabelClosedConstraints,
                constraintsToActivate: [maxTiltLabelOpenLeadingConstraint, currentMaxTiltVerticalConstraint])
        // Slider autohides after a delay.
        setupDelayedTask(gimbalTiltViewModel.closeSlider, delay: Constants.autoHideDelay, key: Constants.hideSliderTaskKey)
    }

    /// Hides the tilt slider view.
    func hideTiltSliderView() {
        animate(viewToShow: zoomButton,
                viewToHide: tiltSliderContainerView,
                constraintsToRemove: [maxTiltLabelOpenLeadingConstraint,
                                      maxTiltLabelOpenPositiveVerticalConstraint,
                                      maxTiltLabelOpenNegativeVerticalConstraint],
                constraintsToActivate: maxTiltLabelClosedConstraints)
        cancelDelayedTask(key: Constants.hideSliderTaskKey)
    }

    /// Shows the zoom slider view.
    func showZoomSliderView() {
        animate(viewToShow: zoomSliderView,
                viewToHide: tiltButton,
                constraintsToRemove: overzoomLabelClosedConstraints,
                constraintsToActivate: overzoomLabelOpenConstraints)
        // Slider autohides after a delay.
        setupDelayedTask(cameraZoomViewModel.closeSlider, delay: Constants.autoHideDelay, key: Constants.hideSliderTaskKey)
    }

    /// Hides the zoom slider view.
    func hideZoomSliderView() {
        animate(viewToShow: tiltButton,
                viewToHide: zoomSliderView,
                constraintsToRemove: overzoomLabelOpenConstraints,
                constraintsToActivate: overzoomLabelClosedConstraints)
        cancelDelayedTask(key: Constants.hideSliderTaskKey)
    }
}

// MARK: - TiltViewDelegate
extension CameraSlidersViewController: TiltSliderViewDelegate {
    func setPitchVelocity(_ velocity: Double) {
        gimbalTiltViewModel?.setPitchVelocity(velocity)
    }

    func resetPitch() {
        gimbalTiltViewModel?.resetPitch()
    }

    func didStartInteracting() {
        cancelDelayedTask(key: Constants.hideSliderTaskKey)
    }

    func didStopInteracting() {
        setupDelayedTask(gimbalTiltViewModel.closeSlider, delay: Constants.autoHideDelay, key: Constants.hideSliderTaskKey)
    }
}

// MARK: - ZoomSliderViewDelegate
extension CameraSlidersViewController: ZoomSliderViewDelegate {
    func startZoom() {
        cameraZoomViewModel?.setZoomVelocity(Constants.defaultZoomVelocity)
        cancelDelayedTask(key: Constants.hideSliderTaskKey)
    }

    func startDezoom() {
        cameraZoomViewModel?.setZoomVelocity(Constants.defaultDezoomVelocity)
        cancelDelayedTask(key: Constants.hideSliderTaskKey)
    }

    func stopZoom() {
        cameraZoomViewModel?.setZoomVelocity(0)
        setupDelayedTask(cameraZoomViewModel.closeSlider, delay: Constants.autoHideDelay, key: Constants.hideSliderTaskKey)
    }

    func resetZoom() {
        cameraZoomViewModel?.resetZoom()
    }
}
