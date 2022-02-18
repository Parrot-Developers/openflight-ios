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

import Foundation

/// This interactor manages the firmware and missions updates.
public final class FirmwareAndMissionsInteractor {
    // MARK: - Public Properties
    /// This interactor is a singleton.
    public static let shared = FirmwareAndMissionsInteractor()

    // MARK: - Private Properties
    /// All missions on files.
    private let allMissionsOnFiles = AirSdkMissionsToUploadFinder.allAirSdkMissionsOnFiles()
    /// The `DroneFirmwaresViewController` data source.
    private var firmwareAndMissionsDataSource = DroneFirmwaresDataSource()
    /// The `FirmwareAndMissionToUpdateModel` used in multiple views in the application.
    private var firmwareAndMissionToUpdateModel: FirmwareAndMissionToUpdateModel = .notInitialized
    /// The `FirmwareUpdateInfoViewModel` that this interactor listens to in order to build its data.
    private lazy var firmwareUpdateInfoViewModel: FirmwareUpdateInfoViewModel = {
        let viewModel = FirmwareUpdateInfoViewModel()
        viewModel.state.valueChanged = { (firmwareUpdateInfoState) in
            self.firmwareUpdateInfoCallback(firmwareUpdateInfoState: firmwareUpdateInfoState)
        }

        return viewModel
    }()

    /// The `AirSdkMissionsUpdaterWrapper` that this interactor listens to in order to build its data.
    private lazy var airSdkMissionsUpdaterWrapper: AirSdkMissionsUpdaterWrapper = {
        let wrapper = AirSdkMissionsUpdaterWrapper()
        wrapper.state.valueChanged = { (airSdkMissionUpdateState) in
            self.airSdkMissionUpdateCallback(airSdkMissionUpdateState: airSdkMissionUpdateState)
        }

        return wrapper
    }()

    /// The `AirSdkMissionsUpdaterManager` to achieve some operations before the update process.
    private let airSdkMissionsUpdaterManager = AirSdkMissionsUpdaterManager.shared
    /// The `FirmwareUpdaterManager` to achieve some operations before the update process.
    private let firmwareUpdaterManager = FirmwareUpdaterManager.shared
    /// The listeners
    private var listeners: Set<FirmwareAndMissionsListener> = []

    // MARK: - Init
    private init() {}

    // MARK: - Public Funcs
    /// Call this function once in the lifecycle of the application to start to listen to missions and firmware updates information.
    public func setup() {
        firmwareUpdaterManager.setup()
        airSdkMissionsUpdaterManager.setup()
        _ = firmwareUpdateInfoViewModel
        _ = airSdkMissionsUpdaterWrapper
    }
}

// MARK: - Internal Funcs
extension FirmwareAndMissionsInteractor {
    /// Prepare the updates and returns a `FirmwareAndMissionUpdateRequirementStatus`.
    ///
    /// - Parameters:
    ///    - updateChoice:The current update choice
    /// - Returns: The current `FirmwareAndMissionUpdateRequirementStatus`.
    func prepareUpdates(updateChoice: FirmwareAndMissionUpdateChoice) -> FirmwareAndMissionUpdateRequirements {
        if !cancelAllUpdates(removeData: true) { return .ongoingUpdate }

        firmwareUpdaterManager.prepareUpdate(updateChoice: updateChoice)
        airSdkMissionsUpdaterManager.prepareMissionsUpdates(updateChoice: updateChoice)

        return requirementStatus(for: updateChoice)
    }

    /// Cancels and cleans all potentials updates.
    ///
    /// - Parameters:
    ///    - removeData: A boolean to indicate if data must be removed.
    /// - Returns: True if the operation was successful.
    func cancelAllUpdates(removeData: Bool) -> Bool {
        let missionCancelSuccess = airSdkMissionsUpdaterManager.cancelAllMissionsUpdates(removeData: removeData)
        let firmwareCancelSuccess = firmwareUpdaterManager.cancelFirmwareProcesses(removeData: removeData)

        return firmwareCancelSuccess && missionCancelSuccess
    }

    /// Cancels all potentials firmware updates and download.
    ///
    /// - Parameters:
    ///    - removeData: A boolean to indicate if data must be removed.
    /// - Returns: True if the operation was successful.
    func cancelFimwareProcesses(removeData: Bool) -> Bool {
        return firmwareUpdaterManager.cancelFirmwareProcesses(removeData: removeData)
    }

    /// Cancels all potentials missions updates.
    ///
    /// - Parameters:
    ///    - removeData: A boolean to indicate if data must be removed.
    /// - Returns: True if the operation was successful.
    func cancelMissionsProcesses(removeData: Bool) -> Bool {
        return airSdkMissionsUpdaterManager.cancelAllMissionsUpdates(removeData: removeData)
    }

    /// Manually browse the missions on drone.
    func manuallyBrowse() {
        airSdkMissionsUpdaterManager.manuallyBrowse()
    }
}

/// Utils for listener management.
extension FirmwareAndMissionsInteractor {
    /// Registers a listener.
    ///
    /// - Parameters:
    ///   - firmwareAndMissionsClosure: The callback triggered for any event related to the mission's update
    /// - Returns: The listener.
    func register(firmwareAndMissionsClosure: @escaping FirmwareAndMissionsClosure) -> FirmwareAndMissionsListener {
        let listener = FirmwareAndMissionsListener(firmwareAndMissionsCallback: firmwareAndMissionsClosure)
        listeners.insert(listener)
        listener.firmwareAndMissionsCallback(firmwareAndMissionsDataSource,
                                             firmwareAndMissionToUpdateModel)

        return listener
    }

    /// Unregisters a listener.
    ///
    /// - Parameters:
    ///     - listener: The listener to unregister
    func unregister(_ listener: FirmwareAndMissionsListener?) {
        if let listener = listener {
            listeners.remove(listener)
        }
    }
}

// MARK: - Private Funcs
private extension FirmwareAndMissionsInteractor {
    /// Listens to `FirmwareUpdateInfoViewModel` updates and builds the current data.
    ///
    /// - Parameters:
    ///     - firmwareUpdateInfoState: The state given by `FirmwareUpdateInfoViewModel`
    func firmwareUpdateInfoCallback(firmwareUpdateInfoState: FirmwareUpdateInfoState) {
        let airSdkMissionUpdateState = airSdkMissionsUpdaterWrapper.state.value
        buildAllInteractorData(with: firmwareUpdateInfoState,
                               airSdkMissionUpdateState: airSdkMissionUpdateState)
    }

    /// Listens to  `AirSdkMissionsUpdaterWrapper`updates  and builds the current data.
    ///
    /// - Parameters:
    ///     - airSdkMissionUpdateState: The state given by `AirSdkMissionsUpdaterWrapper`
    func airSdkMissionUpdateCallback(airSdkMissionUpdateState: AirSdkMissionsUpdaterState) {
        let firmwareUpdateInfoState = firmwareUpdateInfoViewModel.state.value
        buildAllInteractorData(with: firmwareUpdateInfoState,
                               airSdkMissionUpdateState: airSdkMissionUpdateState)
    }

    /// Builds the current data .
    ///
    /// - Parameters:
    ///     - firmwareUpdateInfoState: The state given by `FirmwareUpdateInfoViewModel`
    func buildAllInteractorData(with firmwareUpdateInfoState: FirmwareUpdateInfoState,
                                airSdkMissionUpdateState: AirSdkMissionsUpdaterState) {
        // Case 1: Failure to build a FirmwareToUpdateData.
        guard let firmwareToUpdateData = firmwareUpdateInfoViewModel.firmwareToUpdateData() else {
            firmwareAndMissionToUpdateModel = .notInitialized
            firmwareAndMissionsDataSource = DroneFirmwaresDataSource()
            listeners.forEach { (listener) in
                listener.firmwareAndMissionsCallback(firmwareAndMissionsDataSource,
                                                     firmwareAndMissionToUpdateModel)
            }

            return
        }

        // Case 2: a FirmwareToUpdateData exists.
        firmwareAndMissionsDataSource = DroneFirmwaresDataSource(
            firmwareToUpdateData: firmwareToUpdateData,
            allMissionsOnDrone: airSdkMissionUpdateState.allMissionsOnDrone,
            allMissionsOnFile: allMissionsOnFiles,
            isDroneConnected: firmwareUpdateInfoState.isConnected())

        firmwareAndMissionToUpdateModel = FirmwareAndMissionToUpdateModel(
            firmwareToUpdateData: firmwareToUpdateData,
            firmwareAndMissionsDataSource: firmwareAndMissionsDataSource,
            isDroneConnected: firmwareUpdateInfoState.isConnected())

        listeners.forEach { (listener) in
            listener.firmwareAndMissionsCallback(firmwareAndMissionsDataSource,
                                                 firmwareAndMissionToUpdateModel)
        }
    }

    /// Checks if the update processes can be launched.
    ///
    /// - Parameters:
    ///    - updateChoice:The current update choice
    /// - Returns: a`FirmwareAndMissionUpdateRequirementStatus`.
    func requirementStatus(for updateChoice: FirmwareAndMissionUpdateChoice) -> FirmwareAndMissionUpdateRequirements {
        let onlyNeedFirmwareDownload: Bool
        if let firmware = updateChoice.firmwareToUpdate,
           firmware.allOperationsNeeded.contains(.download)
            && !firmware.allOperationsNeeded.contains(.update) {
            onlyNeedFirmwareDownload = true
        } else {
            onlyNeedFirmwareDownload = false
        }

        return firmwareUpdateInfoViewModel.firmwareAndMissionUpdateRequirementStatus(
            hasMissionToUpdate: !updateChoice.missionsToUpdate.isEmpty,
            hasFirmwareToUpdate: updateChoice.needToUpdateFirmware,
            onlyNeedFirmwareDownload: onlyNeedFirmwareDownload)
    }
}
