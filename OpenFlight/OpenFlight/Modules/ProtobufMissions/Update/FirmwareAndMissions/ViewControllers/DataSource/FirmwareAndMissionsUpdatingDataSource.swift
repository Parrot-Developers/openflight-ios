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

// MARK: - Internal Enums
/// Stores manual rebooting state.
enum FirmwareAndMissionsManualRebootingState {
    case waiting
    case ongoing
    case succeeded
    case failed
}

/// The data source of `FirmwareAndMissionsUpdateViewController` table view.
final class FirmwareAndMissionsUpdatingDataSource {
    // MARK: - Internal Properties
    let elements: [FirmwareMissionsUpdatingCase]
    let currentTotalProgress: Float

    // MARK: - Private Enum
    private enum Constants {
        static let minProgress: Float = 0.0
        static let maxProgress: Float = 100
    }

    // MARK: - Init
    /// Inits the data source
    ///
    /// - Parameters:
    ///    - manualRebootState: the manual rebooting state of the process
    init(manualRebootState: FirmwareAndMissionsManualRebootingState) {
        let firmwareUpdaterManager = FirmwareUpdaterManager.shared
        let missionsUpdaterManager = ProtobufMissionsUpdaterManager.shared
        let missions = missionsUpdaterManager.missionsToUpdateList.missionsToUpdateArray

        guard let firmwareToUpdate = firmwareUpdaterManager.firmwareToUpdate else {
            elements = []
            currentTotalProgress = Constants.minProgress
            return
        }

        var temporaryElements: [FirmwareMissionsUpdatingCase] = []
        var temporaryProgress: Float = Constants.minProgress

        if firmwareToUpdate.allOperationsNeeded.contains(.download) {
            temporaryProgress += Float(firmwareUpdaterManager.currentProgress(for: .download))
            let updatinStep = firmwareUpdaterManager.currentUpdatingStep(for: .download)
            temporaryElements.append(.downloadingFirmware(updatinStep, firmwareToUpdate))
        }
        if firmwareToUpdate.allOperationsNeeded.contains(.update) {
            temporaryProgress += Float(firmwareUpdaterManager.currentProgress(for: .update))
            let updatinStep = firmwareUpdaterManager.currentUpdatingStep(for: .update)
            temporaryElements.append(.updatingFirmware(updatinStep, firmwareToUpdate))
        }
        if firmwareToUpdate.allOperationsNeeded.contains(.reboot) {
            temporaryProgress += Float(firmwareUpdaterManager.currentProgress(for: .reboot))
            let updatinStep = firmwareUpdaterManager.currentUpdatingStep(for: .reboot)
            temporaryElements.append(.reboot(updatinStep))
        }

        for mission in missions {
            let missionUpdatingCase = mission.state.value.missionToUpdateStatus.updatingCase
            temporaryProgress += Float(mission.currentProgress())
            temporaryElements.append(.mission(missionUpdatingCase, mission.missionToUpdateData))
        }

        switch manualRebootState {
        case .waiting:
            temporaryElements.append(.reboot(.waiting))
        case .ongoing:
            temporaryElements.append(.reboot(.loading))
            temporaryProgress += Constants.maxProgress
        case .succeeded:
            temporaryElements.append(.reboot(.succeeded))
            temporaryProgress += Constants.maxProgress
        case .failed:
            temporaryElements.append(.reboot(.failed(L10n.firmwareMissionUpdateOperationFailedNeverStarted)))
            temporaryProgress += Constants.maxProgress
        }

        elements = temporaryElements
        currentTotalProgress = elements.isEmpty ? Constants.maxProgress : temporaryProgress / Float(elements.count)
    }
}
