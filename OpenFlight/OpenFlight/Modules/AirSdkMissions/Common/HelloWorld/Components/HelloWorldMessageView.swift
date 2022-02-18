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

import Foundation
import UIKit
import Reusable

/// Hello World Message View.
class HelloWorldMessageView: UIView, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var messageLabel: UILabel!

    // MARK: - Private Enum
    /// Enum which stores animation constants.
    private enum Constants {
        static let helloWorldAnimationDuration: Double = 0.3
        static let helloWorldAnimationDelay: Double = 1.0
    }

    // MARK: Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.commonInitHelloWordlMessageView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.commonInitHelloWordlMessageView()
    }
}

// MARK: - Internal Funcs
extension HelloWorldMessageView {
    /// Displays then hides the `HelloWorldMessageView` in a specific View Controller.
    ///
    /// - Parameters:
    ///     - viewController: The View Controller
    ///     - message: The message to display
    func displayThenHide(in viewController: UIViewController,
                         with message: String) {

        messageLabel.text = message
        addConstraints(in: viewController)

        alpha = 0.0
        UIView.animate(withDuration: Constants.helloWorldAnimationDuration,
                       delay: 0.0,
                       options: .curveEaseIn,
                       animations: {
                        self.alpha = 1.0
                       }, completion: { (_) in
                        self.removeWithAnimation()
                       })
    }

    /// Retruns true if a `HelloWorldMessageView` is already in the View Controller hierarchy.
    ///
    /// - Parameters:
    ///     - viewController: The View Controller
    /// - Returns: True if a `HelloWorldMessageView` is already in the View Controller hierarchy.
    static func isAlreadyDisplayed(in viewController: UIViewController) -> Bool {
        return viewController.view.subviews.contains(where: { $0 as? HelloWorldMessageView != nil })
    }
}

// MARK: - Private Funcs
private extension HelloWorldMessageView {
    func commonInitHelloWordlMessageView() {
        loadNibContent()
        messageLabel.makeUp(with: .monumental, and: .greySilver)
        isUserInteractionEnabled = false
        alpha = 0.0
    }

    /// Adds `HelloWorldMessageView` in a View Controller.
    ///
    /// - Parameters:
    ///     - viewController: The View Controller
    func addConstraints(in viewController: UIViewController) {
        translatesAutoresizingMaskIntoConstraints = false
        viewController.view.addSubview(self)
        centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor).isActive = true
        centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor).isActive = true
    }

    /// Hides HelloWorldMessageView.
    func removeWithAnimation() {
        UIView.animate(withDuration: Constants.helloWorldAnimationDuration,
                       delay: Constants.helloWorldAnimationDelay,
                       options: .curveEaseOut,
                       animations: {
                        self.alpha = 0.0
                       }, completion: {_ in
                        self.removeFromSuperview()
                       })
    }
}
