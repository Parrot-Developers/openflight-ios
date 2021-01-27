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

/// Utility extension for `Camera2RecordingFramerate`.
extension Camera2RecordingFramerate: BarItemMode, Sortable {
    // MARK: - BarItemMode
    var value: String {
        switch self {
        case .fps8_6:
            return "8.6"
        case .fps10:
            return "10"
        case .fps9:
            return "9"
        case .fps15:
            return "15"
        case .fps20:
            return "20"
        case .fps24:
            return "24"
        case .fps25:
            return "25"
        case .fps30:
            return "30"
        case .fps48:
            return "48"
        case .fps50:
            return "50"
        case .fps60:
            return "60"
        case .fps96:
            return "96"
        case .fps100:
            return "100"
        case .fps120:
            return "120"
        case .fps192:
            return "192"
        case .fps200:
            return "200"
        case .fps240:
            return "240"
        }
    }

    public var title: String {
        return value + " " + L10n.unitFps
    }

    var fpsTitle: String {
        return value + L10n.unitFps
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

    public var logKey: String {
        return LogEvent.LogKeyHUDBottomBarButton.framerateSetting.name
    }

    // MARK: - Sortable
    static var sortedCases: [Camera2RecordingFramerate] {
        return [.fps9, .fps15, .fps20, .fps24, .fps25, .fps30, .fps48, .fps50,
                .fps60, .fps96, .fps100, .fps120, .fps192, .fps200, .fps240]
    }
}
