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

/// Class which display device update.
/// It can be a remote or a drone one.
final class DeviceUpdateViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var sendingStepView: UpdateStepView!
    @IBOutlet private weak var downloadingStepView: UpdateStepView!
    @IBOutlet private weak var rebootingStepView: UpdateStepView!
    @IBOutlet private weak var progressView: DeviceImageView!
    @IBOutlet private weak var backButton: UIButton!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var continueButton: UIButton!

    // MARK: - Private Properties
    private weak var coordinator: UpdateCoordinator?
    private var isUpdateFinished: Bool = false
    private var viewModel: DeviceUpdateProtocol?
    private var model: DeviceUpdateModel = .remote
    /// Tells if the current firmware is already downloaded.
    private var isFirmwareAlreadyDownloaded: Bool = false
    private var isOnlyDownload: Bool = false

    // MARK: - Private Enums
    private enum Constants {
        static let progressDuration: TimeInterval = 1.0
        static let twoSteps: Int = 2
        static let threeSteps: Int = 3
        static let rebootDuration: TimeInterval = 90.0
        static let afterRebootProgressValue: Int = 95
        static let maxProgressValue: Int = 100
    }

    // MARK: - Setup
    static func instantiate(coordinator: UpdateCoordinator,
                            deviceUpdateType: DeviceUpdateType) -> DeviceUpdateViewController {
        let viewController = StoryboardScene.DeviceUpdate.deviceUpdate.instantiate()
        viewController.model = deviceUpdateType.model
        viewController.isOnlyDownload = deviceUpdateType.isOnlyDownload
        viewController.isFirmwareAlreadyDownloaded = deviceUpdateType.isFirmwareAlreadyDownloaded
        viewController.coordinator = coordinator

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        // Init view models according to the current device.
        switch model {
        case .remote:
            initRemoteViewModel()
        case .drone:
            // TODO: remove "model" logic to handle only remote update.
            break
        }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(cancelProcess),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.firmwareUpdate,
                             logType: .screen)
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
private extension DeviceUpdateViewController {
    @IBAction func backButtonTouchedUpInside(_ sender: Any) {
        // Can't cancel the process in the final step of the update.
        switch viewModel?.state.value.deviceUpdateStep.value {
        case .rebooting:
            self.presentCancelAlert()
        default:
            back()
        }
    }

    @IBAction func stateButtonTouchedUpInside(_ sender: Any) {
        if isUpdateFinished {
            coordinator?.dismissDeviceUpdate()
        } else {
            progressView.resetProgress()
            viewModel?.cancelUpdateProcess()
            viewModel?.startUpdateProcess()
        }
    }
}

// MARK: - Private Funcs
/// Common private extension.
private extension DeviceUpdateViewController {
    /// Init the view.
    func initView() {
        titleLabel.text = model.title
        backButton.setTitle(L10n.cancel, for: .normal)
        downloadingStepView.model = UpdateStepModel(state: .todo, title: L10n.remoteUpdateDownloadStep)
        sendingStepView.model = UpdateStepModel(state: .todo,
                                                title: model.sendingStep)
        rebootingStepView.model = UpdateStepModel(state: .todo, title: L10n.remoteUpdateRebootStep)
        progressView.updateDeviceImage(model: model)
        continueButton.cornerRadiusedWith(backgroundColor: ColorName.highlightColor.color,
                                          borderColor: .clear,
                                          radius: Style.largeCornerRadius)
    }

    /// Update device update steps.
    ///
    /// - Parameters:
    ///     - step: current step of the update
    func updateStepView(_ step: DeviceUpdateStep) {
        switch step {
        case .downloadStarted:
            downloadingStepView.model.state = .doing
        case .downloadCompleted:
            downloadingStepView?.model.state = .done
            if isOnlyDownload {
                isUpdateFinished = true
                updateButtonView()
            } else {
                // Launch update when download is finish.
                viewModel?.startUpdateProcess()
            }
        case .updateStarted,
             .uploading,
             .processing:
            downloadingStepView?.model.state = .done
            sendingStepView?.model.state = .doing
        case .rebooting:
            downloadingStepView?.model.state = .done
            sendingStepView?.model.state = .done
            rebootingStepView?.model.state = .doing
        case .updateCompleted:
            rebootingStepView?.model.state = .done
            isUpdateFinished = true
            updateButtonView()
        default:
            break
        }
    }

    /// Update device progress view
    /// according to current progress value and current step of the process.
    ///
    /// - Parameters:
    ///     - step: current step of the update
    ///     - progress: current progress value
    func updateProgressView(step: DeviceUpdateStep?, progress: Int?) {
        switch step {
        case .downloadStarted:
            updateProgress(progress: progress)
        case .downloadCompleted:
            if isOnlyDownload {
                progressView.lockCompleteProgress(Constants.maxProgressValue, duration: Constants.progressDuration)
            } else {
                updateProgress(progress: progress)
            }
        case .updateStarted,
             .uploading,
             .processing:
            updateProgress(progress: progress)
        case .rebooting:
            progressView.lockCompleteProgress(Constants.afterRebootProgressValue, duration: Constants.rebootDuration)
        case .updateCompleted:
            progressView.lockCompleteProgress(Constants.maxProgressValue, duration: Constants.progressDuration)
        default:
            break
        }
    }

    /// Observes errors during the update process.
    ///
    /// - Parameters:
    ///     - event: event during the update
    func listenErrorEvents(_ event: DeviceUpdateEvent?) {
        switch event {
        case .downloadFailed, .updateFailed:
            isUpdateFinished = false
            viewModel?.cancelUpdateProcess()
            updateButtonView()
            if event == .downloadFailed {
                downloadingStepView?.model.state = .error
            } else {
                sendingStepView?.model.state = .error
            }
        default:
            break
        }
    }

    /// Manage update progress.
    ///
    /// - Parameters:
    ///     - progress: current progress
    func updateProgress(progress: Int?) {
        let progress = progress ?? 0
        var currentProgress: Int = 0
        if isFirmwareAlreadyDownloaded {
            currentProgress = progress/Constants.twoSteps
        } else {
            if isOnlyDownload {
                currentProgress = progress
            } else if viewModel?.state.value.deviceUpdateStep.value == .downloadStarted {
                currentProgress = progress/Constants.threeSteps
            } else {
                currentProgress = (progress + Constants.maxProgressValue)/Constants.threeSteps
            }
        }
        progressView.setProgress(currentProgress, animationDuration: Constants.progressDuration)
    }

    /// Updates button view.
    func updateButtonView() {
        continueButton.setTitle(isUpdateFinished
                                    ? L10n.commonContinue
                                    : L10n.commonRetry,
                                for: .normal)
        continueButton.setTitleColor(isUpdateFinished ? .white : ColorName.defaultTextColor.color, for: .normal)
        continueButton.cornerRadiusedWith(backgroundColor: isUpdateFinished ? ColorName.highlightColor.color : ColorName.whiteAlbescent.color,
                                          borderColor: .clear,
                                          radius: Style.largeCornerRadius)
        continueButton.isHidden = false
    }

    /// Presents an alert when internet is not available.
    func showConnectionUnreachableAlert() {
        let validateAction = AlertAction(title: L10n.commonRetry, actionHandler: { [weak self] in
            self?.progressView.resetProgress()
            self?.viewModel?.startNetworkReachability()
            self?.viewModel?.startUpdateProcess()
        })
        let cancelAction = AlertAction(title: L10n.cancel, actionHandler: { [weak self] in
            self?.coordinator?.dismissDeviceUpdate()
        })

        self.showAlert(title: L10n.deviceUpdateConnectionInterruptedTitle,
                       message: L10n.deviceUpdateConnectionInterruptedDescription,
                       cancelAction: cancelAction,
                       validateAction: validateAction)
    }

    /// Comes back to previous screen and cancel the update.
    func back() {
        progressView.resetProgress()
        viewModel?.cancelUpdateProcess()
        switch model {
        case .drone:
            coordinator?.dismissDeviceUpdate()
        case .remote:
            coordinator?.back()
        }
    }

    /// Init the ViewModel for remote update.
    func initRemoteViewModel() {
        viewModel = RemoteUpdateViewModel()
        viewModel?.state.valueChanged = { [weak self] state in
            self?.updateDeviceUpdateState(state)
        }
        viewModel?.state.value.deviceUpdateStep.valueChanged = { [weak self] step in
            self?.updateStepView(step)
        }

        // Check if we can start the update.
        if viewModel?.canStartUpdate() == true {
            viewModel?.startUpdateProcess()
            subtitleLabel.text = L10n.remoteUpdateDescription
            // In case of download only.
            if isOnlyDownload {
                progressView.displayDownloadOnly()
                sendingStepView.isHidden = true
                rebootingStepView.isHidden = true
            }
        } else {
            coordinator?.dismissDeviceUpdate()
        }
    }

    /// Updates current update state.
    ///
    /// - Parameters:
    ///     - state: state of the update
    func updateDeviceUpdateState(_ state: DeviceUpdateState) {
        if !isFirmwareAlreadyDownloaded,
           state.isNetworkReachable == false {
            // Display connection error alerts.
            showConnectionUnreachableAlert()
        }

        updateProgressView(step: state.deviceUpdateStep.value,
                           progress: state.currentProgress)
        listenErrorEvents(state.deviceUpdateEvent)
    }

    /// Shows an alert view when user tries to quit remote update during rebooting.
    func presentCancelAlert() {
        let validateAction = AlertAction(
            title: L10n.firmwareMissionUpdateQuitInstallationCancelAction,
            actionHandler: {
                self.coordinator?.dismissDeviceUpdate()
            })
        let cancelAction = AlertAction(title: L10n.firmwareAndMissionQuitRebootValidateAction,
                                       actionHandler: nil)

        let alert = AlertViewController.instantiate(
            title: L10n.firmwareAndMissionQuitRebootTitle,
            message: L10n.remoteUpdateRebootingError,
            cancelAction: cancelAction,
            validateAction: validateAction)
        present(alert, animated: true, completion: nil)
    }

    /// Cancel current update process and leave screen.
    @objc func cancelProcess() {
        guard viewModel?.state.value.deviceUpdateStep.value.canCancelProcess == true else {
            return
        }

        viewModel?.cancelUpdateProcess()
        coordinator?.dismissDeviceUpdate()
    }
}
