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
import GroundSdk
import Combine
import SwiftyUserDefaults

/// Protocol for the service responsible of holding the current drone
public protocol CurrentDroneHolder: AnyObject {
    /// The current drone - may be connected, disconnected, or fake
    var drone: Drone { get }
    // The current drone publisher
    var dronePublisher: AnyPublisher<Drone, Never> { get }
    /// True if a drone has been connected before
    var hasLastConnectedDrone: Bool { get }
    /// Clear the current drone if it matches the `uid` argument and restart autoconnection
    func clearCurrentDroneOnMatch(uid: String)
}

private extension DefaultsKeys {
    var lastConnectedDroneUID: DefaultsKey<String?> { .init("key_lastConnectedDroneUID") }
}

class CurrentDroneHolderImpl: CurrentDroneHolder {

    private enum Constants {
        static let autoConnectionRestartDelay: TimeInterval = 1.0
        static let defaultDroneUid = DeviceModel.drone(.anafi2).defaultModelUid
    }

    private let groundSdk: GroundSdk

    private let defaultDrone: Drone

    private var cancellables = Set<AnyCancellable>()

    private var droneSubject: CurrentValueSubject<Drone, Never>

    var dronePublisher: AnyPublisher<Drone, Never> { droneSubject.eraseToAnyPublisher() }

    var drone: Drone { droneSubject.value }

    var hasLastConnectedDrone: Bool {
        return Defaults[\.lastConnectedDroneUID] != nil
    }

    init(connectedDroneHolder: ConnectedDroneHolder) {
        let groundSdk = GroundSdk()
        // swiftlint:disable:next force_unwrapping
        let defaultDrone = groundSdk.getDrone(uid: Constants.defaultDroneUid)!
        var lastConnectedDrone: Drone?
        if let uid = Defaults[\.lastConnectedDroneUID] {
            lastConnectedDrone = groundSdk.getDrone(uid: uid)
        }
        self.groundSdk = groundSdk
        self.defaultDrone = defaultDrone
        droneSubject = CurrentValueSubject(lastConnectedDrone ?? defaultDrone)
        listenConnectedDrone(connectedDroneHolder)
    }

    private func listenConnectedDrone(_ connectedDroneHolder: ConnectedDroneHolder) {
        connectedDroneHolder.dronePublisher
            .compactMap({ $0 })
            .filter { [unowned self] drone in
                // Avoid triggering anything when the drone instance is the same
                if drone.uid != self.drone.uid || (drone.uid == self.drone.uid && drone.isConnected != self.drone.isConnected) {
                    return true
                } else {
                    return false
                }
            }
            .sink { [unowned self] drone in
                // Store the drone uid for availability in future sessions
                Defaults.lastConnectedDroneUID = drone.uid
                // Expose the new drone instance
                droneSubject.value = drone
            }
            .store(in: &cancellables)
    }

    public func clearCurrentDroneOnMatch(uid: String) {
        guard drone.uid == uid else { return }
        // Temporary stop autoconnection
        groundSdk.getFacility(Facilities.autoConnection)?.stop()
        // Remove from defaults.
        Defaults.remove(\.lastConnectedDroneUID)
        // Remove the held drone and replace it with the default drone
        droneSubject.value = defaultDrone
        // Restarts AutoConnection after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.autoConnectionRestartDelay) { [weak self] in
            self?.groundSdk.getFacility(Facilities.autoConnection)?.start()
        }
    }

}
