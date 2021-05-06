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

import UIKit
import GroundSdk
import SwiftyUserDefaults

/// State for `CameraCaptureModeViewModel`.
class CameraBarButtonState: BarButtonState, EquatableState, Copying {
    // MARK: - Internal Properties
    var title: String?
    var subtext: String? {
        return mode?.title
    }
    var image: UIImage? {
        return mode?.image
    }
    var mode: BarItemMode?
    var supportedModes: [BarItemMode]?
    var showUnsupportedModes: Bool = false
    var subMode: BarItemSubMode?
    var subtitle: String?
    var enabled: Bool = true
    var isSelected: Observable<Bool> = Observable(false)

    // MARK: - Init
    required init() {
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - title: mode title
    ///    - mode: current mode
    ///    - subMode: current mode submode
    ///    - enabled: availability of the mode
    ///    - isSelected: observable for item selection
    init(title: String? = nil,
         mode: BarItemMode?,
         subMode: BarItemSubMode? = nil,
         enabled: Bool,
         isSelected: Observable<Bool>) {
        self.title = title
        self.mode = mode
        self.subMode = subMode
        self.enabled = enabled
        self.isSelected = isSelected
    }

    // MARK: - Internal Funcs
    func isEqual(to other: CameraBarButtonState) -> Bool {
        return self.mode?.key == other.mode?.key
            && self.subMode?.key == other.subMode?.key
    }

    /// Returns a copy of the object.
    func copy() -> Self {
        if let copy = CameraBarButtonState(title: self.title,
                                           mode: mode,
                                           subMode: self.subMode,
                                           enabled: self.enabled,
                                           isSelected: isSelected) as? Self {
            return copy
        } else {
            fatalError("Must override...")
        }
    }
}

/// View model to manage camera mode widget in HUD Bottom bar.
final class CameraCaptureModeViewModel: BarButtonViewModel<CameraBarButtonState> {

    // MARK: - Private Properties
    private var mainCameraRef: Ref<MainCamera2>?
    private var defaultsDisposables = [DefaultsDisposable]()

    // MARK: - Init
    override init() {
        super.init()

        state.value.title = L10n.commonMode.uppercased()
        listenDefaults()
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        listenCamera(drone: drone)
    }

    /// Update camera capture mode.
    ///
    /// - Parameters :
    ///  - mode: new camera capture mode
    override func update(mode: BarItemMode) {
        guard let camera = drone?.currentCamera,
            let cameraMode = mode as? CameraCaptureMode else {
                return
        }

        // Update user defaults for Timer and Panorama modes that both use single photo mode.
        Defaults.isPanoramaModeActivated = cameraMode == .panorama

        let currentEditor = camera.currentEditor

        switch cameraMode {
        case .photo, .bracketing, .burst, .gpslapse, .timelapse, .panorama:
            currentEditor[Camera2Params.mode]?.value = .photo
            // Always use CONTINUOUS mode for photo streaming mode.
            currentEditor[Camera2Params.photoStreamingMode]?.value = .continuous
            if let photoMode = cameraMode.photoMode {
                currentEditor[Camera2Params.photoMode]?.value = photoMode
            }
        case .video, .slowmotion, .hyperlapse:
            currentEditor[Camera2Params.mode]?.value = .recording
            if let recordingMode = cameraMode.recordingMode {
                currentEditor[Camera2Params.videoRecordingMode]?.value = recordingMode
            }
        }

        // Update timelapse/gpslapse with preset value if
        // drone returns a value that is not handled.
        if cameraMode == .timelapse,
            camera.timeLapseMode == nil,
            let value = TimeLapseMode.preset.value {
            currentEditor[Camera2Params.photoTimelapseInterval]?.value = Double(value)
        } else if cameraMode == .gpslapse,
            camera.gpsLapseMode == nil,
            let value = GpsLapseMode.preset.value {
            currentEditor[Camera2Params.photoGpslapseInterval]?.value = Double(value)
        } else if cameraMode == .burst {
            currentEditor[Camera2Params.photoBurst]?.value = .burst10Over1s
        }

        currentEditor.saveSettings(currentConfig: camera.config)
    }

    /// Update camera sub-mode.
    ///
    /// - Parameters :
    ///  - subMode: new camera sub-mode
    override func update(subMode: BarItemSubMode) {
        guard let camera = drone?.currentCamera else { return }

        let currentEditor = camera.currentEditor

        switch subMode {
        case let subModeKeyable as DefaultsLoadableBarItem:
            Defaults[key: type(of: subModeKeyable).defaultKey] = subModeKeyable.rawValue
        case let bracketingMode as BracketingMode:
            if let value = bracketingMode.value, let bracketingValue = Camera2BracketingValue(rawValue: value) {
                currentEditor[Camera2Params.photoBracketing]?.value = bracketingValue
            }
        case let hyperlapseValue as Camera2HyperlapseValue:
            currentEditor[Camera2Params.videoRecordingHyperlapse]?.value = hyperlapseValue
        case let slowMotionMode as SlowMotionMode:
            if let value = slowMotionMode.value, let resolutionValue = Camera2RecordingResolution(rawValue: value) {
                currentEditor[Camera2Params.videoRecordingResolution]?.value = resolutionValue
            }
        case let gpsLapseMode as GpsLapseMode:
            if let gpsLapseValue = gpsLapseMode.value {
                currentEditor[Camera2Params.photoGpslapseInterval]?.value = Double(gpsLapseValue)
            }
        case let timeLapseMode as TimeLapseMode:
            if let timeLapseValue = timeLapseMode.value {
                currentEditor[Camera2Params.photoTimelapseInterval]?.value = Double(timeLapseValue)
            }
        default:
            break
        }

        currentEditor.saveSettings(currentConfig: camera.config)
    }

    // MARK: - Deinit
    deinit {
        defaultsDisposables.forEach {
            $0.dispose()
        }
        defaultsDisposables.removeAll()
    }
}

// MARK: - Private Funcs
private extension CameraCaptureModeViewModel {
    /// Starts watcher for camera.
    func listenCamera(drone: Drone) {
        mainCameraRef = drone.getPeripheral(Peripherals.mainCamera2) { [weak self] mainCamera in
            guard let camera = mainCamera else { return }
            self?.updateState(withCamera: camera)
        }
    }

    /// Update state from camera mode.
    func updateState(withCamera camera: Camera2) {
        guard let newMode = CameraUtils.computeCameraMode(camera: camera) else {
            return
        }
        let copy = state.value.copy()
        copy.subMode = CameraUtils.computeCameraSubMode(camera: camera, forMode: newMode)
        copy.mode = newMode
        state.set(copy)
    }

    /// Utility method to update state.
    func updateState() {
        guard let camera = drone?.currentCamera else { return }
        self.updateState(withCamera: camera)
    }

    /// Listen updates on user defaults to detect photo mode changes.
    func listenDefaults() {
        defaultsDisposables.append(Defaults.observe(\.isPanoramaModeActivated, options: [.new]) { [weak self] _ in
            DispatchQueue.userDefaults.async {
                self?.updateState()
            }
        })

        defaultsDisposables.append(Defaults.observe(\.userPanoramaSetting, options: [.new]) { [weak self] _ in
            DispatchQueue.userDefaults.async {
                self?.updateState()
            }
        })
    }
}
