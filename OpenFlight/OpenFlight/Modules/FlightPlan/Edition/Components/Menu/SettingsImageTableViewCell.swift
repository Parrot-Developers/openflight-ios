//    Copyright (C) 2022 Parrot Drones SAS
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

/// Image menu table view cell.
final class SettingsImageTableViewCell: SettingsTableViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var modeImage: UIImageView!
    @IBOutlet private weak var imageLabel: UILabel!

    private enum Constants {
        static let separator = Style.whiteSpace + Style.middot + Style.whiteSpace
    }

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()

        titleLabel.makeUp(with: .current, color: .defaultTextColor)
        titleLabel.text = L10n.commonImage

        imageLabel.makeUp(with: .current, color: .defaultTextColor)
        imageLabel.text = Style.dash
    }
}

// MARK: - Internal Funcs
internal extension SettingsImageTableViewCell {
    /// Setup cell.
    func setup(provider: ImageMenuCellProvider?, settings: [FlightPlanSetting], hasCustomType: Bool) {
        guard let provider = provider else {
            imageLabel.text = Style.dash
            return
        }

        let captureMode = provider.captureModeEnum
        var settingDescription: String = ""
        switch captureMode {
        case .gpsLapse:
            if hasCustomType {
                settingDescription += provider.photoResolutionTitle
                    + Constants.separator
                    + provider.exposureTitle
            } else if let value = provider.gpsLapseDistance {
                settingDescription += UnitHelper.stringDistanceWithDouble(Double(value)/1000,
                                                                          spacing: false,
                                                                          useFractionDigit: true)
                    + Constants.separator
                    + provider.photoResolutionTitle
            }
        case .timeLapse:
            if let value = provider.timeLapseCycle {
                settingDescription += UnitHelper.formatSeconds(Double(value)/1000)
                    + Constants.separator
                    + provider.photoResolutionTitle
            }
        case .video:
            settingDescription += provider.resolutionTitle
                + Constants.separator
                + provider.framerateTitle
        }
        modeImage.image = captureMode.image
        imageLabel.text = settingDescription
    }
}
