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

import SwiftyUserDefaults
import GroundSdk

// MARK: - Internal Enums
/// Enum used to display panorama sub-modes in bottom bar.

enum PanoramaMode: String, BarItemSubMode, DefaultsLoadableBarItem {
    case vertical
    case horizontal
    case degrees360
    case wide

    static var defaultKey: DefaultsKey<String> {
        return DefaultsKeys.userPanoramaSettingKey
    }

    static var current: PanoramaMode {
        return PanoramaMode(rawValue: Defaults.userPanoramaSetting) ?? .vertical
    }

    static let allValues: [BarItemMode] = [PanoramaMode.vertical,
                                           PanoramaMode.horizontal,
                                           PanoramaMode.degrees360,
                                           PanoramaMode.wide]

    var title: String {
        switch self {
        case .vertical:
            return L10n.cameraSubModePanoramaVertical
        case .horizontal:
            return L10n.cameraSubModePanoramaHorizontal
        case .degrees360:
            return L10n.cameraSubModePanorama360
        case .wide:
            return L10n.cameraSubModePanoramaSuperWide
        }
    }

    var image: UIImage? {
        switch self {
        case .vertical:
            return Asset.BottomBar.CameraSubModes.icPanoVertical.image
        case .horizontal:
            return Asset.BottomBar.CameraSubModes.icPanoHorizontal.image
        case .degrees360:
            return Asset.BottomBar.CameraSubModes.icPano360.image
        case .wide:
            return Asset.BottomBar.CameraSubModes.icPanoWide.image
        }
    }

    var key: String {
        return rawValue
    }

    var shutterText: String? {
        return nil
    }

    var animationType: AnimationType {
        switch self {
        case .vertical:
            return .vertical180PhotoPanorama
        case .horizontal:
            return .horizontal180PhotoPanorama
        case .degrees360:
            return .sphericalPhotoPanorama
        case .wide:
            return .superWidePhotoPanorama
        }
    }

    var animationConfig: AnimationConfig {
        switch self {
        case .vertical:
            return Vertical180PhotoPanoramaAnimationConfig()
        case .horizontal:
            return Horizontal180PhotoPanoramaAnimationCfg()
        case .degrees360:
            return SphericalPhotoPanoramaAnimationConfig()
        case .wide:
            return SuperWidePhotoPanoramaAnimationConfig()
        }
    }

    var logKey: String {
        return LogEvent.LogKeyHUDBottomBarButton.panorama.name
    }
}
