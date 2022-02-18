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
    /// Current drone connection state
    private var droneConnectionStateSubject = CurrentValueSubject<Bool, Never>(false)

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
        case .none:
            return nil
        }
    }
    /// Terrain elevation source.
    public var elevationSource = MapElevationSource()

    // MARK: Init

    /// Init
    /// - Parameters:
    ///  - locationsTracker: the locations tracker
    ///  - currentDroneHolder: the current drone holder
    ///  - networkService: the network service
    init(locationsTracker: LocationsTracker, connectedDroneHolder: ConnectedDroneHolder, networkService: NetworkService) {
        self.locationsTracker = locationsTracker
        self.connectedDroneHolder = connectedDroneHolder
        self.networkService = networkService
        locationsTracker.droneLocationPublisher
            .combineLatest(locationsTracker.droneGpsFixedPublisher, $alwaysCenterOnDroneLocation, locationsTracker.userLocationPublisher)
            .sink { [unowned self] in
                let (droneLocation, droneGpsFixed, alwaysCenterOnDrone, userLocation) = $0
                centerStateSubject.value = centerState(droneLocation: droneLocation,
                                                       userLocation: userLocation,
                                                       droneGpsFixed: droneGpsFixed,
                                                       alwaysCenterOnDrone: alwaysCenterOnDrone)
            }
            .store(in: &cancellables)

        connectedDroneHolder.dronePublisher
            .sink { [unowned self] in
                droneConnectionStateSubject.value = $0 != nil
            }
            .store(in: &cancellables)
    }
}

// MARK: Private functions
private extension MapViewModel {
    func centerState(droneLocation: OrientedLocation,
                     userLocation: OrientedLocation,
                     droneGpsFixed: Bool,
                     alwaysCenterOnDrone: Bool) -> MapCenterState {
        if droneLocation.isValid, droneGpsFixed || alwaysCenterOnDrone {
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
