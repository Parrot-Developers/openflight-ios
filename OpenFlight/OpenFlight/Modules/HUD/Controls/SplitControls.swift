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

final class SplitControls: NSObject, DelayedTaskProvider {

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
    @IBOutlet private var streamTrailingToSplitViewConstraint: NSLayoutConstraint!
    @IBOutlet private var secondaryViewLeadingToSplitViewConstraint: NSLayoutConstraint!
    // Constraints shouldn't be deactivated in storyboard due to iOS13 issue with return from background.
    @IBOutlet private var streamTrailingToSuperviewConstraint: NSLayoutConstraint! {
        didSet {
            streamTrailingToSuperviewConstraint.isActive = false
        }
    }
    @IBOutlet private var secondaryViewLeadingToSuperviewConstraint: NSLayoutConstraint! {
        didSet {
            secondaryViewLeadingToSuperviewConstraint.isActive = false
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
    @IBOutlet private var streamMiniatureConstraints: [NSLayoutConstraint]!
    @IBOutlet private var secondaryViewFullscreenConstraints: [NSLayoutConstraint]!
    @IBOutlet private var secondaryViewMiniatureConstraints: [NSLayoutConstraint]!
    @IBOutlet private var secondaryViewMiniatureCenterConstraints: [NSLayoutConstraint]!
    @IBOutlet private var secondaryViewHeightRatioConstraints: [NSLayoutConstraint]!

    // MARK: - Private Enums
    private enum Constants {
        static let minimumStreamViewWidth: CGFloat = 200
        // Secondary view has a minimum width of 15% of the screen, unless it is smaller than 140 points.
        static let minimumSecondaryViewWidth: CGFloat = max(UIScreen.main.bounds.width * 0.15, 140)
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
    weak var mapViewController: MapViewController?
    var delayedTaskComponents = DelayedTaskComponents()
    weak var delegate: SplitControlsDelegate?
    var isSecondaryContainerEmpty: Bool {
        return self.secondaryContainerView.subviews.isEmpty
    }

    // MARK: - Private Properties
    private var longPressGestureRecognizer: UILongPressGestureRecognizer!
    private var cancellables = Set<AnyCancellable>()
    private let viewModel = SplitControlsViewModel()
    // TODO: Wrong injection
    private unowned var currentMissionManager = Services.hub.currentMissionManager
    private var currentStreamRatio: CGFloat?
    private var preferredSplitPosition: CGFloat {
        guard let currentStreamRatio = currentStreamRatio else {
            return .zero
        }
        let preferredWidth = view.frame.height * currentStreamRatio + self.splitView.frame.width / 2
        return (Constants.minimumStreamViewWidth...self.view.frame.width - Constants.minimumSecondaryViewWidth)
            .clamp(preferredWidth)
    }
    private var secondaryViewCornerRadius: CGFloat {
        let state = viewModel
        let ratio = state.isJoysticksVisible && state.mode == .stream ? Constants.secondaryMiniatureCenterHeightRatio : Constants.secondaryMiniatureHeightRatio
        return self.view.frame.height * ratio / 2.0
    }
    private var occupancyViewController: OccupancyViewController?
    private var stereoVisionBlendedViewController: StereoVisionBlendedViewController?
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
            updateStreamState(enabled: !$0.isFlightPlanPanelRequired)
        }
        .store(in: &cancellables)
    }

    /// Sets up initial split screen position.
    /// Should be called inside viewDidAppear in
    /// order to have the correct view frame.
    func setupSplitIfNeeded() {
        // Avoid overwrite of previous stream ratio.
        guard currentStreamRatio == nil else {
            return
        }
        currentStreamRatio = Constants.defaultStreamRatio
        if !viewModel.isJoysticksVisible {
            setupSplitedScreen(atValue: preferredSplitPosition)
        }
    }

    /// Updates split mode layout according current and new modes.
    func setSplitMode(_ mode: SplitScreenMode) {
        switch (viewModel.mode, mode) {
        case (.stream, .secondary):
            switchFromStreamingToSecondaryFullScreen()
        case (.stream, .splited):
            switchToSplitScreenFromSecondaryTap()
        case (.splited, .stream):
            setupStreamingFullscreen()
        case (.splited, .secondary):
            setupSecondaryViewFullscreen()
        case (.secondary, .splited):
            switchToSplitScreenFromStreamTap()
        case (.secondary, .stream):
            switchFromSecondaryToStreamingFullScreen()
        default:
            break
        }
        updateSecondaryViewContent()
    }

    /// Switch to full streaming mode if needed.
    func collapseSecondaryViewIfNeeded() {
        switch viewModel.mode {
        case .splited:
            setupStreamingFullscreen()
        default:
            break
        }
    }

    /// Sets up a new ratio for the stream. Should be called when
    /// content zone gets updated.
    ///
    /// - Parameters:
    ///    - contentZone: content zone used to calculate new ratio
    func setupRatio(withContentZone contentZone: CGRect?) {
        guard let contentZone = contentZone, contentZone.height != 0 else {
            return
        }
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

    /// Update secondary view content depending SecondaryScreenType settings.
    func updateSecondaryViewContent() {
        var secondaryView: UIView?
        switch SecondaryScreenType.current {
        case .map,
             .threeDimensions where viewModel.mode == .stream,
             .threeDimensions where isMapRequired:
            secondaryView = mapViewController?.view
        case .threeDimensions:
            if occupancyViewController == nil {
                occupancyViewController = OccupancyViewController.instantiate()
            }
            secondaryView = occupancyViewController?.view
        }

        if let secondView = secondaryView,
           secondaryContainerView.subviews.first(where: { $0 == secondView }) == nil {
            secondaryContainerView.subviews.forEach({ $0.removeFromSuperview() })
            secondaryContainerView.addWithConstraints(subview: secondView)
        }
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
        guard viewModel.mode == .splited else {
            return
        }
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

    /// Updates UI from stream fullscreen to splited mode, and animates changes.
    func switchToSplitScreenFromSecondaryTap() {
        viewModel.setMode(.splited)
        secondaryViewButton.isUserInteractionEnabled = false
        mapViewController?.disableUserInteraction(false)
        updateSecondaryContainer()
        updateSecondaryViewContent()
        UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: {
            // Moves secondary view from miniature position to splited position.
            self.secondaryViewMiniatureConstraints.forEach { $0.isActive = false }
            self.secondaryViewFullscreenConstraints.forEach { $0.isActive = true }
            self.secondaryViewLeadingToSplitViewConstraint.isActive = true
            self.view.layoutIfNeeded()
        }, completion: { _ in
            UIView.animate(withDuration: Constants.defaultAnimationDuration) {
                // Moves stream from fullscreen position to splited position
                // and updates preferred position.
                self.streamTrailingToSuperviewConstraint.isActive = false
                self.streamTrailingToSplitViewConstraint.isActive = true
                self.setupSplitedScreen(atValue: self.preferredSplitPosition)
                self.view.layoutIfNeeded()
            }
        })
    }

    /// Updates UI from secondary view fullscreen to splited mode, and animates changes.
    func switchToSplitScreenFromStreamTap() {
        viewModel.setMode(.splited)
        view.insertSubview(aeLockContainerView, aboveSubview: streamContainerView)
        view.insertSubview(streamContainerView, aboveSubview: secondaryContainerView)
        cameraStreamingViewController?.removeBorder()
        streamButton.isUserInteractionEnabled = false
        mapViewController?.disableUserInteraction(false)
        UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: {
            // Moves stream from miniature to splited position.
            self.streamMiniatureConstraints.forEach { $0.isActive = false }
            self.streamFullscreenConstraints.forEach { $0.isActive = true }
            self.streamTrailingToSplitViewConstraint.isActive = true
            self.view.layoutIfNeeded()
        }, completion: { _ in
            UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: {
                // Moves secondary view to its position for splited
                // mode and updates preferred position.
                self.secondaryViewLeadingToSuperviewConstraint.isActive = false
                self.secondaryViewLeadingToSplitViewConstraint.isActive = true
                self.setupSplitedScreen(atValue: self.preferredSplitPosition)
                self.view.layoutIfNeeded()
            }, completion: { _ in
                self.cameraStreamingViewController?.mode = .fullscreen
            })
        })
    }

    /// Moves currently splited mode to another location.
    func setupSplitedScreen(atValue value: CGFloat, animated: Bool = false) {
        guard viewModel.mode == .splited else {
            return
        }
        if animated {
            UIView.animate(withDuration: Style.shortAnimationDuration) {
                self.splitViewConstraint.constant = value
                self.view.layoutIfNeeded()
            }
        } else {
            splitViewConstraint.constant = value
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
            self.secondaryViewLeadingToSplitViewConstraint.isActive = false
            self.secondaryViewLeadingToSuperviewConstraint.isActive = true
            self.view.layoutIfNeeded()
        }, completion: { _ in
            UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: {
                // Moves stream from splited position to miniature position.
                self.streamTrailingToSplitViewConstraint.isActive = false
                self.streamFullscreenConstraints.forEach { $0.isActive = false }
                self.streamMiniatureConstraints.forEach { $0.isActive = true }
                self.view.layoutIfNeeded()
            }, completion: { _ in
                self.cameraStreamingViewController?.addBorder()
            })
        })
    }

    /// Updates UI for stream fullscreen mode.
    func setupStreamingFullscreen() {
        splitView.stopAnimation()
        viewModel.setMode(.stream)
        view.insertSubview(aeLockContainerView, aboveSubview: streamContainerView)
        view.insertSubview(secondaryContainerView, aboveSubview: streamContainerView)
        mapViewController?.disableUserInteraction(true)
        secondaryViewButton.isUserInteractionEnabled = true
        updateSecondaryViewContent()
        UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: {
            // Moves stream from splited postion to fullscreen position.
            self.streamTrailingToSplitViewConstraint.isActive = false
            self.streamTrailingToSuperviewConstraint.isActive = true
            self.view.layoutIfNeeded()
        }, completion: { _ in
            UIView.animate(withDuration: Constants.defaultAnimationDuration) {
                // Moves secondary view from splited position to miniature position.
                self.secondaryViewLeadingToSplitViewConstraint.isActive = false
                self.secondaryViewFullscreenConstraints.forEach { $0.isActive = false }
                self.secondaryViewMiniatureConstraints.forEach { $0.isActive = true }
                self.updateSecondaryContainer()
                self.view.layoutIfNeeded()
            }
        })
    }

    /// Updates UI from secondary to stream fullscreen mode.
    func switchFromSecondaryToStreamingFullScreen() {
        viewModel.setMode(.stream)
        cameraStreamingViewController?.removeBorder()
        streamButton.isUserInteractionEnabled = false
        mapViewController?.disableUserInteraction(true)
        UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: {
            // Moves stream from miniature to full screen position.
            self.streamMiniatureConstraints.forEach { $0.isActive = false }
            self.streamFullscreenConstraints.forEach { $0.isActive = true }
            self.streamTrailingToSuperviewConstraint.isActive = true
            self.view.layoutIfNeeded()
        }, completion: { _ in
            UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: {
                // Moves secondary view from full screen to miniature position.
                self.secondaryViewLeadingToSuperviewConstraint.isActive = false
                self.secondaryViewLeadingToSplitViewConstraint.isActive = false
                self.secondaryViewFullscreenConstraints.forEach { $0.isActive = false }
                self.secondaryViewMiniatureConstraints.forEach { $0.isActive = true }
                self.updateSecondaryContainer()
                self.view.layoutIfNeeded()
            }, completion: { _ in
                self.view.insertSubview(self.aeLockContainerView, aboveSubview: self.streamContainerView)
                self.view.insertSubview(self.secondaryContainerView, aboveSubview: self.streamContainerView)
                self.secondaryViewButton.isUserInteractionEnabled = true
                self.cameraStreamingViewController?.mode = .fullscreen
            })
        })
    }

    /// Updates UI from stream to secondary fullscreen mode.
    func switchFromStreamingToSecondaryFullScreen() {
        viewModel.setMode(.secondary)
        secondaryViewButton.isUserInteractionEnabled = false
        mapViewController?.disableUserInteraction(false)
        updateSecondaryContainer()
        cameraStreamingViewController?.mode = .preview

        UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: {
            // Moves secondary view from miniature position to full screen position.
            self.secondaryViewMiniatureConstraints.forEach { $0.isActive = false }
            self.secondaryViewFullscreenConstraints.forEach { $0.isActive = true }
            self.secondaryViewLeadingToSplitViewConstraint.isActive = false
            self.secondaryViewLeadingToSuperviewConstraint.isActive = true
            self.view.layoutIfNeeded()
        }, completion: { _ in
            UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: {
                // Moves stream from fullscreen position to miniature position
                // and updates preferred position.
                self.streamTrailingToSuperviewConstraint.isActive = false
                self.streamFullscreenConstraints.forEach { $0.isActive = false }
                self.streamMiniatureConstraints.forEach { $0.isActive = true }
                self.view.layoutIfNeeded()
            }, completion: { _ in
                self.cameraStreamingViewController?.addBorder()
                self.streamButton.isUserInteractionEnabled = true
                self.view.insertSubview(self.streamContainerView, aboveSubview: self.secondaryContainerView)
            })
        })
    }

    /// Notifies delegate when stream size did change.
    ///
    /// - Parameters:
    ///     - afterDelay: Notification is triggered after delay
    func streamSizeDidChange(afterDelay: TimeInterval = Style.shortAnimationDuration) {
        // Inform about an update in stream view size.
        DispatchQueue.main.asyncAfter(deadline: .now() + afterDelay) { [weak self] in
            guard let weakSelf = self else {
                return
            }
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
            let value = viewModel.isJoysticksVisible
                ? UIScreen.main.bounds.width - Constants.minimumSecondaryViewWidth
                : preferredSplitPosition
            setupSplitedScreen(atValue: value)
        }
    }

    /// Update secondary miniature position according to mode and joysticks state.
    ///
    /// - Parameters:
    ///     - state: current split controls state
    func updateMapMiniaturePosition() {
        let needToCenterSecondaryView = viewModel.isJoysticksVisible == true && viewModel.mode == .stream
        secondaryViewMiniatureConstraints.forEach { $0.isActive = !needToCenterSecondaryView }
        secondaryViewMiniatureCenterConstraints.forEach { $0.isActive = needToCenterSecondaryView }

        // Deactivate first height ratio's constraint when minimap is centered.
        secondaryViewHeightRatioConstraints[0].isActive = !needToCenterSecondaryView
        // Activate first height ratio's constraint when minimap is centered.
        secondaryViewHeightRatioConstraints[1].isActive = needToCenterSecondaryView
    }
}

// MARK: - MapViewRestorer
extension SplitControls: MapViewRestorer {
    func addMap(_ map: UIViewController, parent: UIViewController) {
        // Prevent from double calls.
        guard let map = map as? MapViewController,
            map != mapViewController
            else {
                return
        }
        // Remove old map, if exists.
        mapViewController?.remove()
        // Add map.
        mapViewController = map
        mapViewController?.splitControls = self
        parent.addChild(map)
        secondaryContainerView.addWithConstraints(subview: map.view)
        map.didMove(toParent: parent)
    }

    func restoreMapIfNeeded() {
        guard isSecondaryContainerEmpty,
            let mapView = mapViewController?.view
            else {
                return
        }
        secondaryContainerView.addWithConstraints(subview: mapView)
    }
}
