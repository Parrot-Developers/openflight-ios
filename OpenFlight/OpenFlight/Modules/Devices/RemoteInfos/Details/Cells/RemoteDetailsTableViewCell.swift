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

/// Custom cell which display details about device system info.

final class RemoteDetailsTableViewCell: UITableViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var updateButton: UIView!
    @IBOutlet private weak var checkImageView: UIImageView!
    @IBOutlet private weak var updateStateLabel: UILabel!
    @IBOutlet private weak var sectionValueLabel: UILabel! {
        didSet {
            sectionValueLabel.makeUp(with: .large, and: .white50)
        }
    }
    @IBOutlet private weak var sectionLabel: UILabel! {
        didSet {
            sectionLabel.makeUp(with: .large)
        }
    }
    @IBOutlet private weak var updateButtonContainer: UIView!

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()
        updateStateLabel.text = L10n.remoteDetailsUpToDate
        backgroundColor = nil
        selectionStyle = .none
    }

    // MARK: - Internal Funcs
    /// Setup the cell.
    /// - Parameters:
    ///     - model: device model
    ///     - needUpdate: device need an update
    ///     - isConnected: device is connected
    func setup(model: DeviceSystemInfoModel, needUpdate: Bool, isConnected: Bool) {
        resetView()
        sectionLabel.text = model.section?.sectionTitle
        sectionValueLabel.text = model.value?.isEmpty == true ? Style.dash : model.value
        let isSoftwareSection = model.section == SectionSystemInfo.software

        if isSoftwareSection {
            updateButtonContainer.isHidden = false
            if !needUpdate,
                isConnected {
                updateStateLabel.isHidden = false
                checkImageView.isHidden = false
            } else if needUpdate {
                updateButton.isHidden = false
            }
        }
    }
}

// MARK: - Private Funcs
private extension RemoteDetailsTableViewCell {
    /// Reset the view.
    func resetView() {
        updateStateLabel.isHidden = true
        checkImageView.isHidden = true
        updateButton.isHidden = true
        updateButtonContainer.isHidden = true
        sectionLabel.text = nil
        sectionValueLabel.text = nil
    }
}
