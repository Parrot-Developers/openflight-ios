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

import Reusable

/// Custom view for calibration choice.
final class CalibrationChoiceView: UIControl, NibOwnerLoadable {

    // MARK: - Outlets
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!

    // MARK: - Private Enums
    private enum Constants {
        static let alphaEnabled: CGFloat = 1
        static let alphaDisabled: CGFloat = 0.3
    }

    // MARK: - Internal Properties
    var viewModel: CalibrationChoiceModel? {
        didSet {
            update(with: viewModel)
        }
    }

    // MARK: - Override Properties
    override var isEnabled: Bool {
        didSet {
            imageView.alpha = isEnabled ? Constants.alphaEnabled : Constants.alphaDisabled
            titleLabel.alpha = isEnabled ? Constants.alphaEnabled : Constants.alphaDisabled
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
private extension CalibrationChoiceView {

    /// Basic init.
    func commonInit() {
        self.loadNibContent()
        self.applyCornerRadius(Style.largeCornerRadius)
        self.addShadow(shadowColor: ColorName.whiteAlbescent.color)
    }

    /// Update the UI for a specific view model.
    ///
    /// - Parameters:
    ///    - viewModel: view model for the view.
    func update(with viewModel: CalibrationChoiceModel?) {
        self.imageView.image = viewModel?.image
        self.titleLabel.text = viewModel?.title
        self.titleLabel.textColor = viewModel?.titleColor
        backgroundColor = viewModel?.backgroundColor.color
        self.subtitleLabel.text = viewModel?.subtitle
        self.subtitleLabel.textColor = viewModel?.subtitleColor.color
    }
}
