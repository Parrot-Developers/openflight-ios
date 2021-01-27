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

/// Custom View used for the login part to Provider in the header.
final class DashboardLoginCell: UICollectionViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var backView: UIView!
    @IBOutlet private weak var logoImageView: UIImageView!
    @IBOutlet private weak var loginButton: UIButton!

    // MARK: - Private Enums
    private enum Constants {
        static let alpha: CGFloat = 0.15
    }

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()

        self.updateView()
    }

    // MARK: - Internal Funcs
    /// Set logo.
    ///
    /// - Parameters:
    ///     - image: image to set
    func setLogo(_ image: UIImage) {
        logoImageView.image = image
    }
}

// MARK: - Private Funcs
private extension DashboardLoginCell {
    /// Updates the view.
    func updateView() {
        self.loginButton.setTitle(L10n.commonLogIn, for: .normal)
        self.backView.layer.borderColor = UIColor.white.withAlphaComponent(Constants.alpha).cgColor
        self.backView.layer.borderWidth = Style.mediumBorderWidth
        self.backView.layer.cornerRadius = Style.largeCornerRadius
    }
}
