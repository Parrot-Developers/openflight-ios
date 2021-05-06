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
import GroundSdk
import SwiftyUserDefaults

final class LockAETargetZoneViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var lockAETargetZoneImageView: UIImageView!

    // MARK: - Private Enums
    private enum Constants {
        static let defaultTargetZoneWidth: CGFloat = 70
        static let defaultTargetZoneHeight: CGFloat = 70
        static let fadeAnimationTimeInterval: TimeInterval = 0.15
        static let resizeAnimationTimeInterval: TimeInterval = 0.5
        static let hideTargetZoneDelaySeconds: Int = 2
        static let minimumLongTapDuration: TimeInterval = 0.2
    }

    // MARK: - Public properties
    var currentContentZone: CGRect?
    var shouldShowSampleFrame = true

    // MARK: - Private Properties
    private var hideTask = DispatchWorkItem {}
    private var shouldUpdateFrame = false
    private var centerX: Double = 0.0
    private var centerY: Double = 0.0
    private var viewModel = LockAETargetZoneViewModel()

    // MARK: - Setup
    static func instantiate(delegate: BottomBarContainerDelegate? = nil) -> LockAETargetZoneViewController {
        let lockAETargetVC = StoryboardScene.LockAETargetZone.lockAETargetZoneViewController.instantiate()
        return lockAETargetVC
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        self.initUI()
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
    /// Initializes target zone.
    func initTargetZone() {
        lockAETargetZoneImageView.isHidden = false
        guard shouldShowSampleFrame,
              let camera = self.viewModel.state.value.camera,
              !camera.isHdrOn,
              camera.currentEditor[Camera2Params.exposureMode]?.value != .manual else {
            return
        }

        initTargetZone(at: CGRect(center: CGPoint(x: view.center.x, y: view.center.y - view.bounds.height / 8),
                                  width: Constants.defaultTargetZoneWidth,
                                  height: Constants.defaultTargetZoneHeight),
                       isHideTarget: true)
        shouldShowSampleFrame = false
    }

    /// Hides target zone.
    func hideTargetZone() {
        self.lockAETargetZoneImageView.alpha = 0.0
    }
}

// MARK: - Private Funcs
private extension LockAETargetZoneViewController {
    /// Initializes all the UI for the view controller.
    func initUI() {
        let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongTap(recognizer:)))
        longTapGesture.minimumPressDuration = Constants.minimumLongTapDuration
        longTapGesture.delaysTouchesBegan = true
        view.addGestureRecognizer(longTapGesture)
        lockAETargetZoneImageView.isUserInteractionEnabled = true
        lockAETargetZoneImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapOnLockClose)))
    }

    /// Action triggered when user taps on close button.
    @objc func handleTapOnLockClose(_ recognizer: UITapGestureRecognizer) {
        let point = recognizer.location(in: self.lockAETargetZoneImageView)
        let topLeftCorner = CGRect(x: 0.0,
                                   y: 0.0,
                                   width: self.lockAETargetZoneImageView.bounds.width / 2.0,
                                   height: self.lockAETargetZoneImageView.bounds.height / 2.0)

        if topLeftCorner.contains(point) {
            self.viewModel.unlock()
        }
    }

    /// Action triggered when user taps long on screen..
    @objc func handleLongTap(recognizer: UILongPressGestureRecognizer) {
        guard recognizer.state == .began else { return }

        let location = recognizer.location(in: self.view)

        guard let camera = self.viewModel.state.value.camera,
              camera.isHdrOn == false,
              Defaults.isImagingAutoModeActive == true,
              let center = currentContentZone?.relativeCoordinates(for: location) else {
            return
        }

        self.viewModel.lockOnRegion(centerX: Double(center.0),
                                    centerY: Double(center.1))
        centerX = Double(center.0)
        centerY = Double(center.1)
        shouldUpdateFrame = true
        initTargetZone(at: CGRect(center: location,
                                  width: Constants.defaultTargetZoneWidth,
                                  height: Constants.defaultTargetZoneHeight),
                       isHideTarget: false)
    }

    /// Animates hiding target zone.
    func delayedHideTargetZone() {
        hideTask.cancel()
        hideTask = DispatchWorkItem {
            UIView.animate(withDuration: Constants.fadeAnimationTimeInterval, animations: {
                self.lockAETargetZoneImageView.alpha = 0.0
            })
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(Constants.hideTargetZoneDelaySeconds), execute: self.hideTask)
    }

    /// Initializes target zone.
    ///
    /// - Parameters:
    ///     - frame: Target zone frame.
    ///     - isHideTarget: Boolean to indicate if target zone is going to hide.
    func initTargetZone(at frame: CGRect, isHideTarget: Bool) {
        lockAETargetZoneImageView.frame = frame.insetBy(dx: -frame.width / 4, dy: -frame.height / 4)
        lockAETargetZoneImageView.alpha = 1
        UIView.animate(withDuration: Constants.resizeAnimationTimeInterval, animations: {
            self.lockAETargetZoneImageView.frame = frame
            self.lockAETargetZoneImageView.alpha = 0.5
        })
        if isHideTarget {
            delayedHideTargetZone()
        }
    }
}
