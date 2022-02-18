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
    var showUnsupportedModes: Bool = true
    var subMode: BarItemSubMode?
    var subtitle: String?
    var enabled: Bool = true
    var isSelected: Observable<Bool> = Observable(false)
    var unavailableReason: [String: String] = [:]
    var maxItems: Int?
    var singleMode = false

    // MARK: - Init
    required init() {
    }

    /// Constructor.
    ///
    /// - Parameters:
    ///    - title: mode title
    ///    - mode: current mode
    ///    - subMode: current mode submode
    ///    - enabled: availability of the mode
    ///    - isSelected: observable for item selection
    ///    - unavalaibleReasons: reasons why not enabled
    ///    - supportedModes: supported modes
    init(title: String? = nil,
         mode: BarItemMode?,
         subMode: BarItemSubMode? = nil,
         enabled: Bool,
         isSelected: Observable<Bool>,
         unavailableReason: [String: String],
         supportedModes: [BarItemMode]? = nil) {
        self.title = title
        self.mode = mode
        self.subMode = subMode
        self.enabled = enabled
        self.isSelected = isSelected
        self.unavailableReason = unavailableReason
        self.supportedModes = supportedModes
    }

    // MARK: - Internal Funcs
    func isEqual(to other: CameraBarButtonState) -> Bool {
        return mode?.key == other.mode?.key
        && subMode?.key == other.subMode?.key
        && title == other.title
        && enabled == other.enabled
        && unavailableReason == other.unavailableReason
        && (supportedModes as? [CameraCaptureMode]) == (other.supportedModes as? [CameraCaptureMode])
    }

    /// Returns a copy of the object.
    func copy() -> Self {
        if let copy = CameraBarButtonState(title: title,
                                           mode: mode,
                                           subMode: subMode,
                                           enabled: enabled,
                                           isSelected: isSelected,
                                           unavailableReason: unavailableReason,
                                           supportedModes: supportedModes) as? Self {
            return copy
        } else {
            fatalError("Must override...")
        }
    }
}

/// View model to manage camera mode widget in HUD Bottom bar.
final class CameraCaptureModeViewModel: BarButtonViewModel<CameraBarButtonState> {

    // MARK: - Private Properties
    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()
    private var mainCameraRef: Ref<MainCamera2>?
    private var defaultsDisposables = [DefaultsDisposable]()
    /// Panorama service.
    private unowned let panoramaService: PanoramaService
    /// Current mission manager.
    private unowned let currentMissionManager: CurrentMissionManager

    // MARK: - Init
    /// Constructor.
    ///
    /// - Parameters:
    ///   - panoramaService: panorama mode service
    ///   - currentMissionManager: current mission mode manager
    init(panoramaService: PanoramaService, currentMissionManager: CurrentMissionManager) {
        self.panoramaService = panoramaService
        self.currentMissionManager = currentMissionManager
        super.init(barId: "CameraCaptureMode")

        state.value.title = L10n.commonMode.uppercased()
        listenDefaults()

        // update state when current mission changes
        currentMissionManager.modePublisher
            .sink { [unowned self] _ in
                let copy = state.value.copy()
                if let restrictions = currentMissionManager.mode.cameraRestrictions {
                    copy.supportedModes = restrictions.supportedModes
                } else {
                    copy.supportedModes = nil
                }
                copy.singleMode = copy.supportedModes?.count == 1
                state.set(copy)
            }
            .store(in: &cancellables)
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

        // stop current photo capture or video recording if capture mode changes
        if cameraMode != (state.value.mode as? CameraCaptureMode) {
            camera.photoCapture?.stop()
            camera.recording?.stop()
        }

        // Update user defaults for Timer and Panorama modes that both use single photo mode.
        panoramaService.panoramaModeActiveValue = cameraMode == .panorama

        let editor = camera.config.edit(fromScratch: true)

        switch cameraMode {
        case .photo, .bracketing, .burst, .gpslapse, .timelapse, .panorama:
            editor[Camera2Params.mode]?.value = .photo
            // Always use CONTINUOUS mode for photo streaming mode.
            editor[Camera2Params.photoStreamingMode]?.value = .continuous
            if let photoMode = cameraMode.photoMode {
                editor[Camera2Params.photoMode]?.value = photoMode
            }
        case .video:
            editor[Camera2Params.mode]?.value = .recording
            if let recordingMode = cameraMode.recordingMode {
                editor[Camera2Params.videoRecordingMode]?.value = recordingMode
            }
        }

        // adjust photo format, photo file format and HDR settings for panorama mode
        if cameraMode == .panorama {
            editor.applyValueNotForced(Camera2Params.photoFormat, .rectilinear)
            editor.applyValueNotForced(Camera2Params.photoFileFormat, .jpeg)
            editor.applyValueNotForced(Camera2Params.photoDynamicRange, .sdr)
        }

        // Update timelapse/gpslapse with preset value if
        // drone returns a value that is not handled.
        if cameraMode == .timelapse,
            camera.timeLapseMode == nil {
            editor[Camera2Params.photoTimelapseInterval]?.value = TimeLapseMode.preset.interval
        } else if cameraMode == .gpslapse,
            camera.gpsLapseMode == nil {
            editor[Camera2Params.photoGpslapseInterval]?.value = GpsLapseMode.preset.interval
        } else if cameraMode == .burst {
            editor[Camera2Params.photoBurst]?.value = .burst10Over1s
        }

        editor.saveSettings(currentConfig: camera.config)
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
        case let gpsLapseMode as GpsLapseMode:
            currentEditor[Camera2Params.photoGpslapseInterval]?.value = gpsLapseMode.interval
        case let timeLapseMode as TimeLapseMode:
            currentEditor[Camera2Params.photoTimelapseInterval]?.value = timeLapseMode.interval
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
        mainCameraRef = drone.getPeripheral(Peripherals.mainCamera2) { [unowned self] mainCamera in
            guard let camera = mainCamera else { return }
            updateState(withCamera: camera)
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
        updateState(withCamera: camera)
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
