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

import Foundation
import Combine
import GroundSdk

private extension ULogTag {
    static let tag = ULogTag(name: "FirmwareUpdatingViewModel")
}

class FirmwareUpdatingViewModel {
    // MARK: - Private Enum
    private enum Constants {
        static let minProgress: Float = 0.0
        static let maxProgress: Float = 100.0
    }

    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()
    private var firmwareUpdateService: FirmwareUpdateService
    private var currentDroneHolder: CurrentDroneHolder
    private var connectionStateRef: Ref<DeviceState>?
    private var elementsSubject = CurrentValueSubject<[FirmwareMissionsUpdatingCase], Never>([])
    private var currentTotalProgressSubject = CurrentValueSubject<Float, Never>(Constants.minProgress)

    @Published var globalUpdatingState: FirmwareGlobalUpdatingState = .notInitialized
    @Published private(set) var isDroneConnected: Bool = false
    var elementsPublisher: AnyPublisher<[FirmwareMissionsUpdatingCase], Never> {
        elementsSubject.eraseToAnyPublisher()
    }
    var elements: [FirmwareMissionsUpdatingCase] {
        elementsSubject.value
    }
    var currentTotalProgressPublisher: AnyPublisher<Float, Never> {
        currentTotalProgressSubject.eraseToAnyPublisher()
    }
    var currentTotalProgress: Float {
        currentTotalProgressSubject.value
    }
    init(firmwareUpdateService: FirmwareUpdateService, currentDroneHolder: CurrentDroneHolder) {
        self.firmwareUpdateService = firmwareUpdateService
        self.currentDroneHolder = currentDroneHolder
        listenUpdate()
        listenUpdatingState()
        currentDroneHolder.dronePublisher
            .sink { [weak self] drone in
                self?.listenConnectionState(drone)
            }
            .store(in: &cancellables)
    }

    func listenUpdate() {
        firmwareUpdateService.updatePublisher
            .combineLatest(firmwareUpdateService.firmwareToUpdatePublisher)
            .sink { [weak self] _, firmwareToUpdate in
                guard let self = self else { return }
                guard let firmwareToUpdate = firmwareToUpdate else {
                    self.currentTotalProgressSubject.value = Constants.minProgress
                    return
                }
                // Do not update the list anymore if success.
                guard self.globalUpdatingState != .success else { return }

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
                    temporaryProgress += Float(self.firmwareUpdateService.currentProgress(for: .reboot))
                    let updatingStep = self.firmwareUpdateService.currentUpdatingStep(for: .reboot)
                    temporaryElements.append(.reboot(updatingStep))
                }

                ULog.d(.tag, "listenUpdate new elements: \(temporaryElements)")
                self.elementsSubject.value = temporaryElements
                self.currentTotalProgressSubject.value = temporaryElements.isEmpty ? Constants.maxProgress : temporaryProgress / Float(temporaryElements.count)
            }
            .store(in: &cancellables)
    }

    func listenUpdatingState() {
        firmwareUpdateService.globalUpdatingStatePublisher
            .sink { [weak self] globalUpdatingState in
                self?.globalUpdatingState = globalUpdatingState ?? .notInitialized
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

    func startFirmwareProcesses(reboot: Bool) {
        firmwareUpdateService.startFirmwareProcesses(reboot: reboot)
    }

    /// Cancels and cleans all potentials updates.
    ///
    /// - Parameters:
    ///    - removeData: A boolean to indicate if data must be removed.
    /// - Returns: True if the operation was successful.
    func cancelAllUpdates(removeData: Bool) -> Bool {
        return firmwareUpdateService.cancelFirmwareProcesses(removeData: removeData)
    }
}
