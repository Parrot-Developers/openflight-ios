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

import Combine
import GroundSdk
import AVKit

/// A reason for the unavailability of the video player.
public enum VideoPlayerUnavailabilityReason: Equatable {

    /// Player has no known state.
    case unknown
    /// A download task is ongoing.
    case ongoingDownload
    /// A camera recording is ongoing.
    case ongoingCameraRecording

    /// The icon corresponding to the unavailability reason.
    var icon: UIImage? {
        switch self {
        case .ongoingDownload,
                .ongoingCameraRecording:
            return Asset.BottomBar.CameraModes.icCameraModeVideo.image
        case .unknown:
            return nil
        }
    }

    /// The information message to display describing the unavailability reason.
    var message: String? {
        switch self {
        case .ongoingDownload:
            return L10n.galleryPlaybackNotPossibleDownload
        case .ongoingCameraRecording:
            return L10n.galleryPlaybackNotPossibleRecording
        case .unknown:
            return nil
        }
    }
}

/// Video play states.
public enum VideoPlayState: Hashable {

    /// No known play state, player unavailable.
    case unavailable(VideoPlayerUnavailabilityReason)
    /// Video is playing.
    case playing
    /// Video is paused.
    case paused
    /// Video is paused and has reached its end.
    case ended

    /// The icon of the player Play button.
    var playButtonIcon: UIImage? {
        switch self {
        case .unavailable: return nil
        case .playing: return Asset.Gallery.Player.buttonPauseBig.image
        case .paused: return Asset.Gallery.Player.buttonPlayBig.image
        case .ended: return Asset.Gallery.Player.buttonResetBig.image
        }
    }

    // MARK: Init
    /// Constructor. Builds a video play state according to SDK replay states.
    ///
    /// - Parameters:
    ///    - playState: the replay play state
    ///    - position: the replay position
    ///    - duration: the replay duration
    init(from playState: ReplayPlayState,
         position: TimeInterval?,
         duration: TimeInterval?) {
        guard let position = position, let duration = duration else {
            self = .unavailable(.unknown)
            return
        }
        switch playState {
        case .playing:
            self = .playing
        case .none, .paused:
            self = duration > 0 && position >= duration ? .ended : .paused
        }
    }

    /// Constructor. Builds a video play state according to a media replay.
    ///
    /// - Parameters:
    ///   - replay: the media replay
    ///   - cameraRecordingState: the camera recording state
    ///   - isDownloadRunning: whether a download task is running
    init(from replay: MediaReplay?,
         cameraRecordingState: Camera2RecordingState?,
         isDownloadTaskRunning: Bool) {
        if case .started = cameraRecordingState {
            // Trying to init a replay with an ongoing camera recording
            // => Set state to unavailable with corresponding reason.
            self = .unavailable(.ongoingCameraRecording)
            return
        }

        if isDownloadTaskRunning {
            // Trying to init a replay with an ongoing download task
            // => Set state to unavailable with corresponding reason.
            self = .unavailable(.ongoingDownload)
            return
        }

        guard let replay = replay else {
            // No replay => unknown state.
            self = .unavailable(.unknown)
            return
        }

        // Init video play state with replay states.
        self.init(from: replay.playState, position: replay.position, duration: replay.duration)
    }

    /// Toggles play/pause states.
    mutating func toggle() {
        switch self {
        case .unavailable: break
        case .playing: self = .paused
        case .paused, .ended: self = .playing
        }
    }

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .unavailable(let reason):
            hasher.combine(reason)
        default:
            break
        }
    }
}

/// A video aspect.
enum VideoAspect {

    /// Video fits screen.
    case fit
    /// Video fills screen.
    case fill

    /// Toggles current aspect.
    mutating func toggle() {
        self = self == .fit ? .fill : .fit
    }

    /// The stream view scale type according to video aspect.
    var streamScaleType: StreamView.ScaleType {
        self == .fit ? .fit : .crop
    }

    /// The AV player gravity according to video aspect.
    var avPlayerGravity: AVLayerVideoGravity {
        self == .fit ? .resizeAspect : .resizeAspectFill
    }
}

/// A video player view model.
final class VideoPlayerViewModel {

    /// The published media to play.
    @Published private(set) var media: GalleryMedia
    /// The player play state.
    @Published private(set) var playState: VideoPlayState = .unavailable(.unknown)
    /// The video duration (in seconds).
    @Published private(set) var duration: TimeInterval?
    /// The video position (in seconds).
    @Published private(set) var position: TimeInterval?
    /// The video aspect.
    @Published private(set) var aspect: VideoAspect = .fit
    /// Whether the playback is available.
    @Published private(set) var isPlaybackAvailable = true
    /// Whether bottom bar needs extra padding.
    /// (May be needed in case seekbar is available and download progress view is displayed.)
    @Published private(set) var bottomBarNeedsPadding = false
    /// The publisher for a video recording denial.
    var didDenyRecordingPublisher: AnyPublisher<Void, Never> { didDenyRecordingSubject.eraseToAnyPublisher() }

    /// The cancellables.
    private var cancellables = Set<AnyCancellable>()
    /// The AV player (for local videos).
    private var avPlayer: AVPlayer?
    /// The stream replay service.
    private var streamReplayService: StreamReplayService
    /// The recording denial subject.
    private var didDenyRecordingSubject = PassthroughSubject<Void, Never>()

    // MARK: Init
    /// Constructor.
    ///
    /// - Parameters:
    ///    - streamReplayService: the stream replay service
    ///    - cameraRecordingService: the camera recording service
    ///    - mediaStoreService: the media store service
    ///    - media: the media to play
    init(streamReplayService: StreamReplayService,
         cameraRecordingService: CameraRecordingService,
         mediaStoreService: MediaStoreService,
         media: GalleryMedia) {
        self.streamReplayService = streamReplayService
        self.media = media

        if media.source.isDroneSource {
            listen(to: streamReplayService)
            listen(to: cameraRecordingService)
        } else {
            listen(to: mediaStoreService)
            listenToAvPlayerEndNotification()
        }
    }

    deinit {
        removeNotificationObserver()
    }

    /// Sets up AV player in specified view.
    ///
    /// - Parameter view: the view to attach the AV player to
    func setupAvPlayer(in view: AVPlayerView) {
        guard let url = media.url else { return }
        view.setupPlayer(url: url)
        avPlayer = view.player
        duration = avPlayer?.duration
    }

    /// Sets up stream replay in specified view.
    ///
    /// - Parameter view: the view to attach the stream replay to
    func setupStreamReplay(in view: StreamView) {
        // Always stop potentially running stream replay before setting up a new one.
        streamReplayService.stop()
        streamReplayService.setupStreamReplay(for: media, in: view)
    }

    /// Removes any stream attached to specified stream view.
    ///
    /// - Parameter streamView: the stream view to remove any stream from
    func detachStream(from streamView: StreamView) {
        // Stop replay on stream detach in order to ensure stream is released.
        streamView.setStream(stream: nil)
    }

    /// Starts active video playing.
    func playVideo() {
        if media.source.isDroneSource {
            streamPlay()
        } else {
            avPlay()
        }
    }

    /// Pauses active video.
    func pauseVideo() {
        if media.source.isDroneSource {
            streamPause()
        } else {
            avPause()
        }
    }

    /// Toggles play/pause state.
    func togglePlayPause() {
        if media.source.isDroneSource {
            streamTogglePlayPause()
        } else {
            avTogglePlayPause()
        }
    }

    /// Toggles video aspect because of a double tap detection.
    func didDoubleTap() {
        aspect.toggle()
    }

    /// Sets mute state.
    ///
    /// - Parameter isMuted: the mute state to set
    func setMuted(_ isMuted: Bool) {
        guard media.source.isDeviceSource else { return }
        avPlayer?.isMuted = isMuted
    }

    /// Seeks to a specitifc time interval position.
    ///
    /// - Parameter position: the position to seek to (in seconds)
    func seekTo(_ position: TimeInterval) {
        if media.source.isDroneSource {
            streamSeekTo(position)
        } else {
            avSeekTo(position)
        }
    }

    /// Refreshes video position according to player state.
    func refreshPosition() {
        if media.source.isDroneSource {
            position = streamReplayService.position
        } else {
            position = avPlayer?.position
        }
    }
}

// MARK: - Stream Replay
private extension VideoPlayerViewModel {

    /// Listens to stream replay service and updates player states accordingly.
    ///
    /// - Parameter streamReplayService: the stream replay service
    func listen(to streamReplayService: StreamReplayService) {
        streamReplayService.playStatePublisher.removeDuplicates().sink { [weak self] state in
            self?.playState = state
        }
        .store(in: &cancellables)

        streamReplayService.durationPublisher.removeDuplicates().sink { [weak self] duration in
            self?.duration = duration
        }
        .store(in: &cancellables)

        streamReplayService.positionPublisher.removeDuplicates().sink { [weak self] position in
            self?.position = position
        }
        .store(in: &cancellables)
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

    /// Requests active stream to play.
    func streamPlay() {
        streamReplayService.play()
    }

    /// Requests active stream to pause.
    func streamPause() {
        streamReplayService.pause()
    }

    /// Toggles active stream play/pause state.
    func streamTogglePlayPause() {
        streamReplayService.togglePlayPause()
    }

    /// Seeks active stream to specified position.
    ///
    /// - Parameter position: the position to seek to (in seconds)
    func streamSeekTo(_ position: TimeInterval) {
        streamReplayService.seekTo(position)
    }
}

// MARK: - AV Player
private extension VideoPlayerViewModel {

    /// Starts AV player and upates `playState` accordingly.
    func avPlay() {
        guard let player = avPlayer, playState != .playing else { return }
        if playState == .ended {
            avSeekTo(0)
        }
        player.play()
        playState = .playing
    }

    /// Pauses AV player and updates `playState` accordingly.
    func avPause() {
        guard let player = avPlayer, playState == .playing else { return }
        player.pause()
        updateAvPauseState()
    }

    /// Toggles AV play/pause state and updates `playState` accordingly.
    func avTogglePlayPause() {
        guard let player = avPlayer else { return }
        player.isPlaying ? avPause() : avPlay()
    }

    /// Seeks AV player to specified position.
    ///
    /// - Parameter position: the position to seek to (in seconds)
    func avSeekTo(_ position: TimeInterval) {
        guard let player = avPlayer,
              let asset = player.currentItem?.asset else { return }

        let time = CMTimeMakeWithSeconds(position, preferredTimescale: asset.duration.timescale)
        player.seek(to: time)
        if playState != .playing {
            updateAvPauseState()
        }
    }

    /// Updates AV player state after end has been reached.
    @objc func avPlayerDidEnd() {
        avPlayer?.pause()
        updateAvPauseState()
    }

    /// Updates AV playser pause state according to current position and duration.
    func updateAvPauseState() {
        guard let position = avPlayer?.position,
              let duration = avPlayer?.duration else {
            playState = .unavailable(.unknown)
            return
        }
        playState = .init(from: .paused,
                          position: position,
                          duration: duration)
    }

    /// Updates replay availability according to camera recording state.
    ///
    /// - Parameter cameraRecordingState: the camera recording state
    func updateAvailability(cameraRecordingState: Camera2RecordingState) {
        if case .starting = cameraRecordingState {
            // Recording has been requested and replay is ongoing => send recording denial info.
            didDenyRecordingSubject.send()
        }
    }

    /// Listens to media store service.
    ///
    /// - Parameter mediaStoreService: the media store service
    func listen(to mediaStoreService: MediaStoreService) {
        mediaStoreService.isDownloadingPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDownloading in
                self?.bottomBarNeedsPadding = isDownloading
            }
            .store(in: &cancellables)
    }

    /// Listens to AV player end notification.
    func listenToAvPlayerEndNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(avPlayerDidEnd),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: nil)
    }

    /// Removes notification observer.
    func removeNotificationObserver() {
        NotificationCenter.default.removeObserver(self)
    }
}
