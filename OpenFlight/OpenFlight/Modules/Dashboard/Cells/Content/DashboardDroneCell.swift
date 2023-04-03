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
    @IBOutlet private weak var callularStatusImageView: UIImageView!
    @IBOutlet private weak var driStateImageView: UIImageView!
    @IBOutlet private weak var wifiStatusImageView: UIImageView!
    @IBOutlet private weak var deviceImageView: UIImageView!
    @IBOutlet private weak var nameDeviceLabel: UILabel!
    @IBOutlet private weak var deviceStateButton: DeviceStateButton!
    @IBOutlet private weak var batteryValueLabel: UILabel!
    @IBOutlet private weak var batteryLevelImageView: UIImageView!

    // MARK: - Private Properties
    private weak var droneInfosviewModel: DroneInfosViewModel?
    private var viewModel: DashboardDroneCellViewModel = DashboardDroneCellViewModel()
    private var cancellables = Set<AnyCancellable>()
    private weak var delegate: DashboardDeviceCellDelegate?

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()
        // Clean UI when we create the cell.
        cleanViews()
        setupUI()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        // Clean UI and states.
        cleanViews()
    }

    func setupUI() {
        batteryValueLabel.makeUp(with: .current, color: .defaultTextColor)
    }

    // MARK: - Internal Funcs
    /// Sets up view.
    ///
    /// - Parameters:
    ///    - state: The view model state for drone cell
    func setup(_ droneInfosviewModel: DroneInfosViewModel) {
        self.droneInfosviewModel = droneInfosviewModel
        bindToViewModel()
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
        bindDriState()
        bindUpdatesState()
    }

    /// Binds the battery from the view model to battery label
    func bindBatteryLevel() {
        droneInfosviewModel?.$batteryLevel
            .sink { [weak self] batteryValue in
                guard let self = self else { return }
                self.batteryValueLabel.attributedText = NSMutableAttributedString(withBatteryLevel: batteryValue.currentValue)
                self.batteryLevelImageView.image = batteryValue.batteryImage
            }
            .store(in: &cancellables)
    }

    /// Binds the wifi strength from the view model to wifi image view
    func bindWifiStrength() {
        droneInfosviewModel?.$wifiStrength
            .sink { [weak self] wifiStrength in
                guard let self = self else { return }
                self.wifiStatusImageView.image = wifiStrength.signalIcon
            }
            .store(in: &cancellables)
    }

    /// Binds the gps strenght from the view model to gps status image view
    func bindGpsStrength() {
        droneInfosviewModel?.$gpsStrength
            .sink { [weak self] gpsStrength in
                guard let self = self else { return }
                self.gpsStatusImageView.image = gpsStrength.image
            }
            .store(in: &cancellables)
    }

    /// Binds the drone name from the view model to the device name label
    func bindDroneName() {
        droneInfosviewModel?.$droneName
            .sink { [weak self] droneName in
                guard let self = self else { return }
                self.nameDeviceLabel.text = droneName
            }
            .store(in: &cancellables)
    }

    /// Binds the cellular strength from the view model to the network image view
    func bindCellularStrength() {
        droneInfosviewModel?.$cellularStrength
            .sink { [weak self] cellularStrength in
                guard let self = self else { return }
                self.callularStatusImageView.image = cellularStrength.signalIcon
            }
            .store(in: &cancellables)
    }

    /// Binds the dri state from the view model to the dri imageView
    func bindDriState() {
        droneInfosviewModel?.$driState
            .sink { [weak self] driState in
                guard let self = self else { return }
                self.driStateImageView.image = driState.driIcon
            }
            .store(in: &cancellables)
    }

    /// Listens to its viewmodel states to update the device button
    func bindUpdatesState() {
        viewModel.$updateState
            .combineLatest(viewModel.$stateButtonTitle, viewModel.$missionsCount, viewModel.$shouldUpdateBattery)
            .receive(on: RunLoop.main)
            .sink { [weak self] updateState, stateButtonTitle, missionsCount, shouldUpdateBattery in
                guard let self = self else { return }
                let isCalibrationRequired  = self.droneInfosviewModel?.isCalibrationRequired ?? false
                let isCalibrationRecommended = self.droneInfosviewModel?.isCalibrationRecommended ?? false
                self.setDeviceStateButton(
                    updateState: updateState,
                    stateButtonTitle: stateButtonTitle,
                    missionsCount: missionsCount,
                    shouldUpdateBattery: shouldUpdateBattery,
                    isCalibrationRequired: isCalibrationRequired,
                    isCalibrationRecommended: isCalibrationRecommended)
            }
            .store(in: &cancellables)
    }

    /// This method is used to clean UI before setting value from the state.
    func cleanViews() {
        callularStatusImageView.image = nil
        batteryLevelImageView.image = nil
        nameDeviceLabel.text = nil
        batteryValueLabel.text = nil
        wifiStatusImageView.image = nil
        gpsStatusImageView.image = nil
    }
}

// MARK: - Private Funcs
private extension DashboardDroneCell {

    /// Updates the content and style of the device button
    ///
    /// The content is based on available or required firmware and missions updates and calibration requirements.
    /// - Parameters:
    ///     - updateState: Wether there are required or recommanded updates available
    ///     - stateButtonTitle: Custom title when appropriate
    ///     - missionsCount: Number of mission updates available
    ///     - shouldUpdateBattery: `true` if an update to battery firmware is available
    ///     - isCalibrationRequired: `true` if any calibration is required
    ///     - isCalibrationRecommended: `true` if any calibration is recommended
    func setDeviceStateButton(
        updateState: UpdateState?,
        stateButtonTitle: String,
        missionsCount: Int,
        shouldUpdateBattery: Bool,
        isCalibrationRequired: Bool = false,
        isCalibrationRecommended: Bool = false) {
            guard let droneInfosViewModel = droneInfosviewModel else { return }
            let connectionState = droneInfosViewModel.connectionState
            let status: DeviceStateButton.Status
            let title: String
            switch connectionState {
            case .disconnected:
                status = .disconnected
                title = L10n.commonNotConnected
            case .connected:
                if updateState == .required {
                    status = .updateRequired
                    title = stateButtonTitle
                } else if isCalibrationRequired {
                    status = .calibrationRequired
                    title = L10n.droneCalibrationRequired
                } else if updateState == .recommended {
                    status = .updateAvailable
                    title = stateButtonTitle
                } else if isCalibrationRecommended {
                    status = .calibrationIsRecommended
                    title = L10n.droneCalibrationAdvised
                } else if missionsCount == 1 {
                    status = .updateAvailable
                    title = stateButtonTitle
                } else if missionsCount > 1 {
                    status = .updateAvailable
                    title = L10n.firmwareMissionUpdateMissions
                } else if shouldUpdateBattery {
                    status = .updateAvailable
                    title = L10n.battery
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
