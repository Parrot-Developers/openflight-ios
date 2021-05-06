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

/// Custom View used for Drone cell in the Dashboard.
class DashboardDroneCell: UICollectionViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var gpsStatusImageView: UIImageView!
    @IBOutlet private weak var networkImageView: UIImageView!
    @IBOutlet private weak var wifiStatusImageView: UIImageView!
    @IBOutlet private weak var deviceImageView: UIImageView!
    @IBOutlet private weak var nameDeviceLabel: UILabel!
    @IBOutlet private weak var stateDeviceLabel: UILabel!
    @IBOutlet private weak var batteryValueLabel: UILabel!
    @IBOutlet private weak var bottomView: UIView!
    @IBOutlet private weak var needUpdateButton: UpdateCustomButton!

    // MARK: - Private Properties
    private weak var viewModel: DroneInfosViewModel?
    private weak var delegate: DashboardDeviceCellDelegate?

    private var firmwareAndMissionsUpdateListener: FirmwareAndMissionsListener?
    private var firmwareAndMissionToUpdateModel: FirmwareAndMissionToUpdateModel?

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()

        // Clean UI when we create the cell.
        cleanViews()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        // Clean UI and states.
        cleanViews()
        cleanStates()
    }

    // MARK: - Internal Funcs
    /// Sets up view.
    ///
    /// - Parameters:
    ///    - state: The view model state for drone cell
    func setup(_ viewModel: DroneInfosViewModel) {
        self.viewModel = viewModel
        listenViewModel()
        firmwareAndMissionsUpdateListener = FirmwareAndMissionsInteractor.shared
            .register { [weak self] (_, firmwareAndMissionToUpdateModel) in
                self?.firmwareAndMissionToUpdateModel = firmwareAndMissionToUpdateModel
                self?.setStateDeviceLabel(with: firmwareAndMissionToUpdateModel)
            }
    }

    /// Sets up the cell's delegate.
    ///
    /// - Parameters:
    ///    - delegate: the cell's delegate
    func setup(delegate: DashboardDeviceCellDelegate) {
        self.delegate = delegate
    }
}

// MARK: - Actions
private extension DashboardDroneCell {
    @IBAction func needUpdateButtonTouchedUpInside(_ sender: Any) {
        delegate?.startUpdate(.drone)
    }
}

// MARK: - Private Funcs
private extension DashboardDroneCell {
    /// Set battery percent.
    ///
    /// - Parameters:
    ///    - value: the current battery level
    func updateBatteryLevel(_ value: Int?) {
        if let batteryLevel = value {
            batteryValueLabel.attributedText = NSMutableAttributedString(withBatteryLevel: batteryLevel)
        } else {
            batteryValueLabel.text = Style.dash
        }
    }

    /// This method is used to clean UI before setting value from the state.
    func cleanViews() {
        networkImageView.image = nil
        nameDeviceLabel.text = nil
        stateDeviceLabel.text = nil
        batteryValueLabel.text = nil
        needUpdateButton.isHidden = true
        bottomView.isHidden = false
        wifiStatusImageView.image = nil
        gpsStatusImageView.image = nil
        stateDeviceLabel.text = nil
    }

    /// This method is used to clean all current states.
    func cleanStates() {
        FirmwareAndMissionsInteractor.shared.unregister(firmwareAndMissionsUpdateListener)
        firmwareAndMissionToUpdateModel = nil
        viewModel?.state.valueChanged = nil
    }
}

// MARK: - Private Funcs
private extension DashboardDroneCell {
    /// Listens view model.
    func listenViewModel() {
        viewModel?.state.valueChanged = { [weak self] state in
            self?.updateCell(state)
        }
        if let state = viewModel?.state.value {
            updateCell(state)
        }
    }

    /// Updates cell with current state.
    ///
    /// - Parameters:
    ///    - state: drone's infos state
    func updateCell(_ state: DroneInfosState) {
        let isCellularActive = state.currentLink == .cellular
        updateBatteryLevel(state.batteryLevel.currentValue)
        wifiStatusImageView.image = state.wifiStrength.signalIcon(isLinkActive: !isCellularActive)
        gpsStatusImageView.image = state.gpsStrength.image
        nameDeviceLabel.text = state.droneName
        networkImageView.image = state.cellularStrength.signalIcon(isLinkActive: isCellularActive)

        if let firmwareAndMissionToUpdateModel = firmwareAndMissionToUpdateModel {
            setStateDeviceLabel(with: firmwareAndMissionToUpdateModel)
        }
    }

    /// Sets the state device label.
    ///
    /// - Parameters:
    ///    - firmwareAndMissionToUpdateModel: The firmware and mission update model
    func setStateDeviceLabel(with firmwareAndMissionToUpdateModel: FirmwareAndMissionToUpdateModel) {
        guard let droneInfosState = viewModel?.state.value else { return }

        let droneCalibrationRequired = droneInfosState.isConnected() == true
            && droneInfosState.requiresCalibration

        switch firmwareAndMissionToUpdateModel {
        case .upToDate where droneCalibrationRequired,
             .notInitialized where droneCalibrationRequired:
            stateDeviceLabel.text = L10n.remoteCalibrationRequired
            stateDeviceLabel.textColor = ColorName.redTorch.color
        default:
            stateDeviceLabel.textColor = firmwareAndMissionToUpdateModel
                .stateDeviceLabelTextColor(deviceConnectionState: droneInfosState.connectionState)
            stateDeviceLabel.text = firmwareAndMissionToUpdateModel
                .stateDeviceLabelText(deviceConnectionState: droneInfosState.connectionState)
        }

        setNeedUpdateButtonLayoutForDroneCase(with: firmwareAndMissionToUpdateModel,
                                              droneInfosState: droneInfosState)
    }

    /// Sets the need update button layout.
    ///
    /// - Parameters:
    ///    - firmwareAndMissionToUpdateModel: The firmware and mission update model
    ///    - droneInfosState: The view model state for drone cell
    func setNeedUpdateButtonLayoutForDroneCase(with firmwareAndMissionToUpdateModel: FirmwareAndMissionToUpdateModel,
                                               droneInfosState: DroneInfosState) {
        switch firmwareAndMissionToUpdateModel {
        case .upToDate,
             .notInitialized:
            needUpdateButton.isHidden = true
        case .firmware,
             .singleMission,
             .missions:
            needUpdateButton.isHidden = false
            let buttonTitle = firmwareAndMissionToUpdateModel
                .stateDeviceLabelText(deviceConnectionState: droneInfosState.connectionState)
            needUpdateButton.setup(with: buttonTitle)
        }
    }
}
