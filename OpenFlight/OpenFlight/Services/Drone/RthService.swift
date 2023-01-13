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
import GroundSdk
import Combine

private extension ULogTag {
    static let tag = ULogTag(name: "RthService")
}

/// RTH service.
public protocol RthService: AnyObject {
    /// Indicates if RTH is currently active
    var isActive: Bool { get }
    /// Publisher for RTH active state.
    var isActivePublisher: AnyPublisher<Bool, Never> { get }
    /// Minimum Altitude for RTH trajectory
    var minAltitude: Double { get }
    /// Publisher for the minimum RTH altitude
    var minAltitudePublisher: AnyPublisher<Double, Never> { get }
    /// Current RTH target
    var currentTarget: ReturnHomeTarget { get }
    /// Publisher for the current RTH target
    var currentTargetPublisher: AnyPublisher<ReturnHomeTarget, Never> { get }
    /// The home location publisher.
    var homeLocationPublisher: AnyPublisher<Location3D?, Never> { get }
    /// The home indicator state publisher.
    var homeIndicatorStatePublisher: AnyPublisher<HomeIndicatorState, Never> { get }
}

/// Implementation of `RthService`.
public class RthServiceImpl {

    // MARK: Private properties

    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()

    /// References to instruments and peripherals.
    private var returnHomeRef: Ref<ReturnHomePilotingItf>?
    private var returnHome: ReturnHomePilotingItf?
    private var alarmsRef: Ref<Alarms>?
    private var alarms: Alarms?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?
    private var flyingIndicators: FlyingIndicators?

    /// Whether home position set alert is required.
    private var isHomePositionSetAlertRequired = false
    /// The RTH active state.
    private var isActiveSubject = CurrentValueSubject<Bool, Never>(false)
    /// The RTH min altitude
    private var minAltitudeSubject = CurrentValueSubject<Double, Never>(RthPreset.minAltitude)
    /// The RTH target.
    private var currentTargetSubject = CurrentValueSubject<ReturnHomeTarget, Never>(RthPreset.rthType)
    /// The home location subject.
    private var homeLocationSubject = CurrentValueSubject<Location3D?, Never>(nil)
    /// The `returnHome` piloting interface home location subject.
    private var rthHomeLocationSubject = CurrentValueSubject<CLLocation?, Never>(nil)
    /// The `returnHome` piloting interface home location publisher.
    private var rthHomeLocationPublisher: AnyPublisher<CLLocation?, Never> { rthHomeLocationSubject.eraseToAnyPublisher() }
    /// The `returnHome` piloting interface home location.
    private var rthHomelocation: CLLocation? {
        get { rthHomeLocationSubject.value }
        set { rthHomeLocationSubject.value = newValue }
    }
    /// The home indicator state subject.
    private var homeIndicatorStateSubject = CurrentValueSubject<HomeIndicatorState, Never>(.active)
    /// The home indicator state.
    private var homeIndicatorState: HomeIndicatorState {
        get { homeIndicatorStateSubject.value }
        set { homeIndicatorStateSubject.value = newValue }
    }

    /// The banner alert manager service.
    private var bamService: BannerAlertManagerService

    // MARK: init

    /// Constructor.
    ///
    /// - Parameters:
    ///   - currentDroneHolder: drone holder
    ///   - locationsTracker: the locations tracker service
    ///   - bamService: the banner alert manager service
    public init(currentDroneHolder: CurrentDroneHolder,
                locationsTracker: LocationsTracker,
                bamService: BannerAlertManagerService) {
        self.bamService = bamService
        // listen to drone changes
        listen(dronePublisher: currentDroneHolder.dronePublisher)

        // Update home location according to `returnHome` piloting interface and locations tracker updates.
        updateHomeLocation(locationsTracker: locationsTracker)
    }
}

// MARK: Private functions
private extension RthServiceImpl {

    /// Listens for the current drone.
    ///
    /// - Parameter dronePublisher: the drone publisher
    func listen(dronePublisher: AnyPublisher<Drone, Never>) {
        dronePublisher.sink { [weak self] drone in
            self?.listenToRth(drone: drone)
            self?.listenAlarms(drone: drone)
            self?.listenFlyingIndicators(drone: drone)
        }
        .store(in: &cancellables)
    }

    /// Listens to drone's RTH state.
    ///
    /// - Parameter drone: drone to monitor
    func listenToRth(drone: Drone) {
        returnHomeRef = drone.getPilotingItf(PilotingItfs.returnHome) { [weak self] returnHome in
            guard let self = self else { return }
            ULog.i(.tag, "updateReturnHomeState isReturningHome: \(drone.isReturningHome) reason: \(returnHome?.reason ?? .none)")
            self.returnHome = returnHome
            self.updateRthState(drone: drone)
        }
    }

    /// Listens alarms instrument.
    ///
    /// - Parameter drone: drone to monitor
    func listenAlarms(drone: Drone) {
        alarmsRef = drone.getInstrument(Instruments.alarms) { [weak self] alarms in
            guard let self = self else { return }
            self.alarms = alarms
            self.updateRthState(drone: drone)
        }
    }

    /// Listens flying indicators intrument.
    ///
    /// - Parameter drone: drone to monitor
    func listenFlyingIndicators(drone: Drone) {
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [weak self] flyingIndicators in
            guard let self = self else { return }
            self.flyingIndicators = flyingIndicators
            self.updateRthState(drone: drone)
        }
    }

    /// Updates the RTH state according to the drone and the piloting interface states.
    ///
    /// - Parameters:
    ///    - drone: the drone
    ///    - returnHome: the RTH piloting interface
    func updateRthState(drone: Drone) {
        let isForceLanding = drone.isForceLanding(alarms: alarms, flyingIndicators: flyingIndicators)
        let isReturningHome = returnHome?.state == .active
        isActiveSubject.value = isReturningHome && !isForceLanding
        minAltitudeSubject.value = returnHome?.minAltitude?.value ?? RthPreset.minAltitude
        currentTargetSubject.value = returnHome?.currentTarget ?? RthPreset.rthType

        // Update home location from `returnHome` piloting interface.
        rthHomelocation = returnHome?.homeLocation

        let reachability = returnHome?.homeReachability ?? .unknown
        let isRthAvailable = returnHome?.unavailabilityReasons?.isEmpty == true
        // Update home indicator state.
        if drone.isTakingOff || !isRthAvailable {
            homeIndicatorState = .hidden
        } else if reachability == .notReachable {
            homeIndicatorState = .error
        } else if currentTarget != .takeOffPosition {
            homeIndicatorState = .active
        } else {
            homeIndicatorState = returnHome?.gpsWasFixedOnTakeOff ?? false ? .active : .degraded
        }

        // Show home position set banner alert if needed.
        let isHomePositionSet = returnHome?.isHomePositionSet == true
        if drone.isTakingOff {
            // New takeoff => home position set alert is required (if available).
            isHomePositionSetAlertRequired = true
        } else if isRthAvailable, isHomePositionSet, isHomePositionSetAlertRequired {
            bamService.show(HomeAlert.homePositionSet)
            // Do not show alert again until next take off.
            isHomePositionSetAlertRequired = false
        }

        // Show potentiel RTH banner alert according to RTH reason.
        let isIcedPropellerRth = isReturningHome && returnHome?.reason == .icedPropeller
        let isPoorBatteryConnectionRth = isReturningHome && returnHome?.reason == .batteryPoorConnection
        bamService.update(CriticalBannerAlert.rthIcedPropeller, show: isIcedPropellerRth)
        bamService.update(CriticalBannerAlert.rthPoorBatteryConnection, show: isPoorBatteryConnectionRth)
    }

    /// Updates home location subject by listening to related publishers.
    ///
    /// This function updates and publishes home location according to `returnHome` piloting interface info, device's
    /// location and user preferrences.
    ///
    /// Home location should however only be determined by `returnHome` piloting interface.
    /// Device's location is currently used to define home location in case of a pilot RTH target because `homeLocation`
    /// field of `returnHome` piloting interface is not correctly updated in case of a `controllerPosition` preferred
    /// return target.
    ///
    /// - Parameter locationsTracker: the locations tracker service
    func updateHomeLocation(locationsTracker: LocationsTracker) {
        rthHomeLocationPublisher.combineLatest(locationsTracker.userLocationPublisher, currentTargetPublisher)
            .sink { [weak self] homeLocation, userLocation, currentTarget in
                guard let self = self else { return }
                if currentTarget == .takeOffPosition, let homeLocation = homeLocation {
                    self.homeLocationSubject.value = Location3D(coordinate: homeLocation.coordinate,
                                                                altitude: 0)
                } else if let userLocation3D = userLocation.coordinates, userLocation.isValid {
                    self.homeLocationSubject.value = Location3D(coordinate: userLocation3D.coordinate,
                                                                altitude: 0)
                } else {
                    self.homeLocationSubject.value = nil
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: RthService protocol conformance
extension RthServiceImpl: RthService {
    public var isActivePublisher: AnyPublisher<Bool, Never> { isActiveSubject.eraseToAnyPublisher() }
    public var isActive: Bool { isActiveSubject.value }
    public var minAltitudePublisher: AnyPublisher<Double, Never> {
        minAltitudeSubject.eraseToAnyPublisher()
    }
    public var minAltitude: Double {
        minAltitudeSubject.value
    }
    public var currentTarget: ReturnHomeTarget {
        currentTargetSubject.value
    }
    public var currentTargetPublisher: AnyPublisher<ReturnHomeTarget, Never> {
        currentTargetSubject.eraseToAnyPublisher()
    }
    /// The home location publisher.
    public var homeLocationPublisher: AnyPublisher<Location3D?, Never> { homeLocationSubject.eraseToAnyPublisher() }
    /// The home indicator state publisher.
    public var homeIndicatorStatePublisher: AnyPublisher<HomeIndicatorState, Never> { homeIndicatorStateSubject.eraseToAnyPublisher() }
}
