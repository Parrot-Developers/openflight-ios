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
import SwiftyUserDefaults

// MARK: - Internal Enums
/// State for home info banner.
enum HUDTopBannerHomeState {
    /// No home state.
    case none
    /// RTH position has just been set. Transient state.
    case homePositionSet
    /// Precise RTH in progress.
    case preciseRthInProgress
    /// Precise landing in progress.
    case preciseLandingInProgress

    /// Returns text associated with home state.
    var displayText: String? {
        switch self {
        case .none:
            return nil
        case .homePositionSet:
            return L10n.rthPositionSet
        case .preciseRthInProgress:
            return L10n.preciseRth
        case .preciseLandingInProgress:
            return L10n.preciseLanding
        }
    }
}

/// View model for HUD's top banner.

final class HUDTopBannerViewModel {

    /// Boolean for HDR state.
    @Published private(set) var hdrOn: Bool = false
    /// Lock AE mode.
    @Published private(set) var lockAeMode: ExposureLockState = .unavailable
    /// State for home info.
    @Published private(set) var homeState: HUDTopBannerHomeState = .none
    /// Boolean describing if an alert is currently shown.
    @Published private(set) var isDisplayingAlert = false
    /// Boolean describing if we should display lockAE.
    @Published private(set) var shouldDisplayAutoExposureLock = false
    /// Connection state of the drone
    @Published private(set) var connectionState: DeviceState.ConnectionState = .disconnected
    /// Boolean describing if the drone is landed
    @Published private(set) var isLanded: Bool = true

    // MARK: - Private Properties
    private var cameraRef: Ref<MainCamera2>?
    private var droneStateRef: Ref<DeviceState>?
    private var preciseHomeRef: Ref<PreciseHome>?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?
    private var returnHomeRef: Ref<ReturnHomePilotingItf>?
    private let alertBannerViewModel = HUDAlertBannerViewModel()
    // [Banner Alerts] Legacy code is temporarily kept for validation purpose only.
    // TODO: Remove property.
    private var shouldShowHomeSetInfo: Bool = false
    private var isAutoModeActive: Bool = false
    private let autoModeViewModel: ImagingBarAutoModeViewModel
    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()
    /// Camera exposure lock service.
    private unowned var exposureLockService: ExposureLockService
    private unowned var currentDroneHolder: CurrentDroneHolder
    /// The banner alert manager service.
    private let bamService: BannerAlertManagerService

    init() {
        // TODO injection
        bamService = Services.hub.bamService
        exposureLockService = Services.hub.drone.exposureLockService
        autoModeViewModel = ImagingBarAutoModeViewModel(exposureLockService: exposureLockService)
        currentDroneHolder = Services.hub.currentDroneHolder
        listenAlertBannerViewModel()

        currentDroneHolder.dronePublisher
            .sink { [unowned self] drone in
                listenAutoModeViewModel(drone: drone)
                listenCamera(drone: drone)
                listenPreciseHome(drone: drone)
                listenFlyingIndicators(drone: drone)
                listenReturnHome(drone: drone)
                listenExposureLock(drone: drone)
                listenConnectionState(drone: drone)
            }
            .store(in: &cancellables)
    }

    /// Updates the top banner home state
    /// - Parameter state: Top banner home state
    func updateHomeState(with state: HUDTopBannerHomeState) {
        homeState = state
    }
}

// MARK: - Private Funcs
private extension HUDTopBannerViewModel {

    /// Starts watcher for connection state
    func listenConnectionState(drone: Drone) {
        droneStateRef = drone.getState { [unowned self] deviceState in
            connectionState = deviceState?.connectionState ?? .disconnected
        }
    }

    /// Starts watcher for camera.
    func listenCamera(drone: Drone) {
        cameraRef = drone.getPeripheral(Peripherals.mainCamera2) { [unowned self] _ in
            updateState(drone: drone)
        }
    }

    /// Starts watcher for exposure lock.
    func listenExposureLock(drone: Drone) {
        exposureLockService.statePublisher.sink { [unowned self] _ in
            updateState(drone: drone)
        }
        .store(in: &cancellables)
    }

    /// Starts watcher for autoModeViewModel.
    func listenAutoModeViewModel(drone: Drone) {
        autoModeViewModel.$autoExposure
            .sink { [unowned self] autoExposure in
                isAutoModeActive = autoExposure
                updateState(drone: drone)
            }
            .store(in: &cancellables)
    }

    /// Starts watcher for precise home.
    func listenPreciseHome(drone: Drone) {
        preciseHomeRef = drone.getPeripheral(Peripherals.preciseHome) { [weak self] _ in
            self?.updateHomeStates(drone: drone)
        }
    }

    /// Starts watcher for flying indicators.
    func listenFlyingIndicators(drone: Drone) {
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [weak self] flyingIndicators in
            guard let self = self else { return }
            if flyingIndicators?.flyingState == .takingOff {
                self.shouldShowHomeSetInfo = true
            } else if flyingIndicators?.state != .flying {
                self.shouldShowHomeSetInfo = false
            }

            self.isLanded = flyingIndicators?.state == .landed
            self.updateHomeStates(drone: drone)
        }
    }

    /// Starts watcher for return home.
    func listenReturnHome(drone: Drone) {
        returnHomeRef = drone.getPilotingItf(PilotingItfs.returnHome) { [weak self] _ in
            self?.updateHomeStates(drone: drone)
        }
    }

    // [Banner Alerts] Legacy code is temporarily kept for validation purpose only.
    // TODO: Remove function.
    /// Starts watcher for banner alerts.
    func listenAlertBannerViewModel() {
        alertBannerViewModel.state.valueChanged = { [weak self] state in
            self?.updateAlertDisplay(state)
        }
        updateAlertDisplay(alertBannerViewModel.state.value)
    }

    // [Banner Alerts] Legacy code is temporarily kept for validation purpose only.
    // TODO: Remove function.
    /// Update alert display state.
    ///
    /// - Parameters:
    ///    - alertBannerState: current alert banner state
    func updateAlertDisplay(_ alertBannerState: HUDAlertBannerState) {
        isDisplayingAlert = alertBannerState.alert != nil
    }

    /// Updates auto mode state.
    func updateState(drone: Drone) {
        guard let camera = drone.getPeripheral(Peripherals.mainCamera2) else {
            return
        }

        hdrOn = camera.isHdrOn == true
        lockAeMode = exposureLockService.stateValue
        shouldDisplayAutoExposureLock = lockAeMode.locked
            && camera.isHdrOn == false
            && isAutoModeActive == true

        bamService.update(ExposureAlert.hdrOn, show: hdrOn)
        bamService.update(ExposureAlert.lockAe, show: shouldDisplayAutoExposureLock)
    }

    /// Updates state for home.
    func updateHomeStates(drone: Drone) {
        checkHomePositionSet(drone: drone)
        checkPreciseRthOrLanding(drone: drone)
    }

    /// Checks for home position set.
    func checkHomePositionSet(drone: Drone) {
        guard shouldShowHomeSetInfo,
              drone.getPilotingItf(PilotingItfs.returnHome)?.homeLocation != nil,
              drone.getInstrument(Instruments.flyingIndicators)?.flyingState.isFlyingOrWaiting == true else {
                  return
              }

        shouldShowHomeSetInfo = false
        homeState = .homePositionSet
    }

    /// Checks for precise RTH or landing in progress.
    func checkPreciseRthOrLanding(drone: Drone) {
        guard let returnHome = drone.getPilotingItf(PilotingItfs.returnHome),
              drone.getPeripheral(Peripherals.preciseHome)?.state == .active,
              let flyingIndicators = drone.getInstrument(Instruments.flyingIndicators) else {
                  if homeState != .homePositionSet {
                      homeState = .none
                  }
                  return
              }

        if returnHome.state == .active {
            homeState = .preciseRthInProgress
        } else if flyingIndicators.flyingState == .landing {
            homeState = .preciseLandingInProgress
        } else {
            homeState = .none
        }
    }
}
