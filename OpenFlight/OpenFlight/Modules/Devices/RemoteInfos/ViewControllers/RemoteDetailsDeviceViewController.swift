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

/// Displays details about remote control physical device.
final class RemoteDetailsDeviceViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var modelLabel: UILabel!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var remoteImageView: UIImageView!
    @IBOutlet private weak var batteryImageView: UIImageView!
    @IBOutlet private weak var batteryValueLabel: UILabel!

    // MARK: - Private Properties
    private var viewModel: RemoteInfosViewModel?
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

        initView()
        observeViewModel()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Private Funcs
private extension RemoteDetailsDeviceViewController {
    /// Inits the view.
    func initView() {
        batteryImageView.image = Asset.Remote.icBatteryFull.image
        modelLabel.makeUp(with: .huge)
        nameLabel.makeUp(with: .large, and: .white20)
    }

    /// Observes the remote infos view model.
    func observeViewModel() {
        viewModel = RemoteInfosViewModel(batteryLevelDidChange: { [weak self] battery in
            self?.batteryLevelChanged(battery)
        }, nameDidChange: { [weak self] name in
            self?.nameChanged(name)
        }, stateDidChange: { [weak self] connectionState in
            self?.updateVisibility(connectionState == .connected)
        })

        if let state = viewModel?.state.value {
            batteryLevelChanged(state.remoteBatteryLevel.value)
            nameChanged(state.remoteName.value)
            updateVisibility(state.remoteConnectionState.value == .connected)
        }
    }

    /// Updates remote name changed.
    ///
    /// - Parameters:
    ///     - name: current remote name
    func nameChanged(_ name: String?) {
        if let strongName = name, !strongName.isEmpty {
            nameLabel.text = strongName
            nameLabel.isHidden = false
            modelLabel.text = viewModel?.remoteModel
        } else {
            nameLabel.isHidden = true
            modelLabel.text = L10n.remoteDetailsControllerInfos
        }
    }

    /// Manages remote image view according to the connection state.
    ///
    /// - Parameters:
    ///     - isConnected: drone connection state
    func updateVisibility(_ isConnected: Bool) {
        remoteImageView.image = isConnected
            ? Asset.Remote.icRemoteBigConnected.image
            : Asset.Remote.icRemoteBigDisconnected.image
    }

    /// Updates remote battery changed.
    ///
    /// - Parameters:
    ///     - battery: current battery value
    func batteryLevelChanged(_ battery: BatteryValueModel) {
        batteryValueLabel.attributedText = NSMutableAttributedString(withBatteryLevel: battery.currentValue)
        batteryImageView.image = battery.batteryImage
    }
}
