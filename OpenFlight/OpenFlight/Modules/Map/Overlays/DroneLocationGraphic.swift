//    Copyright (C) 2021 Parrot Drones SAS
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

import ArcGIS
import UIKit

/// Class for Drone location graphic
public final class DroneLocationGraphic: AGSGraphic {
    private var heading: Double = 0

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - is3d: Whether if the icon is in 3D
    public init(is3d: Bool) {
        /// We want to make the 3D icon spike as the drone anchor but the possible values are (top, center, bottom).
        /// In order to do that, we changed the dae file to make the drone point to the bottom,
        /// declared the anchor as bottom then added a pitch to move the icon horizontally again.
        super.init(geometry: nil, symbol: nil, attributes: ["PITCH": is3d ? 90 : 0])
    }

    /// Updates oriented location.
    ///
    /// - Parameters:
    ///     - geometry: new geometry.
    ///     - heading: new drone heading angle.
    func update(geometry: AGSPoint, heading: Double) {
        self.geometry = geometry
        self.heading = heading
        if let icon2d = symbol as? AGSPictureMarkerSymbol {
            icon2d.angle = Float(heading)
        } else {
            attributes["HEADING"] = heading
        }
    }

    /// Updates drone icon.
    ///
    /// - Parameters:
    ///     - symbol: new icon.
    func update(symbol: AGSSymbol?) {
        (symbol as? AGSPictureMarkerSymbol)?.angle = Float(heading)
        self.symbol = symbol
    }
}
