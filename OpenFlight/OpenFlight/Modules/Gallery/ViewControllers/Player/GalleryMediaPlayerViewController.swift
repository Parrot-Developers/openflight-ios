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
import Combine
import GroundSdk

/// Gallery media player ViewController.

final class GalleryMediaPlayerViewController: UIViewController {
    private weak var viewModel: GalleryMediaViewModel?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Outlets
    // Top Toolbar
    @IBOutlet private weak var topToolbarView: UIStackView!
    @IBOutlet private weak var backButton: UIButton!
    @IBOutlet private weak var mediaTitleView: GalleryMediaTitleView!
    @IBOutlet private weak var actionsView: UIView!
    @IBOutlet private weak var topSoundButton: UIButton!
    @IBOutlet private weak var topDeleteButton: UIButton!
    @IBOutlet private weak var topShareButton: UIButton!
    @IBOutlet private weak var topDownloadButton: DownloadButton!

    @IBOutlet private weak var loadingView: GalleryLoadingView!
    @IBOutlet private weak var pageControl: UIPageControl!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    // Bottom Toolbar
    @IBOutlet private weak var bottomBarView: UIView!
    @IBOutlet private weak var videoProgressView: MediaVideoBottomBarView!

    // MARK: - Private Properties
    private weak var coordinator: GalleryCoordinator?
    private var mediaIndex: Int = 0
    private var galleryResourceIndex: Int = 0 {
        didSet {
            pageControl.currentPage = galleryResourceIndex
        }
    }
    private var mediaListener: GalleryMediaListener?
    private var mediaPagerViewController: GalleryPlayerPagerViewController?
    private var pageControlInitialTransform: CGAffineTransform = .init(rotationAngle: .pi / 2)
    private var autoHideControlsTimer: Timer?

    // Convenience Computed Properties
    private var media: GalleryMedia? {
        viewModel?.getMedia(index: mediaIndex)
    }
    private var isVideo: Bool { media?.mainMediaItem?.type == .video }
    /// Actual resourceIndex based on gallery index (may vary depending on panorama generation page display).
    private var resourceIndex: Int {
        guard let media = media else { return 0 }
        return media.canGeneratePanorama
        ? max(0, galleryResourceIndex - 1)
        : galleryResourceIndex
    }

    // MARK: - Constants
    private enum Constants {
        static let autoHideControlResetViewTag = 1
        static let autoHideControlsTimerDelay: TimeInterval = 2
        static let pageControlMargin: CGFloat = 30
        static let progressViewFullStyleBottomMargin: CGFloat = 8
        static let toolbarGradientMaxAlpha: CGFloat = 0.7
    }

    // MARK: - Setup
    /// Instantiate view controller.
    ///
    /// - Parameters:
    ///     - coordinator: gallery coordinator
    ///     - viewModel: gallery view model
    ///     - index: Media index in the media array
    /// - Returns: a GalleryMediaPlayerViewController.
    static func instantiate(coordinator: GalleryCoordinator,
                            viewModel: GalleryMediaViewModel,
                            index: Int) -> GalleryMediaPlayerViewController {
        let viewController = StoryboardScene.GalleryMediaPlayerViewController.initialScene.instantiate()
        viewController.coordinator = coordinator
        viewController.viewModel = viewModel
        viewController.mediaIndex = index

        return viewController
    }

    // MARK: - Deinit
    deinit {
        // Video player is only stopped at image media appear and `GalleryMediaPlayerViewController`
        // deinit in order to avoid any race condition when sliding through medias.
        // => Stop potential video media.
        viewModel?.videoStop()

        // Do not listen to medias updates anymore when gallery is dismissed.
        viewModel?.unregisterListener(mediaListener)
        // Cancel any potential ongoing preview downloads initiated by browsing prefetch.
        viewModel?.cancelPreviewsDownloads()
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        observeViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        LogEvent.log(.screen(LogEvent.Screen.galleryViewer))
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        disableAutoHideControlsTimer()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Update gradient @didLayoutSubviews in order to avoid display issue if layer not rendered yet.
        topToolbarView.addGradient(startAlpha: Constants.toolbarGradientMaxAlpha)
        bottomBarView.addGradient(startAlpha: 0, endAlpha: Constants.toolbarGradientMaxAlpha)
    }

    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var prefersStatusBarHidden: Bool { true }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let destination = segue.destination as? GalleryPlayerPagerViewController {
            mediaPagerViewController = destination
            mediaPagerViewController?.coordinator = coordinator
            mediaPagerViewController?.viewModel = viewModel
            mediaPagerViewController?.index = mediaIndex
        }
    }

    /// Observes Gallery VM updates.
    func observeViewModel() {
        // Controls showing update.
        viewModel?.mediaBrowsingViewModel.$areControlsShown
            .sink { [weak self] areControlsShown in
                self?.showControls(areControlsShown)
            }
            .store(in: &cancellables)

        viewModel?.mediaBrowsingViewModel.$isCameraRecordRequested
            .sink { [weak self] isCameraRecordRequested in
                guard isCameraRecordRequested else { return }
                self?.showRecordErrorAlert()
            }
            .store(in: &cancellables)

        // PageControl index update.
        viewModel?.mediaBrowsingViewModel.$resourceIndex
            .sink { [weak self] index in
                self?.galleryResourceIndex = index
                self?.updateToolbarButtonsState() // May need to hide delete button (generate pano page).
                self?.resetAutoHideControlsTimer()
            }
            .store(in: &cancellables)

        // Media index update.
        viewModel?.mediaBrowsingViewModel.$mediaIndex
            .sink { [weak self] index in
                self?.mediaIndex = index
                self?.updateMediaToolbar()
                self?.resetAutoHideControlsTimer()
            }
            .store(in: &cancellables)

        // Media resource counts update.
        viewModel?.mediaBrowsingViewModel.$resourcesCount
            .sink { [weak self] count in
                self?.pageControl.numberOfPages = count
                self?.showPageControl(self?.viewModel?.mediaBrowsingViewModel.areControlsShown ?? false)
            }
            .store(in: &cancellables)

        // Media state update.
        mediaListener = self.viewModel?.registerListener { [weak self] state in
            self?.updateMediaDetails(state)
            self?.updateBottomBarProgress()
        }

        // Listen to drone's memory download state changes.
        guard let viewModel = viewModel else { return }
        viewModel.$downloadProgress
            .combineLatest(viewModel.$downloadStatus)
            .sink { [weak self] (progress, status) in
                guard let self = self else { return }
                self.loadingView.setProgress(progress, status: status)
            }
            .store(in: &cancellables)
    }
}

// MARK: - Actions
private extension GalleryMediaPlayerViewController {
    @objc func singleTapRecognized() {
        updateControlsDisplayState()
    }

    @objc func doubleTapRecognized() {
        updateZoomState()
    }

    @IBAction func pageControlValueChanged(_ sender: UIPageControl) {
        viewModel?.mediaBrowsingViewModel.didDisplayResourceAt(sender.currentPage)
    }

    @IBAction func backButtonTouchedUpInside(_ sender: AnyObject) {
        coordinator?.back()
    }

    @IBAction func topDeleteButtonTouchedUpInside(_ sender: AnyObject) {
        showDeleteAlert()
    }

    @IBAction func topShareButtonTouchedUpInside(_ sender: UIView) {
        shareMedia(srcView: sender)
    }

    @IBAction func topDownloadButtonTouchedUpInside(_ sender: AnyObject) {
        downloadMedia()
    }

    @IBAction func topSoundButtonTouchedUpInside(_ sender: Any) {
        viewModel?.mediaBrowsingViewModel.didTapSoundButton()
        updateVideoMuteButtonState()
    }
}

// MARK: - Private Funcs
private extension GalleryMediaPlayerViewController {
    /// Init view elements.
    func initView() {
        loadingView.delegate = self
        videoProgressView.delegate = self

        // Top Toolbar
        mediaTitleView.style = .light
        updateVideoMuteButtonState()

        // Bottom Toolbar
        updateBottomBarProgress()

        // Rotate pageControl for vertical display.
        pageControl.transform = pageControlInitialTransform

        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(doubleTapRecognized))
        doubleTapGesture.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTapGesture)

        // Tap gesture for controls dismissal gesture recognition.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(singleTapRecognized))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
    }

    /// Toggles lateral page control display.
    ///
    /// - Parameters:
    ///    - show: Display page control if `true`, hide it otherwise.
    func showPageControl(_ show: Bool) {
        let isPageAvailable = pageControl.numberOfPages > 1 && media?.type != .video
        // Page control is already .pi /2 rotated in order to be displayed vertically.
        // => Need to animate appearance from its .top edge.
        pageControl.showFromEdge(.top,
                                 offset: Constants.pageControlMargin,
                                 show: show && isPageAvailable,
                                 initialTransform: pageControlInitialTransform)
    }

    /// Toggles bottom bar display.
    ///
    /// - Parameters:
    ///    - show: Display bottom bar if `true`, hide it otherwise.
    func showBottomBar(_ show: Bool) {
        let isVideo = media?.type == .video

        bottomBarView.showFromEdge(.bottom,
                                   offset: view.safeAreaInsets.bottom + Constants.progressViewFullStyleBottomMargin,
                                   show: show && isVideo,
                                   fadeFrom: 1)
    }

    /// Toggles controls display.
    ///
    /// - Parameters:
    ///    - show: Display controls if `true`, hide them otherwise.
    func showControls(_ show: Bool) {
        topToolbarView.showFromEdge(.top, show: show)
        showPageControl(show)
        showBottomBar(show)
    }

    /// Updates media tool bar state (title, icons) according to media info.
    func updateMediaToolbar() {
        mediaTitleView.model = media
        updateToolbarButtonsState()
    }

    /// Updates media content information (toolbar, loading progress, resources content) according to media info.
    func updateMediaDetails(_ state: GalleryMediaState) {
        // Ensure connection is ok while browsing drone's memory. Close media player otherwise.
        let isConnectionOk = state.sourceType == .mobileDevice || state.isConnected()
        guard isConnectionOk else {
            coordinator?.back()
            return
        }

        activityIndicator.stopAnimating() // Media gallery has been refreshed.
        updateMediaToolbar()
        reloadGalleryImageContent()
    }

    /// Update bottom bar from current resource.
    ///
    /// - Parameters:
    ///    - forceHideBars: if true, hide top and bottom bar
    func updateBottomBarProgress() {
        guard let viewModel = viewModel else { return }
        videoProgressView.updateSlider(position: viewModel.getVideoPosition(), duration: viewModel.getVideoDuration())
    }

    /// Reloads gallery image content.
    func reloadGalleryImageContent() {
        guard let imageViewController = mediaPagerViewController?.viewControllers?.first as? GalleryImageViewController else { return }
        imageViewController.reloadContent()
    }

    /// Updates video mute button state in top toolbar.
    func updateVideoMuteButtonState() {
        topSoundButton.setImage(viewModel?.mediaBrowsingViewModel.videoSoundButtonImage, for: .normal)
    }

    /// Updates buttons according to download state.
    func updateToolbarButtonsState() {
        guard let media = media,
              let downloadState = media.downloadState else {
                  return
              }

        topShareButton.isHiddenInStackView = !downloadState.isShareActionInfoShown
        topDownloadButton.isHiddenInStackView = !downloadState.isDownloadActionInfoShown

        if downloadState.isDownloadActionInfoShown {
            topDownloadButton.model = DownloadButtonModel(title: media.formattedSize,
                                                          state: downloadState)
        }

        topSoundButton.isHiddenInStackView = media.type != .video || media.source != .mobileDevice
        topDeleteButton.isHiddenInStackView = media.canGeneratePanorama && galleryResourceIndex == 0

        // Refresh controls state as we may switch from/to photo/video.
        // => Need to update according to isPageControlShown.
        showControls(viewModel?.mediaBrowsingViewModel.areControlsShown ?? false)
    }

    /// Updates VM controls display state according to user interaction.
    func updateControlsDisplayState() {
        viewModel?.mediaBrowsingViewModel.didInteractForControlsDisplay()
        if viewModel?.mediaBrowsingViewModel.areControlsShown == true {
            resetAutoHideControlsTimer()
        }
        if viewModel?.getVideoState() == .playing {
            viewModel?.videoPause()
        }
    }

    /// Updates VM zoom state according to user interaction.
    func updateZoomState() {
        viewModel?.mediaBrowsingViewModel.didInteractForDoubleTapZoom()
    }
}

private extension GalleryMediaPlayerViewController {
    func resetAutoHideControlsTimer() {
        if viewModel?.mediaBrowsingViewModel.areControlsShown != true {
            // We received media update info and controls are hidden.
            // => User interaction detected, show controls back.
            viewModel?.mediaBrowsingViewModel.didInteractForControlsDisplay(true)
        }

        disableAutoHideControlsTimer()
        autoHideControlsTimer = Timer.scheduledTimer(withTimeInterval: Constants.autoHideControlsTimerDelay, repeats: false) { [weak self] _ in
            guard self?.viewModel?.mediaBrowsingViewModel.isLoading != true else {
                // Reset autohide timer if media is still loading.
                self?.resetAutoHideControlsTimer()
                return
            }
            self?.viewModel?.mediaBrowsingViewModel.didInteractForControlsDisplay(false)
        }
    }

    func disableAutoHideControlsTimer() {
        autoHideControlsTimer?.invalidate()
    }
}

extension GalleryMediaPlayerViewController {
    /// Shares the current media.
    func shareMedia(srcView: UIView) {
        guard let viewModel = viewModel,
              let currentMedia = viewModel.getMedia(index: mediaIndex) else {
                  return
              }

        Task {
            // Get all linked resources' URL for currently displayed resource: the resource
            // itself, plus any non-previewable related resources (i.e. its DNG version if existing).
            let urls = await viewModel.getLinkedResourcesUrls(media: currentMedia, previewableIndex: resourceIndex)
            DispatchQueue.main.async { [weak self] in
                self?.coordinator?.showSharingScreen(fromView: srcView, items: urls)
            }
        }
    }

    /// Shows an alert for removal confirmation.
    func showDeleteAlert() {
        guard let media = media,
              let count = viewModel?.getMediaImageCount(media, previewableOnly: true) else {
                  return
              }

        if count > 1 {
            // Media has more than 1 resource.
            // => Need to know if user wants to remove displayed resource only, or full media.
            showDeleteMediaOrResourceAlert(count)
        } else {
            showDeleteMediaAlert()
        }
    }

    /// Shows an alert for full media removal confirmation.
    func showDeleteMediaAlert() {
        let deleteAction = AlertAction(title: L10n.commonDelete,
                                       style: .destructive,
                                       actionHandler: deleteCurrentMedia)
        let cancelAction = AlertAction(title: L10n.cancel,
                                       style: .default2,
                                       actionHandler: {})
        let message: String = viewModel?.sourceType.deleteConfirmMessage(count: 1) ?? ""

        showAlert(title: L10n.commonDelete,
                  message: message,
                  cancelAction: cancelAction,
                  validateAction: deleteAction)
    }

    /// Shows an alert for full media or single resource removal choice proposal.
    ///
    /// - Parameters:
    ///    - resourcesCount: The number of resources of current media.
    func showDeleteMediaOrResourceAlert(_ resourcesCount: Int) {
        let fromDrone = media?.source != .mobileDevice
        if fromDrone, viewModel?.downloadStatus == .running {
            // Can't delete medias while downloading.
            let cancelAction = AlertAction(title: L10n.ok,
                                           style: .default2,
                                           isActionDelayedAfterDismissal: false) {}
            showAlert(title: L10n.error,
                      message: L10n.galleryRemoveDroneMemoryDownloading,
                      cancelAction: cancelAction)
            return
        }

        let deleteResourceAction = AlertAction(title: L10n.galleryDeleteResource,
                                               style: .destructive,
                                               borderWidth: Style.mediumBorderWidth,
                                               isActionDelayedAfterDismissal: false,
                                               actionHandler: deleteCurrentResource)
        let deleteMediaAction = AlertAction(title: L10n.galleryDeleteMedia(resourcesCount),
                                            style: .destructive,
                                            actionHandler: deleteCurrentMedia)
        let cancelAction = AlertAction(title: L10n.cancel,
                                       style: .default2,
                                       actionHandler: {})
        let message: String = viewModel?.sourceType.deleteResourceConfirmMessage(count: resourcesCount) ?? ""

        showAlert(title: L10n.commonDelete,
                  message: message,
                  cancelAction: cancelAction,
                  validateAction: deleteResourceAction,
                  secondaryAction: deleteMediaAction)
    }

    /// Deletes whole current media (including all its resources).
    func deleteCurrentMedia() {
        guard let viewModel = viewModel,
              let currentMedia = viewModel.getMedia(index: mediaIndex) else {
                  return
              }

        activityIndicator.startAnimating()

        viewModel.deleteMedias([currentMedia], completion: { [weak self] success in
            guard let self = self else { return }

            guard success else {
                DispatchQueue.main.async {
                    self.showDeleteAlert(retryAction: self.deleteCurrentMedia)
                }
                return
            }

            self.activityIndicator.stopAnimating()
            self.coordinator?.back()
        })
    }

    /// Deletes currently displayed media resource.
    func deleteCurrentResource() {
        guard let viewModel = viewModel,
              let media = media else {
                  return
              }

        // Get all linked resources' indexes for currently displayed resource in order to
        // ensure to delete all (previewable AND non-previewable) linked resources.
        let indexes = media.linkedResourcesIndexes(for: resourceIndex)

        activityIndicator.startAnimating()

        viewModel.deleteResourcesAt(indexes, of: media) { [weak self] success in
            guard let self = self else { return }

            guard success else {
                DispatchQueue.main.async {
                    self.showDeleteAlert(retryAction: self.deleteCurrentResource)
                }
                return
            }

            self.viewModel?.refreshMedias()
            self.reloadGalleryImageContent()
            self.activityIndicator.stopAnimating()
        }
    }

    /// Downloads the current media.
    func downloadMedia() {
        guard let viewModel = viewModel,
              let currentMedia = viewModel.getMedia(index: mediaIndex) else {
                  return
              }

        viewModel.downloadMedias([currentMedia]) { _ in }
    }
}

// MARK: - Gallery Loading View Delegate
extension GalleryMediaPlayerViewController: GalleryLoadingViewDelegate {
    func shouldStopProgress() {
        viewModel?.cancelDownloads()
    }
}

extension GalleryMediaPlayerViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let controlsDismissalTapDetected = touch.view?.superview is GalleryMediaFullScreenCollectionViewCell
        || touch.view is MediaVideoView
        || touch.view is GSStreamView
        let controlsDismissalResetDetected = touch.view?.tag == Constants.autoHideControlResetViewTag

        if controlsDismissalResetDetected {
            // Auto-hide timer needs to be reset when an active action is detected in order to prevent
            // unwanted quick dismissals.
            // Current active action buttons are: play/pause and mute buttons.
            resetAutoHideControlsTimer()
        } else if !controlsDismissalTapDetected {
            // General user interaction detected => disable autoHideControlsTimer for now.
            // Will be fired back if controls are manually hidden or when new media is displayed.
            disableAutoHideControlsTimer()
        }

        // Handle tap only if controls dismissal is detected.
        return controlsDismissalTapDetected
    }
}

// MARK: - MediaVideoBottomBarViewDelegate
extension GalleryMediaPlayerViewController: MediaVideoBottomBarViewDelegate {
    func didUpdateSlider(newPositionValue: TimeInterval) {
        viewModel?.videoUpdatePosition(position: newPositionValue)
        // User interacted with slider => need to reset auto-hide timer in order to be able
        // to auto-hide controls when interaction ends.
        resetAutoHideControlsTimer()
    }
}

private extension GalleryMediaPlayerViewController {
    /// Shows an alert when delete process fails.
    ///
    /// - Parameters:
    ///     - retryAction: Delete retry action to perform.
    func showDeleteAlert(retryAction: @escaping () -> Void) {
        let retryAction = AlertAction(title: L10n.commonRetry,
                                      style: .destructive,
                                      isActionDelayedAfterDismissal: false,
                                      actionHandler: retryAction)
        let cancelAction = AlertAction(title: L10n.cancel,
                                       style: .default2,
                                       isActionDelayedAfterDismissal: false) { self.activityIndicator.stopAnimating() }
        let message: String = viewModel?.sourceType.deleteErrorMessage(count: 1) ?? ""

        showAlert(title: L10n.error,
                  message: message,
                  cancelAction: cancelAction,
                  validateAction: retryAction)
    }

    /// Shows an alert when trying to record while video is playing.
    func showRecordErrorAlert() {
        guard isVideo, viewModel?.downloadStatus != .running else { return }

        let okAction = AlertAction(title: L10n.ok,
                                   style: .action1)

        showAlert(title: L10n.galleryRecordingNotPossibleTitle,
                  message: L10n.galleryRecordingNotPossibleDesc,
                  cancelAction: okAction)
    }
}
