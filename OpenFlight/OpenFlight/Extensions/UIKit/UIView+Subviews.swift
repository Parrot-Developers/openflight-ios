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

import UIKit

/// Subviews extension for `UIView`.

extension UIView {
    /// Adds a subview and gives it Autolayout Constraints to match parent size.
    ///
    /// - Parameters:
    ///    - subview: Subview to add to current view
    public func addWithConstraints(subview: UIView) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(subview)
        let layoutAttributes: [NSLayoutConstraint.Attribute] = [.top, .leading, .bottom, .trailing]
        layoutAttributes.forEach { [weak self] attribute in
            self?.addConstraint(NSLayoutConstraint(item: subview,
                                                   attribute: attribute,
                                                   relatedBy: .equal,
                                                   toItem: self,
                                                   attribute: attribute,
                                                   multiplier: 1,
                                                   constant: 0.0))
        }
    }

    /// Adds a subview and gives it Autolayout Constraints to match parent height and horizontally centered with it.
    ///
    /// - Parameters:
    ///    - subview: Subview to add to current view
    func addHorizontallyCenteredWithConstraints(subview: UIView) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(subview)
        // Add vertical constraints.
        let verticalLayoutAttributes: [NSLayoutConstraint.Attribute] = [.top, .bottom]
        verticalLayoutAttributes.forEach { [weak self] attribute in
            self?.addConstraint(NSLayoutConstraint(item: subview,
                                                   attribute: attribute,
                                                   relatedBy: .equal,
                                                   toItem: self,
                                                   attribute: attribute,
                                                   multiplier: 1,
                                                   constant: 0.0))
        }
        // Add centerX constraint.
        self.addConstraint(NSLayoutConstraint(item: subview,
                                              attribute: .centerX,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .centerX,
                                              multiplier: 1.0,
                                              constant: 0.0))
        // Add width constraint.
        let views = ["subview": subview]
        let formatString = "[subview(\(subview.frame.size.width))]"
        let constraints = NSLayoutConstraint.constraints(withVisualFormat: formatString, options: .alignAllTop, metrics: nil, views: views)
        self.addConstraints(constraints)
    }

    /// Adds a subview if it exists.
    ///
    /// - Parameters:
    ///    - subview: Subview to add to current view
    func addSubview(_ subview: UIView?) {
        guard let strongView = subview else { return }
        self.addSubview(strongView)
    }

    /// Remove all subviews for the current view.
    func removeSubViews() {
        self.subviews.forEach({ $0.removeFromSuperview() })
    }
}
