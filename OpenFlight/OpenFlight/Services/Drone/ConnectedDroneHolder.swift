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
import GroundSdk
import Combine

/// Protocol for the service responsible of holding the drone that might be connected
public protocol ConnectedDroneHolder: AnyObject {
    /// The connected drone if any
    var drone: Drone? { get }
    /// Connected drone publisher
    var dronePublisher: AnyPublisher<Drone?, Never> { get }
}

class ConnectedDroneHolderImpl: ConnectedDroneHolder {
    private var groundSdk = GroundSdk()

    private var autoConnectionRef: Ref<AutoConnectionDesc.ApiProtocol>?
    private var droneStateRef: Ref<DeviceState>?

    private let droneSubject = CurrentValueSubject<Drone?, Never>(nil)

    var drone: Drone? { droneSubject.value }

    var dronePublisher: AnyPublisher<Drone?, Never> { droneSubject.eraseToAnyPublisher() }

    init() {
        setupListening()
    }

    /// Listen to `AutoConnection` facility to catch if a drone is detected or not.
    private func setupListening() {
        autoConnectionRef = groundSdk.getFacility(Facilities.autoConnection) { [unowned self] autoConnection in
            // If there's no autoconnection facility or the autoconnection is stopped, we consider there's no drone
            guard let autoConnection = autoConnection, autoConnection.state != .stopped else {
                setDrone(nil)
                return
            }
            // The autoconnection is started, if it carries a drone listen to its state
            if let drone = autoConnection.drone {
                listenDroneState(drone)
            }
        }
    }

    /// Listen to drone's state to catch when it becomes connected
    /// - Parameter drone: the drone
    private func listenDroneState(_ drone: Drone) {
        droneStateRef = drone.getState { [unowned self] droneState in
            // If the drone is not connected we don't consider it
            guard let droneState = droneState,
                  droneState.connectionState == .connected else {
                setDrone(nil)
                return
            }
            // Connected drone case, ensure it's properly set
            setDrone(drone)
        }
    }

    private func setDrone(_ drone: Drone?) {
        // Only trigger anything when there's an effective change
        guard drone?.uid != self.droneSubject.value?.uid else { return }
        self.droneSubject.value = drone
    }
}
