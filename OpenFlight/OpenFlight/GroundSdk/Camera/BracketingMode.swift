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
/// Enum used to display camera bracketing sub-modes in bottom bar.
enum BracketingMode: Int, BarItemSubMode {
    case three = 3
    case five = 5
    case seven = 7

    static let allValues: [BarItemMode] = [BracketingMode.three,
                                           BracketingMode.five,
                                           BracketingMode.seven]

    var title: String {
        return L10n.cameraSubModeBracketingPhotoCount(rawValue)
    }

    var image: UIImage? {
        switch self {
        case .three:
            return Asset.BottomBar.CameraSubModes.icCameraModeBracketing3.image
        case .five:
            return Asset.BottomBar.CameraSubModes.icCameraModeBracketing5.image
        case .seven:
            return Asset.BottomBar.CameraSubModes.icCameraModeBracketing7.image
        }
    }

    var key: String {
        return String(rawValue)
    }

    var value: String? {
        switch self {
        case .three:
            return Camera2BracketingValue.preset1ev.rawValue
        case .five:
            return Camera2BracketingValue.preset1ev2ev.rawValue
        case .seven:
            return Camera2BracketingValue.preset1ev2ev3ev.rawValue
        }
    }

    var shutterText: String? {
        return String(rawValue)
    }

    var logKey: String {
        return LogEvent.LogKeyHUDBottomBarButton.braketing.name
    }
}

/// Utility extension for `Camera2BracketingValue`.
extension Camera2BracketingValue {
    var bracketingMode: BracketingMode {
        switch self {
        case .preset1ev, .preset2ev, .preset3ev:
            return .three
        case .preset1ev2ev, .preset1ev3ev, .preset2ev3ev:
            return .five
        case .preset1ev2ev3ev:
            return .seven
        }
    }
}
