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

import Combine
import GroundSdk

class DroneFirmwaresViewModel {
    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()
    private var currentDroneHolder: CurrentDroneHolder
    private var networkService: NetworkService
    private var updateService: UpdateService
    private var firmwareUpdateService: FirmwareUpdateService
    private var airSdkMissionsUpdaterService: AirSdkMissionsUpdaterService
    private var airSdkMissionManager: AirSdkMissionsManager
    private var batteryGaugeUpdaterService: BatteryGaugeUpdaterService
    private var connectionStateRef: Ref<DeviceState>?
    private var isNetworkReachable: Bool = false
    /// The update elements subject.
    private var elementsSubject = CurrentValueSubject<[FirmwareAndMissionUpdateChoice], Never>([])

    /// The update elements publisher.
    var elementsPublisher: AnyPublisher<[FirmwareAndMissionUpdateChoice], Never> { elementsSubject.eraseToAnyPublisher() }
    @Published var isDroneConnected: Bool = false
    @Published var isFirmwareUpdateNeeded: Bool = false

    /// The update elements.
    private(set) var elements: [FirmwareAndMissionUpdateChoice] {
        get { elementsSubject.value }
        set { elementsSubject.value = newValue }
    }

    // MARK: - Init
    init(
        currentDroneHolder: CurrentDroneHolder,
        networkService: NetworkService,
        updateService: UpdateService,
        firmwareUpdateService: FirmwareUpdateService,
        airSdkMissionsUpdaterService: AirSdkMissionsUpdaterService,
        airSdkMissionManager: AirSdkMissionsManager,
        batteryGaugeUpdaterService: BatteryGaugeUpdaterService
    ) {
        self.currentDroneHolder = currentDroneHolder
        self.networkService = networkService
        self.updateService = updateService
        self.firmwareUpdateService = firmwareUpdateService
        self.airSdkMissionManager = airSdkMissionManager
        self.airSdkMissionsUpdaterService = airSdkMissionsUpdaterService
        self.batteryGaugeUpdaterService = batteryGaugeUpdaterService
        self.elements = []

        currentDroneHolder.dronePublisher
            .sink { [weak self] drone in
                self?.listenConnectionState(drone)
            }
            .store(in: &cancellables)

        let firmwarePublishers = firmwareUpdateService.firmwareVersionPublisher
            .combineLatest(firmwareUpdateService.idealVersionPublisher,
                           firmwareUpdateService.downloadableFirmwaresPublisher,
                           batteryGaugeUpdaterService.statePublisher)
        airSdkMissionManager.allMissionsOnDronePublisher
            .combineLatest($isDroneConnected, updateService.droneUpdatePublisher,
                           firmwarePublishers )
            .receive(on: RunLoop.main)
            .sink { [weak self] allMissionsOnDrone, isDroneConnected, updateState, firmware  in
                guard let self = self else { return }
                let (firmwareVersion, idealVersion, downloadableFirmwares, batteryGaugeUpdaterState) = firmware
                let versionToInstall = idealVersion?.description ?? ""
                let firmwareToUpdateData = FirmwareToUpdateData(
                    firmwareVersion: firmwareVersion ?? "",
                    firmwareIdealVersion: versionToInstall,
                    firmwareVersionToInstall: versionToInstall,
                    firmwareUpdateNeeded: updateState != .upToDate,
                    firmwareNeedToBeDownloaded: !downloadableFirmwares.isEmpty,
                    updateState: updateState ?? .upToDate,
                    droneIsConnected: isDroneConnected)
                let allMissionsOnFile = airSdkMissionManager.allAirSdkMissionsOnFiles()
                self.createUpdateList(
                    firmwareToUpdateData: firmwareToUpdateData,
                    allMissionsOnDrone: allMissionsOnDrone,
                    allMissionsOnFile: allMissionsOnFile,
                    batteryGaugeUpdaterState: batteryGaugeUpdaterState)
            }
            .store(in: &cancellables)
    }

    func listenNetwork() {
        networkService.networkReachable
            .removeDuplicates()
            .sink { [weak self] reachable in
                guard let self = self else { return }
                self.isNetworkReachable = reachable
            }
            .store(in: &cancellables)
    }

    private func createUpdateList(
        firmwareToUpdateData: FirmwareToUpdateData,
        allMissionsOnDrone: [AirSdkMissionBasicInformation],
        allMissionsOnFile: [AirSdkMissionToUpdateData],
        batteryGaugeUpdaterState: BatteryGaugeUpdaterState?) {

            var temporaryElements: [FirmwareAndMissionUpdateChoice] = [.firmware(firmwareToUpdateData)]
            var temporaryAllPotentialMissionsToUpdate: [AirSdkMissionToUpdateData] = []

            // Step one: Fill temporaryElements with missions to update and missions up to date that are present on the drone.
            for missionOnDrone in allMissionsOnDrone {
                let missionOnFile = allMissionsOnFile.first(where: { $0.isSameAndGreaterVersion(of: missionOnDrone) })
                let compatibility = missionOnFile?.compatibility(with: firmwareToUpdateData.firmwareVersion)

                if let missionOnFile = missionOnFile,
                   let compatibility = compatibility,
                   compatibility != .tooRecent {
                    temporaryElements.append(
                        .airSdkMission(missionOnFile, missionOnDrone: missionOnDrone, compatibility: compatibility))
                    temporaryAllPotentialMissionsToUpdate.append(missionOnFile)
                } else {
                    temporaryElements.append(.upToDateAirSdkMission(missionOnDrone))
                }
            }

            // Step two: Fill temporaryElements with missions to update that are not present on the drone.
            for missionOnFile in allMissionsOnFile {
                let compatibility = missionOnFile.compatibility(with: firmwareToUpdateData.firmwareVersion)

                if !allMissionsOnDrone.contains(where: { $0.missionUID == missionOnFile.missionUID }) &&
                    compatibility != .tooRecent {
                    temporaryElements.append(
                        .airSdkMission(missionOnFile, missionOnDrone: nil, compatibility: compatibility))
                    temporaryAllPotentialMissionsToUpdate.append(missionOnFile)
                }
            }

            // Add the "Update all" row.
            temporaryElements.append(.firmwareAndAirSdkMissions(
                firmware: firmwareToUpdateData,
                missions: temporaryAllPotentialMissionsToUpdate))

            // Add the battery gauge row
            if batteryGaugeUpdaterState == .readyToPrepare || batteryGaugeUpdaterState == .readyToUpdate {
                temporaryElements.append(.batteryGaugeUpdate)
            }

            temporaryElements.sort(by: <)

            // Search last built-in mission, which will allow drawing element tree properly.
            var index = temporaryElements.count - 1
        elementLoop: while index >= 0 {
            let element = temporaryElements[index]
            switch element {
            case let .upToDateAirSdkMission(mission, _):
                if mission.isBuiltIn {
                    temporaryElements[index] = .upToDateAirSdkMission(mission, isLastBuiltIn: true)
                    break elementLoop
                } else {
                    fallthrough
                }
            default:
                index -= 1
            }
        }
        elements = temporaryElements
        isFirmwareUpdateNeeded = !firmwareToUpdateData.allOperationsNeeded.isEmpty
    }

    func prepareUpdates(updateChoice: FirmwareAndMissionUpdateChoice) -> FirmwareAndMissionUpdateRequirements {

        if !cancelAllUpdates(removeData: true) { return .ongoingUpdate }

        firmwareUpdateService.prepareUpdate(updateChoice: updateChoice)
        airSdkMissionsUpdaterService.prepareMissionsUpdates(updateChoice: updateChoice)
        return requirementStatus(for: updateChoice)
    }

    /// Starts watcher for drone's connection state.
    ///
    /// - Parameter drone: the current drone
    func listenConnectionState(_ drone: Drone) {
        connectionStateRef = drone.getState { [weak self] state in
            self?.isDroneConnected = state?.connectionState == .connected
        }
    }

    /// Checks if the update processes can be launched.
    ///
    /// - Parameters:
    ///    - updateChoice:The current update choice
    /// - Returns: a`FirmwareAndMissionUpdateRequirements`.
    func requirementStatus(for updateChoice: FirmwareAndMissionUpdateChoice) -> FirmwareAndMissionUpdateRequirements {
        let onlyNeedFirmwareDownload: Bool
        if let firmware = updateChoice.firmwareToUpdate,
           firmware.allOperationsNeeded.contains(.download)
            && !firmware.allOperationsNeeded.contains(.update) {
            onlyNeedFirmwareDownload = true
        } else {
            onlyNeedFirmwareDownload = false
        }

        return firmwareUpdateService.firmwareAndMissionUpdateRequirementStatus(
            hasMissionToUpdate: !updateChoice.missionsToUpdate.isEmpty,
            hasFirmwareToUpdate: updateChoice.needToUpdateFirmware,
            onlyNeedFirmwareDownload: onlyNeedFirmwareDownload,
            isNetworkReachable: true)
    }

    /// Cancels and cleans all potentials updates.
    ///
    /// - Parameters:
    ///    - removeData: A boolean to indicate if data must be removed.
    /// - Returns: True if the operation was successful.
    func cancelAllUpdates(removeData: Bool) -> Bool {
        let missionCancelSuccess = airSdkMissionsUpdaterService.cancelAllMissionsUpdates(removeData: removeData)
        let firmwareCancelSuccess = firmwareUpdateService.cancelFirmwareProcesses(removeData: removeData)
        return firmwareCancelSuccess && missionCancelSuccess
    }
}
