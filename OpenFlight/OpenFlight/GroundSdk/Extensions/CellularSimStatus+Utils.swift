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

import GroundSdk

/// Utility extension for `CellularSimStatus` declared in the `Cellular` Peripheral.
public extension CellularSimStatus {
    // MARK: - Internal Properties
    /// Tells if cellular is available.
    var isCellularAvailable: Bool {
        return self == .ready || self == .locked
    }

    /// Title of the network state.
    var title: String {
        switch self {
        case .ready:
            return L10n.connected
        case .locked:
            return L10n.drone4gSimLocked
        default:
            return Style.dash
        }
    }

    /// Description of the network state.
    var description: String {
        switch self {
        case .locked:
            return L10n.drone4gSimIsLocked
        case .ready:
            return ""
        default:
            return L10n.disconnected
        }
    }

    /// Common color for current state.
    var color: ColorName {
        switch self {
        case .ready:
            return ColorName.greenSpring
        case .locked:
            return ColorName.orangePeel
        default:
            return ColorName.white20
        }
    }
}
