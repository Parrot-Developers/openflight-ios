//    Copyright (C) 2020 Parrot Drones SAS
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
import Combine

/// State for `RemoteUpdateViewModel`.
final class RemoteUpdateState: DevicesConnectionState {
    // MARK: - Internal Properties
    var isNetworkReachable: Bool?
    var idealFirmwareVersion: String?
    var deviceUpdateStep: Observable<RemoteUpdateStep> = Observable(RemoteUpdateStep.none)
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
    ///     - idealFirmwareVersion: The ideal firmware version
    ///     - deviceUpdateStep: state of the update
    ///     - currentProgress: update progress
    init(droneConnectionState: DeviceConnectionState?,
         remoteControlConnectionState: DeviceConnectionState?,
         isNetworkReachable: Bool?,
         idealFirmwareVersion: String?,
         deviceUpdateStep: Observable<RemoteUpdateStep>,
         currentProgress: Int?) {
        super.init(droneConnectionState: droneConnectionState, remoteControlConnectionState: remoteControlConnectionState)
        self.isNetworkReachable = isNetworkReachable
        self.idealFirmwareVersion = idealFirmwareVersion
        self.deviceUpdateStep = deviceUpdateStep
        self.currentProgress = currentProgress
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DevicesConnectionState) -> Bool {
        guard let other = other as? RemoteUpdateState else {
            return false
        }
        return super.isEqual(to: other)
            && self.isNetworkReachable == other.isNetworkReachable
            && self.idealFirmwareVersion == other.idealFirmwareVersion
            && self.deviceUpdateStep.value == other.deviceUpdateStep.value
            && self.currentProgress == other.currentProgress
    }

    override func copy() -> RemoteUpdateState {
        let copy = RemoteUpdateState(droneConnectionState: self.droneConnectionState,
                                     remoteControlConnectionState: self.remoteControlConnectionState,
                                     isNetworkReachable: self.isNetworkReachable,
                                     idealFirmwareVersion: self.idealFirmwareVersion,
                                     deviceUpdateStep: self.deviceUpdateStep,
                                     currentProgress: self.currentProgress)
        return copy
    }
}

/// View Model for remote update process.
final class RemoteUpdateViewModel: DevicesStateViewModel<RemoteUpdateState> {
    // MARK: - Private Properties
    private var remoteControlUpdaterRef: Ref<Updater>?
    private var networkService: NetworkService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Internal Properties
    /// The latest applicable (local) firmware version.
    var latestApplicableFirmwareVersion: FirmwareVersion? {
        remoteControlUpdaterRef?.value?.applicableFirmwares.last?.firmwareIdentifier.version
    }

    // MARK: - Init
    /// Init.
    override init() {
        networkService = Services.hub.systemServices.networkService

        super.init()
    }

    // MARK: - Override Funcs
    override func listenRemoteControl(remoteControl: RemoteControl) {
        super.listenRemoteControl(remoteControl: remoteControl)

        listenUpdater(remoteControl)
        listenNetwork()
    }

    // MARK: - Internal Funcs
    /// Tells whether target firmware needs to be downloaded.
    func needDownload() -> Bool {
        return remoteControlUpdaterRef?.value?.downloadableFirmwares.isEmpty == false
    }

    /// Tells whether an applicable firmware is locally available (it may not be the ideal version).
    func isLocalUpdateAvailable() -> Bool {
        remoteControlUpdaterRef?.value?.applicableFirmwares.isEmpty == false
    }

    /// Returns true if the user can start an update.
    func canStartUpdate() -> Bool {
        // Battery level.
        let updater = remoteControl?.getPeripheral(Peripherals.updater)
        return updater?.updateUnavailabilityReasons.contains(.notEnoughBattery) == false
    }

    /// Starts download or update process.
    func startUpdateProcess() {
        let updater = remoteControl?.getPeripheral(Peripherals.updater)
        if updater?.downloadableFirmwares.isEmpty == false {
            startDownload()
        } else if updater?.applicableFirmwares.isEmpty == false {
            startUpdate()
        }
    }

    /// Starts download of the firmware.
    func startDownload() {
        let started = remoteControl?.getPeripheral(Peripherals.updater)?.downloadAllFirmwares() == true
        if !started {
            state.value.deviceUpdateStep.set(.downloadFailed)
        }
    }

    /// Starts update of the firmware.
    func startUpdate() {
        remoteControl?.getPeripheral(Peripherals.updater)?.updateToLatestFirmware()
        state.value.currentProgress = 0
    }

    /// Cancels the download or the update.
    func cancelUpdateProcess() {
        let updater = remoteControl?.getPeripheral(Peripherals.updater)
        let copy = state.value.copy()

        switch copy.deviceUpdateStep.value {
        case .downloadStarted:
            updater?.cancelDownload()
        case .downloadCompleted, .updateStarted, .uploading, .processing:
            updater?.cancelUpdate()
        default:
            break
        }
    }

    /// Checks if the network is reachable.
    func startNetworkReachability() {
        // Set a default state to nil when we start listen reachability.
        let copy = state.value.copy()
        copy.isNetworkReachable = nil
        self.state.set(copy)
        cancellables.removeAll()
        listenNetwork()
    }
}

// MARK: - Private Funcs
private extension RemoteUpdateViewModel {
    /// Starts watcher for remote updater.
    ///
    /// - Parameters:
    ///     - remoteControl: current remote
    func listenUpdater(_ remoteControl: RemoteControl) {
        remoteControlUpdaterRef = remoteControl.getPeripheral(Peripherals.updater) { [weak self] updater in
            guard let self = self,
                  let updater = updater else { return }

            self.updateFirmwareVersion(updater)
            self.updateCurrentDownload(updater)
            self.updateCurrentUpdate(updater)
        }
    }

    /// Updates ideal firmware version.
    ///
    /// - Parameters:
    ///     - updater: current updater
    func updateFirmwareVersion(_ updater: Updater) {
        let copy = self.state.value.copy()
        copy.idealFirmwareVersion = updater.idealVersion?.description
        self.state.set(copy)
    }

    /// Updates current download state.
    ///
    /// - Parameters:
    ///     - updater: current updater
    func updateCurrentDownload(_ updater: Updater) {
        guard let currentDownload = updater.currentDownload else { return }
        ULog.d(.remoteUpdateTag, "Current download: \(currentDownload)")

        let copy = state.value.copy()
        switch currentDownload.state {
        case .downloading:
            copy.deviceUpdateStep.set(.downloadStarted)
        case .canceled:
            copy.deviceUpdateStep.set(.cancelled)
        case .failed:
            copy.deviceUpdateStep.set(.downloadFailed)
        case .success:
            copy.deviceUpdateStep.set(.downloadCompleted)
        }

        copy.currentProgress = currentDownload.currentProgress
        state.set(copy)
    }

    /// Updates current update state.
    ///
    /// - Parameters:
    ///     - updater: current updater
    func updateCurrentUpdate(_ updater: Updater) {
        guard let currentUpdate = updater.currentUpdate else { return }
        ULog.d(.remoteUpdateTag, "Current update: \(currentUpdate)")

        let copy = state.value.copy()
        switch currentUpdate.state {
        case .processing:
            copy.deviceUpdateStep.set(.processing)
        case .uploading:
            copy.deviceUpdateStep.set(.uploading)
        case .failed:
            copy.deviceUpdateStep.set(.updateFailed)
        case .canceled:
            copy.deviceUpdateStep.set(.cancelled)
        case .waitingForReboot:
            copy.deviceUpdateStep.set(.rebooting)
        case .success:
            copy.deviceUpdateStep.set(.updateCompleted)
        }

        copy.currentProgress = currentUpdate.currentProgress
        state.set(copy)
    }

    func listenNetwork() {
        networkService.networkReachable
            .removeDuplicates()
            .sink { [weak self] reachable in
                guard let self = self else { return }
                let copy = self.state.value.copy()

                copy.isNetworkReachable = reachable
                self.state.set(copy)
            }
            .store(in: &cancellables)
    }
}
