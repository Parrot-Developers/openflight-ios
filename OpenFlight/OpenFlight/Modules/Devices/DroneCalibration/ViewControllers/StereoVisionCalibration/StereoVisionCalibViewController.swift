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
import AVFoundation
import AVKit
import GroundSdk

/// View Controller used to display first Stereo Vision calibration screen.
final class StereoVisionCalibViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var firstLabel: UILabel!
    @IBOutlet private weak var secondLabel: UILabel!
    @IBOutlet private weak var thirdLabel: UILabel!
    @IBOutlet private weak var readyButton: UIButton!
    @IBOutlet private weak var videoView: UIView!
    @IBOutlet private weak var backButton: UIButton!

    // MARK: - Private Properties
    private weak var coordinator: DroneCalibrationCoordinator?
    private var isRequired: Bool = false
    private var videoEndedObserver: Any?

    // MARK: - Private Enums
    private enum Constants {
        static let currentOrientation: String = "orientation"
        static let videoName: String = "Calib_tutorial"
        static let videoFormat: String = "mp4"
    }

    // MARK: - Setup
    /// Instantiate View controller.
    ///
    /// - Parameters:
    ///     - isRequired: tell if the calibration is required
    ///     - coordinator: navigation coordinator
    static func instantiate(isRequired: Bool = false, coordinator: DroneCalibrationCoordinator) -> StereoVisionCalibViewController {
        let viewController = StoryboardScene.StereoVisionCalibration.stereoVisionCalibrationViewController.instantiate()
        viewController.coordinator = coordinator
        viewController.isRequired = isRequired
        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initUI()
        self.addVideoTutorial()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.sensorCalibrationTutorial,
                             logType: .screen)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        NotificationCenter.default.remove(observer: videoEndedObserver)
        videoEndedObserver = nil
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension StereoVisionCalibViewController {
    @IBAction func readyButtonTouchedUpInside(_ sender: Any) {
        self.coordinator?.startStereoVisionCalibrationSteps()
    }
    @IBAction func backButtonTouchedUpInside(_ sender: Any) {
        self.coordinator?.back()
    }
}

// MARK: - Private Funcs
private extension StereoVisionCalibViewController {
    /// Initializes all the UI for the view controller.
    func initUI() {
        if !UIApplication.isLandscape {
            let value = UIInterfaceOrientation.landscapeRight.rawValue
            UIDevice.current.setValue(value, forKey: Constants.currentOrientation)
        }
        self.titleLabel.text = L10n.sensorCalibrationTutorialTitle
        self.firstLabel.text = L10n.sensorCalibrationTutorialDesc1
        self.secondLabel.text = L10n.sensorCalibrationTutorialDesc2
        self.thirdLabel.text = L10n.sensorCalibrationTutorialDesc3
        self.readyButton.cornerRadiusedWith(backgroundColor: ColorName.greenSpring20.color, radius: Style.largeCornerRadius)
        self.readyButton.setTitleColor(ColorName.white.color, for: .normal)
        self.readyButton.setTitle(L10n.sensorCalibrationTutorialReady, for: .normal)
    }

    /// Add tutorial video to first love calibration screen.
    func addVideoTutorial() {
        guard let currentBundle = Bundle.currentBundle(for: StereoVisionCalibViewController.self),
              let videoPath = currentBundle.url(forResource: Constants.videoName, withExtension: Constants.videoFormat) else {
            return
        }

        let moviePlayer = AVPlayer(url: videoPath)
        let playerLayer = AVPlayerLayer(player: moviePlayer)
        playerLayer.frame = videoView.frame
        playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoView.layer.addSublayer(playerLayer)
        videoView.layer.masksToBounds = true
        videoView.bringSubviewToFront(backButton)
        playerLayer.player?.play()
        loopVideo(videoPlayer: moviePlayer)

        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord,
                                                            options: [AVAudioSession.CategoryOptions.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error {
            ULog.e(ULogTag(name: error.localizedDescription))
        }
    }

    /// Loop video when it comes to end.
    ///
    /// - Parameters:
    ///    - videoPlayer: player which reads tutorial video.
    func loopVideo(videoPlayer: AVPlayer) {
        videoEndedObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                                                    object: nil,
                                                                    queue: nil) { _ in
            videoPlayer.seek(to: CMTime.zero)
            videoPlayer.play()
        }
    }
}
