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

/// Custom button for loading action.
public class LoaderButton: ActionButton {
    // MARK: - Private Properties
    private var backView: UIView?
    private var loaderImage: UIImageView?

    // MARK: - Private Enums
    private enum Constants {
        static let imageSize: CGFloat = 21.0
    }

    public var loaderColor: UIColor = .white {
        didSet {
            loaderImage?.tintColor = loaderColor
        }
    }

    /// Start displaying the loader in the button.
    public func startLoader() {
        removeLoader()
        addLoader()
        loaderImage?.startRotate()
    }

    /// Stop displaying the loader in the button.
    public func stopLoader() {
        loaderImage?.stopRotate()
        removeLoader()
    }
}

// MARK: - Private Funcs
private extension LoaderButton {
    /// Add the loader in the button.
    func addLoader() {
        let backViewFrame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        backView = UIView(frame: backViewFrame)
        backView?.backgroundColor = self.backgroundColor
        backView?.layer.borderColor = self.layer.borderColor
        backView?.layer.borderWidth = self.layer.borderWidth
        backView?.layer.cornerRadius = self.layer.cornerRadius
        loaderImage = UIImageView(frame: CGRect(x: 0, y: 0, width: Constants.imageSize, height: Constants.imageSize))
        loaderImage?.center = backViewFrame.center
        loaderImage?.image = Asset.Pairing.icloading.image
        loaderImage?.tintColor = loaderColor

        guard let strongBackView = backView, let strongLoaderImage = loaderImage else { return }

        strongBackView.addSubview(strongLoaderImage)
        self.addSubview(strongBackView)
    }

    /// Remove the loader.
    func removeLoader() {
        loaderImage?.removeFromSuperview()
        backView?.removeFromSuperview()
    }
}
