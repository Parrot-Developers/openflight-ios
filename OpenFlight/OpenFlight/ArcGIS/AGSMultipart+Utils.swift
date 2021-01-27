// Copyright (C) 2020 Parrot Drones SAS
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

/// Utility extension for `AGSMultipart`

extension AGSGeometry {
    /// Makes envelope from multipart geometry with margins.
    ///
    /// - Parameters:
    ///     - marginFactor: factor of self's max dimention to add, as a margin
    ///
    /// - Returns: AGSEnvelope.
    func envelopeWithMargin(_ marginFactor: Double = ArcGISStyle.envelopMarginFactor) -> AGSEnvelope {
        let geodeticLength = AGSGeometryEngine.geodeticLength(of: self,
                                                              lengthUnit: .meters(),
                                                              curveType: .geodesic)
        // Prevent from short flights display issue.
        guard geodeticLength > ArcGISStyle.minimumFlightLineLength
            else {
                // Provide minimum envolope size to prevent from display issue.
                return AGSEnvelope(center: extent.center,
                                   width: ArcGISStyle.defaultEnvelopWidth,
                                   height: ArcGISStyle.defaultEnvelopWidth)
        }
        let envelopeBuilder = AGSEnvelopeBuilder(spatialReference: .wgs84())
        envelopeBuilder.union(with: self.extent)
        envelopeBuilder.expand(byFactor: marginFactor)

        return envelopeBuilder.extent
    }

    /// Makes polygon from geometry with margins in meter.
    /// Geometry polygon will be kept.
    ///
    /// - Parameters:
    ///     - marginInMeter: margin in meter to add.
    ///
    /// - Returns: AGSPolygon.
    public func polygonWithMargin(_ marginInMeter: Double) -> AGSPolygon? {
        return AGSGeometryEngine.geodeticBufferGeometry(self,
                                                        distance: marginInMeter,
                                                        distanceUnit: AGSLinearUnit.meters(),
                                                        maxDeviation: 1.0,
                                                        curveType: .geodesic)
    }
}
