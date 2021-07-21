//
//  Copyright (C) 2020 Parrot Drones SAS.
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

/// State for `HUDAlertPanelHandLaunchViewModel`.
public final class HUDAlertPanelHandLandState: DeviceConnectionState, AlertPanelState {
    // MARK: - AlertPanelState Properties
    public var title: String? {
        return L10n.commonHandland
    }
    public var subtitle: String? {
        switch state {
        case .available:
            return L10n.commonAvailable
        case .started:
            return L10n.alertHandLandLanding
        default:
            return nil
        }
    }
    public var subtitleColor: UIColor? {
        switch state {
        case .started:
            return ColorName.greenSpring.color
        case .available:
            return ColorName.blueDodger.color
        default:
            return ColorName.white.color
        }
    }
    public var icon: UIImage? {
        switch state {
        case .started:
            return Asset.Alertes.HandLand.icHandLand.image
        case .available:
            return Asset.Alertes.icPanelActionButton.image
        default:
            return nil
        }
    }
    public var animationImages: [UIImage]? {
        return Asset.Alertes.HandLand.Animation.allValues.compactMap { $0.image }
    }
    public var state: AlertPanelCurrentState? = .none
    public var isAlertForceHidden: Bool = true
    public var countdown: Int?
    public var startViewIsVisible: Bool {
        return false
    }
    public var actionLabelIsVisible: Bool {
        return state == .available
    }
    public var actionLabelText: String? {
        return L10n.commonStart
    }
    public var rthAlertType: RthAlertType?
    public var stopViewStyle: StopViewStyle? {
        return state == .started ? .classic : .cancelAlert
    }
    /// Should be shown if it is available and if it is not in force hidden state.
    public var shouldShowAlertPanel: Bool {
        return false
    }
    public var hasAnimation: Bool {
        return false
    }
    public var hasProgressView: Bool {
        return false
    }
    public var countdownMessage: ((Int) -> String)? {
        return nil
    }

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - connectionState: drone connection state
    ///    - state: Hand Land state
    ///    - isAlertForceHidden: Hand Land force hide parameter
    ///    - countdown: countdown
    init(connectionState: DeviceState.ConnectionState,
         state: AlertPanelCurrentState?,
         isAlertForceHidden: Bool,
         countdown: Int?) {
        super.init(connectionState: connectionState)

        self.state = state
        self.isAlertForceHidden = isAlertForceHidden
        self.countdown = countdown
    }

    // MARK: - Override Funcs
    public override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? HUDAlertPanelHandLandState else { return false }

        return super.isEqual(to: other)
            && self.state == other.state
            && self.isAlertForceHidden == other.isAlertForceHidden
            && self.countdown == other.countdown
    }

    public override func copy() -> HUDAlertPanelHandLandState {
        return HUDAlertPanelHandLandState(connectionState: self.connectionState,
                                          state: self.state,
                                          isAlertForceHidden: self.isAlertForceHidden,
                                          countdown: self.countdown)
    }
}

/// View model for Hand Land alert.

final class HUDAlertPanelHandLandViewModel: DroneStateViewModel<HUDAlertPanelHandLandState> {
    // MARK: - Private Properties
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?
    private var manualPilotingRef: Ref<ManualCopterPilotingItf>?
    private var timer: Timer?
    private var cancelTimer: Timer?

    // MARK: - Private Enums
    private enum Constants {
        static let countDownDuration: Int = 5
        static let countDownInterval: TimeInterval = 1.0
        static let cancelTimerDuration: TimeInterval = 30.0
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)

        listenFlyingIndicators(drone: drone)
        listenManualPiloting(drone: drone)
    }

    override func droneConnectionStateDidChange() {
        // Reset force hidden when drone disconnects.
        if state.value.connectionState == .disconnected {
            let copy = state.value.copy()
            copy.isAlertForceHidden = false
            self.state.set(copy)
        }

        updateHandLandAvailability()
    }

    // MARK: - Deinit
    deinit {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Private Funcs
private extension HUDAlertPanelHandLandViewModel {
    /// Starts watcher for flying indicators.
    func listenFlyingIndicators(drone: Drone) {
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [weak self] _ in
            self?.updateHandLandAvailability()
        }
    }

    /// Starts watcher for manual piloting.
    func listenManualPiloting(drone: Drone) {
        manualPilotingRef = drone.getPilotingItf(PilotingItfs.manualCopter) { [weak self] _ in
            self?.updateHandLandAvailability()
        }
    }

    /// Update current Hand Land availability.
    func updateHandLandAvailability() {
        let copy = state.value.copy()
        guard let drone = drone else {
            copy.state = .none
            state.set(copy)
            return
        }

        if drone.canHandLand,
           drone.isStateFlying,
           copy.state != .started {
            copy.state = .available
        } else if drone.isStateLanded || copy.countdown == 0 {
            copy.state = .none
        } else if copy.state == .started && !drone.isStateLanded {
            return
        } else {
            copy.state = .unavailable
        }

        state.set(copy)
    }

    /// Starts Hand Hand.
    func startDroneHandLand() {
        drone?.startHandLand()
        let copy = state.value.copy()
        copy.state = .started
        state.set(copy)
        startHandLandCountdown()
    }

    /// Cancels Hand Land.
    func cancelDroneHandLand() {
        guard let drone = drone,
              drone.isLanding else {
            return
        }

        drone.getPilotingItf(PilotingItfs.manualCopter)?.takeOff()
    }

    /// Starts a countdown for hand land.
    /// Used when user starts the handland.
    func startHandLandCountdown() {
        let copy = state.value.copy()
        copy.countdown = Constants.countDownDuration
        state.set(copy)
        timer = Timer.scheduledTimer(withTimeInterval: Constants.countDownInterval, repeats: true, block: { [weak self] _ in
            let copy = self?.state.value.copy()

            if let countDown = copy?.countdown, countDown > 0 {
                copy?.countdown = countDown - Int(Constants.countDownInterval)
            } else {
                copy?.countdown = 0
                self?.updateHandLandAvailability()
                self?.timer?.invalidate()
                self?.timer = nil
            }

            self?.state.set(copy)
        })
    }
}

// MARK: - AlertPanelActionType
extension HUDAlertPanelHandLandViewModel: AlertPanelActionType {
    func startAction() {
        LogEvent.logAppEvent(itemName: LogEvent.LogKeyHUDPanelButton.start.name,
                             newValue: state.value.state?.description,
                             logType: .button)
        guard state.value.state == .available else { return }

        startDroneHandLand()
    }

    func cancelAction() {
        LogEvent.logAppEvent(itemName: LogEvent.LogKeyHUDPanelButton.cancel.name,
                             newValue: state.value.state?.description,
                             logType: .button)
        let copy = state.value.copy()
        // Hides the panel if we cancel the action.
        copy.isAlertForceHidden = true
        self.state.set(copy)
        startTimer()
        cancelDroneHandLand()
    }

    func startTimer() {
        cancelTimer = Timer.scheduledTimer(withTimeInterval: Constants.cancelTimerDuration, repeats: false) { _ in
            let copy = self.state.value.copy()
            copy.isAlertForceHidden = false
            self.state.set(copy)
            self.updateHandLandAvailability()
            self.cancelTimer?.invalidate()
            self.cancelTimer = nil
        }
    }
}
