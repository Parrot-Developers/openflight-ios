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

/// View controller which manage drones wifi connection.

final class PairingConnectDroneViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var loadingImageView: UIImageView!
    @IBOutlet private weak var backgroundView: UIView!

    // MARK: - Private Properties
    private weak var coordinator: PairingCoordinator?
    private var pairingConnectDroneViewModel: PairingConnectDroneViewModel?
    private var items: [RemoteConnectDroneModel]?
    private var failedToConnect: Bool = false
    private var isConnecting: Bool = false
    private var selectedItem: IndexPath?

    // MARK: - Private Enums
    private enum Constants {
        static let smallCellHeight: CGFloat = 70.0
        static let highCellHeight: CGFloat = 90.0
        static let topInset: CGFloat = 24.0
        static let footerHeight: CGFloat = 80.0
    }

    // MARK: - Setup
    static func instantiate(coordinator: Coordinator) -> PairingConnectDroneViewController {
        let viewController = StoryboardScene.Pairing.pairingConnectDroneViewController.instantiate()
        viewController.coordinator = coordinator as? PairingCoordinator

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()

        // Listen state from the view model.
        pairingConnectDroneViewModel = PairingConnectDroneViewModel(stateDidUpdate: {[weak self] state in
            // Come back to pairing menu if the remote is disconnected.
            if state.remoteControlConnectionState?.isConnected() == false {
                self?.coordinator?.dismissRemoteConnectDrone()
            }

            self?.updateDataSource()
            self?.updateConnectionState()
            self?.updateLoadingView()

            if state.unpairState.shouldShowError {
                self?.showUnpairAlert(with: state.unpairState.title ?? L10n.error)
            }
        })
        updateDataSource()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.pairingDroneFinderList,
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

// MARK: - PairingConnectDroneViewController Data source
extension PairingConnectDroneViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()

        guard let item = items?[indexPath.row] else { return cell }

        cell = tableView.dequeueReusableCell(withIdentifier: PairingConnectDroneCell.reuseIdentifier, for: indexPath)
        if let cell = cell as? PairingConnectDroneCell {
            cell.setup(droneModel: item, failedToConnect: failedToConnect && selectedItem == indexPath, isConnecting: isConnecting && selectedItem == indexPath)
            cell.backgroundColor = .clear
            cell.delegate = self
        }

        return cell
    }
}

// MARK: - PairingConnectDroneViewController Delegate
extension PairingConnectDroneViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let item = items?[indexPath.row] {
            if pairingConnectDroneViewModel?.needPassword(uid: item.droneUid) == false {
                logEvent(with: LogEvent.LogKeyPairingButton.connectToDroneWithoutPassword.name)
                // Save the current indexPath when we try to connect to the drone without password.
                selectedItem = indexPath
                pairingConnectDroneViewModel?.connectDroneWithoutPassword(uid: item.droneUid)
            } else {
                logEvent(with: LogEvent.LogKeyPairingButton.connectToDronePasswordNeeded.name)
                selectedItem = nil
                // Open detail screen if we need to connect to the drone with a password.
                coordinator?.startRemoteConnectDroneDetail(droneModel: item)
            }
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Expand cell when there is info or error to show.
        return (failedToConnect || isConnecting) && selectedItem == indexPath ? Constants.highCellHeight : Constants.smallCellHeight
    }
}

// MARK: - Actions
private extension PairingConnectDroneViewController {
    @IBAction func backButtonTouchedUpInside(_ sender: Any) {
        coordinator?.dismissRemoteConnectDrone()
    }
}

// MARK: - Private Funcs
private extension PairingConnectDroneViewController {
    /// Init the view.
    func initView() {
        tableView.contentInset.top = Constants.topInset
        tableView.backgroundColor = .clear
        backgroundView.backgroundColor = UIColor(named: .white10)
        self.view.backgroundColor  = UIColor(named: .black)
        tableView.register(cellType: PairingConnectDroneCell.self)
        titleLabel.text = L10n.pairingLookingForDrone
        // Instantiate the footer.
        let footerView = PairingConnectDroneRefreshView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: Constants.footerHeight))
        footerView.navDelegate = self
        tableView.tableFooterView = footerView
    }

    /// Reload discovered drones list with the refresh button.
    func updateDataSource() {
        items = pairingConnectDroneViewModel?.state.value.discoveredDronesList
        tableView.reloadData()
    }

    /// Update the loader.
    func updateLoadingView() {
        if pairingConnectDroneViewModel?.state.value.isListUnavailable == true {
            loadingImageView?.isHidden = false
            titleLabel.text = L10n.pairingLookingForDrone
            loadingImageView.startRotate()
        } else {
            loadingImageView?.isHidden = true
            titleLabel.text = L10n.pairingSelectYourDrone
            loadingImageView.stopRotate()
        }
    }

    /// Update connection view with label error and connection state.
    func updateConnectionState() {
        guard let connectionState = pairingConnectDroneViewModel?.state.value.connectionState else { return }

        isConnecting = false
        failedToConnect = false

        switch connectionState {
        case PairingDroneConnectionState.connecting:
            isConnecting = true
            // Reload data with a private var like isConnecting.
            updateDataSource()
        case PairingDroneConnectionState.disconnected,
             PairingDroneConnectionState.incorrectPassword:
            pairingConnectDroneViewModel?.resetDroneConnectionStateRef()
            failedToConnect = true
            updateDataSource()
        default:
            break
        }
    }

    /// Calls log event.
    ///
    /// - Parameters:
    ///     - itemName: Button name
    func logEvent(with itemName: String) {
        LogEvent.logAppEvent(itemName: itemName,
                             newValue: nil,
                             logType: .button)
    }

    /// Shows an alert when user can't unpair a drone.
    ///
    /// - Parameters:
    ///     - message: message to display
    func showUnpairAlert(with message: String) {
        let cancelAction = AlertAction(title: L10n.ok, actionHandler: { [weak self] in
            self?.coordinator?.dismiss()
        })

        let alert = AlertViewController.instantiate(title: L10n.error,
                                                    message: message,
                                                    cancelAction: cancelAction,
                                                    validateAction: nil)
        self.present(alert, animated: true)
    }
}

// MARK: - DroneListDelegate
extension PairingConnectDroneViewController: DroneListDelegate {
    func refresh() {
        logEvent(with: LogEvent.LogKeyPairingButton.refreshDroneList.name)
        pairingConnectDroneViewModel?.refreshDroneList()
        failedToConnect = false
        isConnecting = false
        selectedItem = nil
    }
}

// MARK: - PairingConnectDroneCellDelegate
extension PairingConnectDroneViewController: PairingConnectDroneCellDelegate {
    func forgetDrone(uid: String) {
        pairingConnectDroneViewModel?.forgetDrone(uid: uid)
    }
}
