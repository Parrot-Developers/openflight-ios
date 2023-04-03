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

// MARK: - Private Enum
private enum Constants {
    static let minProgress: Float = 0.0
    static let maxProgress: Float = 100.0
}

// MARK: - Internal Enums
/// Stores manual rebooting state.
enum FirmwareAndMissionsManualRebootingState {
    case waiting
    case ongoing
    case succeeded
    case failed
}

class FirmwareAndMissionsUpdateViewModel {
    private var airSdkMissionsUpdaterService: AirSdkMissionsUpdaterService
    private var firmwareUpdateService: FirmwareUpdateService
    private var currentDroneHolder: CurrentDroneHolder
    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()
    private var connectionStateRef: Ref<DeviceState>?

    /// Rebooting State: state for the reboot row of the table view.
    var manualRebootState: FirmwareAndMissionsManualRebootingState = .waiting {
        didSet {
            updateManualRebootState()
        }
    }
    @Published private(set) var elements: [FirmwareMissionsUpdatingCase] = []
    @Published private(set) var currentTotalProgress: Float = Constants.minProgress
    @Published private(set) var firmwareUpdatingState: FirmwareGlobalUpdatingState = .notInitialized
    @Published private(set) var missionsUpdatingState: AirSdkMissionsGlobalUpdatingState = .ongoing
    @Published private(set) var needsReboot: Bool = false
    @Published private(set) var isDroneConnected: Bool = false

    init(airSdkMissionsUpdaterService: AirSdkMissionsUpdaterService,
         firmwareUpdateService: FirmwareUpdateService,
         currentDroneHolder: CurrentDroneHolder) {
        self.airSdkMissionsUpdaterService = airSdkMissionsUpdaterService
        self.firmwareUpdateService = firmwareUpdateService
        self.currentDroneHolder = currentDroneHolder
        listenUpdates()
        listenUpdatingState()
        currentDroneHolder.dronePublisher
            .sink { [weak self] drone in
                self?.listenConnectionState(drone)
            }
            .store(in: &cancellables)
    }

    func listenUpdates() {
        firmwareUpdateService.updatePublisher
            .combineLatest(
                firmwareUpdateService.firmwareToUpdatePublisher,
                airSdkMissionsUpdaterService.missionsToUpdatePublisher)
            .sink { [weak self] _, firmwareToUpdate, missions in
                guard let self = self else { return }
                guard let firmwareToUpdate = firmwareToUpdate else {
                    self.currentTotalProgress = Constants.minProgress
                    self.elements = []
                    return
                }
                self.updateMissionUpdatingState(missions)

                var temporaryProgress: Float = Constants.minProgress
                var temporaryElements: [FirmwareMissionsUpdatingCase] = []

                if firmwareToUpdate.allOperationsNeeded.contains(.download) {
                    temporaryProgress += Float(self.firmwareUpdateService.currentProgress(for: .download))
                    let updatingStep = self.firmwareUpdateService.currentUpdatingStep(for: .download)
                    temporaryElements.append(.downloadingFirmware(updatingStep, firmwareToUpdate))
                }
                if firmwareToUpdate.allOperationsNeeded.contains(.update) {
                    temporaryProgress += Float(self.firmwareUpdateService.currentProgress(for: .update))
                    let updatingStep = self.firmwareUpdateService.currentUpdatingStep(for: .update)
                    temporaryElements.append(.updatingFirmware(updatingStep, firmwareToUpdate))
                }
                if firmwareToUpdate.allOperationsNeeded.contains(.reboot) {
                    if self.isLegacyUpdate() {
                        temporaryProgress += Float(self.firmwareUpdateService.currentProgress(for: .reboot))
                        let updatinStep = self.firmwareUpdateService.currentUpdatingStep(for: .reboot)
                        temporaryElements.append(.reboot(updatinStep))
                    } else {
                        temporaryProgress += Float(self.firmwareUpdateService.currentProgress(for: .process))
                        let updatinStep = self.firmwareUpdateService.currentUpdatingStep(for: .process)
                        temporaryElements.append(.processingFirmware(updatinStep))
                    }
                }

                // Add missions to the list
                for mission in missions {
                    let missionUpdatingCase = mission.status.updatingCase
                    temporaryProgress += Float(mission.currentProgress)
                    temporaryElements.append(.mission(missionUpdatingCase, mission.data))
                }

                // Add the reboot line.
                switch self.manualRebootState {
                case .waiting:
                    temporaryElements.append(.reboot(.waiting))
                case .ongoing:
                    temporaryElements.append(.reboot(.loading))
                case .succeeded:
                    temporaryElements.append(.reboot(.succeeded))
                    temporaryProgress += Constants.maxProgress
                case .failed:
                    temporaryElements.append(.reboot(.failed(L10n.firmwareMissionUpdateOperationFailedNeverStarted)))
                    temporaryProgress += Constants.maxProgress
                }

                self.elements = temporaryElements
                self.currentTotalProgress = self.elements.isEmpty ? Constants.maxProgress : temporaryProgress / Float(self.elements.count)
            }
            .store(in: &cancellables)

    }

    func listenUpdatingState() {
        firmwareUpdateService.globalUpdatingStatePublisher
            .sink { [weak self] globalUpdatingState in
                self?.firmwareUpdatingState = globalUpdatingState ?? .notInitialized
            }
            .store(in: &cancellables)
    }

    /// Starts watcher for drone's connection state.
    ///
    /// - Parameter drone: the current drone
    private func listenConnectionState(_ drone: Drone) {
        connectionStateRef = drone.getState { [weak self] state in
            self?.isDroneConnected = state?.connectionState == .connected
        }
    }

    private func updateMissionUpdatingState(_ missions: [MissionToUpdate]) {
        var uploading = false
        var waiting = false
        for mission in missions {
            if case .onGoingUpdate = mission.status {
                uploading = true
            }
            if case .waitingForUpdate = mission.status {
                waiting = true
            }
            if case .updateDone = mission.status {
                needsReboot = true
            }
        }
        if uploading {
            missionsUpdatingState = .uploading
        } else if waiting {
            missionsUpdatingState = .ongoing
        } else {
            missionsUpdatingState = .done
        }
    }

    func updateManualRebootState() {
        if let index = elements.firstIndex(where: { element in
            if case .reboot = element {
                return true
            }
            return false
        }) {
            switch manualRebootState {
            case .waiting:
                elements[index] = .reboot(.waiting)
            case .ongoing:
                elements[index] = .reboot(.loading)
            case .succeeded:
                elements[index] = .reboot(.succeeded)
            case .failed:
                elements[index] = .reboot(.failed(L10n.firmwareMissionUpdateOperationFailedNeverStarted))
            }
        }
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

    func isLegacyUpdate() -> Bool {
        firmwareUpdateService.legacyUpdate
    }

    func missionsUpdateProcessHasError() -> Bool {
        airSdkMissionsUpdaterService.missionsUpdateProcessHasError()
    }

    func missionsUpdateProcessNeedAReboot() -> Bool {
        airSdkMissionsUpdaterService.missionsUpdateProcessNeedAReboot()
    }

    func startFirmwareProcesses(reboot: Bool) {
        firmwareUpdateService.startFirmwareProcesses(reboot: reboot)
    }

    func startMissionsUpdateProcess(postpone: Bool) {
        airSdkMissionsUpdaterService.startMissionsUpdateProcess(postpone: postpone)
    }

    func triggerManualReboot() {
        airSdkMissionsUpdaterService.triggerManualReboot()
    }
}
