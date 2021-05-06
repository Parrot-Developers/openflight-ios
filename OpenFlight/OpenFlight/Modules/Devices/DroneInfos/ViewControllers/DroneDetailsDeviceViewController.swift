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

/// Displays drone specific details about device state.
final class DroneDetailsDeviceViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var componentsStatusView: DroneComponentsStatusView!
    @IBOutlet private weak var modelLabel: UILabel!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var nbSatelliteLabel: UILabel!
    @IBOutlet private weak var batteryLabel: UILabel!
    @IBOutlet private weak var gpsImageView: UIImageView!
    @IBOutlet private weak var batteryImageView: UIImageView!
    @IBOutlet private weak var satelliteImageView: UIImageView!
    @IBOutlet private weak var networkImageView: UIImageView!
    @IBOutlet private weak var separatorView: UIView!

    // MARK: - Private Properties
    private let viewModel = DroneInfosViewModel()
    private weak var coordinator: Coordinator?

    // MARK: - Setup
    static func instantiate(coordinator: Coordinator) -> DroneDetailsDeviceViewController {
        let viewController = StoryboardScene.DroneDetailsDevice.initialScene.instantiate()
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
private extension DroneDetailsDeviceViewController {
    /// Inits the view.
    func initView() {
        separatorView.backgroundColor = UIColor(named: .white20)
        modelLabel.makeUp(with: .huge)
        nameLabel.makeUp(with: .large, and: .white20)
        separatorView.backgroundColor = ColorName.white20.color
    }

    /// Observes main view model.
    func observeViewModel() {
        viewModel.state.valueChanged = { [weak self] state in
            self?.stateDidUpdate(state)
            self?.batteryLevelChanged(state.batteryLevel)
            self?.gpsStrengthChanged(state.gpsStrength)
            self?.nameChanged(state.droneName)
            self?.updateVisibility(state.isConnected())
            self?.updateSatelliteCount()

            let isCellularActive = state.currentLink == .cellular
            self?.cellularIconChanged(state.cellularStrength.signalIcon(isLinkActive: isCellularActive))
        }

        let state = viewModel.state.value
        stateDidUpdate(state)
        batteryLevelChanged(state.batteryLevel)
        gpsStrengthChanged(state.gpsStrength)
        nameChanged(state.droneName)
        updateVisibility(state.isConnected())
        updateSatelliteCount()
        let isCellularActive = state.currentLink == .cellular
        cellularIconChanged(state.cellularStrength.signalIcon(isLinkActive: isCellularActive))
    }

    /// Listens battery changed.
    ///
    /// - Parameters:
    ///     - battery: current battery value
    func batteryLevelChanged(_ battery: BatteryValueModel) {
        if let batteryLevel = battery.currentValue {
            batteryLabel.attributedText = NSMutableAttributedString(withBatteryLevel: batteryLevel)
        } else {
            batteryLabel.text = Style.dash
        }
        batteryImageView.image = battery.batteryImage
    }

    /// Listens gps changed.
    ///
    /// - Parameters:
    ///     - gpsStrength: current gps value
    func gpsStrengthChanged(_ gpsStrength: GpsStrength) {
        gpsImageView.image = gpsStrength.image
    }

    /// Listens name changed.
    ///
    /// - Parameters:
    ///     - name: current drone name
    func nameChanged(_ name: String) {
        nameLabel.text = name
    }

    /// Listens cellular access icon changed.
    ///
    /// - Parameters:
    ///     - icon: current drone network image
    func cellularIconChanged(_ icon: UIImage?) {
        networkImageView.image = icon
    }

    /// State changed callback.
    ///
    /// - Parameters:
    ///     - state: drone details state
    func stateDidUpdate(_ state: DroneInfosState) {
        componentsStatusView.model.droneGimbalStatus = state.gimbalStatus
        componentsStatusView.model.frontStereoGimbalStatus = state.frontStereoGimbalStatus
        componentsStatusView.model.stereoVisionStatus = state.stereoVisionStatus
        componentsStatusView.model.update(with: state.copterMotorsErrors)
        modelLabel.text = state.droneModel
    }

    /// Manages each item's visibility according to the connection state.
    ///
    /// - Parameters:
    ///     - isConnected: drone connection state
    func updateVisibility(_ isConnected: Bool) {
        componentsStatusView.model.isDroneConnected = isConnected
    }

    /// Updates satellite count.
    func updateSatelliteCount() {
        let isConnected = viewModel.state.value.isConnected()
        nbSatelliteLabel.text = isConnected ? String(viewModel.state.value.satelliteCount ?? 0) : Style.dash
        satelliteImageView.image = isConnected ? Asset.Drone.icSatellite.image : Asset.Drone.icSatelliteUnavailable.image
    }
}
