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

    /// The RTH active state.
    private var isActiveSubject = CurrentValueSubject<Bool, Never>(false)
    /// The RTH min altitude
    private var minAltitudeSubject = CurrentValueSubject<Double, Never>(RthPreset.minAltitude)
    /// The RTH target.
    private var currentTargetSubject = CurrentValueSubject<ReturnHomeTarget, Never>(RthPreset.rthType)
    /// The banner alert manager service.
    private var bamService: BannerAlertManagerService

    // MARK: init

    /// Constructor.
    ///
    /// - Parameters:
    ///   - currentDroneHolder: drone holder
    ///   - bamService: the banner alert manager service
    public init(currentDroneHolder: CurrentDroneHolder,
                bamService: BannerAlertManagerService) {
        self.bamService = bamService
        // listen to drone changes
        listen(dronePublisher: currentDroneHolder.dronePublisher)
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
        // Show potentiel RTH banner alert according to RTH reason.
        let isIcedPropellerRth = isReturningHome && returnHome?.reason == .icedPropeller
        let isPoorBatteryConnectionRth = isReturningHome && returnHome?.reason == .batteryPoorConnection
        bamService.update(CriticalBannerAlert.rthIcedPropeller, show: isIcedPropellerRth)
        bamService.update(CriticalBannerAlert.rthPoorBatteryConnection, show: isPoorBatteryConnectionRth)
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
}
