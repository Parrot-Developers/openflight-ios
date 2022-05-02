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

import UIKit
import Combine
import Reusable

/// Custom View used for Drone cell in the Dashboard.
class DashboardDroneCell: UICollectionViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var gpsStatusImageView: UIImageView!
    @IBOutlet private weak var networkImageView: UIImageView!
    @IBOutlet private weak var wifiStatusImageView: UIImageView!
    @IBOutlet private weak var deviceImageView: UIImageView!
    @IBOutlet private weak var nameDeviceLabel: UILabel!
    @IBOutlet private weak var deviceStateButton: DeviceStateButton!
    @IBOutlet private weak var batteryValueLabel: UILabel!
    @IBOutlet private weak var batteryLevelImageView: UIImageView!

    // MARK: - Private Properties
    private weak var viewModel: DroneInfosViewModel?
    private var cancellables = Set<AnyCancellable>()
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
        bindToViewModel()
        firmwareAndMissionsUpdateListener = FirmwareAndMissionsInteractor.shared
            .register { [weak self] (_, firmwareAndMissionToUpdateModel) in
                self?.firmwareAndMissionToUpdateModel = firmwareAndMissionToUpdateModel
                self?.setDeviceStateButton(with: firmwareAndMissionToUpdateModel,
                                           self?.viewModel?.requiredCalibrationSubject.value ?? false,
                                           self?.viewModel?.recommendedCalibrationSubject.value ?? false)
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
    @IBAction func stateDeviceTouchedUpInside(_ sender: Any) {
        delegate?.startUpdate(.drone)
    }
}

// MARK: - Private Funcs
private extension DashboardDroneCell {

    func bindToViewModel() {
        bindBatteryLevel()
        bindWifiStrength()
        bindGpsStrength()
        bindDroneName()
        bindCellularStrength()
        bindDeviceState()
    }

    /// Binds the battery from the view model to battery label
    func bindBatteryLevel() {
        viewModel?.$batteryLevel
            .sink { [unowned self] batteryValue in
                batteryValueLabel.attributedText = NSMutableAttributedString(withBatteryLevel: batteryValue.currentValue)
                batteryLevelImageView.image = batteryValue.batteryImage
            }
            .store(in: &cancellables)
    }

    /// Binds the wifi strength from the view model to wifi image view
    func bindWifiStrength() {
        viewModel?.$wifiStrength
            .sink { [unowned self] wifiStrength in
                wifiStatusImageView.image = wifiStrength?.signalIcon
            }
            .store(in: &cancellables)
    }

    /// Binds the gps strenght from the view model to gps status image view
    func bindGpsStrength() {
        viewModel?.$gpsStrength
            .sink { [unowned self] gpsStrength in
                gpsStatusImageView.image = gpsStrength.image
            }
            .store(in: &cancellables)
    }

    /// Binds the drone name from the view model to the device name label
    func bindDroneName() {
        viewModel?.$droneName
            .sink { [unowned self] droneName in
                nameDeviceLabel.text = droneName
            }
            .store(in: &cancellables)
    }

    /// Binds the cellular strength from the view model to the network image view
    func bindCellularStrength() {
        viewModel?.$cellularStrength
            .sink { [unowned self] cellularStrength in
                networkImageView.image = cellularStrength.signalIcon
            }
            .store(in: &cancellables)
    }

    /// Binds the device state from the view model to the device state label.
    func bindDeviceState() {
        guard let viewModel = viewModel else { return }

        viewModel.$connectionState
            .combineLatest(viewModel.requiredCalibrationSubject,
                           viewModel.recommendedCalibrationSubject)
            .sink { [unowned self] _, calibrationIsRequired, calibrationIsRecommended in
                if let firmwareAndMissionToUpdateModel = firmwareAndMissionToUpdateModel {
                    setDeviceStateButton(with: firmwareAndMissionToUpdateModel,
                                         calibrationIsRequired,
                                         calibrationIsRecommended)
                }
            }
            .store(in: &cancellables)
    }

    /// This method is used to clean UI before setting value from the state.
    func cleanViews() {
        networkImageView.image = nil
        batteryLevelImageView.image = nil
        nameDeviceLabel.text = nil
        batteryValueLabel.text = nil
        wifiStatusImageView.image = nil
        gpsStatusImageView.image = nil
    }

    /// This method is used to clean all current states.
    func cleanStates() {
        FirmwareAndMissionsInteractor.shared.unregister(firmwareAndMissionsUpdateListener)
        firmwareAndMissionToUpdateModel = nil
    }
}

// MARK: - Private Funcs
private extension DashboardDroneCell {

    /// Sets the device state button label.
    ///
    /// - Parameters:
    ///    - firmwareAndMissionToUpdateModel: The firmware and mission update model
    ///    - calibrationIsRequired: True if a calibration is required
    ///    - calibrationIsRecommended: True if a calibration is recommended
    func setDeviceStateButton(with firmwareAndMissionToUpdateModel: FirmwareAndMissionToUpdateModel,
                              _ calibrationIsRequired: Bool = false,
                              _ calibrationIsRecommended: Bool = false) {
        guard let droneInfosViewModel = viewModel else { return }

        let connectionState = droneInfosViewModel.connectionState
        let status: DeviceStateButton.Status
        let title: String

        switch connectionState {
        case .disconnected:
            status = .disconnected
            title = L10n.commonNotConnected
        case .connected:
            if firmwareAndMissionToUpdateModel.updateRequired {
                status = .updateRequired
                title = firmwareAndMissionToUpdateModel.stateButtonTitle
            } else if calibrationIsRequired {
                status = .calibrationRequired
                title = L10n.droneCalibrationRequired
            } else if firmwareAndMissionToUpdateModel.needUpdate {
                status = .updateAvailable
                title = firmwareAndMissionToUpdateModel.stateButtonTitle
            } else if calibrationIsRecommended {
                status = .calibrationIsRecommended
                title = L10n.droneCalibrationAdvised
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
}
