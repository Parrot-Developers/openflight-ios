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
    static let tag = ULogTag(name: "TouchAndFlyGraphicsOverlay")
}

/// User location overlay.
public final class TouchAndFlyGraphicsOverlay: AGSGraphicsOverlay {
    static let Key = "TouchAndFlyGraphicsOverlayKey"

    // MARK: - Private Properties
    /// Combine cancellables
    private var cancellables = Set<AnyCancellable>()
    /// Way point graphic
    public var wayPointGraphic: FlightPlanWayPointGraphic?
    /// Point of interest graphic
    private var poiGraphic: FlightPlanPoiPointGraphic?
    /// Drone last position
    private var droneLocation: OrientedLocation?

    /// Returns Touch and Fly's drone to waypoint line, if any.
    var touchAndFlyWayPointLineGraphic: TouchAndFlyDroneToPointLineGraphic? {
        return self.graphics
            .compactMap { $0 as? TouchAndFlyDroneToPointLineGraphic }
            .first
    }

    // MARK: - Public Properties
    public var viewModel = TouchAndFlyGraphicsOverlayViewModel()

    override public init() {
        super.init()
        viewModel.graphicTypePublisher.sink { [weak self] graphicType in
            guard let self = self else { return }
            switch graphicType {
            case .waypoint(location: let location):
                self.updateWayPointLocation(location: location)
            case .poi(location: let location):
                self.updatePoiLocation(location: location)
            case .none:
                self.clearGraphics()
            }
        }.store(in: &cancellables)

        viewModel.droneLocationPublisher.sink { [weak self] location in
            self?.droneLocation = location
            self?.updateWayPointItinerary()
        }.store(in: &cancellables)
    }

    /// Update way point location
    ///
    /// - Parameter location: the location of the way point
    func updateWayPointLocation(location: Location3D) {
        if wayPointGraphic == nil {
            clearGraphics()
            wayPointGraphic = FlightPlanWayPointGraphic(touchAndFlyLocation: location)
            if let wayPointGraphic = wayPointGraphic {
                updateWayPointItinerary()
                graphics.add(wayPointGraphic)
            }
        } else {
            wayPointGraphic?.update(location: location)
            updateWayPointItinerary()
        }
    }

    /// Update drone Itinerary
    func updateWayPointItinerary() {
        guard let locationWayPoint = wayPointGraphic?.location,
              let droneLocation = droneLocation?.coordinates else { return }
        let line = AGSPolyline(points: [droneLocation.agsPoint, locationWayPoint.agsPoint])
        if let lineGraphic = touchAndFlyWayPointLineGraphic {
            lineGraphic.update(with: line)
        } else {
            let lineGraphic = TouchAndFlyDroneToPointLineGraphic(polyline: line, isWayPoint: true)
            graphics.add(lineGraphic)
        }
    }

    /// Update poi location
    ///
    /// - Parameter location: the location of the poi
    func updatePoiLocation(location: Location3D) {
        if self.poiGraphic == nil {
            clearGraphics()
            poiGraphic = FlightPlanPoiPointGraphic(touchAndFlyLocation: location)
            if let poiGraphic = poiGraphic {
                graphics.add(poiGraphic)
            }
        } else {
            poiGraphic?.update(location: location)
        }
    }

    /// Clear graphics
    private func clearGraphics() {
        graphics.removeAllObjects()
        poiGraphic = nil
        wayPointGraphic = nil
    }
}
