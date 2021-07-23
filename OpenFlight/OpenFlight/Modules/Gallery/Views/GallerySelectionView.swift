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

// MARK: - Protocols
/// Gallery Selection View Delegate.
protocol GallerySelectionDelegate: AnyObject {
    /// Delete the selection.
    func mustDeleteSelection()
    /// Download the selection.
    func mustDownloadSelection()
    /// Share the selection.
    func mustShareSelection()
}

/// Gallery selection view.

final class GallerySelectionView: UIView, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var deleteButton: UIButton!
    @IBOutlet private weak var infoLabel: UILabel!
    @IBOutlet private weak var downloadButton: UIButton!
    @IBOutlet private weak var shareButton: UIButton!

    // MARK: - Internal Properties
    weak var delegate: GallerySelectionDelegate?

    // MARK: - Private Properties
    private var isDownloadAllowed: Bool = true

    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInitGallerySelectionView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInitGallerySelectionView()
    }
}

// MARK: - Actions
private extension GallerySelectionView {
    @IBAction func deleteButtonDidTouchUpInside(_ sender: Any) {
        delegate?.mustDeleteSelection()
    }

    @IBAction func downloadButtonDidTouchUpInside(_ sender: Any) {
        delegate?.mustDownloadSelection()
    }

    @IBAction func shareButtonDidTouchUpInside(_ sender: Any) {
        delegate?.mustShareSelection()
    }
}

// MARK: - Internal Funcs
internal extension GallerySelectionView {
    /// Sets count and size of items.
    ///
    /// - Parameters:
    ///    - count: count
    ///    - size: size
    func setCountAndSizeOfItems(_ count: Int, _ size: UInt64) {
        self.isHidden = false

        if isDownloadAllowed {
            infoLabel.text = String(format: "%d %@ (%@)",
                                    count,
                                    L10n.galleryMediaSelected.lowercased(),
                                    StorageUtils.sizeForFile(size: size))
        } else {
            infoLabel.text = String(format: "%d %@",
                                    count,
                                    L10n.galleryMediaSelected.lowercased())
        }
    }

    /// Sets if download is allowed.
    ///
    /// - Parameters:
    ///    - enabled: enabled
    func setAllowDownload(_ enabled: Bool) {
        self.isDownloadAllowed = enabled
        downloadButton.isHidden = !enabled
    }

    /// Checks if all medias are downloaded.
    ///
    /// - Parameters:
    ///    - selectedMedias: medias which are selected
    func allMediasDownloaded(selectedMedias: [GalleryMedia]) -> Bool {
        return !selectedMedias.isEmpty && !selectedMedias.contains(where: { $0.downloadState != .downloaded })
    }

    /// Sets if share is allowed.
    ///
    /// - Parameters:
    ///    - enabled: enabled
    func setAllowShare(_ enabled: Bool) {
        shareButton.isHidden = !enabled
    }

    /// Updates buttons if medias are selected or downloaded.
    ///
    /// - Parameters:
    ///    - selectedMedias: tells if medias are selected
    func updateButtons(selectedMedias: [GalleryMedia]) {
        let allMediasAreDownloaded = allMediasDownloaded(selectedMedias: selectedMedias)
        let downloadColor = allMediasAreDownloaded ? ColorName.disabledHighlightColor : ColorName.highlightColor
        downloadButton.setTitleColor(downloadColor.color, for: .normal)

        let downloadTitle = allMediasAreDownloaded ? L10n.commonDownloaded : L10n.commonDownload
        downloadButton.setTitle(downloadTitle, for: .normal)
        downloadButton.isEnabled = !allMediasAreDownloaded

        let deleteColor = selectedMedias.isEmpty ? ColorName.disabledErrorColor : ColorName.errorColor
        deleteButton.setTitleColor(deleteColor.color, for: .normal)
        deleteButton.isEnabled = !selectedMedias.isEmpty

        let shareColor = selectedMedias.isEmpty ? ColorName.disabledHighlightColor : ColorName.highlightColor
        shareButton.setTitleColor(shareColor.color, for: .normal)
        shareButton.isEnabled = !selectedMedias.isEmpty

        infoLabel.textColor = selectedMedias.isEmpty ? ColorName.disabledTextColor.color : ColorName.defaultTextColor.color
    }
}

// MARK: - Private Funcs
private extension GallerySelectionView {
    /// Setup all things related to UI
    func commonInitGallerySelectionView() {
        self.loadNibContent()
        self.isHidden = true
        self.backgroundColor = .white
        deleteButton.setTitle(L10n.commonDelete, for: .normal)
        downloadButton.setTitle(L10n.commonDownloaded, for: .normal)
        shareButton.setTitle(L10n.commonShare, for: .normal)
        updateButtons(selectedMedias: [])
    }
}
