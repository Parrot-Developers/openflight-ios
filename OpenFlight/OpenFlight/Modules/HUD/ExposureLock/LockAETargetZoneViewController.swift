//  Copyright (C) 2021 Parrot Drones SAS.
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
import GroundSdk
import SwiftyUserDefaults

final class LockAETargetZoneViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var lockAETargetZoneImageView: UIImageView!
    @IBOutlet private weak var touchAreaView: UIView!

    // MARK: - Private Enums
    private enum Constants {
        static let defaultTargetZoneWidth: CGFloat = 70
        static let defaultTargetZoneHeight: CGFloat = 70
        static let fadeAnimationTimeInterval: TimeInterval = 0.15
        static let lockedAnimationTimeInterval: TimeInterval = 0.5
        static let lockingAnimationTimeInterval: TimeInterval = 0.5
        static let shortAnimationTimeInterval: TimeInterval = 0.1
        static let hideTargetZoneDelaySeconds: Int = 2
        static let minimumLongTapDuration: TimeInterval = 0.2
        static let targetZoneAlpha: CGFloat = 0.5
        static let lockingTargetZoneAlpha: CGFloat = 0.3
    }

    // MARK: - Public properties
    /// Video streaming content zone.
    var streamingContentZone: CGRect? {
        didSet {
            if let frame = streamingContentZone {
                // resize and move touch area over streaming content
                touchAreaView.frame = frame

                // Hide target zone when sreaming content changes.
                // But do not hide it if this change results from bottom bar
                // opening.
                // TODO: find a way to resize and move correctly the target zone
                // when the streaming content zone changes.
                if hideTargetZoneOnContentZoneChange {
                    hideTargetZone()
                } else if streamingContentZone?.height != oldValue?.height {
                    updateTargetZone(shortAnimation: true)
                }
                hideTargetZoneOnContentZoneChange = true
            }
        }
    }

    // MARK: - Private Properties
    private var hideTask = DispatchWorkItem {}
    /// Combine subscriptions.
    private var cancellables = Set<AnyCancellable>()
    /// View model.
    /// TODO injection
    private var viewModel = LockAETargetZoneViewModel(
        exposureLockService: Services.hub.exposureLockService)
    /// Whether target zoneshould be hidden on next streaming content zone change.
    var hideTargetZoneOnContentZoneChange = true
    /// Time at which touch down occured.
    var touchDownTime: Date?
    /// Whether locked on region animation is ongoing.
    var lockedAnimationOngoing = false

    // MARK: - Setup
    static func instantiate() -> LockAETargetZoneViewController {
        let lockAETargetVC = StoryboardScene.LockAETargetZone.lockAETargetZoneViewController.instantiate()
        return lockAETargetVC
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initUI()
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

    // MARK: - Internal Funcs
    /// Shows target zone if exposure is locked or locking.
    func showTargetZone() {
        hideTargetZoneOnContentZoneChange = false
        updateTargetZone(shortAnimation: true)
    }

    /// Hides target zone.
    func hideTargetZone() {
        hideTask.cancel()
        lockAETargetZoneImageView.layer.removeAllAnimations()
        UIView.animate(withDuration: Constants.shortAnimationTimeInterval,
                       animations: {
                        self.lockAETargetZoneImageView.alpha = 0.0
                       },
                       completion: { _ in
                        self.lockAETargetZoneImageView.isHidden = true
                       }
        )
    }
}

// MARK: - Private Funcs
private extension LockAETargetZoneViewController {
    /// Initializes all the UI for the view controller.
    func initUI() {
        let tapRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleTap))
        tapRecognizer.minimumPressDuration = 0.0
        touchAreaView.addGestureRecognizer(tapRecognizer)

        listenViewModel()
    }

    /// Setups view model listeners.
    func listenViewModel() {
        viewModel.statePublisher
            .removeDuplicates()
            .sink { [unowned self] _ in
                updateTargetZone()
            }
            .store(in: &cancellables)

        viewModel.lockRegionPublisher
            .filter { $0 != nil }
            .sink { [unowned self] _ in
                updateTargetZone()
            }
            .store(in: &cancellables)
    }

    /// Updates target zone display.
    ///
    /// - Parameters:
    ///    - shortAnimation: `true` to animate with short duration
    func updateTargetZone(shortAnimation: Bool = false) {
        switch viewModel.stateValue {
        case .unavailable,
             .unlocked,
             .lockingOnCurrentValues,
             .lockedOnCurrentValues:
            hideTargetZone()
        case .lockingOnRegion(let centerX, let centerY):
            showLockingTargetZone(centerX: centerX,
                                  centerY: centerY)
        case .lockOnRegion:
            showLockedTargetZone(shortAnimation: shortAnimation)
        }
    }

    /// Tells whether a touch event occured on the unlock icon.
    ///
    /// - Parameters:
    ///    - recognizer: long press gesture recognizer
    func hasTappedOnClose(_ recognizer: UILongPressGestureRecognizer) -> Bool {
        let point = recognizer.location(in: lockAETargetZoneImageView)
        let topLeftCorner = CGRect(x: 0.0,
                                   y: 0.0,
                                   width: lockAETargetZoneImageView.bounds.width / 2.0,
                                   height: lockAETargetZoneImageView.bounds.height / 2.0)
        return topLeftCorner.contains(point)
    }

    /// Handles touch events on touch area.
    ///
    /// - Parameters:
    ///    - recognizer: long press gesture recognizer
    @objc func handleTap(_ recognizer: UILongPressGestureRecognizer) {
        guard !viewModel.tapEventsIgnored else {
            return
        }

        if recognizer.state == .began,
           !lockAETargetZoneImageView.isHidden,
           viewModel.stateValue == .lockOnRegion,
           hasTappedOnClose(recognizer) {
            // user tapped on unlock icon
            viewModel.unlock()
        } else if recognizer.state == .began,
                  !lockedAnimationOngoing {
            // on touch down, show target zone where user tapped
            touchDownTime = Date()
            let location = recognizer.location(in: view)
            showTappedZone(center: location)
        } else if recognizer.state != .changed,
                  let beganTime = touchDownTime {
            // touch up occured before long touch delay,
            // hide target zone
            let now = Date()
            if now.timeIntervalSince(beganTime) < Constants.minimumLongTapDuration {
                hideTargetZone()
            }
            touchDownTime = nil
        } else {
            touchDownTime = nil
        }
    }

    /// Shows locked target zone, and hides it after a delay.
    ///
    /// - Parameters:
    ///    - shortAnimation: `true` to animate with short duration
    func showLockedTargetZone(shortAnimation: Bool = false) {
        guard let lockRegion = viewModel.lockRegionValue,
              viewModel.stateValue == .lockOnRegion else {
            return
        }

        let centerX = CGFloat(lockRegion.centerX) * touchAreaView.frame.width
        let centerY = CGFloat(lockRegion.centerY) * touchAreaView.frame.height
        let width = CGFloat(lockRegion.width) * touchAreaView.frame.width
        let height = CGFloat(lockRegion.height) * touchAreaView.frame.height
        let frame = CGRect(center: CGPoint(x: centerX, y: centerY),
                           width: width,
                           height: height)

        let animationDuration = shortAnimation ?
            Constants.shortAnimationTimeInterval : Constants.lockedAnimationTimeInterval
        hideTask.cancel()
        lockAETargetZoneImageView.layer.removeAllAnimations()
        lockAETargetZoneImageView.image = Asset.ExposureLock.aeTargetZoneWithClose.image
        lockAETargetZoneImageView.frame = frame.insetBy(dx: -frame.width / 4, dy: -frame.height / 4)
        lockAETargetZoneImageView.alpha = 1
        lockAETargetZoneImageView.isHidden = false
        lockedAnimationOngoing = true
        UIView.animate(withDuration: animationDuration,
                       animations: {
                        self.lockAETargetZoneImageView.frame = frame
                        self.lockAETargetZoneImageView.alpha = Constants.targetZoneAlpha
                       },
                       completion: { _ in
                        self.lockedAnimationOngoing = false
                       })
        hideTargetZoneDelayed()
    }

    /// Shows locking taget zone.
    ///
    /// - Parameters:
    ///     - centerX: locking target center X
    ///     - centerX: locking target center Y
    func showLockingTargetZone(centerX: Double, centerY: Double) {
        let centerX = CGFloat(centerX) * touchAreaView.frame.width
        let centerY = CGFloat(centerY) * touchAreaView.frame.height
        let width = Constants.defaultTargetZoneWidth
        let height = Constants.defaultTargetZoneHeight
        let frame = CGRect(center: CGPoint(x: centerX, y: centerY),
                           width: width,
                           height: height)

        hideTask.cancel()
        lockAETargetZoneImageView.layer.removeAllAnimations()
        lockAETargetZoneImageView.image = Asset.ExposureLock.aeTargetZone.image
        lockAETargetZoneImageView.frame = frame.insetBy(dx: -frame.width / 4, dy: -frame.height / 4)
        lockAETargetZoneImageView.alpha = 1
        lockAETargetZoneImageView.isHidden = false
        UIView.animate(withDuration: Constants.lockingAnimationTimeInterval,
                       delay: 0.0,
                       options: [.repeat, .curveLinear]) {
            self.lockAETargetZoneImageView.frame = frame.insetBy(dx: frame.width / 4, dy: -frame.height / 4)
            self.lockAETargetZoneImageView.alpha = Constants.lockingTargetZoneAlpha
        }
    }

    /// Shows tapped zone.
    ///
    /// It's displayed with an animation. If this animation completes (i.e. not cancelled),
    /// this means that the user did a long touch. In that case, a request to lock exposure
    /// is notified to the view model.
    ///
    /// - Parameters:
    ///     - center: center of tapped zone, relative to touch area
    func showTappedZone(center: CGPoint) {
        let width = Constants.defaultTargetZoneWidth
        let height = Constants.defaultTargetZoneHeight
        let frame = CGRect(center: center,
                           width: width,
                           height: height)

        hideTask.cancel()
        lockAETargetZoneImageView.layer.removeAllAnimations()
        lockAETargetZoneImageView.image = Asset.ExposureLock.aeTargetZone.image
        lockAETargetZoneImageView.frame = frame
        lockAETargetZoneImageView.alpha = 1
        lockAETargetZoneImageView.isHidden = false
        UIView.animate(withDuration: Constants.minimumLongTapDuration, animations: {
            self.lockAETargetZoneImageView.alpha = Constants.targetZoneAlpha
        }, completion: { finished in
            if finished {
                // animation was not cancelled, meaning user did a long touch
                self.lockOnRegion(center: center)
            }
        })
    }

    /// Animates hiding target zone with a delay.
    func hideTargetZoneDelayed() {
        hideTask.cancel()
        lockAETargetZoneImageView.layer.removeAllAnimations()
        hideTask = DispatchWorkItem {
            UIView.animate(withDuration: Constants.fadeAnimationTimeInterval,
                           animations: {
                            self.lockAETargetZoneImageView.alpha = 0.0
                           },
                           completion: { _ in
                            self.lockAETargetZoneImageView.isHidden = true
                           }
            )
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(Constants.hideTargetZoneDelaySeconds), execute: hideTask)
    }

    /// Notifies view model that user requests to lock exposure on a region.
    ///
    /// - Parameters:
    ///    - center: center of region where user requests locking, relative to touch area
    func lockOnRegion(center: CGPoint) {
        let touchFrame = CGRect(x: 0, y: 0,
                                width: touchAreaView.frame.width,
                                height: touchAreaView.frame.height)
        if let center = touchFrame.relativeCoordinates(for: center) {
            viewModel.lockOnRegion(centerX: Double(center.0),
                                   centerY: Double(center.1))
        }
    }
}
