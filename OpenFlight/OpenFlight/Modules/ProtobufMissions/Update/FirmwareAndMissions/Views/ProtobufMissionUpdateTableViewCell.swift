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
protocol ProtobufMissionUpdateTableViewCellDelegate: AnyObject {
    /// Starts the updates processes choosen by the user.
    /// - Parameters:
    ///   - updateChoice: The update choice of the user
    func startUpdate(for updateChoice: FirmwareAndMissionUpdateChoice)
}

/// A cell for protobuf mission updates.
final class ProtobufMissionUpdateTableViewCell: UITableViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var versionLabel: UILabel!
    @IBOutlet private weak var startUpdateView: ProtobufMissionUpdateStartView!

    // MARK: - Private Properties
    private weak var delegate: ProtobufMissionUpdateTableViewCellDelegate?

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    // MARK: - Public Funcs
    /// Sets up the cell.
    ///
    /// - Parameters:
    ///    - updateChoice: The update choice
    ///    - delegate: The cell's delegate
    ///    - numberOfFiles: The number of files
    ///    - droneIsConnected: True is the drone is connected
    func setup(with updateChoice: FirmwareAndMissionUpdateChoice,
               delegate: ProtobufMissionUpdateTableViewCellDelegate,
               numberOfFiles: Int,
               droneIsConnected: Bool) {
        self.delegate = delegate
        startUpdateView.setup(with: updateChoice,
                              delegate: self,
                              droneIsConnected: droneIsConnected)
        setupUI(with: updateChoice,
                numberOfFiles: numberOfFiles,
                droneIsConnected: droneIsConnected)
    }
}

// MARK: - ProtobufMissionUpdateStartViewProtocol
extension ProtobufMissionUpdateTableViewCell: ProtobufMissionUpdateStartViewProtocol {
    func startUpdate(for updateChoice: FirmwareAndMissionUpdateChoice) {
        delegate?.startUpdate(for: updateChoice)
    }
}

// MARK: - Private Funcs
private extension ProtobufMissionUpdateTableViewCell {
    /// Sets up the UI.
    ///
    /// - Parameters:
    ///    - updateChoice: The update choice
    ///    - numberOfFiles: The number of files
    ///    - droneIsConnected: True is the drone is connected
    func setupUI(with updateChoice: FirmwareAndMissionUpdateChoice,
                 numberOfFiles: Int,
                 droneIsConnected: Bool) {
        setupTitle(for: updateChoice)
        switch updateChoice {
        case .firmwareAndProtobufMissions:
            titleLabel.text = L10n.firmwareMissionUpdateNumberOfFile(numberOfFiles).uppercased()
            versionLabel.text = nil
        case let .firmware(firmware):
            titleLabel.text = firmware.firmwareName
            versionLabel.text = firmware.firmwareVersion
        case let .upToDateProtobufMission(mission):
            titleLabel.text = mission.missionName
            versionLabel.text = mission.missionVersion
        case let .protobufMission(mission, existOnDrone):
            titleLabel.text = mission.missionName
            switch existOnDrone {
            case .doesNotExist:
                versionLabel.text = droneIsConnected ? L10n.firmwareMissionUpdateMissionNotInstalled : Style.dash
            case let .exist(missionVersion: missionVersion):
                versionLabel.text = missionVersion
            }
        }
    }

    /// Sets up the title.
    ///
    /// - Parameters:
    ///    - updateChoice: The update choice
    func setupTitle(for updateChoice: FirmwareAndMissionUpdateChoice) {
        titleLabel.font = updateChoice.titleFont
        titleLabel.textColor = updateChoice.titleColor
        versionLabel.font = updateChoice.titleFont
    }
}
