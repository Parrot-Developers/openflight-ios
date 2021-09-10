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
        static let defaultTargetZoneWidth: CGFloat = 80
        static let defaultTargetZoneHeight: CGFloat = 80
        static let fadeAnimationTimeInterval: TimeInterval = 0.15
        static let tappedAnimationTimeInterval: TimeInterval = 0.5
        static let lockedAnimationTimeInterval: TimeInterval = 0.5
        static let lockingAnimationTimeInterval: TimeInterval = 0.5
        static let shortAnimationTimeInterval: TimeInterval = 0.1
        static let hideTargetZoneDelaySeconds: Int = 2
        static let minimumLongTapDuration: TimeInterval = 1.0
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
                // TODO: find a way to resize and move correctly the target zone
                // when the streaming content zone changes.
                hideTargetZone()
            }
        }
    }

    // MARK: - Private Properties
    private var hideTask = DispatchWorkItem {}
    /// Combine subscriptions.
    private var cancellables = Set<AnyCancellable>()
    /// Long touch timeout.
    private var longTouchTimeout: AnyCancellable?
    /// View model.
    /// TODO injection
    private var viewModel = LockAETargetZoneViewModel(
        exposureService: Services.hub.drone.exposureService,
        exposureLockService: Services.hub.drone.exposureLockService)
    /// Time at which touch down occured.
    var touchDownTime: Date?
    /// Whether locking on region animation is ongoing.
    var lockingAnimationOngoing = false
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
    func updateTargetZone() {
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
            if let lockRegion = viewModel.lockRegionValue {
                showLockedTargetZone(lockRegion: lockRegion)
            }
        }
    }

    /// Handles touch events on touch area.
    ///
    /// - Parameters:
    ///    - recognizer: long press gesture recognizer
    @objc func handleTap(_ recognizer: UILongPressGestureRecognizer) {
        guard !viewModel.tapEventsIgnored,
              !lockingAnimationOngoing,
              !lockedAnimationOngoing else {
            return
        }

        switch recognizer.state {
        case .began:
            // on touch down, show target zone where user tapped
            touchDownTime = Date()
            let location = recognizer.location(in: view)
            showTappedZone(center: location)
            startLongTouchTimeout(center: location)
        case .ended:
            guard let beganTime = touchDownTime else { break }

            let now = Date()
            if now.timeIntervalSince(beganTime) < Constants.minimumLongTapDuration {
                // touch up occured before long touch delay,
                // hide target zone
                hideTargetZone()
                cancelLongTouchTimeout()
            }
            touchDownTime = nil
        case .changed:
            // do nothing
            break
        default:
            hideTargetZone()
            cancelLongTouchTimeout()
            touchDownTime = nil
        }
    }

    /// Starts long touch timeout.
    ///
    /// At timeout, view model is notified that user requests to lock exposure on a region.
    ///
    /// - Parameter center: location touched by the user
    func startLongTouchTimeout(center: CGPoint) {
        longTouchTimeout = Just(true)
            .delay(for: .seconds(Constants.minimumLongTapDuration), scheduler: DispatchQueue.main)
            .sink { [unowned self] _ in
                lockOnRegion(center: center)
            }
    }

    /// Cancels long touch timeout.
    func cancelLongTouchTimeout() {
        longTouchTimeout?.cancel()
        longTouchTimeout = nil
    }

    /// Shows locked target zone, and hides it after a delay.
    ///
    /// - Parameters:
    ///    - lockRegion: locked target region
    func showLockedTargetZone(lockRegion: ExposureLockRegion) {
        let centerX = CGFloat(lockRegion.centerX) * touchAreaView.frame.width
        let centerY = CGFloat(lockRegion.centerY) * touchAreaView.frame.height
        let width = CGFloat(lockRegion.width) * touchAreaView.frame.width
        let height = CGFloat(lockRegion.height) * touchAreaView.frame.height
        let frame = CGRect(center: CGPoint(x: centerX, y: centerY),
                           width: width,
                           height: height)

        hideTask.cancel()
        lockedAnimationOngoing = true
        lockAETargetZoneImageView.layer.removeAllAnimations()
        lockAETargetZoneImageView.image = Asset.ExposureLock.aeTargetZone.image
        lockAETargetZoneImageView.frame = frame.insetBy(dx: -frame.width / 4, dy: -frame.height / 4)
        lockAETargetZoneImageView.alpha = 1
        lockAETargetZoneImageView.isHidden = false
        UIView.animate(withDuration: Constants.lockedAnimationTimeInterval,
                       animations: {
                        self.lockAETargetZoneImageView.frame = frame
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
        lockingAnimationOngoing = true
        lockAETargetZoneImageView.layer.removeAllAnimations()
        lockAETargetZoneImageView.image = Asset.ExposureLock.aeTargetZone.image
        lockAETargetZoneImageView.frame = frame.insetBy(dx: -frame.width / 4, dy: -frame.height / 4)
        lockAETargetZoneImageView.alpha = 1
        lockAETargetZoneImageView.isHidden = false
        UIView.animate(withDuration: Constants.lockingAnimationTimeInterval,
                       delay: 0.0,
                       options: [.repeat, .curveLinear],
                       animations: {
                        self.lockAETargetZoneImageView.frame = frame.insetBy(dx: frame.width / 4, dy: -frame.height / 4)
                        self.lockAETargetZoneImageView.alpha = Constants.lockingTargetZoneAlpha
                       },
                       completion: { _ in
                        self.lockingAnimationOngoing = false
                       })
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
        UIView.animate(withDuration: Constants.tappedAnimationTimeInterval,
                       delay: 0.0,
                       options: [.repeat, .curveLinear, .autoreverse]) {
            self.lockAETargetZoneImageView.alpha = Constants.targetZoneAlpha
        }
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
