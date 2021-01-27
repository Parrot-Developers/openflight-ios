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

// MARK: - Internal Enums
/// Enum used to display camera slow motion sub-modes in bottom bar.

enum SlowMotionMode: String, BarItemSubMode {

    case quarter = "x0.25"
    case semi = "x0.5"

    var image: UIImage? {
        return Asset.BottomBar.CameraModes.icCameraModeSlowMotion.image
    }

    var key: String {
        return rawValue
    }

    static let allValues: [BarItemMode] = [SlowMotionMode.quarter,
                                           SlowMotionMode.semi]

    var title: String {
        switch self {
        case .quarter:
            return L10n.cameraSubModeSlomo025
        case .semi:
            return L10n.cameraSubModeSlomo05
        }
    }

    var value: String? {
        switch self {
        case .quarter:
            return Camera2RecordingResolution.res720p.rawValue
        case .semi:
            return Camera2RecordingResolution.res1080p.rawValue
        }
    }

    var shutterText: String? {
        return title
    }

    var logKey: String {
        return LogEvent.LogKeyHUDBottomBarButton.slowMotion.name
    }
}

/// Utility extension for `Camera2RecordingResolution`.
extension Camera2RecordingResolution {
    var slowMotionMode: SlowMotionMode? {
        switch self {
        case .res720p:
            return .quarter
        case .res1080p:
            return .semi
        default:
            return nil
        }
    }
}
