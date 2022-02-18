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
import SwiftyUserDefaults

private extension ULogTag {
    static let tag = ULogTag(name: "DroneActionVM")
}

// MARK: - DroneActionState
/// State for `DroneActionViewModel`.
final class DroneActionState: DeviceConnectionState {
    // MARK: - Internal Properties
    fileprivate(set) var buttonImage: UIImage?
    fileprivate(set) var backgroundColor: UIColor?
    fileprivate(set) var isRthAvailable: Bool = false
    fileprivate(set) var isTakeOffButtonEnabled: Bool = false
    fileprivate(set) var shouldHideActionButton: Bool = false

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Constructor.
    ///
    /// - Parameters:
    ///    - connectionState: drone connection state
    ///    - buttonImage: current button image
    ///    - backgroundColor: button background color
    ///    - isRthAvailable: Return To Home availability
    ///    - isTakeOffButtonEnabled: tells if the drone can take off or land
    ///    - shouldHideTakeOffButton: tells if takeOff button need to be displayed
    init(connectionState: DeviceState.ConnectionState,
         buttonImage: UIImage?,
         backgroundColor: UIColor?,
         isRthAvailable: Bool,
         isTakeOffButtonEnabled: Bool,
         shouldHideTakeOffButton: Bool) {
        super.init(connectionState: connectionState)

        self.buttonImage = buttonImage
        self.backgroundColor = backgroundColor
        self.isRthAvailable = isRthAvailable
        self.isTakeOffButtonEnabled = isTakeOffButtonEnabled
        self.shouldHideActionButton = shouldHideTakeOffButton
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? DroneActionState else { return false }

        return super.isEqual(to: other)
            && buttonImage == other.buttonImage
            && backgroundColor == other.backgroundColor
            && isRthAvailable == other.isRthAvailable
            && isTakeOffButtonEnabled == other.isTakeOffButtonEnabled
            && shouldHideActionButton == other.shouldHideActionButton
    }

    override func copy() -> DroneActionState {
        let copy = DroneActionState(connectionState: connectionState,
                                    buttonImage: buttonImage,
                                    backgroundColor: backgroundColor,
                                    isRthAvailable: isRthAvailable,
                                    isTakeOffButtonEnabled: isTakeOffButtonEnabled,
                                    shouldHideTakeOffButton: shouldHideActionButton)

        return copy
    }
}

/// ViewModel for Drone action, notifies buttons about flying state and Return Home reachability.
final class DroneActionViewModel: DroneStateViewModel<DroneActionState> {
    // MARK: - Private Properties
    private var manualPilotingRef: Ref<ManualCopterPilotingItf>?
    private var returnHomePilotingRef: Ref<ReturnHomePilotingItf>?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?
    private var handDetectedAlertObserver: Any?

    // MARK: - Init
    override init() {
        super.init()

        listenHandDetectedAlertPresented()
    }

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.remove(observer: handDetectedAlertObserver)
        handDetectedAlertObserver = nil
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)

        listenFlyingIndicators(drone: drone)
        listenReturnHome(drone: drone)
        listenManualPiloting(drone: drone)
    }

    override func droneConnectionStateDidChange() {
        super.droneConnectionStateDidChange()

        updateButtonState()
    }
}

// MARK: - Internal Funcs
extension DroneActionViewModel {
    /// Start action when user touch the action button.
    func startAction() {
        guard let drone = drone else { return }

        // post a notification about take off request;
        // in case of unavailability, we need to display again dismissed alerts
        NotificationCenter.default.post(name: .takeOffRequestedDidChange,
                                        object: nil,
                                        userInfo: [HUDCriticalAlertConstants.takeOffRequestedNotificationKey: true])

        // starts drone action only if the drone can take off or is currently flying
        if Services.hub.ui.criticalAlert.canTakeOff
            || drone.getInstrument(Instruments.flyingIndicators)?.state == .flying {
            takeOffOrLandDrone()
        }
    }

    /// Starts action when user touch the Return Home button.
    func startReturnToHome() {
        switch drone?.getPilotingItf(PilotingItfs.returnHome)?.state {
        case .active:
            ULog.i(.tag, "RTH pressed: cancel RTH")
            _ = drone?.cancelReturnHome()
        case .idle:
            ULog.i(.tag, "RTH pressed: start RTH")
            _ = drone?.performReturnHome()
        default:
            ULog.w(.tag, "RTH pressed: do nothing")
        }
    }
}

// MARK: - Private Funcs
private extension DroneActionViewModel {
    /// Starts watcher for hand land and hand launch alert notifications.
    func listenHandDetectedAlertPresented() {
        handDetectedAlertObserver = NotificationCenter.default.addObserver(
            forName: .handDetectedAlertModalPresentDidChange,
            object: nil,
            queue: nil) { [weak self] notification in
            guard let shouldHide = notification.userInfo?[HUDPanelNotifications.handDetectedNotificationKey] as? Bool else {
                return
            }

            let copy = self?.state.value.copy()
            copy?.shouldHideActionButton = shouldHide
            self?.state.set(copy)
        }
    }

    /// Starts watcher for manual piloting.
    func listenManualPiloting(drone: Drone) {
        manualPilotingRef = drone.getPilotingItf(PilotingItfs.manualCopter) { [unowned self] _ in
            updateButtonState()
            updateRthAvailability()
        }
    }

    /// Starts watcher for flying indicators.
    func listenFlyingIndicators(drone: Drone) {
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [unowned self] _ in
            updateButtonState()
        }
    }

    /// Starts watcher for Return Home.
    func listenReturnHome(drone: Drone) {
        returnHomePilotingRef = drone.getPilotingItf(PilotingItfs.returnHome) { [unowned self] _ in
            updateButtonState()
            updateRthAvailability()
        }
    }

    /// Activates manual piloting (stop Rth if needed).
    func activateManualPiloting() {
        guard let drone = drone else { return }

        // deactivate RTH if it is the current pilotingItf
        if drone.isReturningHome {
            _ = drone.cancelReturnHome()
        } else {
            _ = drone.activateManualPiloting()
        }
    }

    /// Updates button according to current drone state.
    func updateButtonState() {
        let copy = state.value.copy()
        guard let drone = drone else {
            copy.buttonImage = Asset.DroneAction.icTakeOffIndicator.image
            copy.backgroundColor = UIColor(named: .takeoffIndicatorColor)
            state.set(copy)
            return
        }

        if drone.isLandedOrDisconnected {
            copy.buttonImage = Asset.DroneAction.icTakeOffIndicator.image
            copy.backgroundColor = UIColor(named: .takeoffIndicatorColor)
        } else {
            copy.buttonImage = Asset.DroneAction.icLandIndicator.image
            copy.backgroundColor = UIColor(named: .landingIndicatorColor)
        }

        state.set(copy)
    }

    /// Updates RTH availability regarding its state.
    func updateRthAvailability() {
        let copy = state.value.copy()
        copy.isRthAvailable = returnHomePilotingRef?.value?.state != .unavailable

        if let manualState = manualPilotingRef?.value {
            copy.isTakeOffButtonEnabled = manualState.canTakeOff || manualState.canLand
        }

        state.set(copy)
    }

    /// Starts take off or landing action.
    func takeOffOrLandDrone() {
        guard let drone = drone,
              let manualPilotingItf = drone.getPilotingItf(PilotingItfs.manualCopter) else {
                  return
              }

        if !drone.isManualPilotingActive {
            activateManualPiloting()
        }

        switch manualPilotingItf.smartTakeOffLandAction {
        case .thrownTakeOff:
            if Services.hub.drone.handLaunchService.canStart {
                manualPilotingItf.thrownTakeOff()
            } else {
                manualPilotingItf.takeOff()
            }
        case .takeOff:
            manualPilotingItf.takeOff()
        case .land:
            manualPilotingItf.land()
        default:
            break
        }
    }
}
