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
    private var updateOngoing: Bool = false
    private var isProcessCancelable: Bool = true
    private var isWaitingForDroneReconnection: Bool = false
    private var shouldRestartProcesses: Bool = false
    private var droneStateViewModel = DroneStateViewModel()

    // MARK: - Private Enums
    enum Constants {
        static let minProgress: Float = 0.0
        static let tableViewHeight: CGFloat = 50.0
        static let rebootDuration: TimeInterval = 120.0
        static let missionUpdateTag: String = "Firmware Update drone reconnected"
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
        RemoteControlGrabManager.shared.enableRemoteControl()
        coordinator?.back()
    }
}

// MARK: - Actions
private extension FirmwareUpdatingViewController {
    @IBAction func cancelButtonTouchedUpInside(_ sender: Any) {
        if isProcessCancelable {
            presentCancelAlertViewController()
        } else {
            presentQuitRebootAlertViewController()
        }
    }
}

// MARK: - Private Funcs
private extension FirmwareUpdatingViewController {
    /// Starts the download and update firmware processes.
    func startProcesses() {
        RemoteControlGrabManager.shared.disableRemoteControl()
        firmwareUpdaterManager.startFirmwareProcesses()
    }

    /// Listens to the Firmware Update Manager .
    func listenToFirmwareUpdateManager() {
        firmwareUpdateListener = firmwareUpdaterManager
            .register(firmwareToUpdateCallback: { [weak self] ( firmwareGlobalUpdatingState) in
                guard let strongSelf = self,
                      !strongSelf.shouldRestartProcesses else {
                    return
                }

                strongSelf.handleFirmwareProcesses(firmwareGlobalUpdatingState: firmwareGlobalUpdatingState)
            })
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
            isProcessCancelable = false
            updateProgress()
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
        }
    }

    /// Waits for reboot of the drone
    func waitForReboot() {
        cancelButton.isHidden = false
        isWaitingForDroneReconnection = true
        progressView.setFakeRebootProgress(duration: Constants.rebootDuration)
    }

    /// This is the last step of the processes.
    func listenToDroneReconnection() {
        droneStateViewModel.state.valueChanged = { [weak self] state in
            guard let strongSelf = self,
                  state.connectionState == .connected else {
                return
            }

            if strongSelf.shouldRestartProcesses {
                strongSelf.restartProcesses()
            } else if strongSelf.isWaitingForDroneReconnection {
                // After the reboot and the new connection of the drone, func handleFirmwareProcesses() is expected to
                // be called and finalize the UI.
                strongSelf.isWaitingForDroneReconnection = false
                ULog.d(.missionUpdateTag, Constants.missionUpdateTag)
            }
        }
    }

    /// Cancel operation in progress.
    @objc func cancelProcesses() {
        guard isProcessCancelable else { return }

        let cancelSucceeded = FirmwareAndMissionsInteractor.shared.cancelAllUpdates(removeData: false)
        self.cancelButton.isHidden = cancelSucceeded
    }

    /// Restart operation in progress.
    @objc func restartProcesses() {
        guard !isWaitingForDroneReconnection,
              firmwareUpdateListener != nil else { return }

        resetUI()

        // Drone should be connected to restart FW update (depends on operation in progress).
        if droneStateViewModel.state.value.isConnected() == false,
           firmwareUpdaterManager.remainingOperationsRequiresDrone() {
            shouldRestartProcesses = true
        } else {
            shouldRestartProcesses = false
            startProcesses()
        }
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
private extension FirmwareUpdatingViewController {
    /// Inits the UI.
    func initUI() {
        titleLabel.text = L10n.firmwareMissionUpdateFirmwareUpdate
        subtitleLabel.textColor = ColorName.white50.color
        subtitleLabel.text = dataSource.subtitle
        cancelButton.setTitle(L10n.cancel, for: .normal)
        cancelButton.makeup(with: .large)
        cancelButton.cornerRadiusedWith(backgroundColor: ColorName.greyShark.color,
                                        radius: 0.0)
        view.backgroundColor = ColorName.greyShark.color
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
        tableView.makeUp(backgroundColor: ColorName.greyShark.color)
        tableView.tableHeaderView = UIView()
        tableView.separatorColor = .clear
        tableView.register(cellType: ProtobufMissionUpdatingTableViewCell.self)
    }
}
