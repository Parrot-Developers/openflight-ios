//    Copyright (C) 2021 Parrot Drones SAS
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

import AVFoundation
import Combine

/// A class for gallery media browsing view.
final class GalleryMediaBrowsingViewModel {
    enum ZoomLevel {
        case minimum, maximum, custom
    }

    /// The state of gallery controls (shown if `true`, hidden else).
    @Published private(set) var areControlsShown = true
    /// The media loading state.
    @Published private(set) var isLoading = false
    /// The state of video sound (off if `true`, on else).
    @Published private(set) var isVideoMuted = true
    /// The recording state of drone's camera.
    @Published private(set) var isCameraRecording = false
    /// Whether drone's camera start recording is requested.
    @Published private(set) var isCameraRecordRequested = false
    /// The zoom level of the media displayed.
    @Published private(set) var zoomLevel = ZoomLevel.minimum
    /// The index of the media to display.
    @Published private(set) var mediaIndex = 0
    /// The index of the resource to display.
    @Published private(set) var resourceIndex = 0
    /// The number of resources of displayed media.
    @Published private(set) var resourcesCount = 0
    /// The panorama generation status.
    @Published private(set) var panoramaGenerationStatus: GalleryPanoramaStepStatus = .inactive

    /// The image to display for sound state.
    var videoSoundButtonImage: UIImage? {
        isVideoMuted
            ? Asset.Gallery.Player.icSoundOff.image
            : Asset.Gallery.Player.icSoundOn.image
    }

    private var cancellables = Set<AnyCancellable>()

    init(cameraRecordingService: CameraRecordingService) {
        cameraRecordingService.statePublisher
            .sink { [unowned self] state in
                switch state {
                case .starting:
                    isCameraRecordRequested = true
                    isCameraRecording = false
                case .started:
                    isCameraRecording = true
                    isCameraRecordRequested = false
                case .stopping, .stopped:
                    isCameraRecording = false
                    isCameraRecordRequested = false
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Model State Update

    /// Updates mute state.
    func didTapSoundButton() {
        isVideoMuted.toggle()
    }

    /// Updates controls showing state.
    ///
    /// - Parameters:
    ///   - show: Controls are shown if `true`, hidden else.
    func didInteractForControlsDisplay(_ show: Bool? = nil) {
        if let show = show {
            areControlsShown = show
        } else {
            areControlsShown.toggle()
        }
    }

    /// Updates zoom level.
    ///
    /// - Parameters:
    ///   - level: The zoom level to configure.
    func didUpdateZoomLevel(_ level: ZoomLevel) {
        zoomLevel = level
    }

    /// Toggles zoom level after a double tap and hide controls if needed.
    func didInteractForDoubleTapZoom() {
        zoomLevel = zoomLevel == .minimum
            ? .maximum
            : .minimum

        areControlsShown = zoomLevel == .minimum
    }

    /// Updates media info (indexes and urls array).
    ///
    /// - Parameters:
    ///   - media: The displayed media.
    ///   - index: The index of the displayed media.
    ///   - count: The number of resources of the displayed media.
    func didDisplayMedia(_ media: GalleryMedia? = nil,
                         index: Int,
                         count: Int) {
        mediaIndex = index
        resourcesCount = count
    }

    /// Updates resource index.
    ///
    /// - Parameters:
    ///   - index: The index of the displayed resource.
    func didDisplayResourceAt(_ index: Int) {
        resourceIndex = index
    }

    /// Updates loading state.
    ///
    /// - Parameter isLoading: `true` if current media is still loading, `false` otherwise
    func didUpdateLoadingState(isLoading: Bool) {
        self.isLoading = isLoading
    }

    /// Updates panorama generation status.
    ///
    /// - Parameters:
    ///   - status: The panorama generation status to update.
    func didUpdatePanoramaGeneration(_ status: GalleryPanoramaStepStatus) {
        panoramaGenerationStatus = status
    }
}
