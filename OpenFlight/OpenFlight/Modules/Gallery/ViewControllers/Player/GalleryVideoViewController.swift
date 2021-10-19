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

import UIKit
import GroundSdk
import AVFoundation
import Combine

/// Gallery Video view controller.
final class GalleryVideoViewController: UIViewController, SwipableViewController {
    private weak var viewModel: GalleryMediaViewModel?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Outlets
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var streamView: StreamView!
    @IBOutlet private weak var videoView: MediaVideoView!
    @IBOutlet private weak var thumbnailImageView: UIImageView!
    @IBOutlet private weak var playButton: UIButton!
    @IBOutlet private weak var bottomBarView: UIView!
    @IBOutlet private weak var videoProgressView: MediaVideoBottomBarView!
    @IBOutlet private weak var videoProgressViewBottomConstraint: NSLayoutConstraint!

    // MARK: - Internal Properties
    private(set) var index: Int = 0

    // MARK: - Private Properties
    private weak var coordinator: Coordinator?
    private var thumbnailViewModel: GalleryMediaThumbnailViewModel?
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
        stop()
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        videoProgressView.delegate = self
        start()
        updatePlayButton()
        updateBottomBar()
        initMediaPlayerViewModel()
        observeViewModel()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        stop()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        start()
        viewModel?.videoPlay()
        updateMuteState(viewModel?.mediaBrowsingViewModel.isVideoMuted ?? true)
        viewModel?.mediaBrowsingViewModel.didDisplayMedia(index: index, count: 1)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Update gradient @didLayoutSubviews in order to avoid display issue if layer not rendered yet.
        bottomBarView.addGradient(startAlpha: 0, endAlpha: 0.7)
    }

    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .landscape }
    override var prefersStatusBarHidden: Bool { true }

    func observeViewModel() {
        viewModel?.mediaBrowsingViewModel.$isVideoMuted
            .sink { [weak self] isMuted in
                self?.updateMuteState(isMuted)
            }
            .store(in: &cancellables)

        viewModel?.mediaBrowsingViewModel.$areControlsShown
            .sink { [weak self] areControlsShown in
                self?.showControls(areControlsShown)
            }
            .store(in: &cancellables)

        viewModel?.mediaBrowsingViewModel.$zoomLevel
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
                self.hideThumbnail()
            })
        } else {
            viewModel.videoTogglePlayingStatus()
        }
    }
}

// MARK: - Private Funcs
private extension GalleryVideoViewController {
    func showControls(_ show: Bool) {
        bottomBarView.showFromEdge(.bottom,
                                 offset: view.safeAreaInsets.bottom,
                                 show: show)
        videoProgressView.sliderStyle = show ? .full : .minimal
        videoProgressViewBottomConstraint.constant = show ? Constants.progressViewFullStyleBottomMargin : 0
        UIView.animate(withDuration: Style.shortAnimationDuration) {
            self.view.layoutIfNeeded() // Animate constraint change if needed.
        }

        playButton.animateIsHidden(!show)
    }

    /// Init media player view model.
    func initMediaPlayerViewModel() {
        mediaListener = viewModel?.registerListener(didChange: { [weak self] state in
            let isDownloading = state.downloadStatus == .running
            if isDownloading {
                self?.stop()
                self?.activityIndicator.startAnimating()
            } else {
                self?.start()
                self?.activityIndicator.stopAnimating()
            }
            self?.updatePlayButton(forceHideBars: isDownloading)
            self?.updateBottomBar(forceHideBars: isDownloading)

            if self?.viewModel?.videoIsPlaying() == true {
                self?.hideThumbnail()
            }
        })
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
    ///
    /// - Parameters:
    ///    - forceHideBars: if true, hide top and bottom bar
    func updatePlayButton(forceHideBars: Bool = false) {
        guard let viewModel = viewModel else { return }

        let image = viewModel.videoIsPlaying()
            ? Asset.Gallery.Player.buttonPauseBig.image
            : Asset.Gallery.Player.buttonPlayBig.image

        playButton.setImage(image, for: .normal)
    }

    /// Update bottom bar from current resource.
    ///
    /// - Parameters:
    ///    - forceHideBars: if true, hide top and bottom bar
    func updateBottomBar(forceHideBars: Bool = false) {
        guard let viewModel = viewModel else { return }
        videoProgressView.updateSlider(position: viewModel.getVideoPosition(), duration: viewModel.getVideoDuration())
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
    ///    - completion: completion block
    func configureVideo(url: URL, completion: (() -> Void)? = nil) {
        streamView.isHidden = true
        videoView.isHidden = false
        viewModel?.videoSetVideo(index: self.index, completion: { layer in
            self.videoView.playerLayer = layer
            guard let playerLayer = self.videoView.playerLayer else { return }

            playerLayer.player?.seek(to: CMTime(seconds: Constants.timeSeek, preferredTimescale: Constants.preferredTimescale))
            playerLayer.needsDisplayOnBoundsChange = true
            playerLayer.frame = self.videoView.bounds
            self.videoView.layer.addSublayer(playerLayer)
            self.scheduledTimerWithTimeInterval()
            if let completion = completion {
                completion()
            }
        })
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
              let currentMedia = viewModel.getMedia(index: index) else {
            return
        }

        if let mediaUrl = currentMedia.url {
            configureVideo(url: mediaUrl, completion: {
                if let completion = completion {
                    completion()
                }
            })
        } else {
            configureStreaming(completion: {
                if let completion = completion {
                    completion()
                }
            })
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
        timer = Timer.scheduledTimer(withTimeInterval: Constants.timerInterval, repeats: true) { [weak self] _ in
            self?.viewModel?.videoUpdateState()
        }
    }

    /// Show  thumbnail.
    func showThumbnail() {
        guard let media = viewModel?.getMedia(index: index),
              let mediaIndex = viewModel?.getMediaImageDefaultIndex(media),
              let mediaStore = viewModel?.mediaStore else {
            return
        }

        thumbnailViewModel = GalleryMediaThumbnailViewModel(media: media,
                                                            mediaStore: mediaStore,
                                                            index: mediaIndex)
        thumbnailViewModel?.getThumbnail { [weak self] image in
            self?.thumbnailImageView.image = image
            self?.thumbnailImageView.isHidden = false
        }
    }

    /// Hide  thumbnail.
    func hideThumbnail() {
        thumbnailImageView.fadeOut(Constants.fadeOut, completion: {
            self.thumbnailImageView.isHidden = true
        })
    }
}

// MARK: - MediaVideoBottomBarViewDelegate
extension GalleryVideoViewController: MediaVideoBottomBarViewDelegate {
    func didUpdateSlider(newPositionValue: TimeInterval) {
        _ = viewModel?.videoUpdatePosition(position: newPositionValue)
    }
}
