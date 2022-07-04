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
import Combine

/// Gallery image ViewController.

final class GalleryImageViewController: UIViewController, SwipableViewController {
    private weak var viewModel: GalleryMediaViewModel?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Outlets
    @IBOutlet private weak var generateButton: UIButton!
    @IBOutlet private weak var itemsCollectionView: UICollectionView!

    // MARK: - Internal Properties
    private(set) var index: Int = 0

    // MARK: - Private Properties
    private weak var coordinator: GalleryCoordinator?
    private var imageIndex: Int = 0

    // Convenience Computed Properties
    private var media: GalleryMedia? {
        viewModel?.getFilteredMedia(index: index)
    }
    private var hasAdditionalPanoramaGenerationImage: Bool {
        media?.canGeneratePanorama ?? false
    }
    /// The offset used for collectionView items handling in case of an additional blurred panorama image.
    private var additionalImageIndexOffset: Int {
        hasAdditionalPanoramaGenerationImage ? 1 : 0
    }
    private var resourcesCount: Int {
        guard let viewModel = viewModel,
              let media = media else {
            return 0
        }
        return viewModel.getMediaImageCount(media) + additionalImageIndexOffset
    }
    private var currentZoomableCell: GalleryMediaFullScreenCollectionViewCell? {
        guard let cell = itemsCollectionView.visibleCells.first as? GalleryMediaFullScreenCollectionViewCell,
              let model = cell.model,
              model.panoramaGenerationState == .none else {
            return nil
        }
        return cell
    }

    // MARK: - Setup
    /// Instantiate view controller.
    ///
    /// - Parameters:
    ///     - coordinator: gallery coordinator
    ///     - delegate: gallery image delegate
    ///     - viewModel: gallery view model
    ///     - index: Media index in the media array
    /// - Returns: a GalleryImageViewController.
    static func instantiate(coordinator: GalleryCoordinator?,
                            viewModel: GalleryMediaViewModel?,
                            index: Int) -> GalleryImageViewController {
        let viewController = StoryboardScene.GalleryMediaPlayerViewController.galleryImageViewController.instantiate()
        viewController.coordinator = coordinator
        viewController.viewModel = viewModel
        viewController.index = index

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        observeViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        displayMedia()
        setupDefaultImageIndex()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Video player is only stopped at image media appear and `GalleryMediaPlayerViewController`
        // deinit in order to avoid any race condition when sliding through medias.
        // => Stop potential video media.
        viewModel?.videoStop()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Reset VM loading state, as next VC may not be a `GalleryImageViewController`.
        viewModel?.mediaBrowsingViewModel.didUpdateLoadingState(isLoading: false)
    }

    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var prefersStatusBarHidden: Bool { true }

    /// Observe panorama VM updates.
    func observeViewModel() {
        viewModel?.mediaBrowsingViewModel.$panoramaGenerationStatus
            .sink { [unowned self] status in
                guard status == .success else { return }
                self.displayMedia()
                self.reloadVisibleCell()
            }
            .store(in: &cancellables)

        viewModel?.mediaBrowsingViewModel.$zoomLevel
            .sink { [weak self] zoomLevel in
                self?.currentZoomableCell?.updateZoomLevel(zoomLevel)
            }
            .store(in: &cancellables)
    }

    /// Reloads collectionView content and fetch current image.
    func reloadContent() {
        itemsCollectionView.reloadData()
        fetchImage(at: urlIndex(visibleIndex ?? imageIndex))

        guard let viewModel = viewModel,
              let media = media,
              let mediaIndex = viewModel.getMediaIndex(media) else {
                  return
              }

        // Content is reloaded based on current state => do not reset VM urls.
        viewModel.mediaBrowsingViewModel.didDisplayMedia(media,
                                                          index: mediaIndex,
                                                          count: resourcesCount,
                                                          resetUrls: false)
    }
}

private extension GalleryImageViewController {
    /// Sets up UI elements.
    func setupUI() {
        setupCollectionView()
    }

    /// Sets up media resources collectionView.
    func setupCollectionView() {
        itemsCollectionView.register(cellType: GalleryMediaFullScreenCollectionViewCell.self)

        itemsCollectionView.isPagingEnabled = true
        itemsCollectionView.contentInsetAdjustmentBehavior = .never

        let layout = UICollectionViewFlowLayout()
        layout.itemSize = view.bounds.size
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0

        itemsCollectionView.collectionViewLayout = layout
    }
}

// MARK: - Images Fetching
private extension GalleryImageViewController {
    /// Fetches an image for a given resource index.
    ///
    /// - Parameters:
    ///     - index: The resource index in VM `mediaUrls` array.
    func fetchImage(at index: Int?) {
        guard let index = index,
              index < viewModel?.mediaBrowsingViewModel.mediaUrls.count ?? 0,
              viewModel?.mediaBrowsingViewModel.mediaUrls[index] == nil, // Fetch only if URL not known yet.
              let media = media else {
                  didCompleteImageFetch()
                  return
              }

        viewModel?.getMediaPreviewImageUrl(media,
                                           index) { [weak self] url in
            self?.viewModel?.mediaBrowsingViewModel.didLoadUrl(url, at: index)
            self?.reloadVisibleCell()
        }
    }

    /// Reloads current visible collectionView cell.
    func reloadVisibleCell() {
        guard let visibleIndex = visibleIndex,
              visibleIndex < resourcesCount else { return }
        itemsCollectionView.reloadItems(at: [IndexPath(item: visibleIndex, section: 0)])
    }

    /// Updates VM after image fetch is completed.
    func didCompleteImageFetch() {
        // Force isLoading to `true` if currently displayed image is fake blurred pano.
        // (Need to ignore autohide timer and keep controls visible in this case.)
        // Set isLoading to `false` otherwise, as image fetch has been completed.
        let isLoading = hasAdditionalPanoramaGenerationImage && visibleIndex == 0
        viewModel?.mediaBrowsingViewModel.didUpdateLoadingState(isLoading: isLoading)
    }

}

// MARK: - Actions
private extension GalleryImageViewController {

    /// Shows panorama generation view.
    func generatePanorama() {
        guard let viewModel = viewModel,
              let media = media,
              let mediaIndex = viewModel.getMediaIndex(media) else {
                  return
              }

        let galleryPanoramaViewModel = GalleryPanoramaViewModel(galleryMediaViewModel: viewModel,
                                                                coordinator: coordinator,
                                                                mediaIndex: mediaIndex)
        coordinator?.showPanoramaGenerationScreen(viewModel: galleryPanoramaViewModel, index: mediaIndex)
    }

    /// Shows immersive panorama view.
    func showImmersivePanorama() {
        guard let viewModel = viewModel else { return }
        let mediaUrls = viewModel.mediaBrowsingViewModel.mediaUrls
        guard mediaUrls.count > imageIndex,
              let url = mediaUrls[imageIndex] else {
            return
        }

        coordinator?.showPanoramaVisualisationScreen(viewModel: viewModel, url: url)
    }
}

// MARK: - Private Funcs
private extension GalleryImageViewController {
    /// Updates view model with media info and fetches image.
    func displayMedia() {
        guard let viewModel = viewModel,
              let media = media,
              let mediaIndex = viewModel.getMediaIndex(media) else {
                  return
              }

        viewModel.mediaBrowsingViewModel.didDisplayMedia(media, index: mediaIndex, count: resourcesCount)
        fetchImage(at: urlIndex(imageIndex))
    }

    /// Setup default image index.
    func setupDefaultImageIndex() {
        guard let viewModel = viewModel,
              let media = media else {
            return
        }

        imageIndex = viewModel.getMediaImageDefaultIndex(media)
        viewModel.mediaBrowsingViewModel.didDisplayResourceAt(imageIndex)
        DispatchQueue.main.async {
            // Need to dispatch scrolling to defaultIndex, as collectionView may not be visible yet.
            // => visibleIndex not updated.
            self.gotoImageAtIndex(self.imageIndex)
        }
    }

    /// Scrolls collectionView to a specific index and fetches corresponding image.
    /// - Parameters:
    ///     - index: The index of the resource to display.
    func gotoImageAtIndex(_ index: Int) {
        guard index != visibleIndex else { return }

        fetchImage(at: urlIndex(index))
        let indexPath = IndexPath.init(item: index, section: 0)
        itemsCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
    }

    /// The collectionView index of currently displayed cell.
    private var visibleIndex: Int? {
        let visibleRect = CGRect(origin: itemsCollectionView.contentOffset, size: itemsCollectionView.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)

        return itemsCollectionView.indexPathForItem(at: visiblePoint)?.item
    }
}

// MARK: - UIScrollView Delegate
extension GalleryImageViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == itemsCollectionView,
              let visibleIndex = visibleIndex else {
            return
        }

        viewModel?.mediaBrowsingViewModel.didDisplayResourceAt(visibleIndex)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == itemsCollectionView,
              let visibleIndex = visibleIndex else {
            return
        }

        fetchImage(at: urlIndex(visibleIndex))
    }
}

// MARK: - UICollectionView DataSource
extension GalleryImageViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        resourcesCount
    }

    func urlIndex(_ item: Int) -> Int {
        hasAdditionalPanoramaGenerationImage
            ? max(0, item - 1)
            : item
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(for: indexPath) as GalleryMediaFullScreenCollectionViewCell

        let urlIndex = urlIndex(indexPath.item)
        guard urlIndex < viewModel?.mediaBrowsingViewModel.mediaUrls.count ?? 0 else { return cell }

        cell.delegate = self
        cell.model = GalleryMediaFullScreenCellModel(url: viewModel?.mediaBrowsingViewModel.mediaUrls[urlIndex],
                                                     isAdditionalPanoramaCell: hasAdditionalPanoramaGenerationImage && indexPath.item == 0,
                                                     panoramaGenerationState: media?.panoramaGenerationState ?? .none,
                                                     hasShowImmersivePanoramaButton: (media?.canShowImmersivePanorama ?? false) && indexPath.item == 0,
                                                     galleryMediaViewModel: viewModel)

        return cell
    }
}

// MARK: - GalleryMediaFullScreenCell Delegate
extension GalleryImageViewController: GalleryMediaFullScreenCellDelegate {
    func fullScreenCellDidStartLoading() {
        viewModel?.mediaBrowsingViewModel.didUpdateLoadingState(isLoading: true)
    }

    func fullScreenCellDidStopLoading() {
        didCompleteImageFetch()
    }

    func fullScreenCellDidTapGeneratePanorama() {
        generatePanorama()
    }

    func fullScreenCellDidTapShowImmersivePanorama() {
        showImmersivePanorama()
    }

    func fullScreenCellDidStartZooming() {
        viewModel?.mediaBrowsingViewModel.didInteractForControlsDisplay(false)
    }

    func fullScreenCellDidStopZooming() {
        viewModel?.mediaBrowsingViewModel.didUpdateZoomLevel(.custom)
    }
}
