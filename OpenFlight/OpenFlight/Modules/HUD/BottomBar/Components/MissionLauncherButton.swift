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
import Reusable

/// Mission Launcher button on HUD.

final class MissionLauncherButton: UIControl, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var missionImageView: UIImageView!

    // MARK: - Internal Properties
    var model: MissionLauncherState? {
        didSet {
            updateView()
        }
    }

    // MARK: - Private Enums
    private enum Constants {
        static let defaultBorderWidth: CGFloat = 1.0
        static let selectedBorderWidth: CGFloat = 4.0
    }

    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.loadNibContent()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadNibContent()
    }

    // MARK: - Override Funcs
    override func layoutSubviews() {
        super.layoutSubviews()
        updateView()
    }
}

// MARK: - Private Funcs
private extension MissionLauncherButton {

    func updateView() {
        missionImageView.image = model?.image
        let isSelected = model?.isSelected.value == true
        let borderColor = isSelected ? ColorName.greenSpring.color : .white
        let cornerRadius = frame.width / 2
        let borderWidth: CGFloat = isSelected ? Constants.selectedBorderWidth : Constants.defaultBorderWidth
        customCornered(corners: .allCorners,
                       radius: cornerRadius,
                       backgroundColor: ColorName.greenPea.color,
                       borderColor: borderColor,
                       borderWidth: borderWidth)
    }
}
