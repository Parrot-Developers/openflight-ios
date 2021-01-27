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

/// View Controller used to display the drone magnetometer calibration.
final class MagnetometerCalibrationViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var calibrateButton: UIButton!
    @IBOutlet private weak var okButton: UIButton!
    @IBOutlet private weak var droneCalibrationAxesView: DroneCalibrationAxesView!
    @IBOutlet private weak var instructionsView: DroneCalibrationInstructionsView!
    @IBOutlet private weak var droneCalibrationTitle: UILabel!
    @IBOutlet private weak var cancelButton: UIButton!
    @IBOutlet private weak var backButton: UIButton!

    // MARK: - Private Properties
    private weak var coordinator: DroneCalibrationCoordinator?
    private var viewModel = MagnetometerCalibrationViewModel()
    private var isRequired: Bool = false

    // MARK: - Private Enums
    /// Enum which stores messages to log.
    private enum EventLoggerConstants {
        static let screenMessage: String = "DroneMagnetometerCalibration"
    }

    // MARK: - Setup
    /// Instantiate View controller.
    ///
    /// - Parameters:
    ///     - isRequired: tell if the calibration is required
    ///     - coordinator: navigation coordinator
    static func instantiate(isRequired: Bool = false, coordinator: DroneCalibrationCoordinator) -> MagnetometerCalibrationViewController {
        let viewController = StoryboardScene.DroneCalibration.magnetometerCalibrationViewController.instantiate()
        viewController.coordinator = coordinator
        viewController.isRequired = isRequired

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

        logScreen(logMessage: EventLoggerConstants.screenMessage)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.viewModel.cancelCalibration()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
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

    /// Function called when the cancel button is clicked.
    @IBAction func cancelButtonTouchedUpInside(_ sender: UIButton) {
        self.closeCalibrationView()
    }

    /// Function called when the calibrate button is clicked.
    @IBAction func calibrateButtonTouchedUpInside(_ sender: Any) {
        self.calibrateButton.isHidden = true
        self.droneCalibrationAxesView.isHidden = false
        self.viewModel.startCalibration()
        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.magnetometer.name,
                             itemName: LogEvent.LogKeyDroneDetailsCalibrationButton.magnetometerCalibrationCalibrate,
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
        instructionsView.viewModel = DroneCalibrationInstructionsModel(image: Asset.Drone.icDroneDetails.image,
                                                                       firstLabel: L10n.droneCalibrationIntroduction,
                                                                       secondLabel: L10n.droneCalibrationIntroductionComplement,
                                                                       firstLabelColor: ColorName.white.color)
        calibrateButton.setTitle(L10n.remoteCalibrationCalibrate.uppercased(), for: .normal)
        okButton.setTitle(L10n.ok.uppercased(), for: .normal)
        cancelButton.setTitle(L10n.cancel, for: .normal)
        calibrateButton.roundCorneredWith(backgroundColor: ColorName.white20.color)
        okButton.roundCorneredWith(backgroundColor: ColorName.white20.color)
        cancelButton.isHidden = !isRequired
        backButton.isHidden = isRequired
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

    // TODO: To refact.
    /// Display the yaw animation.
    func displayYaw() {
        let yawAnimationImages: [UIImage] = Asset.Drone.Calibration.Yaw.allValues.map { $0.image }
        instructionsView.viewModel.image = UIImage.animatedImage(with: yawAnimationImages, duration: 2)
        instructionsView.viewModel.firstLabel = L10n.droneCalibrationYawInstruction
        instructionsView.viewModel.secondLabel = L10n.droneCalibrationInstructionComplement
        instructionsView.viewModel.firstLabelColor = UIColor.white
        droneCalibrationAxesView.displayCurrentAxis(currentAxis: .yaw)
    }

    /// Display the pitch animation.
    func displayPitch() {
        let pitchAnimationImages: [UIImage] = Asset.Drone.Calibration.Pitch.allValues.map { $0.image }
        instructionsView.viewModel.image = UIImage.animatedImage(with: pitchAnimationImages, duration: 2)
        instructionsView.viewModel.firstLabel = L10n.droneCalibrationPitchInstruction
        instructionsView.viewModel.secondLabel = L10n.droneCalibrationInstructionComplement
        droneCalibrationAxesView.displayCurrentAxis(currentAxis: .pitch)
    }

    /// Display the roll animation.
    func displayRoll() {
        let rollAnimationImages: [UIImage] = Asset.Drone.Calibration.Roll.allValues.map { $0.image }
        instructionsView.viewModel.image = UIImage.animatedImage(with: rollAnimationImages, duration: 2)
        instructionsView.viewModel.firstLabel = L10n.droneCalibrationRollInstruction
        instructionsView.viewModel.secondLabel = L10n.droneCalibrationInstructionComplement
        droneCalibrationAxesView.displayCurrentAxis(currentAxis: .roll)
    }

    /// Update UI for the calibration failure.
    func onFailure() {
        instructionsView.viewModel.image = Asset.Drone.Calibration.Yaw.calibrationYaw00001.image
        instructionsView.viewModel.firstLabel = L10n.droneCalibrationFailed
        instructionsView.viewModel.secondLabel = L10n.droneCalibrationFailureInstruction
        instructionsView.viewModel.firstLabelColor = ColorName.redTorch.color
        droneCalibrationAxesView.isHidden = true
        calibrateButton.setTitle(L10n.droneCalibrationRedo.uppercased(), for: .normal)
        calibrateButton.isHidden = false
    }

    /// Update UI for the calibration success.
    func onCalibrationCompleted() {
        instructionsView.viewModel.image = Asset.Drone.Calibration.Yaw.calibrationYaw00001.image
        instructionsView.viewModel.firstLabel = L10n.droneCalibrationReadyToFly
        instructionsView.viewModel.secondLabel = nil
        instructionsView.viewModel.firstLabelColor = ColorName.greenSpring.color
        droneCalibrationAxesView.isHidden = true
        calibrateButton.isHidden = true
        okButton.isHidden = false
    }

    /// Close the view controller.
    func closeCalibrationView() {
        self.viewModel.cancelCalibration()
        self.navigationController?.popViewController(animated: true)
    }
}
