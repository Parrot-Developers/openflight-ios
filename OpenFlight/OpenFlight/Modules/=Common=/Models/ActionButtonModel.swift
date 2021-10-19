//
//  Copyright (C) 2021 Parrot Drones SAS.
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
/// - primary: plain .white bkg.
/// - secondary: bordered clear bkg.
enum ActionButtonStyle {
    case none
    case validate
    case destructive
    case primary
    case secondary

    var titleColor: ColorName {
        switch self {
        case .validate,
             .destructive:
            return .white
        default:
            return ColorName.defaultTextColor
        }
    }

    var backgroundColor: ColorName {
        switch self {
        case .validate: return ColorName.highlightColor
        case .destructive: return ColorName.errorColor
        case .primary: return ColorName.white
        default: return ColorName.clear
        }
    }

    var borderColor: ColorName {
        switch self {
        case .secondary: return ColorName.defaultTextColor
        default: return ColorName.clear
        }
    }

    var hasShadow: Bool {
        switch self {
        case .secondary: return false
        default: return true
        }
    }
}

/// A model for generic action buttons.
class ActionButtonModel {
    /// The title of the button.
    var title: String?
    /// The color of the title.
    var titleColor: ColorName?
    /// The font style
    var fontStyle: ParrotFontStyle
    /// The background color name of the button.
    var backgroundColor: ColorName?
    /// The border color of the button.
    var borderColor: ColorName?
    /// Flag for shadow display.
    var hasShadow: Bool?

    init(title: String? = nil,
         titleColor: ColorName? = nil,
         fontStyle: ParrotFontStyle = .regular,
         backgroundColor: ColorName? = nil,
         borderColor: ColorName? = nil,
         hasShadow: Bool? = nil,
         style: ActionButtonStyle = .none) {
        self.title = title
        self.titleColor = titleColor ?? style.titleColor
        self.fontStyle = fontStyle
        self.backgroundColor = backgroundColor ?? style.backgroundColor
        self.borderColor = borderColor ?? style.borderColor
        self.hasShadow = hasShadow ?? style.hasShadow
    }
}
