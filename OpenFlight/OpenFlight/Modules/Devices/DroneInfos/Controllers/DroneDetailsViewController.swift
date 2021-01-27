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
import GroundSdk

/// View Controller used to display details about drone.
final class DroneDetailsViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var landscapeContainerView: UIView!
    @IBOutlet private weak var bgView: UIView!
    @IBOutlet private weak var componentsStatusView: DroneComponentsStatusView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var nbSatelliteLabel: UILabel!
    @IBOutlet private weak var batteryLabel: UILabel!
    @IBOutlet private weak var gpsImageView: UIImageView!
    @IBOutlet private weak var batteryImageView: UIImageView!
    @IBOutlet private weak var satelliteImageView: UIImageView!
    @IBOutlet private weak var networkImageView: UIImageView!
    @IBOutlet private weak var separatorView: UIView!

    // MARK: - Private Properties
    private weak var coordinator: DroneCoordinator?
    private var droneDetailsViewModel: DroneDetailsViewModel?
    private var droneDetailsListViewModel: DroneDetailsInformationsViewModel?
    private var droneDetailsMapVC: DroneDetailsMapViewController?

    // MARK: - Private Enums
    private enum Constants {
        static let cellHeight: CGFloat = 40.0
        static let verticalCellMargin: CGFloat = 20.0
    }

    /// Enum which stores messages to log.
    private enum EventLoggerConstants {
        static let screenMessage: String = "DroneDetails"
    }

    // MARK: - Setup
    static func instantiate(coordinator: DroneCoordinator) -> DroneDetailsViewController {
        let viewController = StoryboardScene.DroneDetails.initialScene.instantiate()
        viewController.coordinator = coordinator

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        observeDatas()
        addCloseButton(onTapAction: #selector(backButtonTouchedUpInside(_:)))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        logScreen(logMessage: EventLoggerConstants.screenMessage)
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let buttonsViewController = segue.destination as? DroneDetailsButtonsViewController {
            buttonsViewController.coordinator = coordinator
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension DroneDetailsViewController {
    @objc func backButtonTouchedUpInside(_ sender: UIButton) {
        coordinator?.dismissDroneInfos()
    }
}

// MARK: - Private Funcs
private extension DroneDetailsViewController {
    /// Init the view.
    func initView() {
        bgView.backgroundColor = UIColor(named: .white10)
        separatorView.backgroundColor = UIColor(named: .white20)
    }

    /// Observes main view model.
    func observeDatas() {
        droneDetailsViewModel = DroneDetailsViewModel(stateDidUpdate: {[weak self] state in
            self?.stateDidUpdate(state)
            }, batteryLevelDidChange: {[weak self] battery in
                self?.batteryLevelChanged(battery)
            }, wifiStrengthDidChange: nil,
               gpsStrengthDidChange: {[weak self] gpsStrength in
                self?.gpsStrengthChanged(gpsStrength)
            }, nameDidChange: {[weak self] droneName in
                self?.nameChanged(droneName)
            }, connectionStateDidChange: { [weak self] connectionState in
                self?.updateVisibility(connectionState == .connected)
            }, needUpdateDidChange: nil,
               cellularStateDidChange: { [weak self] cellularIcon in
                self?.cellularIconChanged(cellularIcon)
            }, isCellularAvailabilityChange: { [weak self] isAvailable in
                self?.updateCellularIconVisibility(isAvailable)
            }
        )

        // First init.
        if let state = droneDetailsViewModel?.state.value {
            stateDidUpdate(state)
            batteryLevelChanged(state.batteryLevel.value)
            gpsStrengthChanged(state.gpsStrength.value)
            nameChanged(state.droneName.value)
            updateVisibility(state.droneConnectionState.value == DeviceState.ConnectionState.connected)
            updateCellularIconVisibility(state.isCellularAvailable.value)
        }
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

    /// Listens cellular access availability.
    ///
    /// - Parameters:
    ///     - isAvailable: tells if 4G network is available
    func updateCellularIconVisibility(_ isAvailable: Bool) {
        networkImageView.isHidden = !isAvailable
    }

    /// State changed callback.
    ///
    /// - Parameters:
    ///     - state: drone details state
    func stateDidUpdate(_ state: DroneDetailsState) {
        componentsStatusView.model.droneGimbalStatus = state.gimbalState
        componentsStatusView.model.stereoVisionStatus = state.stereoVisionState
        componentsStatusView.model.update(with: state.copterMotorsError)
    }

    /// Manages each item's visibility according to the connection state.
    ///
    /// - Parameters:
    ///     - isConnected: drone connection state
    func updateVisibility(_ isConnected: Bool) {
        componentsStatusView.model.isDroneConnected = isConnected
        nbSatelliteLabel.text = isConnected ? String(droneDetailsViewModel?.state.value.satelliteCount ?? 0) : Style.dash
        satelliteImageView.image = isConnected ? Asset.Drone.icSatellite.image : Asset.Drone.icSatelliteUnavailable.image
    }

    /// Present a common alert in case of update error.
    ///
    /// - Parameters:
    ///     - title: alert title
    ///     - message: alert message
    func showErrorAlert(title: String, message: String) {
        self.showAlertInfo(title: title, message: title)
    }
}
