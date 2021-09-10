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
import Lottie

/// View Controller used to display the drone magnetometer calibration.
final class MagnetometerCalibrationViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var calibrateButton: UIButton!
    @IBOutlet private weak var okButton: UIButton!
    @IBOutlet private weak var droneCalibrationAxesView: DroneCalibrationAxesView!
    @IBOutlet private weak var instructionsView: DroneCalibrationInstructionsView!
    @IBOutlet private weak var droneCalibrationTitle: UILabel!
    @IBOutlet private weak var backButton: UIButton!

    // MARK: - Private Properties
    private weak var coordinator: DroneCalibrationCoordinator?
    private var viewModel = MagnetometerCalibrationProcessViewModel()

    // MARK: - Private Enums
    private enum Constants {
        static let pitchfileName: String = "pitch"
        static let rollFileName: String = "roll"
        static let yawFileName: String = "yaw"
        static let fileExtension: String = "json"
    }

    // MARK: - Public Enums
    public enum CalibrationAnimations {
        case yaw
        case roll
        case pitch

        /// Json file name for animations.
        var animationFileName: String {
            switch self {
            case .pitch:
                return Constants.pitchfileName
            case .roll:
                return Constants.rollFileName
            case .yaw:
                return Constants.yawFileName
            }
        }

        /// File format for animations.
        var animationFormat: String {
            return Constants.fileExtension
        }
    }

    // MARK: - Setup
    /// Instantiate View controller.
    ///
    /// - Parameters:
    ///     - coordinator: navigation coordinator
    static func instantiate(coordinator: DroneCalibrationCoordinator) -> MagnetometerCalibrationViewController {
        let viewController = StoryboardScene.DroneCalibration.magnetometerCalibrationViewController.instantiate()
        viewController.coordinator = coordinator
        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        self.initUI()
        self.setupViewModels()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.magnetometerCalibration, logType: .screen)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.viewModel.cancelCalibration()
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
}

// MARK: - Actions
private extension MagnetometerCalibrationViewController {
    /// Function called when the back button is clicked.
    @IBAction func backButtonTouchedUpInside(_ sender: UIButton) {
        self.closeCalibrationView()
    }

    /// Function called when the calibrate button is clicked.
    @IBAction func calibrateButtonTouchedUpInside(_ sender: Any) {
        self.calibrateButton.isHidden = true
        self.droneCalibrationAxesView.isHidden = false
        self.viewModel.startCalibration()
        LogEvent.logAppEvent(itemName: LogEvent.LogKeyDroneDetailsCalibrationButton.magnetometerCalibrationCalibrate,
                             newValue: self.viewModel.state.value.calibrationProcessState?.failed.description,
                             logType: .button)
    }

    /// Function called when the ok button is clicked.
    @IBAction func okButtonTouchedUpInside(_ sender: Any) {
        self.closeCalibrationView()
    }
}

// MARK: - Private Funcs
private extension MagnetometerCalibrationViewController {
    /// Initializes all the UI for the view controller.
    func initUI() {
        self.droneCalibrationTitle.text = L10n.remoteCalibrationTitle
        instructionsView.viewModel = DroneCalibrationInstructionsModel(image: Asset.Drone.icDroneOpenYourDrone.image,
                                                                       firstLabel: L10n.droneMagnetometerCalibrationInstruction,
                                                                       secondLabel: L10n.droneMagnetometerCalibrationInstructionComplement,
                                                                       items: [])
        calibrateButton.cornerRadiusedWith(backgroundColor: ColorName.highlightColor.color, radius: Style.largeCornerRadius)
        calibrateButton.setTitle(L10n.commonStart, for: .normal)
        okButton.cornerRadiusedWith(backgroundColor: ColorName.highlightColor.color, radius: Style.largeCornerRadius)
        okButton.setTitle(L10n.ok, for: .normal)
    }

    /// Start lottie animation from json files.
    ///
    /// - Parameters:
    ///     - calibrationType: Enum corresponding to current animation.
    private func startAnimation(calibrationType: CalibrationAnimations) {
        guard let currentBundle = Bundle.currentBundle(for: MagnetometerCalibrationViewController.self),
              let jsonUrl = currentBundle.url(forResource: calibrationType.animationFileName,
                                              withExtension: calibrationType.animationFormat) else {
            return
        }

        instructionsView.playAnimation(filePath: jsonUrl.path)
    }

    /// Updates the UI for the specified state.
    ///
    /// - Parameters:
    ///    - calibrationProcessState: state of the magnetometer.
    func updateMagnetometerUI(calibrationProcessState: Magnetometer3StepCalibrationProcessState) {
        switch calibrationProcessState.currentAxis {
        case .none:
            break
        case .roll:
            self.displayRoll()
        case .pitch:
            self.displayPitch()
        case .yaw:
            self.displayYaw()
        }
        calibrationProcessState.calibratedAxes.forEach { self.droneCalibrationAxesView.markAsCalibrated(axis: $0) }
        if calibrationProcessState.failed {
            self.onFailure()
        }
        if calibrationProcessState.isCalibrated(axis: .roll) {
            self.onCalibrationCompleted()
        }
    }

    /// Sets up view models associated with the view.
    func setupViewModels() {
        self.viewModel.state.valueChanged = { [weak self] state in
            if let droneState = state.droneState,
               droneState == .disconnected || droneState == .disconnecting {
                self?.closeCalibrationView()
            }

            if state.flyingState == .flying {
                self?.viewModel.cancelCalibration()
                self?.closeCalibrationView()
            }

            if let calibrationProcessState = state.calibrationProcessState {
                self?.updateMagnetometerUI(calibrationProcessState: calibrationProcessState)
            }
        }
    }

    /// Display yaw animation.
    func displayYaw() {
        startAnimation(calibrationType: .yaw)
        instructionsView.viewModel.firstLabel = L10n.droneCalibrationYawInstruction
        instructionsView.viewModel.secondLabel = L10n.droneCalibrationInstructionComplement
        droneCalibrationAxesView.displayCurrentAxis(currentAxis: .yaw)
    }

    /// Display pitch animation.
    func displayPitch() {
        startAnimation(calibrationType: .pitch)
        instructionsView.viewModel.firstLabel = L10n.droneCalibrationPitchInstruction
        instructionsView.viewModel.secondLabel = L10n.droneCalibrationInstructionComplement
        droneCalibrationAxesView.displayCurrentAxis(currentAxis: .pitch)
    }

    /// Display roll animation.
    func displayRoll() {
        startAnimation(calibrationType: .roll)
        instructionsView.viewModel.firstLabel = L10n.droneCalibrationRollInstruction
        instructionsView.viewModel.secondLabel = L10n.droneCalibrationInstructionComplement
        droneCalibrationAxesView.displayCurrentAxis(currentAxis: .roll)
    }

    /// Update UI for the calibration failure.
    func onFailure() {
        instructionsView.clearAnimation()
        instructionsView.viewModel.firstLabel = L10n.droneCalibrationFailed
        instructionsView.viewModel.firstLabelColor = ColorName.errorColor.color
        instructionsView.viewModel.firstLabelAlignment = .left
        instructionsView.viewModel.secondLabel = L10n.droneCalibrationFailureDescription
        instructionsView.viewModel.secondLabelAlignment = .left
        instructionsView.viewModel.items = [L10n.droneCalibrationFailureItem1,
                                            L10n.droneCalibrationFailureItem2,
                                            L10n.droneCalibrationFailureItem3,
                                            L10n.droneCalibrationFailureItem4]
        instructionsView.viewModel.image = nil
        droneCalibrationAxesView.isHidden = true
        droneCalibrationAxesView.reset()
        calibrateButton.setTitle(L10n.droneCalibrationRedo.uppercased(), for: .normal)
        calibrateButton.isHidden = true
        okButton.isHidden = false
    }

    /// Update UI for the calibration success.
    func onCalibrationCompleted() {
        instructionsView.clearAnimation()
        instructionsView.viewModel.image = Asset.Drone.Calibration.Yaw.icAnafi2CalibrationYaw00.image
        instructionsView.viewModel.firstLabel = L10n.droneCalibrationReadyToFly
        instructionsView.viewModel.secondLabel = nil
        instructionsView.viewModel.firstLabelColor = ColorName.highlightColor.color
        droneCalibrationAxesView.isHidden = true
        calibrateButton.isHidden = true
        okButton.isHidden = false
    }

    /// Close the view controller.
    func closeCalibrationView() {
        self.viewModel.cancelCalibration()
        coordinator?.leave()
    }
}
