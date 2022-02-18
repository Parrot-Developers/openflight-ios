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

/// Graphic class for Flight Plan's location graphic
public final class FlightPlanLocationGraphic: AGSGraphic {
    // MARK: - Private Properties
    private var locationSymbol: AGSPictureMarkerSymbol
    private var cameraHeading: Int = 0
    private var angle: Int = 0
    private var applyCameraHeading = true
    private let arcgisMagicNumber = -1

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - geometry: geometry
    ///    - heading: heading
    ///    - attributes: attributes
    ///    - image: image
    public init(geometry: AGSPoint, heading: Float, attributes: [String: String], image: UIImage) {
        self.angle = Int(heading)
        locationSymbol = AGSPictureMarkerSymbol(image: image)
        locationSymbol.angle = heading
        let attributes = attributes
        super.init(geometry: geometry, symbol: locationSymbol, attributes: attributes)
        applyRotation()
        self.symbol = getSymbol()
    }

    /// Get symbol
    ///
    /// - Returns: symbol
    private func getSymbol() -> AGSCompositeSymbol {
        var array = [AGSSymbol]()
        array.append(locationSymbol)
        return AGSCompositeSymbol(symbols: array)
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
        guard geometry != self.geometry else {
            return
        }
        self.geometry = geometry
        applyRotation()
        symbol = getSymbol()
    }

    /// Applies rotation to symbols.
    private func applyRotation() {
        var result = 0
        if applyCameraHeading {
            result = (angle - cameraHeading) % 360
        } else {
            result = arcgisMagicNumber * (angle % 360)
        }
        locationSymbol.angle = (Float(result))
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
    ///
    /// - Parameters:
    ///     - image: new image
    func update(image: UIImage) {
        let angle = locationSymbol.angle
        locationSymbol = AGSPictureMarkerSymbol(image: image)
        locationSymbol.angle = angle
        symbol = getSymbol()
    }
}
