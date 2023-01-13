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
import Combine

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
    @IBOutlet private weak var collectionViewHeightConstraint: NSLayoutConstraint!

    // MARK: - Private Properties
    private var viewModel: GalleryViewModel!
    private var dataSource: [GalleryFilterItem] = []
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Private Enums
    private enum Constants {
        static let cellHeight: CGFloat = 37
    }

    // MARK: - Setup
    static func instantiate(viewModel: GalleryViewModel) -> GalleryFiltersViewController {
        let viewController = StoryboardScene.GalleryComponentsViewController.galleryFiltersViewController.instantiate()
        viewController.viewModel = viewModel
        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        view.layoutMargins = .init(top: Layout.mainPadding(isRegularSizeClass), left: 0, bottom: Layout.mainSpacing(isRegularSizeClass), right: 0)
        setupCollection()

        viewModel.$filterItems
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                guard let self = self else { return }
                self.dataSource = items
                self.collection.reloadData()
        }
        .store(in: &cancellables)
    }
}

// MARK: - Private Funcs
private extension GalleryFiltersViewController {
    /// Setup collection.
    func setupCollection() {
        collection.register(cellType: GalleryFilterCollectionViewCell.self)
        collection.dataSource = self
        collection.delegate = self
        collectionViewHeightConstraint.constant = Constants.cellHeight + Layout.mainPadding(isRegularSizeClass) + Layout.mainSpacing(isRegularSizeClass)
        collection.contentInset = .init(top: 0, left: 0, bottom: 0, right: Layout.mainPadding(isRegularSizeClass))
    }
}

// MARK: - CollectionView DataSource
extension GalleryFiltersViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(for: indexPath) as GalleryFilterCollectionViewCell
        let item = dataSource[indexPath.row]
        cell.setup(type: item.type,
                   itemCount: item.count,
                   highlight: viewModel.isFilterMediaTypeSelected(item.type))
        return cell
    }
}

// MARK: - CollectionView Delegate
extension GalleryFiltersViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.didSelect(filterMediaType: dataSource[indexPath.row].type)
    }
}
