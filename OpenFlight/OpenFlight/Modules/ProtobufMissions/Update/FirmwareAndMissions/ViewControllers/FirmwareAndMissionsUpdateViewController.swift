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

/// The controller that manages the updating of the firmware and the missions.
final class FirmwareAndMissionsUpdateViewController: UIViewController {
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
    private var dataSource = FirmwareAndMissionsUpdatingDataSource()
    private var isWaitingForDroneReconnection: Bool = false
    private var droneStateViewModel = DroneStateViewModel()

    private let missionsUpdaterManager = ProtobufMissionsUpdaterManager.shared
    private var missionsUpdateListener: ProtobufAllMissionsUpdaterListener?

    private let firmwareUpdaterManager = FirmwareUpdaterManager.shared
    private var firmwareUpdateListener: FirmwareUpdaterListener?
    private var didStartFirmwareProcess: Bool = false
    private var processesAreFinished: Bool = false

    // MARK: - Private Enums
    enum Constants {
        static let minProgress: Float = 0.0
        static let tableViewHeight: CGFloat = 50.0
        static let rebootDuration: TimeInterval = 60.0
    }

    // MARK: - Setup
    static func instantiate(coordinator: ProtobufMissionUpdateCoordinator) -> FirmwareAndMissionsUpdateViewController {
        let viewController = StoryboardScene.FirmwareAndMissionsUpdate.initialScene.instantiate()
        viewController.coordinator = coordinator
        return viewController
    }

    // MARK: - Deinit
    deinit {
        firmwareUpdaterManager.unregister(firmwareUpdateListener)
        missionsUpdaterManager.unregisterGlobalListener()
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initUI()
        startProcesses()
        listenToDroneReconnection()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
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
        let cell = tableView.dequeueReusableCell(for: indexPath) as ProtobufMissionUpdatingTableViewCell
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
        RemoteControlGrabManager.shared.enableRemoteControl()
        coordinator?.back()
    }
}

// MARK: - Actions
private extension FirmwareAndMissionsUpdateViewController {
    @IBAction func cancelButtonTouchedUpInside(_ sender: Any) {
        if isWaitingForDroneReconnection == false {
            presentCancelAlertViewController()
        } else {
            quitProcesses()
        }
    }
}

// MARK: - Private Funcs
private extension FirmwareAndMissionsUpdateViewController {
    /// Starts the update processes.
    func startProcesses() {
        RemoteControlGrabManager.shared.disableRemoteControl()
        listenToMissionsUpdaterManager()
        missionsUpdaterManager.startMissionsUpdateProcess()
    }

    /// Listens to missions updater.
    func listenToMissionsUpdaterManager() {
        missionsUpdaterManager
            .registerGlobalListener(allMissionToUpdateCallback: { [weak self] (missionsGlobalUpdatingState) in
                self?.reloadUI()
                self?.finalizeMissionsProcesses(missionsGlobalUpdatingState: missionsGlobalUpdatingState)
            })
    }

    /// Finalize Missions processes.
    ///
    /// - Parameters:
    ///    - missionsGlobalUpdatingState: The gobal state of the processes.
    func finalizeMissionsProcesses(missionsGlobalUpdatingState: ProtobufMissionsGlobalUpdatingState) {
        switch missionsGlobalUpdatingState {
        case .processing:
            break
        case .done:
            if !didStartFirmwareProcess {
                didStartFirmwareProcess = true
                listenToFirmwareUpdateManager()
                firmwareUpdaterManager.startFirmwareProcesses()
            }
        }
    }

    /// Listens to the Firmware Update Manager .
    func listenToFirmwareUpdateManager() {
        firmwareUpdateListener = firmwareUpdaterManager
            .register(firmwareToUpdateCallback: { [weak self] ( firmwareGlobalUpdatingState) in
                self?.reloadUI()
                self?.finalizeFirmwareProcesses(firmwareGlobalUpdatingState: firmwareGlobalUpdatingState)
            })
    }

    /// Finalize Firmware processes.
    ///
    /// - Parameters:
    ///    - firmwareGlobalUpdatingState: The gobal state of the processes.
    func finalizeFirmwareProcesses(firmwareGlobalUpdatingState: FirmwareGlobalUpdatingState) {
        switch firmwareGlobalUpdatingState {
        case .notInitialized,
             .ongoing:
            break
        case .waitingForReboot:
            // After the firmware automatic reboot, a connection with the drone must be established to finish the processes
            waitForReboot()
        case .success:
            // After the firmware automatic reboot and the new connection of the drone, this instruction may be triggered.
            displayFinalUI()
        case .error:
            // This instruction may be triggered during the process or after the new connection of the drone following an automatic firmware reboot.

            cancelButton.isHidden = true
            guard missionsUpdaterManager.missionsUpdateProcessNeedAReboot() else {
                displayErrorUI()
                return
            }

            // Just a secure test, as after a manual reboot, maybe the firmware "Updater" send again a message of error so this test avoids infinite loop.
            guard !processesAreFinished else { return }

            // The firmware process failed, however some missions have been updated and need a reboot
            // TODO: Manually display the reboot cell activity.
            missionsUpdaterManager.triggerManualReboot()
            progressView.setFakeRebootProgress(duration: Constants.rebootDuration)
        }
    }

    /// This is the last step of the processes.
    func listenToDroneReconnection() {
        droneStateViewModel.state.valueChanged = { [weak self] state in
            guard let strongSelf = self,
                  strongSelf.isWaitingForDroneReconnection,
                  state.connectionState == .connected,
                  !strongSelf.processesAreFinished
            else {
                return
            }

            strongSelf.isWaitingForDroneReconnection = false
            ULog.d(.missionUpdateTag, "Firmware and Missions Update drone reconnected")
            strongSelf.displayFinalUI()
        }
    }

    /// Shows an alert view.
    func presentCancelAlertViewController() {
        let validateAction = AlertAction(
            title: L10n.firmwareMissionUpdateAlertQuitInstallationValidateAction,
            actionHandler: {
                let cancelsSucceed = FirmwareAndMissionsInteractor.shared.cancelAllUpdates(removeData: false)
                self.cancelButton.isHidden = cancelsSucceed
            })
        let cancelAction = AlertAction(title: L10n.cancel, actionHandler: nil)

        let alert = AlertViewController.instantiate(
            title: L10n.firmwareMissionUpdateAlertQuitInstallationTitle,
            message: L10n.firmwareMissionUpdateAlertQuitInstallationMessage,
            cancelAction: cancelAction,
            validateAction: validateAction)
        present(alert, animated: true, completion: nil)
    }
}

// MARK: - UI Utils
private extension FirmwareAndMissionsUpdateViewController {
    /// Inits the UI.
    func initUI() {
        titleLabel.text = L10n.firmwareMissionUpdateFirmwareUpdate
        subtitleLabel.textColor = ColorName.white50.color
        subtitleLabel.text = dataSource.subtitle
        view.backgroundColor = ColorName.greyShark.color
        cancelButton.setTitle(L10n.cancel, for: .normal)
        cancelButton.tintColor = ColorName.white.color
        cancelButton.cornerRadiusedWith(backgroundColor: ColorName.greyShark.color,
                                        borderColor: .clear,
                                        radius: 0.0,
                                        borderWidth: 0.0)
        progressView.update(currentProgress: Constants.minProgress)
        continueView.setup(delegate: self, state: .waiting)
        reportView.setup(with: .waiting)

        setupTableView()
        tableView.reloadData()
    }

    /// Waits for reboot of the drone
    func waitForReboot() {
        cancelButton.isHidden = false
        isWaitingForDroneReconnection = true
        progressView.setFakeRebootProgress(duration: Constants.rebootDuration)
    }

    /// Reloads the UI.
    func reloadUI() {
        dataSource = FirmwareAndMissionsUpdatingDataSource()
        progressView.update(currentProgress: dataSource.currentTotalProgress)
        tableView.reloadData()
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
        processesAreFinished = true
        continueView.setup(delegate: self, state: .success)
        reportView.setup(with: .success)
        progressView.setFakeSuccessOrErrorProgress()
        cancelButton.isHidden = true
    }

    /// Displays error UI.
    func displayErrorUI() {
        processesAreFinished = true
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
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorInset = UIEdgeInsets.zero

        tableView.tableFooterView = UIView()
        tableView.tableHeaderView = UIView()

        tableView.separatorColor = .clear
        tableView.backgroundColor = ColorName.greyShark.color
        tableView.register(cellType: ProtobufMissionUpdatingTableViewCell.self)
    }
}
