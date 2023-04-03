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

/// Graphic class to show the origin of a trajectory
public final class FlightPlanOriginGraphic: FlightPlanGraphic {
    // MARK: - Private Enums
    private enum Constants {
        static let defaultColor: UIColor = ColorName.blueDodger.color
        static let coneSideSize = 1.2
        static let coneLengthSize = 3.0
        static let coordsToResizeFactor: Double = 3500
        static let minResizeFactor: Double = 0.7
        static let maxResizeFactor: Double = 7
        static let lngToMeters: Double = 111_320
        static let latToMeters: Double = 110_574
        static let coneTraitOverlap: Double = 0.95
    }

    // MARK: - Internal Properties
    private var cone: AGSSimpleMarkerSceneSymbol

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - origin: origin waypoint
    public init?(wayPoints: [WayPoint]) {
        guard let origin = wayPoints.first?.agsPoint else { return nil }
        cone = AGSSimpleMarkerSceneSymbol.cone(with: Constants.defaultColor,
                                               diameter: Constants.coneSideSize,
                                               height: Constants.coneLengthSize,
                                               anchorPosition: .center)
        cone.pitch = 90

        super.init(geometry: origin, symbol: cone, attributes: nil)
        adjustSize(wayPoints: wayPoints)
        applyRotation(wayPoints: wayPoints)
        adjustPositionOffset(point: origin)
    }

    /// Hides arrow symbol.
    func hidden(_ value: Bool) {
        if value {
            symbol = nil
        } else {
            symbol = cone
        }
    }

    /// Applies rotation to symbols.
    private func applyRotation(wayPoints: [WayPoint]) {
        guard wayPoints.count >= 2 else { return }
        cone.heading = wayPoints[1].coordinate.bearingTo(wayPoints[0].coordinate)
    }

    private func adjustSize(wayPoints: [WayPoint]) {
        guard !wayPoints.isEmpty else { return }
        let latitudes = wayPoints.map { $0.coordinate.latitude }.sorted()
        let longitudes = wayPoints.map { $0.coordinate.longitude }.sorted()
        let diffLat = (latitudes.last ?? 0) - (latitudes.first ?? 0)
        let midLat = ((latitudes.last ?? 0) + (latitudes.first ?? 0)).toRadians() / 2
        let diffLng = ((longitudes.last ?? 0) - (longitudes.first ?? 0)) * cos(midLat)
        var resizeFactor = ((diffLng + diffLat) / 2) * Constants.coordsToResizeFactor
        resizeFactor = max(Constants.minResizeFactor, min(resizeFactor, Constants.maxResizeFactor))
        cone.height = Constants.coneLengthSize * resizeFactor
        cone.width = Constants.coneSideSize * resizeFactor
        cone.depth = Constants.coneSideSize * resizeFactor
        symbol = cone
    }

    private func adjustPositionOffset(point: AGSPoint) {
        let size = Double(cone.height) / 2 * Constants.coneTraitOverlap
        let heading = Double(cone.heading).toRadians()
        let deltaX = (size / Constants.lngToMeters) * sin(heading) / cos(Double(point.y).toRadians())
        let deltaY = (size / Constants.latToMeters) * cos(heading)
        geometry = AGSPoint(x: point.x + deltaX, y: point.y + deltaY, z: point.z, spatialReference: .wgs84())
    }
}
