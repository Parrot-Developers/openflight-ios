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

/// View controller which manage drones wifi connection.
final class PairingConnectDroneViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var loadingImageView: UIImageView!

    // MARK: - Private Properties
    private weak var coordinator: PairingCoordinator?
    private var viewModel: PairingConnectDroneViewModel!
    private var cancellables = Set<AnyCancellable>()
    private var items: [RemoteConnectDroneModel]?
    private var failedToConnect: Bool = false
    private var isConnecting: Bool = false
    private var selectedItem: IndexPath?

    // MARK: - Private Enums
    private enum Constants {
        static let errorLabelHeight: CGFloat = 20.0
    }

    // MARK: - Setup
    /// Instantiates the view controller.
    ///
    /// - Parameters:
    ///     - coordinator: the coordinator
    ///     - viewModel: the view model
    /// - Returns: the view controller
    static func instantiate(coordinator: Coordinator,
                            viewModel: PairingConnectDroneViewModel
    ) -> PairingConnectDroneViewController {
        let viewController = StoryboardScene.PairingConnectDrone.initialScene.instantiate()
        viewController.coordinator = coordinator as? PairingCoordinator
        viewController.viewModel = viewModel
        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        setupViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        LogEvent.log(.screen(LogEvent.Screen.pairingDroneFinderList))
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
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
        guard let item = items?[indexPath.row] else { return UITableViewCell() }

        let cell = tableView.dequeueReusableCell(for: indexPath) as PairingConnectDroneCell
        cell.setup(droneModel: item,
                   failedToConnect: failedToConnect && selectedItem == indexPath,
                   isConnecting: isConnecting && selectedItem == indexPath,
                   unpairStatus: viewModel.unpairState)
        cell.backgroundColor = .clear
        cell.delegate = self

        return cell
    }
}

// MARK: - PairingConnectDroneViewController Delegate
extension PairingConnectDroneViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let item = items?[indexPath.row] {
            if viewModel.needPassword(uid: item.droneUid) == false {
                logEvent(with: LogEvent.LogKeyPairingButton.connectToDroneWithoutPassword.name)
                // Save the current indexPath when we try to connect to the drone without password.
                selectedItem = indexPath
                viewModel.connectDroneWithoutPassword(uid: item.droneUid)
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
        let shouldExpand: Bool = (failedToConnect || isConnecting)
        && selectedItem == indexPath

        let baseHeight = Layout.buttonIntrinsicHeight(isRegularSizeClass) + Layout.mainSpacing(isRegularSizeClass)
        return shouldExpand ? baseHeight + Constants.errorLabelHeight : baseHeight
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
        tableView.contentInset.bottom = Layout.tableViewCellContentInset(isRegularSizeClass, screenBorders: [.bottom]).bottom
        tableView.register(cellType: PairingConnectDroneCell.self)
        titleLabel.text = L10n.pairingLookingForDrone
        // Instantiate the footer.
        let footerFrame = CGRect(x: 0, y: 0,
                                 width: tableView.frame.width,
                                 height: Layout.buttonIntrinsicHeight(isRegularSizeClass)
                                 + Layout.mainSpacing(isRegularSizeClass))
        let footerView = PairingConnectDroneRefreshView(frame: footerFrame)
        footerView.navDelegate = self
        tableView.tableFooterView = footerView
    }

    /// Sets up view model
    func setupViewModel() {
        viewModel.$remoteControlConnectionState
            .sink { [unowned self] in
                // Come back to pairing menu if the remote is disconnected.
                if $0 != .connected {
                    coordinator?.dismissRemoteConnectDrone()
                }
            }
            .store(in: &cancellables)

        viewModel.$pairingConnectionState
            .sink { [unowned self] in
                updatePairingDroneConnectionState($0)
            }
            .store(in: &cancellables)

        viewModel.isListUnavailable
            .sink { [unowned self] in
                updateLoadingView(isListUnavailable: $0)
            }
            .store(in: &cancellables)

        viewModel.$discoveredDronesList
            .sink { [unowned self] in
                updateDataSource(discoveredDronesList: $0)
            }
            .store(in: &cancellables)
    }

    /// Update with current pairing connect drone state.
    ///
    /// - Parameters:
    ///    - state: pairing connection state
    func updatePairingDroneConnectionState(_ state: PairingDroneConnectionState) {
        updateConnectionState(state: state)
    }

    /// Reload discovered drones list with the refresh button.
    ///
    /// - Parameters:
    ///    - discoveredDroneList: list of the discovered drone
    func updateDataSource(discoveredDronesList: [RemoteConnectDroneModel]?) {
        items = discoveredDronesList
        tableView.reloadData()
    }

    /// Update the loader.
    ///
    /// - Parameters:
    ///    - isListUnavailable: `true` when the list of the discovered drone is unavailable, `false` otherwise
    func updateLoadingView(isListUnavailable: Bool) {
        if isListUnavailable {
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
    ///
    /// - Parameters:
    ///    - state: pairing connection state
    func updateConnectionState(state: PairingDroneConnectionState) {
        isConnecting = false
        failedToConnect = false

        switch state {
        case .connecting:
            isConnecting = true
            updateDataSource(discoveredDronesList: viewModel.discoveredDronesList)
        case .disconnected:
            failedToConnect = true
            updateDataSource(discoveredDronesList: viewModel.discoveredDronesList)
        case .incorrectPassword:
            guard let selectedItemRow = selectedItem?.row,
                    let item = items?[selectedItemRow] else {
                return
            }
            logEvent(with: LogEvent.LogKeyPairingButton.connectToDronePasswordNeeded.name)
            selectedItem = nil
            // Open detail screen if we need to connect to the drone with a password.
            coordinator?.startRemoteConnectDroneDetail(droneModel: item)
        default:
            break
        }
    }

    /// Calls log event.
    ///
    /// - Parameters:
    ///     - itemName: Button name
    func logEvent(with itemName: String) {
        LogEvent.log(.simpleButton(itemName))
    }
}

// MARK: - DroneListDelegate
extension PairingConnectDroneViewController: DroneListDelegate {
    func refresh() {
        logEvent(with: LogEvent.LogKeyPairingButton.refreshDroneList.name)
        viewModel.refreshDroneList()
        failedToConnect = false
        isConnecting = false
        selectedItem = nil
    }
}

// MARK: - PairingConnectDroneCellDelegate
extension PairingConnectDroneViewController: PairingConnectDroneCellDelegate {
    func forgetDrone(uid: String) {
        let forgetAction = AlertAction(title: L10n.commonForget,
                                       style: .destructive,
                                       actionHandler: { [weak self] in
            self?.viewModel.forgetDrone(uid: uid)
        })
        let cancelAction = AlertAction(title: L10n.cancel,
                                       style: .default2)
        showAlert(title: L10n.cellularPairingForgetDrone,
                  message: L10n.cellularPairingForgetDroneDescription,
                  cancelAction: cancelAction,
                  validateAction: forgetAction)
    }
}
