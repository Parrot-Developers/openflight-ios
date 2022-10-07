//    Copyright (C) 2022 Parrot Drones SAS
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

extension MapViewController {
    /// Whether the point is inside the zone
    ///
    /// - Parameters:
    ///    - point: ags point
    ///    - altitude: altitude to apply
    /// - Returns: Boolean indicating if the location is inside the zone
    public func isInside(point: AGSPoint, altitude: Double = 0.0) -> Bool {
        let locationPoint: AGSPoint
        if shouldDisplayMapIn2D {
            locationPoint = AGSPoint(x: point.x, y: point.y, z: 0.0, spatialReference: .wgs84())
        } else {
            locationPoint = AGSPoint(x: point.x, y: point.y, z: point.z + altitude, spatialReference: .wgs84())
        }

        let screenPoint = sceneView.location(toScreen: locationPoint).screenPoint
        guard !screenPoint.isOriginPoint else { return false }
        let minX = sceneView.bounds.width * MapConstants.mapBorderHorizontal
        let minY = sceneView.bounds.height * MapConstants.mapBorderVertical
        let width = sceneView.bounds.width * (1 - MapConstants.mapBorderHorizontal * 2)
        let height = sceneView.bounds.height * (1 - MapConstants.mapBorderVertical * 2)
        let zone = CGRect(x: minX, y: minY, width: width, height: height)

        return zone.contains(screenPoint)
    }

    /// Whether the location is inside the zone
    ///
    /// - Parameters:
    ///    - location: the 2d location of a point
    ///    - altitude: altitude of the point (AMSL)
    /// - Returns: Boolean indicating if the location is inside the zone
    public func isInside(location: CLLocationCoordinate2D, altitude: Double?) -> Bool {
        return isInside(point: AGSPoint(clLocationCoordinate2D: location), altitude: altitude ?? 0.0)
    }

    /// Creates a view point to view a polyline.
    ///
    /// - Parameters:
    ///    - polyline: the polyline that has to be visible
    ///    - altitudeOffset: altitude offset to apply to polyline, in meters
    /// - Returns: a new view point
    func viewPoint(polyline: AGSPolyline, altitudeOffset: Double? = nil) -> AGSViewpoint {
        let envelope = polyline.envelopeWithMargin(ArcGISStyle.projectEnvelopeMarginFactor,
                                                   altitudeOffset: altitudeOffset)
        return AGSViewpoint(targetExtent: envelope)
    }
}
