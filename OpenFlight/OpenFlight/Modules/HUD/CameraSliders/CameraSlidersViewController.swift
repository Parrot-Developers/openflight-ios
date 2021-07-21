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
import Combine

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
    var viewModel: CameraSlidersViewModel!
    var coordinator: CameraSlidersCoordinator!

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()

    private func currentMaxTiltVerticalConstraint(positive: Bool) -> NSLayoutConstraint {
        positive ? maxTiltLabelOpenPositiveVerticalConstraint : maxTiltLabelOpenNegativeVerticalConstraint
    }

    // MARK: - Private Enums
    private enum Constants {
        static let zoomDisabledTitleColor = UIColor.white.withAlphaComponent(0.3)
        static let hideInfoLabelTaskKey: String = "hideInfoLabel"
        static let hideTiltMaxLabelTaskKey: String = "hideTiltMaxLabel"
        static let maxReachedNotificationDuration: TimeInterval = 1.0
        static let defaultZoomVelocity: Double = 1.0
        static let defaultDezoomVelocity: Double = -1.0
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
    func setupViewModel() {
        listenJoysticksButton()
        listenZoom()
        listenTilt()
    }

    func listenJoysticksButton() {
        viewModel.$showJoysticksButton.sink { [unowned self] in
            joysticksButton.isHidden = !$0
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
            .sink { [unowned self] in zoomButton.isHidden = $0 }
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
        viewModel.gimbalTiltValue
            .sink { [unowned self] in tiltButton.value = $0 }
            .store(in: &cancellables)
        viewModel.gimbalTiltButtonHidden
            .sink { [unowned self] in tiltButton.isHidden = $0 }
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
            .sink { [unowned self] _ in showMaxTiltLabel(positive: true) }
            .store(in: &cancellables)
        viewModel.undertiltEvent
            .sink { [unowned self] _ in showMaxTiltLabel(positive: false) }
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

    /// Show max tilt label
    func showMaxTiltLabel(positive: Bool) {
        if !tiltSliderView.isHidden {
            maxTiltLabelOpenNegativeVerticalConstraint.isActive = false
            maxTiltLabelOpenPositiveVerticalConstraint.isActive = false
            currentMaxTiltVerticalConstraint(positive: positive).isActive = true
        }
        setupDelayedTask(hideMaxTiltLabel,
                         delay: Constants.maxReachedNotificationDuration,
                         key: Constants.hideTiltMaxLabelTaskKey)
        maxTiltLabel.isHidden = false
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
                constraintsToActivate: [maxTiltLabelOpenLeadingConstraint, maxTiltLabelOpenPositiveVerticalConstraint])
    }

    /// Hides the tilt slider view.
    func hideTiltSliderView() {
        animate(viewToShow: zoomButton,
                viewToHide: tiltSliderContainerView,
                constraintsToRemove: [maxTiltLabelOpenLeadingConstraint,
                                      maxTiltLabelOpenPositiveVerticalConstraint,
                                      maxTiltLabelOpenNegativeVerticalConstraint],
                constraintsToActivate: maxTiltLabelClosedConstraints)
    }

    /// Shows the zoom slider view.
    func showZoomSliderView() {
        animate(viewToShow: zoomSliderView,
                viewToHide: tiltButton,
                constraintsToRemove: overzoomLabelClosedConstraints,
                constraintsToActivate: overzoomLabelOpenConstraints)
    }

    /// Hides the zoom slider view.
    func hideZoomSliderView() {
        animate(viewToShow: tiltButton,
                viewToHide: zoomSliderView,
                constraintsToRemove: overzoomLabelOpenConstraints,
                constraintsToActivate: overzoomLabelClosedConstraints)
    }
}
