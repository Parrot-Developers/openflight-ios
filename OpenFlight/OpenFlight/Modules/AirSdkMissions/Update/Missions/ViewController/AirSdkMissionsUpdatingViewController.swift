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
import Combine
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
    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()
    private weak var coordinator: DroneFirmwaresCoordinator?
    private var viewModel: AirSdkMissionsUpdatingViewModel!
    private var rebootState: RebootState = .none
    private var processIsFinished: Bool = false
    private var updateOngoing: Bool = false
    private var isUpdateCancelledAlertShown: Bool = false

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
    static func instantiate(
        coordinator: DroneFirmwaresCoordinator,
        viewModel: AirSdkMissionsUpdatingViewModel) -> AirSdkMissionsUpdatingViewController {
            let viewController = StoryboardScene.AirSdkMissionsUpdating.initialScene.instantiate()
            viewController.coordinator = coordinator
            viewController.viewModel = viewModel
            return viewController
        }

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initUI()
        listenMissionUpdates()
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
        return viewModel.elements.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as AirSdkMissionUpdatingTableViewCell
        cell.setup(with: viewModel.elements[indexPath.row])
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
        viewModel.startMissionsUpdateProcess()
    }

    /// Listens to missions updater.
    func listenMissionUpdates() {
        viewModel.$globalUpdatingState
            .combineLatest(viewModel.$currentTotalProgress, viewModel.elementsPublisher)
            .receive(on: RunLoop.main)
            .sink { [weak self] state, currentTotalProgress, _ in
                self?.updateMissionsProcesses(
                    missionsGlobalUpdatingState: state,
                    currentTotalProgress: currentTotalProgress)
            }
            .store(in: &cancellables)
    }

    /// Finalize Missions processes.
    ///
    /// - Parameters:
    ///    - missionsGlobalUpdatingState: The gobal state of the processes
    ///    - currentTotalProgress: The current total progress between 0 and 1
    func updateMissionsProcesses(
        missionsGlobalUpdatingState: AirSdkMissionsGlobalUpdatingState,
        currentTotalProgress: Float) {
        switch missionsGlobalUpdatingState {
        case .ongoing:
            updateOngoing = true
            return
        case .uploading:
            viewModel.manualRebootState = .waiting
            progressView.update(currentProgress: currentTotalProgress)
            // Reload tableView only one time while uploading to avoid restarting little progress animation
            if updateOngoing {
                updateOngoing = false
                tableView.reloadData()
            }
            if !viewModel.isDroneConnected {
                showUpdateCancelledAlert()
            }
        case .done:
            if !viewModel.isRebootNeeded && !processIsFinished {
                viewModel.manualRebootState = .failed
                tableView.reloadData()
                ULog.i(.missionUpdateTag, "Missions Updates need no reboot")
                displayFinalUI()
            } else if viewModel.isRebootNeeded && rebootState == .none {
                triggerManualReboot()
            }
        }
    }

    /// Triggers manual reboot
    func triggerManualReboot() {
        cancelButton.isHidden = true
        viewModel.triggerManualReboot()
        viewModel.manualRebootState = .ongoing
        tableView.reloadData()
        progressView.setFakeProgress(duration: Constants.rebootDuration)
        rebootState = .requested
    }

    /// Listens to drone while it is rebooting.
    func listenToDroneReconnection() {
        viewModel.$isDroneConnected
            .sink { [weak self] isConnected in
                guard let self = self, !self.processIsFinished else { return }
                switch self.rebootState {
                case .none:
                    break
                case .requested:
                    if !isConnected {
                        self.rebootState = .ongoing
                    }
                case .ongoing:
                    if isConnected {
                        ULog.i(.missionUpdateTag, "Missions Update drone reconnected")
                        self.viewModel.manualRebootState = .succeeded
                        self.tableView.reloadData()
                        self.displayFinalUI()
                    }
                }
            }
            .store(in: &cancellables)
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
        let cancelSucceeded = viewModel.cancelAllUpdates(removeData: false)
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
        let cancelAction = AlertAction(title: L10n.firmwareMissionUpdateQuitInstallationCancelAction, actionHandler: nil)

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
        ULog.i(.missionUpdateTag, "Missions Updates Report screen")
        processIsFinished = true
        if viewModel.missionsUpdateProcessHasError() {
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
