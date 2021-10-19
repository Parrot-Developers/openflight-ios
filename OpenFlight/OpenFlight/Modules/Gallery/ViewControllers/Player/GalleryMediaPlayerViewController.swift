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
import Combine
import GroundSdk

/// Gallery media player ViewController.

final class GalleryMediaPlayerViewController: UIViewController {
    private weak var viewModel: GalleryMediaViewModel?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Outlets
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

    // MARK: - Private Properties
    private weak var coordinator: GalleryCoordinator?
    private var mediaIndex: Int = 0
    private var imageIndex: Int = 0 {
        didSet {
            pageControl.currentPage = imageIndex
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

    // MARK: - Constants
    private enum Constants {
        static let autoHideControlsTimerDelay: TimeInterval = 2
        static let pageControlMargin: CGFloat = 30
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
        viewModel?.unregisterListener(mediaListener)
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        observeViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.galleryViewer, logType: .screen)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        disableAutoHideControlsTimer()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Update gradient @didLayoutSubviews in order to avoid display issue if layer not rendered yet.
        topToolbarView.addGradient(startAlpha: 0.7)
    }

    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .landscape }
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

        // PageControl index update.
        viewModel?.mediaBrowsingViewModel.$resourceIndex
            .sink { [weak self] index in
                self?.imageIndex = index
                self?.resetAutoHideControlsTimer()
            }
            .store(in: &cancellables)

        // Media index update.
        viewModel?.mediaBrowsingViewModel.$mediaIndex
            .sink { [weak self] index in
                self?.mediaIndex = index
                self?.updateMediaDetails()
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
            self?.updateMediaDetails()
            self?.loadingView.setProgress(state.downloadProgress,
                                          status: state.downloadStatus)
        }
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
        deleteMediaPopup()
    }

    @IBAction func topShareButtonTouchedUpInside(_ sender: AnyObject) {
        shareMedia()
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

        // Top Toolbar
        mediaTitleView.style = .light
        topDownloadButton.setup()
        updateVideoMuteButtonState()

        // Rotate pageControl for vertical display.
        pageControl.transform = pageControlInitialTransform

        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(doubleTapRecognized))
        doubleTapGesture.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTapGesture)

        // Tap gesture for controls dismissal gesture recognition.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(singleTapRecognized))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.require(toFail: doubleTapGesture)
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
    }

    func showPageControl(_ show: Bool) {
        let isPageAvailable = pageControl.numberOfPages > 1 && media?.type != .video
        // Page control is already .pi /2 rotated in order to be displayed vertically.
        // => Need to animate appearance from its .top edge.
        pageControl.showFromEdge(.top,
                                 offset: Constants.pageControlMargin,
                                 show: show && isPageAvailable,
                                 initialTransform: pageControlInitialTransform)
    }

    func showControls(_ show: Bool) {
        topToolbarView.showFromEdge(.top, show: show)
        showPageControl(show)
    }

    func updateMediaDetails() {
        mediaTitleView.model = media
        updateToolbarButtonsState()
    }

    func updateVideoMuteButtonState() {
        topSoundButton.setImage(viewModel?.mediaBrowsingViewModel.videoSoundButtonImage, for: .normal)
    }

    /// Updates buttons regarding download state.
    func updateToolbarButtonsState() {
        guard let downloadState = media?.downloadState else { return }

        topShareButton.isHiddenInStackView = !downloadState.isShareActionInfoShown
        topDownloadButton.isHiddenInStackView = !downloadState.isDownloadActionInfoShown

        if downloadState.isDownloadActionInfoShown {
            topDownloadButton.updateState(downloadState,
                                          title: media?.formattedSize)
        }

        topSoundButton.isHiddenInStackView = media?.type != .video || media?.source != .mobileDevice

        // Refresh controls state as we may switch from/to photo/video.
        // => Need to update according to isPageControlShown.
        showControls(viewModel?.mediaBrowsingViewModel.areControlsShown ?? false)
    }

    func updateControlsDisplayState() {
        viewModel?.mediaBrowsingViewModel.didInteractForControlsDisplay()
        if viewModel?.mediaBrowsingViewModel.areControlsShown == true {
            resetAutoHideControlsTimer()
        }
    }

    func updateZoomState() {
        viewModel?.mediaBrowsingViewModel.didInteractForDoubleTapZoom()
    }
}

private extension GalleryMediaPlayerViewController {
    func resetAutoHideControlsTimer() {
        if viewModel?.mediaBrowsingViewModel.areControlsShown != true {
            // We reveived media update info and controls are hidden.
            // => User interaction detected, show controls back.
            viewModel?.mediaBrowsingViewModel.didInteractForControlsDisplay(true)
        }

        disableAutoHideControlsTimer()
        autoHideControlsTimer = Timer.scheduledTimer(withTimeInterval: Constants.autoHideControlsTimerDelay, repeats: false) { [weak self] _ in
            self?.viewModel?.mediaBrowsingViewModel.didInteractForControlsDisplay(false)
        }
    }

    func disableAutoHideControlsTimer() {
        autoHideControlsTimer?.invalidate()
    }
}

extension GalleryMediaPlayerViewController {
    /// Shares the current media.
    func shareMedia() {
        guard let viewModel = viewModel,
              let currentMedia = viewModel.getMedia(index: mediaIndex) else {
            return
        }

        viewModel.getMediaPreviewImageUrl(currentMedia, imageIndex) { [weak self] url in
            guard let url = url,
                  let view = self?.view else {
                return
            }

            self?.coordinator?.showSharingScreen(fromView: view, items: [url])
        }
    }

    /// Shows the delete media popup.
    func deleteMediaPopup() {
        let deleteAction = AlertAction(title: L10n.commonDelete,
                                       style: .destructive,
                                       actionHandler: { [weak self] in
                                        self?.deleteCurrentMedia()
                                       })
        let cancelAction = AlertAction(title: L10n.cancel,
                                       style: .cancel,
                                       actionHandler: {})
        let message: String = viewModel?.sourceType?.deleteConfirmMessage(count: 1) ?? ""
        showAlert(title: L10n.commonDelete,
                  message: message,
                  cancelAction: cancelAction,
                  validateAction: deleteAction)
    }

    /// Deletes current media.
    func deleteCurrentMedia() {
        guard let viewModel = viewModel,
              let currentMedia = viewModel.getMedia(index: mediaIndex) else {
            return
        }

        viewModel.deleteMedias([currentMedia], completion: { [weak self] success in
            guard success else { return }

            self?.viewModel?.refreshMedias()
            self?.coordinator?.back()
        })
    }

    /// Handles download end.
    func handleDownloadEnd() {
        let deleteAction = AlertAction(title: L10n.commonDelete,
                                       style: .destructive,
                                       actionHandler: { [weak self] in
                                        self?.deleteCurrentMedia()
                                       })
        let keepAction = AlertAction(title: L10n.commonKeep,
                                     style: .default,
                                     actionHandler: {})
        showAlert(title: L10n.galleryDownloadComplete,
                  message: L10n.galleryDownloadKeep,
                  cancelAction: deleteAction,
                  validateAction: keepAction)
    }

    /// Downloads the current media.
    func downloadMedia() {
        guard let viewModel = viewModel,
              let currentMedia = viewModel.getMedia(index: mediaIndex) else {
            return
        }

        viewModel.downloadMedias([currentMedia], completion: { [weak self] success in
            guard success else { return }

            self?.handleDownloadEnd()
        })
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
        let controlsDismissalTapDetected = touch.view is GalleryMediaFullScreenCollectionViewCell
            || touch.view is MediaVideoView
            || touch.view is GSStreamView

        if !controlsDismissalTapDetected {
            // General user interaction detected => disable autoHideControlsTimer for now.
            // Will be fired back if controls are manually hidden or when new media is displayed.
            disableAutoHideControlsTimer()
        }

        // Handle tap only if controls dismissal is detected.
        return controlsDismissalTapDetected
    }
}
