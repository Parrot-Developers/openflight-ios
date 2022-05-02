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

import GroundSdk

// TODO: Refactor the whole pro-active alerts (remove ViewModelState / BaseViewModel using)

/// State for `HUDAlertPanelObstacleAvoidanceViewModel`.
public final class HUDAlertPanelObstacleAvoidanceState: DeviceConnectionState, AlertPanelState {
    // MARK: - AlertPanelState Properties
    public var title: String? { L10n.alertOaDroneStuckTitle }
    public var subtitle: String? { L10n.alertOaDroneStuckSubtitle.uppercased() }
    public var titleImage: UIImage?
    public var subtitleColor: UIColor? { ColorName.errorColor.color }
    public var icon: UIImage? { Asset.Alertes.ObstacleAvoidance.icOAAlert.image }
    public var animationImages: [UIImage]?
    public var state: AlertPanelCurrentState? = .none
    public var isAlertForceHidden: Bool = false
    public var countdown: Int?
    public var initialCountdown: TimeInterval?
    public var startViewIsVisible: Bool { false }
    public var actionLabelIsVisible: Bool { true }
    public var actionLabelText: String? { L10n.alertOaDroneStuckActionText }
    public var rthAlertType: RthAlertType?
    public var stopViewStyle: StopViewStyle?
    public var shouldShowAlertPanel: Bool { connectionState == .connected && state == .available }
    public var hasAnimation: Bool { false }
    public var hasTextCountdown: Bool { false }
    public var countdownMessage: ((Int) -> String)?

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - connectionState: drone connection state
    ///    - state: Obstacle avoidance state
    init(connectionState: DeviceState.ConnectionState,
         state: AlertPanelCurrentState?) {
        super.init(connectionState: connectionState)

        self.state = state
    }

    // MARK: - Override Funcs
    public override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? HUDAlertPanelObstacleAvoidanceState else { return false }

        return super.isEqual(to: other) && state == other.state
    }

    public override func copy() -> HUDAlertPanelObstacleAvoidanceState {
        return HUDAlertPanelObstacleAvoidanceState(connectionState: self.connectionState,
                                                   state: self.state)
    }
}

/// View model for Obstacle Avoidance alert.
final class HUDAlertPanelObstacleAvoidanceViewModel: DroneStateViewModel<HUDAlertPanelObstacleAvoidanceState> {
    // MARK: - Private Properties
    private var obstacleAvoidanceMonitor: ObstacleAvoidanceMonitor
    private var alarmsRef: Ref<Alarms>?

    init(obstacleAvoidanceMonitor: ObstacleAvoidanceMonitor) {
        self.obstacleAvoidanceMonitor = obstacleAvoidanceMonitor
        super.init()

        listenAlerts()
    }

}

// MARK: - Private Funcs
private extension HUDAlertPanelObstacleAvoidanceViewModel {

    /// Listen Drone's alerts.
    func listenAlerts() {
        alarmsRef = drone?.getInstrument(Instruments.alarms) { [weak self] _ in
            self?.updateObstacleAvoidanceAlertState()
        }
    }

    func updateObstacleAvoidanceAlertState() {
        let copy = state.value.copy()

        if alarmsRef?.value?.getAlarm(kind: .obstacleAvoidanceFreeze).hasError == true {
            copy.state = .available
        } else {
            copy.state = .unavailable
        }

        state.set(copy)
    }
}

// MARK: - AlertPanelActionType
extension HUDAlertPanelObstacleAvoidanceViewModel: AlertPanelActionType {
    func startAction() {
        // Disable Obstacle Avoidance when user taps Action button.
        obstacleAvoidanceMonitor.userAsks(mode: .disabled)
    }

    func cancelAction() { }
}
