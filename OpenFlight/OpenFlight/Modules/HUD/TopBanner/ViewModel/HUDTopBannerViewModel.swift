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

import Combine
import GroundSdk
import SwiftyUserDefaults

// MARK: - Internal Enums
/// State for home info banner.
enum HUDTopBannerHomeState {
    /// No home state.
    case none
    /// RTH position has just been set. Transient state.
    case homePositionSet
    /// Precise home has just been set. Transient state.
    case preciseHomeSet
    /// Precise RTH in progress.
    case preciseRthInProgress
    /// Precise landing in progress.
    case preciseLandingInProgress

    /// Returns text associated with home state.
    var displayText: String? {
        switch self {
        case .none:
            return nil
        case .preciseHomeSet:
            return L10n.preciseHome
        case .homePositionSet:
            return L10n.rthPositionSet
        case .preciseRthInProgress:
            return L10n.preciseRth
        case .preciseLandingInProgress:
            return L10n.preciseLanding
        }
    }
}

/// State for `HUDTopBannerViewModel`.

final class HUDTopBannerState: DeviceConnectionState {
    // MARK: - Internal Properties
    /// Boolean for HDR state.
    fileprivate(set) var hdrOn: Bool = false
    /// Lock AE mode.
    fileprivate(set) var lockAeMode: ExposureLockState = .unavailable
    /// State for home info.
    fileprivate(set) var homeState: HUDTopBannerHomeState = .none
    /// Boolean describing if an alert is currently shown.
    fileprivate(set) var isDisplayingAlert = false
    /// Boolean describing if we should display lockAE.
    fileprivate(set) var shouldDisplayAutoExposureLock = false

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - connectionState: drone connection state
    ///    - hdrOn: boolean for HDR state
    ///    - lockAeMode: lock AE mode
    ///    - homeState: state for home info
    ///    - isDisplayingAlert: whether an alert is currently shown
    ///    - shouldDisplayLockAE: whether we should display lockAE
    init(connectionState: DeviceState.ConnectionState,
         hdrOn: Bool,
         lockAeMode: ExposureLockState,
         homeState: HUDTopBannerHomeState,
         isDisplayingAlert: Bool,
         shouldDisplayLockAE: Bool) {
        super.init(connectionState: connectionState)
        self.hdrOn = hdrOn
        self.lockAeMode = lockAeMode
        self.homeState = homeState
        self.isDisplayingAlert = isDisplayingAlert
        self.shouldDisplayAutoExposureLock = shouldDisplayLockAE
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? HUDTopBannerState else {
            return false
        }
        return super.isEqual(to: other)
            && self.hdrOn == other.hdrOn
            && self.lockAeMode == other.lockAeMode
            && self.homeState == other.homeState
            && self.isDisplayingAlert == other.isDisplayingAlert
            && self.shouldDisplayAutoExposureLock == other.shouldDisplayAutoExposureLock
    }

    override func copy() -> HUDTopBannerState {
        return HUDTopBannerState(connectionState: self.connectionState,
                                 hdrOn: self.hdrOn,
                                 lockAeMode: self.lockAeMode,
                                 homeState: self.homeState,
                                 isDisplayingAlert: self.isDisplayingAlert,
                                 shouldDisplayLockAE: self.shouldDisplayAutoExposureLock)
    }
}

/// View model for HUD's top banner.

final class HUDTopBannerViewModel: DroneStateViewModel<HUDTopBannerState> {
    // MARK: - Private Properties
    private var cameraRef: Ref<MainCamera2>?
    private var preciseHomeRef: Ref<PreciseHome>?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?
    private var returnHomeRef: Ref<ReturnHomePilotingItf>?
    private let alertBannerViewModel = HUDAlertBannerViewModel()
    private var lastPreciseHomeState: PreciseHomeState?
    private var shouldShowHomeSetInfo: Bool = true
    private var isAutoModeActive: Bool = false
    private let autoModeViewModel = ImagingBarAutoModeViewModel()
    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()
    /// Camera exposure lock service.
    private unowned var exposureLockService: ExposureLockService

    // MARK: - Override Funcs
    override init() {
        // TODO injection
        exposureLockService = Services.hub.exposureLockService

        super.init()

        listenAlertBannerViewModel()
    }

    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)
        // Avoid notifying on home set if drone is already flying.
        if drone.isStateFlying {
            shouldShowHomeSetInfo = false
        }
        listenAutoModeViewModel()
        listenCamera(drone: drone)
        listenPreciseHome(drone: drone)
        listenFlyingIndicators(drone: drone)
        listenReturnHome(drone: drone)
        listenExposureLock()
    }
}

// MARK: - Private Funcs
private extension HUDTopBannerViewModel {

    /// Starts watcher for camera.
    func listenCamera(drone: Drone) {
        cameraRef = drone.getPeripheral(Peripherals.mainCamera2) { [unowned self] _ in
            updateState()
        }
    }

    /// Starts watcher for exposure lock.
    func listenExposureLock() {
        exposureLockService.statePublisher.sink { [unowned self] _ in
            updateState()
        }
        .store(in: &cancellables)
    }

    /// Starts watcher for autoModeViewModel.
    func listenAutoModeViewModel() {
        autoModeViewModel.state.valueChanged = { [weak self] state in
            self?.isAutoModeActive = state.isActive
            self?.updateState()
        }
        isAutoModeActive = autoModeViewModel.state.value.isActive
        updateState()
    }

    /// Starts watcher for precise home.
    func listenPreciseHome(drone: Drone) {
        preciseHomeRef = drone.getPeripheral(Peripherals.preciseHome) { [weak self] _ in
            self?.updateHomeStates()
        }
    }

    /// Starts watcher for flying indicators.
    func listenFlyingIndicators(drone: Drone) {
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [weak self] flyingIndicators in
            if flyingIndicators?.state == .landed {
                // Reset home info on land.
                self?.shouldShowHomeSetInfo = true
            }
            self?.updateHomeStates()
        }
    }

    /// Starts watcher for return home.
    func listenReturnHome(drone: Drone) {
        returnHomeRef = drone.getPilotingItf(PilotingItfs.returnHome) { [weak self] _ in
            self?.updateHomeStates()
        }
    }

    /// Starts watcher for banner alerts.
    func listenAlertBannerViewModel() {
        alertBannerViewModel.state.valueChanged = { [weak self] state in
            self?.updateAlertDisplay(state)
        }
        updateAlertDisplay(alertBannerViewModel.state.value)
    }

    /// Update alert display state.
    ///
    /// - Parameters:
    ///    - alertBannerState: current alert banner state
    func updateAlertDisplay(_ alertBannerState: HUDAlertBannerState) {
        let copy = self.state.value.copy()
        copy.isDisplayingAlert = alertBannerState.alert != nil
        self.state.set(copy)
    }

    /// Updates auto mode state.
    func updateState() {
        guard let camera = drone?.getPeripheral(Peripherals.mainCamera2) else {
            return
        }

        let copy = state.value.copy()
        copy.hdrOn = camera.isHdrOn == true
        copy.lockAeMode = exposureLockService.stateValue
        copy.shouldDisplayAutoExposureLock = copy.lockAeMode.locked
            && camera.isHdrOn == false
            && isAutoModeActive == true
        state.set(copy)
    }

    /// Updates state for home.
    func updateHomeStates() {
        checkPreciseHomeState()
        checkHomePositionSet()
        checkPreciseRthOrLanding()
    }

    /// Checks for precise home.
    func checkPreciseHomeState() {
        guard let drone = drone,
              let preciseHome = drone.getPeripheral(Peripherals.preciseHome) else {
            return
        }

        if preciseHome.state == .available
            && preciseHome.state != lastPreciseHomeState
            && drone.isStateFlying {
            shouldShowHomeSetInfo = false
            let copy = state.value.copy()
            copy.homeState = .preciseHomeSet
            state.set(copy)
            DispatchQueue.main.async { [weak self] in
                let copy = self?.state.value.copy()
                copy?.homeState = .none
                self?.state.set(copy)
            }
        }
        lastPreciseHomeState = preciseHome.state
    }

    /// Checks for home position set.
    func checkHomePositionSet() {
        guard shouldShowHomeSetInfo,
              let drone = drone,
              drone.getPeripheral(Peripherals.preciseHome)?.state == .unavailable,
              drone.getInstrument(Instruments.gps)?.fixed == true,
              drone.getInstrument(Instruments.flyingIndicators)?.flyingState.isFlyingOrWaiting == true else {
            return
        }

        shouldShowHomeSetInfo = false
        let copy = state.value.copy()
        copy.homeState = .homePositionSet
        state.set(copy)
        DispatchQueue.main.async { [weak self] in
            let copy = self?.state.value.copy()
            copy?.homeState = .none
            self?.state.set(copy)
        }
    }

    /// Checks for precise RTH or landing in progress.
    func checkPreciseRthOrLanding() {
        guard let drone = drone,
              let returnHome = drone.getPilotingItf(PilotingItfs.returnHome),
              drone.getPeripheral(Peripherals.preciseHome)?.state == .active,
              let flyingIndicators = drone.getInstrument(Instruments.flyingIndicators) else { return
        }

        let copy = state.value.copy()
        if returnHome.state == .active {
            copy.homeState = .preciseRthInProgress
        } else if flyingIndicators.flyingState == .landing {
            copy.homeState = .preciseLandingInProgress
        } else {
            copy.homeState = .none
        }
        state.set(copy)
    }
}
