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

// MARK: - Public Structs
/// Model for `HUDTopBannerInfoView`.
struct HUDTopBannerInfoModel {
    var image: UIImage?
    var text: String?
    var backgroundColor: UIColor?
}

/// Displays an information label with an optional image and a background.

final class HUDTopBannerInfoView: UIView, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var infoImageView: UIImageView!
    @IBOutlet private weak var infoLabel: UILabel! {
        didSet {
            infoLabel.makeUp(with: .large, and: .black)
        }
    }
    @IBOutlet private weak var backgroundView: UIView!

    // MARK: - Internal Properties
    var model: HUDTopBannerInfoModel? {
        didSet {
            fill()
        }
    }

    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInitHUDTopBannerInfoView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInitHUDTopBannerInfoView()
    }
}

// MARK: - Private Funcs
private extension HUDTopBannerInfoView {
    /// Common init.
    func commonInitHUDTopBannerInfoView() {
        self.loadNibContent()
        self.applyCornerRadius()
    }

    /// Fills view with current model.
    func fill() {
        guard let model = model else {
            return
        }
        infoImageView.image = model.image
        infoImageView.isHidden = model.image == nil
        infoLabel.text = model.text
        backgroundView.backgroundColor = model.backgroundColor
    }
}
