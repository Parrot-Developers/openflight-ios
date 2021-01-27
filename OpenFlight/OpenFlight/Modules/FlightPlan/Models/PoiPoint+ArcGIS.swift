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

/// Utility extension for `PoiPoint` usage with ArcGIS.

extension PoiPoint {
    // MARK: - Public Properties
    /// Returns AGSPoint for poi.
    var agsPoint: AGSPoint {
        return AGSPoint(x: self.coordinate.longitude,
                        y: self.coordinate.latitude,
                        z: self.altitude,
                        spatialReference: .wgs84())
    }

    // MARK: - Public Funcs
    /// Computes marker graphic for poi.
    ///
    /// - Parameters:
    ///    - index: index of poi
    /// - Returns: computed graphic
    func markerGraphic(index: Int) -> FlightPlanPoiPointGraphic {
        return FlightPlanPoiPointGraphic(poiPoint: self,
                                            index: index)
    }

    /// Computes label graphic for poi.
    ///
    /// - Parameters:
    ///    - index: index of poi
    /// - Returns: computed graphic
    func labelGraphic(index: Int) -> FlightPlanPoiPointLabelGraphic {
        return FlightPlanPoiPointLabelGraphic(poiPoint: self,
                                                 index: index)
    }
}
