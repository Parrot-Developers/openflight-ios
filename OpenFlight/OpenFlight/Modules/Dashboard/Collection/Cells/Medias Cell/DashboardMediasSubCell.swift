// Copyright (C) 2020 Parrot Drones SAS
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

/// Custom view used to display a cell containing a single media.
final class DashboardMediasSubCell: UICollectionViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var thumbnailImageView: UIImageView!

    // MARK: - Private Properties
    private var viewModel: GalleryMediaThumbnailViewModel?

    // MARK: - Override Funcs
    override func prepareForReuse() {
        super.prepareForReuse()

        thumbnailImageView.image = nil
    }
}

// MARK: - Internal Funcs
internal extension DashboardMediasSubCell {
    /// Setup cell.
    ///
    /// - Parameters:
    ///    - media: Gallery Media
    ///    - mediaStore: Media Store
    ///    - index: image index
    func setup(media: GalleryMedia,
               mediaStore: MediaStore?,
               index: Int) {
        viewModel = GalleryMediaThumbnailViewModel(media: media,
                                                   mediaStore: mediaStore,
                                                   index: index)
        viewModel?.getThumbnail { [weak self] image in
            self?.thumbnailImageView.image = image
        }
    }
}
