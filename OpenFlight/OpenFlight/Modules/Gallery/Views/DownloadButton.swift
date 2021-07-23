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

/// Dedicated Button with download style.

final class DownloadButton: UIButton {
    // MARK: - Private Enums
    private enum Constants {
        static let contentEdgeInsets = UIEdgeInsets(top: 0.0, left: 12.0, bottom: 0.0, right: 6.0)
        static let imageEdgeInsets = UIEdgeInsets(top: 0.0, left: -8.0, bottom: 0.0, right: 0.0)
    }

    // MARK: - Internal Funcs
    /// Setup display.
    func setup() {
        self.makeup(with: .regular)
        self.applyCornerRadius(Style.mediumCornerRadius)
        self.backgroundColor = ColorName.highlightColor.color
        self.tintColor = .white
        self.contentEdgeInsets = Constants.contentEdgeInsets
        self.imageEdgeInsets = Constants.imageEdgeInsets
        self.setImage(Asset.Gallery.mediaDownload.image, for: .normal)
        self.setTitle(L10n.commonDownload, for: .normal)
    }

    /// Update display retarding state.
    ///
    /// - Parameters:
    ///     - state: Gallery Media Download State
    ///     - title: button title
    func updateState(_ state: GalleryMediaDownloadState?,
                     title: String?) {
        self.setImage(state?.icon, for: .normal)
        self.backgroundColor = state?.backgroundColor
        self.tintColor = state?.tintColor
        self.isHidden = state == nil
        let filteredTitle: String?
        switch state {
        case .downloading,
             .downloaded:
            filteredTitle = nil
        default:
            filteredTitle = title ?? L10n.commonDownload
        }
        self.setTitle(filteredTitle, for: .normal)
        self.isUserInteractionEnabled = state != .downloading
    }

    override var isHighlighted: Bool {
        didSet {
            setHighlightedStyle(isHighlighted)
        }
    }
}

// MARK: - Private Funcs
private extension DownloadButton {
    /// Set specific highlighted style.
    ///
    /// - Parameters:
    ///    - isHighlighted: is highlighted
    func setHighlightedStyle(_ isHighlighted: Bool) {
        self.alpha = isHighlighted ? 0.5 : 1.0
    }
}
