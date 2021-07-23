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

// MARK: - Private Enums
private enum Constants {
    static let defaultProgress: Int = -1
    static let maxProgress = 100
    static let minProgress = 0
}

// MARK: - FirmwareUpdaterWrapperState
/// The states for `FirmwareUpdaterWrapper`.
final class FirmwareUpdaterWrapperState: DeviceConnectionState {
    // MARK: - Private Properties
    fileprivate(set) var currentUpdatingProgress: Int = Constants.defaultProgress
    fileprivate(set) var currentDownloadingProgress: Int = Constants.defaultProgress
    fileprivate(set) var downloadState: UpdaterDownloadState?
    fileprivate(set) var updateState: UpdaterUpdateState?

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Inits the firmware updater state.
    ///
    /// - Parameters:
    ///   - connectionState: The connection state
    ///   - currentUpdatingProgress: The current updating progress
    ///   - currentDownloadingProgress: The current downloading progress
    ///   - downloadState: The dowload state
    ///   - updateState: The update state
    init(connectionState: DeviceState.ConnectionState,
         currentUpdatingProgress: Int,
         currentDownloadingProgress: Int,
         downloadState: UpdaterDownloadState?,
         updateState: UpdaterUpdateState?) {
        super.init(connectionState: connectionState)
        self.currentUpdatingProgress = currentUpdatingProgress
        self.currentDownloadingProgress = currentDownloadingProgress
        self.downloadState = downloadState
        self.updateState = updateState
    }

    // MARK: - EquatableState
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? FirmwareUpdaterWrapperState else { return false }

        return super.isEqual(to: other)
            && other.currentUpdatingProgress == self.currentUpdatingProgress
            && other.currentDownloadingProgress == self.currentDownloadingProgress
            && other.downloadState == self.downloadState
            && other.updateState == self.updateState
    }

    // MARK: - Copying
    override func copy() -> FirmwareUpdaterWrapperState {
        return FirmwareUpdaterWrapperState(connectionState: self.connectionState,
                                           currentUpdatingProgress: self.currentUpdatingProgress,
                                           currentDownloadingProgress: self.currentDownloadingProgress,
                                           downloadState: self.downloadState,
                                           updateState: self.updateState)
    }
}

// MARK: - FirmwareUpdaterWrapper
/// The view model that handles the Firmware update. Don't use this model directly, use `FirmwareUpdaterManager`.
final class FirmwareUpdaterWrapper: DroneStateViewModel<FirmwareUpdaterWrapperState> {
    // MARK: - Private Properties
    private var updaterRef: Ref<Updater>?
    private var updater: Updater?

    // MARK: - Deinit
    deinit {
        self.updaterRef = nil
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)
        listenFirmwareUpdater(drone: drone)
    }

    /// Resets the states.
    func resetFirmwareStates() {
        let copy = self.state.value.copy()
        copy.updateState = nil
        copy.downloadState = nil
        copy.currentDownloadingProgress = Constants.defaultProgress
        copy.currentUpdatingProgress = Constants.defaultProgress
        self.state.set(copy)
    }

    /// Starts the updates.
    func startFirmwareUpdate() {
        guard let updater = updater else { return }

        let updateStarted = updater.updateToLatestFirmware()

        if updateStarted {
            ULog.d(.missionUpdateTag, "Firmware update started")
        } else {
            ULog.d(.missionUpdateTag, "Firmware update never started")
            // The update never started, the logic requires to set its state to "failed".
            update(updateState: .failed,
                   currentUpdatingProgress: Constants.maxProgress)
        }
    }

    /// Starts the download.
    func startFirmwareDownload() {
        guard let updater = updater else { return }

        let downloadStarted = updater.downloadAllFirmwares()

        if downloadStarted {
            ULog.d(.missionUpdateTag, "Firmware download started")
        } else {
            ULog.d(.missionUpdateTag, "Firmware download never started")
            // The download never started, the logic requires to set its state to "failed".
            update(downloadState: .failed,
                   currentDownloadingProgress: Constants.maxProgress)
        }
    }

    /// Cancels the update.
    ///
    /// - Returns: True if the operation was successful.
    func cancelFirmwareUpdate() -> Bool {
        guard let updater = updater else { return false }

        guard let updateState = state.value.updateState else {
            // The update never started, the logic requires to set its state to "canceled".
            update(updateState: .canceled,
                   currentUpdatingProgress: Constants.maxProgress)
            ULog.d(.missionUpdateTag, "Firmware update manually cancelled")

            return true
        }

        switch updateState {
        case .uploading:
            ULog.d(.missionUpdateTag, "Firmware update cancelled")
            return updater.cancelUpdate()
        case .canceled,
             .failed,
             .success:
            return true
        case .processing,
             .waitingForReboot:
            return false
        }
    }

    /// Cancels the download.
    ///
    /// - Returns: True if the operation was successful.
    func cancelFirmwareDownload() -> Bool {
        guard let updater = updater else { return false }

        guard let downloadState = state.value.downloadState else {
            // The download never started, the logic requires to set its state to "canceled".
            update(downloadState: .canceled,
                   currentDownloadingProgress: Constants.maxProgress)
            ULog.d(.missionUpdateTag, "Firmware download manually cancelled")

            return true
        }

        switch  downloadState {
        case .downloading:
            ULog.d(.missionUpdateTag, "Firmware download cancelled")

            return updater.cancelDownload()
        case .canceled,
             .failed,
             .success:
            return true
        }
    }

    /// Checks if the update is finished.
    ///
    /// - Returns: True if the update is finished.
    func isUpdateFinished() -> Bool {
        guard let updateState = state.value.updateState else { return false }

        switch updateState {
        case .canceled,
             .failed,
             .success:
            return true
        case .processing,
             .waitingForReboot,
             .uploading:
            return false
        }
    }

    /// Checks if the download is finished.
    ///
    /// - Returns: True if the download is finished.
    func isDownloadFinished() -> Bool {
        guard let downloadState = state.value.downloadState else { return false }

        switch downloadState {
        case .canceled,
             .failed,
             .success:
            return true
        case .downloading:
            return false
        }
    }

    /// Returns true if the download process or the update process contain an error.
    ///
    /// - Returns: True if the download process or the update process contain an error.
    func downloadOrUpdateContainError() -> Bool {
        return state.value.downloadState == .failed
            || state.value.updateState == .failed
            || state.value.downloadState == .canceled
            || state.value.updateState == .canceled
    }

    /// Returns the current updating step for a given operation.
    ///
    /// - Parameters:
    ///    - operation:The operation
    /// - Returns: The current updating step.
    func currentUpdatingStep(for operation: FirwmwareToUpdateOperation) -> CurrentUpdatingStep {
        switch operation {
        case .download:
            guard let downloadState = state.value.downloadState else { return .waiting }

            return CurrentUpdatingStep(firmwareDownloadingState: downloadState)
        case .update:
            guard let updateState = state.value.updateState else { return .waiting }

            return CurrentUpdatingStep(firmwareUpdatingState: updateState,
                                       forReboot: false)
        case .reboot:
            guard let updateState = state.value.updateState else { return .waiting }

            return CurrentUpdatingStep(firmwareUpdatingState: updateState,
                                       forReboot: true)
        }
    }

    /// Returns the current progress for a given operation.
    ///
    /// - Parameters:
    ///    - operation: The operation
    /// - Returns: The current progress.
    func currentProgress(for operation: FirwmwareToUpdateOperation) -> Int {
        switch operation {
        case .download:
            return currentDownloadProgress()
        case .update:
            return currentUpdateProgress()
        case .reboot:
            return currentRebootProgress()
        }
    }
}

// MARK: - Private Funcs
private extension FirmwareUpdaterWrapper {
    /// Listens to the `Updater` peripheral.
    func listenFirmwareUpdater(drone: Drone) {
        updaterRef = drone.getPeripheral(Peripherals.updater) { [weak self] updater in
            guard let updater = updater,
                  let strongSelf = self else {
                return
            }

            self?.updater = updater

            if let currentUpdate = updater.currentUpdate {
                strongSelf.update(updateState: currentUpdate.state,
                                  currentUpdatingProgress: currentUpdate.currentProgress)
                ULog.d(.missionUpdateTag, "Firmware Update \(currentUpdate)")
            }

            if let currentDownload = updater.currentDownload {
                strongSelf.update(downloadState: currentDownload.state,
                                  currentDownloadingProgress: currentDownload.totalProgress)
                ULog.d(.missionUpdateTag, "Firmware Download \(currentDownload)")
            }
        }
    }

    /// Returns the current download progress.
    ///
    /// - Returns: The current progress.
    func currentDownloadProgress() -> Int {
        guard let downloadState = state.value.downloadState else { return 0 }

        switch downloadState {
        case .canceled,
             .failed,
             .success:
            return Constants.maxProgress
        case .downloading:
            return state.value.currentDownloadingProgress
        }
    }

    /// Returns the current update progress.
    ///
    /// - Returns: The current progress.
    func currentUpdateProgress() -> Int {
        guard let updateState = state.value.updateState else { return 0 }

        switch updateState {
        case .uploading,
             .processing:
            return state.value.currentUpdatingProgress
        case .waitingForReboot,
             .success,
             .failed,
             .canceled:
            return Constants.maxProgress
        }
    }

    /// Returns the current reboot progress.
    ///
    /// - Returns: The current progress.
    func currentRebootProgress() -> Int {
        guard let updateState = state.value.updateState else { return 0 }

        switch updateState {
        case .uploading,
             .processing:
            return Constants.minProgress
        case .waitingForReboot,
             .success,
             .failed,
             .canceled:
            return Constants.maxProgress
        }
    }
}

/// Utils for updating states of `FirmwareUpdaterWrapperState`.
private extension FirmwareUpdaterWrapper {
    /// Updates the state with the download state.
    ///
    /// - Parameters:
    ///     - downloadState: The current download state
    ///     - currentDownloadingProgress: The current downloading progress
    func update(downloadState: UpdaterDownloadState,
                currentDownloadingProgress: Int) {
        let copy = self.state.value.copy()
        copy.downloadState = downloadState
        copy.currentDownloadingProgress = currentDownloadingProgress
        self.state.set(copy)
    }

    /// Updates the state the current update state
    ///
    /// - Parameters:
    ///     - updateState: The current update state
    ///     - currentUpdatingProgress: The current progress
    func update(updateState: UpdaterUpdateState,
                currentUpdatingProgress: Int) {
        let copy = self.state.value.copy()
        copy.updateState = updateState
        copy.currentUpdatingProgress = currentUpdatingProgress
        self.state.set(copy)
    }
}
