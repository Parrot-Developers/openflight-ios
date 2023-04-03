//    Copyright (C) 2023 Parrot Drones SAS
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

/// The interface for the battery updating process
class BatteryUpdatingViewController: UIViewController {
    // MARK: - Private Properties
    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()
    private var viewModel: BatteryUpdatingViewModel!
    private weak var coordinator: DroneFirmwaresCoordinator?

    @IBOutlet weak var cancelButton: InsetHitAreaButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var progressView: NormalizedCircleProgressView!
    @IBOutlet weak var tableView: UpdatingTableView!
    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var reportView: UpdatingSuccessHeader!
    @IBOutlet weak var continueView: UpdatingDoneFooter!

    // MARK: - Private Enums
    enum Constants {
        static let tableViewHeight: CGFloat = 35.0
        static let batteryUpdateDuration: TimeInterval = 12.0
        static let rebootDuration: TimeInterval = 35.0
        static let updatingProgress: Float = 100 * 2.0 / 3.0
        static let stepsCount: Float = 3.0
    }

    // MARK: - Setup
    static func instantiate(coordinator: DroneFirmwaresCoordinator, viewModel: BatteryUpdatingViewModel) -> BatteryUpdatingViewController {
        let viewController = StoryboardScene.BatteryUpdating.initialScene.instantiate()
        viewController.coordinator = coordinator
        viewController.viewModel = viewModel
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        listenBatteryUpdater()
        viewModel.startUpdateProcess()
    }

    /// Inits buttons and labels, resets the progress view and prepares the list of steps.
    func initUI() {
        cancelButton.setTitle(L10n.cancel, for: .normal)
        titleLabel.text = L10n.batteryUpdateTitle
        warningLabel.isHidden = false
        warningLabel.text = L10n.batteryUpdateWarning
        progressView.updateImage(image: Asset.Drone.Battery.illuBattery.image)
        reportView.setup(with: .waiting)
        reportView.isHidden = true
        continueView.setup(delegate: self, state: .waiting)
        continueView.isHidden = true
        setupTableView()
    }

    /// Sets up the table view.
    func setupTableView() {
        tableView.allowsSelection = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableHeaderView = UIView()
        tableView.separatorColor = .clear
        tableView.register(cellType: BatteryUpdatingTableViewCell.self)
    }

    /// Listens to the battery updater peripheral.
    ///
    /// Updates the list of steps and the progress bar accordingly.
    /// Displays the success or error interface when done.
    func listenBatteryUpdater() {
        viewModel.elementsPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)

        viewModel.$progressStep
            .receive(on: RunLoop.main)
            .sink { [weak self] progressStep in
                self?.updateProgress(progressStep: progressStep)
            }
            .store(in: &cancellables)
    }

    /// Updates the progress view and displays success when done.
    ///
    /// Only during the preparingUpdate step, a progress value is used.
    /// Since there is no progress value for the updating and rebooting steps, we use a fake progress animation.
    /// - Parameter progressStep: the current progress step
    func updateProgress(progressStep: ProgressStep) {
        switch progressStep {
        case .preparingUpdate(progress: let progress):
            cancelButton.isHidden = false
            progressView.update(currentProgress: progress / Constants.stepsCount)
        case .updating:
            cancelButton.isHidden = true
            progressView.setFakeProgress(progressEnd: Constants.updatingProgress, duration: Constants.batteryUpdateDuration)
        case .rebooting:
            cancelButton.isHidden = true
            progressView.setFakeProgress(duration: Constants.rebootDuration)
        case .error:
            displayErrorUI()
        case .success:
            displaySuccessUI()
        }
    }

    /// Displays success UI.
    func displaySuccessUI() {
        warningLabel.isHidden = true
        reportView.setup(with: .success)
        reportView.isHidden = false
        continueView.setup(delegate: self, state: .success)
        continueView.isHidden = false
        progressView.setFakeSuccessOrErrorProgress()
        cancelButton.isHidden = true
    }

    /// Displays error UI.
    func displayErrorUI() {
        warningLabel.isHidden = true
        reportView.setup(with: .error)
        reportView.isHidden = false
        continueView.setup(delegate: self, state: .error)
        continueView.isHidden = false
        progressView.setFakeSuccessOrErrorProgress()
        cancelButton.isHidden = true
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

    @IBAction func cancelButtonTouchUpInside() {
        quitProcesses(closeFirmwareList: false)
    }
}

// MARK: - UITableViewDataSource
extension BatteryUpdatingViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.elements.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as BatteryUpdatingTableViewCell
        cell.setup(updatingStep: viewModel.elements[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate
extension BatteryUpdatingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.tableViewHeight
    }
}

// MARK: - UpdatingDoneFooterDelegate
extension BatteryUpdatingViewController: UpdatingDoneFooterDelegate {
    func quitProcesses() {
        quitProcesses(closeFirmwareList: true)
    }
}
