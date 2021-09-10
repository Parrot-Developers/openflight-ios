// Copyright (C) 2020 Parrot Drones SAS
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

// MARK: - Protocols
protocol DashboardDeviceCellDelegate: AnyObject {
    /// Start device update.
    ///
    /// - Parameters:
    ///     - model: device to update
    func startUpdate(_ model: DeviceUpdateModel)
}

/// Custom View used for User Device, Remote and Drone Cells in the Dashboard.
class DashboardDeviceCell: UICollectionViewCell, NibReusable, CellConfigurable {
    // MARK: - Outlets
    @IBOutlet private weak var gpsStatusImageView: UIImageView!
    @IBOutlet private weak var networkImageView: UIImageView!
    @IBOutlet private weak var wifiStatusImageView: UIImageView!
    @IBOutlet private weak var deviceImageView: UIImageView!
    @IBOutlet private weak var deviceNameLabel: UILabel!
    @IBOutlet private weak var deviceStateButton: DeviceStateButton!
    @IBOutlet private weak var batteryValueLabel: UILabel!
    @IBOutlet private weak var batteryLevelImageView: UIImageView!

    // MARK: - Private Properties
    private var currentState: ViewModelState?
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
    /// Sets up function used for User Device, Remote and Drone states.
    ///
    /// - Parameters:
    ///    - state: the current state
    func setup(state: ViewModelState) {
        // We need to clean the current state and UI.
        currentState = state
        cleanViews()
        switch state {
        case is UserDeviceInfosState:
            setupUserDevice(state)
        case is RemoteInfosState:
            setupRemote(state)
        default:
            break
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
private extension DashboardDeviceCell {
    @IBAction func stateDeviceTouchedUpInside(_ sender: Any) {
        switch currentState {
        case is RemoteInfosState:
            delegate?.startUpdate(.remote)
        default:
            break
        }
    }
}

// MARK: - Private Funcs
private extension DashboardDeviceCell {
    /// Updates battery percent and icon.
    ///
    /// - Parameters:
    ///    - batteryValue: the current battery value model
    func updateBatteryLevel(_ batteryValue: BatteryValueModel) {
        batteryValueLabel.attributedText = NSMutableAttributedString(withBatteryLevel: batteryValue.currentValue)
        batteryLevelImageView.image = batteryValue.batteryImage
    }

    /// This method is used to clean UI before setting value from the state.
    func cleanViews() {
        networkImageView.image = nil
        batteryLevelImageView.image = nil
        deviceNameLabel.text = nil
        batteryValueLabel.text = nil
        deviceImageView.image = nil
        wifiStatusImageView.image = nil
        gpsStatusImageView.image = nil
    }

    /// This method is used to clean all current states.
    func cleanStates() {
        FirmwareAndMissionsInteractor.shared.unregister(firmwareAndMissionsUpdateListener)
        firmwareAndMissionToUpdateModel = nil
        switch currentState {
        case is UserDeviceInfosState:
            let userDeviceInfosState = currentState as? UserDeviceInfosState
            userDeviceInfosState?.userDeviceBatteryLevel.valueChanged = nil
        case is RemoteInfosState:
            let remoteInfosState = currentState as? RemoteInfosState
            remoteInfosState?.remoteBatteryLevel.valueChanged = nil
            remoteInfosState?.remoteName.valueChanged = nil
            remoteInfosState?.remoteNeedUpdate.valueChanged = nil
        default:
            break
        }
    }
}

/// Utils for User Device case.
private extension DashboardDeviceCell {
    /// Update User Device cell view.
    ///
    /// - Parameters:
    ///    - state: The view model state for User Device cell
    func setupUserDevice(_ state: ViewModelState) {
        if let userDeviceInfosState = currentState as? UserDeviceInfosState {
            // Set current values because we cleared all fields.
            gpsStatusImageView.image = userDeviceInfosState.userDeviceGpsStrength.value.image
            deviceImageView.image = Asset.Dashboard.icPhone.image
            deviceStateButton.update(with: DeviceStateButton.Status.notDisconnected, title: L10n.commonReady)

            updateBatteryLevel(userDeviceInfosState.userDeviceBatteryLevel.value)

            observeUserDeviceValues(userDeviceInfosState)
        }

        if let targetName = Bundle.main.infoDictionary?["CFBundleName"] as? String {
            deviceNameLabel.text = targetName
        }
    }

    /// Observe values from user device state.
    ///
    /// - Parameters:
    ///    - userDeviceInfosState: The view model state for user device cell
    func observeUserDeviceValues(_ userDeviceInfosState: UserDeviceInfosState) {
        userDeviceInfosState.userDeviceBatteryLevel.valueChanged = { [weak self] batteryValue in
            self?.updateBatteryLevel(batteryValue)
        }
        userDeviceInfosState.userDeviceGpsStrength.valueChanged = { [weak self] gpsStrength in
            self?.gpsStatusImageView.image = gpsStrength.image
        }
    }
}

/// Utils for Remote Case.
private extension DashboardDeviceCell {
    /// Update remote cell view.
    ///
    /// - Parameters:
    ///    - state: The view model state for remote cell
    func setupRemote(_ state: ViewModelState) {
        if let remoteInfosState = currentState as? RemoteInfosState {
            setRemoteValues(remoteInfosState)
            observeRemoteValues(remoteInfosState)
            deviceImageView.image = Asset.Dashboard.icController.image
        }
    }

    /// Set remote cell state.
    ///
    /// - Parameters:
    ///    - remoteInfosState: The view model state for remote cell
    func setRemoteValues(_ remoteInfosState: RemoteInfosState) {
        deviceNameLabel.text = remoteInfosState.remoteName.value
        deviceImageView.image = Asset.Dashboard.icController.image
        updateBatteryLevel(remoteInfosState.remoteBatteryLevel.value)
        updateRemoteStateButton(remoteInfosState)
    }

    /// Updates state button according to remote state.
    ///
    /// - Parameters:
    ///    - remoteInfosState: the view model state for remote cell
    func updateRemoteStateButton(_ remoteInfosState: RemoteInfosState) {
        let connectionState = remoteInfosState.remoteConnectionState.value
        let status: DeviceStateButton.Status
        let title: String

        switch connectionState {
        case .disconnected:
            status = .disconnected
            title = L10n.commonNotConnected
        case .connected:
            if remoteInfosState.remoteNeedUpdate.value == true {
                status = .updateAvailable
                title = remoteInfosState.remoteUpdateVersion.value
            } else if remoteInfosState.remoteNeedCalibration.value == true {
                status = .calibrationRequired
                title = L10n.remoteCalibrationRequired
            } else {
                status = .notDisconnected
                title = connectionState.title
            }
        default:
            status = .notDisconnected
            title = connectionState.title
        }

        deviceStateButton.update(with: status, title: title)
    }

    /// Observe values from remote state.
    ///
    /// - Parameters:
    ///    - remoteInfosState: The view model state for remote cell
    func observeRemoteValues(_ remoteInfosState: RemoteInfosState) {
        remoteInfosState.remoteBatteryLevel.valueChanged = { [weak self] batteryValue in
            self?.updateBatteryLevel(batteryValue)
        }
        remoteInfosState.remoteName.valueChanged = { [weak self] remoteName in
            self?.deviceNameLabel.text = remoteName
        }
        remoteInfosState.remoteNeedUpdate.valueChanged = { [weak self] _ in
            self?.updateRemoteStateButton(remoteInfosState)
        }
        remoteInfosState.remoteConnectionState.valueChanged = { [weak self] _ in
            self?.updateRemoteStateButton(remoteInfosState)
        }
        remoteInfosState.remoteNeedCalibration.valueChanged = { [weak self] _ in
            self?.updateRemoteStateButton(remoteInfosState)
        }
    }
}
