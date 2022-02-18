//    Copyright (C) 2021 Parrot Drones SAS
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

/// A generic style for buttons:
/// - validate: plain .highlightColor bkg.
/// - destructive: plain .errorColor bkg.
/// - default1: plain .white bkg (bordered).
/// - default2: plain .whiteAlbescent bkg.
/// - action1: plain .warning bkg.
/// - action2: plain .blueNavy bkg.
/// - secondary: bordered clear bkg.
public enum ActionButtonStyle {
    case none
    case validate
    case destructive
    case default1
    case default2
    case action1
    case action2
    case secondary1
    case secondary2

    var tintColor: UIColor {
        switch self {
        case .none,
             .default1,
             .default2,
             .secondary1:
            return ColorName.defaultTextColor.color
        default:
            return .white
        }
    }

    var backgroundColor: UIColor {
        switch self {
        case .validate: return ColorName.highlightColor.color
        case .destructive: return ColorName.errorColor.color
        case .default1: return ColorName.white.color
        case .default2: return ColorName.whiteAlbescent.color
        case .action1: return ColorName.warningColor.color
        case .action2: return ColorName.blueNavy.color
        default: return .clear
        }
    }

    var borderColor: UIColor {
        switch self {
        case .default1: return ColorName.whiteAlbescent.color
        case .secondary1: return ColorName.defaultTextColor.color
        case .secondary2: return ColorName.white.color
        default: return .clear
        }
    }

    var hasShadow: Bool {
        switch self {
        case .default2,
            .secondary1,
            .secondary2:
            return false
        default: return true
        }
    }
}

/// A model for generic action buttons.
public struct ActionButtonModel {
    /// The image of the button.
    var image: UIImage?
    /// The title of the button.
    var title: String?
    /// The tint color of the button.
    var tintColor: UIColor
    /// The content horizontal alignment.
    var contentHorizontalAlignment: UIControl.ContentHorizontalAlignment
    /// The label horizontal alignment in case of word wrapping.
    var labelHorizontalAlignment: NSTextAlignment?
    /// The font style.
    var fontStyle: FontStyle
    /// Font digits style.
    var isMonospacedDigitsFont: Bool
    /// The background color of the button.
    var backgroundColor: UIColor
    /// The border color of the button.
    var borderColor: UIColor
    /// Flag for shadow display.
    var hasShadow: Bool

    /// The label horizontal alignment in case of word wrapping.
    var defaultLabelHorizontalAlignment: NSTextAlignment {
        switch contentHorizontalAlignment {
        case .left, .leading: return .left
        case .right, .trailing: return .right
        default: return .center
        }
    }

    public init(image: UIImage? = nil,
                title: String? = nil,
                tintColor: UIColor? = nil,
                contentHorizontalAlignment: UIControl.ContentHorizontalAlignment? = nil,
                labelHorizontalAlignment: NSTextAlignment? = nil,
                fontStyle: FontStyle = .current,
                isMonospacedDigitsFont: Bool = false,
                backgroundColor: UIColor? = nil,
                borderColor: UIColor? = nil,
                hasShadow: Bool? = nil,
                style: ActionButtonStyle = .none) {
        self.image = image
        self.title = title
        self.tintColor = tintColor ?? style.tintColor
        self.contentHorizontalAlignment = contentHorizontalAlignment ?? .center
        self.labelHorizontalAlignment = labelHorizontalAlignment
        self.fontStyle = fontStyle
        self.isMonospacedDigitsFont = isMonospacedDigitsFont
        self.backgroundColor = backgroundColor ?? style.backgroundColor
        self.borderColor = borderColor ?? style.borderColor
        self.hasShadow = hasShadow ?? style.hasShadow
    }

    /// Updates the model with a specific style.
    ///
    /// - Parameters:
    ///    - style: The style of the model to apply.
    mutating func updateWithStyle(_ style: ActionButtonStyle) {
        tintColor = style.tintColor
        backgroundColor = style.backgroundColor
        borderColor = style.borderColor
        hasShadow = style.hasShadow
    }
}
