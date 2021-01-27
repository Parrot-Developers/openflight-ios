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
import AVFoundation

// MARK: - Internal Funcs
/// Gallery Device Media ViewModel video functions.
extension GalleryDeviceMediaViewModel: GalleryVideoCompatible {

    func getVideoDuration() -> TimeInterval {
        guard let videoPlayer = videoPlayer else { return 0 }
        return videoPlayer.currentItem?.asset.duration.seconds ?? 0
    }

    func getVideoPosition() -> TimeInterval {
        guard let videoPlayer = videoPlayer else { return 0 }
        return videoPlayer.currentTime().seconds
    }

    func getVideoState() -> VideoState {
        guard videoPlayer != nil else { return .none }
        return videoIsPlaying() ? .playing : .paused
    }

    func videoPlay(index: Int) -> Bool {
        guard let videoPlayer = videoPlayer else { return false }
        videoPlayer.play()
        return true
    }

    func videoPause() -> Bool {
        guard let videoPlayer = videoPlayer else { return false }
        videoPlayer.pause()
        return true
    }

    func videoStop() {
        videoPlayer = nil
    }

    func videoIsPlaying() -> Bool {
        guard let videoPlayer = videoPlayer else { return false }
        return videoPlayer.rate != 0 && videoPlayer.error == nil
    }

    func videoUpdatePosition(position: TimeInterval) -> Bool {
        guard let videoPlayer = videoPlayer,
            let asset = videoPlayer.currentItem?.asset
            else {
                return false
        }
        let time = CMTimeMakeWithSeconds(position, preferredTimescale: asset.duration.timescale)
        videoPlayer.seek(to: time)
        return true
    }

    func videoTogglePlayingStatus() {
        guard let videoPlayer = videoPlayer else { return }
        videoIsPlaying() ? videoPlayer.pause() : videoPlayer.play()
    }

    func videoUpdateState() {
    }

    func videoShouldReset() -> Bool {
        return videoPlayer == nil
    }
}
