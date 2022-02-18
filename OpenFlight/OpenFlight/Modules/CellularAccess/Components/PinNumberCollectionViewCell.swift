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

// MARK: - Protocols
protocol PinNumberCollectionViewCellDelegate: AnyObject {
    /// Called when user click on number button.
    ///
    /// - Parameters:
    ///     - number: number selected
    func updatePinNumber(number: Int?)
}

/// Custom cell for cellular pin number.
final class PinNumberCollectionViewCell: UICollectionViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var mainView: UIView!
    @IBOutlet private weak var numberButton: UIButton!

    // MARK: - Internal Properties
    weak var delegate: PinNumberCollectionViewCellDelegate?

    // MARK: - Private Properties
    private var number: Int?

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        numberButton.setTitle(nil, for: .normal)
        number = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateView()
    }

    // MARK: - Internal Funcs
    /// Fills the view.
    ///
    /// - Parameters:
    ///     - number: current number to print
    func fill(with number: Int) {
        self.number = number
        numberButton.setTitle("\(number)", for: .normal)
    }
}

// MARK: - Actions
private extension PinNumberCollectionViewCell {
    @IBAction func numberButtonTouchedUpInside(_ sender: Any) {
        updateView()
    }

    @IBAction func numberButtonTouchedDown(_ sender: Any) {
        updateView(isSelected: true)
        delegate?.updatePinNumber(number: number)
    }
}

// MARK: - Private Funcs
private extension PinNumberCollectionViewCell {
    /// Updates view.
    ///
    /// - Parameters:
    ///     - isSelected: tells if the view is selected
    func updateView(isSelected: Bool = false) {
        let cornerRadius = mainView.frame.width / 2
        let backgroundColor = isSelected ? ColorName.highlightColor.color : .clear
        numberButton.cornerRadiusedWith(backgroundColor: backgroundColor,
                                        borderColor: ColorName.defaultTextColor.color,
                                        radius: cornerRadius,
                                        borderWidth: Style.mediumBorderWidth)
    }
}
