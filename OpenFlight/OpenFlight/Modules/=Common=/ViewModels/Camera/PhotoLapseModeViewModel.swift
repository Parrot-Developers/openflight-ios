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
import Combine

private extension ULogTag {
    static let tag = ULogTag(name: "PhotoLapseModeViewModel")
}

/// State for `PhotoLapseModeViewModel`.
final class PhotoLapseState: DeviceConnectionState {
    // MARK: - Internal Properties
    /// Boolean describing current timelapse state.
    var isTimelapseInProgress: Bool = false
    /// Boolean describing current gpslapse state.
    var isGpslapseInProgress: Bool = false
    /// Number of photos which has been take.
    var photosNumber: Int = 0
    /// Selected gpslapse or timelapse value.
    var selectedValue: Double = 1.0

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - connectionState: connection state
    ///    - isTimelapseInProgress: boolean describing current timelapse state
    ///    - isGpslapseInProgress: boolean describing current gpslapse state
    ///    - photosNumber: number of photos which has been take
    ///    - selectedValue: selected value
    init(connectionState: DeviceState.ConnectionState,
         isTimelapseInProgress: Bool,
         isGpslapseInProgress: Bool,
         photosNumber: Int,
         selectedValue: Double) {
        super.init(connectionState: connectionState)
        self.isTimelapseInProgress = isTimelapseInProgress
        self.isGpslapseInProgress = isGpslapseInProgress
        self.photosNumber = photosNumber
        self.selectedValue = selectedValue
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? PhotoLapseState else {
            return false
        }
        return super.isEqual(to: other)
            && self.isTimelapseInProgress == other.isTimelapseInProgress
            && self.isGpslapseInProgress == other.isGpslapseInProgress
            && self.photosNumber == other.photosNumber
            && self.selectedValue == other.selectedValue
    }

    override func copy() -> PhotoLapseState {
        return PhotoLapseState(connectionState: connectionState,
                               isTimelapseInProgress: isTimelapseInProgress,
                               isGpslapseInProgress: isGpslapseInProgress,
                               photosNumber: photosNumber,
                               selectedValue: selectedValue)
    }
}

/// View model that manages timelapse and gpslapse photo capture mode.
final class PhotoLapseModeViewModel: DroneStateViewModel<PhotoLapseState> {
    // MARK: - Private Properties
    private var mediaListRef: Ref<[MediaItem]>?
    private var photoCaptureRef: Ref<Camera2PhotoCapture>?
    private var cameraRef: Ref<MainCamera2>?
    private var camera: Camera2? { drone?.currentCamera }

    private let activeExecutionWatcher = Services.hub.flightPlan.activeFlightPlanWatcher
    private var connectedDroneHolder = Services.hub.connectedDroneHolder
    private var cancellables = Set<AnyCancellable>()
    private var photoCount: Int = 0
    private var photoCaptureCount: Int = 0

    // MARK: - Init
    override init() {
        super.init()

        connectedDroneHolder.dronePublisher
            .combineLatest(activeExecutionWatcher.activeFlightPlanPublisher)
            .sink { [unowned self] drone, activeFlightPlan in
                guard let drone = drone else {
                    photoCaptureRef = nil
                    cameraRef = nil
                    return
                }

                listenMedia(drone: drone, activeFlightPlan: activeFlightPlan)
            }
            .store(in: &cancellables)
    }
}

// MARK: - Private Funcs
private extension PhotoLapseModeViewModel {
    /// Starts watcher for media.
    func listenMedia(drone: Drone, activeFlightPlan: FlightPlanModel?) {
        mediaListRef = drone.getPeripheral(Peripherals.mediaStore)?.newList { [unowned self] mediaList in
            guard let activeFlightPlan = activeFlightPlan,
                  let mediaList = mediaList, !mediaList.isEmpty else {
                      photoCount = 0
                      listenCamera(drone: drone)
                      mediaListRef = nil
                      return
                  }

            // retrieve photo count of current flight plan
            photoCount = mediaList
                .filter { $0.customId == activeFlightPlan.uuid && ($0.mediaType == .timeLapse || $0.mediaType == .gpsLapse) }
                .reduce(0, { $0 + $1.resources.count })
            ULog.d(.tag, "Retrieve \(photoCount) media for activeFlightPlan \(activeFlightPlan.uuid)")
            listenCamera(drone: drone, adjustPhotoCount: true)
            mediaListRef = nil
        }
    }

    /// Starts watcher for camera.
    ///
    /// - Parameters:
    ///   - drone: the current drone
    ///   - adjustPhotoCount: Tells if the photo count adjustment is needed
    func listenCamera(drone: Drone, adjustPhotoCount: Bool = false) {
        // reset capture and progress references on drone change
        photoCaptureRef = nil
        photoCaptureCount = 0

        cameraRef = drone.getPeripheral(Peripherals.mainCamera2) { [unowned self] camera in
            guard let camera = camera else { return }
            // update camera mode
            updateMode(withCamera: camera)
            updateSelectedValue(withCamera: camera)

            // listen photo capture component
            listenPhotoCapture(camera: camera, adjustPhotoCount: adjustPhotoCount)
        }
    }

    /// Listens to photo capture component.
    ///
    /// - Parameters:
    ///    - camera: the camera
    ///    - adjustPhotoCount: Tells if the photo count adjustment is needed
    func listenPhotoCapture(camera: Camera2, adjustPhotoCount: Bool) {
        // do not register photo capture observer if not needed
        guard photoCaptureRef?.value == nil else { return }

        var adjustPhotoCount = adjustPhotoCount
        photoCaptureRef = camera.getComponent(Camera2Components.photoCapture) { [unowned self] photoCapture in
            updateMode(withCamera: camera)
            guard let photoCaptureState = photoCapture?.state else { return }
            switch photoCaptureState {
            case .started(_, _, _, let captureCount, _):
                if adjustPhotoCount {
                    // substract to this photo count the number of current photo capture
                    // in order to not count them twice when displaying photo count
                    photoCount -= captureCount
                    ULog.d(.tag, "Adjust photo count to \(photoCount)")
                    adjustPhotoCount = false
                }
                photoCaptureCount = captureCount
                ULog.d(.tag, "Photo capture started: photoCount \(photoCount), photoCaptureCount \(photoCaptureCount)")
                updatePhotoCount(photoCount: photoCount + photoCaptureCount)
            case .stopped:
                // save last photo capture count if a flight plan is active.
                if activeExecutionWatcher.activeFlightPlan != nil {
                    photoCount += photoCaptureCount
                }
                photoCaptureCount = 0
                ULog.d(.tag, "Photo capture stopped: photoCount \(photoCount), photoCaptureCount \(photoCaptureCount)")
                updatePhotoCount(photoCount: photoCount + photoCaptureCount)
            default:
                break
            }
        }
    }

    /// Update state from camera mode.
    ///
    /// - Parameters:
    ///      - camera: current camera
    func updateMode(withCamera camera: Camera2) {
        let copy = state.value.copy()
        let currentCameraMode = CameraUtils.computeCameraMode(camera: camera)
        if camera.photoCapture?.state.isStarted == true {
            copy.isGpslapseInProgress = currentCameraMode == .gpslapse
            copy.isTimelapseInProgress = currentCameraMode == .timelapse
        } else {
            copy.isGpslapseInProgress = false
            copy.isTimelapseInProgress = false
        }
        state.set(copy)
    }

    /// Updates photo number during a timelapse and a gpslapse.
    ///
    /// - Parameters:
    ///     - photoCount: current photo count
    func updatePhotoCount(photoCount: Int) {
        guard state.value.isGpslapseInProgress || state.value.isTimelapseInProgress else { return }
        let copy = state.value.copy()
        copy.photosNumber = photoCount
        state.set(copy)
    }

    /// Updates selected value.
    ///
    /// - Parameters:
    ///     - camera: current camera
    func updateSelectedValue(withCamera camera: Camera2) {
        let copy = state.value.copy()
        switch CameraUtils.computeCameraMode(camera: camera) {
        case .timelapse:
            if let photoTimelapseInterval = camera.config[Camera2Params.photoTimelapseInterval]?.value {
                copy.selectedValue = photoTimelapseInterval
            }
        case .gpslapse:
            if let photoGpslapseInterval = camera.config[Camera2Params.photoGpslapseInterval]?.value {
                copy.selectedValue = photoGpslapseInterval
            }
        default:
            break
        }
        state.set(copy)
    }
}
