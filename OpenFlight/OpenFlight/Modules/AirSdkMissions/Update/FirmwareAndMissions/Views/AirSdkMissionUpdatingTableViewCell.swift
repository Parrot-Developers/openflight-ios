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
import Reusable

/// A table view cell for AirSdk mission update process.
final class AirSdkMissionUpdatingTableViewCell: UITableViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var updatingView: AirSdkMissionUpdatingView!
    @IBOutlet private weak var missionUpdatingLabel: UILabel!
    @IBOutlet private weak var errorMessageLabel: UILabel!

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    // MARK: - Public Funcs
    /// Sets up the cell.
    ///
    /// - Parameters:
    ///    - currentUpdatingCase: The updating case
    func setup(with currentUpdatingCase: FirmwareMissionsUpdatingCase) {
        setupUI(with: currentUpdatingCase)
    }
}

// MARK: - Private Funcs
private extension AirSdkMissionUpdatingTableViewCell {

    /// Updates the error message label.
    ///
    /// - Parameters:
    ///    - updatingStep: The updating step
    func updateErrorMessageLabel(with updatingStep: CurrentUpdatingStep) {
        switch updatingStep {
        case let .failed(errorMessage):
            errorMessageLabel.text = L10n.firmwareMissionUpdateError(errorMessage)
        case .loading,
             .succeeded,
             .waiting:
            errorMessageLabel.text = nil
        }
    }

    /// Updates the UI.
    ///
    /// - Parameters:
    ///    - updatingStep: The updating step
    func updateUI(with updatingStep: CurrentUpdatingStep) {
        updatingView.setup(with: updatingStep)
        updateErrorMessageLabel(with: updatingStep)
        missionUpdatingLabel.textColor = updatingStep.missionUpdatingLabel
    }

    /// Sets up the cell UI.
    ///
    /// - Parameters:
    ///    - currentUpdatingCase: The updating case
    func setupUI(with currentUpdatingCase: FirmwareMissionsUpdatingCase) {
        missionUpdatingLabel.text = currentUpdatingCase.missionUpdatingLabelText
        switch currentUpdatingCase {
        case let .mission(updatingStep, _):
            updateUI(with: updatingStep)
        case let .downloadingFirmware(updatingStep, _):
            updateUI(with: updatingStep)
        case let .updatingFirmware(updatingStep, _):
            updateUI(with: updatingStep)
        case let .processingFirmware(updatingStep):
            updateUI(with: updatingStep)
        case let .reboot(updatingStep):
            updateUI(with: updatingStep)
        }
    }
}
