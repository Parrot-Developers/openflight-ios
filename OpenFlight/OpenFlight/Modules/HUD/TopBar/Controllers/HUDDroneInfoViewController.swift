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
import Combine

// MARK: - Protocols
protocol HUDDroneInfoViewControllerNavigation: AnyObject {
    /// Called when drone informations screen should be opened.
    func openDroneInfos()
}

/// View controller for top bar drone info.
final class HUDDroneInfoViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var droneBatteryImageView: UIImageView! {
        didSet {
            // Workaround for tint color issues.
            droneBatteryImageView.tintColorDidChange()
        }
    }
    @IBOutlet private weak var droneBatteryLabel: UILabel!
    @IBOutlet private weak var droneCellularImageView: UIImageView!
    @IBOutlet private weak var droneWifiImageView: UIImageView!
    @IBOutlet private weak var droneGpsImageView: UIImageView!
    @IBOutlet private weak var batteryAlertBackgroundView: UIView! {
        didSet {
            batteryAlertBackgroundView.applyCornerRadius(Style.mediumCornerRadius)
        }
    }
    @IBOutlet private weak var wifiAlertBackgroundView: UIView!
    @IBOutlet private weak var cellularBackgroundView: UIView!

    // MARK: - Internal Properties
    weak var navigationDelegate: HUDDroneInfoViewControllerNavigation?

    // MARK: - Private Properties
    private let droneInfosViewModel = DroneInfosViewModel()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        setupViewModel()
    }
}

// MARK: - Actions
private extension HUDDroneInfoViewController {
    /// Called when user taps the main view.
    @IBAction func droneInfoTouchedUpInside() {
        LogEvent.logAppEvent(itemName: LogEvent.LogKeyHUDTopBarButton.droneDetails, logType: .simpleButton)
        navigationDelegate?.openDroneInfos()
    }
}

// MARK: - Private Funcs
private extension HUDDroneInfoViewController {

    /// Sets up view model and initial state.
    func setupViewModel() {
        bindToViewModel()
    }

    /// Binds the view to the view model
    ///
    /// The UI is updated automaticaly when a new value is published by the drone and received in the view model
    func bindToViewModel() {
        // Binding battery level
        droneInfosViewModel.$batteryLevel
            .sink { [unowned self] batteryLevel in
                if let batteryValue = batteryLevel.currentValue {
                    droneBatteryLabel.attributedText = NSMutableAttributedString(withBatteryLevel: batteryValue)
                } else {
                    droneBatteryLabel.text = Style.dash
                }
            }
            .store(in: &cancellables)

        // Binding wifi strength
        droneInfosViewModel.$wifiStrength
            .removeDuplicates()
            .sink { [unowned self] wifiStrength in
                configureWifiView(wifiStrength: wifiStrength ?? .offline)
            }
            .store(in: &cancellables)

        // Binding gps strength
        droneInfosViewModel.$gpsStrength
            .sink { [unowned self] gpsStrength in
                droneGpsImageView.image = gpsStrength.image
            }
            .store(in: &cancellables)

        // Binding cellular strength
        droneInfosViewModel.$cellularStrength
            .removeDuplicates()
            .sink { [unowned self] cellularStrength in
                configureCellularView(cellularStrength: cellularStrength)
            }
            .store(in: &cancellables)

        droneInfosViewModel.$currentLink
            .sink { [unowned self] _ in
                configureWifiView(wifiStrength: droneInfosViewModel.wifiStrength ?? .offline)
                configureCellularView(cellularStrength: droneInfosViewModel.cellularStrength)
            }
            .store(in: &cancellables)
    }
}

private extension HUDDroneInfoViewController {

    /// Sets the color and image for the wifi icon.
    ///
    /// - Parameter wifiStrength: the wifi signal received from the drone
    func configureWifiView(wifiStrength: WifiStrength) {
        let currenLink = droneInfosViewModel.currentLink
        droneWifiImageView.image = wifiStrength.signalIcon(isLinkActive: currenLink == .wlan)
        wifiAlertBackgroundView.isHidden = !(currenLink == .wlan) || wifiStrength == .none
        if currenLink == .wlan {
            wifiAlertBackgroundView.cornerRadiusedWith(backgroundColor: wifiStrength.backgroundColor.color,
                                                       borderColor: wifiStrength.borderColor.color,
                                                       radius: Style.smallCornerRadius,
                                                       borderWidth: Style.mediumBorderWidth)
        }
    }

    /// Sets the color and image for the cellular icon.
    ///
    /// - Parameter cellularStrength: the cellular signal received from the drone
    func configureCellularView(cellularStrength: CellularStrength) {
        let currentLink = droneInfosViewModel.currentLink
        droneCellularImageView.image = cellularStrength.signalIcon(isLinkActive: currentLink == .cellular)
        cellularBackgroundView.isHidden = !(currentLink == .cellular) || cellularStrength == .none
        if currentLink == .cellular {
            cellularBackgroundView.cornerRadiusedWith(backgroundColor: cellularStrength.backgroundColor.color,
                                                      borderColor: cellularStrength.borderColor.color,
                                                      radius: Style.smallCornerRadius,
                                                      borderWidth: Style.mediumBorderWidth)
        }
    }
}
