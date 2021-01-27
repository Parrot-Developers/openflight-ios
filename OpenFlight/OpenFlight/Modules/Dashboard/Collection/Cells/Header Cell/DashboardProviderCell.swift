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

/// Custom View used for the Provider part of the header.
final class DashboardProviderCell: UICollectionViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var profileImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!

    // MARK: - Private Enums
    private enum Constants {
        static let alpha: CGFloat = 0.15
    }

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()
        updateView()
    }

    // MARK: - Internal Funcs
    /// Set cell content.
    ///
    /// - Parameters:
    ///    - icon: profile image of the header.
    ///    - name: profile name of the header.
    func setProfile(icon: UIImage?, name: String) {
        profileImageView.image = icon
        nameLabel.text = name
    }
}

// MARK: - Private Funcs
private extension DashboardProviderCell {
    /// Updates view.
    func updateView() {
        contentView.cornerRadiusedWith(backgroundColor: UIColor.clear,
                                       borderColor: UIColor(white: 1,
                                                            alpha: Constants.alpha),
                                       radius: Style.largeCornerRadius,
                                       borderWidth: Style.mediumBorderWidth)
    }
}
