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

import Reusable

/// Class definition for `GalleryPanoramaStepView`.

final class GalleryPanoramaStepView: UIView, NibOwnerLoadable {

    // MARK: - Outlets
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var descLabel: UILabel!
    @IBOutlet private weak var errorLabel: UILabel!

    // MARK: - Internal Properties
    var model: GalleryPanoramaStepModel? {
        didSet {
            update(with: model)
        }
    }

    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
}

// MARK: - Private Funcs
private extension GalleryPanoramaStepView {

    /// Basic init.
    func commonInit() {
        loadNibContent()
    }

    /// Update the UI for a specific view model.
    ///
    /// - Parameters:
    ///    - model: model for the view.
    func update(with model: GalleryPanoramaStepModel?) {
        guard let model = model else { return }

        if model.status == .active {
            imageView.startRotate()
        } else {
            imageView.stopRotate()
        }
        imageView.image = model.stateIcon
        descLabel.text = model.step.descModel.text
        errorLabel.text = model.step.descModel.errorText

        imageView.tintColor = model.status.iconColor.color
        descLabel.makeUp(with: .big, and: model.status.textColor)
        errorLabel.makeUp(with: .large, and: ColorName.errorColor)
        errorLabel.isHiddenInStackView = model.status != .failure
        // Update alpha in addition to isHidden in order to get cleaner appearance animation.
        errorLabel.alphaHidden(model.status != .failure)

        alpha = model.status != .inactive ? 1 : 0.3
    }
}
