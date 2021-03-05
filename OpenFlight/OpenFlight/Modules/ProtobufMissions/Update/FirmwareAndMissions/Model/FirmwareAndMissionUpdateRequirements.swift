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
import GroundSdk

// MARK: - Internal Enums
/// Enum order by priority to trigger a missing requirement alert view for missions and firmware updates .
enum FirmwareAndMissionUpdateRequirements: Int {
    case droneIsNotConnected
    case notEnoughBattery
    case droneIsFlying
    case notEnoughSpace
    case noInternetConnection
    case ongoingUpdate
    case readyForUpdate

    // MARK: - Private Enums
    private enum Constants {
        static let minimumBatteryLevel: Double = 50.0
    }

    // MARK: - Init
    /// Inits.
    ///
    /// - Parameters:
    ///   - unavailabilityReason: a `UpdaterUpdateUnavailabilityReason`
    init(unavailabilityReason: UpdaterUpdateUnavailabilityReason) {
        switch unavailabilityReason {
        case .notConnected:
            self = .droneIsNotConnected
        case .notEnoughBattery:
            self = .notEnoughBattery
        case .notLanded:
            self = .droneIsFlying
        }
    }
}

// MARK: - Internal Properties
extension FirmwareAndMissionUpdateRequirements {
    /// The alert view title.
    var title: String {
        switch self {
        case .droneIsFlying:
            return L10n.firmwareMissionUpdateAlertDroneFlyingTitle
        case .noInternetConnection:
            return L10n.commonNoInternetConnection
        case .notEnoughBattery:
            return L10n.droneUpdateInsufficientBatteryTitle
        case .notEnoughSpace:
            return L10n.alertInternalMemoryFull
        case .droneIsNotConnected:
            return L10n.error
        case .readyForUpdate:
            return ""
        case .ongoingUpdate:
            return L10n.error
        }
    }

    /// The alert view message.
    var message: String {
        switch self {
        case .droneIsFlying:
            return L10n.deviceUpdateDroneFlying
        case .noInternetConnection:
            return L10n.droneUpdateInternetUnreachableDescription
        case .notEnoughBattery:
            return L10n.droneUpdateInsufficientBatteryDescription(Constants.minimumBatteryLevel.asPercent())
        case .notEnoughSpace:
            return L10n.firmwareMissionUpdateAlertMemoryFullMessage
        case .droneIsNotConnected:
            return L10n.remoteDetailsConnectToADrone
        case .readyForUpdate:
            return ""
        case .ongoingUpdate:
            return L10n.firmwareMissionUpdateAlertCommonMessage
        }
    }

    /// The alert view action title.
    var validateActionTitle: String? {
        switch self {
        case .droneIsFlying:
            return nil
        case .noInternetConnection:
            return L10n.commonRetry
        case .notEnoughBattery:
            return nil
        case .notEnoughSpace:
            return L10n.firmwareMissionUpdateAlertMemoryFullValidateAction
        case .droneIsNotConnected:
            return nil
        case .readyForUpdate:
            return nil
        case .ongoingUpdate:
            return nil
        }
    }

    /// The alert view cancel action title.
    var cancelActionTitle: String {
        switch self {
        case .droneIsFlying:
            return L10n.ok
        case .noInternetConnection:
            return L10n.cancel
        case .notEnoughBattery:
            return L10n.ok
        case .notEnoughSpace:
            return L10n.cancel
        case .droneIsNotConnected:
            return L10n.ok
        case .readyForUpdate:
            return L10n.ok
        case .ongoingUpdate:
            return L10n.ok
        }
    }
}
