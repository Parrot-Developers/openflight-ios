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

// MARK: - Public Funcs
/// Utility extension for `UITextView`.
public extension UITextView {
    /// Sets HTML from string.
    ///
    /// - Parameters:
    ///     - text: text to set
    func setHTMLFromString(text: String) {
        guard let textData = text.data(using: .utf8) else { return }

        do {
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [.documentType: NSAttributedString.DocumentType.html,
                                                                               .characterEncoding: String.Encoding.utf8.rawValue]
            let attrStr = try NSMutableAttributedString(data: textData, options: options, documentAttributes: nil)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .justified
            attrStr.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attrStr.length))
            self.attributedText = attrStr
        } catch {}
    }

    /// Making up textView using style and color.
    ///
    /// - Parameters:
    ///     - style: font style
    ///     - color: color of the text
    final func makeUp(with style: ParrotFontStyle = .regular, and color: ColorName = .white) {
        self.font = UIFont.font(with: style)
        self.textColor = color.color
    }
}
