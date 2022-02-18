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

/// Utility extension for `UICollectionViewCell`.

extension UICollectionView {
    /// Returns `IndexPath` of the cell which is closer to the horizontal center of the collection.
    var closestToHorizontalCenterIndexPath: IndexPath? {
        guard var closestCell: UICollectionViewCell = self.visibleCells.first else {
            return nil
        }
        for cell in self.visibleCells {
            let closestCellDelta = abs(closestCell.center.x - self.bounds.size.width / 2.0 - self.contentOffset.x)
            let cellDelta = abs(cell.center.x - self.bounds.size.width / 2.0 - self.contentOffset.x)
            if cellDelta < closestCellDelta {
                closestCell = cell
            }
        }
        return self.indexPath(for: closestCell)
    }

    /// Returns `IndexPath` of the interactive cell which is closer to the horizontal center of the collection.
    var closestInteractiveToHorizontalCenterIndexPath: IndexPath? {
        guard var closestCell: UICollectionViewCell = self.visibleCells.first(where: { $0.isUserInteractionEnabled }) else {
            return nil
        }
        for cell in self.visibleCells {
            let closestCellDelta = abs(closestCell.center.x - self.bounds.size.width / 2.0 - self.contentOffset.x)
            let cellDelta = abs(cell.center.x - self.bounds.size.width / 2.0 - self.contentOffset.x)
            if cellDelta < closestCellDelta, cell.isUserInteractionEnabled {
                closestCell = cell
            }
        }
        return self.indexPath(for: closestCell)
    }

    /// Returns `IndexPath` of the cell which is closer to the vertical center of the collection.
    var closestToVerticalCenterIndexPath: IndexPath? {
        guard var closestCell = self.visibleCells.first else {
            return nil
        }
        for cell in self.visibleCells {
            let closestCellDelta = abs(closestCell.center.y - self.bounds.size.height / 2.0 - self.contentOffset.y)
            let cellDelta = abs(cell.center.y - self.bounds.size.height / 2.0 - self.contentOffset.y)
            if cellDelta < closestCellDelta {
                closestCell = cell
            }
        }
        return self.indexPath(for: closestCell)
    }

    /// Returns true if given `IndexPath` is the last of the collection.
    func isLast(indexPath: IndexPath) -> Bool {
        let lastSectionIndex = self.numberOfSections - 1
        let lastRowIndex = self.numberOfItems(inSection: lastSectionIndex) - 1
        return indexPath == IndexPath(row: lastRowIndex, section: lastSectionIndex)
    }

    /// Sets placeholder image when collectionView is empty.
    func setEmptyPlaceholder() {
        let placeholderImageView = UIImageView()
        placeholderImageView.image = Asset.Dashboard.icGalleryEmpty.image
        placeholderImageView.contentMode = .scaleAspectFit
        placeholderImageView.tintColor = ColorName.defaultTextColor.color
        self.backgroundView = placeholderImageView
        // Auto Layout
        placeholderImageView.translatesAutoresizingMaskIntoConstraints = false
        placeholderImageView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        placeholderImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
    }

    /// Restores collectionView background.
    func restore() {
        self.backgroundView = nil
    }
}
