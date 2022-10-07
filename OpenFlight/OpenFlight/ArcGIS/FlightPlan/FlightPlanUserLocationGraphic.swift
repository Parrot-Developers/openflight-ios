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

/// Graphic class for Flight Plan's location graphic
public final class FlightPlanUserLocationGraphic: AGSGraphic {
    // MARK: - Private Enums
    private enum Constants {
        static let innerColor: UIColor = ColorName.blueDodger.color
        static let innerSize: CGFloat = 7.5
        static let outerColor: UIColor = ColorName.white.color
        static let outerSize: CGFloat = 9.5
    }

    // MARK: - Private Properties
    private var locationSymbol: AGSCompositeSymbol

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - geometry: geometry
    ///    - attributes: attributes
    public init(geometry: AGSPoint, attributes: [String: String]) {
        locationSymbol = AGSCompositeSymbol(symbols: [
            AGSSimpleMarkerSymbol(style: .circle, color: Constants.outerColor, size: Constants.outerSize),
            AGSSimpleMarkerSymbol(style: .circle, color: Constants.innerColor, size: Constants.innerSize)
        ])
        let attributes = attributes
        super.init(geometry: geometry, symbol: locationSymbol, attributes: attributes)
        self.symbol = locationSymbol
    }
}
