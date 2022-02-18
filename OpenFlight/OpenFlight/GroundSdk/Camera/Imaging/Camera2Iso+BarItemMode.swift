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

/// Utility extension for `Camera2Iso`.
extension Camera2Iso: BarItemMode, RulerDisplayable, Sortable {
    // MARK: - BarItemMode
    public var title: String {
        return String(format: "%@ %@", shortTitle, L10n.unitIso)
    }

    var shortTitle: String {
        switch self {
        case .iso25:
            return "25"
        case .iso50:
            return "50"
        case .iso64:
            return "64"
        case .iso80:
            return "80"
        case .iso100:
            return "100"
        case .iso125:
            return "125"
        case .iso160:
            return "160"
        case .iso200:
            return "200"
        case .iso250:
            return "250"
        case .iso320:
            return "320"
        case .iso400:
            return "400"
        case .iso500:
            return "500"
        case .iso640:
            return "640"
        case .iso800:
            return "800"
        case .iso1000:
            return "1000"
        case .iso1200:
            return "1200"
        case .iso1600:
            return "1600"
        case .iso2000:
            return "2000"
        case .iso2500:
            return "2500"
        case .iso3200:
            return "3200"
        case .iso4000:
            return "4000"
        case .iso5000:
            return "5000"
        case .iso6400:
            return "6400"
        case .iso8000:
            return "8000"
        case .iso10000:
            return "10000"
        case .iso12800:
            return "12800"
        case .iso16000:
            return "16000"
        case .iso20000:
            return "20000"
        case .iso25600:
            return "25600"
        case .iso32000:
            return "32000"
        case .iso40000:
            return "40000"
        case .iso51200:
            return "51200"
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

    // MARK: - RulerDisplayable
    var rulerText: String? {
        return shortTitle
    }

    var rulerBackgroundColor: UIColor? {
        return nil
    }

    // MARK: - Sortable
    public static var sortedCases: [Camera2Iso] {
        return [.iso25, .iso50, .iso64, .iso80, .iso100, .iso125, .iso160, .iso200, .iso250, .iso320, .iso400, .iso500,
                .iso640, .iso800, .iso1000, .iso1200, .iso1600, .iso2000, .iso2500, .iso3200, .iso4000, .iso5000,
                .iso6400, .iso8000, .iso10000, .iso12800, .iso16000, .iso20000, .iso25600, .iso32000, .iso40000, .iso51200]
    }

    public var logKey: String {
        return LogEvent.LogKeyHUDBottomBarButton.cameraIsoSetting.name
    }
}
