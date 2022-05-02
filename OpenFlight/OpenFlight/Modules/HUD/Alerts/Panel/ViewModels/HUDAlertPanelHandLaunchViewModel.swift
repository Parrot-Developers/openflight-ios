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

import Combine
import GroundSdk

/// State for `HUDAlertPanelHandLaunchViewModel`.
public final class HUDAlertPanelHandLaunchState: DeviceConnectionState, AlertPanelState {
    // MARK: - AlertPanelState Properties
    public var title: String? {
        return L10n.commonHandlaunch
    }
    public var subtitle: String? {
        switch state {
        case .available:
            return L10n.commonAvailable
        case .started:
            return L10n.commonReady
        default:
            return nil
        }
    }
    public var titleImage: UIImage?
    public var subtitleColor: UIColor? {
        switch state {
        case .started:
            return ColorName.highlightColor.color
        case .available:
            return ColorName.blueNavy.color
        default:
            return ColorName.defaultTextColor.color
        }
    }
    public var icon: UIImage? {
        return Asset.Alertes.HandLaunch.icHandLaunch.image
    }
    public var animationImages: [UIImage]? {
        return countdown == 0 ? Asset.Alertes.HandLaunch.Animation.allValues.compactMap { $0.image } : []
    }
    public var state: AlertPanelCurrentState?
    public var isAlertForceHidden: Bool = false
    public var countdown: Int?
    public var initialCountdown: TimeInterval?
    public var startViewIsVisible: Bool {
        return state == .started
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
        return connectionState == .connected
        && state != nil
        && state != .unavailable
        && !isAlertForceHidden
    }
    public var hasAnimation: Bool {
        return false
    }
    public var hasTextCountdown: Bool {
        return true
    }
    public var countdownMessage: ((Int) -> String)? = { countdown in
        return countdown == 0 ? L10n.alertHandLaunchLaunch : countdown.description
    }

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Constructor.
    ///
    /// - Parameters:
    ///    - connectionState: drone connection state
    ///    - state: Hand Launch state
    ///    - isAlertForceHidden: Hand Launch force hide parameter
    ///    - countdown: countdown for progress view
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
        guard let other = other as? HUDAlertPanelHandLaunchState else { return false }

        return super.isEqual(to: other)
        && state == other.state
        && isAlertForceHidden == other.isAlertForceHidden
        && countdown == other.countdown
    }

    public override func copy() -> HUDAlertPanelHandLaunchState {
        return HUDAlertPanelHandLaunchState(connectionState: connectionState,
                                            state: state,
                                            isAlertForceHidden: isAlertForceHidden,
                                            countdown: countdown)
    }
}

/// View model for hand launch alert.
final class HUDAlertPanelHandLaunchViewModel: DroneStateViewModel<HUDAlertPanelHandLaunchState> {
    // MARK: - Private Properties
    private var handLaunchService: HandLaunchService
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?
    private var manualPilotingRef: Ref<ManualCopterPilotingItf>?
    private var timer: Timer?
    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Private Enums
    private enum Constants {
        static let countDownDuration: Int = 3
        static let countDownInterval: TimeInterval = 1.0
    }

    /// Constructor.
    ///
    /// - Parameters:
    ///    - handLaunchService: hand launch service
    init(handLaunchService: HandLaunchService) {
        self.handLaunchService = handLaunchService
        super.init()

        listenHandLaunchService()
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)

        listenFlyingIndicators(drone: drone)
        listenManualPiloting(drone: drone)
        updateHandLaunchAvailability()
    }

    // MARK: - Deinit
    deinit {
        timer?.invalidate()
        timer = nil
        let copy = state.value.copy()
        copy.countdown = nil
        state.set(copy)
    }
}

// MARK: - Private Funcs
private extension HUDAlertPanelHandLaunchViewModel {
    /// Starts watcher for flying indicators.
    func listenFlyingIndicators(drone: Drone) {
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [unowned self] _ in
            updateHandLaunchAvailability()
        }
    }

    /// Starts watcher for manual piloting.
    func listenManualPiloting(drone: Drone) {
        manualPilotingRef = drone.getPilotingItf(PilotingItfs.manualCopter) { [unowned self] _ in
            updateHandLaunchAvailability()
        }
    }

    func listenHandLaunchService() {
        handLaunchService.canStartPublisher
            .sink { [unowned self] _ in
                updateHandLaunchAvailability()
            }
            .store(in: &cancellables)
    }

    /// Update current hand launch availability.
    func updateHandLaunchAvailability() {
        let copy = state.value.copy()

        guard let drone = drone else {
            copy.state = .none
            state.set(copy)
            return
        }

        if handLaunchService.canStart {
            copy.state = .available
        } else if drone.isHandLaunchReady {
            copy.state = .started
        } else {
            copy.state = .unavailable
        }

        // whether handlaunch is turned to `started` state
        let starting = state.value.state != .started && copy.state == .started

        state.set(copy)

        if starting {
            // show starting countdown
            startCountdown()
        }
    }

    /// Starts or stops hand launch depending current state.
    func toggleHandLaunch() {
        guard let drone = drone else { return }

        if state.value.state == .started {
            manualPilotingRef?.value?.land()
        } else {
            NotificationCenter.default.post(name: .takeOffRequestedDidChange,
                                            object: nil,
                                            userInfo: [HUDCriticalAlertConstants.takeOffRequestedNotificationKey: true])
            if Services.hub.ui.criticalAlert.canTakeOff {
                drone.startHandLaunch()
            }
        }
    }

    /// Starts countdown.
    func startCountdown() {
        let copy = state.value.copy()
        copy.countdown = Constants.countDownDuration
        state.set(copy)
        timer = Timer.scheduledTimer(withTimeInterval: Constants.countDownInterval, repeats: true, block: { [weak self] _ in
            let copy = self?.state.value.copy()

            if let countDown = copy?.countdown, countDown > 0 {
                copy?.countdown = countDown - Int(Constants.countDownInterval)
            } else {
                copy?.countdown = 0
                self?.timer?.invalidate()
                self?.timer = nil
            }

            self?.state.set(copy)
        })
    }
}

// MARK: - AlertPanelActionType
extension HUDAlertPanelHandLaunchViewModel: AlertPanelActionType {
    func startAction() {
        LogEvent.log(.button(item: LogEvent.LogKeyHUDPanelButton.start.name,
                             value: state.value.state?.description ?? ""))
        guard state.value.state == .available else { return }

        toggleHandLaunch()
    }

    func cancelAction() {
        LogEvent.log(.button(item: LogEvent.LogKeyHUDPanelButton.cancel.name,
                             value: state.value.state?.description ?? ""))
        switch state.value.state {
        case .available:
            handLaunchService.disabledByUser()
        case .started:
            toggleHandLaunch()
        default:
            break
        }
    }
}
