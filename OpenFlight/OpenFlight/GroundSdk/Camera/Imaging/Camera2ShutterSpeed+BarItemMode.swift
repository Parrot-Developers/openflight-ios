//
//  Copyright (C) 2020 Parrot Drones SAS
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

/// Utility extension for `Camera2ShutterSpeed`.
extension Camera2ShutterSpeed: BarItemMode, RulerDisplayable, Sortable {
    // MARK: - BarItemMode
    public var title: String {
        switch self {
        case .one:
            return shortTitle
        default:
            return String(format: "%@ %@", shortTitle, L10n.unitSecond)
        }
    }

    var shortTitle: String {
        switch self {
        case .oneOver10000:
            return "1/10000"
        case .oneOver8000:
            return "1/8000"
        case .oneOver6400:
            return "1/6400"
        case .oneOver5000:
            return "1/5000"
        case .oneOver4000:
            return "1/4000"
        case .oneOver3200:
            return "1/3200"
        case .oneOver2500:
            return "1/2500"
        case .oneOver2000:
            return "1/2000"
        case .oneOver1600:
            return "1/1600"
        case .oneOver1250:
            return "1/1250"
        case .oneOver1000:
            return "1/1000"
        case .oneOver800:
            return "1/800"
        case .oneOver640:
            return "1/640"
        case .oneOver500:
            return "1/500"
        case .oneOver400:
            return "1/400"
        case .oneOver320:
            return "1/320"
        case .oneOver240:
            return "1/240"
        case .oneOver200:
            return "1/200"
        case .oneOver160:
            return "1/160"
        case .oneOver120:
            return "1/120"
        case .oneOver100:
            return "1/100"
        case .oneOver80:
            return "1/80"
        case .oneOver60:
            return "1/60"
        case .oneOver50:
            return "1/50"
        case .oneOver40:
            return "1/40"
        case .oneOver30:
            return "1/30"
        case .oneOver25:
            return "1/25"
        case .oneOver15:
            return "1/15"
        case .oneOver10:
            return "1/10"
        case .oneOver8:
            return "1/8"
        case .oneOver6:
            return "1/6"
        case .oneOver4:
            return "1/4"
        case .oneOver3:
            return "1/3"
        case .oneOver2:
            return "1/2"
        case .oneOver1_5:
            return "1/1.5"
        case .one:
            return String(format: "1 %@", L10n.unitSecondLongFormat)
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

    // MARK: - RulerDisplayable
    var rulerText: String? {
        return shortTitle
    }

    var rulerBackgroundColor: UIColor? {
        return nil
    }

    // MARK: - Sortable
    public static var sortedCases: [Camera2ShutterSpeed] {
        return [.oneOver10000, .oneOver8000, .oneOver6400, .oneOver5000, .oneOver4000, .oneOver3200,
                .oneOver2500, .oneOver2000, .oneOver1600, .oneOver1250, .oneOver1000, .oneOver800, .oneOver640,
                .oneOver500, .oneOver400, .oneOver320, .oneOver240, .oneOver200, .oneOver160, .oneOver120,
                .oneOver100, .oneOver80, .oneOver60, .oneOver50, .oneOver40, .oneOver30, .oneOver25, .oneOver15,
                .oneOver10, .oneOver8, .oneOver6, .oneOver4, .oneOver3, .oneOver2, .oneOver1_5, .one]
    }

    public var logKey: String {
        return LogEvent.LogKeyHUDBottomBarButton.shutterSpeedSetting.name
    }
}
