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

/// Custom view used in HUD bottom bar used to display modes.

public class BarButtonView: UIControl, NibOwnerLoadable {

    // MARK: - Outlets
    @IBOutlet private weak var title: UILabel! {
        didSet {
            title.makeUp(with: .small, and: .white)
        }
    }
    @IBOutlet public weak var currentMode: UILabel! {
        didSet {
            currentMode.makeUp()
        }
    }
    @IBOutlet private weak var subTitle: UILabel! {
        didSet {
            subTitle.makeUp()
        }
    }
    @IBOutlet private weak var modeView: UIView!
    @IBOutlet private weak var imageView: UIImageView!

    // MARK: - Internal Properties
    public var model: BarButtonState! {
        didSet {
            fill(with: model)
        }
    }

    /// Corners to round when view is selected.
    var roundedCorners: UIRectCorner = [.allCorners]

    // MARK: - Init
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        customInitBarButtonView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        customInitBarButtonView()
    }

    // MARK: - Override Funcs
    open override var isSelected: Bool {
        didSet {
            updateBackgroundColor()
        }
    }

    open override var isHighlighted: Bool {
        didSet {
            alpha = isHighlighted ? 0.7 : 1
        }
    }
}

// MARK: - Private Funcs
private extension BarButtonView {
    /// Common init.
    func customInitBarButtonView() {
        loadNibContent()
    }

    /// Fills the UI elements of the view with given model.
    ///
    /// - Parameters:
    ///    - model: model representing the contents
    func fill(with model: BarButtonState) {
        title.text = model.title
        currentMode.text = model.subtext
        subTitle.text = model.subtitle
        modeView.isHidden = model.title == "" && model.subtext == "" && model.subtitle == ""
        imageView.image = model.subMode?.image ?? model.image
        imageView.isHidden = model.image == nil
        let alpha: CGFloat = model.enabled ? 1 : 0.5
        title.alpha = alpha / 2
        currentMode.alpha = alpha
        subTitle.alpha = alpha
        imageView.alpha = alpha
        DispatchQueue.main.async {
            self.updateBackgroundColor()
        }
        isUserInteractionEnabled = model.enabled
    }

    func updateBackgroundColor() {
        if model != nil {
            let isSelected = model?.isSelected.value == true
            let backgroundColor = isSelected ? ColorName.greenSpring20.color : .clear
            let borderColor = isSelected ? ColorName.greenSpring.color : .clear
            customCornered(corners: roundedCorners,
                           radius: Style.largeCornerRadius,
                           backgroundColor: backgroundColor,
                           borderColor: borderColor,
                           borderWidth: 4.0)
        }
    }
}
