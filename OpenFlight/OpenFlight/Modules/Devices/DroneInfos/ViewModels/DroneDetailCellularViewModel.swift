//
//  Copyright (C) 2021 Parrot Drones SAS.
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
import Reachability

final class DroneDetailCellularViewModel {

    // MARK: - Published Variables

    @Published private(set) var remoteCellularStatus: CellularLinkStatus?
    @Published private(set) var networkLinkStatus: NetworkControlLinkInfo?
    @Published private(set) var reachable: Bool = false
    @Published private(set) var cellularStrength: CellularStrength?
    @Published private(set) var remoteError: String?

    // MARK: - Variables

    private weak var coordinator: DroneCoordinator?
    private var currentDroneHolder: CurrentDroneHolder
    private var cellularPairingService: CellularPairingService
    private var connectedRemoteControlHolder: ConnectedRemoteControlHolder
    private var connectedDroneHolder: ConnectedDroneHolder
    private var droneConnectionStateRef: Ref<DeviceState>?
    private var remoteConnectionStateRef: Ref<DeviceState>?
    private var networkControlRef: Ref<NetworkControl>?
    private var remoteCellularLinkStatus: Ref<CellularLinkStatus>?
    private var reachability: Reachability?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(coordinator: DroneCoordinator,
         currentDroneHolder: CurrentDroneHolder,
         cellularPairingService: CellularPairingService,
         connectedRemoteControlHolder: ConnectedRemoteControlHolder,
         connectedDroneHolder: ConnectedDroneHolder) {
        self.coordinator = coordinator
        self.currentDroneHolder = currentDroneHolder
        self.cellularPairingService = cellularPairingService
        self.connectedRemoteControlHolder = connectedRemoteControlHolder
        self.connectedDroneHolder = connectedDroneHolder
        listenReachability()

        connectedRemoteControlHolder.remoteControlPublisher
            .compactMap { $0 }
            .sink { [unowned self] remoteControl in
                listenRemoteCellularLink(remoteControl: remoteControl)
            }
            .store(in: &cancellables)
    }

    // MARK: - AnyPublisher

    /// Publishes the cellular status of the drone
    var cellularStatus: AnyPublisher<DetailsCellularStatus, Never> {
        cellularPairingService.cellularStatusPublisher
            .map { return $0 }
            .eraseToAnyPublisher()
    }

    /// Publishes the operator name
    var operatorName: AnyPublisher<String?, Never> {
        cellularPairingService.operatorNamePublisher
            .map { (operatorName) in
                return operatorName
            }
            .eraseToAnyPublisher()
    }

    /// Publishes if pin button is enabled
    var isEnterPinEnabled: AnyPublisher<Bool, Never> {
        cellularPairingService.cellularStatusPublisher
            .map { cellularStatus in
                return cellularStatus.shouldShowPinAction
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
        $reachable
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
            .combineLatest($reachable)
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
            .combineLatest($reachable, $remoteCellularStatus, $networkLinkStatus)
            .map { (remoteControl, reachable, remoteCellularStatus, networkLinkStatus) in
                if networkLinkStatus?.status == .running {
                    return Asset.CellularPairing.ic4GTopLeftBranchOk.image
                }

                if remoteControl == nil || !reachable || remoteCellularStatus?.status != .running {
                    return Asset.CellularPairing.ic4GTopLeftBranchKo.image
                }

                return Asset.CellularPairing.ic4GTopLeftBranchOk.image
            }
            .eraseToAnyPublisher()
    }

    /// Publishes the error if any for the controller side
    var controllerError: AnyPublisher<String?, Never> {
        remoteControl
            .combineLatest($reachable, $remoteCellularStatus)
            .map { (remoteControl, reachable, remoteCellularStatus) in
                if remoteControl == nil {
                    return L10n.controllerNotConnected
                }

                if !reachable {
                    return L10n.cellularErrorNoInternetMessage
                }

                if remoteCellularStatus?.status != .running {
                    guard case .error = remoteCellularStatus?.status else { return nil }
                    return L10n.controllerErrorParrotConnectionFailed
                }

                return nil
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
            .combineLatest(cellularStatus, $networkLinkStatus)
            .map { (drone, cellularStatus, networkLinkStatus) in
                if drone == nil {
                    return Asset.CellularPairing.ic4GTopRightBranch.image
                }

                if cellularStatus == .simLocked
                    || cellularStatus == .simBlocked
                    || cellularStatus == .simNotDetected
                    || cellularStatus.isStatusError {
                    return Asset.CellularPairing.ic4GTopRightBranchKo.image
                }

                if networkLinkStatus?.status != .running {
                    return Asset.CellularPairing.ic4GTopRightBranchKo.image
                }

                return Asset.CellularPairing.ic4GTopRightBranchOk.image
            }
            .eraseToAnyPublisher()
    }

    /// Publishes the image for cellular asset
    var cellularImage: AnyPublisher<UIImage, Never> {
        remoteControl
            .combineLatest(drone, cellularStatus, $reachable)
            .combineLatest($networkLinkStatus, $cellularStrength, $remoteCellularStatus)
            .map { [unowned self] (arg0, networkLinkStatus, cellularStrength, remoteCellularStatus) in
                let (remoteControl, drone, cellularStatus, reachable) = arg0
                if remoteControl == nil || drone == nil || !reachable || cellularStatus.isStatusError ||
                    cellularStatus == .simLocked || cellularStatus == .simBlocked || cellularStatus == .simNotDetected {
                    return Asset.CellularPairing.ic4GStatus0.image
                }

                if remoteCellularStatus?.status != .running || networkLinkStatus?.status != .running {
                    return Asset.CellularPairing.ic4GStatus0.image
                }

                return imageQualityFor4G(cellularStrength: cellularStrength)
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
            self.unpairAllUser()
            let cellular = self.connectedDroneHolder.drone?.getPeripheral(Peripherals.cellular)
            _ = cellular?.resetSettings()
        }
    }
}

private extension DroneDetailCellularViewModel {

    /// Unpairs all users from the drone
    func unpairAllUser() {
         cellularPairingService.startUnpairProcessRequest()
    }

    /// Selects an image for the cellular asset
    /// - Parameter cellularStrength: The cellular strength of the drone
    /// - Returns: An image representing the current strength
    func imageQualityFor4G(cellularStrength: CellularStrength?) -> UIImage {
        guard let cellularStrength = cellularStrength else {
            return Asset.CellularPairing.ic4GStatus0.image
        }

        switch cellularStrength {
        case .ko0On4:
            return Asset.CellularPairing.ic4GStatus0.image
        case .ok1On4:
            return Asset.CellularPairing.ic4GStatus1.image
        case .ok2On4:
            return Asset.CellularPairing.ic4GStatus2.image
        case .ok3On4:
            return Asset.CellularPairing.ic4GStatus3.image
        case .ok4On4:
            return Asset.CellularPairing.ic4GStatus4.image
        default:
            return Asset.CellularPairing.ic4GStatus0.image
        }
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

    /// Observes network reachability.
    func listenReachability() {
        do {
            try reachability = Reachability()
            try reachability?.startNotifier()
            reachability?.whenReachable = { [unowned self] _ in
                reachable = true
            }
        } catch {
            // Nothing to do here
        }

        reachability?.whenUnreachable = {[unowned self] _ in
            reachable = false
        }
    }
}
