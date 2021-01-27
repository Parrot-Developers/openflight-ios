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

// MARK: - Protocols
/// Delegate used to update container
protocol ContainterSizeDelegate: class {
    /// Called when the content height changed.
    ///
    /// - Parameters:
    ///     - height: content height
    func contentDidUpdateHeight(_ height: CGFloat)
}

// MARK: - Internal Structs
/// Struct for dataSource item.
struct GalleryFilterItem {
    var type: GalleryMediaType
    var count: Int
}

/// Displays medias filters.

final class GalleryFiltersViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var collection: UICollectionView!

    // MARK: - Private Properties
    private var contentHeight: CGFloat = 0.0
    private var dataSource: [GalleryFilterItem] = []
    private weak var coordinator: GalleryCoordinator?
    private weak var viewModel: GalleryMediaViewModel?

    // MARK: - Internal Properties
    weak var delegate: ContainterSizeDelegate?

    // MARK: - Private Enums
    private enum Constants {
        static let cellSpacing: CGFloat = 10.0
        static let topMargin: CGFloat = 0.0
    }

    // MARK: - Setup
    static func instantiate(coordinator: GalleryCoordinator, viewModel: GalleryMediaViewModel) -> GalleryFiltersViewController {
        let viewController = StoryboardScene.GalleryComponentsViewController.galleryFiltersViewController.instantiate()
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

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        adjustCollectionConstraints()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Private Funcs
private extension GalleryFiltersViewController {
    /// Setup collection.
    func setupCollection() {
        collection.register(cellType: GalleryFilterCollectionViewCell.self)
        collection.dataSource = self
        collection.delegate = self
        collection.backgroundColor = .clear
        let flowLayout = GalleryFiltersFlowLayout()
        flowLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        flowLayout.minimumInteritemSpacing = Constants.cellSpacing
        flowLayout.minimumLineSpacing = Constants.cellSpacing
        flowLayout.scrollDirection = .vertical
        flowLayout.sectionInset.right = Constants.cellSpacing
        flowLayout.sectionInset.left = Constants.cellSpacing
        collection.collectionViewLayout = flowLayout
    }

    /// Adjust collection constraints if required.
    func adjustCollectionConstraints() {
        let height = collection.collectionViewLayout.collectionViewContentSize.height
        if contentHeight != height {
            contentHeight = height
            self.delegate?.contentDidUpdateHeight(height)
        }
    }
}

// MARK: - CollectionView DataSource
extension GalleryFiltersViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(for: indexPath) as GalleryFilterCollectionViewCell
        guard let viewModel = viewModel else { return cell }
        let item = dataSource[indexPath.row]
        cell.setup(type: item.type,
                   itemCount: item.count,
                   highlight: (viewModel.selectedMediaTypes.contains(item.type)))
        return cell
    }
}

// MARK: - CollectionView Delegate
extension GalleryFiltersViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let viewModel = viewModel else { return }
        let item = dataSource[indexPath.row]
        var types = viewModel.selectedMediaTypes
        if types.contains(item.type) {
            types.removeAll(where: {$0 == item.type})
        } else {
            types.append(item.type)
        }
        viewModel.setSelectedMediaTypes(types: types)
    }
}

// MARK: - GalleryView Delegate
extension GalleryFiltersViewController: GalleryViewDelegate {
    func stateDidChange(state: GalleryMediaState) {
        var types = Array(Set(state.medias.map({ $0.type })))
        types.sort { $0.rawValue < $1.rawValue }
        self.dataSource.removeAll()
        types.forEach { type in
            let item = GalleryFilterItem(type: type, count: state.medias.filter({ $0.type == type }).count)
            self.dataSource.append(item)
        }
        self.collection.reloadData()
        adjustCollectionConstraints()
    }

    func multipleSelectionDidChange(enabled: Bool) {
        // No specific action for multiple selection on the filters view
    }

    func sourceDidChange(source: GallerySourceType) {
        // No specific action for source change on the filters view
    }
}
