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

/// State for `OccupancyViewModel`.

final class OccupancyState: ViewModelState, EquatableState, Copying {
    // MARK: - Internal Properties
    /// Current stream server enabled state.
    fileprivate(set) var streamEnabled: Bool = false
    fileprivate(set) var origin = [Float32](repeating: 0, count: 3)
    fileprivate(set) var quaternion = [Float32](repeating: 0, count: 4)
    fileprivate(set) var speedVector = vector3(Float32(0), Float32(0), Float32(0))
    fileprivate(set) var isDroneStationary = true

    // MARK: - Init
    required init() { }

    /// Init.
    ///
    /// - Parameters:
    ///    - streamEnabled: stream server enable state
    init(streamEnabled: Bool) {
        self.streamEnabled = streamEnabled
    }

    // MARK: - Internal Funcs
    func isEqual(to other: OccupancyState) -> Bool {
        // State should always get updated to avoid issues
        // with updates while stream view is not visible.
        return false
    }

    /// Returns a copy of the object.
    func copy() -> OccupancyState {
        let copy = OccupancyState(
            streamEnabled: self.streamEnabled
        )
        return copy
    }
}

/// ViewModel for occupancy.
final class OccupancyViewModel: DroneWatcherViewModel<OccupancyState> {

    // MARK: - Private Properties
    private var streamServerRef: Ref<StreamServer>?
    private var cameraLiveRef: Ref<CameraLive>?
    private var sink: StreamSink?
    private var isMonitoring: Bool = false
    private var worldStorage: VoxelStorageCore
    private var loveVideo: FileReplayCore?
    private var missedFrames = 0
    private var dropFrameTrigger = 1
    private var currentFrameCount = 0
    /// Queue to process frames
    private var sdkCoreFrameProcessQueue = DispatchQueue(label: "com.occupancy.framequeue", qos: .userInteractive)
    private var sdkCoreFrameProcessSemaphore = DispatchSemaphore(value: 1)

    /// MoserAPI singleton
    private var moserAPI: MoserAPI? {
        return MoserAPI.sharedMoserAPI() as? MoserAPI
    }

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///     - worldStorage: voxel storage
    init(worldStorage: VoxelStorageCore) {
        self.worldStorage = worldStorage

        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .allDomainsMask).first

        if let pathComponent = documentDirectory?.appendingPathComponent("love.mp4") {
            if fileManager.fileExists(atPath: pathComponent.path) {
                loveVideo = FileReplayCore(source: FileSourceCore(file: pathComponent, track: .defaultVideo))
            }
        }

        super.init()
    }

    // MARK: - Deinit
    deinit {
        self.stopImageProcessing()
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        /// If monitoring is already enabled, reset it for drone change.
        if self.isMonitoring {
            self.enableMonitoring(false)
            self.enableMonitoring(true)
        }
    }

    // MARK: - Internal Funcs
    /// Enables or disables the live monitoring of the stream.
    ///
    /// - Parameters:
    ///    - enabled: whether live should be enabled
    func enableMonitoring(_ enabled: Bool) {
        isMonitoring = enabled

        if enabled, let drone = drone {
            if !drone.isConnected, let video = loveVideo {
                listenVideo(video)
            } else {
                listenStreamServer(drone: drone)
            }
        } else {
            stopImageProcessing()
        }
    }
}

// MARK: - Private Funcs
private extension OccupancyViewModel {

    /// Starts watcher for stream server state.
    func listenStreamServer(drone: Drone) {
        streamServerRef = drone.getPeripheral(Peripherals.streamServer) { [weak self] streamServer in

            guard let strongStreamServer = streamServer,
                strongStreamServer.enabled else {
                    // Avoid issues when dismissing App and returning on it.
                    self?.cameraLiveRef = nil
                    self?.sink = nil
                    return
            }

            self?.cameraLiveRef = strongStreamServer.live(source: CameraLiveSource.disparity) { [weak self] liveStream in
                guard let strongSelf = self,
                    let strongLiveStream = liveStream,
                    strongSelf.sink == nil else {
                        return
                }

                strongSelf.sink = strongLiveStream.openYuvSink(queue: DispatchQueue.main, listener: strongSelf)
                _ = liveStream?.play()
            }
        }
    }

    func listenVideo(_ video: FileReplayCore) {
        sink = video.openYuvSink(queue: DispatchQueue.main, listener: self)
        _ = video.play()
    }

    /// Updates stream enabled state.
    func updateStreamEnabled(_ enabled: Bool) {
        let copy = state.value.copy()
        copy.streamEnabled = enabled
        state.set(copy)
    }

    /// Update voxel info from drone.
    func voxelStatusDidUpdate() {
        state.set(state.value)
    }

    /// Clear every variables of the view model.
    func stopImageProcessing() {
        self.streamServerRef = nil
        self.cameraLiveRef = nil
        self.sink = nil
    }
}

// MARK: - YuvSinkListener
extension OccupancyViewModel: YuvSinkListener {
    func didStart(sink: StreamSink) {}
    func didStop(sink: StreamSink) {}

    func frameReady(sink: StreamSink, frame: SdkCoreFrame) {
        guard let metadataProtobuf = frame.metadataProtobuf
            else { return }

        do {
            // Handle telemetry
            let decodedInfo = try Vmeta_TimedMetadata(serializedData: metadataProtobuf)
            let loveQuat: Vmeta_Quaternion = decodedInfo.camera.quat
            var timestampNs: UInt64 = decodedInfo.camera.timestamp * 1000

            if timestampNs == 0 {
                timestampNs = UInt64(Date().timeIntervalSinceReferenceDate * 1000000000)
            }

            self.state.value.quaternion = [
                decodedInfo.drone.quat.w,
                decodedInfo.drone.quat.x,
                decodedInfo.drone.quat.y,
                decodedInfo.drone.quat.z]
            self.state.value.isDroneStationary = decodedInfo.drone.flyingState == .fsHovering

            self.state.value.speedVector = vector3(decodedInfo.drone.speed.east, decodedInfo.drone.speed.down, decodedInfo.drone.speed.north)

            if let droneOrigin = self.worldStorage.gridOrigin {
                self.state.value.origin = [
                    self.worldStorage.center.x + (droneOrigin.y - decodedInfo.drone.position.east) / Occupancy.voxelRealSize,
                    self.worldStorage.center.y + (droneOrigin.z - decodedInfo.drone.position.down) / Occupancy.voxelRealSize,
                    self.worldStorage.center.z + (decodedInfo.drone.position.north - droneOrigin.x) / Occupancy.voxelRealSize
                ]
            } else {
                self.state.value.origin = [
                    self.worldStorage.center.x,
                    self.worldStorage.center.y,
                    self.worldStorage.center.z
                ]
            }
            var origin: [Float32] = [
                decodedInfo.drone.position.north,
                decodedInfo.drone.position.east,
                decodedInfo.drone.position.down
            ]
            var quaternion: [Float32] = [loveQuat.w, loveQuat.x, loveQuat.y, loveQuat.z]
            self.voxelStatusDidUpdate()

            let doUpdateWorld = (currentFrameCount % dropFrameTrigger) == 0
            if self.sdkCoreFrameProcessSemaphore.wait(timeout: DispatchTime.now()) == .success {
                missedFrames = 0
                self.sdkCoreFrameProcessQueue.async {
                    // If available, update moser occupancy grid
                    if self.moserAPI?.processFrame(
                        frame.mbufFrame,
                        quaternion: quaternion.cPtr,
                        origin: origin.cPtr,
                        timestampNs: timestampNs) == EXIT_SUCCESS {
                        if doUpdateWorld {
                            self.moserAPI?.updateStorage(self.worldStorage)
                        }
                    }
                    self.sdkCoreFrameProcessSemaphore.signal()
                }
            } else {
                missedFrames += 1
                if missedFrames > (dropFrameTrigger - 1) && dropFrameTrigger < Occupancy.Storage.maxDropFrameForUpdate {
                    dropFrameTrigger += 1
                    missedFrames = 0
                }
            }
            currentFrameCount += 1
        } catch {}
    }
}
