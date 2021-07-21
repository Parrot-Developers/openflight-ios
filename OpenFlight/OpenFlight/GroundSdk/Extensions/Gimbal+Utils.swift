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

// MARK: - Private Enums
private enum Constants {
    static let roundPrecision: Int = 2
}

/// Gimbal full calibration state.
enum CalibratableGimbalState {
    case calibrated
    case recommended
    case needed
    case error
    case unavailable

    /// User interaction state for calibration view.
    var isUserInteractionEnabled: Bool {
        return self == .needed || self == .recommended
    }

    /// Image calibration according to gimbal and front stereo calibration state.
    var calibrationImage: UIImage? {
        switch self {
        case .calibrated:
            return Asset.Drone.icGimbalOk.image
        case .recommended:
            return Asset.Drone.icGimbalWarning.image
        case .needed,
             .error:
            return Asset.Drone.icGimbalError.image
        case .unavailable:
            return nil
        }
    }
}

/// Utility extension for gimbal.
extension CalibratableGimbal {
    /// Gimbal calibration state.
    var state: CalibratableGimbalState {
        switch (calibrated, currentErrors.isEmpty) {
        case (false, true):
            return .recommended
        case (_, false):
            return .needed
        default:
            return .calibrated
        }
    }

    /// Color for gimbal calibration subtext.
    var subtextColor: ColorName {
        switch self.state {
        case .calibrated:
            return .white50
        case .recommended:
            return .orangePeel
        case .needed,
             .error,
             .unavailable:
            return .redTorch
        }
    }

    /// Color for gimbal calibration background.
    var backgroundColor: ColorName {
        switch self.state {
        case .calibrated:
            return .white10
        case .recommended:
            return .orangePeel20
        case .needed,
             .error,
             .unavailable:
            return .redTorch25
        }
    }

    /// Image for gimbal calibration.
    var calibrationImage: UIImage {
        switch self.state {
        case .calibrated:
            return Asset.Drone.icGimbalOk.image
        case .recommended:
            return Asset.Drone.icGimbalWarning.image
        case .needed,
             .error,
             .unavailable:
            return Asset.Drone.icGimbalError.image
        }
    }
}

extension Gimbal {
    /// Returns current alerts for gimbal.
    var currentAlerts: [HUDAlertType] {
        return currentErrors.isEmpty
            ? []
            : [HUDBannerCriticalAlertType.cameraError]
    }

    /// String describing gimbal calibration state.
    var calibrationStateDescription: String? {
        switch self.state {
        case .calibrated,
             .unavailable:
            return nil
        case .needed,
             .error:
            return L10n.commonRequired
        case .recommended:
            return L10n.commonRecommended
        }
    }
}
