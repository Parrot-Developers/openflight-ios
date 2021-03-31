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

import Foundation
import GroundSdk

// MARK: - FirmwareUpdaterManager
/// This manager manages the drone Firmware  update.
final class FirmwareUpdaterManager {
    // MARK: - Internal Properties
    /// This manager is a singleton.
    static let shared = FirmwareUpdaterManager()
    /// A reference on the Firmware that will or is currently being updated.
    private(set) var firmwareToUpdate: FirmwareToUpdateData?

    // MARK: - Private Properties
    /// A boolean to indicate if the update started.
    private var wasUpdateStarted: Bool = false
    /// The current listeners.
    private var listeners: Set<FirmwareUpdaterListener> = []
    /// The model that gets notified to GroundSDK `Updater` .
    private lazy var firmwareUpdaterWrapper = FirmwareUpdaterWrapper(
        stateDidUpdate: { (firmwareUpdaterWrapperState) in
            self.firmwareToUpdateCallback(firmwareUpdaterWrapperState: firmwareUpdaterWrapperState)
        })

    // MARK: - Init
    private init() {}
}

// MARK: - internal Funcs
extension FirmwareUpdaterManager {
    /// Call this function once in the life cycle of the application to start to listen to GroundSDK `Updater`.
    func setup() {
        _ = firmwareUpdaterWrapper
    }

    /// Prepare the update.
    ///
    /// - Parameters:
    ///    - updateChoice:The current update choice
    func prepareUpdate(updateChoice: FirmwareAndMissionUpdateChoice) {
        wasUpdateStarted = false
        firmwareUpdaterWrapper.resetFirmwareStates()
        self.firmwareToUpdate = updateChoice.firmwareToUpdate
    }

    /// Starts the download and upload processes.
    func startFirmwareProcesses() {
        guard let firmwareToUpdate = firmwareToUpdate else {
            firmwareToUpdateCallback(firmwareUpdaterWrapperState: firmwareUpdaterWrapper.state.value)
            return
        }

        if firmwareToUpdate.allOperationsNeeded.contains(.download) {
            firmwareUpdaterWrapper.startFirmwareDownload()
        } else if firmwareToUpdate.allOperationsNeeded.contains(.update) {
             firmwareUpdaterWrapper.startFirmwareUpdate()
        } else {
            firmwareToUpdateCallback(firmwareUpdaterWrapperState: firmwareUpdaterWrapper.state.value)
            return
        }
    }

    /// Cancels and cleans the Firmware prcesses.
    ///
    /// - Parameters:
    ///    - removeData: A boolean to indicate if we remove data.
    /// - Returns: True if the cancel was successful.
    func cancelFirmwareProcesses(removeData: Bool) -> Bool {
        if removeData { firmwareToUpdate = nil }
        let cancelFirmwareDownload = firmwareUpdaterWrapper.cancelFirmwareDownload()
        let cancelFirmwareUpdate = firmwareUpdaterWrapper.cancelFirmwareUpdate()
        return cancelFirmwareDownload && cancelFirmwareUpdate
    }

    /// Returns the current updating step for a given operation.
    ///
    /// - Parameters:
    ///    - operation: The operation
    /// - Returns: The current updating step.
    func currentUpdatingStep(for operation: FirwmwareToUpdateOperation) -> CurrentUpdatingStep {
        return firmwareUpdaterWrapper.currentUpdatingStep(for: operation)
    }

    /// Returns the current progress for a given operation.
    ///
    /// - Parameters:
    ///    - operation: The operation
    /// - Returns: The current progress.
    func currentProgress(for operation: FirwmwareToUpdateOperation) -> Int {
        return firmwareUpdaterWrapper.currentProgress(for: operation)
    }

    /// Returns whether updater requires drone.
    func remainingOperationsRequiresDrone() -> Bool {
        return firmwareToUpdate?.allOperationsNeeded.contains(.update) == true
    }
}

/// Utils for listener management.
extension FirmwareUpdaterManager {
    /// Registers a listener.
    ///
    /// - Parameters:
    ///   - firmwareToUpdateCallback: The callback triggered for any event related to the firmware update
    /// - Returns: The listener.
    func register(firmwareToUpdateCallback: @escaping FirmwareUpdaterClosure) -> FirmwareUpdaterListener {
        let listener = FirmwareUpdaterListener(firmwareToUpdateCallback: firmwareToUpdateCallback)
        listeners.insert(listener)

        let firmwareGlobalUpdatingState = self.firmwareGlobalUpdatingState()
        listener.firmwareToUpdateCallback(firmwareGlobalUpdatingState)

        return listener
    }

    /// Unregisters a listener.
    ///
    /// - Parameters:
    ///     - listener: The listener to unregister
    func unregister(_ listener: FirmwareUpdaterListener?) {
        if let listener = listener {
            listeners.remove(listener)
        }
    }
}

// MARK: - Private Funcs
private extension FirmwareUpdaterManager {
    /// Triggers all listeners callbacks.
    ///
    /// - Parameters:
    ///     - firmwareUpdaterWrapperState: The state given by `FirmwareUpdaterWrapper`
    func firmwareToUpdateCallback(firmwareUpdaterWrapperState: FirmwareUpdaterWrapperState) {
        let firmwareGlobalUpdatingState = self.firmwareGlobalUpdatingState()

        for listener in listeners {
            listener.firmwareToUpdateCallback(firmwareGlobalUpdatingState)
        }

        continueProcessIfNeeded(firmwareUpdaterWrapperState: firmwareUpdaterWrapperState)
    }

    /// Continues tthe Firmware process if needed.
    ///
    /// - Parameters:
    ///     - firmwareUpdaterWrapperState: The state given by `FirmwareUpdaterWrapper`
    func continueProcessIfNeeded(firmwareUpdaterWrapperState: FirmwareUpdaterWrapperState) {
        guard let firmwareToUpdate = firmwareToUpdate,
              firmwareToUpdate.allOperationsNeeded.contains(.download)
                && firmwareToUpdate.allOperationsNeeded.contains(.update) else {
            return
        }

        if firmwareUpdaterWrapper.isDownloadFinished() && !wasUpdateStarted {
            wasUpdateStarted = true
            firmwareUpdaterWrapper.startFirmwareUpdate()
        }
    }

    /// Returns the current `FirmwareGlobalUpdatingState`.
    ///
    /// - Returns: The current `FirmwareGlobalUpdatingState`.
    func firmwareGlobalUpdatingState() -> FirmwareGlobalUpdatingState {
        guard firmwareToUpdate != nil else {
            ULog.d(.missionUpdateTag, "Firmware global state not initialized")

            return .notInitialized
        }

        let processesAreFinished = areProcessesFinished()
        if !processesAreFinished {
            let globalState: FirmwareGlobalUpdatingState = firmwareUpdaterWrapper.isWaitingForReboot() ? .waitingForReboot : .ongoing
            ULog.d(.missionUpdateTag, "Firmware global state \(globalState)")

            return globalState
        }

        let globalState: FirmwareGlobalUpdatingState = downloadOrUpdateContainError() ? .error : .success
        ULog.d(.missionUpdateTag, "Firmware global state \(globalState)")

        return globalState
    }

    /// Returns true if the processes are finished.
    ///
    /// - Returns: True if the processes are finished.
    func areProcessesFinished() -> Bool {
        guard let firmwareToUpdate = firmwareToUpdate else { return false }

        if firmwareToUpdate.allOperationsNeeded.contains(.update) {
            return firmwareUpdaterWrapper.isUpdateFinished()
        } else if firmwareToUpdate.allOperationsNeeded.contains(.download) {
            return firmwareUpdaterWrapper.isDownloadFinished()
        } else {
            return false
        }
    }

    /// Returns true if the download process or the update process contain an error.
    ///
    /// - Returns: True if the download process or the update process contain an error.
    func downloadOrUpdateContainError() -> Bool {
        guard firmwareToUpdate != nil else { return false }

        return firmwareUpdaterWrapper.downloadOrUpdateContainError()
    }
}
