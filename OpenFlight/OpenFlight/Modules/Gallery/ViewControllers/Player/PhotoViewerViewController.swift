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
import Combine

private extension ULogTag {
    static let tag = ULogTag(name: "PhotoViewerVC")
}

/// A photo viewer view controller.
final class PhotoViewerViewController: UIViewController, MediaContainer {

    /// The `MediaContainer` media.
    var media: GalleryMedia { viewModel.media }

    // MARK: - Outlets
    @IBOutlet private weak var itemsCollectionView: UICollectionView!
    @IBOutlet private weak var pageControl: UIPageControl!

    // MARK: - Private Properties
    /// The photo viewer view model.
    private var viewModel: PhotoViewerViewModel!
    /// The browser manager.
    private var browserManager: MediaBrowserManager!
    /// The cancellables.
    private var cancellables = Set<AnyCancellable>()
    /// The prefetch tasks.
    private var prefetchTasks = [IndexPath: Task<Void, Error>]()
    /// The refetch task.
    /// Used whenever a cell is displayed and no corresponding fetch task is ongoing (can occur
    /// during quick scrolling).
    private var refetchTask: Task<Void, Error>?
    /// The page control initial transform (needed due to its vertical layout).
    private var pageControlInitialTransform: CGAffineTransform = .init(rotationAngle: .pi / 2)

    // MARK: - Constants
    private enum Constants {
        static let pageControlMargin: CGFloat = 30
        static let refetchDelay: TimeInterval = 1 // in seconds
    }

    // MARK: - Setup
    /// Instantiates view controller.
    ///
    /// - Parameters:
    ///   - viewModel: the photo viewer view model
    ///   - browserManager: the browser manager
    /// - Returns: a photo viewer view controller
    static func instantiate(viewModel: PhotoViewerViewModel,
                            browserManager: MediaBrowserManager) -> PhotoViewerViewController {
        let viewController = StoryboardScene.MediaBrowserViewController.galleryImageViewController.instantiate()
        viewController.viewModel = viewModel
        viewController.browserManager = browserManager

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        observeViewModel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Ensure resource is fetched (may be missed on quick scroll actions).
        refetchIfNeeded(at: 0)

        // Validate current media @didAppear in order to refresh parent UI components only
        // when view is fully displayed.
        browserManager.setActiveMedia(media, forceUpdate: true)
        browserManager.showControls()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        clearFetchTasks()
    }

    /// Observes view model and browser manager.
    func observeViewModel() {
        viewModel.$media
            .receive(on: DispatchQueue.main)
            .sink { [weak self] media in
                self?.load(media: media)
            }
            .store(in: &cancellables)

        browserManager.$areControlsShown
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] areShown in
                self?.showControls(areShown)
            }
            .store(in: &cancellables)

        viewModel.$zoomLevel
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] level in
                self?.zoom(to: level)
            }
            .store(in: &cancellables)
    }
}

private extension PhotoViewerViewController {

    /// Handles user interaction on page control.
    @IBAction func pageControlValueChanged(_ sender: UIPageControl) {
        let indexPath = IndexPath.init(item: sender.currentPage, section: 0)
        itemsCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
    }
}

private extension PhotoViewerViewController {

    /// Sets up UI elements.
    func setupUI() {
        setupCollectionView()

        // Rotate pageControl for vertical display.
        pageControl.transform = pageControlInitialTransform
        pageControl.numberOfPages = viewModel.itemsCount

        // Add double tap gesture recognizer for zoom handling.
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(doubleTapRecognized))
        doubleTapGesture.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTapGesture)
    }

    /// Sets up media resources collectionView.
    func setupCollectionView() {
        itemsCollectionView.register(cellType: PhotoViewerCell.self)

        itemsCollectionView.isPagingEnabled = true
        itemsCollectionView.contentInsetAdjustmentBehavior = .never
        itemsCollectionView.alwaysBounceVertical = true

        let layout = UICollectionViewFlowLayout()
        layout.itemSize = view.bounds.size
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0

        itemsCollectionView.collectionViewLayout = layout
    }

    /// Updates UI components based on current media.
    ///
    /// - Parameter media: the current media
    func load(media: GalleryMedia) {
        guard media.isSameMedia(as: browserManager.activeMedia) else { return }
        browserManager.setActiveMedia(media, forceUpdate: true)
        browserManager.showControls()
        itemsCollectionView.reloadData()
        pageControl.numberOfPages = viewModel.itemsCount
    }

    /// Shows/hides viewer controls (page control and optional immersive pano button).
    ///
    /// - Parameter show: whether the controls are shown
    func showControls(_ show: Bool) {
        // Show/hide cell controls (optional immersive pano button).
        viewerCell(at: resourceIndex)?.showControls(show)

        guard pageControl.numberOfPages > 1 else {
            pageControl.isHidden = true
            return
        }
        // Page control is already .pi / 2 rotated in order to be displayed vertically.
        // => Need to animate appearance from its .top edge.
        pageControl.showFromEdge(.top,
                                 offset: Constants.pageControlMargin,
                                 show: show,
                                 initialTransform: pageControlInitialTransform)
    }

    /// Informs view model that a double tap has been recognized.
    @objc func doubleTapRecognized() {
        viewModel.didDoubleTap()
    }

    /// Zooms active cell to specified level (requested by double touch events).
    ///
    /// - Parameter level: the level to zoom to
    func zoom(to level: PhotoViewerZoomLevel) {
        guard let cell = viewerCell(at: resourceIndex) else { return }
        cell.zoom(to: level)
    }
}

// MARK: - Fetch
private extension PhotoViewerViewController {

    /// Fetches resource at `resourceIndex` and load it to `cell`.
    /// An optional parameter can be provided in order to delay actual fetching.
    ///
    /// - Parameters:
    ///    - cell: the cell to load the resource to
    ///    - resourceIndex: the index of the resource to fetch
    ///    - delay: the delay to wait before triggering fetching (optional)
    ///    - clearRefetch: wether potential ongoing refetch task should be cleared
    func fetch(cell: PhotoViewerCell,
               at resourceIndex: Int,
               after delay: TimeInterval? = nil,
               clearRefetch: Bool = true) async throws {
        let image = try await browserManager.fetchResource(of: viewModel.media,
                                                           at: resourceIndex,
                                                           after: delay)
        ULog.i(.tag, "[galleryRework] Resource \(resourceIndex) fetched.")
        try Task.checkCancellation()

        if clearRefetch {
            clearRefetchTask()
        }

        DispatchQueue.main.async {
            cell.configure(image: image)
        }
        browserManager.startPrefetch(for: viewModel.media, around: resourceIndex)
    }

    /// Refetches resource at `resourceIndex` if needed (i.e. cell is still loading) after a 1 s delay.
    ///
    /// - Parameter resourceIndex: the index of the resource to refetch
    func refetchIfNeeded(at resourceIndex: Int) {
        guard let cell = viewerCell(at: resourceIndex),
              cell.model.isLoading else { return }

        // Cell at `resourceIndex` is still loading, which means prefetch is either still
        // running or won't be completed for this cell (can occur on quick scroll: willDisplay
        // may return the next cell) => force a refetch (after an optional delay).
        refetchTask = Task {
            ULog.i(.tag, "[galleryRework] Refetch \(resourceIndex).")
            try await fetch(cell: cell,
                            at: resourceIndex,
                            after: Constants.refetchDelay * 1_000_000_000,
                            clearRefetch: false)
        }
    }

    /// Clears all fetch tasks.
    func clearFetchTasks() {
        clearPrefetchTasks()
        clearRefetchTask()
    }

    /// Clears prefetch tasks.
    func clearPrefetchTasks() {
        for key in prefetchTasks.keys {
            prefetchTasks[key]?.cancel()
            prefetchTasks[key] = nil
        }
    }

    /// Clears refetch task.
    func clearRefetchTask() {
        refetchTask?.cancel()
        refetchTask = nil
    }
}

// MARK: - UIScrollView Delegate
extension PhotoViewerViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == itemsCollectionView else { return }

        pageControl.currentPage = resourceIndex
        browserManager.setActiveResourceIndex(resourceIndex)
        browserManager.showControls()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        refetchIfNeeded(at: resourceIndex)
    }
}

// MARK: - UICollectionView DataSource
extension PhotoViewerViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.itemsCount
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(for: indexPath) as PhotoViewerCell

        cell.delegate = self
        cell.model = PhotoViewerCellModel(url: viewModel.resourceUrl(for: indexPath.item),
                                          type: viewModel.cellType(for: indexPath.item))

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? PhotoViewerCell,
              cell.model.isLoading else { return }

        // Cell will display => start prefetch and store task with corresponding index.
        prefetchTasks[indexPath] = Task {
            try await fetch(cell: cell, at: viewModel.resourceIndex(for: indexPath.item))
        }
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // Display ended for cell => clear any prefetech task that may still be running.
        clearPrefetchTasks()
    }
}

// MARK: - GalleryMediaFullScreenCell Delegate
extension PhotoViewerViewController: PhotoViewerCellDelegate {

    func didTapGeneratePanorama() {
        browserManager.didTapGeneratePanorama()
    }

    func didTapShowImmersivePanorama() {
        browserManager.didTapShowImmersivePanorama()
    }

    func didStartZooming() {
        browserManager.hideControls()
    }

    func didStopZooming(at level: PhotoViewerZoomLevel) {
        viewModel.setZoomLevel(to: level)
    }
}

// MARK: - Helpers
private extension PhotoViewerViewController {

    /// The collectionView index of currently displayed cell.
    private var resourceIndex: Int {
        let visibleRect = CGRect(origin: itemsCollectionView.contentOffset, size: itemsCollectionView.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)

        return itemsCollectionView.indexPathForItem(at: visiblePoint)?.item ?? 0
    }

    private func viewerCell(at index: Int) -> PhotoViewerCell? {
        itemsCollectionView.cellForItem(at: .init(item: index, section: 0)) as? PhotoViewerCell
    }
}
