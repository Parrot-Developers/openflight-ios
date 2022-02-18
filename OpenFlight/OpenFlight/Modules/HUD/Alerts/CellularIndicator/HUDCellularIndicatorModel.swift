//    Copyright (C) 2021 Parrot Drones SAS
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

/// Stores several infos displayed on the HUD.
enum HUDCellularState: Int {
    case noState
    case cellularConnected
    case cellularConnecting

    /// Returns infos image.
    var image: UIImage? {
        switch self {
        case .cellularConnected:
            return Asset.Cellular.ic4GBigConnected.image
        case .cellularConnecting:
            return Asset.Cellular.ic4GBigConnecting.image
        case .noState:
            return nil
        }
    }

    /// Returns description. Only for 4G infos.
    var description: String {
        switch self {
        case .cellularConnected:
            return L10n.connected
        case .cellularConnecting:
            return L10n.connecting
        case .noState:
            return ""
        }
    }

    /// Returns description color. Only for 4G infos.
    var descriptionColor: ColorName {
        switch self {
        case .cellularConnected:
            return ColorName.highlightColor
        case .noState,
             .cellularConnecting:
            return ColorName.white
        }
    }
}

/// Provides different state error which occurs when cellular connection got problems.
enum HUDCellularStateError: Int {
    case simLocked
    case simBlocked
    case notRegistered
    case networkStatusError
    case networkStatusDenied
    case airplaneMode
    case connectionFailed

    /// Returns title error.
    var title: String? {
        switch self {
        case .simBlocked:
            return L10n.pinModalSimCardPin
        case .notRegistered,
             .networkStatusError,
             .networkStatusDenied:
            return L10n.cellularConnectionUnableToConnect
        case .airplaneMode:
            return L10n.cellularErrorNoInternetTitle
        case .connectionFailed:
            return L10n.cellularErrorConnectionFailedTitle
        case .simLocked:
            return nil
        }
    }

    /// Returns title error.
    var description: String? {
        switch self {
        case .simBlocked:
            return L10n.cellularErrorSimBlockedMessage
        case .notRegistered,
             .networkStatusError,
             .networkStatusDenied:
            return L10n.cellularErrorUnableConnectNetwork
        case .airplaneMode:
            return L10n.cellularErrorNoInternetMessage
        case .connectionFailed:
            return L10n.cellularErrorConnectionFailedMessage
        case .simLocked:
            return nil
        }
    }
}
