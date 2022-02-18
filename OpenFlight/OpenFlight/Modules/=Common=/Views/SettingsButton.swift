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

/// Custom settings button with the imageView placed above the label

class SettingsButton: UIButton {

    override func layoutSubviews() {
        super.layoutSubviews()
        let padding: CGFloat = 1.0
        guard let imageView = self.imageView, imageView.image != nil, let titleLabel = self.titleLabel
        else { return }

        imageView.contentMode = .scaleAspectFill
        imageView.frame.origin.x = (self.bounds.size.width - imageView.frame.size.width) / 2.0
        imageView.frame.origin.y = max(0, (self.bounds.size.height - (imageView.frame.size.height + (titleLabel.frame.size.height) + padding)) / 2.0)
        titleLabel.frame.origin.x = 0
        titleLabel.frame.origin.y = self.bounds.size.height - titleLabel.frame.size.height * 1.5
        titleLabel.frame.size.width = self.bounds.size.width
        titleLabel.textAlignment = .center
    }
}
