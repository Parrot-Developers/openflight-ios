//    Copyright (C) 2021 Parrot Drones SAS
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

import Foundation
import Combine
import GroundSdk
import Network

private extension ULogTag {
    static let tag = ULogTag(name: "DroneDetailCellularViewModel")
}

// swiftlint:disable type_body_length
public final class DroneDetailCellularViewModel {

    // MARK: - Published Variables

    @Published private(set) var remoteCellularLink: CellularLink?
    @Published private(set) var droneCellularLink: NetworkControlLinkInfo?
    @Published private(set) var cellularStrength: CellularStrength?
    @Published private(set) var remoteError: String?
    @Published private(set) var isSupportButtonHidden: Bool = true
    @Published private(set) var isSupportButtonEnabled: Bool = false
    @Published private(set) var supportButtonTitle: String = ""
    @Published private(set) var connectionStatusColor: ColorName = .defaultTextColor

    private(set) var isFlying = CurrentValueSubject<Bool, Never>(false)

    // MARK: - Variables

    private weak var coordinator: DroneCoordinator?
    private var currentDroneHolder: CurrentDroneHolder
    private var cellularPairingService: CellularPairingService
    private var connectedRemoteControlHolder: ConnectedRemoteControlHolder
    private var connectedDroneHolder: ConnectedDroneHolder
    private unowned let networkService: NetworkService
    private var cellularService: CellularService
    private var cellularSessionService: CellularSessionService
    private var cellularSupportProvider: CellularSupportProvider?
    private var networkControlRef: Ref<NetworkControl>?
    private var remoteCellularLinkRef: Ref<CellularLink>?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    public init(coordinator: DroneCoordinator,
                currentDroneHolder: CurrentDroneHolder,
                cellularPairingService: CellularPairingService,
                connectedRemoteControlHolder: ConnectedRemoteControlHolder,
                connectedDroneHolder: ConnectedDroneHolder,
                networkService: NetworkService,
                cellularService: CellularService,
                cellularSessionService: CellularSessionService,
                cellularSupportProvider: CellularSupportProvider? = nil) {
        self.coordinator = coordinator
        self.currentDroneHolder = currentDroneHolder
        self.cellularPairingService = cellularPairingService
        self.connectedRemoteControlHolder = connectedRemoteControlHolder
        self.connectedDroneHolder = connectedDroneHolder
        self.networkService = networkService
        self.cellularService = cellularService
        self.cellularSessionService = cellularSessionService
        self.cellularSupportProvider = cellularSupportProvider

        isSupportButtonHidden = cellularSupportProvider?.isHidden ?? true
        supportButtonTitle = cellularSupportProvider?.title ?? ""
        cellularSupportProvider?.isEnabledPublisher
            .compactMap { $0 }
            .sink { [unowned self] in
                isSupportButtonEnabled = $0
            }
            .store(in: &cancellables)

        connectedDroneHolder.dronePublisher
            .sink { [unowned self] drone in
                listenFlyingState(drone: drone)
            }
            .store(in: &cancellables)

        connectedRemoteControlHolder.remoteControlPublisher
            .compactMap { $0 }
            .sink { [unowned self] remoteControl in
                listenRemoteCellularLink(remoteControl: remoteControl)
            }
            .store(in: &cancellables)

        connectedRemoteControlHolder.remoteControlPublisher
            .sink { [unowned self] remoteControl in
                if remoteControl == nil {
                    connectionStatusColor = .errorColor
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - AnyPublisher

    var cellularStatusString: AnyPublisher<String?, Never> {
        cellularSessionService.currentDroneStatusPublisher
            .combineLatest(remoteControl,
                           networkService.networkReachable.removeDuplicates(),
                           drone)
            .map { (cellularStatus, remoteControl, reachable, drone) in
                if remoteControl == nil || reachable == false || drone == nil {
                    return nil
                }

                return cellularStatus
            }
            .eraseToAnyPublisher()
    }

    /// Publishes the cellular status of the drone
    var cellularStatus: AnyPublisher<DetailsCellularStatus, Never> {
        cellularService.cellularStatusPublisher
            .map { return $0 }
            .eraseToAnyPublisher()
    }

    var cellularLinkState: AnyPublisher<String?, Never> {
        cellularSessionService.droneCellularSessionPublisher
            .combineLatest(cellularSessionService.remoteCellularSessionPublisher)
            .map { [weak self] (droneCellularSession, remoteCellularSession) in
                guard let self = self else { return L10n.commonNotConnected }
                guard let droneCellularSession = droneCellularSession,
                      let remoteCellularSession = remoteCellularSession
                else {
                    self.connectionStatusColor = .errorColor
                    return L10n.commonNotConnected
                }

                return self.checkStatus(droneStatus: droneCellularSession, remoteStatus: remoteCellularSession)
            }
            .eraseToAnyPublisher()
    }

    func checkModemAndServer(modem: CellularSessionStatus.Modem, server: CellularSessionStatus.Server) -> String {
        switch modem {
        case .updating, .off, .offline, .error:
            connectionStatusColor = .errorColor
            return L10n.commonNotConnected

        case .online:
            switch server {
            case .connected, .connecting:
                connectionStatusColor = .defaultTextColor
                return L10n.cellularConnection

            default:
                connectionStatusColor = .errorColor
                return L10n.commonNotConnected
            }
        }
    }

    func checkModemAndConnection(modem: CellularSessionStatus.Modem, connection: CellularSessionStatus.Connection) -> String {
        switch modem {
        case .updating, .off, .offline, .error:
            connectionStatusColor = .errorColor
            return L10n.commonNotConnected

        case .online:
            switch connection {
            case .connecting:
                connectionStatusColor = .defaultTextColor
                return L10n.cellularConnection

            default:
                connectionStatusColor = .errorColor
                return L10n.commonNotConnected
            }
        }
    }

    func checkSimAndServer(sim: CellularSessionStatus.Sim, server: CellularSessionStatus.Server) -> String {
        switch sim {
        case .locked, .error, .absent:
            connectionStatusColor = .errorColor
            return L10n.commonNotConnected

        case .ready:
            switch server {
            case .connected, .connecting:
                connectionStatusColor = .defaultTextColor
                return L10n.cellularConnection

            default:
                connectionStatusColor = .errorColor
                return L10n.commonNotConnected
            }
        }
    }

    func checkSimAndConnection(sim: CellularSessionStatus.Sim, connection: CellularSessionStatus.Connection) -> String {
        switch sim {
        case .locked, .error, .absent:
            connectionStatusColor = .errorColor
            return L10n.commonNotConnected

        case .ready:
            switch connection {
            case .connecting:
                connectionStatusColor = .defaultTextColor
                return L10n.cellularConnection

            default:
                connectionStatusColor = .errorColor
                return L10n.commonNotConnected
            }
        }
    }

    func checkNetworkAndServer(network: CellularSessionStatus.Network, server: CellularSessionStatus.Server ) -> String {
        switch network {
        case .activationDenied, .registrationDenied:
            connectionStatusColor = .errorColor
            return L10n.commonNotConnected

        case .searching, .home, .roaming:
            switch server {
            case .connecting, .connected:
                connectionStatusColor = .defaultTextColor
                return L10n.cellularConnection

            default:
                connectionStatusColor = .errorColor
                return L10n.commonNotConnected
            }
        }
    }

    func checkNetworkAndConnection(network: CellularSessionStatus.Network, connection: CellularSessionStatus.Connection) -> String {
        switch network {
        case .activationDenied, .registrationDenied:
            connectionStatusColor = .errorColor
            return L10n.commonNotConnected

        case .searching, .home, .roaming:
            switch connection {
            case .connecting:
                connectionStatusColor = .defaultTextColor
                return L10n.cellularConnection

            default:
                connectionStatusColor = .errorColor
                return L10n.commonNotConnected
            }
        }
    }

    func checkBothServer(droneServer: CellularSessionStatus.Server, remoteServer: CellularSessionStatus.Server) -> String {
        switch droneServer {
        case .connected, .connecting:
            switch remoteServer {
            case .connected, .connecting:
                connectionStatusColor = .defaultTextColor
                return L10n.cellularConnection

            default:
                connectionStatusColor = .errorColor
                return L10n.commonNotConnected
            }

        default:
            connectionStatusColor = .errorColor
            return L10n.commonNotConnected
        }
    }

    func checkServerAndConnection(server: CellularSessionStatus.Server, connection: CellularSessionStatus.Connection) -> String {
        switch server {
        case .connected, .connecting:
            switch connection {
            case .connecting:
                connectionStatusColor = .defaultTextColor
                return L10n.cellularConnection

            default:
                connectionStatusColor = .errorColor
                return L10n.commonNotConnected
            }

        default:
            connectionStatusColor = .errorColor
            return L10n.commonNotConnected
        }
    }

    func checkConnectionAndServer(connection: CellularSessionStatus.Connection, server: CellularSessionStatus.Server) -> String {
        switch connection {
        case .connecting:
            switch server {
            case .connecting, .connected:
                connectionStatusColor = .defaultTextColor
                return L10n.cellularConnection

            default:
                connectionStatusColor = .errorColor
                return L10n.commonNotConnected
            }

        default:
            connectionStatusColor = .errorColor
            return L10n.commonNotConnected
        }
    }

    func checkBothConnection(droneConnection: CellularSessionStatus.Connection, remoteConnection: CellularSessionStatus.Connection) -> String? {
        switch droneConnection {
        case .connecting:
            switch remoteConnection {
            case .connecting, .established:
                connectionStatusColor = .defaultTextColor
                return L10n.cellularConnection

            default:
                connectionStatusColor = .errorColor
                return L10n.commonNotConnected
            }

        case .established:
            switch remoteConnection {
            case .established:
                connectionStatusColor = .highlightColor
                return nil

            default:
                connectionStatusColor = .errorColor
                return nil
            }

        default:
            connectionStatusColor = .errorColor
            return L10n.commonNotConnected
        }
    }

    func checkStatus(droneStatus: CellularSession, remoteStatus: CellularSession) -> String? {
        guard let droneStatus = droneStatus.status, let remoteStatus = remoteStatus.status else {
            connectionStatusColor = .errorColor
            return L10n.commonNotConnected
        }

        switch(droneStatus, remoteStatus) {
        case (.modem(let modem), .server(let server)):
            return checkModemAndServer(modem: modem, server: server)

        case (.modem(let modem), .connection(let connection)):
            return checkModemAndConnection(modem: modem, connection: connection)

        case (.sim(let sim), .server(let server)):
            return checkSimAndServer(sim: sim, server: server)

        case (.sim(let sim), .connection(let connection)):
            return checkSimAndConnection(sim: sim, connection: connection)

        case (.network(let network), .server(let server)):
            return checkNetworkAndServer(network: network, server: server)

        case (.network(let network), .connection(let connection)):
            return checkNetworkAndConnection(network: network, connection: connection)

        case (.server(let droneServer), .server(let remoteServer)):
            return checkBothServer(droneServer: droneServer, remoteServer: remoteServer)

        case (.server(let server), .connection(let connection)):
            return checkServerAndConnection(server: server, connection: connection)

        case (.connection(let connection), .server(let server)):
            return checkConnectionAndServer(connection: connection, server: server)

        case (.connection(let droneConnection), .connection(let remoteConnection)):
            return checkBothConnection(droneConnection: droneConnection, remoteConnection: remoteConnection)

        default:
            connectionStatusColor = .errorColor
            return L10n.commonNotConnected
        }
    }

    /// Publishes the operator name
    var operatorName: AnyPublisher<String?, Never> {
        cellularService.operatorNamePublisher
            .combineLatest(connectedRemoteControlHolder.remoteControlPublisher,
                           cellularSessionService.droneCellularSessionPublisher,
                           cellularSessionService.remoteCellularSessionPublisher)
            .combineLatest(networkService.networkReachable.removeDuplicates(), drone.removeDuplicates())
            .map { (arg0, reachable, drone) in
                let (operatorName, connectedRemote, droneCellularStatus, remoteCellularStatus) = arg0
                let remoteStatus = remoteCellularStatus?.status
                let droneStatus = droneCellularStatus?.status

                if connectedRemote == nil || drone == nil || !reachable {
                    return nil
                }

                guard case let .connection(connection) = droneStatus, connection == .established else { return nil }
                guard case let .connection(connection) = remoteStatus, connection == .established else { return nil }

                return operatorName
            }
            .eraseToAnyPublisher()
    }

    /// Publishes if pin button is enabled
    var isEnterPinEnabled: AnyPublisher<Bool, Never> {
        cellularService.cellularStatusPublisher
            .map { cellularStatus in
                return cellularStatus.shouldShowPinAction
            }
            .eraseToAnyPublisher()
    }

    var isForgetPinEnabled: AnyPublisher<Bool, Never> {
        connectedDroneHolder.dronePublisher
            .map { drone in
                return drone != nil
            }
            .eraseToAnyPublisher()
    }

    /// Publishes the connected remote controller
    var remoteControl: AnyPublisher<RemoteControl?, Never> {
        connectedRemoteControlHolder.remoteControlPublisher
            .map { return $0 }
            .eraseToAnyPublisher()
    }

    /// Publishes the connected drone
    var drone: AnyPublisher<Drone?, Never> {
        connectedDroneHolder.dronePublisher
            .map { drone in
                self.listenNetworkLink(drone: drone)
                return drone

            }
            .eraseToAnyPublisher()
    }

    /// Publishes the image for the controller asset
    var controllerImage: AnyPublisher<UIImage, Never> {
        remoteControl.map { remoteControl in
            if remoteControl == nil {
                return Asset.CellularPairing.ic4GControllerKo.image
            }

            return Asset.CellularPairing.ic4GControllerOk.image
        }
        .eraseToAnyPublisher()
    }

    /// Publishes the image for the left internet asset
    var leftInternetImage: AnyPublisher<UIImage, Never> {
        networkService.networkReachable
            .removeDuplicates()
            .combineLatest(remoteControl)
            .map { (reachable, remoteControl) in
                if remoteControl == nil || !reachable {
                    return Asset.CellularPairing.ic4GLeftInternetKo.image
                }

                return Asset.CellularPairing.ic4GLeftInternetOk.image
            }
            .eraseToAnyPublisher()
    }

    /// Publishes the image for the drone asset
    var droneImage: AnyPublisher<UIImage, Never> {
        drone
            .combineLatest(cellularStatus)
            .map { (drone, cellularStatus) in
                if drone == nil {
                    return Asset.CellularPairing.ic4GDroneStatus.image
                }

                if cellularStatus == .simLocked || cellularStatus == .simBlocked || cellularStatus == .simNotDetected {
                    return Asset.CellularPairing.ic4GDroneStatusKo.image
                }

                return Asset.CellularPairing.ic4GDroneStatusOk.image
            }
            .eraseToAnyPublisher()
    }

    /// Publishes the image for the right internet asset
    var rightInternetImage: AnyPublisher<UIImage, Never> {
        drone
            .combineLatest(cellularStatus)
            .map { (drone, cellularStatus) in
                if drone == nil {
                    return Asset.CellularPairing.ic4GRightInternet.image
                }

                if cellularStatus == .simLocked || cellularStatus == .simBlocked || cellularStatus == .simNotDetected {
                    return Asset.CellularPairing.ic4GRightInternetKo.image
                }

                if cellularStatus.isStatusError {
                    return Asset.CellularPairing.ic4GRightInternetKo.image
                }

                return Asset.CellularPairing.ic4GRightInternetOk.image
            }
            .eraseToAnyPublisher()
    }

    /// Publishes the image for the bottom left branch asset
    var bottomLeftBranchImage: AnyPublisher<UIImage, Never> {
        remoteControl
            .combineLatest(networkService.networkReachable.removeDuplicates())
            .map { (remoteControl, reachable) in
                if remoteControl == nil || reachable == false {
                    return Asset.CellularPairing.ic4GBottomLeftBranchKo.image
                }

                return Asset.CellularPairing.ic4GBottomLeftBranchOk.image
            }
            .eraseToAnyPublisher()
    }

    /// Publishes the image for the top left branch asset
    var topLeftBranchImage: AnyPublisher<UIImage, Never> {
        remoteControl
            .combineLatest(networkService.networkReachable.removeDuplicates(),
                           cellularSessionService.remoteCellularSessionPublisher,
                           cellularSessionService.droneCellularSessionPublisher)
            .map { (remoteControl, reachable, remoteCellularStatus, droneCellularStatus) in
                let remoteStatus = remoteCellularStatus?.status
                let droneStatus = droneCellularStatus?.status

                if remoteControl == nil || !reachable {
                    return Asset.CellularPairing.ic4GTopLeftBranchKo.image
                }

                guard case let .connection(connection) = droneStatus,
                        connection == .established else {
                    return Asset.CellularPairing.ic4GTopLeftBranchKo.image
                }
                guard case let .connection(connection) = remoteStatus,
                        connection == .established else {
                    return Asset.CellularPairing.ic4GTopLeftBranchKo.image
                }

                return Asset.CellularPairing.ic4GTopLeftBranchOk.image
            }
            .eraseToAnyPublisher()
    }

    var controllerStatus: AnyPublisher<String?, Never> {
        remoteControl
            .combineLatest(networkService.networkReachable.removeDuplicates(),
                           cellularSessionService.currentRemoteStatusPublisher)
            .map { (remoteControl, reachable, remoteCellularStatus) in
                if remoteControl == nil {
                    return L10n.controllerNotConnected
                }

                if !reachable {
                    return L10n.cellularErrorNoInternetMessage
                }

                return remoteCellularStatus
            }
            .eraseToAnyPublisher()
    }

    /// Publishes the image for the bottom right branch asset
    var bottomRightBranchImage: AnyPublisher<UIImage, Never> {
        drone
            .combineLatest(cellularStatus)
            .map { (drone, cellularStatus) in
                if drone == nil {
                    return Asset.CellularPairing.ic4GBottomRightBranch.image
                }

                if cellularStatus == .simLocked
                    || cellularStatus == .simBlocked
                    || cellularStatus == .simNotDetected
                    || cellularStatus.isStatusError {
                    return Asset.CellularPairing.ic4GBottomRightBranchKo.image
                }

                return Asset.CellularPairing.ic4GBottomRightBranchOk.image
            }
            .eraseToAnyPublisher()
    }

    /// Publishes the image for the top right branch image
    var topRightBranchImage: AnyPublisher<UIImage, Never> {
        drone
            .combineLatest(cellularStatus,
                           cellularSessionService.droneCellularSessionPublisher,
                           cellularSessionService.remoteCellularSessionPublisher)
            .combineLatest(networkService.networkReachable.removeDuplicates())
            .map { (arg0, reachable) in
                let (drone, cellularStatus, droneCellularStatus, remoteCellularStatus) = arg0
                let droneStatus = droneCellularStatus?.status
                let remoteStatus = remoteCellularStatus?.status

                if drone == nil {
                    return Asset.CellularPairing.ic4GTopRightBranch.image
                }

                if cellularStatus == .simLocked
                    || cellularStatus == .simBlocked
                    || cellularStatus == .simNotDetected
                    || cellularStatus.isStatusError {
                    return Asset.CellularPairing.ic4GTopRightBranchKo.image
                }

                if !reachable {
                    return Asset.CellularPairing.ic4GTopRightBranchKo.image
                }

                guard case let .connection(connection) = droneStatus,
                        connection == .established else {
                    return Asset.CellularPairing.ic4GTopRightBranchKo.image
                }
                guard case let .connection(connection) = remoteStatus,
                        connection == .established else {
                    return Asset.CellularPairing.ic4GTopRightBranchKo.image
                }

                return Asset.CellularPairing.ic4GTopRightBranchOk.image
            }
            .eraseToAnyPublisher()
    }

    /// Publishes the image for cellular asset
    var cellularImage: AnyPublisher<UIImage, Never> {
        remoteControl
            .combineLatest(drone, cellularStatus, networkService.networkReachable.removeDuplicates())
            .combineLatest(cellularSessionService.droneCellularSessionPublisher,
                           $cellularStrength,
                           cellularSessionService.remoteCellularSessionPublisher)
            .map { (arg0, droneCellularStatus, _, remoteCellularStatus) in
                let (remoteControl, drone, cellularStatus, reachable) = arg0
                let droneStatus = droneCellularStatus?.status
                let remoteStatus = remoteCellularStatus?.status

                if remoteControl == nil || drone == nil || !reachable || cellularStatus.isStatusError ||
                    cellularStatus == .simLocked || cellularStatus == .simBlocked || cellularStatus == .simNotDetected {
                    return Asset.CellularPairing.ic4GStatusKO.image
                }

                guard case let .connection(connection) = droneStatus, connection == .established else { return Asset.CellularPairing.ic4GStatusKO.image }
                guard case let .connection(connection) = remoteStatus, connection == .established else { return Asset.CellularPairing.ic4GStatusKO.image }

                return Asset.CellularPairing.ic4GStatusOK.image
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Functions

    /// Dismisses the current view
    func dismissView() {
        coordinator?.dismiss()
    }

    /// Dismisses the current view and shows the cellular support screen
    func showSupport() {
        coordinator?.dismiss {
            self.coordinator?.startCellularSupport()
        }
    }

    /// Dissmisses the current view and shows the pin access modal
    func showPinCode() {
        coordinator?.dismiss {
            self.coordinator?.displayCellularPinCode()
        }
    }

    /// Reset the pin code
    func forgetPin() {
        coordinator?.displayAlertReboot {
            ULog.i(.tag, "Forget PIN")
            self.unpairAllUser()
        }
    }
}

private extension DroneDetailCellularViewModel {

    /// Unpairs all users from the drone
    func unpairAllUser() {
        cellularPairingService.startUnpairProcessRequest()
    }

    /// Observes the controller's cellular link
    /// - Parameter remoteControl: The connected remote controller
    func listenRemoteCellularLink(remoteControl: RemoteControl) {
        remoteCellularLinkRef = remoteControl.getInstrument(Instruments.cellularLink) { [unowned self] cellularLink in
            remoteCellularLink = cellularLink
        }
    }

    /// Observes the drone's network link status and cellular strength
    /// - Parameter drone: The connected drone
    func listenNetworkLink(drone: Drone?) {
        networkControlRef = drone?.getPeripheral(Peripherals.networkControl) { [unowned self] networkControl in
            let cellularLink = networkControl?.links.first(where: { $0.type == .cellular })
            droneCellularLink = cellularLink
            let cellStrength = drone?.getPeripheral(Peripherals.networkControl)?.cellularStrength
            cellularStrength = cellStrength
        }
    }

    /// Listen flying indicators instrument.
    ///
    /// - Parameter drone: the current drone
    func listenFlyingState(drone: Drone?) {
        guard let drone = drone else { return }

        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [unowned self] flyingIndicator in
            guard let flyingIndicator = flyingIndicator else {
                isFlying.value = false
                return
            }
            isFlying.value =  flyingIndicator.state != .landed && flyingIndicator.state != .emergency
        }
    }
}
