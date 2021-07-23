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

/// Gallery media player ViewController.

final class GalleryMediaPlayerViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var bgView: UIView!
    @IBOutlet private weak var topToolbarSuperView: UIVisualEffectView!
    @IBOutlet private weak var topToolbarView: UIView!
    @IBOutlet private weak var backButton: UIButton!
    @IBOutlet private weak var titleViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var titleImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var actionsView: UIView!
    @IBOutlet private weak var topDeleteButton: UIButton!
    @IBOutlet private weak var topShareButton: UIButton!
    @IBOutlet private weak var topDownloadButton: DownloadButton!
    @IBOutlet private weak var loadingView: GalleryLoadingView!
    @IBOutlet private weak var bottomToolbarView: UIView!
    @IBOutlet private weak var bottomToolbarViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var bottomDeleteButton: UIButton!
    @IBOutlet private weak var bottomShareButton: UIButton!
    @IBOutlet private weak var bottomDownloadButton: DownloadButton!
    @IBOutlet private weak var generateButton: UIButton!

    // MARK: - Private Properties
    private weak var coordinator: GalleryCoordinator?
    private weak var viewModel: GalleryMediaViewModel?
    private var index: Int = 0
    private var imageIndex: Int = 0
    private var mediaListener: GalleryMediaListener?
    private var mediaPagerViewController: GalleryPlayerPagerViewController?

    // MARK: - Private Enums
    private enum Constants {
        static let showBottomToolbarViewHeightConstraint: CGFloat = 80.0
        static let hideBottomToolbarViewHeightConstraint: CGFloat = 0.0
        static let titleViewWithSubtitleLabelTopConstraint: CGFloat = 0.0
        static let titleViewWithoutSubtitleLabelTopConstraint: CGFloat = 10.0
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

        initView()
        removeBackButtonText()
        setupViewModel()
        updateButtons()
        updateContent()
        updateCurrentMedia()
        loadingView.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.galleryViewer, logType: .screen)
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }

    /// Update display when orientation changed.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        updateContent()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let destination = segue.destination as? GalleryPlayerPagerViewController {
            mediaPagerViewController = destination
            mediaPagerViewController?.coordinator = coordinator
            mediaPagerViewController?.viewModel = viewModel
            mediaPagerViewController?.index = index
            mediaPagerViewController?.pagerDelegate = self
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension GalleryMediaPlayerViewController {

    @IBAction func backButtonTouchedUpInside(_ sender: AnyObject) {
        coordinator?.back()
    }

    @IBAction func topDeleteButtonTouchedUpInside(_ sender: AnyObject) {
        deleteMediaPopup()
    }

    @IBAction func bottomDeleteButtonTouchedUpInside(_ sender: AnyObject) {
        deleteMediaPopup()
    }

    @IBAction func topShareButtonTouchedUpInside(_ sender: AnyObject) {
        shareMedia()
    }

    @IBAction func bottomShareButtonTouchedUpInside(_ sender: AnyObject) {
        shareMedia()
    }

    @IBAction func topDownloadButtonTouchedUpInside(_ sender: AnyObject) {
        downloadMedia()
    }

    @IBAction func bottomDownloadButtonTouchedUpInside(_ sender: AnyObject) {
        downloadMedia()
    }

    @IBAction func generateButtonTouchedUpInside(_ sender: AnyObject) {
        guard let viewModel = viewModel,
              let currentMedia = viewModel.getMedia(index: index) else {
            return
        }

        let galleryPanoramaViewModel = GalleryPanoramaViewModel(galleryViewModel: viewModel)
        switch currentMedia.type {
        case .panoWide,
             .panoVertical,
             .panoHorizontal:
            coordinator?.showPanoramaQualityChoiceScreen(viewModel: galleryPanoramaViewModel, index: index)
        case .pano360:
            coordinator?.showPanoramaChoiceTypeScreen(viewModel: viewModel, index: index)
        default:
            return
        }
    }
}

// MARK: - Private Funcs
private extension GalleryMediaPlayerViewController {
    /// Init view elements.
    func initView() {
        navigationController?.setNavigationBarHidden(true, animated: false)
        loadingView.isHidden = true
        titleLabel.text = ""
        subtitleLabel.text = ""
        titleViewTopConstraint.constant = Constants.titleViewWithoutSubtitleLabelTopConstraint
        generateButton.setTitle(L10n.galleryPanoramaGenerate, for: .normal)
        generateButton.cornerRadiusedWith(backgroundColor: ColorName.warningColor.color, radius: Style.largeCornerRadius)
        topDownloadButton.setup()
        bottomDownloadButton.setup()
    }

    /// Setup everything related to view model.
    func setupViewModel() {
        mediaListener = self.viewModel?.registerListener(didChange: { [weak self] state in
            self?.updateContent(forceHideBars: state.shouldHideControls)
            self?.updateCurrentMedia()
            self?.loadingView.setProgress(state.downloadProgress,
                                          status: state.downloadStatus)
        })
    }

    /// Updates content display.
    ///
    /// - Parameters:
    ///    - forceHideBars: if true, hide top and bottom bar
    func updateContent(forceHideBars: Bool = false) {
        topToolbarView.isHidden = forceHideBars
        topToolbarSuperView.isHidden = forceHideBars
        bottomToolbarView.isHidden = forceHideBars ? forceHideBars : UIApplication.isLandscape
        if UIApplication.isLandscape {
            bottomToolbarViewHeightConstraint.constant = Constants.hideBottomToolbarViewHeightConstraint
        } else {
            bottomToolbarViewHeightConstraint.constant = Constants.showBottomToolbarViewHeightConstraint
        }
    }

    /// Updates current media.
    func updateCurrentMedia() {
        // Updates title view.
        updateTitleView()
        // Updates action buttons.
        updateButtons()
    }

    /// Updates title content regarding media type.
    func updateTitleView() {
        guard let viewModel = viewModel,
              let currentMedia = viewModel.getMedia(index: index),
              let titleImage = currentMedia.type.filterImage else {
            return
        }

        titleImageView.image = titleImage
        // Sets the flight plan execution's custom title and its location
        if let customTitle = currentMedia.mainMediaItem?.customTitle,
           !customTitle.isEmpty {
            titleLabel.text = customTitle.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
            currentMedia.mainMediaItem?.locationDetail(completion: { [weak self] locationDetail in
                self?.subtitleLabel.text = locationDetail
                self?.titleViewTopConstraint.constant = Constants.titleViewWithSubtitleLabelTopConstraint
            })
        } else {
            titleLabel.text = currentMedia.date.formattedString(dateStyle: .long, timeStyle: .medium)
            subtitleLabel.text = ""
            titleViewTopConstraint.constant = Constants.titleViewWithoutSubtitleLabelTopConstraint
        }
    }

    /// Updates buttons regarding download state.
    func updateButtons() {
        // Bottom bar buttons (landscape).
        guard let viewModel = viewModel,
              let currentMedia = viewModel.getMedia(index: index) else {
            return
        }

        bottomDownloadButton.updateState(currentMedia.downloadState, title: currentMedia.formattedSize)
        bottomDeleteButton.isEnabled = currentMedia.downloadState != .downloading
        switch currentMedia.downloadState {
        case .toDownload,
             .downloading,
             .error:
            bottomShareButton.isHidden = true
            topShareButton.isHidden = true
            bottomDownloadButton.isHidden = currentMedia.source == .mobileDevice
            topDownloadButton.isHidden = currentMedia.source == .mobileDevice
        case .downloaded:
            bottomShareButton.isHidden = false
            bottomDownloadButton.isHidden = true
            topShareButton.isHidden = false
            topDownloadButton.isHidden = true
        default:
            bottomShareButton.isHidden = false
            bottomDownloadButton.isHidden = false
            topShareButton.isHidden = false
            topDownloadButton.isHidden = false
        }

        // Top bar buttons (portrait).
        topDownloadButton.updateState(currentMedia.downloadState, title: currentMedia.formattedSize)
        topShareButton.isHidden = bottomShareButton.isHidden
        topDownloadButton.isHidden = bottomDownloadButton.isHidden
        generateButton.isHidden = viewModel.shouldHideGenerationOption(currentMedia: currentMedia)
    }

    /// Shares the current media.
    func shareMedia() {
        guard let viewModel = viewModel,
              let currentMedia = viewModel.getMedia(index: index) else {
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
        // TODO: handle this properly when working on delete / download actions
        let message: String = ""
        showAlert(title: L10n.commonDelete,
                  message: message,
                  cancelAction: cancelAction,
                  validateAction: deleteAction)
    }

    /// Deletes current media.
    func deleteCurrentMedia() {
        guard let viewModel = viewModel,
              let currentMedia = viewModel.getMedia(index: index) else {
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
              let currentMedia = viewModel.getMedia(index: index) else {
            return
        }

        viewModel.downloadMedias([currentMedia], completion: { [weak self] success in
            guard success else { return }

            self?.handleDownloadEnd()
        })
    }
}

// MARK: - Gallery Player Pager Delegate
extension GalleryMediaPlayerViewController: GalleryPlayerPagerDelegate {
    func galleryPagerDidChangeToIndex(_ index: Int) {
        self.index = index
        updateCurrentMedia()
    }

    func galleryPagerDidChangeToImageIndex(_ index: Int) {
        imageIndex = index
    }
}

// MARK: - Gallery Loading View Delegate
extension GalleryMediaPlayerViewController: GalleryLoadingViewDelegate {
    func shouldStopProgress() {
        viewModel?.cancelDownloads()
    }
}
