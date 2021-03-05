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
/// Represents current state of an update process.
enum DeviceUpdateStep {
    case none
    case downloadStarted
    case downloadCompleted
    case updateStarted
    case uploading
    case processing
    case rebooting
    case updateCompleted
}

/// Type of event that could happen during a firmware update process.
enum DeviceUpdateEvent {
    case downloadFailed
    case downloadCanceled
    case updateFailed
    case updateCanceled
}

/// Enum describing update type according to the device.
public enum DeviceUpdateModel {
    case drone
    case remote

    /// Title.
    var title: String {
        switch self {
        case .remote:
            return L10n.remoteUpdateControllerUpdate
        case .drone:
            return L10n.droneUpdateControllerUpdate
        }
    }

    /// Description.
    var description: String {
        switch self {
        case .remote:
            return L10n.remoteUpdateConfirmDescription
        case .drone:
            return L10n.droneUpdateConfirmDescription
        }
    }

    /// Device image.
    var image: UIImage {
        switch self {
        case .remote:
            return Asset.Remote.icRemoteUpdate.image
        case .drone:
            return Asset.Drone.icDroneDetailsAvailable.image
        }
    }

    /// Sending step of the update.
    var sendingStep: String {
        switch self {
        case .remote:
            return L10n.remoteUpdateSendingStep
        case .drone:
            return L10n.droneUpdateSendingStep
        }
    }
}

/// Unavailability reasons for update.
enum UpdateUnavailabilityReasons {
    case droneFlying
    case notEnoughBattery
    case droneNotConnected
    case remoteControlNotConnected

    private enum Constants {
        static let minimumBatteryLevel: Double = 40.0
    }

    /// Unavailability reason title.
    var title: String {
        switch self {
        case .droneFlying:
            return L10n.deviceUpdateImpossible
        case .notEnoughBattery:
            return L10n.droneUpdateInsufficientBatteryTitle
        case .droneNotConnected,
             .remoteControlNotConnected:
            return L10n.error
        }
    }

    /// Unavailability reason message.
    var message: String {
        switch self {
        case .droneFlying:
            return L10n.deviceUpdateDroneFlying
        case .notEnoughBattery:
            return L10n.droneUpdateInsufficientBatteryDescription(Constants.minimumBatteryLevel.asPercent())
        case .droneNotConnected:
            return L10n.remoteDetailsConnectToADrone
        case .remoteControlNotConnected:
            return L10n.pairingConnectToTheController
        }
    }
}

// MARK: - Internal Structs
/// Describe the type of the update.
struct DeviceUpdateType {
    /// Model of the  device which will be updated.
    var model: DeviceUpdateModel = .remote
    /// Only download process.
    var isOnlyDownload: Bool = false
    /// Tells if the firmware is already downloaded.
    var isFirmwareAlreadyDownloaded: Bool = false
}
