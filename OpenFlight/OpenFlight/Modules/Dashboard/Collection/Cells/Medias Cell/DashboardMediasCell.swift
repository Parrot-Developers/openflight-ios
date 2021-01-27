// Copyright (C) 2020 Parrot Drones SAS
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
import Reusable

/// Custom View used to show medias and infos about storage.
final class DashboardMediasCell: UICollectionViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var storageIcon: UIImageView!
    @IBOutlet private weak var freeStorageLabel: UILabel!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var mediasLabel: UILabel!
    @IBOutlet private weak var remainingPhotosLabel: UILabel!
    @IBOutlet private weak var remainingVideosLabel: UILabel!

    // MARK: - Private Properties
    private enum Constants {
        static let cellSize: CGFloat = 45.0
        static let cellSpacing: CGFloat = 4.0
        static let maximumNumberOfItems: Int = 3
    }

    // MARK: - Internal Properties
    weak var viewModel: GalleryMediaViewModel?

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()
        initCollectionView()
        updateView()
    }
}

// MARK: - Collection View data source
extension DashboardMediasCell: UICollectionViewDataSource {
    internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(for: indexPath) as DashboardMediasSubCell
        guard let viewModel = viewModel,
            let media = viewModel.getMedia(index: indexPath.row) else {
                return cell
        }

        cell.setup(media: media,
                   mediaStore: viewModel.mediaStore,
                   index: viewModel.getMediaImageDefaultIndex(media))

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let viewModel = viewModel else { return 0 }

        return min(Constants.maximumNumberOfItems, viewModel.numberOfMedias)
    }
}

// MARK: - CollectionView FlowLayout Delegate
extension DashboardMediasCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: Constants.cellSize, height: Constants.cellSize)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
}

// MARK: - Internal Funcs
extension DashboardMediasCell: CellConfigurable {
    func setup(state: ViewModelState) {
        updateView()
        collectionView.reloadData()
    }
}

// MARK: - Private Funcs
private extension DashboardMediasCell {
    /// Init the collection view of the cell.
    func initCollectionView() {
        collectionView.register(cellType: DashboardMediasSubCell.self)
        let flowLayout = DashboardMediasCellFlowLayout()
        flowLayout.minimumInteritemSpacing = Constants.cellSpacing
        flowLayout.scrollDirection = .horizontal
        collectionView.collectionViewLayout = flowLayout
    }

    /// Update the view of the cell.
    func updateView() {
        guard let viewModel = viewModel else { return }

        storageIcon.image = viewModel.sourceType?.image
        freeStorageLabel.attributedText = NSMutableAttributedString(withAvailableSpace: viewModel.getAvailableSpace())
        mediasLabel.text = L10n.dashboardMediasTitle
        remainingPhotosLabel.text = String(format: "%02d", viewModel.numberOfImages)
        remainingVideosLabel.text = String(format: "%02d", viewModel.numberOfVideos)
    }
}
