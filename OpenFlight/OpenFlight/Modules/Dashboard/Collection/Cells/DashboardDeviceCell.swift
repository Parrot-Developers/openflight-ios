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
protocol DashboardDeviceCellDelegate: class {
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
    @IBOutlet private weak var nameDeviceLabel: UILabel!
    @IBOutlet private weak var stateDeviceLabel: UILabel!
    @IBOutlet private weak var batteryValueLabel: UILabel!
    @IBOutlet private weak var bottomView: UIView!
    @IBOutlet private weak var needUpdateButton: UpdateCustomButton!

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
        case is DroneInfosState:
            setupDrone(state)
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
    @IBAction func needUpdateButtonTouchedUpInside(_ sender: Any) {
        switch currentState {
        case is RemoteInfosState:
            delegate?.startUpdate(.remote)
        case is DroneInfosState:
            delegate?.startUpdate(.drone)
        default:
            break
        }
    }
}

// MARK: - Private Funcs
private extension DashboardDeviceCell {
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
        deviceImageView.image = nil
        wifiStatusImageView.image = nil
        gpsStatusImageView.image = nil
        stateDeviceLabel.text = nil
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
        case is DroneInfosState:
            let droneInfosState = currentState as? DroneInfosState
            droneInfosState?.batteryLevel.valueChanged = nil
            droneInfosState?.wifiStrength.valueChanged = nil
            droneInfosState?.gpsStrength.valueChanged = nil
            droneInfosState?.droneName.valueChanged = nil
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
        let userDeviceInfosState = currentState as? UserDeviceInfosState
        // Set current values because we cleared all fields.
        gpsStatusImageView.image = userDeviceInfosState?.userDeviceGpsStrength.value.image
        stateDeviceLabel.text = nil
        deviceImageView.image = Asset.Dashboard.icPhone.image
        deviceImageView.tintColor = ColorName.white.color
        // Get the current app version.
        nameDeviceLabel.text = AppUtils.version
        // TODO: Add bottom view visibility when new app version is available.
        bottomView.isHidden = true

        updateBatteryLevel(userDeviceInfosState?.userDeviceBatteryLevel.value.currentValue)
        userDeviceInfosState?.userDeviceBatteryLevel.valueChanged = { [weak self] batteryValue in
            self?.batteryValueLabel.isHidden = false
            self?.updateBatteryLevel(batteryValue.currentValue)
        }
        userDeviceInfosState?.userDeviceGpsStrength.valueChanged = { [weak self] gpsStrength in
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
        let remoteInfosState = currentState as? RemoteInfosState
        setRemoteValues(remoteInfosState)
        observeRemoteValues(remoteInfosState)
        deviceImageView.image = Asset.Dashboard.icController.image
    }

    /// Set remote cell state.
    ///
    /// - Parameters:
    ///    - remoteInfosState: The view model state for remote cell
    func setRemoteValues(_ remoteInfosState: RemoteInfosState?) {
        nameDeviceLabel.text = remoteInfosState?.remoteName.value
        deviceImageView.image = Asset.Dashboard.icController.image

        updateBatteryLevel(remoteInfosState?.remoteBatteryLevel.value.currentValue)
        if remoteInfosState?.remoteNeedUpdate.value == true,
           remoteInfosState?.remoteConnectionState.value == .connected {
            stateDeviceLabel.text = nil
        } else {
            updateRemoteLabel(remoteInfosState)
        }

        needUpdateButton.isHidden = (remoteInfosState?.remoteNeedUpdate.value == false
                                        || remoteInfosState?.remoteConnectionState.value != .connected)
    }

    /// Updates label according to remote states.
    ///
    /// - Parameters:
    ///    - remoteInfosState: the view model state for remote cell
    func updateRemoteLabel(_ remoteInfosState: RemoteInfosState?) {
        if remoteInfosState?.remoteNeedCalibration.value == true {
            stateDeviceLabel.textColor = ColorName.redTorch.color
        } else if remoteInfosState?.remoteConnectionState.value == .connected {
            stateDeviceLabel.textColor = ColorName.greenSpring.color
        } else {
            stateDeviceLabel.textColor = ColorName.white50.color
        }

        stateDeviceLabel.text = remoteInfosState?.remoteNeedCalibration.value == true
            ? L10n.remoteCalibrationRequired
            : remoteInfosState?.remoteConnectionState.value.title
    }

    /// Observe values from remote state.
    ///
    /// - Parameters:
    ///    - remoteInfosState: The view model state for remote cell
    func observeRemoteValues(_ remoteInfosState: RemoteInfosState?) {
        remoteInfosState?.remoteBatteryLevel.valueChanged = { [weak self] batteryValue in
            self?.batteryValueLabel.isHidden = false
            self?.updateBatteryLevel(batteryValue.currentValue)
        }
        remoteInfosState?.remoteName.valueChanged = { [weak self] remoteName in
            self?.nameDeviceLabel.text = remoteName
        }
        remoteInfosState?.remoteNeedUpdate.valueChanged = { [weak self] remoteNeedUpdate in
            self?.needUpdateButton.isHidden = !remoteNeedUpdate || remoteInfosState?.remoteConnectionState.value != .connected
            if remoteNeedUpdate,
               remoteInfosState?.remoteConnectionState.value == .connected {
                self?.stateDeviceLabel.text = nil
            }
        }
        remoteInfosState?.remoteConnectionState.valueChanged = { [weak self] remoteConnectionState in
            self?.updateRemoteLabel(remoteInfosState)
            self?.needUpdateButton.isHidden = (remoteInfosState?.remoteNeedUpdate.value == false
                                                || remoteConnectionState != .connected)
        }
        remoteInfosState?.remoteNeedCalibration.valueChanged = { [weak self] _ in
            self?.updateRemoteLabel(remoteInfosState)
        }
    }
}

/// Utils for drone Case.
private extension DashboardDeviceCell {
    /// Update drone cell view.
    ///
    /// - Parameters:
    ///    - state: The view model state for drone cell
    func setupDrone(_ state: ViewModelState) {
        guard let droneInfosState = currentState as? DroneInfosState else {
            return
        }

        initUIForDroneCase(droneInfosState)
        listenViewModelsForDroneCase(droneInfosState)
        firmwareAndMissionsUpdateListener = FirmwareAndMissionsInteractor.shared
            .register { [weak self] (_, firmwareAndMissionToUpdateModel) in
                self?.firmwareAndMissionToUpdateModel = firmwareAndMissionToUpdateModel
                self?.setStateDeviceLabelForDroneCase(with: firmwareAndMissionToUpdateModel,
                                                      droneInfosState: droneInfosState)
            }
    }

    /// Inits the UI for drone case.
    ///
    /// - Parameters:
    ///    - droneInfosState: The view model state for drone cell
    func initUIForDroneCase(_ droneInfosState: DroneInfosState) {
        let isCellularActive = droneInfosState.currentLink.value == .cellular
        deviceImageView.image = Asset.Dashboard.icDrone.image
        updateBatteryLevel(droneInfosState.batteryLevel.value.currentValue)
        wifiStatusImageView.image = droneInfosState.wifiStrength.value.signalIcon(isLinkActive: !isCellularActive)
        gpsStatusImageView.image = droneInfosState.gpsStrength.value.image
        nameDeviceLabel.text = droneInfosState.droneName.value
        networkImageView.image = droneInfosState.cellularStrength.value.signalIcon(isLinkActive: isCellularActive)
        networkImageView.isHidden = droneInfosState.isConnected()
    }

    /// Listens View Model for drone state.
    ///
    /// - Parameters:
    ///    - droneInfosState: The view model state for drone cell
    func listenViewModelsForDroneCase(_ droneInfosState: DroneInfosState) {
        droneInfosState.batteryLevel.valueChanged = { [weak self] batteryValue in
            self?.updateBatteryLevel(batteryValue.currentValue)
        }
        droneInfosState.wifiStrength.valueChanged = { [weak self] wifiStrength in
            let isActive = droneInfosState.currentLink.value == .wlan
            self?.wifiStatusImageView.image = wifiStrength.signalIcon(isLinkActive: isActive)
        }
        droneInfosState.gpsStrength.valueChanged = { [weak self] gpsStrength in
            self?.gpsStatusImageView.image = gpsStrength.image
        }
        droneInfosState.droneName.valueChanged = { [weak self] droneName in
            self?.nameDeviceLabel.text = droneName
        }
        droneInfosState.droneNeedStereoVisionSensorCalibration.valueChanged = { [weak self] _ in
            guard let firmwareAndMissionToUpdateModel = self?.firmwareAndMissionToUpdateModel else { return }

            self?.setStateDeviceLabelForDroneCase(with: firmwareAndMissionToUpdateModel,
                                                  droneInfosState: droneInfosState)
        }
        droneInfosState.cellularStrength.valueChanged = { [weak self] cellularStrength in
            let isActive = droneInfosState.currentLink.value == .cellular
            self?.networkImageView.image = cellularStrength.signalIcon(isLinkActive: isActive)
        }
    }

    /// Sets the state device label.
    ///
    /// - Parameters:
    ///    - firmwareAndMissionToUpdateModel: The firmware and mission update model
    ///    - droneInfosState: The view model state for drone cell
    func setStateDeviceLabelForDroneCase(with firmwareAndMissionToUpdateModel: FirmwareAndMissionToUpdateModel,
                                         droneInfosState: DroneInfosState) {
        // TODO: Probably missing check on the magnetometer and perhaps on the gimbal
        let droneCalibrationRequired = droneInfosState.droneConnectionState.value == .connected
            && droneInfosState.droneNeedStereoVisionSensorCalibration.value == true

        switch firmwareAndMissionToUpdateModel {
        case .upToDate where droneCalibrationRequired,
             .notInitialized where droneCalibrationRequired:
            stateDeviceLabel.text = L10n.remoteCalibrationRequired
            stateDeviceLabel.textColor = ColorName.redTorch.color
        default:
            stateDeviceLabel.textColor = firmwareAndMissionToUpdateModel
                .stateDeviceLabelTextColor(deviceConnectionState: droneInfosState.droneConnectionState.value)
            stateDeviceLabel.text = firmwareAndMissionToUpdateModel
                .stateDeviceLabelText(deviceConnectionState: droneInfosState.droneConnectionState.value)
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
                .stateDeviceLabelText(deviceConnectionState: droneInfosState.droneConnectionState.value)
            needUpdateButton.setup(with: buttonTitle)
        }
    }
}
