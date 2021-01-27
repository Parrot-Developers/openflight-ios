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

/// Gallery Video view controller.
final class GalleryVideoViewController: UIViewController, SwipableViewController {
    // MARK: - Outlets
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var streamView: StreamView!
    @IBOutlet private weak var videoView: MediaVideoView!
    @IBOutlet private weak var playButton: UIButton!
    @IBOutlet private weak var fullscreenButton: UIButton!
    @IBOutlet private weak var bottomBarView: MediaVideoBottomBarView!

    // MARK: - Internal Properties
    private(set) var index: Int = 0

    // MARK: - Private Properties
    private weak var coordinator: Coordinator?
    private weak var viewModel: GalleryMediaViewModel?
    private var timer: Timer?
    private var mediaListener: GalleryMediaListener?

    // MARK: - Private Enums
    private enum Constants {
        static let timerInterval: TimeInterval = 0.1
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

        bottomBarView.delegate = self
        start()
        updatePlayButton()
        updateBottomBar()
        initMediaPlayerViewModel()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        viewModel?.videoStop()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updatePlayButton()
        updateBottomBar()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension GalleryVideoViewController {
    @IBAction func playButtonTouchedUpInside(_ sender: AnyObject) {
        guard let viewModel = viewModel else { return }
        if !viewModel.videoIsPlaying(),
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

    @IBAction func fullscreenButtonTouchedUpInside(_ sender: AnyObject) {
        guard let viewModel = viewModel else { return }
        viewModel.toggleShouldHideControls()
    }
}

// MARK: - Private Funcs
private extension GalleryVideoViewController {
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
        })
    }

    /// Update play button design from current player status.
    ///
    /// - Parameters:
    ///    - forceHideBars: if true, hide top and bottom bar
    func updatePlayButton(forceHideBars: Bool = false) {
        guard let viewModel = viewModel else { return }

        playButton.isHidden = forceHideBars ? forceHideBars : viewModel.shouldHideControls
        if viewModel.videoIsPlaying() {
            playButton.setImage(Asset.Gallery.Player.buttonPauseBig.image, for: .normal)
        } else {
            playButton.setImage(Asset.Gallery.Player.buttonPlayBig.image, for: .normal)
        }
    }

    /// Update bottom bar from current resource.
    ///
    /// - Parameters:
    ///    - forceHideBars: if true, hide top and bottom bar
    func updateBottomBar(forceHideBars: Bool = false) {
        guard let viewModel = viewModel else { return }

        bottomBarView.isHidden = forceHideBars ? forceHideBars : viewModel.shouldHideControls
        bottomBarView.updateSlider(position: viewModel.getVideoPosition(), duration: viewModel.getVideoDuration())
    }

    /// Configure streaming.
    ///
    /// - Parameters:
    ///    - completion: completion block
    func configureStreaming(completion: (() -> Void)? = nil) {
        streamView.isHidden = false
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
            playerLayer.videoGravity = .resizeAspect
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
        viewModel?.toggleShouldHideControls(forceHide: false)
        viewModel?.videoStop()
        streamView.setStream(stream: nil)
        timer?.invalidate()
        timer = nil
    }

    /// Scheduled timer to update
    func scheduledTimerWithTimeInterval() {
        timer = Timer.scheduledTimer(withTimeInterval: Constants.timerInterval, repeats: true) { [weak self] _ in
            self?.viewModel?.videoUpdateState()
        }
    }
}

// MARK: - MediaVideoBottomBarViewDelegate
extension GalleryVideoViewController: MediaVideoBottomBarViewDelegate {
    func didUpdateSlider(newPositionValue: TimeInterval) {
        _ = viewModel?.videoUpdatePosition(position: newPositionValue)
    }
}
