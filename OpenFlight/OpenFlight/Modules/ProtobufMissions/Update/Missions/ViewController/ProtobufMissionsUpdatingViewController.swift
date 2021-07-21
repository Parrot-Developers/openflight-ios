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

/// The controller that manages the updating of  the missions.
final class ProtobufMissionsUpdatingViewController: UIViewController {
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
    private var dataSource = ProtobufMissionsUpdatingDataSource(manualRebootState: .waiting)
    private var manualRebootStarted: Bool = false
    private var shouldRestartProcesses: Bool = false
    private var processIsFinished: Bool = false
    private var updateOngoing: Bool = false
    private var droneStateViewModel = DroneStateViewModel()
    private let missionsUpdaterManager = ProtobufMissionsUpdaterManager.shared
    private var missionsUpdateListener: ProtobufAllMissionsUpdaterListener?

    // MARK: - Private Enums
    enum Constants {
        static let minProgress: Float = 0.0
        static let tableViewHeight: CGFloat = 50.0
        static let rebootDuration: TimeInterval = 35.0
    }

    // MARK: - Setup
    static func instantiate(coordinator: ProtobufMissionUpdateCoordinator) -> ProtobufMissionsUpdatingViewController {
        let viewController = StoryboardScene.ProtobufMissionsUpdating.initialScene.instantiate()
        viewController.coordinator = coordinator

        return viewController
    }

    // MARK: - Deinit
    deinit {
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
                                               selector: #selector(cancelProcesses),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(restartProcesses),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
}

// MARK: - UITableViewDataSource
extension ProtobufMissionsUpdatingViewController: UITableViewDataSource {
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
extension ProtobufMissionsUpdatingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.tableViewHeight
    }
}

// MARK: - UpdatingDoneFooterDelegate
extension ProtobufMissionsUpdatingViewController: UpdatingDoneFooterDelegate {
    func quitProcesses() {
        RemoteControlGrabManager.shared.enableRemoteControl()
        coordinator?.back()
    }
}

// MARK: - Actions
private extension ProtobufMissionsUpdatingViewController {
    @IBAction func cancelButtonTouchedUpInside(_ sender: Any) {
        if manualRebootStarted == false {
            presentCancelAlertViewController()
        } else {
            presentQuitRebootAlertViewController()
        }
    }
}

// MARK: - Private Funcs
private extension ProtobufMissionsUpdatingViewController {
    /// Starts the update processes.
    func startProcesses() {
        RemoteControlGrabManager.shared.disableRemoteControl()
        missionsUpdaterManager.startMissionsUpdateProcess()
    }

    /// Listens to missions updater.
    func listenToMissionsUpdaterManager() {
        missionsUpdaterManager
            .registerGlobalListener(allMissionToUpdateCallback: { [weak self] (missionsGlobalUpdatingState) in
                guard let strongSelf = self,
                      strongSelf.droneStateViewModel.state.value.isConnected() else {
                    return
                }

                strongSelf.updateMissionsProcesses(missionsGlobalUpdatingState: missionsGlobalUpdatingState)
            })
    }

    /// Finalize Missions processes.
    ///
    /// - Parameters:
    ///    - missionsGlobalUpdatingState: The gobal state of the processes
    func updateMissionsProcesses(missionsGlobalUpdatingState: ProtobufMissionsGlobalUpdatingState) {
        switch missionsGlobalUpdatingState {
        case .ongoing:
            updateOngoing = true
            return
        case .uploading:
            dataSource = ProtobufMissionsUpdatingDataSource(manualRebootState: .waiting)
            progressView.update(currentProgress: dataSource.currentTotalProgress)
            // Reload tableView only one time while uploading to avoid restarting little progress animation
            if updateOngoing {
                updateOngoing = false
                tableView.reloadData()
            }
        case .done:
            if !missionsUpdaterManager.missionsUpdateProcessNeedAReboot() && !processIsFinished {
                dataSource = ProtobufMissionsUpdatingDataSource(manualRebootState: .failed)
                tableView.reloadData()
                ULog.d(.missionUpdateTag, "Missions Updates need no reboot")
                displayFinalUI()
            } else if missionsUpdaterManager.missionsUpdateProcessNeedAReboot() && !manualRebootStarted {
                triggerManualReboot()
            }
        }
    }

    /// Triggers manual reboot
    func triggerManualReboot() {
        cancelButton.isHidden = false
        missionsUpdaterManager.triggerManualReboot()
        dataSource = ProtobufMissionsUpdatingDataSource(manualRebootState: .ongoing)
        tableView.reloadData()
        progressView.setFakeRebootProgress(duration: Constants.rebootDuration)
        manualRebootStarted = true
    }

    /// This is the last step of the processes.
    func listenToDroneReconnection() {
        droneStateViewModel.state.valueChanged = { [weak self] state in
            guard let strongSelf = self,
                  state.connectionState == .connected,
                  !strongSelf.processIsFinished
            else {
                return
            }

            if strongSelf.shouldRestartProcesses {
                strongSelf.restartProcesses()
            } else if strongSelf.manualRebootStarted {
                ULog.d(.missionUpdateTag, "Missions Update drone reconnected")
                strongSelf.dataSource = ProtobufMissionsUpdatingDataSource(manualRebootState: .succeeded)
                strongSelf.tableView.reloadData()
                strongSelf.displayFinalUI()
            }
        }
    }

    /// Cancel operation in progress.
    @objc func cancelProcesses() {
        guard !manualRebootStarted else { return }

        let cancelSucceeded = FirmwareAndMissionsInteractor.shared.cancelAllUpdates(removeData: false)
        self.cancelButton.isHidden = cancelSucceeded
    }

    /// Restart operation in progress.
    @objc func restartProcesses() {
        guard !manualRebootStarted else { return }

        resetUI()
        // Drone must be connected to restart mission update.
        guard droneStateViewModel.state.value.isConnected() else {
            shouldRestartProcesses = true
            return
        }

        shouldRestartProcesses = false
        startProcesses()
    }

    /// Shows an alert view when user tries to cancel update.
    func presentCancelAlertViewController() {
        let validateAction = AlertAction(
            title: L10n.firmwareMissionUpdateQuitInstallationValidateAction,
            actionHandler: { [weak self] in
                self?.cancelProcesses()
                self?.quitProcesses()
            })
        let cancelAction = AlertAction(title: L10n.cancel, actionHandler: nil)

        let alert = AlertViewController.instantiate(
            title: L10n.firmwareMissionUpdateQuitInstallationTitle,
            message: L10n.firmwareMissionUpdateQuitInstallationDroneMessage,
            cancelAction: cancelAction,
            validateAction: validateAction)
        present(alert, animated: true, completion: nil)
    }

    /// Shows an alert view when user tries to quit drone reboot.
    func presentQuitRebootAlertViewController() {
        let validateAction = AlertAction(
            title: L10n.firmwareAndMissionQuitRebootValidateAction,
            actionHandler: {
                self.quitProcesses()
            })
        let cancelAction = AlertAction(title: L10n.firmwareMissionUpdateQuitInstallationCancelAction,
                                       actionHandler: nil)

        let alert = AlertViewController.instantiate(
            title: L10n.firmwareAndMissionQuitRebootTitle,
            message: L10n.firmwareAndMissionQuitRebootDroneMessage,
            cancelAction: cancelAction,
            validateAction: validateAction)
        present(alert, animated: true, completion: nil)
    }
}

// MARK: - UI Utils
private extension ProtobufMissionsUpdatingViewController {
    /// Inits the UI.
    func initUI() {
        titleLabel.text = L10n.firmwareMissionUpdateFirmwareUpdate
        subtitleLabel.textColor = ColorName.white50.color
        subtitleLabel.text = dataSource.subtitle
        view.backgroundColor = ColorName.greyShark.color
        cancelButton.setTitle(L10n.cancel, for: .normal)
        cancelButton.makeup(with: .large)
        cancelButton.cornerRadiusedWith(backgroundColor: ColorName.greyShark.color,
                                        borderColor: .clear,
                                        radius: 0.0,
                                        borderWidth: 0.0)
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
        tableView.makeUp(backgroundColor: ColorName.greyShark.color)
        tableView.tableHeaderView = UIView()
        tableView.separatorColor = .clear
        tableView.register(cellType: ProtobufMissionUpdatingTableViewCell.self)
    }
}
