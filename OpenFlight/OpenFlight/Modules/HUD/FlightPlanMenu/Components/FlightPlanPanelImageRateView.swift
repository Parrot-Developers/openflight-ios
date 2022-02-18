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

import Foundation
import Reusable

public final class FlightPlanPanelImageRateView: UIView, NibOwnerLoadable {

    // MARK: - Outlets
    @IBOutlet private weak var modeImageRate: UIImageView!
    @IBOutlet private weak var imageLabel: UILabel!

    // MARK: - Override Funcs
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInitImageMenuView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInitImageMenuView()
    }

    func commonInitImageMenuView() {
        self.loadNibContent()
        imageLabel.makeUp(with: .current, color: .defaultTextColor)
        imageLabel.text = Style.dash
    }

    func setup(provider: ImageMenuCellProvider?, settings: [FlightPlanSetting]) {
        guard let provider = provider else {
            imageLabel.text = Style.dash
            return
        }

        let captureMode = provider.captureModeEnum
        let hasModeImageSetting = settings.contains(where: {$0.key == ClassicFlightPlanSettingType.imageMode.key })
        modeImageRate.isHidden = !hasModeImageSetting

        var settingDescription: String = ""
        // Add mode description.
        if hasModeImageSetting {
            modeImageRate.image = captureMode.image
            switch captureMode {
            case .gpsLapse:
                if let value = provider.gpsLapseDistance {
                    settingDescription += Style.whiteSpace
                        + UnitHelper.stringDistanceWithDouble(Double(value)/1000, useFractionDigit: true)
                }
            case .timeLapse:
                if let value = provider.timeLapseCycle {
                    settingDescription += Style.whiteSpace + UnitHelper.formatSeconds(Double(value)/1000)
                }
            case .video:
                settingDescription += Style.whiteSpace
                    + provider.resolutionTitle
                    + Style.whiteSpace
                    + provider.framerateTitle
            }
        }

        // Add photo resolution description if needed.
        if settings.contains(where: {$0.key == ClassicFlightPlanSettingType.photoResolution.key }) {
            settingDescription += Style.whiteSpace + provider.photoResolutionTitle
        }

        // Add exposure and white balance mode description if there is not mode description.
        if !hasModeImageSetting {
            settingDescription += String(format: " %@ %@",
                                         provider.exposureTitle,
                                         provider.whiteBalanceModeTitle)
        }

        imageLabel.text = settingDescription
    }
}
