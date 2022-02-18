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

public protocol PinCodeService: AnyObject {

    var isPinCodeRequested: AnyPublisher<Bool, Never> { get }
    var isPinCodeRequestedValue: Bool { get }

    func resetPinCodeRequested()
}

class PinCodeServiceImpl {
    private let connectedDroneHolder: ConnectedDroneHolder
    private var cellularRef: Ref<Cellular>?
    private var cancellables = Set<AnyCancellable>()

    private var isPinCodeRequestedSubject = CurrentValueSubject<Bool, Never>(false)

    init(connectedDroneHolder: ConnectedDroneHolder) {
        self.connectedDroneHolder = connectedDroneHolder

        connectedDroneHolder.dronePublisher
            .removeDuplicates()
            .sink { [unowned self] drone in
                listenCellular(drone: drone)
            }
            .store(in: &cancellables)
    }

    /// Listens the drone's cellular state
    func listenCellular(drone: Drone?) {
        cellularRef = drone?.getPeripheral(Peripherals.cellular) { [unowned self] _ in
            updateCellularState(drone: drone)
        }
    }

    /// Updates if the pin code is requested
    /// - Parameter drone: The connected drone
    func updateCellularState(drone: Drone?) {
        guard let drone = drone else { return }
        pinCodeRequested(drone: drone)
    }
}

private extension PinCodeServiceImpl {

    func pinCodeRequested(drone: Drone?) {
        let droneCellular = drone?.getPeripheral(Peripherals.cellular)

        if droneCellular?.isSimCardInserted == false
            || droneCellular?.isActivated == false
            || (droneCellular?.simStatus == .locked && droneCellular?.pinRemainingTries == 0) {
            isPinCodeRequestedSubject.send(false)
        } else {
            isPinCodeRequestedSubject.send(droneCellular?.isPinCodeRequested == true)
        }
    }
}

extension PinCodeServiceImpl: PinCodeService {
    var isPinCodeRequestedValue: Bool { isPinCodeRequestedSubject.value }

    var isPinCodeRequested: AnyPublisher<Bool, Never> { isPinCodeRequestedSubject.eraseToAnyPublisher() }

    func resetPinCodeRequested() {
        isPinCodeRequestedSubject.send(false)
    }
}
