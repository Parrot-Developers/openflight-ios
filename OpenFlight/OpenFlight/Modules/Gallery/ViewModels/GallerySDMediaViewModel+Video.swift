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

/// Gallery SD Media ViewModel video functions.

// MARK: - Internal Funcs
extension GallerySDMediaViewModel: GalleryVideoCompatible {

    func getVideoDuration() -> TimeInterval {
        guard let streamingCurrentReplay = streamingCurrentReplay else { return 0 }
        return streamingCurrentReplay.duration
    }

    func getVideoPosition() -> TimeInterval {
        guard let streamingCurrentReplay = streamingCurrentReplay else { return 0 }
        return streamingCurrentReplay.position
    }

    func getVideoState() -> VideoState {
        guard let streamingCurrentReplay = streamingCurrentReplay else { return .none }
        return convertToVideoState(streamingCurrentReplay.playState)
    }

    func videoPlay() -> Bool {
        guard let streamingCurrentReplay = streamingCurrentReplay else { return false }
        return streamingCurrentReplay.play()
    }

    func videoPause() -> Bool {
        guard let streamingCurrentReplay = streamingCurrentReplay else { return false }
        return streamingCurrentReplay.pause()
    }

    func videoStop() {
        streamingCurrentReplay?.stop()
        if streamingMediaReplayRef != nil {
            streamingMediaReplayRef = nil
        }
    }

    func videoIsPlaying() -> Bool {
        return streamingReplayState == .playing
    }

    func videoUpdatePosition(position: TimeInterval) -> Bool {
        guard let streamingCurrentReplay = streamingCurrentReplay,
              position < streamingCurrentReplay.duration else {
            return false
        }

        return streamingCurrentReplay.seekTo(position: position)
    }

    func videoTogglePlayingStatus() {
        _ = streamingCurrentReplay?.playState == .playing ? videoPause() : videoPlay()
    }

    func videoUpdateState() {
    }

    func videoShouldReset() -> Bool {
        return streamingMediaReplayRef == nil
    }
}

extension GallerySDMediaViewModel {
    /// Configure streaming with resource.
    ///
    /// - Parameters:
    ///    - resource: Resource to stream
    ///    - completion: Completion called when mediaReplay is instantiated
    func setStreamFromResource(_ resource: MediaItem.Resource,
                               completion: @escaping (_ replay: Replay?) -> Void) {
        guard let drone = self.drone,
              let source = MediaReplaySourceFactory.videoTrackOf(resource: resource,
                                                                 track: streamingDefaultTrack)
        else {
            completion(nil)
            return
        }

        streamingCurrentResource = resource
        drone.getPeripheral(Peripherals.streamServer)?.enabled = true
        streamingMediaReplayRef = drone.getPeripheral(Peripherals.streamServer)?.replay(source: source) { _ in }
        completion(streamingMediaReplayRef?.value)
    }

    /// Convert replay play state (used for streaming) to video state.
    ///
    /// - Parameters:
    ///    - replayPlayState: replay play state
    /// - Returns: video state
    func convertToVideoState(_ replayPlayState: ReplayPlayState?) -> VideoState {
        switch replayPlayState {
        case .playing:
            return VideoState.playing
        case .paused:
            return VideoState.paused
        default:
            return VideoState.none
        }
    }

    /// Convert video state to replay play state (used for streaming).
    ///
    /// - Parameters:
    ///    - videoState: video state
    /// - Returns: replay play state
    func convertToReplayPlayState(_ videoState: VideoState?) -> ReplayPlayState {
        switch videoState {
        case .playing:
            return ReplayPlayState.playing
        case .paused:
            return ReplayPlayState.paused
        default:
            return ReplayPlayState.none
        }
    }
}
