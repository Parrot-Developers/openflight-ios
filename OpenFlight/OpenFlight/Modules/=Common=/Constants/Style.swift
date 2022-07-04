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

/// Global style constants which are used in the app are defined here.

// MARK: - Global constants
public enum Style {
    public static let dash: String = "-"
    public static let doubledash: String = "--"
    public static let arrow: String = " ▸ "
    public static let dot: String = "."
    public static let middot: String = "•"
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
    /// Animation duration = 0.2. For fast animations like bottom bar levels navigation.
    public static let fastAnimationDuration: TimeInterval = 0.2
    /// Animation duration = 0.3.
    public static let shortAnimationDuration: TimeInterval = 0.3
    /// Animation duration = 0.35.
    public static let transitionAnimationDuration: TimeInterval = 0.35
    /// Animation duration = 0.5.
    public static let mediumAnimationDuration: TimeInterval = 0.5
    /// Animation duration = 1.0.
    public static let longAnimationDuration: TimeInterval = 1.0
    /// Estimated time for a tap gesture = 0.15.
    public static let tapGestureDuration: TimeInterval = 0.15
    /// Corner radius = 2.0.
    public static let tinyCornerRadius: CGFloat = 2.0
    /// Corner radius = 3.0.
    public static let verySmallCornerRadius: CGFloat = 3.0
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
    /// Border width = 3.0
    public static let selectedItemBorderWidth: CGFloat = 3.0
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
    /// Disabled view opacity.
    public static let disabledAlpha: CGFloat = 0.5
    /// Shadow offset.
    public static let shadowOffset: CGSize = .init(width: 0, height: 2)
    /// Shadow radius.
    public static let shadowRadius: CGFloat = 2
    /// Shadow opacity.
    public static let shadowOpacity: Float = 0.2
}

// MARK: - Parrot Font Styles UIFont helper
public extension UIFont {
    /// Apply font using ParrotFontStyle.
    static func font(with style: ParrotFontStyle) -> UIFont? {
        return style.font
    }
    /// Apply font using FontStyle.
    static func font(_ isRegular: Bool, with style: FontStyle) -> UIFont? {
        return style.font(isRegular)
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

    public var font: UIFont {
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

/// Font styles.
public enum FontStyle {
    case caps
    case caps2
    case current
    case mode
    case big
    case readingText
    case title
    case subtitle
    case smallText
    case topBar
    case medium

    /// Returns the font according to device's size class.
    ///
    /// - Parameters:
    ///    - isRegular: `true` if device has a wRhR size class, `false` otherwise
    ///    - monospacedDigits: return monospacedDigits font if `true`, default font otherwise
    ///  - Returns: the font of current style for the given device's size class
    public func font(_ isRegular: Bool, monospacedDigits: Bool = false) -> UIFont {
        switch self {
        case .caps:
            return UIFont.rajdhaniSemiBold(size: Layout.capsFontSize(isRegular),
                                           monospacedDigits: monospacedDigits)
        case .caps2:
            return UIFont.rajdhaniSemiBold(size: Layout.caps2FontSize(isRegular),
                                           monospacedDigits: monospacedDigits)
        case .current:
            return UIFont.rajdhaniSemiBold(size: Layout.currentFontSize(isRegular),
                                           monospacedDigits: monospacedDigits)
        case .mode:
            return UIFont.rajdhaniSemiBold(size: Layout.modeFontSize(isRegular),
                                           monospacedDigits: monospacedDigits)
        case .big:
            return UIFont.rajdhaniSemiBold(size: Layout.bigFontSize(isRegular),
                                           monospacedDigits: monospacedDigits)
        case .readingText:
            return UIFont.rajdhaniMedium(size: Layout.readingTextFontSize(isRegular))
        case .title:
            return UIFont.rajdhaniSemiBold(size: Layout.titleFontSize(isRegular),
                                           monospacedDigits: monospacedDigits)
        case .subtitle:
            return UIFont.rajdhaniSemiBold(size: Layout.subtitleFontSize(isRegular),
                                           monospacedDigits: monospacedDigits)
        case .smallText:
            return UIFont.rajdhaniMedium(size: Layout.smallTextFontSize(isRegular))
        case .topBar:
            return UIFont.rajdhaniSemiBold(size: Layout.topBarFontSize(isRegular),
                                           monospacedDigits: monospacedDigits)
        case .medium:
            return UIFont.rajdhaniMedium(size: Layout.mediumFontSize(isRegular))
        }
    }
}
