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

/// Custom class used to identify separators than a view.
final public class SeparatorView: UIView {
    // MARK: - Private Properties
    private var width: CGFloat = 1.0
    private var height: CGFloat = 1.0
    private var backColor: UIColor = ColorName.white20.color

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    // MARK: - Public Funcs
    /// Init.
    ///
    /// - Parameters:
    ///     - size: size for the current orientation. It can be width or height
    ///     - orientation: separator orientation which is setted to horizontal by default
    ///     - backColor: separator's background color
    public init(size: CGFloat,
                orientation: NSLayoutConstraint.Axis = .horizontal,
                backColor: UIColor = ColorName.white20.color) {
        self.backColor = backColor
        if orientation == .horizontal {
            self.width = size
        } else {
            self.height = size
        }

        super.init(frame: CGRect.zero)

        self.commonInit(orientation: orientation)
    }
}

// MARK: - Private Funcs
private extension SeparatorView {
    /// Init separator's view.
    ///
    /// - Parameters:
    ///     - orientation: separator orientation which is setted to horizontal by default
    func commonInit(orientation: NSLayoutConstraint.Axis = .horizontal) {
        if orientation == .horizontal {
            self.widthAnchor.constraint(equalToConstant: self.width).isActive = true
        } else {
            self.heightAnchor.constraint(equalToConstant: self.height).isActive = true
        }

        self.backgroundColor = self.backColor
    }
}

/// Utility extension for `UIStackView`.
public extension UIStackView {
    /// Updates separators view.
    func updateSeparators() {
        removeSeparators()
        addSeparators()
    }

    /// Adds separators between arranged subviews.
    ///
    /// - Parameters:
    ///     - size: size for the current orientation. It can be width or height
    ///     - backColor: separator's background color
    func addSeparators(size: CGFloat = 1.0,
                       backColor: UIColor = ColorName.white20.color) {
        for view in arrangedSubviews where view.isHidden == false {
            if let firstElement = arrangedSubviews.first(where: { $0.isHidden == false }),
               let firstIndex = arrangedSubviews.firstIndex(of: firstElement),
               let index = arrangedSubviews.firstIndex(of: view),
               index > firstIndex,
               index < arrangedSubviews.count {
                // Add separators after the first visible element.
                let separator = SeparatorView(size: size, orientation: self.axis, backColor: backColor)
                insertArrangedSubview(separator, at: index)
            }
        }
    }

    /// Removes separators between arranged subviews.
    func removeSeparators() {
        for view in arrangedSubviews where view is SeparatorView {
            removeArrangedSubview(view)
        }
    }

    /// Safely remove arranged subviews.
    ///
    /// - Parameters:
    ///     - deactivateConstraint: Specifies if you want to activate/deactivate the constraint of the subviews
    func safelyRemoveArrangedSubviews(deactivateConstraint: Bool = true) {
        // Remove all the arranged subviews and save them to an array.
        let removedSubviews = arrangedSubviews.reduce([]) { (sum, next) -> [UIView] in
            self.removeArrangedSubview(next)
            return sum + [next]
        }

        if deactivateConstraint {
            // Deactive all constraints at once.
            NSLayoutConstraint.deactivate(removedSubviews.flatMap({ $0.constraints }))
        }

        // Remove the views from self.
        removedSubviews.forEach({ $0.removeFromSuperview() })
    }
}
