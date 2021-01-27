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

/// Utility extension for `Camera2RecordingResolution`.
extension Camera2RecordingResolution: BarItemMode, Sortable {
    // MARK: - BarItemMode
    public var title: String {
        switch self {
        case .resUhd8k:
            return L10n.videoSettingsResolution8k
        case .res5k:
            return L10n.videoSettingsResolution5k
        case .resDci4k:
            return L10n.videoSettingsResolution4kCinema
        case .resUhd4k:
            return L10n.videoSettingsResolution4k
        case .res2_7k:
            return L10n.videoSettingsResolution27k
        case .res1080p:
            return L10n.videoSettingsResolution1080p
        case .res720p:
            return L10n.videoSettingsResolution720p
        case .res480p:
            return L10n.videoSettingsResolution480p
        case .res1080pSd:
            return L10n.videoSettingsResolution1080pSD
        case .res720pSd:
            return L10n.videoSettingsResolution720pSD
        }
    }

    public var image: UIImage? {
        return nil
    }

    public var key: String {
        return description
    }

    public static var allValues: [BarItemMode] {
        return self.allCases.sorted()
    }

    public var subModes: [BarItemSubMode]? {
        return nil
    }

    // MARK: - Sortable
    static var sortedCases: [Camera2RecordingResolution] {
        return [.res480p, .res720pSd, .res720p, .res1080pSd, .res1080p,
                .res2_7k, .resDci4k, .resUhd4k, .res5k, .resUhd8k]
    }

    public var logKey: String {
        return LogEvent.LogKeyHUDBottomBarButton.videoResolutionSetting.name
    }
}
