//
//  Copyright (C) 2021 Parrot Drones SAS.
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
import GroundSdk

/// Joysticks availability service
public protocol JoysticksAvailabilityService: AnyObject {

    /// Publisher for joysticks availability
    var joysticksAvailablePublisher: AnyPublisher<Bool, Never> { get }
    /// Joysticks availability
    var joysticksAvailable: Bool { get }

    /// Publisher for joysticks visibility
    var showJoysticksPublisher: AnyPublisher<Bool, Never> { get }
    /// Joysticks visibility
    var showJoysticks: Bool { get }
    /// Setter for joysticks visibility. Will be takend into account only when possible, reset at each mission change.
    func setJoysticksVisibility(_ show: Bool)
}

/// Implementation for `JoysticksAvailabilityService`
class JoysticksAvailabilityServiceImpl {

    private var cancellables = Set<AnyCancellable>()
    private var areJoysticksAvailableSubject = CurrentValueSubject<Bool, Never>(false)
    private var showJoysticksSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private var userWantsJoysticksVisible: Bool?

    init(currentMissionManager: CurrentMissionManager,
         connectedDroneHolder: ConnectedDroneHolder,
         connectedRemoteControlHolder: ConnectedRemoteControlHolder) {
        // Listen to everything
        listenMission(currentMissionManager: currentMissionManager)
        listen(connectedDroneHolder: connectedDroneHolder,
               connectedRemoteControlholder: connectedRemoteControlHolder)
    }

}

private extension JoysticksAvailabilityServiceImpl {

    /// Compute joysticks availability based on drone and remote control connections
    /// (available when drone connected and no RC connected)
    ///
    /// - Parameters:
    ///   - connectedDroneHolder: the connected drone holder
    ///   - connectedRemoteControlholder: the connected remote holder
    func listen(connectedDroneHolder: ConnectedDroneHolder, connectedRemoteControlholder: ConnectedRemoteControlHolder) {
        let droneIsConnectedPublisher = connectedDroneHolder.dronePublisher.map({ $0 != nil })
        let rcIsConnectedPublisher = connectedRemoteControlholder.remoteControlPublisher.map({ $0 != nil })
        droneIsConnectedPublisher
            .combineLatest(rcIsConnectedPublisher)
            .sink { [unowned self ] (isDroneConnected, isRcConnected) in
                areJoysticksAvailableSubject.value = isDroneConnected && !isRcConnected
            }
            .store(in: &cancellables)
    }

    /// Compute joysticks visibility based on current mission and user preferrence. Resets user preferrence on mission change.
    /// - Parameter currentMissionManager: the current mission manager
    func listenMission(currentMissionManager: CurrentMissionManager) {
        currentMissionManager.modePublisher
            .map({ [unowned self] (mode: MissionMode) -> MissionMode in
                // Reset user preferrence on mission change
                userWantsJoysticksVisible = nil
                return mode
            })
            .combineLatest(joysticksAvailablePublisher, $userWantsJoysticksVisible)
            .sink { [unowned self] (mode, joysticksAvailable, userWantsJoysticksVisible) in
                // When the user asks for it, prefer displaying the joysticks.
                // Else display them by default only for classic mission (piloted flight)
                let preferrence = userWantsJoysticksVisible ?? (mode.key == ClassicMission.manualMode.key)
                showJoysticksSubject.value = joysticksAvailable && preferrence
            }
            .store(in: &cancellables)
    }
}

/// `JoysticksAvailabilityService` conformance
extension JoysticksAvailabilityServiceImpl: JoysticksAvailabilityService {

    var joysticksAvailable: Bool { areJoysticksAvailableSubject.value }
    var joysticksAvailablePublisher: AnyPublisher<Bool, Never> { areJoysticksAvailableSubject.eraseToAnyPublisher() }
    var showJoysticks: Bool { showJoysticksSubject.value }
    var showJoysticksPublisher: AnyPublisher<Bool, Never> { showJoysticksSubject.eraseToAnyPublisher() }

    func setJoysticksVisibility(_ show: Bool) {
        userWantsJoysticksVisible = show
    }
}
