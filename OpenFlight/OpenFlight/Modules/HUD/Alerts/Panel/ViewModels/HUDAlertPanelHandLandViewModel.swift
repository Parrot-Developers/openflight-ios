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

/// State for `HUDAlertPanelHandLaunchViewModel`.
public final class HUDAlertPanelHandLandState: DeviceConnectionState, AlertPanelState {
    // MARK: - AlertPanelState Properties
    public var title: String? {
        return L10n.commonHandland
    }
    public var subtitle: String? {
        return L10n.alertHandLandLanding
    }
    public var subtitleColor: UIColor? {
        return ColorName.highlightColor.color
    }
    public var icon: UIImage? {
        return Asset.Alertes.HandLand.icHandLand.image
    }
    public var animationImages: [UIImage]? {
        return Asset.Alertes.HandLand.Animation.allValues.compactMap { $0.image }
    }
    public var state: AlertPanelCurrentState? = .none
    public var isAlertForceHidden: Bool = false
    public var countdown: Int?
    public var initialCountdown: TimeInterval?
    public var startViewIsVisible: Bool {
        return false
    }
    public var actionLabelIsVisible: Bool {
        return false
    }
    public var actionLabelText: String?
    public var rthAlertType: RthAlertType?
    public var stopViewStyle: StopViewStyle?
    public var shouldShowAlertPanel: Bool {
        return connectionState == .connected
            && state == .started
    }
    public var hasAnimation: Bool {
        return false
    }
    public var hasTextCountdown: Bool {
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
    init(connectionState: DeviceState.ConnectionState,
         state: AlertPanelCurrentState?) {
        super.init(connectionState: connectionState)

        self.state = state
    }

    // MARK: - Override Funcs
    public override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? HUDAlertPanelHandLandState else { return false }

        return super.isEqual(to: other)
            && self.state == other.state
    }

    public override func copy() -> HUDAlertPanelHandLandState {
        return HUDAlertPanelHandLandState(connectionState: self.connectionState,
                                          state: self.state)
    }
}

/// View model for Hand Land alert.

final class HUDAlertPanelHandLandViewModel: DroneStateViewModel<HUDAlertPanelHandLandState> {
    // MARK: - Private Properties
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)

        listenFlyingIndicators(drone: drone)
    }
}

// MARK: - Private Funcs
private extension HUDAlertPanelHandLandViewModel {
    /// Starts watcher for flying indicators.
    func listenFlyingIndicators(drone: Drone) {
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [weak self] _ in
            self?.updateHandLandState()
        }
    }

    /// Update current Hand Land state.
    func updateHandLandState() {
        let copy = state.value.copy()

        if flyingIndicatorsRef?.value?.isHandLanding == true {
            copy.state = .started
        } else {
            copy.state = .none
        }

        state.set(copy)
    }
}
