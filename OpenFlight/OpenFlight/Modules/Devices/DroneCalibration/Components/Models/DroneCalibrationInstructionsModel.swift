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

/// Model for DroneCalibrationInstructionsView.
struct DroneCalibrationInstructionsModel {

    // MARK: - Internal Properties
    /// Instruction image.
    var image: UIImage?
    /// Main instruction label.
    var firstLabel: String
    /// Main instruction label color.
    var firstLabelColor: UIColor
    /// Main instruction label alignment.
    var firstLabelAlignment: NSTextAlignment
    /// Subtitle instruction label.
    var secondLabel: String?
    /// Subtitle instruction label color.
    var secondLabelColor: UIColor
    /// Subtitle instruction label alignment.
    var secondLabelAlignment: NSTextAlignment
    /// Item labels.
    var items: [String]

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - image: Instruction image.
    ///    - firstLabel: Main instruction label.
    ///    - firstLabelColor: Main instruction label color.
    ///    - firstLabelAlignment: Main instruction label alignment.
    ///    - secondLabel: Subtitle instruction label.
    ///    - secondLabelColor: Main instruction label color.
    ///    - secondLabelAlignment: Subtitle instruction label alignment.
    ///    - items: Item failure labels.
    init(image: UIImage?,
         firstLabel: String,
         firstLabelColor: UIColor = ColorName.defaultTextColor.color,
         firstLabelAlignment: NSTextAlignment = .center,
         secondLabel: String?,
         secondLabelColor: UIColor = ColorName.defaultTextColor.color,
         secondLabelAlignment: NSTextAlignment = .center,
         items: [String]) {
        self.image = image
        self.firstLabel = firstLabel
        self.firstLabelColor = firstLabelColor
        self.firstLabelAlignment = firstLabelAlignment
        self.secondLabel = secondLabel
        self.secondLabelColor = secondLabelColor
        self.secondLabelAlignment = firstLabelAlignment
        self.items = items
    }
}
