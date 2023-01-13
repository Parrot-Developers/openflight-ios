//    Copyright (C) 2022 Parrot Drones SAS
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
    static let tag = ULogTag(name: "StreamReplayService")
}

// MARK: - Protocol

/// The protocol defining the stream replay service.
public protocol StreamReplayService: AnyObject {

    /// The playback state publisher.
    var playStatePublisher: AnyPublisher<VideoPlayState, Never> { get }

    /// The duration publisher.
    var durationPublisher: AnyPublisher<TimeInterval?, Never> { get }

    /// The position publisher.
    var positionPublisher: AnyPublisher<TimeInterval?, Never> { get }

    /// The position.
    var position: TimeInterval? { get }

    /// Sets up stream replay for a specific media in a stream view.
    ///
    /// - Parameters:
    ///    - media: the media containing the resource to stream
    ///    - streamView: the view to stream the resource to
    func setupStreamReplay(for media: GalleryMedia, in streamView: StreamView)

    /// Requests active stream replay to start.
    /// - Returns: `true` if request has been successfully sent, `false` otherwise
    @discardableResult func play() -> Bool

    /// Requests active stream replay to pause.
    /// - Returns: `true` if request has been successfully sent, `false` otherwise
    @discardableResult func pause() -> Bool

    /// Requests active stream replay to toggle play/pause state.
    /// - Returns: `true` if request has been successfully sent, `false` otherwise
    @discardableResult func togglePlayPause() -> Bool

    /// Stops and detach active stream replay.
    func stop()

    /// Seeks to a specitifc time interval position.
    /// - Parameter position: the position to seek to (in seconds)
    func seekTo(_ position: TimeInterval)
}

// MARK: - Implementation

/// An implementation of the `StreamServerService` protocol.
public class StreamReplayServiceImpl {

    /// The cancellables.
    private var cancellables = Set<AnyCancellable>()
    /// The stream server reference.
    private var streamServerRef: Ref<StreamServer>?
    /// The stream server.
    private var streamServer: StreamServer?
    /// The camera recording service.
    private var cameraRecordingService: CameraRecordingService
    /// The media store service.
    private var mediaStoreService: MediaStoreService
    /// The replay reference.
    private var replayRef: Ref<MediaReplay>?
    /// The replay value.
    private var replay: MediaReplay? { replayRef?.value }
    /// The playback state subject.
    private var playStateSubject = CurrentValueSubject<VideoPlayState, Never>(.unavailable(.unknown))
    /// The playback state.
    private var playState: VideoPlayState {
        get { playStateSubject.value }
        set { playStateSubject.value = newValue }
    }
    /// The duration subject.
    private var durationSubject = CurrentValueSubject<TimeInterval?, Never>(nil)
    /// The duration.
    private var duration: TimeInterval? {
        get { durationSubject.value }
        set { durationSubject.value = newValue }
    }
    /// The position subject.
    private var positionSubject = CurrentValueSubject<TimeInterval?, Never>(nil)

    // MARK: Init
    /// Constructor.
    ///
    /// - Parameters:
    ///    - currentDroneHolder: the drone holder
    ///    - cameraRecordingService: the camera recording service
    ///    - mediaStoreService: the media store service
    init(currentDroneHolder: CurrentDroneHolder,
         cameraRecordingService: CameraRecordingService,
         mediaStoreService: MediaStoreService) {
        self.cameraRecordingService = cameraRecordingService
        self.mediaStoreService = mediaStoreService

        listen(to: currentDroneHolder)
        listen(to: cameraRecordingService)
        listen(to: mediaStoreService)
    }

    // MARK: Deinit
    deinit {
        streamServerRef = nil
        replayRef = nil
    }
}

// MARK: StreamServerService protocol conformance
extension StreamReplayServiceImpl: StreamReplayService {

    /// The playback state publisher.
    public var playStatePublisher: AnyPublisher<VideoPlayState, Never> { playStateSubject.eraseToAnyPublisher() }

    /// The duration publisher.
    public var durationPublisher: AnyPublisher<TimeInterval?, Never> { durationSubject.eraseToAnyPublisher() }

    /// The position publisher.
    public var positionPublisher: AnyPublisher<TimeInterval?, Never> { positionSubject.eraseToAnyPublisher() }

    /// The position.
    public var position: TimeInterval? { replay?.position }

    /// Sets up stream replay for a specific media in a stream view.
    ///
    /// - Parameters:
    ///    - media: the media containing the resource to stream
    ///    - streamView: the view to stream the resource to
    public func setupStreamReplay(for media: GalleryMedia, in streamView: StreamView) {
        guard let resource = media.mediaResources?.first,
              let source = MediaReplaySourceFactory.videoTrackOf(resource: resource, track: .defaultVideo) else { return }
        replayRef = streamServer?.replay(source: source) { [weak self] replay in
            self?.updateStream(replay: replay, in: streamView)
        }
    }

    /// Requests active stream replay start.
    /// - Returns: `true` if request has been successfully sent, `false` otherwise
    @discardableResult public func play() -> Bool {
        replay?.play() ?? false
    }

    /// Requests active stream replay to pause.
    /// - Returns: `true` if request has been successfully sent, `false` otherwise
    @discardableResult public func pause() -> Bool {
        replay?.pause() ?? false
    }

    /// Requests active stream replay to toggle play/pause state.
    /// - Returns: `true` if request has been successfully sent, `false` otherwise
    @discardableResult public func togglePlayPause() -> Bool {
        guard let replay = replay else { return false }
        return replay.playState == .playing ? replay.pause() : replay.play()
    }

    /// Stops and detach active stream replay.
    public func stop() {
        replay?.stop()
        replayRef = nil
    }

    /// Seeks to a specitifc time interval position.
    /// - Parameter position: the position to seek to (in seconds)
    public func seekTo(_ position: TimeInterval) {
        guard let replay = replay,
              position < replay.duration else { return }
        _ = replay.seekTo(position: position)
    }
}

// Peripherals and instruments listeners.
private extension StreamReplayServiceImpl {

    /// Listens to current drone holder.
    ///
    /// - Parameter currentDroneHolder: the current drone holder
    func listen(to currentDroneHolder: CurrentDroneHolder) {
        currentDroneHolder.dronePublisher
            .sink { [weak self] drone in
                self?.listenToStreamServer(drone: drone)
            }
            .store(in: &cancellables)
    }

    /// Listens to removable user storage.
    ///
    /// - Parameter drone: the current drone.
    func listenToStreamServer(drone: Drone) {
        streamServerRef = drone.getPeripheral(Peripherals.streamServer) { [weak self] streamServer in
            self?.streamServer = streamServer
        }
    }

    /// Listens to camera recording service in order to adapt UI to download/record limitations.
    ///
    /// - Parameter cameraRecordingService: the camera recording service
    func listen(to cameraRecordingService: CameraRecordingService) {
        cameraRecordingService.statePublisher
            .sink { [weak self] state in
                self?.updateAvailability(cameraRecordingState: state)
            }
            .store(in: &cancellables)
    }

    /// Listens to media store service.
    ///
    /// - Parameter mediaStoreService: the media store service
    func listen(to mediaStoreService: MediaStoreService) {
        mediaStoreService.isDownloadingPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDownloading in
                self?.updateAvailability(isDownloading: isDownloading)
            }
            .store(in: &cancellables)
    }

    /// Updates a stream replay in specified view.
    ///
    /// - Parameters:
    ///   - replay: the stream replay interface
    ///   - streamView: the view to attach the stream to
    func updateStream(replay: MediaReplay?, in streamView: StreamView) {
        // Attach stream to view. Has no effect if stream has already been attached.
        streamView.setStream(stream: replay)

        duration = replay?.duration
        playState = .init(from: replay,
                          cameraRecordingState: cameraRecordingService.state,
                          isDownloadTaskRunning: mediaStoreService.isDownloading)
    }

    /// Updates replay availability according to camera recording state.
    ///
    /// - Parameter cameraRecordingState: the camera recording state
    func updateAvailability(cameraRecordingState: Camera2RecordingState) {
        playState = .init(from: replay,
                          cameraRecordingState: cameraRecordingState,
                          isDownloadTaskRunning: mediaStoreService.isDownloading)
    }

    /// Updates replay availability according to ongoing download task state.
    ///
    /// - Parameter isDownloading: whether a download task is ongoing
    func updateAvailability(isDownloading: Bool) {
        playState = .init(from: replay,
                          cameraRecordingState: cameraRecordingService.state,
                          isDownloadTaskRunning: isDownloading)
    }
}
