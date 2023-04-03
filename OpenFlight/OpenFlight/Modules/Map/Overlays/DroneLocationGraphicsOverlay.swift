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
import GroundSdk
import CoreLocation
import Combine

private extension ULogTag {
    static let tag = ULogTag(name: "DroneLocationGraphicsOverlay")
}

/// Drone location overlay.
public final class DroneLocationGraphicsOverlay: AGSGraphicsOverlay {

    static let Key = "DroneLocationGraphicsOverlayKey"

    // MARK: - Private Properties
    /// Combine cancellables
    private var cancellables = Set<AnyCancellable>()
    // Drone graphic
    private let droneGraphic: DroneLocationGraphic
    // MARK: - Public Properties
    public let viewModel: DroneLocationGraphicsOverlayViewModel

    /// Elevation at take off point, must be provided by 3D maps using the overlay.
    public var elevationTakeOff: Double = 0
    public var droneLocation: OrientedLocation?

    public var isDroneConnected: Bool = false

    // MARK: - Override Funcs
    /// Init
    /// - parameters:
    ///   - isScene : true if the overlay is created for a 3D scene, false for a 2D map
    ///   - showWhenDisconnected : true if the drone icon should be visible when the drone is disconnected
    init(isScene: Bool = false, showWhenDisconnected: Bool = false) {
        viewModel = DroneLocationGraphicsOverlayViewModel(
            isScene: isScene,
            showWhenDisconnected: showWhenDisconnected,
            connectedDroneHolder: Services.hub.connectedDroneHolder,
            locationsTracker: Services.hub.locationsTracker)
        droneGraphic = DroneLocationGraphic(is3d: isScene)
        super.init()

        if let location = viewModel.droneLocation, let point = location.coordinates?.agsPoint {
            droneGraphic.update(geometry: point, heading: location.heading)
        }

        let renderer = AGSSimpleRenderer()
        renderer.sceneProperties?.headingExpression = "[HEADING]"
        renderer.sceneProperties?.pitchExpression = "[PITCH]"
        self.renderer = renderer
        graphics.add(droneGraphic)

        viewModel.isDroneConnectedPublisher
            .sink { [weak self] isDroneConnected in
                self?.isDroneConnected = isDroneConnected
            }
            .store(in: &cancellables)

        viewModel.$droneLocation
            .sink { [weak self] droneLocation in
                guard let self = self, let droneLocation = droneLocation else { return }
                self.update(location: droneLocation)
            }
            .store(in: &cancellables)

        viewModel.droneIconPublisher
            .sink { [weak self] droneSymbol in
                guard let self = self else { return }
                self.droneGraphic.update(symbol: droneSymbol)
            }
            .store(in: &cancellables)
    }

    // MARK: - Private Funcs
    /// Update the location of the agsGraphic
    ///
    /// - Parameters
    ///     - location : the new location
    private func update(location: OrientedLocation) {
        guard let coordinates = location.coordinates else { return }
        droneLocation = location
        var geometry = coordinates.agsPoint
        if sceneProperties?.surfacePlacement != .drapedFlat {
            geometry = AGSPoint(x: geometry.x, y: geometry.y, z: max(coordinates.altitude, elevationTakeOff), spatialReference: .wgs84())
            droneLocation?.coordinates?.altitude = geometry.z
        }

        droneGraphic.update(geometry: geometry, heading: location.heading)
    }
}
