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
import GroundSdk

/// Model for calibration choice view.
struct CalibrationChoiceModel {

    // MARK: - Internal Properties
    /// Calibration image.
    var image: UIImage
    /// Calibration title.
    var title: String
    /// Calibration title color.
    var titleColor: UIColor
    /// Calibration subtitle.
    var subtitle: String?
    /// Calibration subtitle color.
    var subtitleColor: ColorName
    /// Calibration background color.
    var backgroundColor: ColorName

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - image: Calibration image.
    ///    - title: Calibration title.
    ///    - titleColor: Calibration title color.
    ///    - subtitle: Calibration subtitle.
    ///    - subtitleColor: Calibration subtitle color.
    ///    - backgroundColor: Calibration background color.
    init(image: UIImage,
         title: String,
         titleColor: UIColor = ColorName.defaultTextColor.color,
         subtitle: String? = nil,
         subtitleColor: ColorName = .defaultTextColor,
         backgroundColor: ColorName = .white) {
        self.image = image
        self.title = title
        self.titleColor = titleColor
        self.subtitle = subtitle
        self.subtitleColor = subtitleColor
        self.backgroundColor = backgroundColor
    }
}
