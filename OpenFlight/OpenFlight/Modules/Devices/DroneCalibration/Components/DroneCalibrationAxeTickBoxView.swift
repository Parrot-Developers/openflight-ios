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

/// Custom view for drone calibration axes tickbox.
final class DroneCalibrationAxeTickBoxView: UIView, NibOwnerLoadable {

    // MARK: - Outlets
    @IBOutlet private weak var tickBoxImage: UIImageView!
    @IBOutlet private weak var axeLabel: UILabel!

    // MARK: - Internal Properties
    var viewModel: DroneCalibrationAxeTickboxModel! {
        didSet {
            fill(with: viewModel)
        }
    }

    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInitDroneCalibrationAxeTickBoxView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInitDroneCalibrationAxeTickBoxView()
    }
}

// MARK: - Private Funcs
private extension DroneCalibrationAxeTickBoxView {

    /// Basic init.
    func commonInitDroneCalibrationAxeTickBoxView() {
        self.loadNibContent()
    }

    /// Update the UI for a specific view model.
    ///
    /// - Parameters:
    ///    - viewModel: view model for the view.
    func fill(with viewModel: DroneCalibrationAxeTickboxModel) {
        self.tickBoxImage.image = viewModel.tickBoxImage
        self.axeLabel.text = viewModel.axeLabel
    }
}
