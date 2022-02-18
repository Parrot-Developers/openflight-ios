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

import UIKit
import GroundSdk

/// Utility extension for `DiscoveredDrone`.

extension DiscoveredDrone {
    // MARK: - Internal Properties
    /// Returns wifi image regarding rssi value.
    var wifiImage: UIImage {
        if rssi > Constants.rssi40 {
            return Asset.Wifi.icWifiQuality5.image
        } else if rssi >= Constants.rssi40 {
            return Asset.Wifi.icWifiQuality4.image
        } else if rssi > Constants.rssi50 && rssi <= Constants.rssi40 {
            return Asset.Wifi.icWifiQuality3.image
        } else if rssi > Constants.rssi60 && rssi <= Constants.rssi50 {
            return Asset.Wifi.icWifiQuality2.image
        } else if rssi > Constants.rssi70 && rssi <= Constants.rssi60 {
            return Asset.Wifi.icWifiQuality1.image
        } else {
            return Asset.Wifi.icWifiOffline.image
        }
    }

    /// Returns wifi hightlighted image regarding rssi value.
    var wifiHighlightImage: UIImage {
        if rssi > Constants.rssi40 {
            return Asset.Wifi.icWifiQuality5Highlighted.image
        } else if rssi >= Constants.rssi40 {
            return Asset.Wifi.icWifiQuality4Highlighted.image
        } else if rssi > Constants.rssi50 && rssi <= Constants.rssi40 {
            return Asset.Wifi.icWifiQuality3Highlighted.image
        } else if rssi > Constants.rssi60 && rssi <= Constants.rssi50 {
            return Asset.Wifi.icWifiQuality2Highlighted.image
        } else if rssi > Constants.rssi70 && rssi <= Constants.rssi60 {
            return Asset.Wifi.icWifiQuality1Highlighted.image
        } else {
            return Asset.Wifi.icWifiOffline.image
        }
    }

    var cellularImage: UIImage {
        return Asset.Cellular.ic4GQuality5.image
    }

    var cellularHighlightImage: UIImage {
        return Asset.Cellular.ic4GQuality5Highlighted.image
    }

    // MARK: - Private Enums
    private enum Constants {
        static let rssi40: Int = -40
        static let rssi50: Int = -50
        static let rssi60: Int = -60
        static let rssi70: Int = -70
    }
}
