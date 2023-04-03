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

/// Displays medias.

final class GalleryMediaViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var collection: UICollectionView!

    // MARK: - Private Properties
    private var viewModel: GalleryViewModel!
    private var cancellables = Set<AnyCancellable>()
    private var dataSource: [(date: Date, medias: [GalleryMedia])] = []

    private var selectedMedias: [GalleryMedia] = []

    // MARK: - Private Enums
    private enum Constants {
        static let nbColumnsLandscape: CGFloat = 4.0
        static let itemSpacing: CGFloat = 2.0
        static let itemTitleHeight: CGFloat = 37.0
        static let headerHeight: CGFloat = 26.0
        static let longPressDuration: TimeInterval = 0.5
        static let collectionViewInsets: UIEdgeInsets = .init(top: 0, left: 0, bottom: 12, right: 0)
    }

    // MARK: - Setup
    /// Instantiates view controller.
    ///
    /// - Parameter viewModel: the gallery view model
    /// - Returns: a `GalleryMediaViewController`
    static func instantiate(viewModel: GalleryViewModel) -> GalleryMediaViewController {
        let viewController = StoryboardScene.GalleryComponentsViewController.galleryMediaViewController.instantiate()
        viewController.viewModel = viewModel

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        setupCollection()

        viewModel.$filteredMediaData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] list in
            guard let self = self else { return }
            self.dataSource = list
            self.collection.reloadData()
        }
        .store(in: &cancellables)

        viewModel.$activeActionTypes
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] types in
                self?.updateSelectionMode(isEnabled: types.contains(.select))
            }
            .store(in: &cancellables)

        viewModel.selectedMediaUidsPublisher.removeDuplicates()
            .combineLatest(viewModel.downloadIdsPublisher)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.collection.reloadData()
            }
            .store(in: &cancellables)

        viewModel.storageSourceTypePublisher
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self = self, !self.dataSource.isEmpty else { return }
                self.collection.scrollToItem(at: .init(item: 0, section: 0), at: .centeredVertically, animated: false)
            }
            .store(in: &cancellables)
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
        collection.contentInset = .init(top: 0, left: 0, bottom: 0, right: Layout.mainSpacing(isRegularSizeClass))
    }

    /// Handle download.
    ///
    /// - Parameter medias: list of medias to download
    func handleDownload(_ medias: [GalleryMedia]) {
        viewModel.download(medias: medias)
    }

    /// Handle long press on collection view cell.
    ///
    /// - Parameters:
    ///     - longPress: reference to the gesture recognizer
    @objc func handleLongPress(longPress: UILongPressGestureRecognizer) {
        guard collection.allowsMultipleSelection == false,
              let indexPath = collection.indexPathForItem(at: longPress.location(in: collection)) else {
            return
        }

        viewModel.setSelectMode(true)

        DispatchQueue.main.async {
            self.collectionView(self.collection, didSelectItemAt: indexPath)
        }
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

        let media = dataSource[indexPath.section].medias[indexPath.row]
        cell.setup(media: media,
                   delegate: self,
                   selected: viewModel.isSelected(uid: media.droneMediaIdentifier),
                   actionState: viewModel.actionState(of: media),
                   isDownloadAvailable: !viewModel.isActionActive(.select))

        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let cell = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                                       for: indexPath,
                                                                       viewType: GalleryMediaCollectionReusableView.self)
            let date = Array(dataSource)[indexPath.section].date
            cell.setup(date: date)
            return cell
        }

        return UICollectionReusableView()
    }
}

// MARK: - CollectionView Delegate
extension GalleryMediaViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let media = dataSource[indexPath.section].medias[indexPath.row]
        viewModel.didSelectMedia(media)
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
        if dataSource[indexPath.section].medias[indexPath.row].cellTitle.isEmpty == false {
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

private extension GalleryMediaViewController {
    func updateSelectionMode(isEnabled: Bool) {
        collection.allowsMultipleSelection = isEnabled
        DispatchQueue.main.async {
            self.collection.reloadData()
        }
    }
}
