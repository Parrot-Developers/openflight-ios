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

/// The controller that manages the downloading and the updating of the firmware.
final class FirmwareUpdatingViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var progressView: FirmwareAndMissionProgressView!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var cancelButton: UIButton!
    @IBOutlet private weak var reportView: UpdatingSuccessHeader!
    @IBOutlet private weak var continueView: UpdatingDoneFooter!

    // MARK: - Private Properties
    private weak var coordinator: ProtobufMissionUpdateCoordinator?

    private let firmwareUpdaterManager = FirmwareUpdaterManager.shared
    private var firmwareUpdateListener: FirmwareUpdaterListener?
    private var dataSource = FirmwareUpdatingDataSource()
    private var globalUpdateState = FirmwareGlobalUpdatingState.notInitialized
    private var updateOngoing: Bool = false
    private var isProcessCancelable: Bool = true
    private var isUpdateCancelledAlertShown: Bool = false
    private var droneStateViewModel = DroneStateViewModel()

    // MARK: - Private Enums
    enum Constants {
        static let minProgress: Float = 0.0
        static let tableViewHeight: CGFloat = 50.0
        static let rebootDuration: TimeInterval = 120.0
    }

    // MARK: - Setup
    static func instantiate(coordinator: ProtobufMissionUpdateCoordinator) -> FirmwareUpdatingViewController {
        let viewController = StoryboardScene.FirmwareUpdatingViewController.initialScene.instantiate()
        viewController.coordinator = coordinator

        return viewController
    }

    // MARK: - Deinit
    deinit {
        firmwareUpdaterManager.unregister(firmwareUpdateListener)
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initUI()
        listenToFirmwareUpdateManager()
        startProcesses()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
}

// MARK: - UITableViewDataSource
extension FirmwareUpdatingViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return dataSource.elements.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as ProtobufMissionUpdatingTableViewCell
        cell.setup(with: dataSource.elements[indexPath.row])

        return cell
    }
}

// MARK: - UITableViewDelegate
extension FirmwareUpdatingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.tableViewHeight
    }
}

// MARK: - UpdatingDoneFooterDelegate
extension FirmwareUpdatingViewController: UpdatingDoneFooterDelegate {
    func quitProcesses() {
        quitProcesses(closeFirmwareList: false)
    }
}

// MARK: - Actions
private extension FirmwareUpdatingViewController {
    @IBAction func cancelButtonTouchedUpInside(_ sender: Any) {
        showCancelAlert()
    }
}

// MARK: - Private Funcs
private extension FirmwareUpdatingViewController {
    /// Listens to the Firmware Update Manager.
    func listenToFirmwareUpdateManager() {
        firmwareUpdateListener = firmwareUpdaterManager
            .register(firmwareToUpdateCallback: { [weak self] ( firmwareGlobalUpdatingState) in
                self?.handleFirmwareProcesses(firmwareGlobalUpdatingState: firmwareGlobalUpdatingState)
            })
    }

    /// Starts the download and update firmware processes.
    func startProcesses() {
        RemoteControlGrabManager.shared.disableRemoteControl()
        firmwareUpdaterManager.startFirmwareProcesses()
    }

    /// Handles firmware update processes callback from the manager.
    ///
    /// - Parameters:
    ///    - firmwareGlobalUpdatingState: The gobal state of the processes.
    func handleFirmwareProcesses(firmwareGlobalUpdatingState: FirmwareGlobalUpdatingState) {
        switch firmwareGlobalUpdatingState {
        case .notInitialized:
            break
        case .ongoing:
            updateOngoing = true
        case .downloading,
             .uploading:
            // Reload tableView only one time to avoid restarting little progress animation
            if updateOngoing {
                updateOngoing = false
                reloadUI()
            } else {
                updateProgress()
            }
        case .processing:
            if isProcessCancelable {
                isProcessCancelable = false
                cancelButton.isHidden = true
                reloadUI()
            } else {
                updateProgress()
            }
        case .waitingForReboot:
            // After the reboot, a connection with the drone must be established to finish the processes
            reloadUI()
            waitForReboot()
        case .success:
            // After the reboot and the new connection of the drone, this instruction may be triggered.
            reloadUI()
            displaySuccessUI()
        case .error:
            // This instruction may be triggered during the process or after the new connection of the drone following
            // a reboot.
            reloadUI()
            displayErrorUI()

            if globalUpdateState == .uploading
                && droneStateViewModel.state.value.connectionState != .connected {
                showUpdateCancelledAlert()
            }
        }

        globalUpdateState = firmwareGlobalUpdatingState
    }

    /// Waits for reboot of the drone
    func waitForReboot() {
        cancelButton.isHidden = true
        progressView.setFakeRebootProgress(duration: Constants.rebootDuration)
    }

    /// Called when the app enters background.
    @objc func didEnterBackground() {
        let cancelled = cancelProcesses()
        if cancelled {
            showUpdateCancelledAlert()
        } else {
            quitProcesses(closeFirmwareList: true)
        }
    }

    /// Cancel operation in progress.
    func cancelProcesses() -> Bool {
        guard isProcessCancelable else { return false }

        let cancelSucceeded = FirmwareAndMissionsInteractor.shared.cancelAllUpdates(removeData: false)
        self.cancelButton.isHidden = cancelSucceeded
        return cancelSucceeded
    }

    /// Quits the updating processes.
    ///
    /// - Parameter closeFirmwareList: `true` to close the firmware list as well
    func quitProcesses(closeFirmwareList: Bool) {
        RemoteControlGrabManager.shared.enableRemoteControl()
        if closeFirmwareList {
            coordinator?.quitUpdateProcesses()
        } else {
            coordinator?.back()
        }
    }

    /// Shows an alert view when user tries to cancel update.
    func showCancelAlert() {
        let validateAction = AlertAction(
            title: L10n.firmwareMissionUpdateQuitInstallationValidateAction,
            actionHandler: { [weak self] in
                let cancelled = self?.cancelProcesses()
                if cancelled == true {
                    self?.quitProcesses(closeFirmwareList: true)
                }
            })
        let cancelAction = AlertAction(title: L10n.cancel, actionHandler: nil)
        let alert = AlertViewController.instantiate(
            title: L10n.firmwareMissionUpdateQuitInstallationTitle,
            message: L10n.firmwareMissionUpdateQuitInstallationDroneMessage,
            cancelAction: cancelAction,
            validateAction: validateAction)
        present(alert, animated: true, completion: nil)
    }

    /// Shows an alert view when update has been cancelled while entering background or disconnecting.
    func showUpdateCancelledAlert() {
        guard !isUpdateCancelledAlertShown else {
            return
        }

        isUpdateCancelledAlertShown = true
        let validateAction = AlertAction(
            title: L10n.ok,
            actionHandler: { [weak self] in
                self?.quitProcesses(closeFirmwareList: false)
            })
        let alert = AlertViewController.instantiate(
            title: L10n.firmwareAndMissionUpdateCancelledTitle,
            message: L10n.firmwareAndMissionUpdateCancelledDroneMessage,
            validateAction: validateAction)
        present(alert, animated: true, completion: nil)
    }
}

// MARK: - UI Utils
private extension FirmwareUpdatingViewController {
    /// Inits the UI.
    func initUI() {
        titleLabel.text = L10n.firmwareMissionUpdateFirmwareUpdate
        subtitleLabel.text = dataSource.subtitle
        cancelButton.setTitle(L10n.cancel, for: .normal)
        setupTableView()
        resetUI()
    }

    /// Reset the dynamic UI part.
    func resetUI() {
        progressView.update(currentProgress: Constants.minProgress)
        continueView.setup(delegate: self, state: .waiting)
        reportView.setup(with: .waiting)
        cancelButton.isHidden = false
        tableView.reloadData()
    }

    /// Reloads the whole UI.
    func reloadUI() {
        dataSource = FirmwareUpdatingDataSource()
        progressView.update(currentProgress: dataSource.currentTotalProgress)
        tableView.reloadData()
    }

    /// Updates the progress view.
    func updateProgress() {
        dataSource = FirmwareUpdatingDataSource()
        progressView.update(currentProgress: dataSource.currentTotalProgress)
    }

    /// Displays success UI.
    func displaySuccessUI() {
        continueView.setup(delegate: self, state: .success)
        reportView.setup(with: .success)
        progressView.setFakeSuccessOrErrorProgress()
        cancelButton.isHidden = true
        // Unregister to prevent from issues when app goes in background.
        firmwareUpdaterManager.unregister(firmwareUpdateListener)
        firmwareUpdateListener = nil
    }

    /// Displays error UI.
    func displayErrorUI() {
        continueView.setup(delegate: self, state: .error)
        reportView.setup(with: .error)
        progressView.setFakeSuccessOrErrorProgress()
        cancelButton.isHidden = true
    }

    /// Sets up the table view.
    func setupTableView() {
        tableView.allowsSelection = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableHeaderView = UIView()
        tableView.separatorColor = .clear
        tableView.register(cellType: ProtobufMissionUpdatingTableViewCell.self)
    }
}
