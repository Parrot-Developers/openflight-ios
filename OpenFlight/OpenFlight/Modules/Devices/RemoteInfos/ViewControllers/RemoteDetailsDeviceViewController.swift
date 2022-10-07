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

/// Displays details about remote control physical device.
final class RemoteDetailsDeviceViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var remoteImageView: UIImageView!
    @IBOutlet private weak var batteryImageView: UIImageView!
    @IBOutlet private weak var batteryValueLabel: UILabel!
    @IBOutlet private weak var batteryDeviceImageView: UIImageView!
    @IBOutlet private weak var batteryDeviceValueLabel: UILabel!
    @IBOutlet private weak var iconGpsImageView: UIImageView!

    // MARK: - Private Properties
    private var viewModel: RemoteInfosViewModel?
    private var userDeviceViewModel: UserDeviceViewModel?
    private weak var coordinator: RemoteCoordinator?

    // MARK: - Setup
    static func instantiate(coordinator: RemoteCoordinator) -> RemoteDetailsDeviceViewController {
        let viewController = StoryboardScene.RemoteDetailsDevice.initialScene.instantiate()
        viewController.coordinator = coordinator

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        observeViewModel()
        observeUserDeviceViewModel()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Private Funcs
private extension RemoteDetailsDeviceViewController {
    func setupUI() {
        batteryValueLabel.makeUp(with: .current, color: .defaultTextColor)
        batteryDeviceValueLabel.makeUp(with: .current, color: .defaultTextColor)
    }

    /// Observes the remote infos view model.
    func observeViewModel() {
        viewModel = RemoteInfosViewModel(batteryLevelDidChange: { [weak self] battery in
            self?.batteryLevelChanged(battery, self?.viewModel?.state.value.remoteConnectionState.value == .connected)
        }, nameDidChange: { [weak self] name in
            self?.nameChanged(name)
        }, stateDidChange: { [weak self] connectionState in
            self?.updateVisibility(connectionState == .connected)
            self?.batteryLevelUserDeviceChanged(self?.userDeviceViewModel?.state.value.userDeviceBatteryLevel.value, connectionState == .connected)
            self?.gpsStrengthChanged(self?.userDeviceViewModel?.state.value.userDeviceGpsStrength.value, isConnected: connectionState == .connected)
        })

        if let state = viewModel?.state.value {
            let isConnected = state.remoteConnectionState.value == .connected
            let batteryLevel = state.remoteBatteryLevel.value
            batteryLevelChanged(batteryLevel, isConnected)
            nameChanged(state.remoteName.value)
            updateVisibility(isConnected)
        }
    }

    func observeUserDeviceViewModel() {
        userDeviceViewModel = UserDeviceViewModel(userLocationManager: UserLocationManager(),
                                                  batteryLevelDidChange: { [weak self] battery in
            self?.batteryLevelUserDeviceChanged(battery, self?.viewModel?.state.value.remoteConnectionState.value == .connected)
        }, gpsStrengthDidChange: { [weak self] gps in
            self?.gpsStrengthChanged(gps, isConnected: self?.viewModel?.state.value.remoteConnectionState.value == .connected)
        })
    }

    /// Updates remote name changed.
    ///
    /// - Parameters:
    ///     - name: current remote name
    func nameChanged(_ name: String?) {
        if let parent = self.parent as? RemoteDetailsViewController {
            parent.nameLabel.text = name
            parent.nameLabel.isHidden = name?.isEmpty ?? true
        }
    }

    /// Manages remote image view according to the connection state.
    ///
    /// - Parameters:
    ///     - isConnected: remote connection state
    func updateVisibility(_ isConnected: Bool) {
        remoteImageView.image = isConnected
            ? Asset.Remote.icRemoteBigConnected.image
            : Asset.Remote.icRemoteBigDisconnected.image
    }

    /// Updates remote battery changed.
    ///
    /// - Parameters:
    ///     - battery: current remote battery value
    ///     - isConnected: remote connection state
    func batteryLevelChanged(_ battery: BatteryValueModel, _ isConnected: Bool) {
        batteryValueLabel.attributedText = NSMutableAttributedString(withBatteryLevel: battery.currentValue)
        batteryImageView.image = isConnected ? battery.batteryRemoteControl : Asset.Remote.icBatteryRemoteNone.image
    }

    /// Updates user's device gps strength display.
    ///
    /// - Parameters:
    ///     - gps: user device gps strength
    ///     - isConnected: remote connection state
    func gpsStrengthChanged(_ gps: UserLocationGpsStrength?, isConnected: Bool) {
        iconGpsImageView.image = isConnected ? gps?.image : UserLocationGpsStrength.unavailable.image
    }

    /// Updates user's device battery level display.
    ///
    /// - Parameters:
    ///     - battery: current user device battery value
    ///     - isConnected: remote connection state
    func batteryLevelUserDeviceChanged(_ battery: BatteryValueModel?, _ isConnected: Bool) {
        let currentValue = isConnected ? battery?.currentValue : nil
        batteryDeviceValueLabel.attributedText = NSMutableAttributedString(withBatteryLevel: currentValue)
        batteryDeviceImageView.image = isConnected ? battery?.batteryUserDevice : Asset.Remote.icBatteryUserDeviceNone.image
    }
}
