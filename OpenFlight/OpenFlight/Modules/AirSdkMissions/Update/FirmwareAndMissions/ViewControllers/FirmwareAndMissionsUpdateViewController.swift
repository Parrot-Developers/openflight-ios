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
import GroundSdk

/// The controller that manages the updating of the firmware and the missions.
final class FirmwareAndMissionsUpdateViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var progressView: NormalizedCircleProgressView!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var cancelButton: InsetHitAreaButton!
    @IBOutlet private weak var reportView: UpdatingSuccessHeader!
    @IBOutlet private weak var continueView: UpdatingDoneFooter!

    // MARK: - Private Properties
    private weak var coordinator: DroneFirmwaresCoordinator?
    private var dataSource = FirmwareAndMissionsUpdatingDataSource(manualRebootState: .waiting)
    private var droneStateViewModel = DroneStateViewModel()
    private var globalUpdateState = GlobalUpdateState.initial
    private var missionUpdateOngoing = false
    private var isUpdateCancelledAlertShown = false

    private let missionsUpdaterManager = AirSdkMissionsUpdaterManager.shared

    private let firmwareUpdaterManager = FirmwareUpdaterManager.shared
    private var firmwareUpdateListener: FirmwareUpdaterListener?

    // MARK: - Private Enums
    enum Constants {
        static let minProgress: Float = 0.0
        static let tableViewHeight: CGFloat = 32.0
        static let firmwareProcessingDuration: TimeInterval = 40.0
        static let firmwareRebootDuration: TimeInterval = 110.0
        static let missionRebootDuration: TimeInterval = 35.0
    }

    enum GlobalUpdateState {
        case initial
        case downloadingFirmware
        case uploadingFirmware
        case processingFirmware
        case waitingForRebootAfterFirmwareUpdate
        case uploadingMissions
        case waitingForRebootAfterMissionsUpdate
        case finished

        /// Returns true if operation can be cancelled.
        var isCancellable: Bool {
            switch self {
            case .downloadingFirmware,
                 .uploadingFirmware,
                 .uploadingMissions:
                return true
            default:
                return false
            }
        }
    }

    // MARK: - Setup
    static func instantiate(coordinator: DroneFirmwaresCoordinator) -> FirmwareAndMissionsUpdateViewController {
        let viewController = StoryboardScene.FirmwareAndMissionsUpdate.initialScene.instantiate()
        viewController.coordinator = coordinator
        return viewController
    }

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
        firmwareUpdaterManager.unregister(firmwareUpdateListener)
        missionsUpdaterManager.unregisterGlobalListener()
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        ULog.d(.missionUpdateTag, "Start firmware and mission update - legacy: \(firmwareUpdaterManager.legacyUpdate)")

        initUI()
        startProcesses()
        if firmwareUpdaterManager.legacyUpdate {
            listenToDroneReconnection()
        }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
}

// MARK: - UITableViewDataSource
extension FirmwareAndMissionsUpdateViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return dataSource.elements.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as AirSdkMissionUpdatingTableViewCell
        cell.setup(with: dataSource.elements[indexPath.row])

        return cell
    }
}

// MARK: - UITableViewDelegate
extension FirmwareAndMissionsUpdateViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.tableViewHeight
    }
}

// MARK: - UpdatingDoneFooterDelegate
extension FirmwareAndMissionsUpdateViewController: UpdatingDoneFooterDelegate {
    func quitProcesses() {
        quitProcesses(closeFirmwareList: true)
    }
}

// MARK: - Actions
private extension FirmwareAndMissionsUpdateViewController {
    @IBAction func cancelButtonTouchedUpInside(_ sender: Any) {
        showCancelAlert()
    }
}

// MARK: - Private Funcs
private extension FirmwareAndMissionsUpdateViewController {
    /// Starts the update processes.
    func startProcesses() {
        listenToFirmwareUpdateManager()
        firmwareUpdaterManager.startFirmwareProcesses(reboot: false)
    }

    /// Listens to the Firmware Update Manager.
    func listenToFirmwareUpdateManager() {
        firmwareUpdateListener = firmwareUpdaterManager
            .register(firmwareToUpdateCallback: { [weak self] firmwareGlobalUpdatingState in
                self?.handleFirmwareProcesses(firmwareGlobalUpdatingState: firmwareGlobalUpdatingState)
            })
    }

    /// Handles firmware update processes callback from the manager.
    ///
    /// - Parameters:
    ///    - firmwareGlobalUpdatingState: The gobal state of the processes.
    func handleFirmwareProcesses(firmwareGlobalUpdatingState: FirmwareGlobalUpdatingState) {
        switch firmwareGlobalUpdatingState {
        case .notInitialized,
             .ongoing:
            break
        case .downloading:
            // Reload tableView only one time while downloading to avoid restarting little progress animation
            if globalUpdateState == .initial {
                globalUpdateState = .downloadingFirmware
                reloadUI()
            } else {
                updateProgress()
            }
        case .uploading:
            // Reload tableView only one time while uploading to avoid restarting little progress animation
            if globalUpdateState == .initial || globalUpdateState == .downloadingFirmware {
                globalUpdateState = .uploadingFirmware
                reloadUI()
            } else {
                updateProgress()
            }
        case .processing:
            if globalUpdateState == .uploadingFirmware {
                globalUpdateState = .processingFirmware
                reloadUI(duration: firmwareUpdaterManager.legacyUpdate ? nil : Constants.firmwareProcessingDuration)
                cancelButton.isHidden = true
            }
        case .waitingForReboot:
            if globalUpdateState == .processingFirmware {
                if firmwareUpdaterManager.legacyUpdate {
                    // We need to reboot now
                    globalUpdateState = .waitingForRebootAfterFirmwareUpdate
                    missionsUpdaterManager.triggerManualReboot()
                    // After the reboot, a connection with the drone must be established to finish the processes.
                    reloadUI(duration: Constants.firmwareRebootDuration)
                } else {
                    // Reboot will be triggered after mission upload
                    globalUpdateState = .uploadingMissions
                    reloadUI()
                    startMissionsProcesses()
                }
            }
        case .success:
            if firmwareUpdaterManager.legacyUpdate {
                if globalUpdateState == .waitingForRebootAfterFirmwareUpdate {
                    // After the reboot and the new connection of the drone, this instruction should be triggered.
                    globalUpdateState = .uploadingMissions
                    reloadUI()
                    startMissionsProcesses()
                }
            } else if globalUpdateState == .waitingForRebootAfterMissionsUpdate {
                globalUpdateState = .finished
                reloadUI(finalRebootState: .succeeded)
                displayFinalUI()
            }
        case .error:
            if globalUpdateState == .uploadingFirmware
                && droneStateViewModel.state.value.connectionState != .connected {
                showUpdateCancelledAlert()
            }

            if globalUpdateState == .downloadingFirmware
                || globalUpdateState == .uploadingFirmware
                || globalUpdateState == .processingFirmware
                || globalUpdateState == .waitingForRebootAfterFirmwareUpdate {
                // This instruction may be triggered during the process or after the new connection of the drone
                // following a reboot.
                globalUpdateState = .finished
                reloadUI()
                displayErrorUI()
            }
        }
    }

    /// Starts missions update processes.
    func startMissionsProcesses() {
        listenToMissionsUpdaterManager()
        missionsUpdaterManager.startMissionsUpdateProcess(postpone: true)
    }

    /// Listens to missions updater.
    func listenToMissionsUpdaterManager() {
        missionsUpdaterManager
            .registerGlobalListener(allMissionToUpdateCallback: { [weak self] (missionsGlobalUpdatingState) in
                self?.handleMissionsProcesses(missionsGlobalUpdatingState: missionsGlobalUpdatingState)
            })
    }

    /// Handles missions update processes callback from the manager.
    ///
    /// - Parameters:
    ///    - missionsGlobalUpdatingState: The gobal state of the processes.
    func handleMissionsProcesses(missionsGlobalUpdatingState: AirSdkMissionsGlobalUpdatingState) {
        guard globalUpdateState == .uploadingMissions else {
            return
        }

        switch missionsGlobalUpdatingState {
        case .ongoing:
            missionUpdateOngoing = true
            reloadUI()
        case .uploading:
            // Reload tableView only one time while uploading to avoid restarting little progress animation
            if missionUpdateOngoing {
                missionUpdateOngoing = false
                reloadUI()
            } else {
                updateProgress()
            }

            if droneStateViewModel.state.value.connectionState != .connected {
                showUpdateCancelledAlert()
            }
        case .done:
            if firmwareUpdaterManager.legacyUpdate {
                if missionsUpdaterManager.missionsUpdateProcessNeedAReboot() {
                    globalUpdateState = .waitingForRebootAfterMissionsUpdate
                    missionsUpdaterManager.triggerManualReboot()
                    reloadUI(finalRebootState: .ongoing, duration: Constants.missionRebootDuration)
                } else {
                    globalUpdateState = .finished
                    reloadUI(finalRebootState: .failed)
                    displayFinalUI()
                }
            } else {
                globalUpdateState = .waitingForRebootAfterMissionsUpdate
                missionsUpdaterManager.triggerManualReboot()
                reloadUI(finalRebootState: .ongoing, duration: Constants.firmwareRebootDuration)
            }
        }
    }

    /// This is the last step of the processes.
    func listenToDroneReconnection() {
        droneStateViewModel.state.valueChanged = { [weak self] state in
            // If drone reconnects after firmware update, nothing is done here because func finalizeFirmwareProcesses()
            // is expected to be called.
            guard let strongSelf = self,
                  strongSelf.globalUpdateState == .waitingForRebootAfterMissionsUpdate,
                  state.connectionState == .connected else {
                return
            }

            ULog.d(.missionUpdateTag, "Firmware and Missions Update drone reconnected")
            strongSelf.globalUpdateState = .finished
            strongSelf.reloadUI(finalRebootState: .succeeded)
            strongSelf.displayFinalUI()
        }
    }

    /// Cancel operation in progress and leave screen.
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
        guard globalUpdateState.isCancellable else { return false }

        let cancelSucceeded = FirmwareAndMissionsInteractor.shared.cancelAllUpdates(removeData: false)
        self.cancelButton.isHidden = cancelSucceeded
        return cancelSucceeded
    }

    /// Quits the updating processes.
    ///
    /// - Parameter closeFirmwareList: `true` to close the firmware list as well
    func quitProcesses(closeFirmwareList: Bool) {
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
private extension FirmwareAndMissionsUpdateViewController {
    /// Inits the UI.
    func initUI() {
        titleLabel.text = L10n.firmwareMissionUpdateDroneUpdate
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
    ///
    /// - Parameters:
    ///   - finalRebootState: the final reboot state of the process
    ///   - duration: the duration of the progress animation, or `nil` to disable animation
    func reloadUI(finalRebootState: FirmwareAndMissionsManualRebootingState = .waiting, duration: TimeInterval? = nil) {
        dataSource = FirmwareAndMissionsUpdatingDataSource(manualRebootState: finalRebootState)
        if let duration = duration {
            progressView.setFakeProgress(progressEnd: dataSource.currentTotalProgress, duration: duration)
        } else {
            progressView.update(currentProgress: dataSource.currentTotalProgress)
        }
        tableView.reloadData()
    }

    /// Updates the progress view.
    func updateProgress() {
        dataSource = FirmwareAndMissionsUpdatingDataSource(manualRebootState: .waiting)
        progressView.update(currentProgress: dataSource.currentTotalProgress)
    }

    /// Displays final UI.
    func displayFinalUI() {
        if missionsUpdaterManager.missionsUpdateProcessHasError() {
            displayErrorUI()
        } else {
            displaySuccessUI()
        }
    }

    /// Displays success UI.
    func displaySuccessUI() {
        continueView.setup(delegate: self, state: .success)
        reportView.setup(with: .success)
        progressView.setFakeSuccessOrErrorProgress()
        cancelButton.isHidden = true
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
        tableView.register(cellType: AirSdkMissionUpdatingTableViewCell.self)
    }
}
