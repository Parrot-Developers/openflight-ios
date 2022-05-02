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

// MARK: - Protocols
/// Delegate used to discuss with main controller.
protocol GalleryMediaViewDelegate: AnyObject {
    /// Called when an action was triggered by the multiple selection.
    func multipleSelectionActionTriggered()
    /// Called when the multiple selection is enabled from here.
    func multipleSelectionEnabled()
    func didUpdateMediaSelection(count: Int, size: UInt64)
}

/// Displays medias.

final class GalleryMediaViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var collection: UICollectionView!

    // MARK: - Private Properties
    private var dataSource: [(key: Date, medias: [GalleryMedia])] = []
    private weak var coordinator: GalleryCoordinator?
    private weak var viewModel: GalleryMediaViewModel?
    private var loadingMedias: [GalleryMedia] = []
    private var unsortedMedias: [GalleryMedia] {
        dataSource.map({ $0.medias }).flatMap({ $0 })
    }
    private var selectedMedias: [GalleryMedia] = [] {
        didSet {
            delegate?.didUpdateMediaSelection(count: selectedMedias.count,
                                              size: selectedMediasSize)
        }
    }
    private var selectedMediasSize: UInt64 {
        return selectedMedias.reduce(0) { $0 + $1.size }
    }

    // MARK: - Internal Properties
    weak var delegate: GalleryMediaViewDelegate?

    // MARK: - Private Enums
    private enum Constants {
        static let nbColumnsLandscape: CGFloat = 4.0
        static let itemSpacing: CGFloat = 2.0
        static let itemTitleHeight: CGFloat = 37.0
        static let headerHeight: CGFloat = 26.0
        static let longPressDuration: TimeInterval = 0.5
        static let collectionViewInsets: UIEdgeInsets = .init(top: 0, left: 0, bottom: 12, right: 0)
    }

    // MARK: - Publishers
    @Published var isSharingMedia = false

    // MARK: - Setup
    /// Instantiate view controller.
    ///
    /// - Parameters:
    ///     - coordinator: gallery coordinator
    ///     - viewModel: gallery view model
    /// - Returns: a GalleryMediaViewController.
    static func instantiate(coordinator: GalleryCoordinator, viewModel: GalleryMediaViewModel) -> GalleryMediaViewController {
        let viewController = StoryboardScene.GalleryComponentsViewController.galleryMediaViewController.instantiate()
        viewController.coordinator = coordinator
        viewController.viewModel = viewModel

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .clear
        setupCollection()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel?.refreshMedias(source: viewModel?.sourceType)
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    /// Update display when orientation changed.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        collection.reloadData()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Private Funcs
private extension GalleryMediaViewController {
    /// Setup collection.
    func setupCollection() {
        collection.register(cellType: GalleryMediaCollectionViewCell.self)
        collection.register(supplementaryViewType: GalleryMediaCollectionReusableView.self,
                            ofKind: UICollectionView.elementKindSectionHeader)
        collection.dataSource = self
        collection.delegate = self
        collection.collectionViewLayout = GalleryMediaFlowLayout()
        collection.backgroundColor = .clear
        collection.contentInsetAdjustmentBehavior = .always
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(longPress:)))
        longPressGesture.minimumPressDuration = Constants.longPressDuration
        longPressGesture.delaysTouchesBegan = true
        collection.addGestureRecognizer(longPressGesture)
    }

    /// Handle download.
    ///
    /// - Parameters:
    ///     - medias: list of medias to download
    func handleDownload(_ medias: [GalleryMedia]) {
        loadingMedias = medias
        viewModel?.downloadMedias(loadingMedias, completion: { [weak self] success in
            guard success else { return }

            self?.handleDownloadEnd()
        })
    }

    /// Handle download end.
    func handleDownloadEnd() {
        let medias = loadingMedias.compactMap({ $0.mainMediaItem })
        guard medias.first(where: { $0.isDownloaded == false }) == nil else { return }

        medias.forEach { media in
            if let index = selectedMedias.firstIndex(where: { $0.uid == media.uid }) {
                selectedMedias[index].downloadState = .downloaded
            }
        }

        let deleteAction = AlertAction(title: L10n.commonDelete,
                                       style: .destructive,
                                       actionHandler: { [weak self] in
                                        // Delete loading medias.
                                        guard let medias = self?.loadingMedias else { return }

                                        self?.viewModel?.deleteMedias(medias, completion: { _ in
                                            self?.loadingMedias.removeAll()
                                            self?.viewModel?.refreshMedias()
                                            self?.delegate?.multipleSelectionActionTriggered()
                                        })
                                       })
        let keepAction = AlertAction(title: L10n.commonKeep,
                                     style: .validate,
                                     actionHandler: { [weak self] in
                                        // Remove loading files.
                                        self?.loadingMedias.removeAll()
                                        self?.viewModel?.refreshMedias()
                                     })
        let message = loadingMedias.count == 1 ? L10n.galleryDownloadKeep : L10n.galleryDownloadKeepPlural
        showAlert(title: L10n.galleryDownloadComplete,
                  message: message,
                  cancelAction: deleteAction,
                  validateAction: keepAction)
    }

    /// Handle delete.
    ///
    /// - Parameters:
    ///     - medias: list of medias to delete
    func handleDelete(_ medias: [GalleryMedia]) {
        viewModel?.deleteMedias(medias, completion: { [weak self] success in
            guard success else {
                DispatchQueue.main.async {
                    self?.showDeleteAlert(count: medias.count) { self?.handleDelete(medias) }
                }
                return
            }

            self?.viewModel?.refreshMedias()
        })
    }

    /// Handle delete media selection.
    func deleteSelection() {
        let medias = selectedMedias
        delegate?.multipleSelectionActionTriggered()
        handleDelete(medias)
    }

    /// Handle share.
    func handleShare(srcView: UIView) {
        // Inform the processing started.
        isSharingMedia = true
        Task {
            // Get list of selected media's urls.
            let urls = await selectedMediaPreviewImageUrls()
            // Update the UI in the main thread.
            DispatchQueue.main.async { [weak self] in
                // Display the sharing screen.
                self?.coordinator?.showSharingScreen(fromView: srcView, items: urls)
                // Sharing process finished.
                self?.isSharingMedia = false
            }
        }
    }

    /// Get the list of selected media's urls.
    ///
    /// - returns async:
    ///    - The selected medias' preview images `[URL]`.
    func selectedMediaPreviewImageUrls() async -> [URL] {
        // Generate a list of media/url-indexes tuple.
        let mediaIndexTuples = selectedMedias
            .compactMap { media in
                // Get list of media and url index tuples.
                media.urls?
                    .enumerated()
                    .map {(media, $0.offset)}
            }
            // Reduce tuples
            .reduce([], +)
        // Get urls for each tuples.
        var urls = [URL]()
        for mediaIndexTuple in mediaIndexTuples {
            if let url = try? await viewModel?.getMediaPreviewImageUrl(mediaIndexTuple.0,
                                                                       mediaIndexTuple.1) {
                urls.append(url)
            }
        }
        return urls
    }

    /// Handle long press on collection view cell.
    ///
    /// - Parameters:
    ///     - longPress: reference to the gesture recognizer
    @objc func handleLongPress(longPress: UILongPressGestureRecognizer) {
        guard collection.allowsMultipleSelection == false,
              let delegate = delegate,
              let indexPath = collection.indexPathForItem(at: longPress.location(in: collection)) else {
            return
        }

        delegate.multipleSelectionEnabled()
        collectionView(collection, didSelectItemAt: indexPath)
    }
}

// MARK: - CollectionView DataSource
extension GalleryMediaViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource[section].medias.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(for: indexPath) as GalleryMediaCollectionViewCell
        guard let viewModel = viewModel else { return cell }

        let media = dataSource[indexPath.section].medias[indexPath.row]
        cell.setup(media: media,
                   mediaStore: viewModel.mediaStore,
                   index: viewModel.getMediaImageDefaultIndex(media),
                   delegate: self,
                   selected: selectedMedias.first(where: { $0.uid == media.uid }) != nil)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let cell = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                                       for: indexPath,
                                                                       viewType: GalleryMediaCollectionReusableView.self)
            let date = Array(dataSource)[indexPath.section].key
            cell.setup(date: date)
            return cell
        }

        return UICollectionReusableView()
    }
}

// MARK: - CollectionView Delegate
extension GalleryMediaViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let viewModel = viewModel else { return }

        let media = dataSource[indexPath.section].medias[indexPath.row]

        if collectionView.allowsMultipleSelection {
            if let index = selectedMedias.firstIndex(where: { $0.uid == media.uid }) {
                selectedMedias.remove(at: index)
            } else {
                selectedMedias.append(media)
            }

            collectionView.reloadData()
        } else if let index = viewModel.state.value.filteredMedias.firstIndex(of: media) {
            coordinator?.showMediaPlayer(viewModel: viewModel, index: index)
        }
    }
}

// MARK: - CollectionView FlowLayout Delegate
extension GalleryMediaViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Remove left and right insets
        var collectionViewWidth = collectionView.frame.width
        // Handle safe area screens.
        collectionViewWidth -= collectionView.adjustedContentInset.left + collectionView.adjustedContentInset.right
        // Compute width.

        let width = collectionViewWidth / Constants.nbColumnsLandscape - Constants.itemSpacing

        // Prevent from issue when rotate.
        guard width >= 0.0 else { return CGSize() }
        var height = width
        if dataSource[indexPath.section].medias[indexPath.row].cellTitle?.isEmpty == false {
            height += Constants.itemTitleHeight
        }

        return CGSize(width: width, height: height)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return Constants.itemSpacing
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return Constants.itemSpacing
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        Constants.collectionViewInsets
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: Constants.headerHeight)
    }

    private class GalleryMediaFlowLayout: UICollectionViewFlowLayout {

        // Align on top rows that contains items with title and others without title
        override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
            guard let attributes = super.layoutAttributesForElements(in: rect) else {
                return nil
            }
            let cells = attributes.filter { $0.representedElementCategory == .cell && $0.representedElementKind == nil }
            var alignedRows = [IndexPath]() // Section and literal row (not item)
            for attribute in cells {
                let rowIndex = IndexPath(row: row(of: attribute.indexPath),
                                         section: attribute.indexPath.section)
                if alignedRows.contains(rowIndex) {
                    continue
                }
                let sameRow = cells.filter { $0.indexPath.section == rowIndex.section && row(of: $0.indexPath) == rowIndex.row }
                let minY = sameRow.map { $0.frame.minY }.min() ?? 0
                sameRow.forEach {$0.frame.origin.y = minY }
                alignedRows.append(rowIndex)
            }
            return attributes
        }

        private func row(of indexPath: IndexPath) -> Int {
            return Int(floor(CGFloat(indexPath.row) / Constants.nbColumnsLandscape))
        }
    }
}

// MARK: - GalleryMediaCell Delegate
extension GalleryMediaViewController: GalleryMediaCellDelegate {
    func shouldDownloadMedia(_ media: GalleryMedia) {
        if !collection.allowsMultipleSelection {
            handleDownload([media])
        }
    }
}

// MARK: - GalleryView Delegate
extension GalleryMediaViewController: GalleryViewDelegate {
    func stateDidChange(state: GalleryMediaState) {
        dataSource = state.mediasByDate
        collection.reloadData()
    }

    func multipleSelectionDidChange(enabled: Bool) {
        collection.allowsMultipleSelection = enabled
        if !collection.allowsMultipleSelection {
            selectedMedias.removeAll()
            collection.reloadData()
        }
    }

    func sourceDidChange(source: GallerySourceType) {
        if collection.allowsMultipleSelection {
            selectedMedias.removeAll()
            collection.reloadData()
        }

        viewModel?.setSourceType(type: source)
        viewModel?.setSelectedMediaTypes(types: [])
        viewModel?.refreshMedias()
    }
}

// MARK: - Gallery Selection View Delegate.
extension GalleryMediaViewController: GallerySelectionDelegate {
    func mustDeleteSelection() {
        let fromDrone = selectedMedias.contains { $0.source != .mobileDevice }
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

        let deleteAction = AlertAction(title: L10n.commonDelete,
                                       style: .destructive,
                                       isActionDelayedAfterDismissal: false,
                                       actionHandler: { [weak self] in
                                        self?.deleteSelection()
                                       })
        let cancelAction = AlertAction(title: L10n.cancel,
                                       style: .default2,
                                       actionHandler: {})
        let message: String = viewModel?.sourceType.deleteConfirmMessage(count: selectedMedias.count) ?? ""
        showAlert(title: L10n.commonDelete,
                  message: message,
                  cancelAction: cancelAction,
                  validateAction: deleteAction)
    }

    func mustDownloadSelection() {
        let medias = selectedMedias
        delegate?.multipleSelectionEnabled()
        handleDownload(medias)
    }

    func mustShareSelection(srcView: UIView) {
        handleShare(srcView: srcView)
    }

    func mustSelectAll() {
        selectedMedias = unsortedMedias
        collection.reloadData()
    }

    func mustDeselectAll() {
        selectedMedias.removeAll()
        collection.reloadData()
    }
}

private extension GalleryMediaViewController {
    /// Shows an alert when delete process fails.
    ///
    /// - Parameters:
    ///     - count: Selected medias count (used for plural or singular message selection).
    ///     - retryAction: Delete retry action to perform.
    func showDeleteAlert(count: Int, retryAction: @escaping () -> Void) {
        let retryAction = AlertAction(title: L10n.commonRetry,
                                      style: .destructive,
                                      isActionDelayedAfterDismissal: false,
                                      actionHandler: retryAction)
        let cancelAction = AlertAction(title: L10n.cancel,
                                       style: .default2,
                                       isActionDelayedAfterDismissal: false) {}
        let message: String = viewModel?.sourceType.deleteErrorMessage(count: count) ?? ""

        showAlert(title: L10n.error,
                  message: message,
                  cancelAction: cancelAction,
                  validateAction: retryAction)
    }
}
