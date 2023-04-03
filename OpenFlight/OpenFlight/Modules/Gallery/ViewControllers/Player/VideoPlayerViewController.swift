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

import UIKit
import GroundSdk
import AVFoundation
import Combine

/// Gallery Video view controller.
final class VideoPlayerViewController: UIViewController, MediaContainer {
    var media: GalleryMedia { viewModel.media }
    private var viewModel: VideoPlayerViewModel!
    private var browserManager: MediaBrowserManager!
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Outlets
    @IBOutlet private weak var previewImageView: UIImageView!
    @IBOutlet private weak var blurredPreviewImageView: UIImageView!
    @IBOutlet private weak var avPlayerView: AVPlayerView!
    @IBOutlet private weak var streamView: StreamView!
    @IBOutlet private weak var playButton: UIButton!
    @IBOutlet private weak var videoProgressView: MediaVideoBottomBarView!
    @IBOutlet private weak var bannerAlertView: BannerAlertView!
    @IBOutlet private weak var bannerAlertViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var bottomBarView: UIView!
    @IBOutlet private weak var bottomBarBottomConstraint: NSLayoutConstraint!

    // MARK: - Private Properties
    /// The seekbar update timer.
    // TODO: [GalleryRework] Check for a cleaner implementation for seekbar handling.
    private var timer: Timer?
    /// The auto-play task.
    private var autoPlayTask: Task<Void, Error>?

    // MARK: - Private Enums
    private enum Constants {
        static let timerInterval: TimeInterval = 0.1
        static let progressViewFullStyleBottomMargin: CGFloat = 12
        static let toolbarGradientMaxAlpha: CGFloat = 0.7
        static let autoPlayDelay: TimeInterval = 0.3 // in seconds
    }

    // MARK: - Setup
    /// Instantiate view controller.
    ///
    /// - Parameters:
    ///     - coordinator: gallery coordinator
    ///     - index: Media index in the media array
    /// - Returns: a GalleryVideoViewController.
    static func instantiate(viewModel: VideoPlayerViewModel,
                            browserManager: MediaBrowserManager) -> VideoPlayerViewController {
        let viewController = StoryboardScene.MediaBrowserViewController.galleryVideoViewController.instantiate()
        viewController.viewModel = viewModel
        viewController.browserManager = browserManager

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()

        browserManager.$areControlsShown.sink { [weak self] areShown in
            self?.showControls(areShown)
        }
        .store(in: &cancellables)

        browserManager.$isVideoMuted.removeDuplicates().sink { [weak self] isMuted in
            self?.updateMuteState(isMuted)
        }
        .store(in: &cancellables)

        viewModel.$playState.removeDuplicates().sink { [weak self] playState in
            self?.updateUI(for: playState)
        }
        .store(in: &cancellables)

        viewModel.$duration.removeDuplicates().sink { [weak self] duration in
            self?.videoProgressView.updateSlider(duration: duration)
        }
        .store(in: &cancellables)

        viewModel.$position.removeDuplicates().sink { [weak self] position in
            self?.videoProgressView.updateSlider(position: position)
        }
        .store(in: &cancellables)

        viewModel.$aspect.removeDuplicates().sink { [weak self] aspect in
            self?.updateAspect(aspect)
        }
        .store(in: &cancellables)

        viewModel.didDenyRecordingPublisher.sink { [weak self] in
            self?.showUnavailableRecordingAlert()
        }
        .store(in: &cancellables)

        viewModel.$bottomBarNeedsPadding.removeDuplicates().sink { [weak self] needsPadding in
            self?.updateBottomBar(needsPadding: needsPadding)
        }
        .store(in: &cancellables)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.setupStreamReplay(in: streamView)
        browserManager.showControls()
        browserManager.setActiveMedia(media, forceUpdate: true)

        viewModel.seekTo(0)
        autoPlayTask = Task {
            try await Task.sleep(nanoseconds: UInt64(Constants.autoPlayDelay * 1_000_000_000))
            try Task.checkCancellation()
            viewModel.playVideo()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        autoPlayTask?.cancel()
        viewModel.detachStream(from: streamView)
        resetTimer()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bottomBarView.addGradient(startAlpha: 0, endAlpha: Constants.toolbarGradientMaxAlpha)
    }
}

// MARK: - Actions
private extension VideoPlayerViewController {
    @IBAction func playButtonTouchedUpInside(_ sender: AnyObject) {
        viewModel.togglePlayPause()
    }
}

// MARK: - Private Funcs
private extension VideoPlayerViewController {

    /// Sets up view.
    func setupView() {
        streamView.renderingPaddingFill = .none
        setupPreviewImage()
        videoProgressView.showFromEdge(.bottom, show: false, animate: false)
        viewModel.setupAvPlayer(in: avPlayerView)
        videoProgressView.delegate = self

        // Add double tap gesture recognizer for zoom handling.
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(doubleTapRecognized))
        doubleTapGesture.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTapGesture)

        bannerAlertViewTopConstraint.constant = Layout.hudTopBarHeight(isRegularSizeClass) + Layout.mainSpacing(isRegularSizeClass)
    }

    /// Sets up preview image to be displayed for unavailable playing states.
    func setupPreviewImage() {
        guard media.source.isDroneSource else { return }

        let thumbnailViewModel = GalleryMediaThumbnailViewModel(media: media,
                                                                index: 0)
        blurredPreviewImageView.addBlurEffect(with: .regular)

        thumbnailViewModel.getThumbnail { [weak self] image in
            guard let self = self else { return }
            self.previewImageView.image = image
            self.blurredPreviewImageView.image = image
            self.showPreviewImage(show: true, withBlur: false)
        }
    }

    /// Shows/hides a mock image above video player view.
    ///
    /// - Parameters:
    ///    - show: whether the mock image should be shown
    ///    - withBlur: whether mock image should be blurred
    ///    - animated: whether change should be animated
    func showPreviewImage(show: Bool, withBlur: Bool = false, animated: Bool = true) {
        let imageView = withBlur ? blurredPreviewImageView : previewImageView
        if withBlur {
            previewImageView.isHidden = true
        } else {
            blurredPreviewImageView.isHidden = true
        }
        if animated {
            imageView?.animateIsHidden(!show)
        } else {
            imageView?.isHidden = !show
        }
    }

    /// Updates controls showing/hiding.
    ///
    /// - Parameter show: whether controls should be shown
    func showControls(_ show: Bool) {
        playButton.animateIsHidden(!show)
        bottomBarView.showFromEdge(.bottom,
                                   offset: view.safeAreaInsets.bottom + Constants.progressViewFullStyleBottomMargin,
                                   show: show,
                                   fadeFrom: 1)
    }

    /// Updates muting state (only relevant for device source).
    ///
    /// - Parameter isMuted: whether video is muted
    func updateMuteState(_ isMuted: Bool) {
        viewModel.setMuted(isMuted)
    }

    /// Informs view model that a double tap has been recognized.
    @objc func doubleTapRecognized() {
        viewModel.didDoubleTap()
    }

    /// Updates video aspect.
    ///
    /// - Parameter aspect: the video aspect to set
    func updateAspect(_ aspect: VideoAspect) {
        UIView.animate(withDuration: Style.shortAnimationDuration) {
            self.streamView.renderingScaleType = aspect.streamScaleType
            self.avPlayerView.setGravity(aspect.avPlayerGravity)
        }
    }

    /// Updates UI according to play state.
    ///
    /// - Parameter playState: the video play state
    func updateUI(for playState: VideoPlayState) {
        playButton.setImage(playState.playButtonIcon, for: .normal)

        // Enable/disable seekbar update timer according to play state.
        if playState == .playing {
            scheduledTimerWithTimeInterval()
        } else {
            timer?.invalidate()
        }

        if case .unavailable(let reason) = playState {
            // Unavailable state => update UI elements according to reason.
            bannerAlertView.animateIsHidden(false)
            bannerAlertView.viewModel = .init(content: .init(icon: reason.icon,
                                                             title: reason.message ?? ""),
                                              style: .init(iconColor: ColorName.errorColor.color,
                                                           titleColor: .white,
                                                           backgroundColor: ColorName.black60.color))
            switch reason {
            case .unknown:
                showPreviewImage(show: true, withBlur: false)
            case .ongoingDownload,
                    .ongoingCameraRecording:
                showPreviewImage(show: true, withBlur: true)
            }
        } else {
            // Valid play state => hide unavailable state UI elements.
            bannerAlertView.animateIsHidden(true)
            showPreviewImage(show: false)

            // Video has reached its end => show controls.
            if playState == .ended {
                browserManager.showControls()
                showControls(true)
            }
        }
    }

    /// Updates bottom bar padding if needed.
    ///
    /// - Parameter needsPadding: whether padding is needed
    func updateBottomBar(needsPadding: Bool) {
        bottomBarBottomConstraint.constant = needsPadding ? Layout.buttonIntrinsicHeight(isRegularSizeClass) / 2 : 0
        UIView.animate { self.view.layoutIfNeeded() }
    }

    /// Resets seekbar update timer.
    func resetTimer() {
        timer?.invalidate()
        timer = nil
    }

    /// Schedules seekbar update timer.
    func scheduledTimerWithTimeInterval() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: Constants.timerInterval, repeats: true) { [weak self] _ in
            self?.viewModel.refreshPosition()
        }
    }

    /// Shows unavailable recording popup alert.
    func showUnavailableRecordingAlert() {
        showAlert(title: L10n.galleryRecordingNotPossibleTitle,
                  message: L10n.galleryRecordingNotPossibleDesc,
                  cancelAction: AlertAction(title: L10n.ok,
                                            style: .action1))
    }
}

// MARK: - MediaVideoBottomBarViewDelegate
extension VideoPlayerViewController: MediaVideoBottomBarViewDelegate {

    func didUpdateSlider(newPositionValue: TimeInterval) {
        viewModel.seekTo(newPositionValue)
        // User interacted with slider => need to reset auto-hide timer in order to be able
        // to auto-hide controls when interaction ends.
        browserManager.showControls()
    }
}
