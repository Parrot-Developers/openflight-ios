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
protocol GallerySelectionDelegate: class {
    /// Delete the selection.
    func mustDeleteSelection()
    /// Download the selection.
    func mustDownloadSelection()
}

/// Gallery selection view.

final class GallerySelectionView: UIView, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var deleteButton: UIButton!
    @IBOutlet private weak var infoLabel: UILabel!
    @IBOutlet private weak var downloadButton: UIButton!

    // MARK: - Internal Properties
    weak var delegate: GallerySelectionDelegate?

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
}

// MARK: - Internal Funcs
internal extension GallerySelectionView {
    /// Set number of items.
    ///
    /// - Parameters:
    ///    - count: count
    func setNumberOfItems(_ count: Int) {
        self.isHidden = false
        infoLabel.text = String(format: "%d", count)
    }

    /// Set if download is allowed.
    ///
    /// - Parameters:
    ///    - enabled: enabled
    func setAllowDownload(_ enabled: Bool) {
        downloadButton.isHidden = !enabled
    }

    /// Lock delete button if there is no selected medias.
    ///
    /// - Parameters:
    ///    - isMediasSelected: tells if medias is selected
    func updateButtons(isMediasSelected: Bool) {
        downloadButton.makeup(with: .largeMedium, color: isMediasSelected ? ColorName.greenSpring20 : ColorName.greenSpring)
        deleteButton.makeup(with: .largeMedium, color: isMediasSelected ? ColorName.redTorch25 : ColorName.redTorch)
        downloadButton.isEnabled = !isMediasSelected
        deleteButton.isEnabled = !isMediasSelected
    }
}

// MARK: - Private Funcs
private extension GallerySelectionView {
    /// Setup all things related to UI
    func commonInitGallerySelectionView() {
        self.loadNibContent()
        self.addBlurEffect(cornerRadius: 0.0)
        self.isHidden = true
        deleteButton.makeup(with: .largeMedium, color: ColorName.redTorch)
        deleteButton.setTitle(L10n.commonDelete, for: .normal)
        infoLabel.makeUp(with: .large)
        infoLabel.textColor = ColorName.white50.color
        downloadButton.makeup(with: .largeMedium, color: ColorName.greenSpring)
        downloadButton.setTitle(L10n.commonDownload, for: .normal)
    }
}
