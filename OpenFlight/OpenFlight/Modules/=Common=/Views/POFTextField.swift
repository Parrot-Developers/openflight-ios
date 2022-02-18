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

// MARK: - Protocols
public protocol POFTextFieldDelegate: AnyObject {
    /// Asks the delegate when secure entry button is tapped
    ///
    /// - Parameters:
    ///    - sender: The text field informing the delegate
    ///    - isSecure: State of text field's secure entry
    func didTapToggleSecureEntry(sender: POFTextField, isSecure: Bool)

    /// Asks the delegate when secure entry state is changed
    ///
    /// - Parameters:
    ///    - sender: The text field informing the delegate
    ///    - isSecure: State of text field's secure entry
    func didChangeSecureEntry(sender: POFTextField, isSecure: Bool)
}

/// Optional delegate methods
public extension POFTextFieldDelegate {
    /// Optional delegate when secure entry state is changed
    ///
    /// - Parameters:
    ///    - sender: The text field informing the delegate
    ///    - isSecure: State of text field's secure entry
    func didTapToggleSecureEntry(sender: POFTextField, isSecure: Bool) {}

    /// Optinal delegate when secure entry state is changed
    ///
    /// - Parameters:
    ///    - sender: The text field informing the delegate
    ///    - isSecure: State of text field's secure entry
    func didChangeSecureEntry(sender: POFTextField, isSecure: Bool) {}
}

/// Parrot Design UITextField
// MARK: - Class
final public class POFTextField: UITextField {
    // MARK: _ Delegate
    public weak var secureEntryDelegate: POFTextFieldDelegate?
    // MARK: _ Enum
    private enum Constants {
        static let leftPadding: CGFloat = 10.0
        static let rightPadding: CGFloat = 50.0
    }
    // MARK: _ Private
    private var passwordView: UIView?
    private var passwordButton: UIButton?
    private var padding: UIEdgeInsets {
        return UIEdgeInsets(top: 0,
                            left: Constants.leftPadding,
                            bottom: 0,
                            right: isSecureTextEntry ? Constants.rightPadding : Constants.leftPadding)
    }
    private var passwordFrame: CGRect {
        return CGRect(x: 0, y: 0, width: Constants.rightPadding, height: self.frame.height)
    }

    // MARK: - Override
    override public func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    override public func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override public func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override public func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    // MARK: - UI
    /// Setup UI.
    private func setupUI() {
        backgroundColor = .white
        layer.borderWidth = Style.mediumBorderWidth
        layer.borderColor = UIColor.clear.cgColor
        layer.cornerRadius = Style.largeCornerRadius
        clipsToBounds = true

        addTarget(self, action: #selector(textFieldDidBeginEditing), for: .editingDidBegin)
        addTarget(self, action: #selector(textFieldDidEndEditing), for: .editingDidEnd)

        if isSecureTextEntry {
            passwordView = UIView(frame: passwordFrame)
            passwordButton = UIButton(frame: passwordFrame)
            passwordButton?.setImage(Asset.Common.Icons.icPasswordShow.image, for: .normal)
            passwordButton?.addTarget(self, action: #selector(passwordButtonTouchedUpInside), for: .touchUpInside)
            passwordButton?.tintColor = ColorName.defaultTextColor.color
            rightViewMode = .whileEditing

            if let passwordButton = passwordButton {
                passwordView?.addSubview(passwordButton)
            }

            rightView = passwordView
        }
    }

    // MARK: _ Handlers
    @objc private func passwordButtonTouchedUpInside() {
        toggleSecureEntry()
        secureEntryDelegate?.didTapToggleSecureEntry(sender: self, isSecure: isSecureTextEntry)
    }

    @objc private func textFieldDidBeginEditing() {
        layer.borderColor = ColorName.defaultTextColor.color.cgColor
        layoutIfNeeded()
    }

    @objc private func textFieldDidEndEditing() {
        layer.borderColor = UIColor.clear.cgColor
    }
}

// MARK: - Public
extension POFTextField {

    /// Set the string in parameter in the placeholder.
    ///
    /// - Parameters:
    ///    - placeholder: string to set in placeholder.
    ///    - color: set the color of placeholder text with a default value
    public func setPlaceholderTitle(_ placeholder: String, color: Color = ColorName.defaultTextColor20.color) {
        self.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [NSAttributedString.Key.foregroundColor: color]
        )
    }

    /// Changes the background color of the textField.
    ///
    /// - Parameters:
    ///    - inErrorState: a boolean value that indicates whether or not the caller is in an error state
    public func setInErrorState(_ inErrorState: Bool) {
        let borderColor = inErrorState ? ColorName.errorColor.color : .clear
        self.setBorder(borderColor: borderColor, borderWidth: Style.mediumBorderWidth)
    }

    /// Toggle secure entry visibility
    ///
    /// - Parameters:
    ///    - force: boolean value that force secure text entry
    public func toggleSecureEntry(force: Bool? = nil) {
        if let force = force {
            isSecureTextEntry = force
        } else {
            isSecureTextEntry = !isSecureTextEntry
        }

        // Prevent text purge when editing after toggling.
        if let existingText = text, isSecureTextEntry {
            text = nil
            insertText(existingText)

            // Prevent from showing last charater
            if let textRange = textRange(from: beginningOfDocument, to: endOfDocument) {
                replace(textRange, withText: existingText)
            }
        }

        // Prevent the text cursor from being in a wrong position after toggling.
        if let existingSelectedTextRange = selectedTextRange {
            selectedTextRange = nil
            selectedTextRange = existingSelectedTextRange
        }

        // Change icon
        let image = isSecureTextEntry ?
            Asset.Common.Icons.icPasswordShow.image :
            Asset.Common.Icons.icPasswordHide.image
        passwordButton?.setImage(image, for: .normal)

        secureEntryDelegate?.didChangeSecureEntry(sender: self, isSecure: isSecureTextEntry)
    }
}
