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

/// Design extension for `UIButton`.

extension UIButton {
    /// Style HUD round button with gray background and thin white border.
    func applyHUDRoundButtonStyle(backgroundColor: UIColor = UIColor(named: .white90)) {
        applyRoundButtonStyle(backgroundColor: backgroundColor, borderWidth: Style.smallBorderWidth)
        setTitleColor(.white, for: .normal)
        setTitleColor(.white, for: .highlighted)
        setTitleColor(.white, for: .disabled)
        setTitleColor(.white, for: .selected)
    }

    /// Style round button with given background color and border.
    func applyRoundButtonStyle(backgroundColor: UIColor = UIColor(named: .white90),
                               borderColor: UIColor = UIColor(named: .white20),
                               borderWidth: CGFloat = Style.smallBorderWidth) {
        self.backgroundColor = backgroundColor
        layer.cornerRadius = self.bounds.width / 2
        layer.borderColor = borderColor.cgColor
        layer.borderWidth = borderWidth
    }

    /// Sets a button's edge insets according to desired content insets and image padding.
    ///
    /// - Parameters:
    ///    - contentEdgeInsets: the desired button's content edge insets
    ///    - imageTitlePadding: the padding between button's image and title
    ///    - trailingTitlePadding:the padding beetween button's title and trailing anchor
    func setInsets(contentEdgeInsets: UIEdgeInsets,
                   imageTitlePadding: CGFloat = 0,
                   trailingTitlePadding: CGFloat = 0) {
        self.contentEdgeInsets = contentEdgeInsets
        self.contentEdgeInsets.right += imageTitlePadding + trailingTitlePadding
        titleEdgeInsets = .init(top: 0,
                                left: imageTitlePadding,
                                bottom: 0,
                                right: -imageTitlePadding)
    }
}
