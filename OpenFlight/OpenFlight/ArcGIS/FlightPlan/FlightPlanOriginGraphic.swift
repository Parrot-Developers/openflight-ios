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
        static let width: CGFloat = 29.0
        static let height: CGFloat = 30.0
        static let offSetY: CGFloat = 3
        static let offSetX: CGFloat = 1.5
        static let borderSize: CGFloat = 5.0
        static let defaultColor: UIColor = ColorName.highlightColor.color
        static let selectedColor: UIColor = ColorName.white.color
    }

    // MARK: - Internal Properties
    /// Associated waypoint.
    private(set) var originWayPoint: WayPoint?
    /// Symbol
    private var arrow: AGSPictureMarkerSymbol?
    /// Heading
    private var headingDegrees: Float = 0
    /// Rotation factor to fix heading. -1 when overlay type is draped.
    private var rotationFactor: Float = 1

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - origin: origin waypoint
    public init(origin: WayPoint) {
        let triangleView = TriangleView(frame: CGRect(x: 0, y: 0, width: Constants.width,
                                                      height: Constants.height), color: Constants.defaultColor,
                                                      externalColor: Constants.selectedColor)
        arrow = AGSPictureMarkerSymbol(image: triangleView.asImage())
        arrow?.angleAlignment = .map
        arrow?.offsetY = Constants.offSetY
        arrow?.offsetX = Constants.offSetX
        originWayPoint = origin
        super.init(geometry: origin.agsPoint,
                   symbol: arrow,
                   attributes: nil)

        orientationCalculation()
    }

    /// Calculate orientation of origin
    private func orientationCalculation() {
        guard let origin = originWayPoint else { return }
        if let coordinateNextWayPoint = origin.nextWayPoint?.coordinate {
            let deltaLong = (coordinateNextWayPoint.longitude - origin.coordinate.longitude).toRadians()
            let xValue = cos(coordinateNextWayPoint.latitude.toRadians()) * sin(deltaLong)
            let yValue = cos(origin.coordinate.latitude.toRadians())
                * sin(coordinateNextWayPoint.latitude.toRadians())
                - sin(origin.coordinate.latitude.toRadians())
                * cos(coordinateNextWayPoint.latitude.toRadians()) * cos(deltaLong)
            let bearing = atan2(xValue, yValue)
            headingDegrees = Float(bearing.toDegrees())
            arrow?.angle = Float(headingDegrees) * rotationFactor
        }
    }

    /// Updates rotation factor to fix heading display.
    func update(rotationFactor: Float) {
        self.rotationFactor = rotationFactor
        orientationCalculation()
    }

    /// Hides arrow symbol.
    func hidden(_ value: Bool) {
        if value {
            symbol = nil
        } else {
            symbol = arrow
        }
    }

}
