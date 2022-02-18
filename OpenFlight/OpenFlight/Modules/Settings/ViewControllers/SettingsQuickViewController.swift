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
import Reusable
import GroundSdk

/// This is a specific settings display (collection view) used as shortcuts.
/// Quick settings will reuse as much a possible setting content and its children logic.
final class SettingsQuickViewController: UIViewController, StoryboardBased {
    // MARK: - Outlets
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var collectionViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var collectionViewHeightConstraint: NSLayoutConstraint!

    // MARK: - Private Properties
    // TODO wrong injection, viewModel should be prepared one level up (coordinator or upper VM)
    private let viewModel = QuickSettingsViewModel(obstacleAvoidanceMonitor: Services.hub.obstacleAvoidanceMonitor)
    private var settings: [SettingEntry] = [] {
        didSet {
            guard let indexPath = settingTappedIndexPath else { return }
            collectionView.reloadItems(at: [indexPath])
        }
    }
    private var settingTappedIndexPath: IndexPath?
    private var filteredSettings: [SettingEntry] {
        return settings.filter({ $0.setting != nil })
    }
    private var itemSpacing: (compact: CGFloat, regular: CGFloat) = (10, 15)
    private var itemWidth: (compact: CGFloat, regular: CGFloat) = (150, 200)
    private var itemHeight: (compact: CGFloat, regular: CGFloat) = (120, 160)
    private var itemSize: CGSize {
        return isRegularSizeClass
        ? CGSize.init(width: itemWidth.regular, height: itemHeight.regular)
        : CGSize.init(width: itemWidth.compact, height: itemHeight.compact)
    }
    private var valueInterSpaceItem: CGFloat { isRegularSizeClass ? itemSpacing.regular : itemSpacing.compact }
    private var valueInterLineRowItem: CGFloat { isRegularSizeClass ? itemSpacing.regular : itemSpacing.compact }
    private var valueMaxItemsPerRow: CGFloat = 3

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        setupViewModel()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
}

private extension SettingsQuickViewController {
    /// Inits view.
    func initView() {
        setupCollectionViewLayout()
        collectionView.register(cellType: SettingsQuickCollectionViewCell.self)
    }

    /// Sets up view model.
    func setupViewModel() {
        // watch current drone.
        viewModel.state.valueChanged = { [weak self] _ in
            self?.updateCells()
        }
        updateCells()
    }

    func setupCollectionViewLayout() {
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }

        // updates collection view size
        let maxItemPerRow: CGFloat = valueMaxItemsPerRow
        let maxItemPerLine = ceil(CGFloat(filteredSettings.count) / valueMaxItemsPerRow)

        let maxInterItem = maxItemPerRow > 1 ? maxItemPerRow - 1 : 1
        let maxInterLine = maxItemPerLine > 1 ? maxItemPerLine - 1 : 1
        collectionViewWidthConstraint.constant = maxItemPerRow * itemSize.width + maxInterItem * valueInterSpaceItem
        collectionViewHeightConstraint.constant = maxItemPerLine * itemSize.height + maxInterLine * valueInterLineRowItem

        // updates layout
        layout.estimatedItemSize = CGSize.zero
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = valueInterSpaceItem
        layout.minimumLineSpacing = valueInterLineRowItem
        layout.itemSize = CGSize(width: itemSize.width, height: itemSize.height)
    }

    func updateCells() {
        settings = viewModel.settingEntries
        setupCollectionViewLayout()
    }
}

// MARK: - UICollectionView DataSource
extension SettingsQuickViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredSettings.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: SettingsQuickCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)

        let settingEntry = filteredSettings[indexPath.row]
        cell.configureCell(settingEntry: settingEntry, atIndexPath: indexPath, delegate: self)
        cell.backgroundColor = settingEntry.bgColor
        return cell
    }
}

// MARK: - Settings quick collection view cell delegate
extension SettingsQuickViewController: SettingsQuickCollectionViewCellDelegate {
    func settingsQuickCelldidTap(indexPath: IndexPath) {
        settingTappedIndexPath = indexPath
        let settingEntry = filteredSettings[indexPath.row]

        if let model = settingEntry.segmentModel {
            viewModel.saveSettingsEntry(settingEntry, at: model.nextIndex)
        }
    }
}
