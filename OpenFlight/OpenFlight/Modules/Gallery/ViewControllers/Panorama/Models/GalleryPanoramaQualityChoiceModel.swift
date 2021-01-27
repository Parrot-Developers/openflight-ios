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

/// Model for panorama quality choice view.
struct GalleryPanoramaQualityChoiceModel {

    // MARK: - Internal Properties
    /// Panorama choice icon.
    var icon: UIImage
    /// Panorama choice text.
    var text: String
    /// Panorama choice text color.
    var textColor: ColorName
    /// Panorama choice subtitle text.
    var subText: String?
    /// Panorama choice subtitle text color.
    var subTextColor: ColorName

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - icon: icon.
    ///    - text: main text.
    ///    - textColor: main text color.
    ///    - subText: subtitle text.
    ///    - subTextColor: subtitle text color.
    init(icon: UIImage,
         text: String,
         textColor: ColorName = .white,
         subText: String,
         subTextColor: ColorName = .white50) {
        self.icon = icon
        self.text = text
        self.textColor = textColor
        self.subText = subText
        self.subTextColor = subTextColor
    }
}
