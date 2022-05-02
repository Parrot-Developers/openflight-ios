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

/// View controller that manages gimbal tilt and zoom components.
final class CameraSlidersViewController: UIViewController, DelayedTaskProvider {
    // MARK: - Outlets
    @IBOutlet private weak var tiltButtonContainer: UIView!
    @IBOutlet private weak var tiltButton: TiltButton!
    @IBOutlet private weak var tiltSliderView: TiltSliderView!
    @IBOutlet private weak var tiltSliderContainerView: UIView!
    @IBOutlet private weak var zoomButtonContainer: UIView!
    @IBOutlet private weak var zoomButton: InsetHitAreaButton!
    @IBOutlet private weak var zoomSliderView: ZoomSliderView!
    @IBOutlet private weak var overzoomLabel: UILabel!
    @IBOutlet private weak var joysticksButtonContainer: UIView!
    @IBOutlet private weak var joysticksButton: InsetHitAreaButton!
    @IBOutlet private weak var infoTiltLabel: PaddingLabel!

    @IBOutlet private var overzoomLabelOpenConstraints: [NSLayoutConstraint]!
    @IBOutlet private var overzoomLabelClosedConstraints: [NSLayoutConstraint]!
    @IBOutlet weak var maxTiltSliderLabelUpConstraint: NSLayoutConstraint!
    @IBOutlet weak var maxTiltSliderLabelDownConstraint: NSLayoutConstraint!
    @IBOutlet weak var maxTiltSliderLabel: UILabel!
    @IBOutlet private weak var maxTiltRemoteLabel: UILabel!
    @IBOutlet weak var leadingInfoTiltLabelConstraint: NSLayoutConstraint!

    // MARK: - Internal Properties
    var delayedTaskComponents = DelayedTaskComponents()
    var viewModel: CameraSlidersViewModel!
    var coordinator: CameraSlidersCoordinator!

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Private Enums
    private enum Constants {
        static let zoomDisabledTitleColor = UIColor.black.withAlphaComponent(0.3)
        static let hideInfoLabelTaskKey: String = "hideInfoLabel"
        static let hideTiltMaxLabelTaskKey: String = "hideTiltMaxLabel"
        static let maxReachedNotificationDuration: TimeInterval = 1.0
        static let defaultAnimationDuration: TimeInterval = 0.2
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        zoomSliderView.viewModel = coordinator.zoomSliderViewModel()
        tiltSliderView.viewModel = coordinator.gimbalTiltSliderViewModel()
        setupView()
        setupViewModel()
    }
}

// MARK: - Actions
private extension CameraSlidersViewController {
    /// Called when user taps the zoom button.
    @IBAction func zoomButtonTouchedUpInside(_ sender: Any) {
        viewModel.zoomButtonTapped()
    }

    /// Called when user taps the tilt button.
    @IBAction func tiltButtonTouchedUpInside(_ sender: Any) {
        viewModel.tiltButtonTapped()
        leadingInfoTiltLabelConstraint.isActive = false
    }

    /// Called when user touch jogs button.
    @IBAction func joysticksButtonTouchedUpInside(_ sender: Any) {
        viewModel.joysticksButtonTapped()
    }
}

// MARK: - Private Funcs
private extension CameraSlidersViewController {
    /// Sets up basic UI elements of the view.
    func setupView() {
        self.view.translatesAutoresizingMaskIntoConstraints = false
        // titleButton
        tiltButton.roundCornered()
        // zoomButton
        zoomButton.roundCornered()
        zoomButton.setTitleColor(Constants.zoomDisabledTitleColor, for: .disabled)
        // joysticksButton
        joysticksButton.roundCornered()
        joysticksButton.tintColor = ColorName.defaultTextColor.color
        // overzoomLabel
        overzoomLabel.applyCornerRadius(Style.largeCornerRadius)
        overzoomLabel.text = L10n.zoomMaxReached
        // maxTiltRemoteLabel
        maxTiltRemoteLabel.applyCornerRadius(Style.largeCornerRadius)
        maxTiltRemoteLabel.text = L10n.tiltMaxReached
        maxTiltSliderLabel.applyCornerRadius(Style.largeCornerRadius)
        maxTiltSliderLabel.text = L10n.tiltMaxReached
        // infoTiltLabel
        infoTiltLabel.applyCornerRadius(Style.largeCornerRadius)
        infoTiltLabel.text = ""
        infoTiltLabel.textColor = ColorName.defaultTextColor.color
        infoTiltLabel.backgroundColor = ColorName.white90.color
    }

    /// Sets up view models associated with the view.
    func setupViewModel() {
        listenJoysticksButton()
        listenZoom()
        listenTilt()
    }

    func listenJoysticksButton() {
        viewModel.$showJoysticksButton.sink { [unowned self] in
            joysticksButtonContainer.isHidden = !$0
        }
        .store(in: &cancellables)
        viewModel.$joysticksButtonImage.sink { [unowned self] in
            joysticksButton.setImage($0, for: .normal)
        }
        .store(in: &cancellables)
    }

    func listenZoom() {
        // Button
        viewModel.zoomButtonEnabled
            .sink { [unowned self] in zoomButton.isEnabled = $0 }
            .store(in: &cancellables)
        viewModel.zoomButtonHidden
            .sink { [unowned self] in zoomButtonContainer.isHidden = $0 }
            .store(in: &cancellables)
        viewModel.$zoomButtonTitle
            .sink { [unowned self] in
                zoomButton.setTitle($0, for: .normal)
            }
            .store(in: &cancellables)
        viewModel.$zoomButtonColor
            .sink { [unowned self] in
                zoomButton.setTitleColor($0, for: .normal)
            }
            .store(in: &cancellables)
        // Slider
        viewModel.$showZoomSlider
            .removeDuplicates()
            .sink { [unowned self] in
                if $0 {
                    showZoomSliderView()
                } else {
                    hideZoomSliderView()
                }
            }
            .store(in: &cancellables)
        // Overzooming warning
        viewModel.overzoomingEvent
            .sink { [unowned self] _ in showOverzoomLabel() }
            .store(in: &cancellables)
    }

    func listenTilt() {
        // Button
        viewModel.gimbalTiltButtonEnabled
            .sink { [unowned self] in tiltButton.isEnabled = $0 }
            .store(in: &cancellables)
        // Value
        viewModel.gimbalTiltValue
            .removeDuplicates()
            .dropFirst(1)
            .sink { [unowned self] in
                tiltButton.value = $0
                infoTiltLabel.text = "\(Int($0))°"
                viewModel.showInfoTiltLabel()
            }
            .store(in: &cancellables)
        // Label tilt
        viewModel.$showInfoTiltLabelFlag
            .removeDuplicates()
            .dropFirst(2)
            .sink { [unowned self] in
                if $0 {
                    showInfoTiltLabel()
                } else {
                    hideInfoTiltLabel()
                }
            }
            .store(in: &cancellables)
        viewModel.gimbalTiltButtonHidden
            .sink { [unowned self] in tiltButtonContainer.isHidden = $0 }
            .store(in: &cancellables)
        // Slider
        viewModel.$showGimbalTiltSlider
            .removeDuplicates()
            .sink { [unowned self] in
                if $0 {
                    showTiltSliderView()
                } else {
                    hideTiltSliderView()
                }
            }
            .store(in: &cancellables)
        // Over / under tilt
        viewModel.overtiltEvent
            .sink { [unowned self] _ in
                displayMaxTiltLabel(forOverTilt: true)
            }
            .store(in: &cancellables)
        viewModel.undertiltEvent
            .sink { [unowned self] _ in
                displayMaxTiltLabel(forOverTilt: false)
            }
            .store(in: &cancellables)
    }

    // Show the overzoom label and schedules its hidding
    func showOverzoomLabel() {
        setupDelayedTask(hideOverzoomLabel,
                         delay: Constants.maxReachedNotificationDuration,
                         key: Constants.hideInfoLabelTaskKey)
        overzoomLabel.isHidden = false
    }

    /// Hides the overzoom information label.
    func hideOverzoomLabel() {
        overzoomLabel.isHidden = true
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
        animate(viewToShow: tiltSliderContainerView, viewToHide: zoomButtonContainer)
    }

    /// Hides the tilt slider view.
    func hideTiltSliderView() {
        animate(viewToShow: zoomButtonContainer, viewToHide: tiltSliderContainerView)
        leadingInfoTiltLabelConstraint.isActive = true
    }

    /// Shows the zoom slider view.
    func showZoomSliderView() {
        animate(viewToShow: zoomSliderView,
                viewToHide: tiltButtonContainer,
                constraintsToRemove: overzoomLabelClosedConstraints,
                constraintsToActivate: overzoomLabelOpenConstraints)
    }

    /// Hides the zoom slider view.
    func hideZoomSliderView() {
        animate(viewToShow: tiltButtonContainer,
                viewToHide: zoomSliderView,
                constraintsToRemove: overzoomLabelOpenConstraints,
                constraintsToActivate: overzoomLabelClosedConstraints)
    }

    // MARK: - Max tilt label.
    /// Displays the "Max tilt" label depending on whether the slider is on the screen.
    func displayMaxTiltLabel(forOverTilt value: Bool) {
        if tiltSliderContainerView.isHidden {
            showMaxTiltRemoteLabel()
        } else {
            // Displays the max tilt label of the slider
            showMaxTitlSliderLabel(positionUp: value)
        }
        fadeOutAnimateMaxTitlSliderLabel()
        fadeOutAnimateMaxTiltRemoteLabel()
    }

    // MARK: - Max tilt for slider.

    /// Operates the constraints to display the max tilt label.
    func showMaxTitlSliderLabel(positionUp: Bool) {
        showMaxTiltSliderLabel()
        if positionUp {
            // displays the label in the upward position
            maxTiltSliderLabelUpConstraint.isActive = true
            maxTiltSliderLabelDownConstraint.isActive = false
        } else {
            // displays the label in a downward position
            maxTiltSliderLabelUpConstraint.isActive = false
            maxTiltSliderLabelDownConstraint.isActive = true
        }
    }

    /// Shows the max tilt information label for the slider.
    func showMaxTiltSliderLabel() {
        maxTiltSliderLabel.isHidden = false
    }

    /// hides the max tilt information label for the slider.
    func hideMaxTiltSliderLabel() {
        maxTiltSliderLabel.isHidden = true
    }

    /// Fade in animation to hide the label for the slider.
    func fadeOutAnimateMaxTitlSliderLabel() {
        setupDelayedTask(hideMaxTiltSliderLabel, delay: Constants.maxReachedNotificationDuration)
    }

    // MARK: - Max tilt for remote.

    /// Shows the max tilt information label for the cursor when the remote control is used.
    func showMaxTiltRemoteLabel() {
        maxTiltRemoteLabel.isHidden = false
    }

    /// Hides the max tilt information label for the cursor for the remote control.
    func hideMaxTiltRemoteLabel() {
        maxTiltRemoteLabel.isHidden = true
    }

    /// Fade in animation to hide the label for the remote control.
    func fadeOutAnimateMaxTiltRemoteLabel() {
        setupDelayedTask(hideMaxTiltRemoteLabel,
                         delay: Constants.maxReachedNotificationDuration,
                         key: Constants.hideTiltMaxLabelTaskKey)
    }

    // MARK: - InfoTiltLabel
    func  showInfoTiltLabel() {
        infoTiltLabel.isHidden = false
    }
    func hideInfoTiltLabel() {
        infoTiltLabel.isHidden = true
    }
}
