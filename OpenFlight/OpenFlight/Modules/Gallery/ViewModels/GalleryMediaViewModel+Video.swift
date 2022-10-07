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
import AVFoundation

// MARK: - Protocols
/// Protocol describing video compatible view model interface.
protocol GalleryVideoCompatible {

    /// Get the video duration.
    ///
    /// - Returns: video duration
    func getVideoDuration() -> TimeInterval

    /// Get the video current position.
    ///
    /// - Returns: video position
    func getVideoPosition() -> TimeInterval

    /// Get the video current state.
    ///
    /// - Returns: video state
    func getVideoState() -> VideoState

    /// Triggered when we ask to play the video.
    ///
    /// - Returns: boolean for success.
    func videoPlay() -> Bool

    /// Triggered when we ask to pause the video.
    ///
    /// - Returns: boolean for success
    func videoPause() -> Bool

    /// Triggered when we ask to stop the video.
    func videoStop()

    /// Determine if the video is playing.
    ///
    /// - Returns: boolean for playing
    func videoIsPlaying() -> Bool

    /// Triggered when we ask to change position in the video.
    ///
    /// - Parameters:
    ///    - position: desired position
    /// - Returns: boolean for success.
    func videoUpdatePosition(position: TimeInterval) -> Bool

    /// Triggered when we want to toggle the playing status of the video.
    func videoTogglePlayingStatus()

    /// Triggered when we want to get a state update on the video.
    func videoUpdateState()

    /// Determine if the we can reset the video setup.
    ///
    /// - Returns: boolean
    func videoShouldReset() -> Bool
}

/// Gallery Media ViewModel video functions.

// MARK: - Internal Funcs
extension GalleryMediaViewModel: GalleryVideoCompatible {

    func getCurrentViewModel() -> GalleryVideoCompatible? {
        switch sourceType {
        case .droneSdCard:
            return sdCardViewModel
        case .droneInternal:
            return internalViewModel
        case .mobileDevice:
            return deviceViewModel
        default:
            return nil
        }
    }

    func getVideoDuration() -> TimeInterval {
        return getCurrentViewModel()?.getVideoDuration() ?? 0
    }

    func getVideoPosition() -> TimeInterval {
        return getCurrentViewModel()?.getVideoPosition() ?? 0
    }

    func getVideoState() -> VideoState {
        return getCurrentViewModel()?.getVideoState() ?? .none
    }

    @discardableResult func videoPlay() -> Bool {
        return getCurrentViewModel()?.videoPlay() ?? false
    }

    @discardableResult func videoPause() -> Bool {
        return getCurrentViewModel()?.videoPause() ?? false
    }

    func videoStop() {
        getCurrentViewModel()?.videoStop()
    }

    func videoIsPlaying() -> Bool {
        return getCurrentViewModel()?.videoIsPlaying() ?? false
    }

    @discardableResult func videoUpdatePosition(position: TimeInterval) -> Bool {
        return getCurrentViewModel()?.videoUpdatePosition(position: position) ?? false
    }

    func videoTogglePlayingStatus() {
        // Rewind if player is stopped at the end of video (can be true only if video is not playing).
        if isStoppedAtEnd {
            rewind()
        }
        getCurrentViewModel()?.videoTogglePlayingStatus()
    }

    /// Whether player has reached the end of video.
    var hasReachedEnd: Bool {
        guard let viewModel = getCurrentViewModel() else { return false }
        let duration = viewModel.getVideoDuration()
        guard duration > 0 else { return false }
        return viewModel.getVideoPosition() >= duration
    }

    /// Whether player is stopped at the end of video.
    var isStoppedAtEnd: Bool {
        guard let viewModel = getCurrentViewModel() else { return false }
        return !viewModel.videoIsPlaying() && hasReachedEnd
    }

    /// Rewinds the player to position 0.
    func rewind() {
        _ = getCurrentViewModel()?.videoUpdatePosition(position: 0)
    }

    func videoUpdateState() {
        guard let videoDuration = getCurrentViewModel()?.getVideoDuration(),
            let videoPosition = getCurrentViewModel()?.getVideoPosition(),
            let videoState = getCurrentViewModel()?.getVideoState(),
            (
                videoDuration != self.state.value.videoDuration
                    || videoPosition != self.state.value.videoPosition
                    || videoState != self.state.value.videoState
            ) else {
                return
        }

        let copy = self.state.value.copy()
        copy.videoDuration = videoDuration
        copy.videoPosition = videoPosition
        copy.videoState = videoState
        self.state.set(copy)
    }

    func videoShouldReset() -> Bool {
        getCurrentViewModel()?.videoShouldReset() ?? true
    }
}

extension GalleryMediaViewModel {
    /// Setup the video player for local video.
    ///
    /// - Parameters:
    ///    - index: Media index in the gallery media array page
    func videoSetVideo(index: Int) {
        guard let media = getMedia(index: index),
            let mediaUrl = media.url else { return }
        videoSetVideo(with: mediaUrl)
    }

    /// Setup the video player with for a media's url.
    ///
    /// - Parameters:
    ///    - url: The media's URL.
    func videoSetVideo(with url: URL) {
        deviceViewModel?.videoPlayer = AVPlayer(url: url)
    }

    // TODO: Remove all unnecessary completion blocks for synchronous methods.
    /// Setup the video player for streaming.
    ///
    /// - Parameters:
    ///    - index: Media index in the gallery media array page
    ///    - completion: completion block
    func videoSetStream(index: Int, completion: @escaping (_ replay: Replay?) -> Void) {
        guard let media = getMedia(index: index),
              let firstResource = media.mediaResources?.first else {
                  completion(nil)
                  return
              }

        switch sourceType {
        case .droneSdCard:
            sdCardViewModel?.setStreamFromResource(firstResource, completion: completion)
        case .droneInternal:
            internalViewModel?.setStreamFromResource(firstResource, completion: completion)
        default:
            completion(nil)
        }
    }
}
