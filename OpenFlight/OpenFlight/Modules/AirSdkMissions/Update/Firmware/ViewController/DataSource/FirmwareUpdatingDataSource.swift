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

/// The data source of `FirmwareUpdatingViewController`'s table view.
final class FirmwareUpdatingDataSource {
    // MARK: - Internal Properties
    let elements: [FirmwareMissionsUpdatingCase]
    let currentTotalProgress: Float

    // MARK: - Private Enum
    private enum Constants {
        static let minProgress: Float = 0.0
        static let maxProgress: Float = 100
    }

    // MARK: - Init
    init(withProgress: Float? = nil) {
        let firmwareUpdaterManager = FirmwareUpdaterManager.shared
        var temporaryElements: [FirmwareMissionsUpdatingCase] = []
        var temporaryProgress: Float = Constants.minProgress

        guard let firmwareToUpdate = firmwareUpdaterManager.firmwareToUpdate else {
            elements = []
            currentTotalProgress = Constants.minProgress
            return
        }

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

        elements = temporaryElements

        if let withProgress = withProgress {
            currentTotalProgress = withProgress
        } else {
            currentTotalProgress = elements.isEmpty ? Constants.maxProgress : temporaryProgress / Float(elements.count)
        }
    }
}
