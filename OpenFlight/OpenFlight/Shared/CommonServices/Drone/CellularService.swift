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
import GroundSdk
import Combine

private extension ULogTag {
    static let tag = ULogTag(name: "CellularService")
}

public protocol CellularService: AnyObject {
    var cellularStatusPublisher: AnyPublisher<DetailsCellularStatus, Never> { get }
    var operatorNamePublisher: AnyPublisher<String?, Never> { get }
    var isCellularAvailablePublisher: AnyPublisher<Bool, Never> { get }
    var isCellularAvailable: Bool { get }
    var cellularStatusValue: DetailsCellularStatus { get }
}

final class CellularServiceImpl {

    private var cellularRef: Ref<Cellular>?
    private var networkControlRef: Ref<NetworkControl>?

    private var connectedDroneHolder: ConnectedDroneHolder

    private var cellularStatusSubject = CurrentValueSubject<DetailsCellularStatus, Never>(.noState)
    private var operatorNameSubject = CurrentValueSubject<String?, Never>(nil)
    private var isCellularAvailableSubject = CurrentValueSubject<Bool, Never>(false)

    private var cancellables = Set<AnyCancellable>()

    init(connectedDroneHolder: ConnectedDroneHolder) {
        self.connectedDroneHolder = connectedDroneHolder

        connectedDroneHolder.dronePublisher
            .sink { [unowned self] drone in
                listenCellular(drone)
                listenNetworkControl(drone)
            }
            .store(in: &cancellables)

        cellularStatusPublisher
            .removeDuplicates()
            .sink { cellularStatus in
                ULog.i(.tag, "Cellular status: \(cellularStatus.cellularDetailsTitle ?? "No value")")
            }
            .store(in: &cancellables)
    }

    /// Updates cellular state.
    func updateCellularStatus(drone: Drone?) {
        var status: DetailsCellularStatus = .noState
        var operatorName = ""

        guard let cellular = drone?.getPeripheral(Peripherals.cellular),
              drone?.isConnected == true else {
                  updateCellularSubject(with: status)
                  return
              }

        // Update the current cellular state.
        let networkControl = drone?.getPeripheral(Peripherals.networkControl)
        let cellularLink = networkControl?.links.first(where: { $0.type == .cellular })
        let isDronePaired: Bool = drone?.isAlreadyPaired == true

        if cellularLink?.status == .running,
           isDronePaired {
            status = .cellularConnected
            operatorName = cellular.operator
        } else if cellular.mode.value == .nodata {
            status = .noData
        } else if cellular.simStatus == .absent {
            status = .simNotDetected
        } else if cellular.simStatus == .unknown {
            status = .simNotRecognized
        } else if cellular.simStatus == .initializing {
            status = .initializing
        } else if cellular.simStatus == .locked {
            if cellular.pinRemainingTries == 0 {
                status = .simBlocked
            } else {
                status = .simLocked
            }
        } else if cellularLink?.status == .error || cellularLink?.error != nil {
            status = .connectionFailed
        } else if cellular.modemStatus != .online {
            status = .modemStatusOff
        } else if cellular.registrationStatus == .notRegistered {
            status = .notRegistered
        } else if cellular.networkStatus == .error {
            status = .networkStatusError
        } else if cellular.networkStatus == .denied {
            status = .networkStatusDenied
        } else if cellular.isAvailable {
            status = .cellularConnecting
            operatorName = cellular.operator
        } else if !isDronePaired {
            status = .userNotPaired
        } else {
            status = .noState
        }

        updateCellularSubject(with: status)
        updateOperatorName(operatorName: operatorName)
    }

    /// Starts watcher for Cellular.
    func listenCellular(_ drone: Drone?) {
        cellularRef = drone?.getPeripheral(Peripherals.cellular) { [unowned self] cellular in
            updateCellularStatus(drone: drone)
            updateCellularAvailability(with: cellular)
        }
    }

    /// Starts watcher for drone network control.
    func listenNetworkControl(_ drone: Drone?) {
        networkControlRef = drone?.getPeripheral(Peripherals.networkControl) { [unowned self] _ in
            updateCellularStatus(drone: drone)
        }
    }

    /// Updates cellular status.
    ///
    /// - Parameters:
    ///     - cellularStatus: 4G status to update
    func updateCellularSubject(with cellularStatus: DetailsCellularStatus) {
        cellularStatusSubject.send(cellularStatus)
    }

    /// Updates operator name.
    ///
    /// - Parameters:
    ///     - operatorName: name of the operator
    func updateOperatorName(operatorName: String) {
        operatorNameSubject.send(operatorName)
    }

    /// Updates cellular availability state.
    ///
    /// - Parameters:
    ///     - cellular: current cellular reference's value
    func updateCellularAvailability(with cellular: Cellular?) {
        isCellularAvailableSubject.send(cellular?.isSimCardInserted == true)
    }
}

extension CellularServiceImpl: CellularService {
    var cellularStatusPublisher: AnyPublisher<DetailsCellularStatus, Never> { cellularStatusSubject.eraseToAnyPublisher() }
    var operatorNamePublisher: AnyPublisher<String?, Never> { operatorNameSubject.eraseToAnyPublisher() }
    var isCellularAvailablePublisher: AnyPublisher<Bool, Never> { isCellularAvailableSubject.eraseToAnyPublisher() }
    var isCellularAvailable: Bool { isCellularAvailableSubject.value }
    var cellularStatusValue: DetailsCellularStatus { cellularStatusSubject.value }
}
