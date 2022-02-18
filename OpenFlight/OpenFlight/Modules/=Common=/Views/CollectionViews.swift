//    Copyright (C) 2021 Parrot Drones SAS
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

/// A collection view with file manager UI layout.
class FileManagerCollectionView: UICollectionView {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupView()
    }

    private func setupView() {
        let layout = GridCollectionViewLayout()
        let spacing = Layout.mainSpacing(isRegularSizeClass)
        layout.columnsCount = Layout.fileCollectionViewColumnsCount(isRegularSizeClass)
        layout.cellHeight = Layout.fileCollectionViewCellHeight(isRegularSizeClass)
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        collectionViewLayout = layout

        contentInset = Layout.fileCollectionViewContentInset(isRegularSizeClass, screenBorders: [.left, .bottom])
        contentInsetAdjustmentBehavior = .never
    }
}

/// A grid collection view flow layout with `columnsCount` and `cellHeight` parameters.
/// (Used in `gridItemSize()` of `UICollectionView` extension.)
class GridCollectionViewLayout: UICollectionViewFlowLayout {
    var columnsCount: Int?
    var cellHeight: CGFloat?
}

extension UICollectionView {
    /// Returns auto-computed grid item size based on given parameters.
    ///
    /// - Parameters:
    ///    - columns: The number of columns of the grid (1 if not specified).
    ///    - spacing: The horizontal spacing between 2 grid elements (0 if not specified).
    ///    - height: The height of an item (returns a 1:1 ratio item size if not specified).
    /// - Returns: The size of a grid item.
    func gridItemSize(columns: Int? = nil,
                      spacing: CGFloat? = nil,
                      height: CGFloat? = nil) -> CGSize {
        let spacing = spacing ?? (collectionViewLayout as? UICollectionViewFlowLayout)?.minimumInteritemSpacing ?? 0
        let columns = max(columns ?? (collectionViewLayout as? GridCollectionViewLayout)?.columnsCount ?? 1, 1)
        let availableWidth = bounds.width - contentInset.left - contentInset.right
        let itemWidth = (availableWidth - CGFloat(columns - 1) * spacing) / CGFloat(columns)
        let itemHeight = height ?? (collectionViewLayout as? GridCollectionViewLayout)?.cellHeight ?? itemWidth
        return .init(width: itemWidth, height: itemHeight)
    }
}
