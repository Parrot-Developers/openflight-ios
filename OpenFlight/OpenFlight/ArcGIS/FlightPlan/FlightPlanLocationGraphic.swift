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

/// Graphic class for Flight Plan's location graphic
public final class FlightPlanLocationGraphic: AGSGraphic {
    // MARK: - Private Properties
    public var locationSymbol: AGSPictureMarkerSymbol?
    private var cameraHeading: Int = 0
    private var angle: Int = 0
    private var applyCameraHeading = true
    private var modelSymbol: AGSModelSceneSymbol?
    var compositeSymbol: AGSDistanceCompositeSceneSymbol?

    public var symbol3D: AGSModelSceneSymbol?
    private var cameraZoomLevel: Int?
    private var cameraPosition: AGSPoint?
    private var originalWidth: Double?
    private var originalHeight: Double?
    private var originalDepth: Double?

    private var distance: Double = 0
    private var isReduced = false
    private var originalGeometry: AGSPoint
    private var display3D = false
    private enum Constants {
        static let lngToMeters: Double = 111_320
        static let latToMeters: Double = 110_574
        static let kValue = 0.013
        static let symbolTraitOverlap = 1.3
    }

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - geometry: geometry
    ///    - heading: heading
    ///    - attributes: attributes
    ///    - image: image
    ///    - image3D: 3D image
    ///    - display3D: whether the display is in 3D or not
    public init(geometry: AGSPoint, heading: Float, attributes: [String: String], image: UIImage?,
                image3D: AGSModelSceneSymbol?, display3D: Bool) {
        self.originalGeometry = geometry
        self.angle = Int(heading)
        self.display3D = display3D

        if let image = image, !display3D {
            locationSymbol = AGSPictureMarkerSymbol(image: image)
            locationSymbol?.angle = heading
            super.init(geometry: geometry, symbol: locationSymbol, attributes: attributes)
        } else if let image3D = image3D {
            symbol3D = image3D
            symbol3D?.heading = Double(heading)
            symbol3D?.anchorPosition = .origin
            // set up the distance composite symbol

            super.init(geometry: geometry, symbol: symbol3D, attributes: attributes)
        } else {
            super.init(geometry: geometry, symbol: nil, attributes: attributes)
        }
        applyRotation()
        self.symbol = getSymbol()
    }

    /// Get symbol
    ///
    /// - Returns: symbol
    private func getSymbol() -> AGSSymbol? {
        var array = [AGSSymbol]()
        if display3D {
            if let symbol3D = symbol3D {
                compositeSymbol = AGSDistanceCompositeSceneSymbol()
                array.append(symbol3D)
                return AGSCompositeSymbol(symbols: array)
            }
        } else {
            if let compositeSymbol = compositeSymbol {
                return compositeSymbol
            } else if let locationSymbol = locationSymbol {
                array.append(locationSymbol)
                return AGSCompositeSymbol(symbols: array)
            }
        }
        return nil
    }

    /// Updates camera heading.
    ///
    /// - Parameters:
    ///     - cameraHeading: new camera heading
    func update(cameraHeading newCameraHeading: Double) {
        if cameraHeading != Int(newCameraHeading) {
            cameraHeading = Int(newCameraHeading)
            applyRotation()
            symbol = getSymbol()
        }
    }

    /// Updates angle
    ///
    /// - Parameters:
    ///     - angle:new  angle
    func update(angle newAngle: Float) {
        if angle != Int(newAngle) {
            angle = Int(newAngle)
            applyRotation()
            symbol = getSymbol()
        }
    }

    /// Updates geometry
    ///
    /// - Parameters:
    ///     - geometry: new geometry
    func update(geometry: AGSPoint) {
        guard geometry != self.originalGeometry else {
            return
        }
        originalGeometry = geometry
        updateSizeSymbol()
        applyRotation()
        symbol = getSymbol()
    }

    /// Applies rotation to symbols.
    private func applyRotation() {
        var result = 0
        if applyCameraHeading && symbol3D == nil {
            result = (angle - cameraHeading) % 360
        } else {
            // Minus because the bearing angle is counter-clockwise, but AGS expects a clockwise angle for a 2D graphic
            if symbol3D == nil {
                result = -1 * (angle % 360)
            } else {
                result = angle
            }
        }
        locationSymbol?.angle = (Float(result))
        symbol3D?.heading = Double(result)
        adjustPositionOffset()
    }

    /// Updates apply camera heading
    ///
    /// - Parameters:
    ///     - applyCameraHeading: new  apply camera heading
    func update(applyCameraHeading: Bool) {
        guard applyCameraHeading != self.applyCameraHeading else {
            return
        }
        self.applyCameraHeading = applyCameraHeading
        applyRotation()
        symbol = getSymbol()
    }

    /// Updates image
    /// PS : only used in 2D.
    ///
    /// - Parameters:
    ///     - image: new image
    func update(image: UIImage?) {
        if let image = image {
            let angle = locationSymbol?.angle
            locationSymbol = AGSPictureMarkerSymbol(image: image)
            locationSymbol?.angle = angle ?? 0
            symbol = getSymbol()
        } else {
            locationSymbol = nil
            symbol = getSymbol()
        }
    }

    /// Updates 3D image
    ///
    /// - Parameters:
    ///     - image: new image
    func update(image3D: AGSModelSceneSymbol?) {
        self.symbol3D = image3D
        symbol3D?.heading = Double(self.angle)
        symbol3D?.anchorPosition = .bottom
        symbol = getSymbol()
    }

    /// Updates camera zoom level and camera position
    ///
    /// - Parameters:
    ///     - cameraZoomLevel: new camera zoom level
    ///     - position: new position of camera
    func update(cameraZoomLevel: Int, position: AGSPoint) {
        self.cameraZoomLevel = cameraZoomLevel
        self.cameraPosition = position
        updateSizeSymbol()
        symbol = getSymbol()
    }

    /// Calculate distance between camera and the symbol.
    private func setDistanceBetweenCoordinate() {
        if let geometry = geometry as? AGSPoint, let cameraPosition = cameraPosition {
            distance = cameraPosition.distanceToPoint(geometry)
        }
    }

    /// Update size of 3D Symbol
    private func updateSizeSymbol() {
        setDistanceBetweenCoordinate()
        if let symbol3D = symbol3D {
            if originalWidth == nil, originalHeight == nil, originalDepth == nil {
                originalWidth = symbol3D.width
                originalHeight = symbol3D.height
                originalDepth = symbol3D.depth
            }

            guard let originalWidth = originalWidth, let originalHeight = originalHeight,
                    let originalDepth = originalDepth else { return }
            symbol3D.width = distance * originalWidth * Constants.kValue * (isReduced ? 2 : 1)
            symbol3D.height = distance * originalHeight * Constants.kValue * (isReduced ? 2 : 1)
            symbol3D.depth = distance * originalDepth * Constants.kValue * (isReduced ? 2 : 1)
        }
    }

    /// Set reduced mode, this is used when map is mini.
    ///
    /// - Parameters:
    ///    - value: the new value
    func setReduced(_ value: Bool) {
        self.isReduced = value
        updateSizeSymbol()
    }

    private func adjustPositionOffset() {
        guard let symbol3D = symbol3D else {
            self.geometry = originalGeometry
            return
        }
        let size = Double(max(symbol3D.width, symbol3D.height)) / 2  * Constants.symbolTraitOverlap
        let heading = Double(symbol3D.heading).toRadians()
        let deltaX = (size / Constants.lngToMeters) * sin(heading) / cos(Double(originalGeometry.y).toRadians())
        let deltaY = (size / Constants.latToMeters) * cos(heading)
        self.geometry = AGSPoint(x: originalGeometry.x - deltaX, y: originalGeometry.y - deltaY, z: originalGeometry.z, spatialReference: .wgs84())
    }
}
