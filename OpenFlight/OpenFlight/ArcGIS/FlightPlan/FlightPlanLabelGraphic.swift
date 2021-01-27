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

import ArcGIS

/// Base class for Flight Plan label items.

public class FlightPlanLabelGraphic: FlightPlanPointGraphic {
    // MARK: - Override Properties
    override var altitude: Double? {
        guard let agsPoint = attributes[FlightPlanAGSConstants.agsPointAttributeKey] as? AGSPoint else {
            return nil
        }
        return agsPoint.z - Constants.textAltitudeOffset
    }

    // MARK: - Public Properties
    /// Main label for graphic (altitude display).
    var mainLabel: AGSTextSymbol? {
        return nil
    }

    // MARK: - Private Enums
    private enum Constants {
        // Labels altitude should be offset to prevent from colliding with other graphics.
        static let textAltitudeOffset: Double = 0.05
    }

    // MARK: - Override Funcs
    override func updateAltitude(_ altitude: Double) {
        self.attributes[FlightPlanAGSConstants.agsPointAttributeKey] = mapPoint?.withAltitude(altitude + Constants.textAltitudeOffset)

        mainLabel?.text = UnitHelper.stringDistanceWithDouble(altitude,
                                                              spacing: false)
    }

    // MARK: - Public Funcs
    /// Updates the item location.
    ///
    /// - Parameters:
    ///    - point: new location
    public func updateLocation(_ point: AGSPoint) {
        let drapedPoint = point.withAltitude(Constants.textAltitudeOffset)
        let elevatedPoint = point.withAltitude(point.z + Constants.textAltitudeOffset)
        attributes[FlightPlanAGSConstants.agsPointAttributeKey] = elevatedPoint
        attributes[FlightPlanAGSConstants.drapedAgsPointAttributeKey] = point.withAltitude(Constants.textAltitudeOffset)
        self.geometry = drapedPoint
    }
}

// MARK: - Internal Funcs
extension FlightPlanLabelGraphic {
    /// Refreshes label display.
    func refreshLabel() {
        guard let altitude = altitude else { return }

        mainLabel?.text = UnitHelper.stringDistanceWithDouble(altitude,
                                                              spacing: false)
    }
}
