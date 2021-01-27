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

/// Utility extension for `UIViewController` standard close button.
public extension UIViewController {
    // MARK: Public Enums
    /// Default values for close button.
    enum CloseButtonConstants {
        public static let defaultWidth: CGFloat = 60.0
        public static let defaulHeight: CGFloat = 60.0
    }

    /// Style for close button.
    enum CloseButtonStyle {
        case backArrow
        case cross

        var image: UIImage {
            switch self {
            case .backArrow:
                return Asset.Common.Icons.icBack.image
            case .cross:
                return Asset.Common.Icons.icCloseMedium.image
            }
        }
    }

    // MARK: - Public Funcs
    /// Adds a standard close button to screen. Close button is attached
    /// to main view, along safe area, unless a target view is specified.
    ///
    /// - Parameters:
    ///    - size: size of the button
    ///    - onTapAction: selector for back button tap action
    ///    - targetView: optional target view to attach back button
    ///    - style: close button style. Default: back arrow
    func addCloseButton(size: CGSize = CGSize(width: CloseButtonConstants.defaultWidth,
                                              height: CloseButtonConstants.defaulHeight),
                        onTapAction: Selector,
                        targetView: UIView? = nil,
                        style: CloseButtonStyle = .backArrow) {
        let containerView = targetView ?? self.view

        // Setup button.
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setSizeConstraints(size)
        button.setImage(style.image,
                        for: .normal)

        // Add to main view.
        containerView?.addSubview(button)
        let layoutAttributes: [NSLayoutConstraint.Attribute] = [.top, .leading]
        layoutAttributes.forEach { [weak self] attribute in
            self?.view.addConstraint(NSLayoutConstraint(item: button,
                                                        attribute: attribute,
                                                        relatedBy: .equal,
                                                        toItem: targetView ?? self?.view.safeAreaLayoutGuide,
                                                        attribute: attribute,
                                                        multiplier: 1.0,
                                                        constant: 0.0))
        }

        // Add selector target.
        button.addTarget(self,
                         action: onTapAction,
                         for: .touchUpInside)
    }
}
