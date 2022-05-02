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

import Foundation
import UIKit
import SwiftyUserDefaults
import Combine

/// Class that manages ths split screen between streaming and secondary HUD view.

public class SplitControls: NSObject, DelayedTaskProvider {

    // MARK: - Outlets
    @IBOutlet private weak var view: UIView!
    @IBOutlet private weak var streamContainerView: UIView!
    @IBOutlet private weak var aeLockContainerView: UIView!
    @IBOutlet private weak var secondaryContainerView: UIView!
    @IBOutlet private weak var splitView: HUDSplitView!
    @IBOutlet private weak var splitTouchView: UIView!
    @IBOutlet private weak var cameraSlidersHUD: UIView!
    @IBOutlet private weak var bottomBarContainerHUD: UIView!
    @IBOutlet private weak var centerMapButton: InsetHitAreaButton! {
        didSet {
            centerMapButton.setImage(Asset.Map.centerOnUser.image, for: .normal)
        }
    }
    @IBOutlet private weak var splitViewConstraint: NSLayoutConstraint!
    @IBOutlet private weak var splitViewIpadConstraint: NSLayoutConstraint!

    @IBOutlet private var streamTrailingToSplitViewConstraint: NSLayoutConstraint!
    @IBOutlet private var streamBottomToSplitViewIpadConstraint: NSLayoutConstraint!

    @IBOutlet private var secondaryViewLeadingToSplitViewConstraint: NSLayoutConstraint!
    @IBOutlet private var secondaryViewTopToSplitViewIpadConstraint: NSLayoutConstraint!
    @IBOutlet private var secondaryViewTrailingConstraints: [NSLayoutConstraint]!

    // Constraints shouldn't be deactivated in storyboard due to iOS13 issue with return from background.
    @IBOutlet private var streamTrailingToSuperviewConstraint: NSLayoutConstraint! {
        didSet {
            streamTrailingToSuperviewConstraint.isActive = false
        }
    }
    @IBOutlet private var streamBottomToSuperviewIpadConstraint: NSLayoutConstraint! {
        didSet {
            streamBottomToSuperviewIpadConstraint.isActive = false
        }
    }

    @IBOutlet private var secondaryViewLeadingToSuperviewConstraint: NSLayoutConstraint! {
        didSet {
            secondaryViewLeadingToSuperviewConstraint.isActive = false
        }
    }
    @IBOutlet private var secondaryViewTopToSuperviewIpadConstraint: NSLayoutConstraint! {
        didSet {
            secondaryViewTopToSuperviewIpadConstraint.isActive = false
        }
    }

    @IBOutlet private weak var streamButton: UIButton!
    @IBOutlet private weak var secondaryViewButton: UIButton!

    @IBOutlet private var streamFullscreenConstraints: [NSLayoutConstraint]!
    @IBOutlet private var streamFullScreenIpadConstraints: [NSLayoutConstraint]!

    @IBOutlet private var streamMiniatureConstraints: [NSLayoutConstraint]!

    @IBOutlet private var secondaryViewFullscreenConstraints: [NSLayoutConstraint]!
    @IBOutlet private var secondaryViewFullscreenIpadConstraints: [NSLayoutConstraint]!

    @IBOutlet private var secondaryViewMiniatureConstraints: [NSLayoutConstraint]!
    @IBOutlet private var secondaryViewMiniatureIpadConstraints: [NSLayoutConstraint]!

    @IBOutlet private var secondaryViewMiniatureCenterConstraints: [NSLayoutConstraint]!

    @IBOutlet private var secondaryViewHeightRatioConstraints: [NSLayoutConstraint]!

    // MARK: - Private Enums

    private enum Constants {
        static let minimumStreamViewHeight: CGFloat = UIScreen.main.bounds.height * 0.21
        static let minimumStreamViewWidth: CGFloat = 200
        // Secondary view has a minimum width of 15% of the screen, unless it is smaller than 140 points.
        static let minimumSecondaryViewWidth: CGFloat = max(UIScreen.main.bounds.width * 0.15, 140)
        static let minimumSecondaryViewHeight: CGFloat = max(UIScreen.main.bounds.height * 0.25, 140)
        static let defaultAnimationDuration: TimeInterval = 0.35
        static let defaultStreamRatio: CGFloat = 4/3
        static let secondaryMiniatureHeightRatio: CGFloat = 0.3
        static let secondaryMiniatureCenterHeightRatio: CGFloat = 0.2
    }

    // MARK: - Internal Properties

    weak var cameraStreamingViewController: HUDCameraStreamingViewController?
    var mapViewController: MapViewController?
    weak var mapOr3DParent: UIViewController?
    var delayedTaskComponents = DelayedTaskComponents()
    weak var delegate: SplitControlsDelegate?

    // MARK: - Private Properties

    private var splitViewConstraintsGetter: NSLayoutConstraint {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return splitViewIpadConstraint

        default:
            return splitViewConstraint
        }
    }

    private var streamToSplitViewConstraint: NSLayoutConstraint {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return streamBottomToSplitViewIpadConstraint

        default:
            return streamTrailingToSplitViewConstraint
        }
    }

    private var secondaryViewToSplitViewConstraint: NSLayoutConstraint {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return secondaryViewTopToSplitViewIpadConstraint

        default:
            return secondaryViewLeadingToSplitViewConstraint
        }
    }

    private var streamToSuperviewConstraint: NSLayoutConstraint {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return streamBottomToSuperviewIpadConstraint
        default:
            return streamTrailingToSuperviewConstraint
        }
    }

    private var secondaryViewToSuperviewConstraint: NSLayoutConstraint {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return secondaryViewTopToSuperviewIpadConstraint
        default:
            return secondaryViewLeadingToSuperviewConstraint
        }
    }

    private var streamFullscreenConstraintsGetter: [NSLayoutConstraint] {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return streamFullScreenIpadConstraints
        default:
            return streamFullscreenConstraints
        }
    }

    private var secondaryViewFullscreenConstraintsGetter: [NSLayoutConstraint] {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return secondaryViewFullscreenIpadConstraints
        default:
            return secondaryViewFullscreenConstraints
        }
    }

    private var secondaryViewMiniatureConstraintsGetter: [NSLayoutConstraint] {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return secondaryViewMiniatureIpadConstraints
        default:
            return secondaryViewMiniatureConstraints
        }
    }

    private var longPressGestureRecognizer: UILongPressGestureRecognizer!
    private var cancellables = Set<AnyCancellable>()
    private let viewModel = SplitControlsViewModel()
    public var forceStream: Bool = false

    /// Whether to disabled user interaction for the map
    private var mapDisabledUserInteractionSubject = CurrentValueSubject<Bool, Never>(false)
    /// Publisher to know if user interaction for the map is disabled.
    public var mapDisabledUserInteractionPublisher: AnyPublisher<Bool, Never> { mapDisabledUserInteractionSubject.eraseToAnyPublisher() }

    private unowned var currentMissionManager: CurrentMissionManager!
    private var preferredSplitPosition: CGFloat?
    private var defaultSplitPosition: CGFloat {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            let preferredHeight = view.bounds.width * Constants.defaultStreamRatio + splitView.bounds.height / 2

            // Avoid crash when the app is laucnhed for the first time
            if Constants.minimumStreamViewHeight >= view.bounds.height {
                return (Constants.minimumStreamViewHeight...view.bounds.width).clamp(preferredHeight)
            } else {
                let height = view.bounds.height
                if height - Constants.minimumSecondaryViewHeight >= Constants.minimumStreamViewHeight {
                    return (Constants.minimumStreamViewHeight...view.bounds.height - Constants.minimumSecondaryViewHeight)
                        .clamp(preferredHeight)
                } else {
                    return (view.bounds.height - Constants.minimumSecondaryViewHeight...Constants.minimumStreamViewHeight)
                        .clamp(preferredHeight)
                }
            }

        default:
            let preferredWidth = view.bounds.height * Constants.defaultStreamRatio + splitView.bounds.width / 2
            return (Constants.minimumStreamViewWidth...view.bounds.width - Constants.minimumSecondaryViewWidth)
                .clamp(preferredWidth)
        }
    }
    private var secondaryViewCornerRadius: CGFloat {
        let state = viewModel
        let ratio = state.isJoysticksVisible && state.mode == .stream ? Constants.secondaryMiniatureCenterHeightRatio : Constants.secondaryMiniatureHeightRatio
        return view.bounds.height * ratio / 2.0
    }
    private var occupancyViewController: OccupancyViewController?
    private var streamViewController: HUDCameraStreamingViewController?
    private var isMapRequired: Bool { currentMissionManager.mode.isMapRequired }

    // MARK: - Internal Funcs

    /// Sets up gesture recognizers.
    /// Should be called inside viewDidLoad.
    func start(currentMissionManager: CurrentMissionManager) {
        self.currentMissionManager = currentMissionManager
        setLongPressGesture()
        viewModel.shouldHideSecondary
            .sink { [weak self] shouldHideSecondary in
                guard let self = self else { return }
                UIView.animate(withDuration: Constants.defaultAnimationDuration) {
                    self.secondaryContainerView.alphaHidden(shouldHideSecondary)
                }
            }
            .store(in: &cancellables)
        viewModel.bottomBarModePublisher
            .combineLatest(viewModel.isJoysticksVisiblePublisher, viewModel.modePublisher)
            .sink { [weak self] _ in
                self?.updateJogs()
            }
            .store(in: &cancellables)
        currentMissionManager.modePublisher.sink { [weak self] in
            guard let self = self else { return }
            self.updateSplitModeLayout($0.preferredSplitMode)
            self.updateStreamState(enabled: !$0.isRightPanelRequired)
        }
        .store(in: &cancellables)
    }

    /// Updates the constraints when returning from background
    @objc func updateConstraintForForeground() {
        guard let currentMode = viewModel.mode else {
            return
        }
        streamTrailingToSuperviewConstraint.isActive = false
        if currentMode == .secondary {
            secondaryViewToSplitViewConstraint.isActive = false
            secondaryViewToSuperviewConstraint.isActive = true
        } else {
            secondaryViewToSplitViewConstraint.isActive = true
            secondaryViewToSuperviewConstraint.isActive = false
        }
        viewModel.setMode(currentMissionManager.mode.preferredSplitMode)
        updateSplitModeLayout(currentMode, animated: false)
        centerMapButton.applyHUDRoundButtonStyle()
    }

    /// Sets up initial split screen position.
    /// Should be called inside viewDidAppear in
    /// order to have the correct view frame.
    func setupSplitIfNeeded() {
        guard preferredSplitPosition == nil, !viewModel.isJoysticksVisible else { return }
        setupSplitedScreen(atValue: defaultSplitPosition)
    }

    /// Updates split mode layout according current and new modes.
    func updateSplitModeLayout(_ mode: SplitScreenMode, animated: Bool = true) {
        if mode != viewModel.mode {
            hideBottomBar(hide: false)
            hideCameraSliders(hide: false)
        }
        switch (viewModel.mode, mode) {
        case (.stream, .secondary):
            switchFromStreamingToSecondaryFullScreen(animated: animated)
        case (.stream, .splited):
            switchToSplitScreenFromSecondaryTap(animated: animated)
        case (.splited, .stream):
            if animated {
                setupStreamingFullscreen()
            } else {
                setupStreamingFullscreenWithoutAnimation()
            }
        case (.splited, .secondary):
            if animated {
                setupSecondaryViewFullscreen()
            } else {
                setupSecondaryViewFullscreenNoAnimation()
            }
        case (.secondary, .splited):
            applySecondaryViewTrailingConstraint(value: 0, isActive: true)
            switchToSplitScreenFromStreamTap(animated: animated)
        case (.secondary, .stream):
            applySecondaryViewTrailingConstraint(value: 0, isActive: true)
            switchFromSecondaryToStreamingFullScreen(animated: animated)
        case (nil, .splited):
            switchToSplitScreenFromSecondaryTap()
        default:
            view.setNeedsLayout()
        }
        displayMapOr3DasChild()
    }

    /// Apply value for trailing constraint of secondary view
    ///
    /// - Parameters:
    ///    - value: the new value of the constraint
    ///    - isActive: Whether the constraint is active or not
    private func applySecondaryViewTrailingConstraint(value: CGFloat, isActive: Bool) {
        for constraint in secondaryViewTrailingConstraints {
            constraint.constant = value
            constraint.isActive = isActive
        }
    }

    /// Starts or stops stream (⚠️ only works after viewDidAppear).
    ///
    /// - Parameters:
    ///    - enabled: whether stream should be started or stopped
    func updateStreamState(enabled: Bool) {
        enabled ? cameraStreamingViewController?.restartStream() : cameraStreamingViewController?.stopStream()
        streamContainerView.isHidden = !enabled
        streamButton.isHidden = !enabled
    }

    /// Update centerMapButton status.
    ///
    /// - Parameters:
    ///    - image: image
    open func updateCenterMapButtonStatus(image: UIImage? = nil) {
        switch SecondaryScreenType.current {
        case .threeDimensions where isMapRequired, .map:
            if forceStream {
                centerMapButton.isHidden = true
            } else {
                centerMapButton.isHidden = false
                if image != nil {
                    centerMapButton.setImage(image, for: .normal)
                }
            }
        case .threeDimensions:
            centerMapButton.isHidden = true
        }
    }
}

// MARK: - Actions

private extension SplitControls {
    @IBAction func streamButtonTouchedUpInside(_ sender: UIButton) {
        switchToSplitScreenFromStreamTap()
    }

    @IBAction func secondaryViewButtonTouchedUpInside(_ sender: UIButton) {
        switchToSplitScreenFromSecondaryTap()
    }

    @IBAction func centerMapButtonTouchedUpInside(_ sender: UIButton) {
        mapViewController?.disableAutoCenter(false)
    }
}

// MARK: - Gesture Recognizers

private extension SplitControls {
    /// Sets up gesture for long press.
    func setLongPressGesture() {
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(onLongPress))
        longPressGestureRecognizer.minimumPressDuration = 0
        splitTouchView.addGestureRecognizer(longPressGestureRecognizer)
    }

    /// Called when a long press on split touch view occurs.
    @objc func onLongPress(sender: UILongPressGestureRecognizer) {
        guard viewModel.mode == .splited else { return }

        let point = sender.location(in: view)
        switch sender.state {
        case .ended:
            // Update user's preferred split position when touch ends.
            preferredSplitPosition = splitViewConstraintsGetter.constant
            fallthrough
        case .cancelled, .failed:
            cancelDelayedTask()
            splitView.stopAnimation()
            return

        default:
            break
        }

        handleLongPress(at: point)
    }
}

// MARK: - Private Funcs

private extension SplitControls {

    /// Handles long press action. When user moves around, both views
    /// are resized accordingly. If user moves past a specific threshold,
    /// view automatically switches to fullscreen.
    ///
    /// - Parameters:
    ///    - point: point where the event occurs (in main view frame)
    func handleLongPress(at point: CGPoint) {
        let bounds = view.bounds
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            switch point.y {
            case Constants.minimumStreamViewHeight...bounds.height - Constants.minimumSecondaryViewHeight:
                setupSplitedScreen(atValue: point.y)

            default:
                break
            }

        default:
            switch point.x {
            case Constants.minimumStreamViewWidth...bounds.width - Constants.minimumSecondaryViewWidth:
                setupSplitedScreen(atValue: point.x)

            default:
                break
            }
        }

    }

    /// Updates UI from stream fullscreen to splited mode, and animates changes.
    ///
    /// - Parameter animated: If the UI changes should be animated or not
    func switchToSplitScreenFromSecondaryTap(animated: Bool = true) {
        viewModel.setMode(.splited)
        secondaryViewButton.isUserInteractionEnabled = false
        mapDisabledUserInteractionSubject.value = false
        displayMapOr3DasChild()

        if animated {
            UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: { [weak self] in
                guard let self = self else { return }
                // Moves secondary view from miniature position to splited position.
                self.secondaryViewMiniatureConstraintsGetter.forEach { $0.isActive = false }
                self.secondaryViewFullscreenConstraintsGetter.forEach { $0.isActive = true }
                self.secondaryViewToSplitViewConstraint.isActive = true
                self.view.layoutIfNeeded()
            }, completion: { [weak self] _ in
                UIView.animate(withDuration: Constants.defaultAnimationDuration) { [weak self] in
                    guard let self = self else { return }
                    // Moves stream from fullscreen position to splited position
                    // and updates preferred position.
                    self.streamToSuperviewConstraint.isActive = false
                    self.streamToSplitViewConstraint.isActive = true
                    self.view.layoutIfNeeded()
                }
            })
        } else {
            secondaryViewMiniatureConstraintsGetter.forEach { $0.isActive = false }
            secondaryViewFullscreenConstraintsGetter.forEach { $0.isActive = true }
            secondaryViewToSplitViewConstraint.isActive = true
            streamToSuperviewConstraint.isActive = false
            streamToSplitViewConstraint.isActive = true
            view.setNeedsLayout()
        }
    }

    /// Updates UI from secondary view fullscreen to splited mode, and animates changes.
    ///
    /// - Parameter animated: If the UI changes should be animated or not
    func switchToSplitScreenFromStreamTap(animated: Bool = true) {
        viewModel.setMode(.splited)
        view.insertSubview(aeLockContainerView, aboveSubview: streamContainerView)
        view.insertSubview(streamContainerView, aboveSubview: secondaryContainerView)
        cameraStreamingViewController?.removeBorder()
        streamButton.isUserInteractionEnabled = false
        mapDisabledUserInteractionSubject.value = false
        if animated {
            UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: { [weak self] in
                // Moves stream from miniature to splited position.
                guard let self = self else { return }
                self.streamMiniatureConstraints.forEach { $0.isActive = false }
                self.streamFullscreenConstraintsGetter.forEach { $0.isActive = true }
                self.streamToSplitViewConstraint.isActive = true
                self.view.layoutIfNeeded()
            }, completion: { [weak self] _ in
                UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: { [weak self] in
                    guard let self = self else { return }
                    // Moves secondary view to its position for splited
                    // mode and updates preferred position.
                    self.secondaryViewToSuperviewConstraint.isActive = false
                    self.secondaryViewToSplitViewConstraint.isActive = true
                    self.view.layoutIfNeeded()
                }, completion: { [weak self] _ in
                    self?.cameraStreamingViewController?.mode = .fullscreen
                })
            })
        } else {
            streamMiniatureConstraints.forEach { $0.isActive = false }
            streamFullscreenConstraintsGetter.forEach { $0.isActive = true }
            streamToSplitViewConstraint.isActive = true
            secondaryViewToSuperviewConstraint.isActive = false
            secondaryViewToSplitViewConstraint.isActive = true
            view.setNeedsLayout()
            cameraStreamingViewController?.mode = .fullscreen
        }
    }

    /// Moves currently splited mode to another location.
    ///
    /// - Parameters:
    ///    - value: the split view position to move at (function has no effect if `nil`)
    ///    - animated: whether split view change sholuld be animated
    func setupSplitedScreen(atValue value: CGFloat?, animated: Bool = false) {
        guard let value = value, viewModel.mode == .splited else { return }

        if animated {
            UIView.animate(withDuration: Style.shortAnimationDuration) { [weak self] in
                guard let self = self else { return }
                self.splitViewConstraintsGetter.constant = value
                self.view.layoutIfNeeded()
            }
        } else {
            splitViewConstraintsGetter.constant = value
        }
        streamSizeDidChange()
    }

    /// Updates UI for secondary view fullscreen mode.
    func setupSecondaryViewFullscreen() {
        splitView.stopAnimation()
        viewModel.setMode(.secondary)
        view.insertSubview(streamContainerView, aboveSubview: secondaryContainerView)
        streamButton.isUserInteractionEnabled = true
        mapDisabledUserInteractionSubject.value = false
        cameraStreamingViewController?.mode = .preview

        UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: { [weak self] in
            // Moves secondary view from splited position to fullscreen position.
            guard let self = self else { return }
            self.secondaryViewToSplitViewConstraint.isActive = false
            self.secondaryViewToSuperviewConstraint.isActive = true
            self.view.layoutIfNeeded()
        }, completion: { _ in
            UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: { [weak self] in
                guard let self = self else { return }
                // Moves stream from splited position to miniature position.
                self.streamToSplitViewConstraint.isActive = false
                self.streamFullscreenConstraintsGetter.forEach { $0.isActive = false }
                self.streamMiniatureConstraints.forEach { $0.isActive = true }
                self.view.layoutIfNeeded()
            }, completion: { [weak self] _ in
                self?.cameraStreamingViewController?.addBorder()
            })
        })
    }

    /// Updates UI for secondary view fullscreen mode without animation.
    func setupSecondaryViewFullscreenNoAnimation() {
        splitView.stopAnimation()
        viewModel.setMode(.secondary)
        view.insertSubview(streamContainerView, aboveSubview: secondaryContainerView)
        streamButton.isUserInteractionEnabled = true
        mapDisabledUserInteractionSubject.value = false
        cameraStreamingViewController?.mode = .preview

        secondaryViewToSplitViewConstraint.isActive = false
        secondaryViewToSuperviewConstraint.isActive = true
        streamToSplitViewConstraint.isActive = false
        streamFullscreenConstraintsGetter.forEach { $0.isActive = false }
        streamMiniatureConstraints.forEach { $0.isActive = true }
        view.setNeedsLayout()
        cameraStreamingViewController?.addBorder()
    }

    /// Updates UI for stream fullscreen mode.
    func setupStreamingFullscreen() {
        splitView.stopAnimation()
        viewModel.setMode(.stream)
        view.insertSubview(aeLockContainerView, aboveSubview: streamContainerView)
        view.insertSubview(secondaryContainerView, aboveSubview: streamContainerView)
        mapDisabledUserInteractionSubject.value = true
        secondaryViewButton.isUserInteractionEnabled = true
        displayMapOr3DasChild()

        UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: { [weak self] in
            guard let self = self else { return }
            // Moves stream from splited postion to fullscreen position.
            self.streamToSplitViewConstraint.isActive = false
            self.streamToSuperviewConstraint.isActive = true
            self.view.layoutIfNeeded()
        }, completion: { [weak self] _ in
            UIView.animate(withDuration: Constants.defaultAnimationDuration) { [weak self] in
                guard let self = self else { return }
                // Moves secondary view from splited position to miniature position.
                self.secondaryViewToSplitViewConstraint.isActive = false
                self.secondaryViewFullscreenConstraintsGetter.forEach { $0.isActive = false }
                self.secondaryViewMiniatureConstraintsGetter.forEach { $0.isActive = true }
                self.view.layoutIfNeeded()
            }
        })
    }

    /// Updated UI for stream fullscreen mode without animation.
    func setupStreamingFullscreenWithoutAnimation() {
        splitView.stopAnimation()
        viewModel.setMode(.stream)
        view.insertSubview(aeLockContainerView, aboveSubview: streamContainerView)
        view.insertSubview(secondaryContainerView, aboveSubview: streamContainerView)
        mapDisabledUserInteractionSubject.value = true
        secondaryViewButton.isUserInteractionEnabled = true
        displayMapOr3DasChild()

        streamToSplitViewConstraint.isActive = false
        streamToSuperviewConstraint.isActive = true
        secondaryViewToSplitViewConstraint.isActive = false
        secondaryViewFullscreenConstraintsGetter.forEach { $0.isActive = false }
        secondaryViewMiniatureConstraintsGetter.forEach { $0.isActive = true }
        view.setNeedsLayout()
    }

    /// Updates UI from secondary to stream fullscreen mode.
    ///
    /// - Parameter animated: If the UI changes should be animated or not
    func switchFromSecondaryToStreamingFullScreen(animated: Bool = true) {
        viewModel.setMode(.stream)
        cameraStreamingViewController?.removeBorder()
        streamButton.isUserInteractionEnabled = false
        mapDisabledUserInteractionSubject.value = true

        if animated {
            UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: { [weak self] in
                guard let self = self else { return }
                // Moves stream from miniature to full screen position.
                self.streamMiniatureConstraints.forEach { $0.isActive = false }
                self.streamFullscreenConstraintsGetter.forEach { $0.isActive = true }
                self.streamToSuperviewConstraint.isActive = true
                self.view.layoutIfNeeded()
            }, completion: { [weak self] _ in
                UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: { [weak self] in
                    guard let self = self else { return }
                    // Moves secondary view from full screen to miniature position.
                    self.secondaryViewToSuperviewConstraint.isActive = false
                    self.secondaryViewToSplitViewConstraint.isActive = false
                    self.secondaryViewFullscreenConstraintsGetter.forEach { $0.isActive = false }
                    self.secondaryViewMiniatureConstraintsGetter.forEach { $0.isActive = true }
                    self.view.layoutIfNeeded()
                }, completion: { [weak self] _ in
                    guard let self = self else { return }
                    self.view.insertSubview(self.aeLockContainerView, aboveSubview: self.streamContainerView)
                    self.view.insertSubview(self.secondaryContainerView, aboveSubview: self.streamContainerView)
                    self.secondaryViewButton.isUserInteractionEnabled = true
                    self.cameraStreamingViewController?.mode = .fullscreen
                })
            })
        } else {
            streamMiniatureConstraints.forEach { $0.isActive = false }
            streamFullscreenConstraintsGetter.forEach { $0.isActive = true }
            streamToSuperviewConstraint.isActive = true
            secondaryViewToSuperviewConstraint.isActive = false
            secondaryViewToSplitViewConstraint.isActive = false
            secondaryViewFullscreenConstraintsGetter.forEach { $0.isActive = false }
            secondaryViewMiniatureConstraintsGetter.forEach { $0.isActive = true }
            view.setNeedsLayout()
            view.insertSubview(aeLockContainerView, aboveSubview: streamContainerView)
            view.insertSubview(secondaryContainerView, aboveSubview: streamContainerView)
            secondaryViewButton.isUserInteractionEnabled = true
            cameraStreamingViewController?.mode = .fullscreen
        }
    }

    /// Updates UI from stream to secondary fullscreen mode.
    ///
    /// - Parameter animated: If the UI changes should be animated or not
    func switchFromStreamingToSecondaryFullScreen(animated: Bool = true) {
        viewModel.setMode(.secondary)
        secondaryViewButton.isUserInteractionEnabled = false
        mapDisabledUserInteractionSubject.value = false
        cameraStreamingViewController?.mode = .preview

        if animated {
            UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: { [weak self] in
                guard let self = self else { return }
                // Moves secondary view from miniature position to full screen position.
                self.secondaryViewMiniatureConstraintsGetter.forEach { $0.isActive = false }
                self.secondaryViewFullscreenConstraintsGetter.forEach { $0.isActive = true }
                self.secondaryViewToSplitViewConstraint.isActive = false
                self.secondaryViewToSuperviewConstraint.isActive = true
                self.view.layoutIfNeeded()
            }, completion: { [weak self] _ in
                UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: { [weak self] in
                    guard let self = self else { return }
                    // Moves stream from fullscreen position to miniature position
                    // and updates preferred position.
                    self.streamToSuperviewConstraint.isActive = false
                    self.streamFullscreenConstraintsGetter.forEach { $0.isActive = false }
                    self.streamMiniatureConstraints.forEach { $0.isActive = true }
                    self.view.layoutIfNeeded()
                }, completion: { [weak self] _ in
                    guard let self = self else { return }
                    self.cameraStreamingViewController?.addBorder()
                    self.streamButton.isUserInteractionEnabled = true
                    self.view.insertSubview(self.streamContainerView, aboveSubview: self.secondaryContainerView)
                })
            })
        } else {
            secondaryViewMiniatureConstraintsGetter.forEach { $0.isActive = false }
            secondaryViewFullscreenConstraintsGetter.forEach { $0.isActive = true }
            secondaryViewToSplitViewConstraint.isActive = false
            secondaryViewToSuperviewConstraint.isActive = true
            streamToSuperviewConstraint.isActive = false
            streamFullscreenConstraintsGetter.forEach { $0.isActive = false }
            streamMiniatureConstraints.forEach { $0.isActive = true }
            cameraStreamingViewController?.addBorder()
            view.setNeedsLayout()
            streamButton.isUserInteractionEnabled = true
            view.insertSubview(streamContainerView, aboveSubview: secondaryContainerView)
        }
    }

    /// Notifies delegate when stream size did change.
    ///
    /// - Parameters:
    ///     - afterDelay: Notification is triggered after delay
    func streamSizeDidChange(afterDelay: TimeInterval = Style.shortAnimationDuration) {
        // Inform about an update in stream view size.
        DispatchQueue.main.asyncAfter(deadline: .now() + afterDelay) { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.delegate?.streamSizeDidChange(width: weakSelf.streamContainerView.frame.width)
        }
    }

    /// Update split regarding jogs state.
    ///
    /// - Parameters:
    ///     - state: current split controls state
    func updateJogs() {
        splitTouchView.isUserInteractionEnabled = !viewModel.isJoysticksVisible && !currentMissionManager.mode.isRightPanelRequired
        updateMapMiniaturePosition()

        // Setup a splited value when joysticks are visible and if the mode is not full stream.
        if viewModel.mode == .stream {
            // Update radius of the minimap if mode is stream
            secondaryContainerView.applyCornerRadius(secondaryViewCornerRadius)
        } else if viewModel.mode == .splited {
            switch UIDevice.current.userInterfaceIdiom {
            case .pad:
                let value = viewModel.isJoysticksVisible
                ? UIScreen.main.bounds.height - Constants.minimumSecondaryViewHeight
                : preferredSplitPosition
                setupSplitedScreen(atValue: value)
            default:
                let value = viewModel.isJoysticksVisible
                ? UIScreen.main.bounds.width - Constants.minimumSecondaryViewWidth
                : preferredSplitPosition
                setupSplitedScreen(atValue: value)
            }
        }
    }

    /// Update secondary miniature position according to mode and joysticks state.
    ///
    /// - Parameters:
    ///     - state: current split controls state
    func updateMapMiniaturePosition() {
        let needToCenterSecondaryView = viewModel.isJoysticksVisible && viewModel.mode == .stream
        secondaryViewTopToSuperviewIpadConstraint.isActive = !needToCenterSecondaryView
        secondaryViewMiniatureConstraintsGetter.forEach { $0.isActive = !needToCenterSecondaryView }
        secondaryViewMiniatureCenterConstraints.forEach { $0.isActive = needToCenterSecondaryView }

        // Deactivate first height ratio's constraint when minimap is centered.
        secondaryViewHeightRatioConstraints[0].isActive = !needToCenterSecondaryView
        // Activate first height ratio's constraint when minimap is centered.
        secondaryViewHeightRatioConstraints[1].isActive = needToCenterSecondaryView
    }
}

extension SplitControls {
    public func addMap(_ map: MapViewController, parent: UIViewController) {

        // Prevent from double calls.
        guard parent != mapOr3DParent || map != mapViewController else {
            return
        }
        forceStream = false
        // remove if needed
        mapViewController?.remove()
        mapViewController?.unplug()

        // keep map and parent
        mapViewController = map
        mapViewController?.splitControls = self
        // keep parent (in order to add Map ou 3D view as child)
        mapOr3DParent = parent
        displayMapOr3DasChild()
    }

    /// Adapt secondary container (used in secondary mode)
    ///
    /// - Parameters:
    ///     - width: width to remove from trailing constraints.
    public func adaptSecondaryContainerTrailing(width: CGFloat) {
        applySecondaryViewTrailingConstraint(value: width, isActive: true)
    }

    /// Change display of bottom bar in HUD
    ///
    /// - Parameters:
    ///     - hide: state of display of bottom bar
    public func hideBottomBar(hide: Bool) {
        bottomBarContainerHUD.showFromEdge(.bottom, show: !hide, fadeFrom: 1)
    }

    /// Change display of camera sliders in HUD
    ///
    /// - Parameters:
    ///     - hide: state of display of camera sliders
    public func hideCameraSliders(hide: Bool) {
        cameraSlidersHUD.showFromEdge(.left, show: !hide, fadeFrom: 1)
    }

    /// Update the right pannel with Map or 3D View
    open func displayMapOr3DasChild() {
        guard mapViewController != nil, let parent = mapOr3DParent else {
            return
        }
        var vcToDisplay: UIViewController?
        switch SecondaryScreenType.current {
        case .threeDimensions where isMapRequired, .map:
            if forceStream {
                if streamViewController == nil {
                    streamViewController = HUDCameraStreamingViewController.instantiate()
                }
                vcToDisplay = streamViewController
            } else {
                vcToDisplay = mapViewController
            }

        case .threeDimensions:
            if occupancyViewController == nil {
                occupancyViewController = OccupancyViewController.instantiate()
            }
            vcToDisplay = occupancyViewController
        }

        if vcToDisplay?.parent == parent {
            // the requested ViewController is currently displayed
            return
        } else {
            // remove the previous
            mapViewController?.remove()
            streamViewController?.remove()
            occupancyViewController?.remove()
            // we do not keep the occupancyViewController if it is not necessary
            if vcToDisplay != occupancyViewController {
                occupancyViewController = nil
            }
            if vcToDisplay != streamViewController {
                streamViewController = nil
            }
            // add the vcToDisplay as child
            if let vcToDisplay = vcToDisplay {
                parent.addChild(vcToDisplay)
                secondaryContainerView.addWithConstraints(subview: vcToDisplay.view)
                vcToDisplay.didMove(toParent: parent)
            }
        }
    }
}
