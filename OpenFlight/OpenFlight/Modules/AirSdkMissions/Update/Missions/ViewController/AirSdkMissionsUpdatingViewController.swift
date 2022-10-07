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

/// The controller that manages the updating of  the missions.
final class AirSdkMissionsUpdatingViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var progressView: NormalizedCircleProgressView!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var cancelButton: InsetHitAreaButton!
    @IBOutlet private weak var reportView: UpdatingSuccessHeader!
    @IBOutlet private weak var continueView: UpdatingDoneFooter!

    // MARK: - Private Properties
    private weak var coordinator: DroneFirmwaresCoordinator?
    private var dataSource = AirSdkMissionsUpdatingDataSource(manualRebootState: .waiting)
    private var rebootState: RebootState = .none
    private var processIsFinished: Bool = false
    private var updateOngoing: Bool = false
    private var isUpdateCancelledAlertShown: Bool = false
    private var droneStateViewModel = DroneStateViewModel()
    private let missionsUpdaterManager = AirSdkMissionsUpdaterManager.shared

    // MARK: - Private Enums
    enum Constants {
        static let minProgress: Float = 0.0
        static let tableViewHeight: CGFloat = 50.0
        static let rebootDuration: TimeInterval = 35.0
    }

    enum RebootState {
        case none
        case requested
        case ongoing
    }

    // MARK: - Setup
    static func instantiate(coordinator: DroneFirmwaresCoordinator) -> AirSdkMissionsUpdatingViewController {
        let viewController = StoryboardScene.AirSdkMissionsUpdating.initialScene.instantiate()
        viewController.coordinator = coordinator

        return viewController
    }

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
        missionsUpdaterManager.unregisterGlobalListener()
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initUI()
        listenToMissionsUpdaterManager()
        startProcesses()
        listenToDroneReconnection()

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
extension AirSdkMissionsUpdatingViewController: UITableViewDataSource {
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
extension AirSdkMissionsUpdatingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.tableViewHeight
    }
}

// MARK: - UpdatingDoneFooterDelegate
extension AirSdkMissionsUpdatingViewController: UpdatingDoneFooterDelegate {
    func quitProcesses() {
        quitProcesses(closeFirmwareList: false)
    }
}

// MARK: - Actions
private extension AirSdkMissionsUpdatingViewController {
    @IBAction func cancelButtonTouchedUpInside(_ sender: Any) {
        showCancelAlert()
    }
}

// MARK: - Private Funcs
private extension AirSdkMissionsUpdatingViewController {
    /// Starts the update processes.
    func startProcesses() {
        missionsUpdaterManager.startMissionsUpdateProcess(postpone: false)
    }

    /// Listens to missions updater.
    func listenToMissionsUpdaterManager() {
        missionsUpdaterManager
            .registerGlobalListener(allMissionToUpdateCallback: { [weak self] (missionsGlobalUpdatingState) in
                self?.updateMissionsProcesses(missionsGlobalUpdatingState: missionsGlobalUpdatingState)
            })
    }

    /// Finalize Missions processes.
    ///
    /// - Parameters:
    ///    - missionsGlobalUpdatingState: The gobal state of the processes
    func updateMissionsProcesses(missionsGlobalUpdatingState: AirSdkMissionsGlobalUpdatingState) {
        switch missionsGlobalUpdatingState {
        case .ongoing:
            updateOngoing = true
            return
        case .uploading:
            dataSource = AirSdkMissionsUpdatingDataSource(manualRebootState: .waiting)
            progressView.update(currentProgress: dataSource.currentTotalProgress)
            // Reload tableView only one time while uploading to avoid restarting little progress animation
            if updateOngoing {
                updateOngoing = false
                tableView.reloadData()
            }

            if droneStateViewModel.state.value.connectionState != .connected {
                showUpdateCancelledAlert()
            }
        case .done:
            if !missionsUpdaterManager.missionsUpdateProcessNeedAReboot() && !processIsFinished {
                dataSource = AirSdkMissionsUpdatingDataSource(manualRebootState: .failed)
                tableView.reloadData()
                ULog.d(.missionUpdateTag, "Missions Updates need no reboot")
                displayFinalUI()
            } else if missionsUpdaterManager.missionsUpdateProcessNeedAReboot() && rebootState == .none {
                triggerManualReboot()
            }
        }
    }

    /// Triggers manual reboot
    func triggerManualReboot() {
        cancelButton.isHidden = true
        missionsUpdaterManager.triggerManualReboot()
        dataSource = AirSdkMissionsUpdatingDataSource(manualRebootState: .ongoing)
        tableView.reloadData()
        progressView.setFakeProgress(duration: Constants.rebootDuration)
        rebootState = .requested
    }

    /// This is the last step of the processes.
    func listenToDroneReconnection() {
        droneStateViewModel.state.valueChanged = { [weak self] state in
            guard let strongSelf = self,
                  !strongSelf.processIsFinished
            else {
                return
            }

            switch strongSelf.rebootState {
            case .none:
                break
            case .requested:
                if state.connectionState == .disconnected {
                    strongSelf.rebootState = .ongoing
                }
            case .ongoing:
                if state.connectionState == .connected {
                    ULog.d(.missionUpdateTag, "Missions Update drone reconnected")
                    strongSelf.dataSource = AirSdkMissionsUpdatingDataSource(manualRebootState: .succeeded)
                    strongSelf.tableView.reloadData()
                    strongSelf.displayFinalUI()
                }
            }
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
        guard rebootState == .none else { return false }

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
private extension AirSdkMissionsUpdatingViewController {
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

    /// Displays final UI.
    func displayFinalUI() {
        ULog.d(.missionUpdateTag, "Missions Updates Report screen")
        processIsFinished = true
        if missionsUpdaterManager.missionsUpdateProcessHasError() {
            displayErrorUI()
        } else {
            displaySuccessUI()
        }
    }

    /// Displays success UI.
    func displaySuccessUI() {
        reportView.setup(with: .success)
        continueView.setup(delegate: self, state: .success)
        progressView.setFakeSuccessOrErrorProgress()
        cancelButton.isHidden = true
        // Unregister to prevent from issues when app goes in background.
        missionsUpdaterManager.unregisterGlobalListener()
    }

    /// Displays error UI.
    func displayErrorUI() {
        reportView.setup(with: .error)
        continueView.setup(delegate: self, state: .error)
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
