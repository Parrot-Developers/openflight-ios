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

// MARK: - DashboardMediasCellFlowLayoutRow
/// Custom row for the flow so we can adjust row layout.
class DashboardMediasCellFlowLayoutRow {
    // MARK: - Internal Properties
    var attributes = [UICollectionViewLayoutAttributes]()

    // MARK: - Private Properties
    private var spacing: CGFloat = 0.0
    private var rowWidth: CGFloat {
        let attributesWidth = attributes.reduce(0, { result, attribute -> CGFloat in
            return result + attribute.frame.width
        })
        let marginsWidth = spacing * CGFloat(attributes.count - 1)

        return attributesWidth + marginsWidth
    }

    // MARK: - Init
    ///
    /// - Parameters:
    ///     - spacing: spacing between cells
    init(spacing: CGFloat) {
        self.spacing = spacing
    }

    /// Adjust the row layout based on collection view width.
    ///
    /// - Parameters:
    ///     - width: collection view width
    func adjustLayout(to width: CGFloat) {
        var offset: CGFloat = 0.0
        if rowWidth < width {
            offset = (width - rowWidth) / 2
        }
        for attribute in attributes {
            attribute.frame.origin.x = offset
            offset += attribute.frame.width + spacing
        }
    }
}

// MARK: - DashboardMediasCellFlowLayout
/// Custom flow layout.
class DashboardMediasCellFlowLayout: UICollectionViewFlowLayout {
    // MARK: - Override Funcs
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let collectionView = collectionView,
            let attributes = super.layoutAttributesForElements(in: rect) else {
            return nil
        }

        var rows = [DashboardMediasCellFlowLayoutRow]()
        var currentRowYPosition: CGFloat = -1.0
        for attribute in attributes {
            if currentRowYPosition != attribute.frame.origin.y {
                currentRowYPosition = attribute.frame.origin.y
                rows.append(DashboardMediasCellFlowLayoutRow(spacing: minimumInteritemSpacing))
            }
            rows.last?.attributes.append(attribute)
        }
        rows.forEach { $0.adjustLayout(to: collectionView.frame.width) }

        return rows.flatMap { $0.attributes }
    }
}
