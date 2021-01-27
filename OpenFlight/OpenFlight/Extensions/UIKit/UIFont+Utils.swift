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

/// Utility extension for `UIFont`. Provides classes funcs for custom fonts.

public extension UIFont {
    /// Returns a `Rajdhani-Medium` font of given size.
    ///
    /// - Parameters:
    ///    - size: font size
    /// - Returns: result font
    class func rajdhaniMedium(size: CGFloat) -> UIFont {
        return UIFont(name: "Rajdhani-Medium", size: size) ?? UIFont.systemFont(ofSize: size, weight: .medium)
    }

    /// Returns a `Rajdhani-SemiBold` font of given size.
    ///
    /// - Parameters:
    ///    - size: font size
    /// - Returns: result font
    class func rajdhaniSemiBold(size: CGFloat) -> UIFont {
        return UIFont(name: "Rajdhani-SemiBold", size: size) ?? UIFont.systemFont(ofSize: size, weight: .semibold)
    }

    /// Returns a `Rajdhani-Bold` font of given size.
    ///
    /// - Parameters:
    ///    - size: font size
    /// - Returns: result font
    class func rajdhaniBold(size: CGFloat) -> UIFont {
        return UIFont(name: "Rajdhani-Bold", size: size) ?? UIFont.systemFont(ofSize: size, weight: .bold)
    }
}
