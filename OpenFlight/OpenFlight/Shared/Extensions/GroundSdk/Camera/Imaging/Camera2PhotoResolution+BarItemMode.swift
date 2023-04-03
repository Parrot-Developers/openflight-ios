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

/// Utility extension for `Camera2PhotoResolution`.
extension Camera2PhotoResolution: BarItemMode, Sortable {
    // MARK: - BarItemMode
    public var title: String {
        switch self {
        case .res12MegaPixels:
            return "12" + L10n.unitMegapixel
        case .res48MegaPixels:
            return "48" + L10n.unitMegapixel
        }
    }

    public var image: UIImage? {
        return nil
    }

    public var key: String {
        return description
    }

    public static var allValues: [BarItemMode] {
        return allCases.sorted()
    }

    public var subModes: [BarItemSubMode]? {
        return nil
    }

    public var logKey: String {
        return LogEvent.LogKeyHUDBottomBarButton.photoResolutionSetting.name
    }

    /// List of available resolutions.
    public static var availableResolutions: [Camera2PhotoResolution] {
        [.res12MegaPixels,
         .res48MegaPixels]
    }

    /// Default value.
    public static var defaultResolution: Camera2PhotoResolution {
        .res48MegaPixels
    }

    /// Returns resolution for an index, based on all resolutions available.
    public static func resolutionForIndex(_ index: Int) -> Camera2PhotoResolution {
        guard index < availableResolutions.count else { return defaultResolution }

        return availableResolutions[index]
    }

    // MARK: - Sortable
    public static var sortedCases: [Camera2PhotoResolution] {
        return [.res12MegaPixels, .res48MegaPixels]
    }
}
