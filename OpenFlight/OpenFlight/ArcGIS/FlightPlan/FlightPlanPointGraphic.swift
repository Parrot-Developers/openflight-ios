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

import ArcGIS

/// Base class for Flight Plan's points graphics.

public class FlightPlanPointGraphic: FlightPlanGraphic {
    // MARK: - Public Properties
    /// Returns graphic's geometry as `AGSPoint`.
    var mapPoint: AGSPoint? {
        return geometry as? AGSPoint
    }

    /// Returns graphic's altitude.
    var altitude: Double? {
        return mapPoint?.z
    }

    // MARK: - Public Funcs
    /// Updates altitude of waypoint.
    ///
    /// - Parameters:
    ///    - altitude: new altitude
    func updateAltitude(_ altitude: Double) {
        /// Implement in children.
    }
}

extension FlightPlanPointGraphic {
    /// Create image with text
    ///
    /// - Parameters:
    ///     - name: name
    ///     - textColor: text color
    ///     - fontSize: size of the font
    ///     - size: size of the text graphic
    /// - Returns: generated image
    static func imageWith(name: String?, textColor: UIColor, fontSize: CGFloat, size: CGSize) -> UIImage? {
        let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        let nameLabel = UILabel(frame: frame)
        nameLabel.textAlignment = .center
        nameLabel.backgroundColor = .clear
        nameLabel.textColor = textColor
        nameLabel.font = UIFont.rajdhaniSemiBold(size: fontSize)
        nameLabel.text = name
        UIGraphicsBeginImageContextWithOptions(frame.size, false, 0.0)
        if let currentContext = UIGraphicsGetCurrentContext() {
            nameLabel.layer.render(in: currentContext)
            let nameImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return nameImage
        }
        return nil
    }
}
