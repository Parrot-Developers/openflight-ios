//
//  Copyright (C) 2021 Parrot Drones SAS.
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

// MARK: - Structs
/// Represents an information model for Drone or Remote devices.
struct DeviceInformationsModel {
    /// Device information title.
    var title: String?
    /// Device information description.
    var description: String?
}

/// Displays a custom view for drone or remote informations.
final class DeviceInformationsView: UIView, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!

    // MARK: - Internal Properties
    /// Device information model.
    var model: DeviceInformationsModel = DeviceInformationsModel(title: Style.dash,
                                                               description: Style.dash) {
        didSet {
            fill()
        }
    }

    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.commonInitDroneInformationsView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.commonInitDroneInformationsView()
    }
}

// MARK: - Private Funcs
private extension DeviceInformationsView {
    /// Common init.
    func commonInitDroneInformationsView() {
        self.loadNibContent()

        titleLabel.makeUp(with: .large)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = Style.minimumScaleFactor
        descriptionLabel.makeUp(with: .regular, and: .white50)
        descriptionLabel.adjustsFontSizeToFitWidth = true
        descriptionLabel.minimumScaleFactor = Style.minimumScaleFactor
    }

    /// Fill the view.
    func fill() {
        titleLabel.text = model.title
        descriptionLabel.text = model.description
    }
}
