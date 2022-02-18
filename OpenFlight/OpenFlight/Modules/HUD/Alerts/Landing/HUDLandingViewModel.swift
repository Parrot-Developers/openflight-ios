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
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?

    private var connectedDroneHolder = Services.hub.connectedDroneHolder
    private var cancellables = Set<AnyCancellable>()

    private(set) var isReturnHomeActive = CurrentValueSubject<Bool, Never>(false)
    private(set) var isLanding = CurrentValueSubject<Bool, Never>(false)

    /// Drone current landed state.
    private var landedState: FlyingIndicatorsLandedState = .none

    var isLandingOrRth: Bool {
        isReturnHomeActive.value || isLanding.value
    }

    var isReturHomeActiveValue: Bool {
        isReturnHomeActive.value
    }

    var image: AnyPublisher<UIImage?, Never> {
        isReturnHomeActive
            .removeDuplicates()
            .combineLatest(isLanding.removeDuplicates())
            .map { (isReturnHomeActive, isLanding) in
                if isLanding {
                    return Asset.Common.Icons.landing.image
                }
                if isReturnHomeActive {
                    return Asset.Alertes.Rth.icRthHUD.image
                }
                return nil
            }
            .eraseToAnyPublisher()
    }

    init() {
        connectedDroneHolder.dronePublisher
            .compactMap { $0 }
            .sink { [unowned self] drone in
                listenDrone(drone: drone)
            }
            .store(in: &cancellables)
    }

}

// MARK: - Private Funcs
private extension HUDLandingViewModel {

    func listenDrone(drone: Drone) {
        listenFlyingIndicators(drone: drone)
        listenReturnHome(drone: drone)
    }

    /// Starts watcher for flying indicators.
    func listenFlyingIndicators(drone: Drone) {
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [unowned self] flyingIndicators in
            updateLandingState(flyingIndicators: flyingIndicators)
        }
    }

    /// Starts watcher for Return Home.
    func listenReturnHome(drone: Drone) {
        returnHomeRef = drone.getPilotingItf(PilotingItfs.returnHome) { [unowned self] _ in
            updateReturnHomeState(drone: drone)
        }
        updateReturnHomeState(drone: drone)
    }

    /// Updates return home state.
    func updateReturnHomeState(drone: Drone) {
        ULog.i(.tag, "updateReturnHomeState isReturningHome: \(drone.isReturningHome) isForceLandingInProgress: \(drone.isForceLandingInProgress)")
        // Bypass `drone.isReturningHome` value if a force landing is in progress.
        isReturnHomeActive.value = drone.isReturningHome && !drone.isForceLandingInProgress
    }

    /// Updates landing state.
    func updateLandingState(flyingIndicators: FlyingIndicators?) {
        // ignore landing state if previous state was hand launch
        isLanding.value = flyingIndicators?.flyingState == .landing && landedState != .waitingUserAction
        landedState = flyingIndicators?.landedState ?? .none
    }
}
