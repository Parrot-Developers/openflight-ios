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

/// ViewModel for `ReturnHomeGraphicsOverlay`
public class ReturnHomeGraphicsOverlayViewModel {
    // MARK: Private Properties
    private let flightPlanRunManager = Services.hub.flightPlan.run
    private let rthService: RthService = Services.hub.drone.rthService
    private let locationsTracker: LocationsTracker = Services.hub.locationsTracker
    private var currentTargetPublisher: AnyPublisher<ReturnHomeTarget, Never> { rthService.currentTargetPublisher
    }
    private var takeOffLocationPublisher: AnyPublisher<CLLocationCoordinate2D?, Never> { locationsTracker.returnHomeLocationPublisher }
    private var userLocationPublisher: AnyPublisher<OrientedLocation, Never> { locationsTracker.userLocationPublisher }
    /// Combine cancellables
    private var cancellables = Set<AnyCancellable>()

    // MARK: Published properties
    @Published private(set) var isActive: Bool = false
    @Published private(set) var homeLocation: Location3D?
    // MARK: Public Properties
    public var droneLocationPublisher: AnyPublisher<OrientedLocation, Never> {
        locationsTracker.droneLocationPublisher.eraseToAnyPublisher()
    }
    public var droneLocation: OrientedLocation {
        locationsTracker.droneLocation
    }
    public var droneAbsoluteLocation: OrientedLocation {
        locationsTracker.droneAbsoluteLocation
    }
    public var minAltitude: Double {
        rthService.minAltitude
    }

    init() {
        listenLocations()
        listenRth()
    }

    /// Updates the return target.
    ///
    /// Sets the target location according to `rthService` information.
    func listenLocations() {
        rthService.homeLocationPublisher
            .sink { [weak self] homeLocation in
                self?.homeLocation = homeLocation
            }
            .store(in: &cancellables)
    }

    /// Updates the RTH state.
    ///
    /// Sets active state based on events from the RTH service and the flight plan run manager.
    private func listenRth() {
        rthService.isActivePublisher
            .combineLatest(flightPlanRunManager.statePublisher, locationsTracker.droneGpsFixedPublisher)
            .sink { [weak self] isActive, runManagerState, isDroneGpsFixed in
                var isFlightPlanRthActive: Bool
                guard let self = self else { return }
                switch runManagerState {
                case let .playing(droneConnected: _, flightPlan: _, rth: rth):
                    isFlightPlanRthActive = rth
                case .rth(flightPlan: _):
                    isFlightPlanRthActive = true
                default:
                    isFlightPlanRthActive = false
                }
                self.isActive = (isActive || isFlightPlanRthActive) && isDroneGpsFixed
            }
            .store(in: &cancellables)
    }
}
