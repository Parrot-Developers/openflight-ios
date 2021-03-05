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
    @IBOutlet private weak var bgBottomBar: UIView!
    @IBOutlet private weak var loadingView: GalleryLoadingView!
    @IBOutlet private weak var toolbarView: UIView!
    @IBOutlet private weak var deleteButton: UIButton!
    @IBOutlet private weak var generateButton: UIButton!
    @IBOutlet private weak var shareButton: UIButton!
    @IBOutlet private weak var downloadButton: DownloadButton!

    // MARK: - Private Properties
    private weak var coordinator: GalleryCoordinator?
    private weak var viewModel: GalleryMediaViewModel?
    private var index: Int = 0
    private var imageIndex: Int = 0
    // Views for navigation bar items, in landscape mode.
    private var shareTopBarButton = UIButton()
    private var deleteTopBarButton = UIButton()
    private var downloadTopBarButton = DownloadButton()
    private var actionsStackView = UIStackView()
    private var actionsBarItem = [UIBarButtonItem]()
    private var mediaListener: GalleryMediaListener?
    private var mediaPagerViewController: GalleryPlayerPagerViewController?

    // MARK: - Private Enums
    private enum Constants {
        static let actionsTopItemsSpacing: CGFloat = 50.0
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
        downloadTopBarButton.setup()
        downloadTopBarButton.addTarget(self,
                                       action: #selector(downloadButtonTouchedUpInside),
                                       for: .touchUpInside)
        setupViewModel()
        setupNavigationBar()
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
    @IBAction func deleteButtonTouchedUpInside(_ sender: AnyObject) {
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

    @IBAction func shareButtonTouchedUpInside(_ sender: AnyObject) {
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

    @IBAction func downloadButtonTouchedUpInside(_ sender: AnyObject) {
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

// MARK: - Private Funcs
private extension GalleryMediaPlayerViewController {
    /// Init view elements.
    func initView() {
        bgView.backgroundColor = ColorName.black80.color
        bgBottomBar.backgroundColor = ColorName.black.color
        loadingView.isHidden = true
        deleteButton.tintColor = ColorName.white.color
        generateButton.makeup(with: .large, color: ColorName.white)
        generateButton.setTitle(L10n.galleryPanoramaGenerate, for: .normal)
        generateButton.cornerRadiusedWith(backgroundColor: ColorName.greenSpring20.color, radius: Style.largeCornerRadius)
        shareButton.tintColor = ColorName.white.color
        downloadButton.setup()
    }

    /// Delete current media.
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

    /// Setup everything related to view model.
    func setupViewModel() {
        mediaListener = self.viewModel?.registerListener(didChange: { [weak self] state in
            self?.updateContent(forceHideBars: state.shouldHideControls)
            self?.updateCurrentMedia()
            self?.loadingView.setProgress(state.downloadProgress,
                                          status: state.downloadStatus)
        })
    }

    /// Updates view for the navigation bar.
    func setupNavigationBar() {
        self.navigationController?.navigationBar.addBlurEffect()

        // Setup actions.
        shareTopBarButton.setImage(Asset.Common.Icons.icExport.image, for: .normal)
        shareTopBarButton.addTarget(self,
                                    action: #selector(shareButtonTouchedUpInside),
                                    for: .touchUpInside)

        deleteTopBarButton.setImage(Asset.Common.Icons.iconTrashWhite.image, for: .normal)
        deleteTopBarButton.addTarget(self,
                                     action: #selector(deleteButtonTouchedUpInside),
                                     for: .touchUpInside)
        deleteButton.imageEdgeInsets = UIEdgeInsets(top: 0.0,
                                                    left: -Style.attributedTitleViewSpacing,
                                                    bottom: 0.0,
                                                    right: 0.0)
        actionsStackView = UIStackView(arrangedSubviews: [deleteTopBarButton,
                                                          shareTopBarButton,
                                                          downloadTopBarButton])
        actionsStackView.axis = .horizontal
        actionsStackView.distribution = .fill
        actionsStackView.spacing = Constants.actionsTopItemsSpacing
        actionsBarItem = [UIBarButtonItem(customView: actionsStackView)]
        self.navigationItem.rightBarButtonItems = actionsBarItem

        updateButtons()
    }

    /// Updates content display.
    ///
    /// - Parameters:
    ///    - forceHideBars: if true, hide top and bottom bar
    func updateContent(forceHideBars: Bool = false) {
        toolbarView.isHidden = forceHideBars ? forceHideBars : UIApplication.isLandscape
        bgBottomBar.isHidden = forceHideBars ? forceHideBars : toolbarView.isHidden
        self.navigationItem.rightBarButtonItems = toolbarView.isHidden ? actionsBarItem : []
        self.navigationController?.setNavigationBarHidden(forceHideBars, animated: false)
    }

    /// Updates current media.
    func updateCurrentMedia() {
        guard let viewModel = viewModel,
              let currentMedia = viewModel.getMedia(index: index) else {
            return
        }

        // Update title view.
        self.navigationItem.titleView = currentMedia.titleStackView
        // Update action buttons.
        updateButtons()
    }

    /// Updates buttons regarding download state.
    func updateButtons() {
        // Bottom bar buttons (landscape).
        guard let viewModel = viewModel,
              let currentMedia = viewModel.getMedia(index: index) else {
            return
        }

        downloadButton.updateState(currentMedia.downloadState)
        deleteButton.isEnabled = currentMedia.downloadState != .downloading
        switch currentMedia.downloadState {
        case .toDownload,
             .downloading,
             .error:
            shareButton.isHidden = true
            downloadButton.isHidden = currentMedia.source == .mobileDevice
        case .downloaded:
            shareButton.isHidden = false
            downloadButton.isHidden = true
        default:
            shareButton.isHidden = false
            downloadButton.isHidden = false
        }

        // Top bar buttons (portrait).
        downloadTopBarButton.updateState(currentMedia.downloadState)
        shareTopBarButton.isHidden = shareButton.isHidden
        downloadTopBarButton.isHidden = downloadButton.isHidden
        deleteTopBarButton.isEnabled = deleteButton.isEnabled
        generateButton.isHidden = viewModel.shouldHideGenerationOption(currentMedia: currentMedia)
    }

    /// Handle download end.
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
