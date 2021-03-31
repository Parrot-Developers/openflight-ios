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
import GroundSdk
import Reachability

/// Common state for `DeviceConfirmUpdateViewModel`.

final class DeviceConfirmUpdateState: DevicesConnectionState {
    // MARK: - Internal Properties
    var canDownloadRemote: Bool?
    var canDownloadDrone: Bool?
    var canUpdateRemote: Bool?
    var canUpdateDrone: Bool?

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///     - droneConnectionState: connection state of the drone
    ///     - remoteConnectionState: connection state of the remote
    ///     - canDownloadRemote: tells if user can download remote
    ///     - canDownloadDrone: tells if user can download drone
    ///     - canUpdateRemote: tells if user can update remote
    ///     - canUpdateDrone: tells if user can update drone
    init(droneConnectionState: DeviceConnectionState?,
         remoteControlConnectionState: DeviceConnectionState?,
         canDownloadRemote: Bool?,
         canDownloadDrone: Bool?,
         canUpdateRemote: Bool?,
         canUpdateDrone: Bool?) {
        super.init(droneConnectionState: droneConnectionState, remoteControlConnectionState: remoteControlConnectionState)
        self.canDownloadRemote = canDownloadRemote
        self.canDownloadDrone = canDownloadDrone
        self.canUpdateRemote = canUpdateRemote
        self.canUpdateDrone = canUpdateDrone
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DevicesConnectionState) -> Bool {
        guard let other = other as? DeviceConfirmUpdateState else {
            return false
        }
        return super.isEqual(to: other)
            && self.canDownloadRemote == other.canDownloadRemote
            && self.canDownloadDrone == other.canDownloadDrone
            && self.canUpdateRemote == other.canUpdateRemote
            && self.canUpdateDrone == other.canUpdateDrone
    }

    override func copy() -> DeviceConfirmUpdateState {
        let copy = DeviceConfirmUpdateState(droneConnectionState: self.droneConnectionState,
                                            remoteControlConnectionState: self.remoteControlConnectionState,
                                            canDownloadRemote: self.canDownloadRemote,
                                            canDownloadDrone: self.canDownloadDrone,
                                            canUpdateRemote: self.canUpdateRemote,
                                            canUpdateDrone: self.canUpdateDrone)
        return copy
    }
}

/// View Model for device update process.

final class DeviceConfirmUpdateViewModel: DevicesStateViewModel<DeviceConfirmUpdateState> {
    // MARK: - Internal Properties
    /// Returns remote update unavailability reason.
    var unavailabilityRemoteReason: UpdateUnavailabilityReasons? {
        if errorUpdateRemote {
            return .remoteControlNotConnected
        } else if drone?.isStateFlying == true {
            return .droneFlying
        } else if remoteControlUpdaterRef?.value?.updateUnavailabilityReasons.contains(.notEnoughBattery) == true {
            return .notEnoughBattery(model: .remote)
        } else {
            return nil
        }
    }

    /// Returns drone update unavailability reason.
    var unavailabilityDroneReason: UpdateUnavailabilityReasons? {
        if errorUpdateDrone {
            return .droneNotConnected
        } else if drone?.isStateFlying == true {
            return .droneFlying
        } else if droneUpdaterRef?.value?.updateUnavailabilityReasons.contains(.notEnoughBattery) == true {
            return .notEnoughBattery(model: .drone)
        } else {
            return nil
        }
    }

    // MARK: - Private Properties
    private var remoteControlUpdaterRef: Ref<Updater>?
    private var droneUpdaterRef: Ref<Updater>?
    /// Connection error for remote update.
    /// Returns true if there is a local update and when the remote is not connected.
    private var errorUpdateRemote: Bool {
        return state.value.remoteControlConnectionState?.isConnected() == false
            && state.value.canDownloadRemote == false
            && state.value.canUpdateRemote == true
    }

    /// Connection error for drone update.
    /// Returns true if there is a local update and when the drone is not connected.
    private var errorUpdateDrone: Bool {
        return state.value.droneConnectionState?.isConnected() == false
            && state.value.canDownloadDrone == false
            && state.value.canUpdateDrone == true
    }

    // MARK: - Override Funcs
    override func listenRemoteControl(remoteControl: RemoteControl) {
        super.listenRemoteControl(remoteControl: remoteControl)
        listenRemoteUpdater(remoteControl)
    }

    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)
        listenDroneUpdater(drone)
    }

    // MARK: - Internal Funcs
    /// Returns update type of the device.
    ///
    /// - Parameters:
    ///     - model: current device model
    func getUpdateType(model: DeviceUpdateModel) -> DeviceUpdateType {
        var isOnlyDownload = false
        var isFirmwareAlreadyDownloaded = false
        let copy = state.value.copy()
        switch model {
        case .remote:
            if copy.canDownloadRemote == true {
                isOnlyDownload = copy.remoteControlConnectionState?.isConnected() == false
                isFirmwareAlreadyDownloaded = false
            } else if copy.canUpdateRemote == true {
                isOnlyDownload = false
                isFirmwareAlreadyDownloaded = true
            }
        case .drone:
            if copy.canDownloadDrone == true {
                isOnlyDownload = copy.droneConnectionState?.isConnected() == false
                isFirmwareAlreadyDownloaded = false
            } else if copy.canUpdateDrone == true {
                isOnlyDownload = false
                isFirmwareAlreadyDownloaded = true
            }
        }

        return DeviceUpdateType(model: model,
                                isOnlyDownload: isOnlyDownload,
                                isFirmwareAlreadyDownloaded: isFirmwareAlreadyDownloaded)
    }

    /// Returns true if user can update the device.
    ///
    /// - Parameters:
    ///     - model: current device model
    func canUpdate(model: DeviceUpdateModel) -> Bool? {
        switch model {
        case .remote:
            return unavailabilityRemoteReason == nil
                && !errorUpdateRemote
        case .drone:
            return unavailabilityDroneReason == nil
                && !errorUpdateDrone
        }
    }
}

// MARK: - Private Funcs
private extension DeviceConfirmUpdateViewModel {
    /// Starts watcher for remote updater.
    func listenRemoteUpdater(_ remoteControl: RemoteControl) {
        remoteControlUpdaterRef = remoteControl.getPeripheral(Peripherals.updater) { [weak self] updater in
            guard let updater = updater else {
                return
            }
            self?.observeRemoteUpdate(updater)
        }
    }

    /// Observes current remote update state.
    ///
    /// - Parameters:
    ///     - updater: current updater
    func observeRemoteUpdate(_ updater: Updater) {
        let copy = state.value.copy()
        copy.canDownloadRemote = !updater.downloadableFirmwares.isEmpty
        copy.canUpdateRemote = !updater.applicableFirmwares.isEmpty
        state.set(copy)
    }

    /// Starts watcher for drone updater.
    func listenDroneUpdater(_ drone: Drone) {
        droneUpdaterRef = drone.getPeripheral(Peripherals.updater) { [weak self] updater in
            guard let updater = updater else {
                return
            }
            self?.observeDroneUpdate(updater)
        }
    }

    /// Observes current drone update state.
    ///
    /// - Parameters:
    ///     - updater: current updater
    func observeDroneUpdate(_ updater: Updater) {
        let copy = state.value.copy()
        copy.canDownloadDrone = !updater.downloadableFirmwares.isEmpty
        copy.canUpdateDrone = !updater.applicableFirmwares.isEmpty
        state.set(copy)
    }
}
