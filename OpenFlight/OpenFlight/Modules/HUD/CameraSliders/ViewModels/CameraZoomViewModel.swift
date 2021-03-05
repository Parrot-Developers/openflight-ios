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
import SwiftyUserDefaults

// MARK: - CameraZoomState
/// State for `CameraZoomViewModel`.

final class CameraZoomState: ViewModelState, EquatableState, Copying {
    // MARK: - Internal Properties
    /// Current zoom.
    fileprivate(set) var current: Double = 0.0
    /// Max lossless zoom.
    fileprivate(set) var maxLossLess: Double = 3.0
    /// Max lossy zoom.
    fileprivate(set) var maxLossy: Double = 1.4
    /// Boolean describing zoom control availability.
    fileprivate(set) var isAvailable: Bool = false
    /// Boolean describing lossy zoom availability.
    fileprivate(set) var isLossyAllowed: Bool = false
    /// Boolean describing zoom slider open state.
    fileprivate(set) var shouldOpenSlider: Observable<Bool> = Observable(false)
    /// Boolean with a transient true state, indicating that an overzoom occurred.
    fileprivate(set) var isOverzooming: Observable<Bool> = Observable(false)
    /// Boolean to know if zoom widget should be hidden.
    fileprivate(set) var shouldHideZoom: Observable<Bool> = Observable(false)
    /// Formatted string representing current value with 1 digit and a multiply sign.
    var formattedTitle: String {
        return String(format: "%.01f", current) + Style.multiplySign
    }
    /// Color associated with current value.
    var color: UIColor {
        return UIColor(named: current > maxLossLess ? .orangePeel : .white)
    }

    // MARK: - Init
    required init() { }

    /// Init.
    ///
    /// - Parameters:
    ///    - current: current zoom level
    ///    - maxLossLess: max lossless level allowed
    ///    - maxLossy: max lossy level allowed
    ///    - isAvailable: availability of the zoom
    ///    - isLossyAllowed: availability of lossy zoom
    ///    - shouldOpenSlider: observable for slider visibility
    ///    - isOverzooming: observable for overzoom
    init(current: Double,
         maxLossLess: Double,
         maxLossy: Double,
         isAvailable: Bool,
         isLossyAllowed: Bool,
         shouldOpenSlider: Observable<Bool>,
         isOverzooming: Observable<Bool>,
         shouldHideZoom: Observable<Bool>) {
        self.current = current
        self.maxLossLess = maxLossLess
        self.maxLossy = maxLossy
        self.isAvailable = isAvailable
        self.isLossyAllowed = isLossyAllowed
        self.shouldOpenSlider = shouldOpenSlider
        self.isOverzooming = isOverzooming
        self.shouldHideZoom = shouldHideZoom
    }

    // MARK: - Internal Funcs
    func isEqual(to other: CameraZoomState) -> Bool {
        return self.current == other.current
            && self.maxLossLess == other.maxLossLess
            && self.maxLossy == other.maxLossy
            && self.isAvailable == other.isAvailable
            && self.isLossyAllowed == other.isLossyAllowed
    }

    /// Returns a copy of the object.
    func copy() -> CameraZoomState {
        let copy = CameraZoomState(current: self.current,
                                   maxLossLess: self.maxLossLess,
                                   maxLossy: self.maxLossy,
                                   isAvailable: self.isAvailable,
                                   isLossyAllowed: self.isLossyAllowed,
                                   shouldOpenSlider: self.shouldOpenSlider,
                                   isOverzooming: self.isOverzooming,
                                   shouldHideZoom: self.shouldHideZoom)
        return copy
    }

    /// Updates current object with given zoom.
    ///
    /// - Parameters:
    ///    - zoom: current zoom
    func update(with zoom: Camera2Zoom) {
        self.current = zoom.level
        self.maxLossLess = zoom.maxLossLessLevel
        self.maxLossy = zoom.maxLevel
    }
}

// MARK: - CameraZoomViewModel
/// ViewModel for camera zoom, notifies on zoom changes.

final class CameraZoomViewModel: DroneWatcherViewModel<CameraZoomState> {
    // MARK: - Private Properties
    private var cameraRef: Ref<MainCamera2>?
    private var zoomRef: Ref<Camera2Zoom>?
    private var remoteControlGrabber: RemoteControlAxisGrabber?
    private var isZoomingWithApp: Bool = false
    private var isZoomingWithGrabbedRemoteControl = false
    private var evSettingObserver: DefaultsDisposable?
    private var splitModeObserver: Any?
    private var actionKey: String {
        return NSStringFromClass(type(of: self)) + SkyCtrl3AxisEvent.rightSlider.description
    }

    // MARK: - Private Enums
    private enum Constants {
        static let defaultZoomLevel: Double = 1.0
        static let roundPrecision: Int = 2
    }

    // MARK: - Deinit
    deinit {
        evSettingObserver?.dispose()
        evSettingObserver = nil
        if let splitModeObserver = splitModeObserver {
            NotificationCenter.default.removeObserver(splitModeObserver)
        }
        splitModeObserver = nil
    }

    // MARK: - Init
    init(stateDidUpdate: ((CameraZoomState) -> Void)? = nil,
         sliderVisibilityDidUpdate: ((Bool) -> Void)? = nil,
         isOverzoomingDidUpdate: ((Bool) -> Void)? = nil,
         zoomVisibilityDidUpdate: ((Bool) -> Void)? = nil) {
        super.init(stateDidUpdate: stateDidUpdate)
        self.state.value.shouldOpenSlider.valueChanged = sliderVisibilityDidUpdate
        self.state.value.isOverzooming.valueChanged = isOverzoomingDidUpdate
        self.state.value.shouldHideZoom.valueChanged = zoomVisibilityDidUpdate
        remoteControlGrabber = RemoteControlAxisGrabber(axis: .rightSlider,
                                                        event: .rightSlider,
                                                        key: actionKey,
                                                        action: onRemoteControlGrabUpdate)
        listenSplitModeChanges()
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        listenCamera(drone: drone)
    }

    // MARK: - Internal Funcs
    /// Controls the camera zoom with given velocity.
    ///
    /// - Parameters:
    ///    - velocity: velocity (between -1.0 and 1.0)
    func setZoomVelocity(_ velocity: Double) {
        guard let zoom: Camera2Zoom = drone?.currentCamera?.zoom else {
            return
        }

        zoom.control(mode: .velocity, target: velocity)
        isZoomingWithApp = velocity > 0
        if zoom.isZoomMaxReached(isLossyAllowed: self.state.value.isLossyAllowed),
           isZoomingWithApp {
            didOverzoom()
        }
    }

    /// Controls the camera's zoom and resets its level to default.
    func resetZoom() {
        guard let zoom = drone?.currentCamera?.zoom else {
            return
        }
        zoom.control(mode: .level, target: Constants.defaultZoomLevel)
    }

    /// Should be called to request a zoom slider visibility toggle.
    func toggleSliderVisibility() {
        state.value.shouldOpenSlider.set(!state.value.shouldOpenSlider.value)
    }

    /// Should be called to close the zoom slider.
    func closeSlider() {
        state.value.shouldOpenSlider.set(false)
    }
}

// MARK: - Private Funcs
private extension CameraZoomViewModel {
    /// Starts watcher for camera.
    func listenCamera(drone: Drone) {
        cameraRef = drone.getPeripheral(Peripherals.mainCamera2) { [weak self] camera in
            guard let strongSelf = self,
                  let camera = camera else { return }

            // Update velocity control quality mode.
            let copy = strongSelf.state.value.copy()
            copy.isLossyAllowed = camera.config[Camera2Params.zoomVelocityControlQualityMode]?.value.isLossyAllowed == true
            self?.state.set(copy)

            // Refresh zoom ref.
            strongSelf.listenZoom(camera: camera)
        }
    }

    /// Starts watcher for camera zoom.
    ///
    /// - Parameters:
    ///    - camera: the camera
    func listenZoom(camera: Camera2) {
        zoomRef = camera.getComponent(Camera2Components.zoom) { [weak self] zoom in
            let copy = self?.state.value.copy()

            guard let zoom = zoom else {
                copy?.isAvailable = false
                self?.state.set(copy)
                self?.state.value.shouldOpenSlider.set(false)

                return
            }

            self?.handleZoomMax(zoom: zoom)
            copy?.isAvailable = true
            copy?.update(with: zoom)
            self?.state.set(copy)
        }
    }

    /// Starts listening split mode changes.
    func listenSplitModeChanges() {
        splitModeObserver = NotificationCenter.default.addObserver(forName: .splitModeDidChange,
                                                                   object: nil,
                                                                   queue: nil) { [weak self] notification in
            if let splitMode = notification.userInfo?[SplitControlsConstants.splitScreenModeKey] as? SplitScreenMode {
                self?.state.value.shouldHideZoom.set(splitMode == .secondary)
            }
        }
    }

    /// Called on remote control grab update.
    func onRemoteControlGrabUpdate(_ newState: Int) {
        switch newState {
        case ..<0:
            if isZoomingWithGrabbedRemoteControl == false {
                didOverzoom()
                isZoomingWithGrabbedRemoteControl = true
            }
        case 0:
            isZoomingWithGrabbedRemoteControl = false
        default:
            ungrabRemoteControl()
        }
    }

    /// Checks if zoom max is reached and grabs remote control if needed.
    func handleZoomMax(zoom: Camera2Zoom) {
        if zoom.isZoomMaxReached(isLossyAllowed: self.state.value.isLossyAllowed) {
            let oldValue = self.state.value.current.rounded(toPlaces: Constants.roundPrecision)
            let newValue = zoom.level.rounded(toPlaces: Constants.roundPrecision)
            if newValue > oldValue {
                didOverzoom()
                if !isZoomingWithApp { // Not zooming with app == Zooming with remote control.
                    isZoomingWithGrabbedRemoteControl = true
                }
            }
            remoteControlGrabber?.grab()
        } else {
            ungrabRemoteControl()
        }
    }

    /// Listen Ev trigger setting to prevent from grab issues.
    func listenEvSetting() {
        evSettingObserver = Defaults.observe(\.evTriggerSetting, options: [.new]) { [weak self] _ in
            DispatchQueue.userDefaults.async {
                if EVTriggerManager.shared.isEvTriggerSettingEnabled {
                    // If EV trigger changed to state enable, ungrab zoom
                    self?.ungrabRemoteControl()
                }
            }
        }
    }

    /// Helper to ungrab remote control.
    func ungrabRemoteControl() {
        self.remoteControlGrabber?.ungrab()
        self.isZoomingWithGrabbedRemoteControl = false
    }

    /// Called when an overzoom is detected.
    func didOverzoom() {
        self.state.value.isOverzooming.set(true)
        self.state.value.isOverzooming.set(false)
    }
}
