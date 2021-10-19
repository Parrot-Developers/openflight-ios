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

/// Utility extension for `Camera2WhiteBalanceMode`.
extension Camera2WhiteBalanceMode: BarItemMode, Sortable {
    // MARK: - BarItemMode
    public var title: String {
        switch self {
        case .incandescent:
            return L10n.cameraWhiteBalanceIncandescent
        case .coolWhiteFluorescent:
            return L10n.cameraWhiteBalanceFluo
        case .sunny:
            return L10n.cameraWhiteBalanceSunny
        case .cloudy:
            return L10n.cameraWhiteBalanceCloudy
        case .shaded:
            return L10n.cameraWhiteBalanceShaded
        case .custom:
            return L10n.cameraWhiteBalanceCustom
        case .automatic:
            return L10n.commonAuto
        default:
            return ""
        }
    }

    public var image: UIImage? {
        switch self {
        case .automatic:
            return Asset.BottomBar.Icons.iconAuto.image
        case .incandescent:
            return Asset.BottomBar.CameraWhiteBalance.iconWbTungstene.image
        case .coolWhiteFluorescent:
            return Asset.BottomBar.CameraWhiteBalance.iconWbCoolFluo.image
        case .sunny:
            return Asset.BottomBar.CameraWhiteBalance.iconWbSunny.image
        case .cloudy:
            return Asset.BottomBar.CameraWhiteBalance.iconWbCloudy.image
        case .shaded:
            return Asset.BottomBar.CameraWhiteBalance.iconWbShaded.image
        case .custom:
            return Asset.BottomBar.CameraWhiteBalance.iconWbCustom.image
        default:
            return nil
        }
    }

    public var key: String {
        return description
    }

    public static var allValues: [BarItemMode] {
        // This doesn't include available automatic mode which is
        // not displayed inside segmented bar view.
        return [Camera2WhiteBalanceMode.incandescent,
                Camera2WhiteBalanceMode.coolWhiteFluorescent,
                Camera2WhiteBalanceMode.sunny,
                Camera2WhiteBalanceMode.cloudy,
                Camera2WhiteBalanceMode.shaded,
                Camera2WhiteBalanceMode.custom]
    }

    public static var availableModes: [Camera2WhiteBalanceMode] {
        return [Camera2WhiteBalanceMode.automatic,
                Camera2WhiteBalanceMode.sunny,
                Camera2WhiteBalanceMode.cloudy]
    }

    /// Returns mode for an index, based on all modes available.
    public static func modeForIndex(_ index: Int) -> Camera2WhiteBalanceMode {
        guard index < availableModes.count else { return defaultMode }

        return availableModes[index]
    }

    /// Default value.
    public static var defaultMode: Camera2WhiteBalanceMode {
        .automatic
    }

    public var subModes: [BarItemSubMode]? {
        return nil
    }

    public var autoClose: Bool {
        return false
    }

    /// Alternative title for level one bottom bar item view.
    var altTitle: String? {
        switch self {
        case .custom:
            // Temperature is diplayed for custom mode.
            return nil
        default:
            return L10n.cameraWhiteBalance
        }
    }

    // MARK: - Sortable
    public static var sortedCases: [Camera2WhiteBalanceMode] {
        return [.automatic, .candle, .sunset, .incandescent, .warmWhiteFluorescent,
                .halogen, .fluorescent, .coolWhiteFluorescent, .flash, .daylight,
                .sunny, .cloudy, .snow, .hazy, .shaded, .greenFoliage, .blueSky, .custom]
    }

    public var logKey: String {
        return LogEvent.LogKeyHUDBottomBarButton.whiteBalanceSetting.name
    }
}
