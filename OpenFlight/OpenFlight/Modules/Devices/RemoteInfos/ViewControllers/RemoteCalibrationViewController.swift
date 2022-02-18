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

import UIKit

/// Class which manages remote calibration.
final class RemoteCalibrationViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var axesView: RemoteCalibrationAxesView!
    @IBOutlet private weak var calibrationButton: ActionButton!
    @IBOutlet private weak var okButton: ActionButton!
    @IBOutlet private weak var remoteImageView: UIImageView!

    // MARK: - Private Properties
    private weak var coordinator: Coordinator?
    private let remoteCalibrationViewModel = RemoteCalibrationViewModel()

    // MARK: - Private Enums
    private enum Constants {
        static let animationDuration: TimeInterval = 3.0
    }

    // MARK: - Setup
    static func instantiate(coordinator: Coordinator) -> RemoteCalibrationViewController {
        let viewController = StoryboardScene.RemoteCalibration.initialScene.instantiate()
        viewController.coordinator = coordinator
        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        initViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        LogEvent.log(.screen(LogEvent.Screen.remoteCalibration))
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension RemoteCalibrationViewController {
    @IBAction func calibrationButtonTouchedUpInside(_ sender: Any) {
        LogEvent.log(.button(item: LogEvent.LogKeyRemoteInfosButton.remoteCalibration.name,
                             value: remoteCalibrationViewModel.state.value.calibrationState?.description ?? ""))
        calibrationButton.isHidden = true
        calibrationButton.isUserInteractionEnabled = false
        axesView.isHidden = false
        // Starts an animation on the remote image. It will show the user how to calibrate the device.
        let animationImages = Asset.Remote.Calibration.allValues.compactMap { $0.image }
        remoteImageView.image = UIImage.animatedImage(with: animationImages, duration: Constants.animationDuration)
        remoteCalibrationViewModel.startCalibration()
    }

    @IBAction func okButtonTouchedUpInside(_ sender: Any) {
        LogEvent.log(.simpleButton(LogEvent.LogKeyRemoteInfosButton.okRemoteCalibration.name))
        closeCalibration()
    }

    @IBAction func backButtonTouchedUpInside(_ sender: Any) {
        LogEvent.log(.simpleButton(LogEvent.LogKeyCommonButton.back))
        closeCalibration()
    }
}

// MARK: - Private Funcs
private extension RemoteCalibrationViewController {
    /// Init the view.
    func initView() {
        titleLabel.text = L10n.remoteCalibrationTitle
        titleLabel.font = FontStyle.title.font(isRegularSizeClass)
        descriptionLabel.text = L10n.remoteCalibrationDescription
        descriptionLabel.font = FontStyle.readingText.font(isRegularSizeClass)
        descriptionLabel.isHidden = true
        okButton.setup(title: L10n.remoteCalibrationReadyToFly, style: .validate)
        calibrationButton.setup(title: L10n.remoteCalibrationCalibrate, style: .validate)
    }

    /// Inits the view model.
    func initViewModel() {
        remoteCalibrationViewModel.state.valueChanged = { [weak self] state in
            switch state.calibrationState {
            case .started:
                self?.updateProgress(state)
                self?.descriptionLabel.isHidden = false
            case .finished:
                self?.calibrationCompleted()
                self?.descriptionLabel.isHidden = true
            case .cancelled:
                self?.closeCalibration()
            default:
                break
            }
        }
    }

    /// Update progress for each axes.
    /// - Parameters:
    ///     - state: calibration state
    func updateProgress(_ state: RemoteCalibrationState) {
        axesView?.updateYawProgress(yaw: state.yawValue)
        axesView?.updateRollProgress(roll: state.rollValue)
        axesView?.updatePitchProgress(pitch: state.pitchValue)
    }

    /// Called when calibration is completed.
    func calibrationCompleted() {
        axesView.isHidden = true
        okButton.isHidden = false
        remoteImageView.image = Asset.Remote.Calibration.icRemoteCalibration16.image
        remoteCalibrationViewModel.cancelCalibration()
        descriptionLabel.text = L10n.commonDone
    }

    ///  Cancel the calibration and close the view.
    func closeCalibration() {
        remoteCalibrationViewModel.cancelCalibration()
        coordinator?.back()
    }
}
