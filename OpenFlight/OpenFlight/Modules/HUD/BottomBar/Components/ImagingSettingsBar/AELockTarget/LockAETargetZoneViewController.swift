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
    @IBOutlet private weak var lockAETargetZone: UIImageView!

    // MARK: - Private Enums
    private enum Constants {
        static let defaultTargetZoneWidth: CGFloat = 70
        static let defaultTargetZoneHeight: CGFloat = 70
        static let fadeAnimationTimeInterval: TimeInterval = 0.15
        static let resizeAnimationTimeInterval: TimeInterval = 0.5
        static let hideTargetZoneDelaySeconds: Int = 2
    }

    // MARK: - Public properties
    var currentContentZone: CGRect?

    // MARK: - Private Properties
    private var hideTask = DispatchWorkItem {}
    private var shouldShowSampleFrame = true
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
        self.setupViewModels()
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
        lockAETargetZone.isHidden = false
        guard shouldShowSampleFrame,
              let camera = self.viewModel.state.value.camera,
              !camera.isHdrOn,
              camera.currentEditor[Camera2Params.exposureMode]?.value != .manual else {
            return
        }

        initTargetZone(at: CGRect(center: CGPoint(x: view.center.x, y: view.center.y - view.bounds.height / 8),
                                  width: Constants.defaultTargetZoneWidth,
                                  height: Constants.defaultTargetZoneHeight))
        shouldShowSampleFrame = false
    }

    /// Hides target zone.
    func hideTargetZone() {
        self.lockAETargetZone.alpha = 0.0
        self.lockAETargetZone.isHidden = true
    }
}

// MARK: - Private Funcs
private extension LockAETargetZoneViewController {
    /// Initializes all the UI for the view controller.
    func initUI() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        tapGesture.numberOfTapsRequired = 1
        view.addGestureRecognizer(tapGesture)
    }

    /// Sets up view models associated with the view.
    func setupViewModels() {
        self.viewModel.state.valueChanged = { [weak self] state in
            guard let mode = state.lockAEMode else {
                return
            }

            switch mode {
            case .region:
                self?.shouldShowSampleFrame = false
                if let frame = self?.currentContentZone?.rectAt(CGFloat(self?.centerX ?? 0.0),
                                                                CGFloat(self?.centerY ?? 0.0),
                                                                CGFloat(Constants.defaultTargetZoneWidth),
                                                                CGFloat(Constants.defaultTargetZoneHeight)) {
                    self?.moveTargetZone(to: frame)
                }
            case .none, .currentValues:
                self?.hideTask.cancel()
                UIView.animate(withDuration: Constants.fadeAnimationTimeInterval, animations: {
                    self?.lockAETargetZone.alpha = 0
                })
            }
        }
    }

    /// Action triggered when user tap on screen..
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: self.view)
        guard let camera = self.viewModel.state.value.camera,
              camera.isHdrOn == false,
              camera.currentEditor[Camera2Params.exposureMode]?.value != .manual,
              let exposureLock = camera.getComponent(Camera2Components.exposureLock),
              let center = currentContentZone?.relativeCoordinates(for: location) else {
            return
        }

        exposureLock.unlock()
        exposureLock.lockOnRegion(centerX: Double(center.0),
                                  centerY: Double(center.1))
        centerX = Double(center.0)
        centerY = Double(center.1)
        shouldUpdateFrame = true
        initTargetZone(at: CGRect(center: location,
                                  width: Constants.defaultTargetZoneWidth,
                                  height: Constants.defaultTargetZoneHeight))
    }

    /// Moves target zone.
    ///
    /// - Parameters:
    ///     - frame: new target zone frame to given frame.
    func moveTargetZone(to frame: CGRect) {
        guard lockAETargetZone.frame.contains(frame.center), shouldUpdateFrame else {
            return
        }

        shouldUpdateFrame = false
        lockAETargetZone.alpha = 0
        UIView.animate(withDuration: Constants.fadeAnimationTimeInterval, animations: {
            self.lockAETargetZone.alpha = 1
            self.lockAETargetZone.frame = frame.insetBy(dx: -frame.width / 4, dy: -frame.height / 4)
        }, completion: { _ in
            guard self.lockAETargetZone.frame.contains(frame.center) else {
                return
            }

            UIView.animate(withDuration: Constants.resizeAnimationTimeInterval, animations: {
                self.lockAETargetZone.frame = frame
            }, completion: { _ in
                self.delayedHideTargetZone()
            })
        })
    }

    /// Animates hiding target zone.
    func delayedHideTargetZone() {
        hideTask.cancel()
        hideTask = DispatchWorkItem {
            UIView.animate(withDuration: Constants.fadeAnimationTimeInterval, animations: {
                self.lockAETargetZone.alpha = 0
            })
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(Constants.hideTargetZoneDelaySeconds), execute: self.hideTask)
    }

    /// Initializes target zone.
    ///
    /// - Parameters:
    ///     - frame: Target zone frame.
    func initTargetZone(at frame: CGRect) {
        lockAETargetZone.frame = frame.insetBy(dx: -frame.width / 4, dy: -frame.height / 4)
        lockAETargetZone.alpha = 1
        UIView.animate(withDuration: Constants.resizeAnimationTimeInterval, animations: {
            self.lockAETargetZone.frame = frame
            self.lockAETargetZone.alpha = 0.5
        })
        delayedHideTargetZone()
    }
}
