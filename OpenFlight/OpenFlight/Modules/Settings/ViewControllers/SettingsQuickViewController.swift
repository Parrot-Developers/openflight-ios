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
import Reusable
import GroundSdk

/// This is a specific settings display (collection view) used as shortcuts.
/// Quick settings will reuse as much a possible setting content and its children logic.
final class SettingsQuickViewController: UIViewController, StoryboardBased {
    // MARK: - Outlets
    @IBOutlet private weak var collection: UICollectionView!

    // MARK: - Private Properties
    private weak var coordinator: Coordinator?
    private let viewModel = QuickSettingsViewModel()
    private var settings: [SettingEntry] = [] {
        didSet {
            collection?.reloadData()
            self.collection.isUserInteractionEnabled = true
        }
    }
    /// Some settings may not be available regarding drone state.
    private var filteredSettings: [SettingEntry] {
        return settings.filter({ $0.setting != nil })
    }

    // MARK: - Private Enums
    private enum Constants {
        static let cellSize: CGSize = CGSize(width: 110, height: 110)
        static let defaultCellMargin: CGFloat = 10.0
        static let cellSpacing: CGFloat = 10.0
        static let sideMargin: CGFloat = 16.0
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        setupCollection()

        // watch current drone.
        viewModel.state.valueChanged = { [weak self] _ in
            self?.updateCells()
        }

        updateCells()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
}

// MARK: - Private Funcs
private extension SettingsQuickViewController {
    /// setup collection.
    func setupCollection() {
        collection.backgroundColor = self.view.backgroundColor
        if let flowLayout = collection.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.itemSize = Constants.cellSize
            flowLayout.estimatedItemSize = CGSize.zero // use fixed size
            flowLayout.scrollDirection = .vertical
            flowLayout.sectionInset.right = Constants.sideMargin
            flowLayout.sectionInset.left = Constants.sideMargin
            let insetsTopBottom = (view.bounds.height - (collection.bounds.height))
                / 2.0
            flowLayout.sectionInset.top = insetsTopBottom
            flowLayout.sectionInset.bottom = insetsTopBottom
            flowLayout.minimumLineSpacing = Constants.cellSpacing
        }
        collection.register(cellType: SettingsQuickCollectionViewCell.self)
    }

    func updateCells() {
        settings = viewModel.settingEntries
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
        cell.configureCell(settingEntry: settingEntry,
                           atIndexPath: indexPath,
                           delegate: self)
        cell.backgroundColor = settingEntry.bgColor

        return cell
    }
}

// MARK: - Settings quick collection view cell delegate
extension SettingsQuickViewController: SettingsQuickCollectionViewCellDelegate {
    func settingsQuickCellWillSwipe() {
        self.collection.isUserInteractionEnabled = false
    }

    func settingsQuickCelldidSwipe(_ direction: UISwipeGestureRecognizer.Direction, at indexPath: IndexPath) {
        let settingEntry = filteredSettings[indexPath.row]
        if let model = settingEntry.segmentModel {
            let index = (direction == .left) ? model.nextIndex : model.previousIndex
            viewModel.saveSettingsEntry(settingEntry, at: index)
        }
    }
}
