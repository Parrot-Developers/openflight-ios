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

/// Global style constants which are used in the app are defined here.

// MARK: - Global constants
public enum Style {
    public static let dash: String = "-"
    public static let doubledash: String = "--"
    public static let arrow: String = " ▸ "
    public static let dot: String = "."
    public static let colon: String = ":"
    public static let multiplySign: String = "×"
    public static let pipe: String = "|"
    public static let comma: String = ","
    public static let slash: String = " / "
    public static let newLine: String = "\n"
    public static let whiteSpace: String = " "
    public static let equalSign: String = "="
    public static let plusSign: String = " + "
    public static let ampersand: String = "&"
    public static let noBreakSpace: String = "\u{00A0}"
    /// Animation duration = 0.3.
    public static let shortAnimationDuration: TimeInterval = 0.3
    /// Animation duration = 0.5.
    public static let mediumAnimationDuration: TimeInterval = 0.5
    /// Animation duration = 1.0.
    public static let longAnimationDuration: TimeInterval = 1.0
    /// Estimated time for a tap gesture = 0.15.
    public static let tapGestureDuration: TimeInterval = 0.15
    /// Corner radius = 2.0.
    public static let tinyCornerRadius: CGFloat = 2.0
    /// Corner radius = 4.0.
    public static let smallCornerRadius: CGFloat = 4.0
    /// Corner radius = 6.0.
    public static let mediumCornerRadius: CGFloat = 6.0
    /// Corner radius = 9.0.
    public static let largeCornerRadius: CGFloat = 9.0
    /// Corner radius = 8.0.
    public static let largeFitCornerRadius: CGFloat = 8.0
    /// Corner radius = 10.0.
    public static let fitLargeCornerRadius: CGFloat = 10.0
    /// Corner radius = 11.0.
    public static let fitExtraLargeCornerRadius: CGFloat = 11.0
    /// Border width = 0.0
    public static let noBorderWidth: CGFloat = 0.0
    /// Border width = 0.5
    public static let smallBorderWidth: CGFloat = 0.5
    /// Border width = 1.0
    public static let mediumBorderWidth: CGFloat = 1.0
    /// Border width = 2.0
    public static let largeBorderWidth: CGFloat = 2.0
    /// Scale factor = 0.5
    public static let minimumScaleFactor: CGFloat = 0.5
    /// Toast margin
    public static let toastMargin: CGFloat = 20.0
    /// Attributed title view spacing
    public static let attributedTitleViewSpacing: CGFloat = 8.0
    /// Attributed title view spacing
    public static let attributedTitleViewTitleOffset: Int = 6
    /// Bottom bar separator width.
    public static let bottomBarSeparatorWidth: CGFloat = 10.0
}

// MARK: - Parrot Font Styles UIFont helper
public extension UIFont {
    /// Apply font using ParrotFontStyle.
    static func font(with style: ParrotFontStyle) -> UIFont? {
        return style.font
    }
}

// MARK: - Parrot Font Styles

/// Lists predefined fonts and sizes used in the app.
public enum ParrotFontStyle {
    /// Rajdhani SemiBold 10.
    case tiny
    /// Rajdhani SemiBold 11.
    case small
    /// Rajdhani SemiBold 13.
    case regular
    /// Rajdhani Medium 15.
    case largeMedium
    /// Rajdhani SemiBold 15.
    case large
    /// Rajdhani Medium 17.
    case big
    /// Rajdhani SemiBold 19.
    case huge
    /// Rajdhani SemiBold 25.
    case veryHuge
    /// Rajdhani SemiBold 34.
    case giant
    /// Rajdhani Bold 68.
    case monumental

    var font: UIFont {
        switch self {
        case .tiny:
            return UIFont.rajdhaniSemiBold(size: 10)
        case .small:
            return UIFont.rajdhaniSemiBold(size: 11)
        case .regular:
            return UIFont.rajdhaniSemiBold(size: 13)
        case .largeMedium:
            return UIFont.rajdhaniMedium(size: 15)
        case .large:
            return UIFont.rajdhaniSemiBold(size: 15)
        case .big:
            return UIFont.rajdhaniMedium(size: 17)
        case .huge:
            return UIFont.rajdhaniSemiBold(size: 19)
        case .veryHuge:
            return UIFont.rajdhaniSemiBold(size: 25)
        case .giant:
            return UIFont.rajdhaniSemiBold(size: 34)
        case .monumental:
            return UIFont.rajdhaniBold(size: 68)
        }
    }
}
