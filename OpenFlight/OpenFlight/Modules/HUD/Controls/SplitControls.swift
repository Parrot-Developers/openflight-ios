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
    @IBOutlet private weak var primaryContainerView: UIView!
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

    // MARK: - Private Enums

    private enum Constants {
        static let minimumStreamViewHeight: CGFloat = UIScreen.main.bounds.height * 0.21
        static let minimumStreamViewWidth: CGFloat = 200
        // Secondary view has a minimum width of 15% of the screen, unless it is smaller than 140 points.
        static let minimumSecondaryViewWidth: CGFloat = max(UIScreen.main.bounds.width * 0.15, 140)
        static let minimumSecondaryViewHeight: CGFloat = max(UIScreen.main.bounds.height * 0.25, 140)
        static let defaultAnimationDuration: TimeInterval = 0.35
        static let defaultStreamRatio: CGFloat = 4/3
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

    private var longPressGestureRecognizer: UILongPressGestureRecognizer!
    private var cancellables = Set<AnyCancellable>()
    private let viewModel = SplitControlsViewModel()
    public var forceStream: Bool = false

    private unowned var currentMissionManager: CurrentMissionManager!
    private var preferredSplitPosition: CGFloat?
    private var defaultSplitPosition: CGFloat {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            let preferredHeight = UIScreen.main.bounds.width * Constants.defaultStreamRatio
            return (Constants.minimumStreamViewHeight...UIScreen.main.bounds.height - Constants.minimumSecondaryViewHeight)
                .clamp(preferredHeight)

        default:
            let preferredWidth = UIScreen.main.bounds.height * Constants.defaultStreamRatio
            return (Constants.minimumStreamViewWidth...UIScreen.main.bounds.width - Constants.minimumSecondaryViewWidth)
                .clamp(preferredWidth)
        }
    }
    private var occupancyViewController: OccupancyViewController?
    public var streamViewController: HUDCameraStreamingViewController?
    private var isMapRequired: Bool { currentMissionManager.mode.isMapRequired }

    // MARK: - Internal Funcs

    /// Sets up gesture recognizers.
    /// Should be called inside viewDidLoad.
    func start(currentMissionManager: CurrentMissionManager) {
        self.currentMissionManager = currentMissionManager
        setLongPressGesture()
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
        updateSplitModeLayout(viewModel.mode ?? currentMissionManager.mode.preferredSplitMode)
        centerMapButton.applyHUDRoundButtonStyle()
    }

    /// Sets up initial split screen position.
    /// Should be called inside viewDidAppear in
    /// order to have the correct view frame.
    func setupSplitIfNeeded() {
        guard preferredSplitPosition == nil, !viewModel.isJoysticksVisible else { return }
        setupSplitScreen(atValue: defaultSplitPosition)
    }

    /// Updates split mode layout according current and new modes.
    func updateSplitModeLayout(_ mode: SplitScreenMode) {
        if mode != viewModel.mode {
            viewModel.setMode(mode)
            hideBottomBar(hide: false)
            hideCameraSliders(hide: false)
        }

        primaryContainerView.isHidden = mode == .secondary
        secondaryContainerView.isHidden = mode == .primary
        splitView.isHidden = mode != .split

        displayMapOr3DasChild()
    }

    /// Starts or stops stream (⚠️ only works after viewDidAppear).
    ///
    /// - Parameters:
    ///    - enabled: whether stream should be started or stopped
    func updateStreamState(enabled: Bool) {
        enabled ? cameraStreamingViewController?.restartStream() : cameraStreamingViewController?.stopStream()
    }

    /// Update centerMapButton status.
    ///
    /// - Parameters:
    ///    - image: image
    open func updateCenterMapButtonStatus(state: MapCenterState? = nil) {
        switch SecondaryScreenType.current {
        case .threeDimensions where isMapRequired, .map:
            centerMapButton.isHidden = forceStream
        case .threeDimensions:
            centerMapButton.isHidden = true
        }
        if let state = state {
            centerMapButton.setImage(state.image, for: .normal)
            centerMapButton.accessibilityValue = state.rawValue
        }
    }
}

// MARK: - Actions

private extension SplitControls {
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
        guard viewModel.mode == .split else { return }

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
                setupSplitScreen(atValue: point.y)

            default:
                break
            }

        default:
            switch point.x {
            case Constants.minimumStreamViewWidth...bounds.width - Constants.minimumSecondaryViewWidth:
                setupSplitScreen(atValue: point.x)

            default:
                break
            }
        }
    }

    /// Moves currently split mode to another location.
    ///
    /// - Parameters:
    ///    - value: the split view position to move at (function has no effect if `nil`)
    ///    - animated: whether split view change sholuld be animated
    func setupSplitScreen(atValue value: CGFloat?, animated: Bool = false) {
        guard let value = value, viewModel.mode == .split else { return }

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

    /// Notifies delegate when stream size did change.
    ///
    /// - Parameters:
    ///     - afterDelay: Notification is triggered after delay
    func streamSizeDidChange(afterDelay: TimeInterval = Style.shortAnimationDuration) {
        // Inform about an update in stream view size.
        DispatchQueue.main.asyncAfter(deadline: .now() + afterDelay) { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.delegate?.streamSizeDidChange(width: weakSelf.primaryContainerView.frame.width)
        }
    }

    /// Update split regarding jogs state.
    ///
    /// - Parameters:
    ///     - state: current split controls state
    func updateJogs() {
        splitTouchView.isUserInteractionEnabled = !viewModel.isJoysticksVisible && !currentMissionManager.mode.isRightPanelRequired

        // Setup a split value when joysticks are visible.
        if viewModel.mode == .split {
            switch UIDevice.current.userInterfaceIdiom {
            case .pad:
                let value = viewModel.isJoysticksVisible
                ? UIScreen.main.bounds.height - Constants.minimumSecondaryViewHeight
                : preferredSplitPosition
                setupSplitScreen(atValue: value)
            default:
                let value = viewModel.isJoysticksVisible
                ? UIScreen.main.bounds.width - Constants.minimumSecondaryViewWidth
                : preferredSplitPosition
                setupSplitScreen(atValue: value)
            }
        }
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
    public func displayMapOr3DasChild() {
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
