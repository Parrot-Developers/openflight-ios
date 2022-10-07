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

import CoreLocation
import ArcGIS

/// `MapViewController` extension dedicated to RTH display
extension MapViewController {
    // MARK: - Private Enums
    private enum Constants {
        static let overlayKey: String = "RTHOverlayKey"
    }

    private var rthOverlay: RthGraphicsOverlay? {
        return getGraphicOverlay(forKey: Constants.overlayKey) as? RthGraphicsOverlay
    }

    /// Adds or removes RTH overlay.
    ///
    /// - Parameters:
    ///    - isActive: true if the drone is currently returning to home
    ///    - isConnected: true if the drone is connected
    ///    - droneLocation: location of the drone
    ///    - homeLocation: location of the home point
    ///    - minAltitude: minimum RTH altitude
    func updateRthOverlay(isActive: Bool, isConnected: Bool, droneLocation: Location3D?, homeLocation: CLLocationCoordinate2D?, minAltitude: Double) {
        if currentMapMode.isHudMode, isActive, isConnected,
           let droneLocation = droneLocation,
           let homeLocation = homeLocation {
            if rthOverlay == nil {
                createRthOverlay(droneLocation: droneLocation, homeLocation: homeLocation, minAltitude: minAltitude)
            }
            displayRthGraphics(homeLocation: homeLocation, droneLocation: droneLocation, minAltitude: minAltitude)
        } else {
            rthOverlay?.clearGraphics()
            removeGraphicOverlay(forKey: Constants.overlayKey)
        }
    }

    /// Displays or refreshes the graphics of the RTH overlay.
    ///
    /// - Parameters:
    ///    - homeLocation: location of the home point
    ///    - droneLocation: location of the drone
    ///    - minAltitude: minimum RTH altitude
    func displayRthGraphics(homeLocation: CLLocationCoordinate2D, droneLocation: Location3D, minAltitude: Double) {
        guard let rthOverlay = rthOverlay else {
            return
        }
        updateElevationVisibility()
        if shouldDisplayMapIn2D {
            rthOverlay.sceneProperties?.surfacePlacement = .drapedFlat
        } else {
            rthOverlay.sceneProperties?.surfacePlacement = .relativeToScene
            rthOverlay.sceneProperties?.altitudeOffset = 1
        }
        let rthLocation = Location3D(coordinate: homeLocation, altitude: 0.0)
        rthOverlay.update(homeLocation: rthLocation, droneLocation: droneLocation)
    }

    /// Creates the RTH overlay.
    func createRthOverlay(droneLocation: Location3D, homeLocation: CLLocationCoordinate2D, minAltitude: Double) {
        let newOverlay = RthGraphicsOverlay(droneLocation: droneLocation, homeLocation: homeLocation, minAltitude: minAltitude)
        addGraphicOverlay(newOverlay, forKey: Constants.overlayKey, at: 0)
        getGraphicOverlay(forKey: Constants.overlayKey)?.sceneProperties?.surfacePlacement = .drapedFlat
    }
}
