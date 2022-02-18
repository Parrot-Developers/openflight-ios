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

import UIKit
import GroundSdk
import AVFoundation
import Combine

/// Gallery Video view controller.
final class GalleryVideoViewController: UIViewController, SwipableViewController {
    private weak var viewModel: GalleryMediaViewModel?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Outlets
    @IBOutlet private weak var previewImageView: UIImageView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var streamView: StreamView!
    @IBOutlet private weak var videoView: MediaVideoView!
    @IBOutlet private weak var playButton: UIButton!

    // MARK: - Internal Properties
    private(set) var index: Int = 0

    // MARK: - Private Properties
    private weak var coordinator: Coordinator?
    private var timer: Timer?
    private var mediaListener: GalleryMediaListener?
    private var videoGravity = AVLayerVideoGravity.resizeAspect

    // MARK: - Private Enums
    private enum Constants {
        static let timerInterval: TimeInterval = 0.1
        static let timeSeek: Double = 0.04
        static let preferredTimescale: CMTimeScale = 100
        static let fadeOut: Double = 1.0
        static let progressViewFullStyleBottomMargin: CGFloat = 12
    }

    // MARK: - Setup
    /// Instantiate view controller.
    ///
    /// - Parameters:
    ///     - coordinator: gallery coordinator
    ///     - viewModel: gallery view model
    ///     - index: Media index in the media array
    /// - Returns: a GalleryVideoViewController.
    static func instantiate(coordinator: Coordinator?,
                            viewModel: GalleryMediaViewModel?,
                            index: Int) -> GalleryVideoViewController {
        let viewController = StoryboardScene.GalleryMediaPlayerViewController.galleryVideoViewController.instantiate()
        viewController.coordinator = coordinator
        viewController.viewModel = viewModel
        viewController.index = index

        return viewController
    }

    // MARK: - Deinit
    deinit {
        viewModel?.unregisterListener(mediaListener)
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        updatePlayButton()
        initMediaPlayerViewModel()
        observeViewModel()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        stop()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        setupPreviewImage()
        stop()
        viewModel?.mediaBrowsingViewModel.didDisplayMedia(index: index, count: 1)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        start {
            self.viewModel?.videoPlay()
        }
    }

    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var prefersStatusBarHidden: Bool { true }

    func observeViewModel() {
        guard let mediaBrowsingViewModel = viewModel?.mediaBrowsingViewModel else { return }

        mediaBrowsingViewModel.$isVideoMuted
            .sink { [weak self] isMuted in
                self?.updateMuteState(isMuted)
            }
            .store(in: &cancellables)

        mediaBrowsingViewModel.$areControlsShown
            .combineLatest(mediaBrowsingViewModel.$isCameraRecording)
            .sink { [weak self] (areControlsShown, isCameraRecording) in
                self?.showControls(areControlsShown && !isCameraRecording)
            }
            .store(in: &cancellables)

        mediaBrowsingViewModel.$zoomLevel
            .sink { [weak self] zoomLevel in
                self?.updateZoomLevel(zoomLevel)
            }
            .store(in: &cancellables)
    }
}

// MARK: - Actions
private extension GalleryVideoViewController {
    @IBAction func playButtonTouchedUpInside(_ sender: AnyObject) {
        guard let viewModel = viewModel else { return }

        if !viewModel.videoIsPlaying(),
           viewModel.getVideoDuration() != 0,
           viewModel.getVideoPosition() == viewModel.getVideoDuration() {
            // We should reset video position to the beginning
            stop()
            start(completion: {
                viewModel.videoTogglePlayingStatus()
            })
        } else {
            viewModel.videoTogglePlayingStatus()
        }
    }
}

// MARK: - Private Funcs
private extension GalleryVideoViewController {
    func setupPreviewImage() {
        guard let viewModel = viewModel,
              let media = viewModel.getMedia(index: index) else {
                  return
              }

        let thumbnailViewModel = GalleryMediaThumbnailViewModel(media: media,
                                                                mediaStore: viewModel.mediaStore,
                                                                index: viewModel.getMediaImageDefaultIndex(media))
        thumbnailViewModel.getThumbnail { [weak self] image in
            self?.showPreviewImage(true)
            self?.previewImageView.image = image
        }
    }

    func showPreviewImage(_ show: Bool) {
        UIView.animate { self.previewImageView.alpha = show ? 1 : 0 }
    }

    func showControls(_ show: Bool) {
        playButton.animateIsHidden(!show)
    }

    /// Init media player view model.
    func initMediaPlayerViewModel() {
        guard let viewModel = viewModel else { return }
        mediaListener = viewModel.registerListener(didChange: { [unowned self] _ in
            updatePlayButton()
            showPreviewImage(viewModel.getVideoPosition() == 0)
        })

        viewModel.$downloadStatus
            .sink { [unowned self] status in
                if status == .running {
                    stop()
                    activityIndicator.startAnimating()
                } else {
                    start()
                    activityIndicator.stopAnimating()
                }
                updatePlayButton()
            }
            .store(in: &cancellables)
    }

    func updateMuteState(_ isMuted: Bool) {
        videoView.playerLayer?.player?.isMuted = isMuted
    }

    func updateZoomLevel(_ level: GalleryMediaBrowsingViewModel.ZoomLevel) {
        UIView.animate(withDuration: Style.shortAnimationDuration) {
            self.videoView.playerLayer?.videoGravity = level == .maximum
                ? .resizeAspectFill
                : .resizeAspect
        }
    }

    /// Update play button design from current player status.
    func updatePlayButton() {
        guard let viewModel = viewModel else { return }

        let image = viewModel.videoIsPlaying()
            ? Asset.Gallery.Player.buttonPauseBig.image
            : Asset.Gallery.Player.buttonPlayBig.image

        playButton.setImage(image, for: .normal)

        if !viewModel.videoIsPlaying() && viewModel.getVideoPosition() == viewModel.getVideoDuration() {
            // Show controls when video has reached end.
            viewModel.mediaBrowsingViewModel.didInteractForControlsDisplay(true)
        }
    }

    /// Configure streaming.
    ///
    /// - Parameters:
    ///    - completion: completion block
    func configureStreaming(completion: (() -> Void)? = nil) {
        streamView.isHidden = false
        streamView.renderingPaddingFill = .none
        videoView.isHidden = true
        viewModel?.videoSetStream(index: self.index) { replay in
            self.startReplay(replay)
            self.scheduledTimerWithTimeInterval()
            if let completion = completion {
                completion()
            }
        }
    }

    /// Configure video from url.
    ///
    /// - Parameters:
    ///    - url: media url
    func configureVideo(url: URL) {
        // Configure the player with the media's url.
        viewModel?.videoSetVideo(with: url)

        // Ensure the player layer exists.
        guard let playerLayer = viewModel?.deviceViewModel?.videoPlayerLayer else { return }

        // Remove the previous playerLayer if exists.
        videoView.playerLayer?.removeFromSuperlayer()

        // Setup the playerLayer.
        playerLayer.player?.seek(to: CMTime(seconds: Constants.timeSeek,
                                            preferredTimescale: Constants.preferredTimescale))
        playerLayer.needsDisplayOnBoundsChange = true

        // Display the video view.
        streamView.isHidden = true
        videoView.isHidden = false
        videoView.playerLayer = playerLayer
        videoView.layer.addSublayer(playerLayer)
        scheduledTimerWithTimeInterval()
    }

    /// Start replay configuration.
    ///
    /// - Parameters:
    ///    - replay: Replay
    func startReplay(_ replay: Replay?) {
        streamView.setStream(stream: replay)
    }

    /// Start playing configuration.
    ///
    /// - Parameters:
    ///    - completion: completion block
    func start(completion: (() -> Void)? = nil) {
        guard let viewModel = viewModel,
              viewModel.videoShouldReset(),
              let currentMedia = viewModel.getMedia(index: index),
        !Platform.isSimulator else {
            completion?()
            return
        }

        if let mediaUrl = currentMedia.url {
            configureVideo(url: mediaUrl)
            updateMuteState(viewModel.mediaBrowsingViewModel.isVideoMuted)
            completion?()
        } else {
            configureStreaming(completion: completion)
        }
    }

    /// Stop playing.
    func stop() {
        viewModel?.mediaBrowsingViewModel.didInteractForControlsDisplay(true)
        viewModel?.videoStop()
        streamView.setStream(stream: nil)
        timer?.invalidate()
        timer = nil
    }

    /// Scheduled timer to update.
    func scheduledTimerWithTimeInterval() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: Constants.timerInterval, repeats: true) { [weak self] _ in
            self?.viewModel?.videoUpdateState()
        }
    }
}

// MARK: - MediaVideoBottomBarViewDelegate
extension GalleryVideoViewController: MediaVideoBottomBarViewDelegate {
    func didUpdateSlider(newPositionValue: TimeInterval) {
        viewModel?.videoUpdatePosition(position: newPositionValue)
    }
}
