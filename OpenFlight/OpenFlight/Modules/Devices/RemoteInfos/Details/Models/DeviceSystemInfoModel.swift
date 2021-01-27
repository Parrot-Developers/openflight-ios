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

import UIKit

// MARK: - Internal Enums
/// Enum which describes a system info section.

enum SectionSystemInfo {
    case model
    case hardware
    case software
    case serial
    case flightsNumber
    case totalFlightDuration

    var sectionTitle: String? {
        switch self {
        case .model:
            return L10n.remoteDetailsModel
        case .hardware:
            return L10n.remoteDetailsHardware
        case .software:
            return L10n.remoteDetailsSoftware
        case .serial:
            return L10n.remoteDetailsSerialNumber
        case .flightsNumber:
            return L10n.droneDetailsNumberFlights
        case .totalFlightDuration:
            return L10n.droneDetailsTotalFlightTime
        }
    }
}

/// Describes system info for a selected device.

class DeviceSystemInfoModel {
    // MARK: - Internal Properties
    /// System item.
    var section: SectionSystemInfo?
    /// System value for a selected item.
    var value: String?

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - section: current section of the model
    ///    - value: value of the current section
    init(section: SectionSystemInfo?, value: String?) {
        self.section = section
        self.value = value
    }
}
