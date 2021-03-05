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

/// View Controller used to display details about Remote.
final class RemoteDetailsViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var remoteImageView: UIImageView!
    @IBOutlet private weak var batteryImageView: UIImageView!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var batteryValueLabel: UILabel!
    @IBOutlet private weak var droneButtonView: DeviceButtonView!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var calibrationButton: DeviceButtonView!
    @IBOutlet private weak var resetButton: DeviceButtonView!
    @IBOutlet private weak var backgroundView: UIView!

    // MARK: - Private Properties
    private var detailsListViewModel: RemoteDetailsListViewModel?
    private var detailsViewModel: RemoteDetailsViewModel?
    private weak var coordinator: RemoteCoordinator?
    private var items: [DeviceSystemInfoModel]?

    // MARK: - Private Enums
    private enum Constants {
        static let minimumBatteryLevel: Double = 40.0
    }

    // MARK: - Setup
    static func instantiate(coordinator: RemoteCoordinator) -> RemoteDetailsViewController {
        let viewController = StoryboardScene.RemoteDetails.initialScene.instantiate()
        viewController.coordinator = coordinator

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        // Starts observing view models
        observeDetailsViewModel()
        observeDetailsListViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.remoteControlDetails,
                             logType: .screen)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        updateButtons()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        updateButtons()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension RemoteDetailsViewController {
    @IBAction func backButtonTouchedUpInside(_ sender: Any) {
        LogEvent.logAppEvent(itemName: LogEvent.LogKeyCommonButton.back, logType: .simpleButton)
        coordinator?.dismissChildCoordinator()
    }

    @IBAction func droneButtonTouchedUpInside(_ sender: Any) {
        LogEvent.logAppEvent(itemName: LogEvent.LogKeyRemoteInfosButton.remoteConnectToDrone.name,
                             newValue: nil,
                             logType: .button)
        if detailsViewModel?.state.value.remoteControlConnectionState?.isConnected() == true {
            coordinator?.startDronesList()
        }
    }

    @IBAction func resetButtonTouchedUpInside(_ sender: Any) {
        // Present an alert if the user wants to reset the remote.
        let validateAction = AlertAction(title: L10n.commonReset, actionHandler: { [weak self] in
            self?.detailsViewModel?.resetRemote()
            LogEvent.logAppEvent(itemName: LogEvent.LogKeyRemoteInfosButton.remoteReset.name,
                                 newValue: nil,
                                 logType: .button)
        })

        self.showAlert(title: L10n.remoteDetailsResetTitle,
                       message: L10n.remoteDetailsResetDescription,
                       validateAction: validateAction)
    }

    @IBAction func calibrationButtonTouchedUpInside(_ sender: Any) {
        coordinator?.startCalibration()
    }
}

// MARK: - Private Funcs
private extension RemoteDetailsViewController {
    /// Init the view.
    func initView() {
        backgroundView.backgroundColor = UIColor(named: .white10)
        tableView.register(cellType: RemoteDetailsTableViewCell.self)
        tableView.backgroundColor = .clear
        tableView.backgroundView = nil
        tableView.isScrollEnabled = false
        resetButton.cornerRadiusedWith(backgroundColor: UIColor(named: .white20),
                                       radius: Style.largeCornerRadius)
        calibrationButton.cornerRadiusedWith(backgroundColor: UIColor(named: .white20),
                                             radius: Style.largeCornerRadius)
        batteryImageView.image = Asset.Remote.icBatteryFull.image

        calibrationButton.fill(model: DeviceButtonModel(label: L10n.remoteDetailsCalibration, image: nil))
        resetButton.fill(model: DeviceButtonModel(label: L10n.commonReset, image: nil))
    }

    /// Observe the details list view model.
    func observeDetailsListViewModel() {
        detailsListViewModel = RemoteDetailsListViewModel(stateDidUpdate: { [weak self] _ in
            self?.updateDataSource()
        })
        titleLabel.text = detailsListViewModel?.state.value.remoteName

        // Initial state.
        updateDataSource()
    }

    /// Observe the details view model.
    func observeDetailsViewModel() {
        detailsViewModel = RemoteDetailsViewModel(stateDidUpdate: { [weak self] state in
            self?.updateView(state)
            self?.updateButtons()
        })
        // Initial state.
        updateView(detailsViewModel?.state.value)
    }

    /// Update the table view data source.
    func updateDataSource() {
        items = detailsListViewModel?.remoteSystemItems
        tableView.reloadData()
    }

    /// Update the view.
    /// - Parameters:
    ///     - state: remote detail state
    func updateView(_ state: RemoteDetailsState?) {
        guard let state = state else { return }

        // Update title.
        if let name = state.remoteName {
            titleLabel.text = name
        } else {
            titleLabel.text = L10n.remoteDetailsControllerInfos
        }

        titleLabel.text = state.remoteName
        // Update remote & battery view.
        if let batteryLevel = state.batteryLevel?.currentValue {
            batteryValueLabel.attributedText = NSMutableAttributedString(withBatteryLevel: batteryLevel)
        } else {
            batteryValueLabel.text = Style.dash
        }

        batteryImageView.image = state.batteryLevel?.batteryImage
        if state.remoteControlConnectionState?.isConnected() == true {
            remoteImageView.image = Asset.Remote.icRemoteBigConnected.image
        } else {
            remoteImageView.image = Asset.Remote.icRemoteBigDisconnected.image
        }

        // Update drone Buttons.
        if state.droneConnectionState?.isConnected() == true,
           state.remoteControlConnectionState?.isConnected() == true {
            droneButtonView.fill(model: DeviceButtonModel(label: state.droneName,
                                                          image: state.wifiStrength.signalIcon()))
        } else if state.remoteControlConnectionState?.isConnected() == true,
                  state.droneConnectionState?.isConnected() == false {
            droneButtonView.fill(model: DeviceButtonModel(label: L10n.remoteDetailsConnectToADrone,
                                                          image: nil))
        } else {
            droneButtonView.fill(model: DeviceButtonModel(label: L10n.disconnected,
                                                          image: Asset.Remote.icSdCardUsb.image))
        }
    }

    /// Update buttons view regarding screen orientation.
    func updateButtons() {
        // Update left buttons.
        let state = detailsViewModel?.state.value

        droneButtonView.cornerRadiusedWith(backgroundColor: .clear,
                                           radius: 0.0)

        if state?.remoteControlConnectionState?.isConnected() == true,
           state?.droneConnectionState?.isConnected() == false {
            droneButtonView.cornerRadiusedWith(backgroundColor: UIColor(named: .greenSpring20),
                                               radius: Style.largeCornerRadius)
            droneButtonView.titleColor = UIColor(named: .greenSpring)
        } else {
            droneButtonView.cornerRadiusedWith(backgroundColor: UIColor(named: .white20),
                                               radius: Style.largeCornerRadius)
            droneButtonView.titleColor = UIColor(named: .white)
        }

        let isConnected = state?.remoteControlConnectionState?.isConnected()
        // Update buttons according to connection state.
        calibrationButton.titleColor = UIColor(named: isConnected == true ? .white : .white50)
        resetButton.titleColor = UIColor(named: isConnected == true ? .white : .white50)
        droneButtonView.titleColor = UIColor(named: isConnected == true ? .white : .white50)

        calibrationButton.isEnabled = isConnected == true
        resetButton.isEnabled = isConnected == true

        // Update calibration button.
        calibrationButton.backgroundColor = UIColor(named: state?.needCalibration == true ? .orangePeel : .white20)
    }

    /// Present a common alert in case of update error.
    ///
    /// - Parameters:
    ///     - title: alert title
    ///     - message: alert description
    func showErrorAlert(title: String, message: String) {
        let cancelAction = AlertAction(title: L10n.ok,
                                       actionHandler: nil)

        let alert = AlertViewController.instantiate(title: title,
                                                    message: message,
                                                    cancelAction: cancelAction,
                                                    validateAction: nil)
        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: - RemoteDetailsViewController Data Source
extension RemoteDetailsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let item = items?[indexPath.row] else { return UITableViewCell() }

        let cell = tableView.dequeueReusableCell(for: indexPath) as RemoteDetailsTableViewCell
        if let state = detailsListViewModel?.state.value {
            cell.setup(model: item,
                       needUpdate: state.needUpdate == true,
                       isConnected: state.remoteControlConnectionState?.isConnected() == true)
        }

        return cell
    }
}

// MARK: - RemoteDetailsViewController Delegate
extension RemoteDetailsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let item = items?[indexPath.row],
           item.section == SectionSystemInfo.software,
           detailsViewModel?.state.value.remoteControlConnectionState?.isConnected() == true,
           detailsListViewModel?.state.value.needUpdate == true {
            if detailsViewModel?.isBatteryLevelSufficient() == false {
                let percent = Constants.minimumBatteryLevel.asPercent()
                showErrorAlert(title: L10n.remoteUpdateInsufficientBatteryTitle,
                               message: L10n.remoteUpdateInsufficientBatteryDescription(percent))
            } else if detailsViewModel?.isDroneFlying() == true {
                showErrorAlert(title: L10n.deviceUpdateImpossible,
                               message: L10n.deviceUpdateDroneFlying)
            } else {
                // Launchs intermediate screen before update.
                coordinator?.startUpdate()
            }
        }
    }
}
