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
    static let tag = ULogTag(name: "HandLaunchService")
}

/// Drone hand launch service.
public protocol HandLaunchService: AnyObject {
    /// Publisher telling whether hand launch can be started.
    var canStartPublisher: AnyPublisher<Bool, Never> { get }
    /// Whether hand launch can be started.
    var canStart: Bool { get }
    /// Publisher telling whether hand launch is disabled by user.
    var isDisabledByUserPublisher: AnyPublisher<Bool, Never> { get }
    /// Whether hand launch is disabled by user.
    var isDisabledByUser: Bool { get }
    /// Disables hand launch until drone is landed again on a stable surface.
    func disabledByUser()
    /// Updates the takeOffButtonPressed value
    ///  - Parameter buttonPressed: If the button was pressed
    func updateTakeOffButtonPressed(_ buttonPressed: Bool)
}

/// Implementation of `HandLaunchService`.
public class HandLaunchServiceImpl {

    // MARK: Private properties

    /// Reference to flying indicators instrument.
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?
    /// Reference to manual piloting interface.
    private var manualPilotingRef: Ref<ManualCopterPilotingItf>?
    /// Current drone holder.
    private var currentDroneHolder: CurrentDroneHolder
    /// Subject telling whether hand launch can be started.
    private var canStartSubject = CurrentValueSubject<Bool, Never>(false)
    /// Whether hand launch has been disabled by user. Turned to `false` when the drone is landed on a stable surface.
    private var isDisabledByUserSubject = CurrentValueSubject<Bool, Never>(false)
    /// Reset pressed button timer
    private var resetPressedButtonTimer: Timer?
    /// Whether the take off button has been pressed
    private var takeOffButtonPressed = false
    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Constants
    enum Constants {
        static let resetButtonPressedTimer = TimeInterval(10)
    }

    // MARK: init

    /// Constructor.
    ///
    /// - Parameters:
    ///   - currentDroneHolder: drone holder
    public init(currentDroneHolder: CurrentDroneHolder) {
        self.currentDroneHolder = currentDroneHolder
        // listen to drone changes
        listen(dronePublisher: currentDroneHolder.dronePublisher)

        canStartPublisher.sink { canStart in
            ULog.i(.tag, "Can start hand launch: \(canStart)")
        }
        .store(in: &cancellables)

        isDisabledByUserPublisher.sink { isDisabledByUser in
            ULog.i(.tag, "Hand launch disabled: \(isDisabledByUser)")
        }
        .store(in: &cancellables)
    }
}

// MARK: Private functions
private extension HandLaunchServiceImpl {

    /// Listens for the current drone.
    ///
    /// - Parameters:
    ///    - dronePublisher: the drone publisher
    func listen(dronePublisher: AnyPublisher<Drone, Never>) {
        dronePublisher.sink { [unowned self] in
            listenFlyingIndicators(drone: $0)
            listenManualPiloting(drone: $0)
            checkConnectionState(drone: $0)
        }
        .store(in: &cancellables)
    }

    /// Starts watcher for flying indicators.
    ///
    /// - Parameters:
    ///    - drone: the current drone.
    func listenFlyingIndicators(drone: Drone) {
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [unowned self] flyingIndicator in
            if flyingIndicator?.flyingState == .flying && takeOffButtonPressed || flyingIndicator?.state == .landed {
                updateTakeOffButtonPressed(false)
            }

            updateDisabledState()
            updateCanStart()
        }
    }

    /// Starts watcher for manual piloting interface.
    ///
    /// - Parameters:
    ///    - drone: the current drone.
    func listenManualPiloting(drone: Drone) {
        manualPilotingRef = drone.getPilotingItf(PilotingItfs.manualCopter) { [unowned self] _ in
            updateDisabledState()
            updateCanStart()
        }
    }

    /// Checks the connection state.
    ///
    /// - Parameters:
    ///    - drone: the current drone.
    func checkConnectionState(drone: Drone) {
        if !drone.isConnected && takeOffButtonPressed {
            updateTakeOffButtonPressed(false)
        }
    }

    /// Updates disabled state.
    ///
    /// When the user dismisses the hand launch alert, hand launch is disabled.
    /// It is enabled again when the drone is landed on a stable surface.
    func updateDisabledState() {
        let drone = currentDroneHolder.drone
        let manualPilotingItf = drone.getPilotingItf(PilotingItfs.manualCopter)
        if drone.isStateLanded,
           manualPilotingItf?.smartTakeOffLandAction != .thrownTakeOff {
            isDisabledByUserSubject.value = false
        }
    }

    /// Updates hand launch sart availability.
    func updateCanStart() {
        let drone = currentDroneHolder.drone
        canStartSubject.value = !isDisabledByUserSubject.value && drone.isHandLaunchAvailable && !takeOffButtonPressed
    }
}

// MARK: HandLaunchService protocol conformance
extension HandLaunchServiceImpl: HandLaunchService {

    public var canStartPublisher: AnyPublisher<Bool, Never> { canStartSubject.eraseToAnyPublisher() }

    public var isDisabledByUserPublisher: AnyPublisher<Bool, Never> {
        isDisabledByUserSubject.eraseToAnyPublisher()
    }

    public var canStart: Bool { canStartSubject.value }

    public var isDisabledByUser: Bool { isDisabledByUserSubject.value }

    public func disabledByUser() {
        isDisabledByUserSubject.value = true
        updateCanStart()
    }

    public func updateTakeOffButtonPressed(_ buttonPressed: Bool) {
        resetPressedButtonTimer?.invalidate()
        resetPressedButtonTimer = nil
        takeOffButtonPressed = buttonPressed
        if buttonPressed {
            resetPressedButtonTimer = Timer.scheduledTimer(withTimeInterval: Constants.resetButtonPressedTimer, repeats: false) { [unowned self] _ in
                takeOffButtonPressed = false
            }
        }
    }
}
