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

/// Utility extension for `UIImage`.

public extension UIImage {

    /// Provide a compressed thumbnail for an image.
    ///
    /// - Parameters:
    ///    - width: width of thumbnail
    ///    - completition: completiion block
    func compressedThumbnail(width: CGFloat, completion: @escaping (_ data: Data?) -> Void) {
        let actualHeight: CGFloat = self.size.height
        let actualWidth: CGFloat = self.size.width
        let imgRatio: CGFloat = actualWidth/actualHeight
        let maxWidth: CGFloat = width
        let resizedHeight: CGFloat = maxWidth/imgRatio
        let compressionQuality: CGFloat = 0.5
        let rect: CGRect = CGRect(x: 0, y: 0, width: maxWidth, height: resizedHeight)
        UIGraphicsBeginImageContext(rect.size)
        self.draw(in: rect)
        if let img: UIImage = UIGraphicsGetImageFromCurrentImageContext(),
            let imageData: Data = img.jpegData(compressionQuality: compressionQuality) {
            UIGraphicsEndImageContext()
            completion(imageData)
        } else {
            completion(nil)
        }
    }
}
