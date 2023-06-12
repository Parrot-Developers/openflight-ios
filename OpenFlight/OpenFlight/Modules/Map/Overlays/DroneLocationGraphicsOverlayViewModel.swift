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

import Foundation

import Combine
import ArcGIS
import GroundSdk

/// ViewModel for `DroneLocationGraphicsOverlay`
public class DroneLocationGraphicsOverlayViewModel {
    // MARK: Private Properties
    /// Combine cancellables
    private var cancellables = Set<AnyCancellable>()
    private let locationsTracker: LocationsTracker
    private let connectedDroneHolder: ConnectedDroneHolder

    /// Whether the drone location is displayed in a scene or a map.
    public var droneIconSubject = CurrentValueSubject<AGSSymbol?, Never>(nil)
    public var isDroneConnectedPublisher: AnyPublisher<Bool, Never> {
        connectedDroneHolder.dronePublisher.map({ $0 != nil }).removeDuplicates().eraseToAnyPublisher()
    }

    // MARK: Public Properties
    /// Returns the drone location as displayed in the map
    @Published public var droneLocation: OrientedLocation?
    /// Returns the drone gps fixed
    @Published public var droneGpsFixed: Bool?
    public var droneIconPublisher: AnyPublisher<AGSSymbol?, Never> { droneIconSubject.eraseToAnyPublisher() }

    public let isScene: Bool
    private let showWhenDisconnected: Bool
    private var isMiniMapSubject = CurrentValueSubject<Bool, Never>(false)

    private enum Constants {
        static let icon3DWidth = 2.49834
        static let icon3DDepth = 0.337177
        static let icon3DHeight = 2.81204
        static let icon2DWidth = 116.0
        static let icon2DHeight = 116.0
    }

    /// Init
    /// - Parameters:
    ///  - networkService: the network service
    init(isScene: Bool, showWhenDisconnected: Bool, connectedDroneHolder: ConnectedDroneHolder, locationsTracker: LocationsTracker) {
        self.isScene = isScene
        self.showWhenDisconnected = showWhenDisconnected
        self.connectedDroneHolder = connectedDroneHolder
        self.locationsTracker = locationsTracker

        if let coordinates = locationsTracker.droneLocation, let heading = locationsTracker.droneHeading {
            let altitude = isScene ? (locationsTracker.droneAbsoluteAltitude ?? 0) : 0
            self.droneLocation = OrientedLocation(coordinates: Location3D(coordinate: coordinates, altitude: altitude), heading: heading)
        }

        let droneLocationPublisher = isScene
        ? locationsTracker.drone3DLocationPublisher(animated: true, absoluteAltitude: true)
        : locationsTracker.drone2DOrientedLocationPublisher(animated: true)
        droneLocationPublisher
            .sink { [weak self] location in
                self?.droneLocation = location
            }
            .store(in: &cancellables)

        isDroneConnectedPublisher.removeDuplicates().combineLatest(
            locationsTracker.droneGpsFixedPublisher.removeDuplicates(), isMiniMapSubject.removeDuplicates())
            .sink { [weak self] (isConnected, isGpsFixed, isMiniMap) in
                self?.updateDroneIcon(isConnected: isConnected, isGpsFixed: isGpsFixed, isMiniMap: isMiniMap)
            }
            .store(in: &cancellables)

        locationsTracker.droneGpsFixedPublisher.removeDuplicates()
            .sink { [weak self] isGpsFixed in
                self?.droneGpsFixed = isGpsFixed
            }.store(in: &cancellables)
    }

    /// Updates drone icon
    ///
    /// - Parameters:
    ///  - isConnected: if the drone is connected
    ///  - isGpsFixed: if we have a fixed gps location
    ///  - isMiniMap: if the map is displayed on the minimap
    func updateDroneIcon(isConnected: Bool, isGpsFixed: Bool, isMiniMap: Bool) {
        let shouldDisplay = isConnected || showWhenDisconnected
        if isScene {
            let symbol = AGSModelSceneSymbol(name: isGpsFixed ? "Drone3DOK" : "Drone3DKO", extension: "dae", scale: 1)
            symbol.anchorPosition = .bottom
            symbol.symbolSizeUnits = .dips
            let scale: Double = shouldDisplay ? (isMiniMap ? 14 : 7) : 0

            symbol.width = Constants.icon3DWidth * scale
            symbol.height = Constants.icon3DHeight * scale
            symbol.depth = Constants.icon3DDepth * scale
            droneIconSubject.value = symbol
        } else {
            let image = isGpsFixed ? Asset.Map.mapDrone.image : Asset.Map.mapDroneDisconnected.image
            let symbol = AGSPictureMarkerSymbol(image: image)
            symbol.angleAlignment = .map
            symbol.opacity = shouldDisplay ? 1 : 0

            let scale: Double = isMiniMap ? 2 : 1
            symbol.width = Constants.icon2DWidth * scale
            symbol.height = Constants.icon2DHeight * scale
            droneIconSubject.value = symbol
        }
    }

    /// Updates the value of isMiniMap
    ///
    /// - Parameter isMiniMap: the new value of isMiniMap
    func update(isMiniMap: Bool) {
        isMiniMapSubject.value = isMiniMap
    }
}
