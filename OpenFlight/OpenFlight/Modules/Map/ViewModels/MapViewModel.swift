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

import Foundation
import Combine
import CoreLocation
import ArcGIS
import GroundSdk

/// ViewModel for `MapViewController`
public class MapViewModel {

    // MARK: Private Properties
    /// Combine cancellables
    private var cancellables = Set<AnyCancellable>()
    /// Force hide center button
    @Published private var forceHideCenterButton = false
    /// Auto center disabled subject
    private var autoCenterDisabledSubject = CurrentValueSubject<Bool, Never>(false)
    /// Always center on drone location
    @Published private var alwaysCenterOnDroneLocation = false
    /// Center state subject
    private var centerStateSubject = CurrentValueSubject<MapCenterState, Never>(.none)
    /// Locations tracker
    private unowned var locationsTracker: LocationsTracker
    /// Connected drone holder
    private unowned var connectedDroneHolder: ConnectedDroneHolder
    /// Network service
    private let networkService: NetworkService
    /// FlightPlan Edition Service
    private let flightPlanEdition: FlightPlanEditionService
    /// Current drone connection state
    private var droneConnectionStateSubject = CurrentValueSubject<Bool, Never>(false)
    /// Reference to GPS Instrument
    private var gpsRef: Ref<Gps>?
    /// Drone gps strength
    @Published private(set) var droneIcon = Asset.Map.mapDrone.image

    // MARK: Public Properties
    /// User location publisher
    public var userLocationPublisher: AnyPublisher<OrientedLocation, Never> { locationsTracker.userLocationPublisher }
    /// Drone location publisher
    public var droneLocationPublisher: AnyPublisher<OrientedLocation, Never> { locationsTracker.droneLocationPublisher }
    /// Drone connection state publisher
    public var droneConnectedPublisher: AnyPublisher<Bool, Never> { droneConnectionStateSubject.eraseToAnyPublisher() }
    /// Network reachable publisher
    public var networkReachablePublisher: AnyPublisher<Bool, Never> { networkService.networkReachable }
    /// Drone location
    public var droneLocation: OrientedLocation { locationsTracker.droneLocation }
    /// Return home location
    public var returnHomeLocation: CLLocationCoordinate2D? { locationsTracker.returnHomeLocation }

    // TODO: center button should not be managed by this VM (currently SplitObjects holds the IBOutlet)
    /// Hide center button publisher
    public var hideCenterButtonPublisher: AnyPublisher<Bool, Never> {
        centerStateSubject
            .combineLatest($forceHideCenterButton, autoCenterDisabledSubject)
            .map {
                let (centerState, forceHide, centerDisabled) = $0
                return centerState == .none || !centerDisabled || forceHide
            }
            .eraseToAnyPublisher()
    }
    /// Center state publisher
    public var centerStatePublisher: AnyPublisher<MapCenterState, Never> { centerStateSubject.eraseToAnyPublisher() }
    /// Auto center disabled
    public var autoCenterDisabled: Bool { autoCenterDisabledSubject.value }
    /// Auto center disabled publisher
    public var autoCenterDisabledPublisher: AnyPublisher<Bool, Never> { autoCenterDisabledSubject.eraseToAnyPublisher() }
    /// Helper for current center coordinates.
    public var currentCenterCoordinates: CLLocationCoordinate2D? {
        switch centerStateSubject.value {
        case .drone:
            return droneLocation.coordinates?.coordinate
        case .user:
            return locationsTracker.userLocation.coordinates?.coordinate
        case .project:
            return flightPlanEdition.currentFlightPlanValue?.center ??
            locationsTracker.userLocation.coordinates?.coordinate
        case .none:
            return nil
        }
    }
    /// Terrain elevation source.
    public var elevationSource: MapElevationSource

    // MARK: Init

    /// Init
    /// - Parameters:
    ///  - locationsTracker: the locations tracker
    ///  - currentDroneHolder: the current drone holder
    ///  - networkService: the network service
    ///  - flightPlanEdition: the FlightPlan Edition Service
    init(locationsTracker: LocationsTracker,
         connectedDroneHolder: ConnectedDroneHolder,
         networkService: NetworkService,
         flightPlanEdition: FlightPlanEditionService) {
        self.locationsTracker = locationsTracker
        self.connectedDroneHolder = connectedDroneHolder
        self.networkService = networkService
        self.flightPlanEdition = flightPlanEdition

        elevationSource = MapElevationSource(networkService: networkService)

        connectedDroneHolder.dronePublisher
            .sink { [weak self] drone in
                guard let self = self else { return }
                self.droneConnectionStateSubject.value = drone != nil
                self.listenGps(drone: drone)
            }
            .store(in: &cancellables)
    }

    /// Starts observing changes for gps strength and updates the gps Strength published property.
    ///
    /// - Parameter drone: the current drone
    func listenGps(drone: Drone?) {
        guard let drone = drone else {
            updateDroneIcon(gps: .none)
            return
        }
        gpsRef = drone.getInstrument(Instruments.gps) { [weak self] gps in
            self?.updateDroneIcon(gps: gps?.gpsStrength ?? .none)
        }
    }

    /// Updates drone icon according to its gps strength
    ///
    /// - Parameter gps: the current gps strength
    func updateDroneIcon(gps: GpsStrength) {
        droneIcon = (gps == .none || gps == .notFixed)
            ? Asset.Map.mapDroneDisconnected.image
            : Asset.Map.mapDrone.image
    }

    /// Listen to publishers that may change center map button behaviour
    /// - Parameters:
    ///  - currentMapModePublisher: Publisher for the mapMode in MapViewController
    func listenCenterState(currentMapModePublisher: AnyPublisher<MapMode, Never>) {
        Publishers.CombineLatest(
            Publishers.CombineLatest3(locationsTracker.droneLocationPublisher, locationsTracker.droneGpsFixedPublisher, $alwaysCenterOnDroneLocation),
            Publishers.CombineLatest3(locationsTracker.userLocationPublisher, flightPlanEdition.currentFlightPlanPublisher, currentMapModePublisher)
        ).sink { [unowned self] in
                let ((droneLocation, droneGpsFixed, alwaysCenterOnDrone),
                     (userLocation, currentFlightPlanEdition, currentMapMode)) = $0
                centerStateSubject.value = centerState(droneLocation: droneLocation,
                                                       userLocation: userLocation,
                                                       droneGpsFixed: droneGpsFixed,
                                                       alwaysCenterOnDrone: alwaysCenterOnDrone,
                                                       currentFlightPlanEdition: currentFlightPlanEdition,
                                                       currentMapMode: currentMapMode)
            }
            .store(in: &cancellables)
    }
}

// MARK: Private functions
private extension MapViewModel {
    func centerState(droneLocation: OrientedLocation,
                     userLocation: OrientedLocation,
                     droneGpsFixed: Bool,
                     alwaysCenterOnDrone: Bool,
                     currentFlightPlanEdition: FlightPlanModel?,
                     currentMapMode: MapMode) -> MapCenterState {

        var isFlying: Bool = false
        if let drone = self.connectedDroneHolder.drone, drone.isFlying {
            isFlying = drone.isFlying
        }
        if currentMapMode == .flightPlanEdition || currentMapMode == .flightPlan,
           currentFlightPlanEdition != nil, !isFlying {
            return .project
        } else if droneLocation.isValid, droneGpsFixed || alwaysCenterOnDrone {
            return .drone
        } else if userLocation.isValid {
            return .user
        } else if droneLocation.isValid {
            return .drone
        } else {
            return .none
        }
    }
}

// MARK: Internal functions
extension MapViewModel {
    var droneConnectionState: Bool {
        return droneConnectionStateSubject.value
    }

    var droneConnectionStatePublisher: AnyPublisher<Bool, Never> {
        droneConnectionStateSubject.eraseToAnyPublisher()
    }

    /// Force / stop force hidding center button
    /// - Parameter forceHide: whether hidding should be forced
    func forceHideCenterButton(_ forceHide: Bool) {
        forceHideCenterButton = forceHide
    }

    /// Disable / enable auto center
    /// - Parameter disableAutoCenter: whether auto center should be disabled
    func disableAutoCenter(_ disableAutoCenter: Bool) {
        autoCenterDisabledSubject.value = disableAutoCenter
    }

    /// Always / don't center on drone location
    /// - Parameter alwaysCenterOnDrone: whether the map should center on drone location
    func alwaysCenterOnDroneLocation(_ alwaysCenterOnDrone: Bool) {
        alwaysCenterOnDroneLocation = alwaysCenterOnDrone
    }
}
