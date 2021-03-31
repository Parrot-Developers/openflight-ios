//
//  Copyright (C) 2020 Parrot Drones SAS.
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

// MARK: - Protocols
/// Used to store methods for `RemoteUpdateViewModel` and `DroneUpdateViewModel`.
protocol DeviceUpdateProtocol {
    /// Returns state of the current device update.
    var state: Observable<DeviceUpdateState> { get }
    /// Returns true if the user can start the update.
    func canStartUpdate() -> Bool
    /// Starts download or update process.
    func startUpdateProcess()
    /// Cancels the download or the update process.
    func cancelUpdateProcess()
    /// Checks if the network is reachable.
    func startNetworkReachability()
}

// MARK: - DeviceUpdateState
/// Common state for `RemoteUpdateViewModel` and `DroneUpdateViewModel`.

final class DeviceUpdateState: DevicesConnectionState {
    // MARK: - Internal Properties
    var isNetworkReachable: Bool?
    var deviceUpdateStep: Observable<DeviceUpdateStep> = Observable(DeviceUpdateStep.none)
    var deviceUpdateEvent: DeviceUpdateEvent?
    var currentProgress: Int?

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///     - droneConnectionState: connection state of the drone
    ///     - remoteConnectionState: connection state of the remote
    ///     - isNetworkReachable: network reachability
    ///     - deviceUpdateStep: state of the update
    ///     - deviceUpdateEvent: event during the update
    ///     - currentProgress: update progress
    init(droneConnectionState: DeviceConnectionState?,
         remoteControlConnectionState: DeviceConnectionState?,
         isNetworkReachable: Bool?,
         deviceUpdateStep: Observable<DeviceUpdateStep>,
         deviceUpdateEvent: DeviceUpdateEvent?,
         currentProgress: Int?) {
        super.init(droneConnectionState: droneConnectionState, remoteControlConnectionState: remoteControlConnectionState)
        self.isNetworkReachable = isNetworkReachable
        self.deviceUpdateStep = deviceUpdateStep
        self.deviceUpdateEvent = deviceUpdateEvent
        self.currentProgress = currentProgress
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DevicesConnectionState) -> Bool {
        guard let other = other as? DeviceUpdateState else {
            return false
        }
        return super.isEqual(to: other)
            && self.isNetworkReachable == other.isNetworkReachable
            && self.deviceUpdateStep.value == other.deviceUpdateStep.value
            && self.deviceUpdateEvent == other.deviceUpdateEvent
            && self.currentProgress == other.currentProgress
    }

    override func copy() -> DeviceUpdateState {
        let copy = DeviceUpdateState(droneConnectionState: self.droneConnectionState,
                                     remoteControlConnectionState: self.remoteControlConnectionState,
                                     isNetworkReachable: self.isNetworkReachable,
                                     deviceUpdateStep: self.deviceUpdateStep,
                                     deviceUpdateEvent: self.deviceUpdateEvent,
                                     currentProgress: self.currentProgress)
        return copy
    }
}
