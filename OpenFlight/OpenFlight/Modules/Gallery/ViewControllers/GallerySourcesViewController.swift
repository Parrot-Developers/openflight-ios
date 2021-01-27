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
/// Delegate used to discuss with main controller.
protocol GallerySourcesViewDelegate: class {
    /// Called when the source did change.
    func sourceDidChange(source: GallerySourceType)
}

/// Displays medias sources.
final class GallerySourcesViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var collection: UICollectionView!

    // MARK: - Private Properties
    private var dataSource: [GallerySource] = []
    private weak var coordinator: GalleryCoordinator?
    private weak var viewModel: GalleryMediaViewModel?
    private var gallerySDMediaViewModel: GallerySDMediaViewModel? = GallerySDMediaViewModel.shared
    private var galleryDeviceMediaViewModel: GalleryDeviceMediaViewModel? = GalleryDeviceMediaViewModel.shared
    private var sdCardListener: GallerySdMediaListener?
    private var deviceListener: GalleryDeviceMediaListener?

    // MARK: - Internal Properties
    weak var delegate: GallerySourcesViewDelegate?

    // MARK: - Private Enums
    private enum Constants {
        static let nbColumnsLandscape: CGFloat = 1.0
        static let nbColumnsPortrait: CGFloat = 3.0
        static let itemSpacing: CGFloat = 10.0
        static let cellHeight: CGFloat = 80.0
    }

    // MARK: - Setup
    /// Instantiate view controller.
    ///
    /// - Parameters:
    ///     - coordinator: gallery coordinator
    ///     - viewModel: gallery view model
    /// - Returns: a GallerySourcesViewController.
    static func instantiate(coordinator: GalleryCoordinator, viewModel: GalleryMediaViewModel) -> GallerySourcesViewController {
        let viewController = StoryboardScene.GalleryComponentsViewController.gallerySourcesViewController.instantiate()
        viewController.coordinator = coordinator
        viewController.viewModel = viewModel

        return viewController
    }

    // MARK: - Deinit
    deinit {
        gallerySDMediaViewModel?.unregisterListener(sdCardListener)
        galleryDeviceMediaViewModel?.unregisterListener(deviceListener)
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = ColorName.black.color

        setupCollection()

        sdCardListener = gallerySDMediaViewModel?.registerListener(didChange: { [weak self] state in
            guard let strongSelf = self else { return }

            if let previousStorage = strongSelf.dataSource.first(where: { $0.type == .droneSdCard }),
                previousStorage.storageUsed.rounded(toPlaces: 1) == state.storageUsed.rounded(toPlaces: 1) {
                return
            }

            strongSelf.updateDataSource()
        })

        deviceListener = galleryDeviceMediaViewModel?.registerListener(didChange: { [weak self] state in
            guard let strongSelf = self else { return }

            if let previousStorage = strongSelf.dataSource.first(where: { $0.type == .mobileDevice }),
                previousStorage.storageUsed.rounded(toPlaces: 1) == state.storageUsed.rounded(toPlaces: 1) {
                return
            }

            strongSelf.updateDataSource()
        })

        updateDataSource()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        reloadContent()
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

        if let flowLayout = collection.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.scrollDirection = UIApplication.isLandscape ? .vertical : .horizontal
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Private Funcs
private extension GallerySourcesViewController {
    /// Setup collection.
    func setupCollection() {
        collection.register(cellType: GallerySourceCollectionViewCell.self)
        collection.dataSource = self
        collection.delegate = self
        collection.backgroundColor = .clear
        collection.contentInsetAdjustmentBehavior = .always
    }

    /// Update data source.
    func updateDataSource() {
        dataSource.removeAll()
        GallerySourceType.allCases.forEach { type in
            var storageUsed: Double = 0.0
            var storageCapacity: Double =  0.0
            var isOffline: Bool = true

            switch type {
            case .droneSdCard:
                if let sdState = gallerySDMediaViewModel?.state.value {
                    storageUsed = sdState.storageUsed
                    storageCapacity = sdState.capacity
                    isOffline = !(sdState.isConnected() && sdState.physicalStorageState == .available)
                }
            case .droneInternal:
                isOffline = true
            case .mobileDevice:
                storageUsed = UIDevice.current.usedStorageAsDouble
                storageCapacity = UIDevice.current.capacityAsDouble
                isOffline = false
            case .unknown:
                return
            }
            let source = GallerySource(type: type,
                                       storageUsed: storageUsed,
                                       storageCapacity: storageCapacity,
                                       isOffline: isOffline)
            dataSource.append(source)
        }

        reloadContent()
    }
}

// MARK: - Internal Funcs
internal extension GallerySourcesViewController {
    // Reload content.
    func reloadContent() {
        collection.reloadData()
    }
}

// MARK: - CollectionView DataSource
extension GallerySourcesViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(for: indexPath) as GallerySourceCollectionViewCell
        let source = dataSource[indexPath.row]
        cell.setup(source: source, isSelected: viewModel?.sourceType == source.type)
        cell.isUserInteractionEnabled = !source.isOffline

        return cell
    }
}

// MARK: - CollectionView Delegate
extension GallerySourcesViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let newType = dataSource[indexPath.row].type
        if viewModel?.sourceType != newType {
            delegate?.sourceDidChange(source: newType)
            collectionView.reloadData()
        }
    }
}

// MARK: - CollectionView FlowLayout Delegate
extension GallerySourcesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Remove top and bottom insets (2 * Constants.itemSpacing)
        var collectionViewHeight = collectionView.frame.height - 2 * Constants.itemSpacing
        // Handle safe area screens (bottom).
        collectionViewHeight -= UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0.0
        let height = UIApplication.isLandscape ? Constants.cellHeight : collectionViewHeight
        // Remove left and right insets (2 * Constants.itemSpacing)
        var collectionViewWidth = collectionView.frame.width - 2 * Constants.itemSpacing
        // Handle safe area screens (left).
        collectionViewWidth -= UIApplication.shared.keyWindow?.safeAreaInsets.left ?? 0.0
        // Compute width.
        let nbColumns = UIApplication.isLandscape ? Constants.nbColumnsLandscape : Constants.nbColumnsPortrait
        let width = collectionViewWidth / nbColumns

        // Prevent from issue when rotate.
        guard width >= 0.0, height >= 0.0 else { return CGSize() }

        return CGSize(width: width, height: height)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: Constants.itemSpacing,
                            left: Constants.itemSpacing,
                            bottom: Constants.itemSpacing,
                            right: Constants.itemSpacing)
    }
}
