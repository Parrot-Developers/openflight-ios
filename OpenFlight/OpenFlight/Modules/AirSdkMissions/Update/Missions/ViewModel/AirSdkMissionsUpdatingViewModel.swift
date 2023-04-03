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

// MARK: - Internal Enums
/// Stores each mission rebooting state.
enum AirSdkMissionsManualRebootingState {
    case waiting
    case ongoing
    case succeeded
    case failed
}

class AirSdkMissionsUpdatingViewModel {
    // MARK: - Private Enum
    private enum Constants {
        static let minProgress: Float = 0.0
        static let maxProgress: Float = 100
    }

    private var airSdkMissionsUpdaterService: AirSdkMissionsUpdaterService
    private var currentDroneHolder: CurrentDroneHolder
    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()
    private var connectionStateRef: Ref<DeviceState>?
    private var elementsSubject = CurrentValueSubject<[FirmwareMissionsUpdatingCase], Never>([])

    /// Rebooting State: state for the reboot row of the table view.
    var manualRebootState: AirSdkMissionsManualRebootingState = .waiting {
        didSet {
            updateManualRebootState()
        }
    }

    @Published private(set) var currentTotalProgress: Float = Constants.minProgress
    @Published private(set) var globalUpdatingState: AirSdkMissionsGlobalUpdatingState = .ongoing
    @Published private(set) var isRebootNeeded: Bool = false
    @Published private(set) var isDroneConnected: Bool = false
    var elementsPublisher: AnyPublisher<[FirmwareMissionsUpdatingCase], Never> {
        elementsSubject.eraseToAnyPublisher()
    }
    var elements: [FirmwareMissionsUpdatingCase] {
        elementsSubject.value
    }

    init(airSdkMissionsUpdaterService: AirSdkMissionsUpdaterService,
         currentDroneHolder: CurrentDroneHolder) {
        self.airSdkMissionsUpdaterService = airSdkMissionsUpdaterService
        self.currentDroneHolder = currentDroneHolder
        listenMissions()
        currentDroneHolder.dronePublisher
            .sink { [weak self] drone in
                self?.listenConnectionState(drone)
            }
            .store(in: &cancellables)
    }

    private func listenMissions() {
        airSdkMissionsUpdaterService.missionsToUpdatePublisher.sink { [weak self] missions in
            guard let self = self else { return }
            self.updateGlobalState(missions)
            self.updateMissionList(missions)
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

    /// Updates the global state of the update process.
    ///
    /// This is used to update the view labels and progress animations.
    /// - parameter missions: Array of missions to update.
    private func updateGlobalState(_ missions: [MissionToUpdate]) {
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
                isRebootNeeded = true
            }
        }
        if uploading {
            globalUpdatingState = .uploading
        } else if waiting {
            globalUpdatingState = .ongoing
        } else {
            globalUpdatingState = .done
        }
    }

    /// Updates the mission tableview datasource and current progress value based on missions to update.
    /// - parameter missions: Array of missions to update.
    private func updateMissionList(_ missions: [MissionToUpdate]) {
        var temporaryElements: [FirmwareMissionsUpdatingCase] = []
        var temporaryProgress: Float = Constants.minProgress
        for mission in missions {
            let missionUpdatingCase = mission.status.updatingCase
            temporaryProgress += Float(mission.currentProgress)
            temporaryElements.append(.mission(missionUpdatingCase, mission.data))
        }

        switch manualRebootState {
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
        elementsSubject.value = temporaryElements
        currentTotalProgress = temporaryElements.isEmpty ? Constants.maxProgress : temporaryProgress / Float(temporaryElements.count)
    }

    /// Calls the service to start the update process.
    func startMissionsUpdateProcess() {
        airSdkMissionsUpdaterService.startMissionsUpdateProcess(postpone: false)
    }

    /// Calls the service to trigger the reboot once the missions have been sent.
    func triggerManualReboot() {
        airSdkMissionsUpdaterService.triggerManualReboot()
    }

    /// Returns `true` if the service returns an error for the update process.
    func missionsUpdateProcessHasError() -> Bool {
        airSdkMissionsUpdaterService.missionsUpdateProcessHasError()
    }

    /// Updates the manual reboot state, used to display the last row of the tableview.
    ///
    /// This is used to keep the view active and waiting while the drone restarts.
    func updateManualRebootState() {
        if let index = elements.firstIndex(where: { element in
            if case .reboot = element {
                return true
            }
            return false
        }) {
            switch manualRebootState {
            case .waiting:
                elementsSubject.value[index] = .reboot(.waiting)
            case .ongoing:
                elementsSubject.value[index] = .reboot(.loading)
            case .succeeded:
                elementsSubject.value[index] = .reboot(.succeeded)
            case .failed:
                elementsSubject.value[index] = .reboot(.failed(L10n.firmwareMissionUpdateOperationFailedNeverStarted))
            }
        }
    }

    /// Cancels and cleans all potentials updates.
    ///
    /// - Parameters:
    ///    - removeData: A boolean to indicate if data must be removed.
    /// - Returns: True if the operation was successful.
    func cancelAllUpdates(removeData: Bool) -> Bool {
        return airSdkMissionsUpdaterService.cancelAllMissionsUpdates(removeData: removeData)
    }
}
