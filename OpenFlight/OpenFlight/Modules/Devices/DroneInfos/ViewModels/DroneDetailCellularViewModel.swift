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

final class DroneDetailCellularViewModel {

    // MARK: - Published Variables

    @Published private(set) var remoteCellularStatus: CellularLinkStatus?
    @Published private(set) var networkLinkStatus: NetworkControlLinkInfo?
    @Published private(set) var cellularStrength: CellularStrength?
    @Published private(set) var remoteError: String?
    private(set) var isFlying = CurrentValueSubject<Bool, Never>(false)

    // MARK: - Variables

    private weak var coordinator: DroneCoordinator?
    private var currentDroneHolder: CurrentDroneHolder
    private var cellularPairingService: CellularPairingService
    private var connectedRemoteControlHolder: ConnectedRemoteControlHolder
    private var connectedDroneHolder: ConnectedDroneHolder
    private unowned let networkService: NetworkService
    private var cellularService: CellularService
    private var networkControlRef: Ref<NetworkControl>?
    private var remoteCellularLinkStatus: Ref<CellularLinkStatus>?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(coordinator: DroneCoordinator,
         currentDroneHolder: CurrentDroneHolder,
         cellularPairingService: CellularPairingService,
         connectedRemoteControlHolder: ConnectedRemoteControlHolder,
         connectedDroneHolder: ConnectedDroneHolder,
         networkService: NetworkService,
         cellularService: CellularService) {
        self.coordinator = coordinator
        self.currentDroneHolder = currentDroneHolder
        self.cellularPairingService = cellularPairingService
        self.connectedRemoteControlHolder = connectedRemoteControlHolder
        self.connectedDroneHolder = connectedDroneHolder
        self.networkService = networkService
        self.cellularService = cellularService

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
    }

    // MARK: - AnyPublisher

    var cellularStatusString: AnyPublisher<String?, Never> {
        cellularService.cellularStatusPublisher
            .combineLatest(remoteControl,
                           networkService.networkReachable.removeDuplicates(),
                           drone)
            .map { (cellularStatus, remoteControl, reachable, drone) in
                if remoteControl == nil || reachable == false || drone == nil {
                    return nil
                }

                return cellularStatus.cellularDetailsTitle
            }
            .eraseToAnyPublisher()
    }

    var cellularStatusColor: AnyPublisher<ColorName, Never> {
        cellularService.cellularStatusPublisher
            .map { (cellularStatus) in
                return cellularStatus.detailsTextColor
            }
            .eraseToAnyPublisher()

    }

    /// Publishes the cellular status of the drone
    var cellularStatus: AnyPublisher<DetailsCellularStatus, Never> {
        cellularService.cellularStatusPublisher
            .map { return $0 }
            .eraseToAnyPublisher()
    }

    /// Publishes the operator name
    var operatorName: AnyPublisher<String?, Never> {
        cellularService.operatorNamePublisher
            .combineLatest(connectedRemoteControlHolder.remoteControlPublisher, $remoteCellularStatus, $networkLinkStatus)
            .combineLatest(networkService.networkReachable.removeDuplicates(), drone.removeDuplicates())
            .map { (arg0, reachable, drone) in
                let (operatorName, connectedRemote, remoteCellularStatus, networkLinkStatus) = arg0
                if connectedRemote == nil || drone == nil || remoteCellularStatus?.status != .running || networkLinkStatus?.status != .running || !reachable {
                    return nil
                }

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
            .combineLatest(networkService.networkReachable.removeDuplicates(), $remoteCellularStatus, $networkLinkStatus)
            .map { (remoteControl, reachable, remoteCellularStatus, networkLinkStatus) in
                if remoteControl == nil || !reachable || remoteCellularStatus?.status != .running {
                    return Asset.CellularPairing.ic4GTopLeftBranchKo.image
                }

                if networkLinkStatus?.status == .running {
                    return Asset.CellularPairing.ic4GTopLeftBranchOk.image
                }

                return Asset.CellularPairing.ic4GTopLeftBranchOk.image
            }
            .eraseToAnyPublisher()
    }

    /// Publishes the error if any for the controller side
    var controllerError: AnyPublisher<String?, Never> {
        remoteControl
            .combineLatest(networkService.networkReachable.removeDuplicates(), $remoteCellularStatus)
            .map { (remoteControl, reachable, remoteCellularStatus) in
                if remoteControl == nil {
                    return L10n.controllerNotConnected
                }

                if !reachable {
                    return L10n.cellularErrorNoInternetMessage
                }

                switch remoteCellularStatus?.status {
                case .error(error: let error):
                    switch error {
                    case .dns:
                        return L10n.cellularConnectionControllerDnsError

                    case .connect:
                        return L10n.cellularConnectionControllerConnectError

                    case .authentication:
                        return L10n.cellularConnectionControllerAuthenticationError

                    case .communicationLink:
                        return L10n.cellularConnectionControllerCommunicationLinkError

                    case .timeout:
                        return L10n.cellularConnectionControllerTimeoutError

                    case .invite:
                        return L10n.cellularConnectionControllerInviteError

                    default:
                        return nil
                    }

                default:
                    return nil
                }
            }
            .eraseToAnyPublisher()
    }

    /// Publishes the error if any for the drone side
    var droneError: AnyPublisher<String?, Never> {
        $networkLinkStatus
            .map { networkLinkStatus in
                guard let linkError = networkLinkStatus?.error else { return nil }
                switch linkError {
                case .dns:
                    return L10n.cellularConnectionDroneDnsError

                case .connect:
                    return L10n.cellularConnectionDroneConnectError

                case .authentication:
                    return L10n.cellularConnectionDroneAuthenticationError

                case .publish:
                    return L10n.cellularConnectionDronePublishError

                case .communicationLink:
                    return L10n.cellularConnectionDroneCommunicationLinkError

                case .timeout:
                    return L10n.cellularConnectionDroneTimeoutError

                default:
                    return nil
                }
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
            .combineLatest(cellularStatus, $networkLinkStatus, $remoteCellularStatus)
            .combineLatest(networkService.networkReachable.removeDuplicates())
            .map { (arg0, reachable) in
                let (drone, cellularStatus, networkLinkStatus, remoteCellularLinkStatus) = arg0
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

                if networkLinkStatus?.status != .running || remoteCellularLinkStatus?.status != .running {
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
            .combineLatest($networkLinkStatus, $cellularStrength, $remoteCellularStatus)
            .map { (arg0, networkLinkStatus, _, remoteCellularStatus) in
                let (remoteControl, drone, cellularStatus, reachable) = arg0
                if remoteControl == nil || drone == nil || !reachable || cellularStatus.isStatusError ||
                    cellularStatus == .simLocked || cellularStatus == .simBlocked || cellularStatus == .simNotDetected {
                    return Asset.CellularPairing.ic4GStatusKO.image
                }

                if remoteCellularStatus?.status != .running || networkLinkStatus?.status != .running {
                    return Asset.CellularPairing.ic4GStatusKO.image
                }

                return Asset.CellularPairing.ic4GStatusOK.image
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Functions

    /// Dismisses the current view
    func dismissView() {
        coordinator?.dismiss()
    }

    /// Dismisses the current view and shows the cellular debug screen
    func showDebug() {
        coordinator?.dismiss {
            self.coordinator?.displayCellularDebug()
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
            ULog.d(.tag, "Forget PIN")
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
        remoteCellularLinkStatus = remoteControl.getInstrument(Instruments.cellularLinkStatus) { [unowned self] remoteCellular in
            remoteCellularStatus = remoteCellular
        }
    }

    /// Observes the drone's network link status and cellular strength
    /// - Parameter drone: The connected drone
    func listenNetworkLink(drone: Drone?) {
        networkControlRef = drone?.getPeripheral(Peripherals.networkControl) { [unowned self] networkControl in
            let cellularLink = networkControl?.links.first(where: { $0.type == .cellular })
            networkLinkStatus = cellularLink
            let cellularStrength = drone?.getPeripheral(Peripherals.networkControl)?.cellularStrength
            self.cellularStrength = cellularStrength
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
