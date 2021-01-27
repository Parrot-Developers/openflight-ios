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

// MARK: - GimbalTiltState
/// State for `GimbalTiltViewModel`.

final class GimbalTiltState: ViewModelState, EquatableState, Copying {
    // MARK: - Internal Properties
    /// Current tilt.
    fileprivate(set) var current: Double = 0.0
    /// Current tilt range.
    fileprivate(set) var range: Range<Double>?
    /// Current tilt availability.
    fileprivate(set) var isAvailable: Bool = false
    /// Boolean describing tilt slider open state.
    fileprivate(set) var shouldOpenSlider: Observable<Bool> = Observable(false)
    /// Boolean with a transient true state, indicating that an overtilt occured.
    fileprivate(set) var isOvertilting: Observable<Bool> = Observable(false)
    /// Boolean to know if tilt widget should be hidden.
    fileprivate(set) var shouldHideTilt: Observable<Bool> = Observable(false)

    // MARK: - Init
    required init() { }

    /// Init.
    ///
    /// - Parameters:
    ///    - current: current tilt level
    ///    - isAvailable: availability of the tilt
    ///    - shouldOpenSlider: observable for slider visibility
    ///    - isOvertilting: observable for overtilt
    ///    - shouldHideTilt: observable for tilt visibility
    init(current: Double,
         range: Range<Double>?,
         isAvailable: Bool,
         shouldOpenSlider: Observable<Bool>,
         isOvertilting: Observable<Bool>,
         shouldHideTilt: Observable<Bool>) {
        self.current = current
        self.range = range
        self.isAvailable = isAvailable
        self.shouldOpenSlider = shouldOpenSlider
        self.isOvertilting = isOvertilting
        self.shouldHideTilt = shouldHideTilt
    }

    // MARK: - Internal Funcs
    func isEqual(to other: GimbalTiltState) -> Bool {
        return self.current == other.current
            && self.range == other.range
            && self.isAvailable == other.isAvailable
    }

    /// Returns a copy of the object.
    func copy() -> GimbalTiltState {
        let copy = GimbalTiltState(current: self.current,
                                   range: self.range,
                                   isAvailable: self.isAvailable,
                                   shouldOpenSlider: self.shouldOpenSlider,
                                   isOvertilting: self.isOvertilting,
                                   shouldHideTilt: self.shouldHideTilt)
        return copy
    }
}

// MARK: - GimbalTiltViewModel
/// ViewModel for GimbalTilt, notifies on tilt and tilt range changes.

final class GimbalTiltViewModel: DroneWatcherViewModel<GimbalTiltState> {
    // MARK: - Private Properties
    private var gimbalRef: Ref<Gimbal>?
    private var deviceStateRef: Ref<DeviceState>?
    private var remoteControlGrabber: RemoteControlAxisGrabber?
    private var isTiltingWithApp: Bool = false
    private var isTiltingWithGrabbedRemoteControl: Bool = false
    private var splitModeObserver: Any?
    private var actionKey: String {
        return NSStringFromClass(type(of: self)) + SkyCtrl3AxisEvent.leftSlider.description
    }

    // MARK: - Private Enums
    private enum Constants {
        static let defaultTiltPosition: Double = 0.0
        static let roundPrecision: Int = 2
    }

    // MARK: - Init
    init(stateDidUpdate: ((GimbalTiltState) -> Void)? = nil,
         sliderVisibilityDidUpdate: ((Bool) -> Void)? = nil,
         isOverTiltingDidUpdate: ((Bool) -> Void)? = nil,
         tiltVisibilityDidUpdate: ((Bool) -> Void)? = nil) {
        super.init(stateDidUpdate: stateDidUpdate)
        self.state.value.shouldOpenSlider.valueChanged = sliderVisibilityDidUpdate
        self.state.value.isOvertilting.valueChanged = isOverTiltingDidUpdate
        self.state.value.shouldHideTilt.valueChanged = tiltVisibilityDidUpdate
        remoteControlGrabber = RemoteControlAxisGrabber(axis: .leftSlider,
                                                        event: .leftSlider,
                                                        key: actionKey,
                                                        action: onRemoteControlGrabUpdate)
        listenSplitModeChanges()
    }

    // MARK: - Deinit
    deinit {
        if let splitModeObserver = splitModeObserver {
            NotificationCenter.default.removeObserver(splitModeObserver)
        }
        splitModeObserver = nil
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        listenGimbal(drone: drone)
        listenState(drone: drone)
    }

    // MARK: - Internal Funcs
    /// Controls the drone's gimbal with given velocity.
    ///
    /// - Parameters:
    ///    - velocity: velocity (between -1.0 and 1.0)
    func setPitchVelocity(_ velocity: Double) {
        guard let gimbal = drone?.getPeripheral(Peripherals.gimbal) else {
            return
        }
        gimbal.control(mode: .velocity, yaw: nil, pitch: velocity, roll: nil)
        isTiltingWithApp = velocity != 0
        if (gimbal.isMaxPositiveTiltReached || gimbal.isMaxNegativeTiltReached) && isTiltingWithApp {
            didOvertilt()
        }
    }

    /// Controls the drone's gimbal and resets its pitch to default.
    func resetPitch() {
        guard let gimbal = drone?.getPeripheral(Peripherals.gimbal) else {
            return
        }
        gimbal.control(mode: .position, yaw: nil, pitch: Constants.defaultTiltPosition, roll: nil)
    }

    /// Should be called to request a tilt slider visibility toggle.
    func toggleSliderVisibility() {
        state.value.shouldOpenSlider.set(!state.value.shouldOpenSlider.value)
    }

    /// Should be called to close the tilt slider.
    func closeSlider() {
        state.value.shouldOpenSlider.set(false)
    }
}

// MARK: - Private Funcs
private extension GimbalTiltViewModel {
    /// Starts watcher for gimbal.
    func listenGimbal(drone: Drone) {
        gimbalRef = drone.getPeripheral(Peripherals.gimbal) { [weak self] _ in
            self?.updateState()
        }
    }

    /// Starts watcher for drone state.
    func listenState(drone: Drone) {
        deviceStateRef = drone.getState { [weak self] _ in
            self?.updateState()
        }
    }

    /// Starts listening split mode changes.
    func listenSplitModeChanges() {
        splitModeObserver = NotificationCenter.default.addObserver(
            forName: .splitModeDidChange,
            object: nil,
            queue: nil) { [weak self] notification in
                guard let splitMode = notification.userInfo?[SplitControlsConstants.splitScreenModeKey]
                    as? SplitScreenMode else {
                        return
                }
                self?.state.value.shouldHideTilt.set(splitMode == .secondary)
        }
    }

    /// Compute current tilt state.
    func updateState() {
        guard let drone = drone,
              let gimbal = drone.getPeripheral(Peripherals.gimbal)
            else {
                return
        }
        let copyState = state.value.copy()
        handleTiltMax(gimbal: gimbal)
        copyState.current = gimbal.currentAttitude[.pitch] ?? Constants.defaultTiltPosition
        copyState.range = gimbal.attitudeBounds[.pitch]
        copyState.isAvailable = drone.isConnected
        if !copyState.isAvailable {
            copyState.shouldOpenSlider.set(false)
        }
        self.state.set(copyState)
    }

    /// Checks if max tilt is reached and grabs remote control if needed.
    ///
    /// - Parameters:
    ///     - gimbal: current gimbal
    func handleTiltMax(gimbal: Gimbal) {
        let oldValue = self.state.value.current.rounded(toPlaces: Constants.roundPrecision)
        let newValue = (gimbal.currentAttitude[.pitch] ?? Constants.defaultTiltPosition).rounded(toPlaces: Constants.roundPrecision)
        if gimbal.isMaxPositiveTiltReached {
            if newValue > oldValue {
                didOvertilt()
                if !isTiltingWithApp { // Not tilting with app == Tilting with remote control.
                    isTiltingWithGrabbedRemoteControl = true
                }
            }
            remoteControlGrabber?.grab()
        } else if gimbal.isMaxNegativeTiltReached {
            if newValue < oldValue {
                didOvertilt()
                if !isTiltingWithApp { // Not tilting with app == Tilting with remote control.
                    isTiltingWithGrabbedRemoteControl = true
                }
            }
            remoteControlGrabber?.grab()
        } else {
            remoteControlGrabber?.ungrab()
            isTiltingWithGrabbedRemoteControl = false
        }
    }

    /// Called on remote control grab update.
    ///
    /// - Parameters:
    ///     - newState: new grab state
    func onRemoteControlGrabUpdate(_ newState: Int) {
        guard let gimbal = drone?.getPeripheral(Peripherals.gimbal) else {
            return
        }
        switch (newState, gimbal.isMaxNegativeTiltReached, gimbal.isMaxPositiveTiltReached) {
        case (0, _, _):
            isTiltingWithGrabbedRemoteControl = false
        case (..<0, true, _):
            if !isTiltingWithGrabbedRemoteControl {
                didOvertilt()
                isTiltingWithGrabbedRemoteControl = true
            }
        case (0..., _, true):
            if !isTiltingWithGrabbedRemoteControl {
                didOvertilt()
                isTiltingWithGrabbedRemoteControl = true
            }
        default:
            remoteControlGrabber?.ungrab()
            isTiltingWithGrabbedRemoteControl = false
        }
    }

    /// Called when overtilt is detected.
    func didOvertilt() {
        self.state.value.isOvertilting.set(true)
        self.state.value.isOvertilting.set(false)
    }
}
