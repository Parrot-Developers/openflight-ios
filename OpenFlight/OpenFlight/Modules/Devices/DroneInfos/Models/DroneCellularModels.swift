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

// MARK: - Internal Enums
/// Provides different state and errors which occurs when cellular connection got problems.
public enum DetailsCellularStatus: Int {
    case noState
    case initializing
    case cellularConnected
    case cellularConnecting
    case simLocked
    case simBlocked
    case simNotDetected
    case simNotRecognized
    case userNotPaired
    case notRegistered
    case networkStatusError
    case networkStatusDenied
    case airplaneMode
    case modemStatusOff
    case noData
    case connectionFailed
}

// MARK: - Internal Properties
/// Extension for `DroneDetails` feature.
extension DetailsCellularStatus {
    /// Returns true if there is an error.
    var isStatusError: Bool {
        return self != .cellularConnecting
            && self != .cellularConnected
    }

    /// Returns error title in drone cellular details.
    var cellularDetailsTitle: String? {
        switch self {
        case .simBlocked:
            return L10n.cellularDetailsSimBlocked
        case .simNotDetected:
            return L10n.cellularDetailsNoSimCard
        case .simNotRecognized:
            return nil
        case .simLocked:
            return L10n.drone4gEnterPin
        case .userNotPaired:
            return L10n.cellularDetailsUserNotPaired
        case .networkStatusError:
            return L10n.cellularConnectionUnableToConnect
        case .connectionFailed,
             .notRegistered,
             .networkStatusDenied,
             .noState,
             .initializing,
             .cellularConnecting:
            return L10n.connecting
        case .airplaneMode:
            return L10n.cellularErrorNoInternetMessage
        case .modemStatusOff:
            return L10n.cellularModemOffline
        case .noData:
            return L10n.cellularDetailsDataDisabled
        case .cellularConnected:
            return L10n.connected
        }
    }

    /// Returns details text color for drone tile and cellular screen.
    var detailsTextColor: ColorName {
        switch self {
        case .cellularConnected:
            return .highlightColor
        case .simBlocked,
             .userNotPaired,
             .notRegistered,
             .networkStatusError,
             .networkStatusDenied,
             .airplaneMode,
             .modemStatusOff,
             .simNotRecognized,
             .connectionFailed,
             .noState:
            return .errorColor
        case .noData,
             .cellularConnecting,
             .initializing:
            return .defaultTextColor
        case .simNotDetected,
             .simLocked:
            return .warningColor
        }
    }

    var shouldShowPinAction: Bool {
        return self == .simLocked
    }

    /// Returns action button title.
    var actionButtonTitle: String {
        switch self {
        case .userNotPaired:
            return L10n.cellularDetailsPairDevice
        case .simLocked:
            return L10n.drone4gEnterPin
        case .noData:
            return L10n.cellularConnectionActivate
        default:
            return ""
        }
    }
}

/// Stores states which occurs during drone unpairing.
public enum UnpairDroneState: Equatable {
    case notStarted
    case noInternet(context: UnpairDroneStateContext)
    case forgetError(context: UnpairDroneStateContext)
    case done

    /// Title of the state.
    var title: String? {
        switch self {
        case .noInternet(.details):
            return L10n.cellularErrorInternetTryAgain
        case .noInternet(.discover):
            return L10n.cellularErrorInternetUnpair
        case .forgetError(.details):
            return L10n.cellularPairingDetailsForgotError
        case .forgetError(.discover):
            return L10n.cellularPairingDiscoveryForgotError
        default:
            return nil
        }
    }

    /// Returns true if an error needs to be displayed.
    var shouldShowError: Bool {
        switch self {
        case .noInternet,
             .forgetError:
            return true
        default:
            return false
        }
    }
}

/// Specify context of drone unpairing.
public enum UnpairDroneStateContext {
    case details
    case discover
}
