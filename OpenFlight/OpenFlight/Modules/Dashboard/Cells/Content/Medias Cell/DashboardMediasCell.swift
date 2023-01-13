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

import Combine
import Reusable

/// Custom View used to show medias and infos about storage.
final class DashboardMediasCell: UICollectionViewCell, NibReusable {

    /// The cancellables.
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Outlets
    @IBOutlet private weak var sdCardFormatNeededIcon: UIImageView!
    @IBOutlet private weak var sdCardErrorLabel: UILabel!
    @IBOutlet private weak var storageIcon: UIImageView!
    @IBOutlet private weak var freeStorageLabel: UILabel!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var emptyImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!

    /// The medias displayed in the tile.
    private var medias = [GalleryMedia]() {
        didSet { updateMedias(with: medias) }
    }

    // MARK: - Private Properties
    private enum Constants {
        static let cellSpacing: CGFloat = 5.0
        static let maximumNumberOfItems: Int = 3
    }

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }

    func setup(viewModel: DashboardMediasViewModel) {
        viewModel.$medias
            .receive(on: DispatchQueue.main)
            .sink { [weak self] medias in
            self?.medias = medias
        }
        .store(in: &cancellables)

        viewModel.$sdCardErrorState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
            self?.updateSdCardErrorState(with: state)
        }
        .store(in: &cancellables)

        viewModel.$sourceDetails
            .receive(on: DispatchQueue.main)
            .sink { [weak self] details in
            self?.updateSourceDetails(with: details)
        }
        .store(in: &cancellables)
    }
}

// MARK: - Collection View data source
extension DashboardMediasCell: UICollectionViewDataSource {
    internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(for: indexPath) as DashboardMediasSubCell

        cell.setup(media: medias[indexPath.item])

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        medias.count
    }
}

// MARK: - CollectionView FlowLayout Delegate
extension DashboardMediasCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let maxNumberItems = CGFloat(Constants.maximumNumberOfItems)
        let cellWidth = (collectionView.frame.width
                         - Constants.cellSpacing * (maxNumberItems - 1))
                         / maxNumberItems
        return CGSize(width: cellWidth, height: collectionView.frame.height)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
}

// MARK: - Private Funcs
private extension DashboardMediasCell {

    /// Sets up view.
    func setupView() {
        titleLabel.text = L10n.dashboardMediasTitle
        initCollectionView()
        initSdCardFormatNeededIcon()
    }

    /// Init the collection view of the cell.
    func initCollectionView() {
        collectionView.register(cellType: DashboardMediasSubCell.self)
        let flowLayout = DashboardMediasCellFlowLayout()
        flowLayout.minimumInteritemSpacing = Constants.cellSpacing
        flowLayout.scrollDirection = .horizontal
        collectionView.collectionViewLayout = flowLayout
    }

    /// Inits the SD card format needed icon.
    func initSdCardFormatNeededIcon() {
        sdCardFormatNeededIcon.tintColor = ColorName.errorColor.color
        sdCardErrorLabel.makeUp(with: .mode, color: .errorColor)
        sdCardErrorLabel.text = L10n.alertNoSdcardErrorTitle.localizedUppercase
    }

    /// Updates medias collection.
    ///
    /// - Parameter medias: the medias array to update the cell with
    func updateMedias(with medias: [GalleryMedia]) {
        emptyImageView.isHidden = !medias.isEmpty
        collectionView.reloadData()
    }

    /// Updates source details.
    ///
    /// - Parameter details: the storage details to update the cell with
    func updateSourceDetails(with details: UserStorageDetails) {
        storageIcon.image = details.type.image?.withTintColor(ColorName.highlightColor.color)
        if let availableSpace = details.availableStorage {
            freeStorageLabel.attributedText = NSMutableAttributedString(withAvailableSpace: availableSpace)
            freeStorageLabel.accessibilityValue = "\(availableSpace)"
        } else {
            freeStorageLabel.text = "-"
        }
    }

    /// Updates SD card error state.
    ///
    /// - Parameter state: the error state to update the cell with
    func updateSdCardErrorState(with state: UserStorageState?) {
        if let state = state {
            sdCardFormatNeededIcon.animateIsHiddenInStackView(false)
            sdCardErrorLabel.animateIsHiddenInStackView(state != .notDetected)
        } else {
            sdCardFormatNeededIcon.animateIsHiddenInStackView(true)
            sdCardErrorLabel.animateIsHiddenInStackView(true)
        }
    }
}
