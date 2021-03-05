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

/// State for `DevicesStateViewModel`.
open class DevicesConnectionState: ViewModelState, EquatableState, Copying {
    // MARK: - Internal Properties
    /// Drone connection state.
    public fileprivate(set) var droneConnectionState: DeviceConnectionState?
    /// Remote control connection state.
    public fileprivate(set) var remoteControlConnectionState: DeviceConnectionState?

    // MARK: - Init
    required public init() { }

    /// Init.
    ///
    /// - Parameters:
    ///    - droneConnectionState: drone connection state
    ///    - remoteControlConnectionState: remote control connection state
    public init(droneConnectionState: DeviceConnectionState?,
                remoteControlConnectionState: DeviceConnectionState?) {
        self.droneConnectionState = droneConnectionState
        self.remoteControlConnectionState = remoteControlConnectionState
    }

    // MARK: - Public Funcs
    /// Returns true if state is equal to given state.
    /// Must be overriden in subclasses.
    ///
    /// - Parameters:
    ///    - other: other state
    ///
    open func isEqual(to other: DevicesConnectionState) -> Bool {
        return self.droneConnectionState == other.droneConnectionState
            && self.remoteControlConnectionState == other.remoteControlConnectionState
    }

    /// Returns a copy of the object.
    /// Must be overriden in sublasses.
    open func copy() -> Self {
        if let copy = DevicesConnectionState(droneConnectionState: self.droneConnectionState,
                                             remoteControlConnectionState: self.remoteControlConnectionState) as? Self {
            return copy
        } else {
            fatalError("Must override...")
        }
    }
}

/// ViewModel used to watch both drone and remote state.

open class DevicesStateViewModel<T: DevicesConnectionState>: WatcherViewModel<T> {
    // MARK: - Private Properties
    private var droneStateRef: Ref<DeviceState>?
    private var remoteControlStateRef: Ref<DeviceState>?

    // MARK: - Override Funcs
    open override func listenDrone(drone: Drone) {
        droneStateRef = drone.getState { [weak self] droneState in
            guard let copyState = self?.state.value.copy() else {
                return
            }
            copyState.droneConnectionState = DeviceConnectionState(connectionState: droneState?.connectionState)
            self?.state.set(copyState)
            self?.droneConnectionStateDidChange()
        }
    }

    open override func listenRemoteControl(remoteControl: RemoteControl) {
        remoteControlStateRef = remoteControl.getState { [weak self] remoteControlState in
            guard let copyState = self?.state.value.copy() else {
                return
            }
            copyState.remoteControlConnectionState = DeviceConnectionState(connectionState: remoteControlState?.connectionState)
            self?.state.set(copyState)
            self?.remoteControlConnectionStateDidChange()
        }
    }

    // MARK: - Public Funcs
    /// Func called when drone state changes.
    open func droneConnectionStateDidChange() {
        // To override if needed.
    }

    /// Func called when remote control state changes.
    open func remoteControlConnectionStateDidChange() {
        // To override if needed.
    }
}
