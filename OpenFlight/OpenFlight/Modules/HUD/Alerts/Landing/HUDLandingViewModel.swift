//    Copyright (C) 2020 Parrot Drones SAS
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

import GroundSdk
import Combine

private extension ULogTag {
    static let tag = ULogTag(name: "HUDLandingVM")
}

/// View model which observes landing state.
final class HUDLandingViewModel {

    // MARK: - Private Properties
    private var returnHomeRef: Ref<ReturnHomePilotingItf>?
    private var returnHome: ReturnHomePilotingItf?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?
    private var flyingIndicators: FlyingIndicators?
    private var alarmsRef: Ref<Alarms>?
    private var alarms: Alarms?

    private var connectedDroneHolder = Services.hub.connectedDroneHolder
    private var runManager = Services.hub.flightPlan.run
    private var cancellables = Set<AnyCancellable>()

    private(set) var isLanding = CurrentValueSubject<Bool, Never>(false)
    private(set) var isBasicRthActive = CurrentValueSubject<Bool, Never>(false)
    private(set) var isFlightPlanRthActive = CurrentValueSubject<Bool, Never>(false)

    // A PassthroughSubject publishing an image when a forced update is needed.
    var forceImageUpdateSubject = PassthroughSubject<UIImage?, Never>()

    var isReturnHomeActive: AnyPublisher<Bool, Never> {
        isBasicRthActive
            .combineLatest(isFlightPlanRthActive)
            .map { basicRth, flightPlanRth in
                basicRth || flightPlanRth
            }
            .eraseToAnyPublisher()
    }

    /// Drone current landed state.
    private var landedState: FlyingIndicatorsLandedState = .none

    var isLandingOrRth: Bool {
        isReturnHomeActiveValue || isLanding.value
    }

    var isReturnHomeActiveValue: Bool {
        isBasicRthActive.value || isFlightPlanRthActive.value
    }

    var image: AnyPublisher<UIImage?, Never> {
        isReturnHomeActive
            .removeDuplicates()
            .combineLatest(isLanding.removeDuplicates())
            .map { [weak self] _ in self?.currentImage }
            .eraseToAnyPublisher()
    }

    init() {
        connectedDroneHolder.dronePublisher
            .compactMap { $0 }
            .sink { [weak self] drone in
                self?.listenDrone(drone: drone)
            }
            .store(in: &cancellables)
        listenAppState()
    }

}

// MARK: - Private Funcs
private extension HUDLandingViewModel {

    /// Starts watcher for current drone.
    ///
    ///  - Parameters:
    ///     - drone: current drone
    func listenDrone(drone: Drone) {
        listenFlyingIndicators(drone: drone)
        listenReturnHome(drone: drone)
        listenAlarms(drone: drone)
        listenFlightPlanReturnHome(runManager: runManager)
    }

    /// Starts watcher for flying indicators.
    ///
    ///  - Parameters:
    ///     - drone: current drone
    func listenFlyingIndicators(drone: Drone) {
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [weak self] flyingIndicators in
            guard let self = self else { return }
            self.flyingIndicators = flyingIndicators
            self.updateLandingState()
            self.updateReturnHomeState(drone: drone)
        }
    }

    /// Starts watcher for Return Home.
    ///
    ///  - Parameters:
    ///     - drone: current drone
    func listenReturnHome(drone: Drone) {
        returnHomeRef = drone.getPilotingItf(PilotingItfs.returnHome) { [weak self] returnHome in
            guard let self = self else { return }
            self.returnHome = returnHome
            self.updateReturnHomeState(drone: drone)
        }
        updateReturnHomeState(drone: drone)
    }

    /// Starts watcher for alarms.
    ///
    ///  - Parameters:
    ///     - drone: current drone
    func listenAlarms(drone: Drone) {
        alarmsRef = drone.getInstrument(Instruments.alarms) { [weak self] alarms in
            guard let self = self else { return }
            self.alarms = alarms
            self.updateReturnHomeState(drone: drone)
        }
    }

    /// Starts watcher for flight plan Return Home.
    ///
    ///  - Parameters:
    ///     - runManager: current FP run manager
    func listenFlightPlanReturnHome(runManager: FlightPlanRunManager) {
        runManager.statePublisher
            .sink { [weak self] state in
                guard let self = self else { return }
                switch state {
                case let .playing(droneConnected: _, flightPlan: _, rth: rth):
                    self.isFlightPlanRthActive.send(rth)
                case .rth:
                    self.isFlightPlanRthActive.send(true)
                default:
                    self.isFlightPlanRthActive.send(false)
                }
            }
            .store(in: &cancellables)
    }

    /// Listens the App State to force image update when coming from background.
    func listenAppState() {
        UIApplication.statePublisher
            .sink { [weak self] in
                guard $0 == .didBecomeActive else { return }
                self?.forceImageUpdateSubject.send(self?.currentImage)
            }
            .store(in: &cancellables)
    }

    /// Updates return home state.
    ///
    ///  - Parameters:
    ///     - drone: current drone
    func updateReturnHomeState(drone: Drone) {
        let isForceLanding = drone.isForceLanding(alarms: self.alarms, flyingIndicators: self.flyingIndicators)
        let isReturningHome = returnHome?.state == .active && returnHome?.suspended == false
        ULog.i(.tag, "updateReturnHomeState isReturningHome: \(isReturningHome) isForceLandingInProgress: \(isForceLanding)")
        // Bypass `drone.isReturningHome` value if a force landing is in progress.
        isBasicRthActive.value = isReturningHome && !isForceLanding
    }

    /// Updates landing state.
    func updateLandingState() {
        // ignore landing state if previous state was hand launch
        isLanding.value = flyingIndicators?.flyingState == .landing && landedState != .waitingUserAction
        landedState = flyingIndicators?.landedState ?? .none
    }

    /// The image to display according to the current state.
    var currentImage: UIImage? {
        guard isLandingOrRth else { return nil }
        return isLanding.value ? Asset.Common.Icons.landing.image
        : Asset.Alertes.Rth.icRthHUD.image
    }
}
