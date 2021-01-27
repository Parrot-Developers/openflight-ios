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

import GroundSdk

/// State used to watch DeviceState.

open class DeviceConnectionState: ViewModelState, EquatableState, Copying {
    // MARK: - Private Properties
    public fileprivate(set) var connectionState: DeviceState.ConnectionState = .disconnected

    // MARK: - Init
    /// Default init.
    public required init() { }

    /// Init with device state.
    public init(connectionState: DeviceState.ConnectionState) {
        self.connectionState = connectionState
    }

    /// Failable init with device state.
    public convenience init?(connectionState: DeviceState.ConnectionState?) {
        guard let connectionState = connectionState else { return nil }

        self.init(connectionState: connectionState)
    }

    // MARK: - Public Funcs
    /// Returns true if state is equal to given state.
    /// Must be overriden in subclasses.
    ///
    /// - Parameters:
    ///    - other: other state
    ///
    open func isEqual(to other: DeviceConnectionState) -> Bool {
        return self.connectionState == other.connectionState
    }

    /// Returns a copy of the object.
    /// Must be overriden in sublasses.
    open func copy() -> Self {
        if let copy = DeviceConnectionState(connectionState: connectionState) as? Self {
            return copy
        } else {
            fatalError("Must override...")
        }
    }

    /// Helper.
    public func isConnected() -> Bool {
        return self.connectionState == .connected
    }
}

/// View model used to watch drone state.

open class DroneStateViewModel<T: DeviceConnectionState>: DroneWatcherViewModel<T> {
    // MARK: - Private Properties
    private var droneStateRef: Ref<DeviceState>?

    // MARK: - Override Funcs
    override open func listenDrone(drone: Drone) {
        droneStateRef = drone.getState { [weak self] deviceState in
            let copy = self?.state.value.copy()
            copy?.connectionState = deviceState?.connectionState ?? .disconnected
            self?.state.set(copy)
            self?.droneConnectionStateDidChange()
        }
    }

    // MARK: - Public Funcs
    /// Func called when drone state changes.
    open func droneConnectionStateDidChange() {
        // To override if needed.
    }
}

/// View model used to watch remote control state.

class RemoteControlStateViewModel<T: DeviceConnectionState>: RemoteControlWatcherViewModel<T> {
    // MARK: - Private Properties
    private var remoteControleStateRef: Ref<DeviceState>?

    // MARK: - Override Funcs
    override func listenRemoteControl(remoteControl: RemoteControl) {
        remoteControleStateRef = remoteControl.getState { [weak self] deviceState in
            guard let remoteState = deviceState else { return }

            let copy = self?.state.value.copy()
            copy?.connectionState = deviceState?.connectionState ?? .disconnected
            self?.state.set(copy)
            self?.remoteControlStateDidChange(state: remoteState)
        }
    }

    // MARK: - Public Funcs
    /// Func called when remote control state changes.
    func remoteControlStateDidChange(state: DeviceState) {
        // To override if needed.
    }
}
