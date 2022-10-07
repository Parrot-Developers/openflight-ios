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
import GroundSdk

// MARK: - Protocols
protocol HUDControlsInfoViewControllerNavigation: AnyObject {
    /// Called when remote control informations screen should be opened.
    func openRemoteControlInfos()
    /// Called when drone information screen should be opened.
    func openDroneInfos()
    /// Called when network settings should be opened.
    func openNetworkSettings()
}

final class HUDControlsInfoViewController: UIViewController {
    // MARK: - Outlets
    // Controller Infos
    @IBOutlet private weak var controllerImageView: UIImageView! {
        didSet {
            // Workaround for tint color issues.
            controllerImageView.tintColorDidChange()
        }
    }
    @IBOutlet private weak var controllerBatteryLevelLabel: UILabel!
    @IBOutlet private weak var controllerGpsImageView: UIImageView!
    @IBOutlet private weak var controllerBatteryAlertBackgroundView: UIView!

    // Drone Infos
    @IBOutlet private weak var droneBatteryImageView: UIImageView! {
        didSet {
            // workaround for tint color issues
            droneBatteryImageView.tintColorDidChange()
        }
    }
    @IBOutlet private weak var droneBatteryLabel: UILabel!
    @IBOutlet private weak var droneGpsImageView: UIImageView!
    @IBOutlet private weak var droneBatteryAlertBackgroundView: UIView!

    // Network Infos
    @IBOutlet private weak var droneWifiImageView: UIImageView!
    @IBOutlet private weak var wifiAlertBackgroundView: UIView!
    @IBOutlet private weak var droneCellularImageView: UIImageView!
    @IBOutlet private weak var cellularBackgroundView: UIView!

    // MARK: - Internal Properties
    weak var navigationDelegate: HUDControlsInfoViewControllerNavigation?

    // MARK: - Private Properties
    private let controllerInfosViewModel = ControllerInfosViewModel()
    private let droneInfosViewModel = DroneInfosViewModel()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        bindToControllerViewModel()
        bindToDroneViewModel()
    }
}

// MARK: - Actions
private extension HUDControlsInfoViewController {
    @IBAction func controllerInfoTouchedUpInside(_ sender: Any) {
        guard controllerInfosViewModel.currentController == .remoteControl else { return }

        LogEvent.log(.simpleButton(LogEvent.LogKeyHUDTopBarButton.remoteControlDetails))
        navigationDelegate?.openRemoteControlInfos()
    }

    @IBAction func droneInfoTouchedUpInside() {
        LogEvent.log(.simpleButton(LogEvent.LogKeyHUDTopBarButton.droneDetails))
        navigationDelegate?.openDroneInfos()
    }

    @IBAction func droneCellularWifiTouchedUpInside(_ sender: Any) {
        navigationDelegate?.openNetworkSettings()
    }
}

// MARK: - Private Funcs
private extension HUDControlsInfoViewController {
    /// Sets up view.
    func setupView() {
        controllerBatteryLevelLabel.font = FontStyle.topBar.font(isRegularSizeClass, monospacedDigits: true)
        droneBatteryLabel.font = FontStyle.topBar.font(isRegularSizeClass, monospacedDigits: true)
        controllerBatteryAlertBackgroundView.applyCornerRadius(Style.mediumCornerRadius)
        droneBatteryAlertBackgroundView.applyCornerRadius(Style.mediumCornerRadius)
    }

    /// Binds to controller's view model.
    func bindToControllerViewModel() {
        controllerInfosViewModel.$batteryLevel
            .sink { [unowned self] batteryLevel in
                if let level = batteryLevel.currentValue {
                    controllerBatteryLevelLabel.attributedText = NSMutableAttributedString(withBatteryLevel: level)
                    controllerBatteryLevelLabel.accessibilityValue = "\(level)"
                } else {
                    controllerBatteryLevelLabel.text = Style.dash
                    controllerBatteryLevelLabel.accessibilityValue = "-"
                }

                controllerBatteryAlertBackgroundView.backgroundColor =  batteryLevel.alertLevel.color
            }
            .store(in: &cancellables)

        controllerInfosViewModel.$currentController
            .sink { [unowned self] controller in
                controllerImageView.image = controller.batteryImage
            }
            .store(in: &cancellables)

        controllerInfosViewModel.$gpsStrength
            .sink { [unowned self] gpsStrength in
                controllerGpsImageView.image = gpsStrength.image
            }
            .store(in: &cancellables)
    }

    /// Binds to drone's view model.
    func bindToDroneViewModel() {
        // Binding battery level
        droneInfosViewModel.$batteryLevel
            .sink { [unowned self] batteryLevel in
                if let batteryValue = batteryLevel.currentValue {
                    droneBatteryLabel.attributedText = NSMutableAttributedString(withBatteryLevel: batteryValue)
                    droneBatteryLabel.accessibilityValue = "\(batteryValue)"
                } else {
                    droneBatteryLabel.text = Style.dash
                    droneBatteryLabel.accessibilityValue = "-"
                }

                droneBatteryAlertBackgroundView.backgroundColor = batteryLevel.alertLevel.color
            }
            .store(in: &cancellables)

        // Binding gps strength
        droneInfosViewModel.$gpsStrength
            .sink { [unowned self] gpsStrength in
                droneGpsImageView.image = gpsStrength.image
            }
            .store(in: &cancellables)

        // Binding wifi strength
        droneInfosViewModel.$wifiStrength
            .sink { [unowned self] wifiStrength in
                configureWifiView(wifiStrength: wifiStrength ?? .offline)
            }
            .store(in: &cancellables)

        // Binding cellular strength
        droneInfosViewModel.$cellularStrength
            .sink { [unowned self] cellularStrength in
                configureCellularView(cellularStrength: cellularStrength)
            }
            .store(in: &cancellables)

        droneInfosViewModel.$currentLink
            .sink { [unowned self] currentLink in
                configureWifiView(wifiStrength: droneInfosViewModel.wifiStrength ?? .offline, currentLink: currentLink)
                configureCellularView(cellularStrength: droneInfosViewModel.cellularStrength, currentLink: currentLink)
            }
            .store(in: &cancellables)
    }

    func configureWifiView(wifiStrength: WifiStrength, currentLink: NetworkControlLinkType? = nil) {
        let currenLink = currentLink ?? droneInfosViewModel.currentLink
        droneWifiImageView.image = wifiStrength.signalIcon
        wifiAlertBackgroundView.animateIsHiddenInStackView(currenLink != .wlan)
        if currenLink == .wlan {
            wifiAlertBackgroundView.cornerRadiusedWith(backgroundColor: wifiStrength.backgroundColor.color,
                                                       borderColor: wifiStrength.borderColor.color,
                                                       radius: Style.smallCornerRadius,
                                                       borderWidth: Style.mediumBorderWidth)
        }
    }

    func configureCellularView(cellularStrength: CellularStrength, currentLink: NetworkControlLinkType? = nil) {
        let currentLink = currentLink ?? droneInfosViewModel.currentLink
        droneCellularImageView.image = cellularStrength.signalIcon
        cellularBackgroundView.animateIsHiddenInStackView(currentLink != .cellular)
        if currentLink == .cellular {
            cellularBackgroundView.cornerRadiusedWith(backgroundColor: cellularStrength.backgroundColor.color,
                                                      borderColor: cellularStrength.borderColor.color,
                                                      radius: Style.smallCornerRadius,
                                                      borderWidth: Style.mediumBorderWidth)
        }
    }
}
