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
public final class DroneLocationGraphicsOverlay: CommonGraphicsOverlay {

    static let Key = "DroneLocationGraphicsOverlayKey"

    // MARK: - Private Properties
    // Drone graphic
    private var droneGraphic: FlightPlanLocationGraphic?

    // MARK: - Public Properties
    public var viewModel = DroneLocationGraphicsOverlayViewModel(
        connectedDroneHolder: Services.hub.connectedDroneHolder,
        locationsTracker: Services.hub.locationsTracker)

    /// Elevation at take off point, must be provided by 3D maps using the overlay.
    public var elevationTakeOff: Double = 0

    // MARK: - Override Funcs
    /// Init
    override public init() {
        super.init()
        viewModel.droneLocationPublisher
            .sink { [weak self] droneLocation in
                self?.update(location: droneLocation)
            }
            .store(in: &cancellables)

        viewModel.droneConnectionStatePublisher
            .sink { [weak self] droneConnected in
                guard let self = self else { return }
                self.isActive.value = droneConnected
            }
            .store(in: &cancellables)

        viewModel.droneIconPublisher.removeDuplicates()
            .sink { [weak self] droneIcon in
                self?.droneGraphic?.update(image: droneIcon)
            }
            .store(in: &cancellables)

        viewModel.droneIcon3DPublisher.removeDuplicates()
            .sink { [weak self] droneIcon3D in
                self?.droneGraphic?.update(image3D: droneIcon3D)
            }
            .store(in: &cancellables)
    }

    init(isScene: Bool) {
        super.init()
        viewModel.isScene.value = isScene
        viewModel.droneLocationPublisher
            .sink { [weak self] droneLocation in
                self?.update(location: droneLocation)
            }
            .store(in: &cancellables)

        viewModel.droneConnectionStatePublisher
            .sink { [weak self] droneConnected in
                guard let self = self else { return }
                self.isActive.value = droneConnected
            }
            .store(in: &cancellables)

        viewModel.droneIconPublisher.removeDuplicates()
            .sink { [weak self] droneIcon in
                self?.droneGraphic?.update(image: droneIcon)
            }
            .store(in: &cancellables)

        viewModel.droneIcon3DPublisher.removeDuplicates()
            .sink { [weak self] droneIcon3D in
                self?.droneGraphic?.update(image3D: droneIcon3D)
            }
            .store(in: &cancellables)
    }

    /// Updates camera zoom level and camera position
    ///
    /// - Parameters:
    ///     - cameraZoomLevel: new camera zoom level
    ///     - position: new position of camera
    func update(cameraZoomLevel: Int, position: AGSPoint) {
        droneGraphic?.update(cameraZoomLevel: cameraZoomLevel, position: position)
    }

    // MARK: - Private Funcs
    /// Update the location of the agsGraphic
    ///
    /// - Parameters
    ///     - location : the new location
    private func update(location: OrientedLocation) {
        guard let coordinates = location.coordinates else {return}
        let adjustedLocation = Location3D(coordinate: coordinates.coordinate, altitude: max(coordinates.altitude, elevationTakeOff))
        var geometry = adjustedLocation.agsPoint

        if let droneGraphic = droneGraphic {
            if sceneProperties?.surfacePlacement == .drapedFlat {
                geometry = AGSPoint(x: adjustedLocation.agsPoint.x, y: adjustedLocation.agsPoint.y, z: 0, spatialReference: .wgs84())
            }
            droneGraphic.update(geometry: geometry)
            droneGraphic.update(angle: Float(location.heading))
            droneGraphic.setReduced(viewModel.isMiniMap.value)
            setOrientationOfDroneGraphic()
        } else {
            // create graphic for drone location, if it does not exist
            let attributes = ["type": "droneLocation"]
            droneGraphic = FlightPlanLocationGraphic(
                geometry: geometry, heading: Float(location.heading),
                attributes: attributes,
                image: viewModel.isScene.value ? nil : viewModel.droneIconSubject.value,
                image3D: viewModel.isScene.value ? viewModel.droneIconSubject3D.value : nil,
                display3D: viewModel.isScene.value)
            droneGraphic?.setReduced(viewModel.isMiniMap.value)
            setOrientationOfDroneGraphic()
            if let droneGraphic = droneGraphic {
                graphics.add(droneGraphic)
            }
        }
    }

    /// Set orientation of drone graphic depending on type of map / scene and if it is flat
    private func setOrientationOfDroneGraphic() {
        droneGraphic?.locationSymbol?.angleAlignment = viewModel.isScene.value ? .screen : .map
        if let sceneProperties = sceneProperties {
            if viewModel.isScene.value {
                droneGraphic?.update(applyCameraHeading: sceneProperties.surfacePlacement != .drapedFlat)
            } else {
                droneGraphic?.update(applyCameraHeading: sceneProperties.surfacePlacement == .drapedFlat)
            }
        }
    }

    func update(cameraHeading: Double) {
        droneGraphic?.update(cameraHeading: cameraHeading)
    }

    // MARK: - Public Funcs
    /// Clears the overlay
    public func clearGraphics() {
        graphics.removeAllObjects()
        self.droneGraphic = nil
    }
}
