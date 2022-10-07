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

// MARK: - Protocols
/// Gallery Media CollectionView Cell Delegate.
protocol GalleryMediaCellDelegate: AnyObject {
    /// Should download media.
    ///
    /// - Parameters:
    ///    - media: GalleryMedia
    func shouldDownloadMedia(_ media: GalleryMedia)
}

/// Gallery Media Collection View Cell.

final class GalleryMediaCollectionViewCell: UICollectionViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var typeImage: UIImageView!
    @IBOutlet private weak var thumbnailImageView: UIImageView!
    @IBOutlet private weak var internalStorageIcon: UIView!
    @IBOutlet private weak var downloadButton: DownloadButton!
    @IBOutlet private weak var selectionView: UIView!
    @IBOutlet private weak var selectionCheckmarkView: UIView!
    @IBOutlet private weak var nameLabel: UILabel!

    // MARK: - Internal Properties
    weak var delegate: GalleryMediaCellDelegate?

    // MARK: - Private Properties
    private var media: GalleryMedia?
    private var viewModel: GalleryMediaThumbnailViewModel?

    // MARK: - Override Funcs
    override func prepareForReuse() {
        super.prepareForReuse()
        typeImage.image = nil
        thumbnailImageView.image = nil
        internalStorageIcon.isHidden = true
    }
}

// MARK: - IBActions
private extension GalleryMediaCollectionViewCell {
    @IBAction func downloadTouchedUpInside(_ sender: Any) {
        guard let media = self.media,
              media.downloadState == .toDownload else {
                return
        }
        delegate?.shouldDownloadMedia(media)
    }
}

// MARK: - Internal Funcs
internal extension GalleryMediaCollectionViewCell {
    /// Setup cell.
    ///
    /// - Parameters:
    ///    - media: Gallery Media
    ///    - index: image index
    ///    - delegate: Gallery Media Cell Delegate
    ///    - selected: Selected state
    func setup(media: GalleryMedia,
               index: Int,
               delegate: GalleryMediaCellDelegate?,
               selected: Bool = false) {
        setupViewModel(media: media, index: index)
        setupView(media: media,
                  delegate: delegate,
                  selected: selected)
    }

    /// Setup view model.
    ///
    /// - Parameters:
    ///    - media: Gallery Media
    ///    - index: image index
    func setupViewModel(media: GalleryMedia, index: Int) {
        viewModel = GalleryMediaThumbnailViewModel(media: media, index: index)
        viewModel?.getThumbnail { [weak self] image in
            self?.thumbnailImageView.image = image
        }
    }

    /// Setup view.
    ///
    /// - Parameters:
    ///    - media: Gallery Media
    ///    - delegate: Gallery Media Cell Delegate
    ///    - selected: Selected state
    func setupView(media: GalleryMedia,
                   delegate: GalleryMediaCellDelegate?,
                   selected: Bool = false) {
        self.media = media
        self.delegate = delegate

        // Check whether media is of `.bracketing` type AND has a DNG resource, as DNG bracketings
        // are not meant to be considered as a type on their own, but still need to have their own picto.
        typeImage.image = media.type == .bracketing && media.hasDng ?
        Asset.Gallery.icBracketingDNG.image :
        media.type.image
        downloadButton.model = DownloadButtonModel(title: media.formattedSize,
                                                   state: media.downloadState)
        downloadButton.isHidden = media.source == .mobileDevice
        selectionView.isHidden = !selected
        selectionCheckmarkView.isHidden = !selected
        selectionView.setBorder(borderColor: ColorName.highlightColor.color, borderWidth: selected ? 2.0 : 0.0)
        selectionView.backgroundColor = ColorName.cellSelectionColor.color
        internalStorageIcon.applyCornerRadius(Style.mediumCornerRadius)
        internalStorageIcon.isHidden = media.source != .droneInternal
        nameLabel.text = media.cellTitle
        accessibilityLabel = nameLabel.text ?? ""
        accessibilityValue = media.type.stringValue
    }
}
