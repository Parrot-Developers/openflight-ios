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

/// The Firmware to update status.
private enum FirmwareToUpdateStatus {
    case downloadAndUpdateNeeded
    case updateNeeded
    case upTodate
}

/// The potential Firmware to update process operation.
enum FirwmwareToUpdateOperation {
    case download
    case update
    case reboot
}

/// A struc to represent the Firmware to update.
struct FirmwareToUpdateData {
    // MARK: - Internal Properties
    let firmwareName: String = L10n.firmwareMissionUpdateFirmwareName
    let firmwareVersion: String
    let firmwareIdealVersion: String
    let allOperationsNeeded: [FirwmwareToUpdateOperation]

    // MARK: - Private Properties
    fileprivate let droneWasConnected: Bool
    fileprivate let firmwareToUpdateStatus: FirmwareToUpdateStatus

    init(firmwareVersion: String,
         firmwareIdealVersion: String,
         firmwareUpdateNeeded: Bool,
         firmwareNeedToBeDownloaded: Bool,
         droneIsConnected: Bool) {
        self.firmwareVersion = firmwareVersion
        self.firmwareIdealVersion = firmwareIdealVersion
        self.droneWasConnected = droneIsConnected

        if firmwareUpdateNeeded && firmwareNeedToBeDownloaded {
            self.firmwareToUpdateStatus = .downloadAndUpdateNeeded
        } else if firmwareUpdateNeeded {
            self.firmwareToUpdateStatus = .updateNeeded
        } else {
            self.firmwareToUpdateStatus = .upTodate
        }

        switch self.firmwareToUpdateStatus {
        case .downloadAndUpdateNeeded:
            if droneWasConnected {
                allOperationsNeeded = [.download, .update, .reboot]
            } else {
                allOperationsNeeded = [.download]
            }
        case .updateNeeded:
            allOperationsNeeded = [.update, .reboot]
        case .upTodate:
            allOperationsNeeded = []
        }
    }
}
