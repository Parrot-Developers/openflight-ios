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
    @IBOutlet private weak var deviceImageView: UIImageView!
    @IBOutlet private weak var deviceNameLabel: UILabel!
    @IBOutlet private weak var deviceStateButton: DeviceStateButton!
    @IBOutlet private weak var batteryValueLabel: UILabel!
    @IBOutlet private weak var batteryLevelImageView: UIImageView!
    @IBOutlet private weak var batteryLevelUserDeviceImageView: UIImageView!
    @IBOutlet private weak var batteryValueUserDeviceLabel: UILabel!

    // MARK: - Private Properties
    private var currentState: ViewModelState?
    private var currentUserDeviceState: UserDeviceInfosState?
    private weak var delegate: DashboardDeviceCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    func setupUI() {
        batteryValueLabel.makeUp(with: .current, color: .defaultTextColor)
        batteryValueUserDeviceLabel.makeUp(with: .current, color: .defaultTextColor)
    }

    // MARK: - Internal Funcs
    /// Sets up function used for User Device and Remote states.
    ///
    /// - Parameters:
    ///    - state: the current state
    func setup(state: ViewModelState) {
        switch state {
        case is UserDeviceInfosState:
            currentUserDeviceState = state as? UserDeviceInfosState
            setupUserDevice(state)
        case is RemoteInfosState:
            currentState = state
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
        batteryLevelImageView.image = batteryValue.batteryRemoteControl
    }
}

/// Utils for User Device case.
private extension DashboardDeviceCell {
    /// Update User Device cell view.
    ///
    /// - Parameters:
    ///    - state: The view model state for User Device cell
    func setupUserDevice(_ state: ViewModelState) {
        if let userDeviceInfosState = state as? UserDeviceInfosState {
            updateGpsStatus(with: currentUserDeviceState?.userDeviceGpsStrength.value ?? .unavailable)
            updateUserDeviceBatteryLevel(userDeviceInfosState.userDeviceBatteryLevel.value)
            observeUserDeviceValues(userDeviceInfosState)
        }
    }

    /// Observe values from user device state.
    ///
    /// - Parameters:
    ///    - userDeviceInfosState: The view model state for user device cell
    func observeUserDeviceValues(_ userDeviceInfosState: UserDeviceInfosState) {
        userDeviceInfosState.userDeviceBatteryLevel.valueChanged = { [weak self] batteryValue in
            self?.updateUserDeviceBatteryLevel(batteryValue)
        }
        userDeviceInfosState.userDeviceGpsStrength.valueChanged = { [weak self] gpsStrength in
            self?.updateGpsStatus(with: gpsStrength)
        }
    }

    /// Updates user device gps status icon.
    ///
    /// - Parameters:
    ///    - gps: the current user location gps strength
    func updateGpsStatus(with gps: UserLocationGpsStrength) {
        gpsStatusImageView.image = Asset.Gps.Controller.icGpsNone.image
        if let currentState = currentState as? RemoteInfosState,
           currentState.remoteConnectionState.value == .connected {
            gpsStatusImageView.image = gps.image
        }
    }

    /// Updates user device battery percent and icon.
    ///
    /// - Parameters:
    ///    - batteryValue: the current battery value model
    func updateUserDeviceBatteryLevel(_ batteryValue: BatteryValueModel) {
        var currentValue: Int?
        var imageBattery = Asset.Remote.icBatteryUserDeviceNone.image

        if let currentState = currentState as? RemoteInfosState,
           currentState.remoteConnectionState.value == .connected {
            currentValue = batteryValue.currentValue ?? nil
            imageBattery = batteryValue.batteryUserDevice
        }

        batteryValueUserDeviceLabel.attributedText = NSMutableAttributedString(withBatteryLevel: currentValue)
        batteryLevelUserDeviceImageView.image = imageBattery
    }
}

/// Utils for Remote Case.
private extension DashboardDeviceCell {
    /// Update remote cell view.
    ///
    /// - Parameters:
    ///    - state: The view model state for remote cell
    func setupRemote(_ state: ViewModelState) {
        if let remoteInfosState = state as? RemoteInfosState {
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
            deviceImageView.image = Asset.Dashboard.icController.image
        case .connected:
            if remoteInfosState.remoteUpdateState.value == .required {
                status = .updateRequired
                title = remoteInfosState.remoteUpdateVersion.value
            } else if remoteInfosState.remoteNeedCalibration.value == true {
                status = .calibrationRequired
                title = L10n.remoteCalibrationRequired
            } else if remoteInfosState.remoteUpdateState.value == .recommended {
                status = .updateAvailable
                title = remoteInfosState.remoteUpdateVersion.value
            } else {
                status = .notDisconnected
                title = connectionState.title
            }
            deviceImageView.image = Asset.Dashboard.icControllerOn.image
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
        remoteInfosState.remoteUpdateState.valueChanged = { [weak self] _ in
            self?.updateRemoteStateButton(remoteInfosState)
        }
        remoteInfosState.remoteConnectionState.valueChanged = { [weak self] _ in
            self?.updateRemoteStateButton(remoteInfosState)
            if let currentUserDeviceState = self?.currentUserDeviceState {
                self?.updateUserDeviceBatteryLevel(currentUserDeviceState.userDeviceBatteryLevel.value)
                self?.updateGpsStatus(with: currentUserDeviceState.userDeviceGpsStrength.value)
            }
        }
        remoteInfosState.remoteNeedCalibration.valueChanged = { [weak self] _ in
            self?.updateRemoteStateButton(remoteInfosState)
        }
    }
}
