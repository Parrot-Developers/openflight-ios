//    Copyright (C) 2023 Parrot Drones SAS
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
import Combine

private extension ULogTag {
    static let tag = ULogTag(name: "FirmwareUpdateService")
}

/// The global possible states of a Firmware update process.
public enum FirmwareGlobalUpdatingState {
    case notInitialized
    case ongoing
    case downloading
    case uploading
    case processing
    case waitingForReboot
    case success
    case error
}

// MARK: - Private Enums
private enum Constants {
    static let defaultProgress: Int = -1
    static let maxProgress = 100
    static let minProgress = 0
}

/// FirmwareUpdate service.
public protocol FirmwareUpdateService: AnyObject {
    /// Whether legacy update process should be applied, which includes an extra reboot before uploading missions
    var legacyUpdate: Bool { get }

    /// FirmwareToUpdate publisher
    ///
    /// A reference on the firmware that will or is currently being updated.
    var firmwareToUpdatePublisher: AnyPublisher<FirmwareToUpdateData?, Never> { get }
    /// Update publisher
    var updatePublisher: AnyPublisher<UpdaterUpdate?, Never> { get }
    /// download publisher
    var downloadPublisher: AnyPublisher<UpdaterDownload?, Never> { get }
    /// Downloadable firmwares publisher
    var downloadableFirmwaresPublisher: AnyPublisher<[FirmwareInfo], Never> { get }
    /// Up to date publisher
    var isUpToDatePublisher: AnyPublisher<Bool, Never> { get }
    /// Ideal version publisher
    var idealVersionPublisher: AnyPublisher<FirmwareVersion?, Never> { get }
    /// Current firmware version publisher
    var firmwareVersionPublisher: AnyPublisher<String?, Never> { get }
    /// Global Updating state publisher
    var globalUpdatingStatePublisher: AnyPublisher<FirmwareGlobalUpdatingState?, Never> { get }

    /// Prepare the update.
    ///
    /// - Parameters:
    ///    - updateChoice:The current update choice
    func prepareUpdate(updateChoice: FirmwareAndMissionUpdateChoice)

    /// Starts the download and upload processes.
    /// - Parameters:
    ///    - reboot:`true` if automatic reboot requested at the end.
    func startFirmwareProcesses(reboot: Bool)

    /// Returns the current progress for a given operation.
    ///
    /// - Parameters:
    ///    - operation: The operation
    /// - Returns: The current progress.
    func currentProgress(for operation: FirwmwareToUpdateOperation) -> Int

    /// Returns the current updating step for a given operation.
    ///
    /// - Parameters:
    ///    - operation: The operation
    /// - Returns: The current updating step.
    func currentUpdatingStep(for operation: FirwmwareToUpdateOperation) -> CurrentUpdatingStep

    /// Returns a `FirmwareAndMissionUpdateRequirements`.
    ///
    /// - Parameters:
    ///     - hasMissionToUpdate: `true` if some missions need to be updated
    ///     - hasFirmwareToUpdate: `true` if the firmware needs to be updated
    ///     - onlyNeedFirmwareDownload: `true` if the firmware only needs to be downloaded
    ///     - isNetworkReachable: `true` if there is a network connection
    /// - Returns: The current `FirmwareAndMissionUpdateRequirements`.
    func firmwareAndMissionUpdateRequirementStatus(hasMissionToUpdate: Bool,
                                                   hasFirmwareToUpdate: Bool,
                                                   onlyNeedFirmwareDownload: Bool,
                                                   isNetworkReachable: Bool
    ) -> FirmwareAndMissionUpdateRequirements

    /// Cancels and cleans the Firmware processes.
    ///
    /// - Parameters:
    ///    - removeData: A boolean to indicate if we remove data.
    /// - Returns: `true` if the cancel was successful.
    func cancelFirmwareProcesses(removeData: Bool) -> Bool
}

/// Implementation of `FirmwareUpdateService`.
public class FirmwareUpdateServiceImpl {

    // MARK: Private properties
    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()
    /// Latest applicable (local) firmware version
    private var latestApplicableFirmwareVersion: FirmwareVersion? {
        updater?.applicableFirmwares.last?.firmwareIdentifier.version
    }
    /// A boolean to indicate if the update started.
    private var wasUpdateStarted: Bool = false
    /// Whether an automatic reboot should be triggered at the end of the process
    private var automaticReboot: Bool = false

    /// Reference to the updater peripheral
    private var updaterRef: Ref<Updater>?
    private var updater: Updater?
    /// Reference to the system info peripheral
    private var systemInfoRef: Ref<SystemInfo>?

    /// FirmwareToUpdate subject
    private var firmwareToUpdateSubject = CurrentValueSubject<FirmwareToUpdateData?, Never>(nil)
    /// Update subject
    private var updateSubject = CurrentValueSubject<UpdaterUpdate?, Never>(nil)
    /// Download subject
    private var downloadSubject = CurrentValueSubject<UpdaterDownload?, Never>(nil)
    /// Download firmwares subject
    private var downloadableFirmwaresSubject = CurrentValueSubject<[FirmwareInfo], Never>([])
    /// Up to date subject
    private var isUpToDateSubject = CurrentValueSubject<Bool, Never>(false)
    /// Ideal firmware version subject
    private var idealVersionSubject = CurrentValueSubject<FirmwareVersion?, Never>(nil)
    /// Current firmware version subject
    private var firmwareVersionSubject = CurrentValueSubject<String?, Never>(nil)
    private var globalUpdatingStateSubject = CurrentValueSubject<FirmwareGlobalUpdatingState?, Never>(nil)

    // MARK: init
    /// Constructor.
    ///
    /// - Parameters:
    ///   - currentDroneHolder: drone holder
    public init(currentDroneHolder: CurrentDroneHolder) {
        // listen to drone changes
        listen(dronePublisher: currentDroneHolder.dronePublisher)
    }
}

// MARK: Private functions
private extension FirmwareUpdateServiceImpl {
    /// Listens for the current drone.
    ///
    /// - Parameter dronePublisher: the drone publisher
    func listen(dronePublisher: AnyPublisher<Drone, Never>) {
        dronePublisher.sink { [unowned self] drone in
            listenSystemInfo(drone)
            listenUpdater(drone)
        }
        .store(in: &cancellables)
    }

    /// Listens to the `SystemInfo` peripheral.
    func listenSystemInfo(_ drone: Drone) {
        systemInfoRef = drone.getPeripheral(Peripherals.systemInfo) { [weak self] systemInfo in
            self?.firmwareVersionSubject.value = systemInfo?.firmwareVersion
        }
    }

    /// Listens to the updater peripheral
    ///
    /// - Parameter drone: drone to monitor
    func listenUpdater(_ drone: Drone) {
        updaterRef = drone.getPeripheral(Peripherals.updater) { [weak self] updater in
            guard let updater = updater,
                  let self = self else {
                return
            }
            self.updater = updater
            self.updateSubject.value = updater.currentUpdate
            self.downloadSubject.value = updater.currentDownload
            self.downloadableFirmwaresSubject.value = updater.downloadableFirmwares
            self.isUpToDateSubject.value = updater.isUpToDate
            self.idealVersionSubject.value = updater.idealVersion
            self.globalUpdatingStateSubject.value = self.firmwareGlobalUpdatingState()
            self.continueProcessIfNeeded()
        }
    }

    /// Starts the updates
    ///
    /// - Parameter reboot: `true` to make the device reboot automatically at the end of the process
    func startFirmwareUpdate(reboot: Bool) {
        guard let updater = updater else { return }

        let updateStarted = updater.updateToNextFirmware(reboot: reboot)
        if updateStarted {
            ULog.i(.tag, "Firmware update started")
        } else {
            ULog.i(.tag, "Firmware update never started")
            globalUpdatingStateSubject.value = .error
        }
    }

    /// Starts the download.
    func startFirmwareDownload() {
        guard let updater = updater else { return }

        let downloadStarted = updater.downloadAllFirmwares()

        if downloadStarted {
            ULog.i(.tag, "Firmware download started")
        } else {
            ULog.i(.tag, "Firmware download never started")
        }
    }

    /// Cancels the update.
    ///
    /// - Returns: `true` if the operation was successful.
    func cancelFirmwareUpdate() -> Bool {
        guard let updater = updater else { return false }

        guard let updateState = updateSubject.value?.state else {
            ULog.i(.tag, "Firmware update manually cancelled")
            return true
        }

        switch updateState {
        case .uploading:
            ULog.i(.tag, "Firmware update cancelled")
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

    /// Cancels the firmware download.
    ///
    /// - Returns: `true` if the operation was successful.
    func cancelFirmwareDownload() -> Bool {
        guard let updater = updater else { return false }

        guard let downloadState = downloadSubject.value?.state else {
            ULog.i(.tag, "Firmware download manually cancelled")
            return true
        }

        switch  downloadState {
        case .downloading:
            ULog.i(.tag, "Firmware download cancelled")
            return updater.cancelDownload()
        case .canceled,
                .failed,
                .success:
            return true
        }
    }

    /// Continues the firmware process if needed.
    func continueProcessIfNeeded() {
        guard let firmwareToUpdate = firmwareToUpdateSubject.value,
              firmwareToUpdate.allOperationsNeeded.contains(.download)
                && firmwareToUpdate.allOperationsNeeded.contains(.update)
                && !wasUpdateStarted else {
            return
        }

        let shouldStartUpdate: Bool
        switch downloadSubject.value?.state {
        case .success:
            shouldStartUpdate = true
        case .failed:
            if let targetVersion = latestApplicableFirmwareVersion {
                ULog.i(.tag, "download of firmware \(firmwareToUpdate.firmwareIdealVersion) failed, "
                       + "start update with local firmware \(targetVersion)")
                self.firmwareToUpdateSubject.value = FirmwareToUpdateData(firmwareVersion: firmwareToUpdate.firmwareVersion,
                                                             firmwareIdealVersion: firmwareToUpdate.firmwareIdealVersion,
                                                             firmwareVersionToInstall: targetVersion.description,
                                                             firmwareUpdateNeeded: true,
                                                             firmwareNeedToBeDownloaded: true,
                                                             updateState: firmwareToUpdate.updateState,
                                                             droneIsConnected: true)
                shouldStartUpdate = true
            } else {
                fallthrough
            }
        default:
            shouldStartUpdate = false
        }

        if shouldStartUpdate {
            wasUpdateStarted = true
            startFirmwareUpdate(reboot: automaticReboot)
        }
    }

    /// Checks if the update is finished.
    ///
    /// - Returns: `true` if the update is finished.
    func isUpdateFinished() -> Bool {
        guard let updateState = updateSubject.value?.state else { return false }
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
    /// - Returns: `true` if the download is finished.
    func isDownloadFinished() -> Bool {
        guard let downloadState = downloadSubject.value?.state else { return false }

        switch downloadState {
        case .canceled,
                .failed,
                .success:
            return true
        case .downloading:
            return false
        }
    }

    /// Returns true if the processes are finished.
    ///
    /// - Returns: True if the processes are finished.
    func areProcessesFinished() -> Bool {
        guard let firmwareToUpdate = firmwareToUpdateSubject.value else { return false }
        if firmwareToUpdate.allOperationsNeeded.contains(.update) {
            return isUpdateFinished()
        } else if firmwareToUpdate.allOperationsNeeded.contains(.download) {
            return isDownloadFinished()
        } else {
            return false
        }
    }

    /// Checks if the download process or the update process contains an error.
    ///
    /// - Returns: `true` if the download process or the update process contain an error.
    func downloadOrUpdateContainError() -> Bool {
        guard let updateState = updateSubject.value?.state,
              let downloadState = downloadSubject.value?.state else { return false }
        return downloadState == .failed
        || updateState == .failed
        || downloadState == .canceled
        || updateState == .canceled
    }

    /// Returns the current download progress.
    ///
    /// - Returns: The current progress.
    func currentDownloadProgress() -> Int {
        guard let download = downloadSubject.value else { return Constants.minProgress }

        switch download.state {
        case .canceled,
             .failed,
             .success:
            return Constants.maxProgress
        case .downloading:
            return download.totalProgress
        }
    }

    /// Returns the current update progress.
    ///
    /// - Returns: The current progress.
    func currentUpdateProgress() -> Int {

        guard let update = updateSubject.value else {
            ULog.e(.tag, "*** currentUpdateProgress: no UpdaterUpdate")
            return Constants.minProgress
        }

        switch update.state {
        case .uploading,
             .processing:
            return update.currentProgress
        case .waitingForReboot,
             .success,
             .failed,
             .canceled:
            return Constants.maxProgress
        }
    }

    /// Returns the current process progress.
    ///
    /// - Returns: The current progress.
    func currentProcessProgress() -> Int {
        guard let update = updateSubject.value else { return 0 }

        switch update.state {
        case .uploading:
            return Constants.minProgress
        case .processing,
             .waitingForReboot,
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
        guard let update = updateSubject.value else { return 0 }

        switch update.state {
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

    /// Returns the current `FirmwareGlobalUpdatingState`.
    ///
    /// - Returns: The current `FirmwareGlobalUpdatingState`.
    func firmwareGlobalUpdatingState() -> FirmwareGlobalUpdatingState {
        let globalState: FirmwareGlobalUpdatingState

        if firmwareToUpdateSubject.value == nil {
            globalState = .notInitialized
        } else if areProcessesFinished() {
            globalState = downloadOrUpdateContainError() ? .error : .success
        } else if downloadSubject.value?.state == .downloading {
            globalState = .downloading
        } else {
            switch updateSubject.value?.state {
            case .uploading:
                globalState = .uploading
            case .processing:
                globalState = .processing
            case .waitingForReboot:
                globalState = .waitingForReboot
            default:
                globalState = .ongoing
            }
        }
        ULog.i(.tag, "Firmware global state \(globalState)")
        return globalState
    }
}

// MARK: FirmwareUpdateService protocol conformance
extension FirmwareUpdateServiceImpl: FirmwareUpdateService {
    /// Whether legacy update process should be applied, which includes an extra reboot before uploading missions
    public var legacyUpdate: Bool {
        firmwareVersionSubject.value?.starts(with: "7.0") == true
    }
    public var firmwareToUpdatePublisher: AnyPublisher<FirmwareToUpdateData?, Never> {
        firmwareToUpdateSubject.eraseToAnyPublisher()
    }
    public var updatePublisher: AnyPublisher<UpdaterUpdate?, Never> {
        updateSubject.eraseToAnyPublisher()
    }
    public var downloadPublisher: AnyPublisher<UpdaterDownload?, Never> {
        downloadSubject.eraseToAnyPublisher()
    }
    public var downloadableFirmwaresPublisher: AnyPublisher<[FirmwareInfo], Never> {
        downloadableFirmwaresSubject.eraseToAnyPublisher()
    }
    public var isUpToDatePublisher: AnyPublisher<Bool, Never> {
        isUpToDateSubject.eraseToAnyPublisher()
    }
    public var idealVersionPublisher: AnyPublisher<FirmwareVersion?, Never> {
        idealVersionSubject.eraseToAnyPublisher()
    }
    public var firmwareVersionPublisher: AnyPublisher<String?, Never> {
        firmwareVersionSubject.eraseToAnyPublisher()
    }
    public var globalUpdatingStatePublisher: AnyPublisher<FirmwareGlobalUpdatingState?, Never> {
        globalUpdatingStateSubject.eraseToAnyPublisher()
    }

    public func startFirmwareProcesses(reboot: Bool) {
        guard let firmwareToUpdate = firmwareToUpdateSubject.value else {
            globalUpdatingStateSubject.value = firmwareGlobalUpdatingState()
            continueProcessIfNeeded()
            return
        }

        if firmwareToUpdate.allOperationsNeeded.contains(.download) {
            automaticReboot = reboot
            startFirmwareDownload()
        } else if firmwareToUpdate.allOperationsNeeded.contains(.update) {
            startFirmwareUpdate(reboot: reboot)
        } else {
            globalUpdatingStateSubject.value = firmwareGlobalUpdatingState()
            continueProcessIfNeeded()
            return
        }
    }

    public func prepareUpdate(updateChoice: FirmwareAndMissionUpdateChoice) {
        wasUpdateStarted = false
        firmwareToUpdateSubject.value = updateChoice.firmwareToUpdate
    }

    public func currentProgress(for operation: FirwmwareToUpdateOperation) -> Int {
        switch operation {
        case .download:
            return currentDownloadProgress()
        case .update:
            return currentUpdateProgress()
        case .process:
            return currentProcessProgress()
        case .reboot:
            return currentRebootProgress()
        }
    }

    public func currentUpdatingStep(for operation: FirwmwareToUpdateOperation) -> CurrentUpdatingStep {
        switch operation {
        case .download:
            guard let downloadState = downloadSubject.value?.state else { return .waiting }

            return CurrentUpdatingStep(firmwareDownloadingState: downloadState)
        case .update:
            guard let updateState = updateSubject.value?.state else { return .waiting }
            return CurrentUpdatingStep(firmwareUpdatingState: updateState)
        case .process:
            guard let updateState = updateSubject.value?.state else { return .waiting }
            return CurrentUpdatingStep(firmwareUpdatingState: updateState, forProcess: true)
        case .reboot:
            guard let updateState = updateSubject.value?.state else { return .waiting }
            return CurrentUpdatingStep(firmwareUpdatingState: updateState, forReboot: true)
        }
    }

    public func firmwareAndMissionUpdateRequirementStatus(
        hasMissionToUpdate: Bool,
        hasFirmwareToUpdate: Bool,
        onlyNeedFirmwareDownload: Bool,
        isNetworkReachable: Bool
    ) -> FirmwareAndMissionUpdateRequirements {
        if onlyNeedFirmwareDownload && !hasMissionToUpdate {
            return isNetworkReachable ? .readyForUpdate : .noInternetConnection
        }

        guard let updater = updater else {
            return .noInternetConnection
        }

        if let firstReason = updater.updateUnavailabilityReasons.first {
            return FirmwareAndMissionUpdateRequirements(unavailabilityReason: firstReason)
        } else if hasFirmwareToUpdate
                    && !isNetworkReachable
                    && !updater.downloadableFirmwares.isEmpty
                    && !updater.applicableFirmwares.isEmpty {
            return .noInternetConnection
        }
        return .readyForUpdate
    }

    public func cancelFirmwareProcesses(removeData: Bool) -> Bool {
        if removeData { firmwareToUpdateSubject.value = nil }
        let cancelFirmwareDownload = cancelFirmwareDownload()
        let cancelFirmwareUpdate = cancelFirmwareUpdate()
        return cancelFirmwareDownload && cancelFirmwareUpdate
    }
}
