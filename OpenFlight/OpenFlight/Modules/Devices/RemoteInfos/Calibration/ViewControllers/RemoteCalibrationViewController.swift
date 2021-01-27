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

/// Class which manages remote calibration.
final class RemoteCalibrationViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var axesView: RemoteCalibrationAxesView!
    @IBOutlet private weak var calibrationButton: UIButton!
    @IBOutlet private weak var okButton: UIButton!
    @IBOutlet private weak var remoteImageView: UIImageView!
    @IBOutlet private weak var backgroundView: UIView!

    // MARK: - Private Properties
    private weak var coordinator: Coordinator?
    private var remoteCalibrationViewModel: RemoteCalibrationViewModel?

    // MARK: - Private Enums
    private enum Constants {
        static let animationDuration: TimeInterval = 3.0
    }

    /// Enum which stores messages to log.
    private enum EventLoggerConstants {
        static let screenMessage: String = "RemoteCalibration"
    }

    // MARK: - Setup
    static func instantiate(coordinator: Coordinator) -> RemoteCalibrationViewController {
        let viewController = StoryboardScene.RemoteDetails.remoteCalibrationViewController.instantiate()
        viewController.coordinator = coordinator

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()

        /// Starts observing view model.
        remoteCalibrationViewModel = RemoteCalibrationViewModel(stateDidUpdate: { [weak self] state in
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
        })
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        logScreen(logMessage: EventLoggerConstants.screenMessage)
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
private extension RemoteCalibrationViewController {
    @IBAction func calibrationButtonTouchedUpInside(_ sender: Any) {
        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.remoteCalibration.name,
                             itemName: LogEvent.LogKeyRemoteInfosButton.remoteCalibration.name,
                             newValue: remoteCalibrationViewModel?.state.value.calibrationState?.description,
                             logType: .button)
        calibrationButton.isHidden = true
        calibrationButton.isUserInteractionEnabled = false
        axesView.isHidden = false
        // Starts an animation on the remote image. It will show the user how to calibrate the device.
        let animationImages = Asset.Remote.Calibration.allValues.compactMap { $0.image }
        remoteImageView.image = UIImage.animatedImage(with: animationImages, duration: Constants.animationDuration)
        remoteCalibrationViewModel?.startCalibration()
    }

    @IBAction func okButtonTouchedUpInside(_ sender: Any) {
        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.remoteCalibration.name,
                             itemName: LogEvent.LogKeyRemoteInfosButton.okRemoteCalibration.name,
                             newValue: nil,
                             logType: .button)
        closeCalibration()
    }

    @IBAction func backButtonTouchedUpInside(_ sender: Any) {
        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.remoteCalibration.name,
                             itemName: LogEvent.LogKeyRemoteInfosButton.backRemoteCalibration.name,
                             newValue: nil,
                             logType: .button)
        closeCalibration()
    }
}

// MARK: - Private Funcs
private extension RemoteCalibrationViewController {
    /// Init the view.
    func initView() {
        backgroundView.backgroundColor = UIColor(named: .white10)
        titleLabel.text = L10n.remoteCalibrationTitle
        descriptionLabel.text = L10n.remoteCalibrationDescription
        descriptionLabel.isHidden = true
        okButton.setTitle(L10n.remoteCalibrationReadyToFly, for: .normal)
        calibrationButton.setTitle(L10n.remoteCalibrationCalibrate, for: .normal)
        calibrationButton.cornerRadiusedWith(backgroundColor: UIColor(named: .white20),
                                             borderColor: .clear,
                                             radius: Style.largeCornerRadius)
        okButton.cornerRadiusedWith(backgroundColor: UIColor(named: .white20),
                                    borderColor: .clear,
                                    radius: Style.largeCornerRadius)
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
        remoteImageView.image = Asset.Remote.Calibration.calibrationRemote00001.image
        remoteCalibrationViewModel?.cancelCalibration()
        descriptionLabel.text = L10n.commonDone
    }

    ///  Cancel the calibration and close the view.
    func closeCalibration() {
        remoteCalibrationViewModel?.cancelCalibration()
        coordinator?.back()
    }
}
