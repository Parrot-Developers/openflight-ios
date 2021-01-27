// Copyright (C) 2020 Parrot Drones SAS
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

import Foundation
import UIKit

// Utility extension for `NSMutableAttributedString`.

extension NSMutableAttributedString {
    // MARK: - Public Funcs
    /// Convenience init: creates an attributed string for given battery level.
    ///
    /// - Parameters:
    ///    - level: battery level
    convenience init(withBatteryLevel level: Int) {
        self.init()
        append(NSAttributedString(string: String(level),
                                  attributes: [NSAttributedString.Key.font: ParrotFontStyle.regular.font]))
        append(NSAttributedString(string: "%",
                                  attributes: [NSAttributedString.Key.font: ParrotFontStyle.tiny.font]))
    }

    /// Convenience init: creates an attributed string for given available space.
    ///
    /// - Parameters:
    ///    - space: available space
    convenience init(withAvailableSpace space: Double) {
        self.init()
        append(NSAttributedString(string: String(format: "%.1lf", space),
                                  attributes: [
                                    NSAttributedString.Key.font: ParrotFontStyle.regular.font,
                                    NSAttributedString.Key.foregroundColor: ColorName.white.color
        ]))
        append(NSAttributedString(string: String(format: " %@", L10n.galleryMemoryFree.uppercased()),
                                  attributes: [
                                    NSAttributedString.Key.font: ParrotFontStyle.tiny.font,
                                    NSAttributedString.Key.foregroundColor: ColorName.white50.color
        ]))
    }

    /// Convenience init: creates an attributed string for a given image and text.
    ///
    /// - Parameters:
    ///    - image: image
    ///    - text: text
    ///    - offset: offset for text alignment
    convenience init(withImage image: UIImage, text: String, offset: Int) {
        self.init()
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = image
        append(NSAttributedString(attachment: imageAttachment))
        append(NSAttributedString(string: String(format: " %@", text),
                                  attributes: [
                                    NSAttributedString.Key.font: ParrotFontStyle.large.font,
                                    NSAttributedString.Key.baselineOffset: NSNumber(value: offset)
        ]))
    }

    /// Transforms current attributed string with a different font for value and unit.
    ///
    /// - Parameters:
    ///    - valueFont: UIFont to apply to the value part of the string
    ///    - unitFont: UIFont to apply to the unit part of the string
    func valueUnitFormatted(valueFont: UIFont, unitFont: UIFont) {
        self.addAttribute(.font, value: unitFont, range: NSRange(location: 0, length: self.length))
        if let spaceIndex = self.string.firstIndex(of: " ")?.utf16Offset(in: self.string) {
            self.addAttribute(.font, value: valueFont, range: NSRange(location: 0, length: spaceIndex))
        }
    }
}
