// Copyright (C) 2020 Parrot Drones SAS
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
    @IBOutlet private weak var centerMapButton: UIButton! {
        didSet {
            self.centerMapButton.setImage(Asset.Map.centerOnUser.image, for: .normal)
            self.centerMapButton.applyHUDRoundButtonStyle()
        }
    }
    @IBOutlet private weak var splitViewConstraint: NSLayoutConstraint!
    @IBOutlet private weak var splitViewIpadConstraint: NSLayoutConstraint!

    @IBOutlet private var streamTrailingToSplitViewConstraint: NSLayoutConstraint!
    @IBOutlet private var streamBottomToSplitViewIpadConstraint: NSLayoutConstraint!

    @IBOutlet private var secondaryViewLeadingToSplitViewConstraint: NSLayoutConstraint!
    @IBOutlet private var secondaryViewTopToSplitViewIpadConstraint: NSLayoutConstraint!

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

    @IBOutlet private var streamMiniatureLeadingToMissionLauncher: NSLayoutConstraint! {
        didSet {
            streamMiniatureLeadingToMissionLauncher.isActive = false
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
        static let minimumStreamViewHeight: CGFloat = UIScreen.main.bounds.height / 2
        static let minimumStreamViewWidth: CGFloat = 200
        // Secondary view has a minimum width of 15% of the screen, unless it is smaller than 140 points.
        static let minimumSecondaryViewWidth: CGFloat = max(UIScreen.main.bounds.width * 0.15, 140)
        static let minimumSecondaryViewHeight: CGFloat = max(UIScreen.main.bounds.height * 0.25, 140)
        static let splitToFullscreenAnimationDelay: TimeInterval = 0.8
        static let defaultAnimationDuration: TimeInterval = 0.35
        static let defaultStreamRatio: CGFloat = 4/3
        static let streamRatioPrecision: Int = 1
        static let secondaryMiniatureHeightRatio: CGFloat = 0.3
        static let secondaryMiniatureCenterHeightRatio: CGFloat = 0.2
        static let secondaryMiniatureBorderWidth: CGFloat = 4.0
        static let secondaryMiniatureBorderColor: UIColor = ColorName.black60.color
    }

    // MARK: - Internal Properties

    weak var cameraStreamingViewController: HUDCameraStreamingViewController?
    var mapViewController: MapViewController?
    weak var mapOr3DParent: UIViewController?
    var delayedTaskComponents = DelayedTaskComponents()
    weak var delegate: SplitControlsDelegate?
    var isSecondaryContainerEmpty: Bool {
        return self.secondaryContainerView.subviews.isEmpty
    }

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

    // TODO: Wrong injection
    private unowned var currentMissionManager = Services.hub.currentMissionManager
    private var currentStreamRatio: CGFloat?
    private var preferredSplitPosition: CGFloat {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            guard let currentStreamRatio = currentStreamRatio else {
                return .zero
            }
            let preferredHeight = view.frame.width * currentStreamRatio + self.splitView.frame.height / 2

            // Avoid crash when the app is laucnhed for the first time
            if Constants.minimumStreamViewHeight >= self.view.frame.height {
                return ( Constants.minimumStreamViewHeight...self.view.frame.width).clamp(preferredHeight)
            } else {
                let height = self.view.frame.height
                if height - Constants.minimumSecondaryViewHeight >= Constants.minimumStreamViewHeight {
                    return (Constants.minimumStreamViewHeight...self.view.frame.height - Constants.minimumSecondaryViewHeight)
                        .clamp(preferredHeight)
                } else {
                    return (self.view.frame.height - Constants.minimumSecondaryViewHeight...Constants.minimumStreamViewHeight)
                        .clamp(preferredHeight)
                }
            }

        default:
            guard let currentStreamRatio = currentStreamRatio else {
                return .zero
            }
            let preferredWidth = view.frame.height * currentStreamRatio + self.splitView.frame.width / 2
            return (Constants.minimumStreamViewWidth...self.view.frame.width - Constants.minimumSecondaryViewWidth)
                .clamp(preferredWidth)
        }
    }
    private var secondaryViewCornerRadius: CGFloat {
        let state = viewModel
        let ratio = state.isJoysticksVisible && state.mode == .stream ? Constants.secondaryMiniatureCenterHeightRatio : Constants.secondaryMiniatureHeightRatio
        return self.view.frame.height * ratio / 2.0
    }
    private var occupancyViewController: OccupancyViewController?
    private var streamViewController: HUDCameraStreamingViewController?
    private var isMapRequired: Bool { Services.hub.currentMissionManager.mode.isMapRequired }

    // MARK: - Internal Funcs

    /// Sets up gesture recognizers.
    /// Should be called inside viewDidLoad.
    func start() {
        setLongPressGesture()
        viewModel.shouldHideSecondary
            .sink { [weak self] shouldHideSecondary in
                UIView.animate(withDuration: Constants.defaultAnimationDuration) {
                    self?.secondaryContainerView.alphaHidden(shouldHideSecondary)
                }
            }
            .store(in: &cancellables)
        viewModel.bottomBarModePublisher
            .combineLatest(viewModel.isJoysticksVisiblePublisher, viewModel.modePublisher)
            .sink { [weak self] _ in
                self?.updateJogs()
            }
            .store(in: &cancellables)
        currentMissionManager.modePublisher.sink { [unowned self] in
            setSplitMode($0.preferredSplitMode)
            updateStreamState(enabled: !$0.isRightPanelRequired)
        }
        .store(in: &cancellables)
    }

    /// Updates the constraints when returning from background
    @objc func updateConstraintForForeground() {
        streamMiniatureLeadingToMissionLauncher.isActive = false
        streamTrailingToSuperviewConstraint.isActive = false
        let tempMode = viewModel.mode
        if tempMode == .secondary {
            secondaryViewToSplitViewConstraint.isActive = false
        } else {
            secondaryViewLeadingToSuperviewConstraint.isActive = false
        }
        viewModel.setMode(currentMissionManager.mode.preferredSplitMode)
        setSplitMode(tempMode, animated: false)
    }

    /// Sets up initial split screen position.
    /// Should be called inside viewDidAppear in
    /// order to have the correct view frame.
    func setupSplitIfNeeded() {
        // Avoid overwrite of previous stream ratio.
        guard currentStreamRatio == nil else { return }

        currentStreamRatio = Constants.defaultStreamRatio
        if !viewModel.isJoysticksVisible {
            setupSplitedScreen(atValue: preferredSplitPosition)
        }
    }

    /// Updates split mode layout according current and new modes.
    func setSplitMode(_ mode: SplitScreenMode, animated: Bool = true) {
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
            switchToSplitScreenFromStreamTap(animated: animated)
        case (.secondary, .stream):
            switchFromSecondaryToStreamingFullScreen(animated: animated)
        default:
            break
        }
        displayMapOr3DasChild()
    }

    /// Sets up a new ratio for the stream. Should be called when
    /// content zone gets updated.
    ///
    /// - Parameters:
    ///    - contentZone: content zone used to calculate new ratio
    func setupRatio(withContentZone contentZone: CGRect?) {
        guard let contentZone = contentZone, contentZone.height != 0 else { return }
        let videoRatio = contentZone.width / contentZone.height

        /// Update only if ratio has changed.
        if videoRatio.rounded(toPlaces: Constants.streamRatioPrecision) != currentStreamRatio?.rounded(toPlaces: Constants.streamRatioPrecision) {
            currentStreamRatio = videoRatio
            setupSplitedScreen(atValue: preferredSplitPosition, animated: true)
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
    func updateCenterMapButtonStatus(hide: Bool, image: UIImage?) {
        centerMapButton.isHidden = hide
        centerMapButton.setImage(image, for: .normal)
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

    @IBAction func centerMapButtonTouchedUpInsider(_ sender: UIButton) {
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

        switch sender.state {
        case .ended, .cancelled, .failed:
            cancelDelayedTask()
            splitView.stopAnimation()
            return

        default:
            break
        }

        handleLongPress(at: sender.location(in: view))
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
        let baseFrame = view.frame
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            switch point.y {
            case 0...Constants.minimumStreamViewHeight:
                if !isTaskPending() {
                    setupDelayedTask(setupSecondaryViewFullscreen,
                                     delay: Constants.splitToFullscreenAnimationDelay)
                    splitView.startAnimation()
                }

            case Constants.minimumStreamViewHeight...baseFrame.height - Constants.minimumSecondaryViewHeight:
                cancelDelayedTask()
                splitView.stopAnimation()
                setupSplitedScreen(atValue: point.y)

            case baseFrame.height - Constants.minimumSecondaryViewHeight...baseFrame.height:
                if !isTaskPending() {
                    setupDelayedTask(setupStreamingFullscreen,
                                     delay: Constants.splitToFullscreenAnimationDelay)
                    splitView.startAnimation()
                }

            default:
                break
            }

        default:
            switch point.x {
            case 0...Constants.minimumStreamViewWidth:
                if !isTaskPending() {
                    setupDelayedTask(setupSecondaryViewFullscreen,
                                     delay: Constants.splitToFullscreenAnimationDelay)
                    splitView.startAnimation()
                }

            case Constants.minimumStreamViewWidth...baseFrame.width - Constants.minimumSecondaryViewWidth:
                cancelDelayedTask()
                splitView.stopAnimation()
                setupSplitedScreen(atValue: point.x)

            case baseFrame.width - Constants.minimumSecondaryViewWidth...baseFrame.width:
                if !isTaskPending() {
                    setupDelayedTask(setupStreamingFullscreen,
                                     delay: Constants.splitToFullscreenAnimationDelay)
                    splitView.startAnimation()
                }
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
        mapViewController?.disableUserInteraction(false)
        updateSecondaryContainer()
        displayMapOr3DasChild()

        if animated {
            UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: {
                // Moves secondary view from miniature position to splited position.

                self.secondaryViewMiniatureConstraintsGetter.forEach { $0.isActive = false }
                self.secondaryViewFullscreenConstraintsGetter.forEach { $0.isActive = true }
                self.secondaryViewToSplitViewConstraint.isActive = true
                self.view.layoutIfNeeded()
            }, completion: { _ in
                UIView.animate(withDuration: Constants.defaultAnimationDuration) {
                    // Moves stream from fullscreen position to splited position
                    // and updates preferred position.

                    self.streamToSuperviewConstraint.isActive = false
                    self.streamToSplitViewConstraint.isActive = true
                    self.setupSplitedScreen(atValue: self.preferredSplitPosition)
                    self.view.layoutIfNeeded()
                }
            })
        } else {
            self.secondaryViewMiniatureConstraintsGetter.forEach { $0.isActive = false }
            self.secondaryViewFullscreenConstraintsGetter.forEach { $0.isActive = true }
            self.secondaryViewToSplitViewConstraint.isActive = true
            self.streamToSuperviewConstraint.isActive = false
            self.streamToSplitViewConstraint.isActive = true
            self.setupSplitedScreen(atValue: self.preferredSplitPosition)
            self.view.layoutIfNeeded()
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
        mapViewController?.disableUserInteraction(false)

        if animated {
            UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: {
                // Moves stream from miniature to splited position.

                self.streamMiniatureConstraints.forEach { $0.isActive = false }
                self.streamFullscreenConstraintsGetter.forEach { $0.isActive = true }
                self.streamToSplitViewConstraint.isActive = true
                self.view.layoutIfNeeded()
            }, completion: { _ in
                UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: {
                    // Moves secondary view to its position for splited
                    // mode and updates preferred position.

                    self.secondaryViewToSuperviewConstraint.isActive = false
                    self.secondaryViewToSplitViewConstraint.isActive = true
                    self.setupSplitedScreen(atValue: self.preferredSplitPosition)
                    self.view.layoutIfNeeded()
                }, completion: { _ in
                    self.cameraStreamingViewController?.mode = .fullscreen
                })
            })
        } else {
            self.streamMiniatureConstraints.forEach { $0.isActive = false }
            self.streamFullscreenConstraintsGetter.forEach { $0.isActive = true }
            self.streamToSplitViewConstraint.isActive = true
            self.secondaryViewToSuperviewConstraint.isActive = false
            self.secondaryViewToSplitViewConstraint.isActive = true
            self.setupSplitedScreen(atValue: self.preferredSplitPosition)
            self.view.layoutIfNeeded()
            self.cameraStreamingViewController?.mode = .fullscreen
        }
    }

    /// Moves currently splited mode to another location.
    func setupSplitedScreen(atValue value: CGFloat, animated: Bool = false) {
        guard viewModel.mode == .splited else {
            return
        }
        if animated {
            UIView.animate(withDuration: Style.shortAnimationDuration) {
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
        mapViewController?.disableUserInteraction(false)
        cameraStreamingViewController?.mode = .preview

        UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: {
            // Moves secondary view from splited position to fullscreen position.

            self.secondaryViewToSplitViewConstraint.isActive = false
            self.secondaryViewToSuperviewConstraint.isActive = true
            self.view.layoutIfNeeded()
        }, completion: { _ in
            UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: {
                // Moves stream from splited position to miniature position.

                self.streamToSplitViewConstraint.isActive = false
                self.streamFullscreenConstraintsGetter.forEach { $0.isActive = false }
                self.streamMiniatureConstraints.forEach { $0.isActive = true }
                self.view.layoutIfNeeded()
            }, completion: { _ in
                self.cameraStreamingViewController?.addBorder()
            })
        })
    }

    /// Updates UI for secondary view fullscreen mode without animation.
    func setupSecondaryViewFullscreenNoAnimation() {
        splitView.stopAnimation()
        viewModel.setMode(.secondary)
        view.insertSubview(streamContainerView, aboveSubview: secondaryContainerView)
        streamButton.isUserInteractionEnabled = true
        mapViewController?.disableUserInteraction(false)
        cameraStreamingViewController?.mode = .preview

        self.secondaryViewToSplitViewConstraint.isActive = false
        self.secondaryViewToSuperviewConstraint.isActive = true
        self.streamToSplitViewConstraint.isActive = false
        self.streamFullscreenConstraintsGetter.forEach { $0.isActive = false }
        self.streamMiniatureConstraints.forEach { $0.isActive = true }
        self.view.layoutIfNeeded()
        self.cameraStreamingViewController?.addBorder()
    }

    /// Updates UI for stream fullscreen mode.
    func setupStreamingFullscreen() {
        splitView.stopAnimation()
        viewModel.setMode(.stream)
        view.insertSubview(aeLockContainerView, aboveSubview: streamContainerView)
        view.insertSubview(secondaryContainerView, aboveSubview: streamContainerView)
        mapViewController?.disableUserInteraction(true)
        secondaryViewButton.isUserInteractionEnabled = true
        displayMapOr3DasChild()

        UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: {
            // Moves stream from splited postion to fullscreen position.

            self.streamToSplitViewConstraint.isActive = false
            self.streamToSuperviewConstraint.isActive = true
            self.view.layoutIfNeeded()
        }, completion: { _ in
            UIView.animate(withDuration: Constants.defaultAnimationDuration) {
                // Moves secondary view from splited position to miniature position.

                self.secondaryViewToSplitViewConstraint.isActive = false
                self.secondaryViewFullscreenConstraintsGetter.forEach { $0.isActive = false }
                self.secondaryViewMiniatureConstraintsGetter.forEach { $0.isActive = true }
                self.updateSecondaryContainer()
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
        mapViewController?.disableUserInteraction(true)
        secondaryViewButton.isUserInteractionEnabled = true
        displayMapOr3DasChild()

        self.streamToSplitViewConstraint.isActive = false
        self.streamToSuperviewConstraint.isActive = true
        self.secondaryViewToSplitViewConstraint.isActive = false
        self.secondaryViewFullscreenConstraintsGetter.forEach { $0.isActive = false }
        self.secondaryViewMiniatureConstraintsGetter.forEach { $0.isActive = true }
        self.updateSecondaryContainer()
        self.view.layoutIfNeeded()
    }

    /// Updates UI from secondary to stream fullscreen mode.
    ///
    /// - Parameter animated: If the UI changes should be animated or not
    func switchFromSecondaryToStreamingFullScreen(animated: Bool = true) {
        viewModel.setMode(.stream)
        cameraStreamingViewController?.removeBorder()
        streamButton.isUserInteractionEnabled = false
        mapViewController?.disableUserInteraction(true)

        if animated {
            UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: {
                // Moves stream from miniature to full screen position.

                self.streamMiniatureConstraints.forEach { $0.isActive = false }
                self.streamFullscreenConstraintsGetter.forEach { $0.isActive = true }
                self.streamToSuperviewConstraint.isActive = true
                self.view.layoutIfNeeded()
            }, completion: { _ in
                UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: {
                    // Moves secondary view from full screen to miniature position.

                    self.secondaryViewToSuperviewConstraint.isActive = false
                    self.secondaryViewToSplitViewConstraint.isActive = false
                    self.secondaryViewFullscreenConstraintsGetter.forEach { $0.isActive = false }
                    self.secondaryViewMiniatureConstraintsGetter.forEach { $0.isActive = true }
                    self.updateSecondaryContainer()
                    self.view.layoutIfNeeded()
                }, completion: { _ in
                    self.view.insertSubview(self.aeLockContainerView, aboveSubview: self.streamContainerView)
                    self.view.insertSubview(self.secondaryContainerView, aboveSubview: self.streamContainerView)
                    self.secondaryViewButton.isUserInteractionEnabled = true
                    self.cameraStreamingViewController?.mode = .fullscreen
                })
            })
        } else {
            self.streamMiniatureConstraints.forEach { $0.isActive = false }
            self.streamFullscreenConstraintsGetter.forEach { $0.isActive = true }
            self.streamToSuperviewConstraint.isActive = true
            self.secondaryViewToSuperviewConstraint.isActive = false
            self.secondaryViewToSplitViewConstraint.isActive = false
            self.secondaryViewFullscreenConstraintsGetter.forEach { $0.isActive = false }
            self.secondaryViewMiniatureConstraintsGetter.forEach { $0.isActive = true }
            self.updateSecondaryContainer()
            self.view.layoutIfNeeded()
            self.view.insertSubview(self.aeLockContainerView, aboveSubview: self.streamContainerView)
            self.view.insertSubview(self.secondaryContainerView, aboveSubview: self.streamContainerView)
            self.secondaryViewButton.isUserInteractionEnabled = true
            self.cameraStreamingViewController?.mode = .fullscreen
        }
    }

    /// Updates UI from stream to secondary fullscreen mode.
    ///
    /// - Parameter animated: If the UI changes should be animated or not
    func switchFromStreamingToSecondaryFullScreen(animated: Bool = true) {
        viewModel.setMode(.secondary)
        secondaryViewButton.isUserInteractionEnabled = false
        mapViewController?.disableUserInteraction(false)
        updateSecondaryContainer()
        cameraStreamingViewController?.mode = .preview

        if animated == true {
            UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: {
                // Moves secondary view from miniature position to full screen position.

                self.secondaryViewMiniatureConstraintsGetter.forEach { $0.isActive = false }
                self.secondaryViewFullscreenConstraintsGetter.forEach { $0.isActive = true }
                self.secondaryViewToSplitViewConstraint.isActive = false
                self.secondaryViewToSuperviewConstraint.isActive = true
                self.view.layoutIfNeeded()
            }, completion: { _ in
                UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: {
                    // Moves stream from fullscreen position to miniature position
                    // and updates preferred position.

                    self.streamToSuperviewConstraint.isActive = false
                    self.streamFullscreenConstraintsGetter.forEach { $0.isActive = false }
                    self.streamMiniatureConstraints.forEach { $0.isActive = true }
                    self.view.layoutIfNeeded()
                }, completion: { _ in
                    self.cameraStreamingViewController?.addBorder()
                    self.streamButton.isUserInteractionEnabled = true
                    self.view.insertSubview(self.streamContainerView, aboveSubview: self.secondaryContainerView)
                })
            })
        } else {
            self.secondaryViewMiniatureConstraintsGetter.forEach { $0.isActive = false }
            self.secondaryViewFullscreenConstraintsGetter.forEach { $0.isActive = true }
            self.secondaryViewToSplitViewConstraint.isActive = false
            self.secondaryViewToSuperviewConstraint.isActive = true
            self.streamToSuperviewConstraint.isActive = false
            self.streamFullscreenConstraintsGetter.forEach { $0.isActive = false }
            self.streamMiniatureConstraints.forEach { $0.isActive = true }
            self.cameraStreamingViewController?.addBorder()
            self.view.layoutIfNeeded()
            self.streamButton.isUserInteractionEnabled = true
            self.view.insertSubview(self.streamContainerView, aboveSubview: self.secondaryContainerView)
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

    /// Updates secondary container view for current split screen mode.
    /// Miniature is rounded with a border when stream is fullscreen.
    func updateSecondaryContainer() {
        let isMiniature = viewModel.mode == .stream
        secondaryContainerView.setBorder(borderColor: isMiniature ? Constants.secondaryMiniatureBorderColor : .clear,
                                         borderWidth: isMiniature ? Constants.secondaryMiniatureBorderWidth : 0.0)
        // Adds/removes secondary view's custom corner radius (with animation).
        secondaryContainerView.addCornerRadiusAnimation(toValue: isMiniature ? secondaryViewCornerRadius : 0.0,
                                                        duration: Constants.defaultAnimationDuration)
    }

    /// Update split regarding jogs state.
    ///
    /// - Parameters:
    ///     - state: current split controls state
    func updateJogs() {
        splitTouchView.isUserInteractionEnabled = !viewModel.isJoysticksVisible
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
        let needToCenterSecondaryView = viewModel.isJoysticksVisible == true && viewModel.mode == .stream
        secondaryViewTopToSuperviewIpadConstraint.isActive = !needToCenterSecondaryView
        secondaryViewMiniatureConstraintsGetter.forEach { $0.isActive = !needToCenterSecondaryView }
        secondaryViewMiniatureCenterConstraints.forEach { $0.isActive = needToCenterSecondaryView }

        // Deactivate first height ratio's constraint when minimap is centered.
        secondaryViewHeightRatioConstraints[0].isActive = !needToCenterSecondaryView
        // Activate first height ratio's constraint when minimap is centered.
        secondaryViewHeightRatioConstraints[1].isActive = needToCenterSecondaryView
    }
}

// MARK: - MapViewRestorer

extension SplitControls: MapViewRestorer {
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

    /// Update the right pannel with Map or 3D View
    open func displayMapOr3DasChild() {
        guard mapViewController != nil, let parent = mapOr3DParent else {
            return
        }
        var vcToDisplay: UIViewController?
        switch SecondaryScreenType.current {
        case .map,
             .threeDimensions where isMapRequired:
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

    public func restoreMapIfNeeded() {
        guard isSecondaryContainerEmpty, let mapView = mapViewController?.view else {
                return
        }
        forceStream = false
        secondaryContainerView.addWithConstraints(subview: mapView)
    }
}
