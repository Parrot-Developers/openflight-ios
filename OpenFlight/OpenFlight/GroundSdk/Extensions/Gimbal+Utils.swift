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

import GroundSdk

// MARK: - Private Enums

/// Gimbal full calibration state.
enum CalibratableGimbalState {
    case calibrated
    case needed

    /// String describing gimbal calibration state.
    var description: String {
        self == .needed ? L10n.commonRequired : ""
    }
}

/// Utility extension for gimbal.
extension CalibratableGimbal {
    /// Gimbal calibration state.
    var state: CalibratableGimbalState {
        calibrated ? .calibrated : .needed
    }

    /// Color for gimbal calibration title.
    var titleColor: ColorName {
        state == .needed ? .white : .defaultTextColor
    }

    /// Color for gimbal calibration subtitle.
    var subtitleColor: ColorName {
        state == .needed ? .white : .highlightColor
    }

    /// Color for gimbal calibration background.
    var backgroundColor: ColorName {
        state == .needed ? .errorColor : .white
    }
}

extension Gimbal {
    /// Whether gimbal has errors.
    var hasErrors: Bool { !currentErrors.isEmpty }

    // [Banner Alerts] Legacy code is temporarily kept for validation purpose only.
    // TODO: Remove property.
    /// Returns current alerts for gimbal.
    var currentAlerts: [HUDAlertType] {
        return currentErrors.isEmpty
            ? []
            : [HUDBannerCriticalAlertType.cameraError]
    }

    /// Image error according to gimbal and front stereo calibration state.
    var errorImage: UIImage {
        return currentErrors.isEmpty
        ? Asset.Drone.icGimbalOk.image
        : Asset.Drone.icGimbalError.image
    }
}
