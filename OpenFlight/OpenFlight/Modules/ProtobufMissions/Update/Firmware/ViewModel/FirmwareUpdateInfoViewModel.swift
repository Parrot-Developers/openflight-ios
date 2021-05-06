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
import SwiftProtobuf
import Reachability
import SwiftyUserDefaults

// MARK: - FirmwareUpdateInfoState
/// The states for `FirmwareUpdateInfoViewModel`.
final class FirmwareUpdateInfoState: DeviceConnectionState {
    // MARK: - Private Properties
    fileprivate(set) var firmwareVersion: String?
    fileprivate(set) var firmwareUpdateNeeded: Bool = false
    fileprivate(set) var idealFirmwareVersion: String?
    fileprivate(set) var firmwareNeedToBeDownloaded: Bool = false
    fileprivate(set) var isNetworkReachable: Bool = false

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Inits the `FirmwareUpdateInfoState` state.
    ///
    /// - Parameters:
    ///   - connectionState: The connection state
    ///   - firmwareVersion: The firmware version
    ///   - firmwareUpdateNeeded: The firmware update needed bool
    ///   - idealFirmwareVersion: The ideal firmware version
    ///   - firmwareNeedToBeDownloaded: True if a download of the firmware is needed
    ///   - isNetworkReachable: True is the network is reachable
    init(connectionState: DeviceState.ConnectionState,
         firmwareVersion: String?,
         firmwareUpdateNeeded: Bool,
         idealFirmwareVersion: String?,
         firmwareNeedToBeDownloaded: Bool,
         isNetworkReachable: Bool) {
        super.init(connectionState: connectionState)
        self.firmwareVersion = firmwareVersion
        self.firmwareUpdateNeeded = firmwareUpdateNeeded
        self.idealFirmwareVersion = idealFirmwareVersion
        self.firmwareNeedToBeDownloaded = firmwareNeedToBeDownloaded
        self.isNetworkReachable = isNetworkReachable
    }

    // MARK: - EquatableState
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? FirmwareUpdateInfoState else { return false }

        return super.isEqual(to: other)
            && self.firmwareVersion == other.firmwareVersion
            && self.firmwareUpdateNeeded == other.firmwareUpdateNeeded
            && self.idealFirmwareVersion == other.idealFirmwareVersion
            && self.firmwareNeedToBeDownloaded == other.firmwareNeedToBeDownloaded
            && self.isNetworkReachable == other.isNetworkReachable
    }

    // MARK: - Copying
    override func copy() -> FirmwareUpdateInfoState {
        return FirmwareUpdateInfoState(connectionState: self.connectionState,
                                       firmwareVersion: self.firmwareVersion,
                                       firmwareUpdateNeeded: self.firmwareUpdateNeeded,
                                       idealFirmwareVersion: self.idealFirmwareVersion,
                                       firmwareNeedToBeDownloaded: self.firmwareNeedToBeDownloaded,
                                       isNetworkReachable: self.isNetworkReachable)
    }
}

// MARK: - FirmwareUpdateInfoViewModel
/// A view model that represents the Firmware to update information.
final class FirmwareUpdateInfoViewModel: DroneStateViewModel<FirmwareUpdateInfoState> {
    // MARK: - Private Properties
    private var systemInfoRef: Ref<SystemInfo>?
    private var updaterRef: Ref<Updater>?
    private var internalUserStorageRef: Ref<InternalUserStorage>?
    private var reachability: Reachability?

    // MARK: - Deinit
    deinit {
        reachability?.stopNotifier()
        systemInfoRef = nil
        updaterRef = nil
        internalUserStorageRef = nil
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)

        listenUpdater(drone)
        listenSystemInfo(drone)
        listenInternaUserStorage(drone)
        listenReachability()
    }

    // MARK: - Public Funcs
    /// Returns a `FirmwareToUpdateData` if possible.
    ///
    /// - Returns: A `FirmwareToUpdateData` if possible.
    func firmwareToUpdateData() -> FirmwareToUpdateData? {
        let firmwareInfo = self.state.value
        let droneIsConnected = self.state.value.isConnected()

        guard let firmwareVersion = firmwareInfo.firmwareVersion else { return nil }

        return FirmwareToUpdateData(firmwareVersion: firmwareVersion,
                                    firmwareIdealVersion: firmwareInfo.idealFirmwareVersion ?? firmwareVersion,
                                    firmwareUpdateNeeded: firmwareInfo.firmwareUpdateNeeded,
                                    firmwareNeedToBeDownloaded: firmwareInfo.firmwareNeedToBeDownloaded,
                                    droneIsConnected: droneIsConnected)
    }

    /// Returns a `FirmwareAndMissionUpdateRequirementStatus`.
    ///
    /// - Parameters:
    ///     - hasMissionToUpdate: A boolean to indicate if some missions need to be updated
    ///     - hasFirmwareToUpdate: A boolean to indicate if  the firmware needs to be updated
    ///     - onlyNeedFirmwareDownload: A boolean to indicate if the firmware only needs to be downloaded
    /// - Returns: The current `FirmwareAndMissionUpdateRequirementStatus`.
    func firmwareAndMissionUpdateRequirementStatus(hasMissionToUpdate: Bool,
                                                   hasFirmwareToUpdate: Bool,
                                                   onlyNeedFirmwareDownload: Bool) -> FirmwareAndMissionUpdateRequirements {
        if onlyNeedFirmwareDownload && !hasMissionToUpdate {
            return state.value.isNetworkReachable ? .readyForUpdate : .noInternetConnection
        }

        if let updateUnavailabilityReason = drone?.getPeripheral(Peripherals.updater)?.updateUnavailabilityReasons,
           let firstReason = updateUnavailabilityReason.first {
            return FirmwareAndMissionUpdateRequirements(unavailabilityReason: firstReason)
        } else if hasFirmwareToUpdate
                    && !self.state.value.isNetworkReachable
                    && self.state.value.firmwareNeedToBeDownloaded {
            return .noInternetConnection
        }
        // TODO: Check internal memory
        return .readyForUpdate
    }
}

// MARK: - Private Funcs
private extension FirmwareUpdateInfoViewModel {
    /// Listens to the `SystemInfo` peripheral.
    func listenSystemInfo(_ drone: Drone) {
        systemInfoRef = drone.getPeripheral(Peripherals.systemInfo) { [weak self] systemInfo in
            self?.update(firmwareVersion: systemInfo?.firmwareVersion)
        }
    }

    /// Listens to the `Updater` peripheral.
    func listenUpdater(_ drone: Drone) {
        updaterRef = drone.getPeripheral(Peripherals.updater) { [weak self] updater in
            guard let updater = updater,
                  let strongSelf = self else { return }

            strongSelf.update(idealFirmwareVersion: updater.idealVersion?.description,
                              firmwareUpdateNeeded: !updater.isUpToDate,
                              firmwareNeedToBeDownloaded: !updater.downloadableFirmwares.isEmpty)
        }
    }

    /// Listens to the `InternalUserStorage` peripheral.
    func listenInternaUserStorage(_ drone: Drone) {
        internalUserStorageRef = drone.getPeripheral(Peripherals.internalUserStorage) { _ in // [weak self] internalUserStorage in
            // guard let internalUserStorage = internalUserStorage else { return }
            // TODO: Check the available space and compare it with Firmware and Mission sizes
        }
    }

    /// Checks if the network is reachable.
    func listenReachability() {
        do {
            try reachability = Reachability()
            try reachability?.startNotifier()
        } catch {
            self.update(isNetworkReachable: false)
        }
        reachability?.whenReachable = { [weak self] _ in
            self?.update(isNetworkReachable: true)
        }
        reachability?.whenUnreachable = { [weak self] _ in
            self?.update(isNetworkReachable: false)
        }
    }
}

/// Utils for updating states of `FirmwareUpdateInfoState`.
private extension FirmwareUpdateInfoViewModel {
    /// Updates the state.
    ///
    /// - Parameters:
    ///     - idealFirmwareVersion: The ideal firmware version
    ///     - firmwareUpdateNeeded: True if a firmware update is needed
    ///     - firmwareNeedToBeDownloaded: True if a download of the firmware is needed
    func update(idealFirmwareVersion: String?,
                firmwareUpdateNeeded: Bool,
                firmwareNeedToBeDownloaded: Bool) {
        let copy = self.state.value.copy()
        copy.idealFirmwareVersion = idealFirmwareVersion
        copy.firmwareUpdateNeeded = firmwareUpdateNeeded
        copy.firmwareNeedToBeDownloaded = firmwareNeedToBeDownloaded
        self.state.set(copy)
    }

    /// Updates the state with the firmware version.
    ///
    /// - Parameters:
    ///     - firmwareVersion: The firmware version
    func update(firmwareVersion: String?) {
        let copy = self.state.value.copy()
        copy.firmwareVersion = firmwareVersion
        self.state.set(copy)
    }

    /// Updates the state with the network reachability.
    ///
    /// - Parameters:
    ///     - isNetworkReachable: True if the network is reachable
    func update(isNetworkReachable: Bool) {
        let copy = self.state.value.copy()
        copy.isNetworkReachable = isNetworkReachable
        self.state.set(copy)
    }
}
