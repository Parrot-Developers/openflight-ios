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
import Reusable
import GroundSdk

// MARK: - Internal Enums
/// Represents a current updating step for
/// - a mission update
/// - a firmware download/update/reboot
/// - and for the missions reboot if necessary.
enum CurrentUpdatingStep: Equatable {
    case waiting
    case loading
    case succeeded
    case failed(String)

    // MARK: - Equatable
    public static func == (lhs: CurrentUpdatingStep,
                           rhs: CurrentUpdatingStep) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true
        case (.waiting, .waiting):
            return true
        case (.succeeded, .succeeded):
            return true
        case (let .failed(lhsError), let .failed(rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }

    // MARK: - Inits
    /// Inits.
    ///
    /// - Parameters:
    ///   - firmwareDownloadingState: an `UpdaterDownloadState`
    init(firmwareDownloadingState: UpdaterDownloadState) {
        switch firmwareDownloadingState {
        case .canceled:
            self = .failed(L10n.firmwareMissionUpdateOperationCancel)
        case .downloading:
            self = .loading
        case .failed:
            self = .failed(L10n.firmwareMissionUpdateOperationFailedUnknownReason)
        case .success:
            self = .succeeded
        }
    }

    /// Inits.
    ///
    /// - Parameters:
    ///   - firmwareUpdatingState: an `UpdaterUpdateState`
    ///   - forReboot: a boolean to indicate if the `CurrentUpdatingStep`to build is for the reboot step
    init(firmwareUpdatingState: UpdaterUpdateState,
         forReboot: Bool) {
        switch firmwareUpdatingState {
        case .canceled:
            self = .failed(L10n.firmwareMissionUpdateOperationCancel)
        case .uploading:
            self = forReboot ? .waiting : .loading
        case .processing,
             .waitingForReboot:
            self = forReboot ? .loading : .succeeded
        case .failed:
            self = .failed(L10n.firmwareMissionUpdateOperationFailedUnknownReason)
        case .success:
            self = .succeeded
        }
    }

    /// Inits.
    ///
    /// - Parameters:
    ///   - missionStatus: a `ProtobufMissionToUpdateStatus`
    init(missionStatus: ProtobufMissionToUpdateStatus) {
        switch missionStatus {
        case .notInUpdateList:
            self = .failed(L10n.firmwareMissionUpdateOperationFailedNeverStarted)
        case .onGoingUpdate:
            self = .loading
        case let .failed(error):
            self = .failed(error.description)
        case .updateDone:
            self = .succeeded
        case .waitingForUpdate:
            self = .waiting
        }
    }
}

// MARK: - Internal Properties
extension CurrentUpdatingStep {
    /// The  updating label text color.
    var missionUpdatingLabel: UIColor {
        switch self {
        case .failed,
             .loading,
             .succeeded:
            return ColorName.defaultTextColor.color
        case .waiting:
            return ColorName.defaultTextColor80.color
        }
    }

    /// The `ProtobufMissionUpdatingView` image.
    var image: UIImage? {
        switch self {
        case .loading:
            return Asset.Pairing.icloading.image
        case .waiting:
            return nil
        case .succeeded:
            return Asset.Common.Checks.icChecked.image
        case .failed:
            return Asset.Remote.icErrorUpdate.image
        }
    }

    /// The `ProtobufMissionUpdatingView` tint color.
    var imageTintColor: UIColor? {
        switch self {
        case .succeeded,
             .loading:
            return ColorName.highlightColor.color
        case .waiting:
            return nil
        case .failed:
            return ColorName.errorColor.color
        }
    }
}

extension MissionUpdaterError {
    var description: String {
        switch self {
        case .badMissionFile:       return L10n.firmwareMissionUpdateErrorBadMission
        case .serverError:          return L10n.firmwareMissionUpdateErrorServer
        case .connectionError:      return L10n.firmwareMissionUpdateErrorConnection
        case .badRequest:           return L10n.firmwareMissionUpdateErrorBadRequest
        case .canceled:             return L10n.firmwareMissionUpdateErrorCancelled
        case .busy:                 return L10n.firmwareMissionUpdateErrorBusy
        case .missionAlreadyExists: return L10n.firmwareMissionUpdateErrorMissionAlreadyExists
        case .installationFailed:   return L10n.firmwareMissionUpdateErrorInstallationFailed
        case .noSpaceLeft:          return L10n.firmwareMissionUpdateErrorNoSpaceLeft
        case .incorrectMethod:      return L10n.firmwareMissionUpdateErrorIncorrectMethod
        case .invalidSignature:     return L10n.firmwareMissionUpdateErrorInvalidSignature
        case .versionMismatch:      return L10n.firmwareMissionUpdateErrorVersionMismatch
        case .modelMismatch:        return L10n.firmwareMissionUpdateErrorModelMismatch
        case .badInfoFile:          return L10n.firmwareMissionUpdateErrorBadInfoFile
        case .corruptedFile:        return L10n.firmwareMissionUpdateErrorCorruptedFile
        }
    }
}
