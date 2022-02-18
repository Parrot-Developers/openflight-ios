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

/// Utility extension to ease the `AlertViewController` use in `UIViewController`.

extension UIViewController {
    /// Show alert view controller.
    ///
    /// - Parameters:
    ///     - title: alert title
    ///     - message: alert message
    ///     - cancelAction: alert cancel action
    ///     - validateAction: alert validate action
    ///     - secondaryAction: alert secondary action
    func showAlert(title: String,
                   message: String,
                   cancelAction: AlertAction = AlertAction(title: L10n.cancel),
                   validateAction: AlertAction? = nil,
                   secondaryAction: AlertAction? = nil) {
        let alert = AlertViewController.instantiate(title: title,
                                                    message: message,
                                                    closeButtonStyle: .cross,
                                                    cancelAction: cancelAction,
                                                    validateAction: validateAction,
                                                    secondaryAction: secondaryAction)
        self.present(alert, animated: true, completion: nil)
    }

    /// Show toast message which is automatically dismissed.
    ///
    /// - Parameters:
    ///     - message: toast message
    ///     - duration: display duration
    func showToast(message: String, duration: Double = Style.longAnimationDuration) {
        // Creating toast label.
        let toastLabel = UILabel(frame: CGRect())
        toastLabel.makeUp(with: .large, and: ColorName.highlightColor)
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        toastLabel.numberOfLines = 0
        toastLabel.textAlignment = .center
        toastLabel.text = message
        toastLabel.sizeToFit()
        // Creating toast container.
        let toastContainer = UIView(frame: CGRect())
        toastContainer.translatesAutoresizingMaskIntoConstraints = false
        toastContainer.cornerRadiusedWith(backgroundColor: ColorName.black60.color, radius: Style.largeCornerRadius)
        toastContainer.alpha = 0.0
        toastContainer.addSubview(toastLabel)
        view.addSubview(toastContainer)
        // Adding constraints to anchor the container at the bottom.
        let toastContainerWidth = toastLabel.frame.size.width + 2 * Style.toastMargin
        let toastContainerHeight = toastLabel.frame.size.height + Style.toastMargin
        let toastContainerHorizontalConstraint = toastContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        let toastContainerVerticalConstraint = toastContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor,
                                                                                      constant: -Style.toastMargin)
        let toastContainerWidthConstraint = toastContainer.widthAnchor.constraint(equalToConstant: toastContainerWidth)
        let toastContainerHeightConstraint = toastContainer.heightAnchor.constraint(equalToConstant: toastContainerHeight)
        let toastHorizontalConstraint = toastLabel.centerXAnchor.constraint(equalTo: toastContainer.centerXAnchor)
        let toastVerticalConstraint = toastLabel.centerYAnchor.constraint(equalTo: toastContainer.centerYAnchor)
        view.addConstraints([
            toastContainerHorizontalConstraint,
            toastContainerVerticalConstraint,
            toastContainerWidthConstraint,
            toastContainerHeightConstraint,
            toastHorizontalConstraint,
            toastVerticalConstraint
        ])
        // Starting animations (fade in, display for duration, fade out, remove).
        UIView.animate(withDuration: Style.mediumAnimationDuration, delay: 0.0, options: .curveEaseIn, animations: {
            toastContainer.alpha = 1.0
        }, completion: { _ in
            UIView.animate(withDuration: Style.mediumAnimationDuration, delay: duration, options: .curveEaseOut, animations: {
                toastContainer.alpha = 0.0
            }, completion: { _ in
                toastContainer.removeFromSuperview()
            })
        })
    }

    // In order to display actionSheet on iPad, sourceView should be different from UIViewController.view
    func presentSheet(viewController: UIViewController, sourceView: UIView) {
        if UIDevice.current.userInterfaceIdiom == .pad {
            viewController.popoverPresentationController?.sourceView = sourceView
            viewController.popoverPresentationController?.sourceRect = sourceView.bounds
        }
        present(viewController, animated: true, completion: nil)
    }
}
