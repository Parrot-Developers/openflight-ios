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

// MARK: - Internal Protocols
protocol DroneFirmwaresStartViewProtocol: AnyObject {
    /// Starts the updates processes choosen by the user.
    /// - Parameters:
    ///   - updateChoice: The update choice of the user
    func startUpdate(for updateChoice: FirmwareAndMissionUpdateChoice)
}

/// A view representing the start button for drone firmware or mission update.
final class DroneFirmwaresStartView: UIView, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var startUpdateButton: UIButton!
    @IBOutlet private weak var upToDateLabel: UILabel!
    @IBOutlet private weak var upToDateImageView: UIImageView!

    // MARK: - Private Properties
    private var updateChoice: FirmwareAndMissionUpdateChoice?
    private weak var delegate: DroneFirmwaresStartViewProtocol?

    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.commonInit()
    }

    // MARK: - Override Funcs
    override init(frame: CGRect) {
        super.init(frame: frame)

        self.commonInit()
    }

    // MARK: - Internal Funcs
    /// Sets up the view.
    ///
    /// - Parameters:
    ///    - updateChoice: The view's update choice
    ///    - delegate: The view's delegate
    ///    - droneIsConnected: True is the drone is connected
    func setup(with updateChoice: FirmwareAndMissionUpdateChoice,
               delegate: DroneFirmwaresStartViewProtocol,
               droneIsConnected: Bool) {
        self.updateChoice = updateChoice
        self.delegate = delegate
        refreshUI(with: updateChoice, droneIsConnected: droneIsConnected)
    }
}

// MARK: - Actions
private extension DroneFirmwaresStartView {
    @IBAction func startUpdateButtonTouchedUpInside(_ sender: Any) {
        guard let updateChoice = updateChoice else { return }

        delegate?.startUpdate(for: updateChoice)
    }
}

// MARK: - Private Funcs
private extension DroneFirmwaresStartView {
    /// Common init.
    func commonInit() {
        self.loadNibContent()
        initUI()
    }

    /// Inits the UI.
    func initUI() {
        upToDateLabel.text = L10n.firmwareMissionUpdateUpToDate
    }

    /// Refreshes the UI.
    ///
    /// - Parameters:
    ///    - updateChoice: The update choice
    ///    - droneIsConnected: True is the drone is connected
    func refreshUI(with updateChoice: FirmwareAndMissionUpdateChoice,
                   droneIsConnected: Bool) {
        reinitView()
        setButton(for: updateChoice)

        switch updateChoice {
        case let .firmwareAndProtobufMissions(firmware: firmwareToUpdateData, missions: missionsToUpdate):
            startUpdateButton.setTitle(L10n.firmwareMissionUpdateInstallAll, for: .normal)
            if firmwareToUpdateData.allOperationsNeeded.isEmpty && missionsToUpdate.isEmpty {
                startUpdateButton.isEnabled = false
            } else {
                startUpdateButton.isEnabled = droneIsConnected
            }
        case let .firmware(firmware):
            updateUI(for: firmware, droneIsConnected: droneIsConnected)
        case .upToDateProtobufMission:
            showUpToDate()
        case let .protobufMission(mission, _, _):
            startUpdateButton.setTitle(L10n.firmwareMissionUpdateInstallOne(mission.missionVersion),
                                       for: .normal)
            startUpdateButton.isEnabled = droneIsConnected
            if !droneIsConnected {
                startUpdateButton.setBorder(borderColor: ColorName.white10.color,
                                            borderWidth: Style.mediumBorderWidth)
            }
        }
    }

    /// Updates the UI for the firmware case.
    ///
    /// - Parameters:
    ///    - firmware: The firmware
    ///    - droneIsConnected: True is the drone is connected
    func updateUI(for firmware: FirmwareToUpdateData,
                  droneIsConnected: Bool) {
        if firmware.allOperationsNeeded.contains(.update) {
            startUpdateButton.setTitle(
                L10n.firmwareMissionUpdateInstallOne(firmware.firmwareIdealVersion),
                for: .normal)
            startUpdateButton.isEnabled = droneIsConnected
            if !droneIsConnected {
                startUpdateButton.setBorder(borderColor: ColorName.white10.color,
                                            borderWidth: Style.mediumBorderWidth)
            }
        } else if firmware.allOperationsNeeded.contains(.download) {
            startUpdateButton.setTitle(
                L10n.firmwareMissionUpdateDownloadFirmware(firmware.firmwareIdealVersion),
                for: .normal)
            startUpdateButton.isEnabled = true
        } else {
            showUpToDate()
        }
    }

    /// Sets the button.
    ///
    /// - Parameters:
    ///    - updateChoice: The update choice
    func setButton(for updateChoice: FirmwareAndMissionUpdateChoice) {
        startUpdateButton.cornerRadiusedWith(backgroundColor: updateChoice.buttonBackgroundColor,
                                             borderColor: updateChoice.buttonBorderColor ,
                                             radius: Style.mediumCornerRadius,
                                             borderWidth: Style.mediumBorderWidth)
        startUpdateButton.tintColor = updateChoice.buttonTintColor
    }

    /// Reinits the view.
    func reinitView() {
        startUpdateButton.isHidden = false
        upToDateLabel.isHidden = true
        upToDateImageView.isHidden = true
    }

    /// Shows up to date view.
    func showUpToDate() {
        startUpdateButton.isHidden = true
        startUpdateButton.setTitle("", for: .normal)
        upToDateLabel.isHidden = false
        upToDateImageView.isHidden = false
    }
}
