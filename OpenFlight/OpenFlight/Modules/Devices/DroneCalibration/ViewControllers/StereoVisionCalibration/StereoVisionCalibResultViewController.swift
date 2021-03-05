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

/// View Controller used to display Stereo Vision calibration result screen.
final class StereoVisionCalibResultViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var resultImageView: UIImageView!
    @IBOutlet private weak var retryButton: UIButton!
    @IBOutlet private weak var cancelButton: UIButton!

    // MARK: - Internal Properties
    var isCalibrated: Bool?

    // MARK: - Private Properties
    private weak var coordinator: DroneCalibrationCoordinator?
    private var isRequired: Bool = false

    // MARK: - Private Enums
    private enum Constants {
        static let currentOrientation: String = "orientation"
    }

    // MARK: - Setup
    /// Instantiate View controller.
    ///
    /// - Parameters:
    ///     - isRequired: tell if the calibration is required
    ///     - coordinator: navigation coordinator
    static func instantiate(isRequired: Bool = false, coordinator: DroneCalibrationCoordinator) -> StereoVisionCalibResultViewController {
        let viewController = StoryboardScene.StereoVisionCalibration.stereoVisionCalibrationResultViewController.instantiate()
        viewController.coordinator = coordinator
        viewController.isRequired = isRequired

        return viewController
    }

    // MARK: - Override Funcs
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.initLogs()
        self.initUI()
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
private extension StereoVisionCalibResultViewController {
    @IBAction func retryButtonTouchedUpInside(_ sender: Any) {
        guard let isCalibrated = isCalibrated else { return }
        isCalibrated ? self.coordinator?.backToRoot() : self.coordinator?.startStereoVisionCalibrationSteps()
    }

    @IBAction func cancelButtonTouchedUpInside(_ sender: Any) {
        self.coordinator?.backToRoot()
    }
}

// MARK: - Private Funcs
private extension StereoVisionCalibResultViewController {
    /// Initializes all the UI for the view controller.
    func initUI() {
        guard let isCalibrated = isCalibrated else { return }

        self.descriptionLabel.isHidden = isCalibrated
        self.descriptionLabel.text = L10n.loveCalibrationRetry
        self.descriptionLabel.textColor = ColorName.orangePeel.color
        self.cancelButton.isHidden = isCalibrated
        self.retryButton.cornerRadiusedWith(backgroundColor: ColorName.greenSpring20.color, radius: Style.largeCornerRadius)
        self.retryButton.setTitleColor(ColorName.white.color, for: .normal)
        self.cancelButton.cornerRadiusedWith(backgroundColor: ColorName.white20.color, radius: Style.largeCornerRadius)
        self.cancelButton.setTitleColor(ColorName.white.color, for: .normal)
        self.cancelButton.setTitle(L10n.cancel, for: .normal)

        switch isCalibrated {
        case true:
            self.titleLabel.textColor = ColorName.greenSpring.color
            self.titleLabel.text = L10n.sensorCalibrationCompleted
            resultImageView.image = Asset.Drone.icStereoVisionSuccess.image
            self.retryButton.setTitle(L10n.loveCalibrationFinish, for: .normal)
        default:
            resultImageView.image = Asset.Drone.icStereoVisionFailed.image
            self.titleLabel.textColor = ColorName.orangePeel.color
            self.titleLabel.text = L10n.sensorCalibrationFailed
            self.retryButton.setTitle(L10n.commonRetry, for: .normal)
        }
    }

    /// Inits event logs.
    func initLogs() {
        guard let isCalibrated = isCalibrated else { return }

        LogEvent.logAppEvent(screen: isCalibrated
                                ? LogEvent.EventLoggerScreenConstants.sensorCalibrationSuccess
                                : LogEvent.EventLoggerScreenConstants.sensorCalibrationFailure,
                             logType: .screen)
    }
}
