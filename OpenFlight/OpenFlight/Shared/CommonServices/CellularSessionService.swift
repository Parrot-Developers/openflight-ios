//    Copyright (C) 2022 Parrot Drones SAS
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

public protocol CellularSessionService: AnyObject {

    /// The current cellular session for the remote
    var remoteCellularSessionPublisher: AnyPublisher<CellularSession?, Never> { get }

    /// The current cellular session for the drone
    var droneCellularSessionPublisher: AnyPublisher<CellularSession?, Never> { get }

    /// The current cellular status for the drone
    var currentDroneStatusPublisher: AnyPublisher<String?, Never> { get }

    /// The current cellular status for the drone
    var currentRemoteStatusPublisher: AnyPublisher<String?, Never> { get }
}

final class CellularSessionServiceImpl {
    // MARK: Private properties

    private var registrationDeniedCount = 0
    private var activationDeniedCount = 0
    private var droneConnectionErrorCount = 0
    private var remoteConnectionErrorCount = 0

    private var droneCellularSessionRef: Ref<CellularSession>?
    private var remoteCellularSessionRef: Ref<CellularSession>?

    private var connectedDroneHolder: ConnectedDroneHolder
    private var connectedRemoteControlHolder: ConnectedRemoteControlHolder
    private var cellularService: CellularService
    private var cancellables = Set<AnyCancellable>()

    private var droneCellularSessionSubject = CurrentValueSubject<CellularSession?, Never>(nil)
    private var remoteCellularSessionSubject = CurrentValueSubject<CellularSession?, Never>(nil)
    private var currentDroneStatus = CurrentValueSubject<String?, Never>(nil)
    private var currentRemoteStatus = CurrentValueSubject<String?, Never>(nil)

    init(connectedDroneHolder: ConnectedDroneHolder, connectedRemoteControlHolder: ConnectedRemoteControlHolder, cellularService: CellularService) {
        self.connectedDroneHolder = connectedDroneHolder
        self.connectedRemoteControlHolder = connectedRemoteControlHolder
        self.cellularService = cellularService

        connectedDroneHolder.dronePublisher
            .sink { [unowned self] drone in
                listenDroneCellularSession(drone: drone)
            }
            .store(in: &cancellables)

        connectedRemoteControlHolder.remoteControlPublisher
            .sink { [unowned self] remoteControl in
                listenRemoteCellularSession(remote: remoteControl)
            }
            .store(in: &cancellables)
    }
}

extension CellularSessionServiceImpl: CellularSessionService {
    var droneCellularSessionPublisher: AnyPublisher<CellularSession?, Never> { droneCellularSessionSubject.eraseToAnyPublisher() }
    var remoteCellularSessionPublisher: AnyPublisher<CellularSession?, Never> { remoteCellularSessionSubject.eraseToAnyPublisher() }
    var currentDroneStatusPublisher: AnyPublisher<String?, Never> { currentDroneStatus.eraseToAnyPublisher() }
    var currentRemoteStatusPublisher: AnyPublisher<String?, Never> { currentRemoteStatus.eraseToAnyPublisher() }
}

private extension CellularSessionServiceImpl {

    func listenDroneCellularSession(drone: Drone?) {
        droneCellularSessionRef = drone?.getInstrument(Instruments.cellularSession) { [unowned self] cellularSession in
            updateCurrentDroneStatus(cellularSession: cellularSession)
            droneCellularSessionSubject.send(cellularSession)
        }
    }

    func listenRemoteCellularSession(remote: RemoteControl?) {
        remoteCellularSessionRef = remote?.getInstrument(Instruments.cellularSession) { [unowned self] cellularSession in
            updateCurrentRemoteStatus(cellularSession: cellularSession)
            remoteCellularSessionSubject.send(cellularSession)
        }
    }

    // MARK: - Drone status

    /// Updates the current drone status
    /// - Parameter cellularSession: The current cellular session's value
    func updateCurrentDroneStatus(cellularSession: CellularSession?) {
        guard let status = cellularSession?.status else {
            currentDroneStatus.send(nil)
            return
        }

        switch status {
        case .unknown:
            currentDroneStatus.send(L10n.statusUnknown)
        case .modem(let modem):
            processModem(modem: modem)
        case .sim(let sim):
            processSim(sim: sim)
        case .network(let network):
            processNetwork(network: network)
        case .server(let server):
            processDroneServer(server: server)
        case .connection(let connection):
            processDroneConnection(connection: connection)
        }
    }

    func processModem(modem: CellularSessionStatus.Modem) {
        switch modem {
        case .off:
            return
        case .offline:
            currentDroneStatus.send(L10n.droneModemStatusOffline)
        case .updating:
            currentDroneStatus.send(L10n.droneModemStatusUpdating)
        case .online:
            currentDroneStatus.send(L10n.droneModemStatusOnline)
        case .error:
            currentDroneStatus.send(L10n.droneModemStatusError)
        }
    }

    func processSim(sim: CellularSessionStatus.Sim) {
        switch sim {
        case .locked:
            currentDroneStatus.send(cellularService.cellularStatusValue == .simBlocked ? L10n.cellularDetailsSimBlocked : L10n.droneSimStatusLocked)
        case .ready:
            currentDroneStatus.send(L10n.droneSimStatusReady)
        case .absent:
            currentDroneStatus.send(L10n.droneSimStatusAbsent)
        case .error:
            currentDroneStatus.send(L10n.droneSimStatusError)
        }
    }

    func processNetwork(network: CellularSessionStatus.Network) {
        switch network {
        case .searching:
            registrationDeniedCount = 0
            activationDeniedCount = 0
            currentDroneStatus.send(L10n.droneNetworkStatusSearching)
        case .home:
            registrationDeniedCount = 0
            activationDeniedCount = 0
            currentDroneStatus.send(L10n.droneNetworkStatusHome)
        case .roaming:
            registrationDeniedCount = 0
            activationDeniedCount = 0
            currentDroneStatus.send(L10n.droneNetworkStatusRoaming)
        case .registrationDenied:
            activationDeniedCount = 0
            if registrationDeniedCount == 3 {
                currentDroneStatus.send(L10n.droneNetworkStatusRegistrationDenied)
            } else {
                registrationDeniedCount += 1
            }
        case .activationDenied:
            registrationDeniedCount = 0
            if activationDeniedCount == 3 {
                currentDroneStatus.send(L10n.droneNetworkStatusActivationDenied)
            } else {
                activationDeniedCount += 1
            }
        }
    }

    func processDroneServer(server: CellularSessionStatus.Server) {
        switch server {
        case .waitApcToken:
            return
        case .connecting:
            currentDroneStatus.send(L10n.serverStatusConnecting)
        case .connected:
            currentDroneStatus.send(L10n.serverStatusConnected)
        case .unreachableDns, .unreachableConnect:
            currentDroneStatus.send(L10n.serverStatusRestricted)
        case .unreachableAuth:
            currentDroneStatus.send(L10n.serverStatusAuthentication)
        }
    }

    func processDroneConnection(connection: CellularSessionStatus.Connection) {
        switch connection {
        case .offline:
            droneConnectionErrorCount = 0
            currentDroneStatus.send(L10n.connectionStatusOffline)
        case .connecting:
            droneConnectionErrorCount = 0
            currentDroneStatus.send(L10n.droneConnectionStatusConnecting)
        case .established:
            droneConnectionErrorCount = 0
            currentDroneStatus.send(L10n.connectionStatusEstablished)
        case .error:
            if droneConnectionErrorCount == 3 {
                currentDroneStatus.send(L10n.connectionStatusError)
            } else {
                droneConnectionErrorCount += 1
            }
        case .errorCommLink:
            droneConnectionErrorCount = 0
            currentDroneStatus.send(L10n.connectionStatusErrorCommlink)
        case .errorTimeout:
            droneConnectionErrorCount = 0
            currentDroneStatus.send(L10n.connectionStatusErrorTimeout)
        case .errorMismatch:
            droneConnectionErrorCount = 0
            currentDroneStatus.send(L10n.connectionStatusErrorMismatch)
        }
    }

    // MARK: - Remote status

    func processRemoteServer(server: CellularSessionStatus.Server) {
        switch server {
        case .waitApcToken:
            currentRemoteStatus.send(L10n.remoteServerStatusApcToken)
        case .connecting:
            currentRemoteStatus.send(L10n.serverStatusConnecting)
        case .connected:
            currentRemoteStatus.send(L10n.serverStatusConnected)
        case .unreachableDns, .unreachableConnect:
            currentRemoteStatus.send(L10n.serverStatusRestricted)
        case .unreachableAuth:
            currentRemoteStatus.send(L10n.serverStatusAuthentication)
        }
    }

    func processRemoteConnection(connection: CellularSessionStatus.Connection) {
        switch connection {
        case .offline:
            remoteConnectionErrorCount = 0
            currentRemoteStatus.send(L10n.connectionStatusOffline)
        case .connecting:
            remoteConnectionErrorCount = 0
            return
        case .established:
            remoteConnectionErrorCount = 0
            currentRemoteStatus.send(L10n.connectionStatusEstablished)
        case .error:
            if remoteConnectionErrorCount == 3 {
                currentRemoteStatus.send(L10n.connectionStatusError)
            } else {
                remoteConnectionErrorCount += 1
            }

        case .errorCommLink:
            remoteConnectionErrorCount = 0
            currentRemoteStatus.send(L10n.connectionStatusErrorCommlink)
        case .errorTimeout:
            remoteConnectionErrorCount = 0
            currentRemoteStatus.send(L10n.connectionStatusErrorTimeout)
        case .errorMismatch:
            remoteConnectionErrorCount = 0
            currentRemoteStatus.send(L10n.connectionStatusErrorMismatch)
        }
    }

    /// Updates the current remote status
    /// - Parameter cellularSession: The current cellular session's value
    func updateCurrentRemoteStatus(cellularSession: CellularSession?) {
        guard let status = cellularSession?.status else {
            currentRemoteStatus.send(nil)
            return
        }

        switch status {
        case .unknown:
            currentRemoteStatus.send(L10n.statusUnknown)
        case .server(let server):
            processRemoteServer(server: server)
        case .connection(let connection):
            processRemoteConnection(connection: connection)
        default:
            return
        }
    }
}
