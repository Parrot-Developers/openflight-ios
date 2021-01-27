// Copyright (C) 2020 Parrot Drones SAS
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

import GroundSdk

/// Class notifying when current drone changes.
final public class CurrentDroneWatcher {

    // MARK: - Private Properties
    private let groundSdk = GroundSdk()
    private var autoConnectionRef: Ref<AutoConnection>?
    private var currentDroneDidChangeCb: ((_ drone: Drone) -> Void)?
    /// Current or last connected drone.
    public private(set) var drone: Drone?

    // MARK: - Init
    public init() {}
}

// MARK: - Public Funcs
extension CurrentDroneWatcher {

    /// Starts watching for drone change.
    ///
    /// - Parameters:
    ///    - callback: callback called when the current drone changes
    ///    - drone: current drone
    /// - Note: callback is immediately called when registered.
    public func start(callback: @escaping (_ drone: Drone) -> Void) {
        currentDroneDidChangeCb = callback
        // Initial notification with stored drone.
        if let drone = groundSdk.getDrone(uid: CurrentDroneStore.currentDroneUid) {
            currentDroneDidChange(drone)
        }
        // Listen to autoconnection facility.
        autoConnectionRef = groundSdk.getFacility(Facilities.autoConnection) { [weak self] autoConnection in
            // If autoconnection is stopped, switch to default drone.
            if autoConnection?.state == .stopped,
                let defaultDrone = self?.groundSdk.getDrone(uid: DroneConstants.defaultDroneUid) {
                self?.currentDroneDidChange(defaultDrone)
            } else if let drone = autoConnection?.drone {
                self?.currentDroneDidChange(drone)
            }
        }
    }
}

// MARK: - Private Funcs
private extension CurrentDroneWatcher {
    /// Called when current drone changes (either AutoConnection
    /// update, or initial notification).
    ///
    /// - Parameters:
    ///    - drone: the new drone
    func currentDroneDidChange(_ newDrone: Drone) {
        guard newDrone.uid != drone?.uid else {
            return
        }
        drone = newDrone
        currentDroneDidChangeCb?(newDrone)
    }
}
