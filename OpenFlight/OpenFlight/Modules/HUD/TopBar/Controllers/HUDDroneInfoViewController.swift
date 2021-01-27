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

// MARK: - Protocols
protocol HUDDroneInfoViewControllerNavigation: class {
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

    // MARK: - Internal Properties
    weak var navigationDelegate: HUDDroneInfoViewControllerNavigation?

    // MARK: - Private Properties
    private var droneInfosViewModel: DroneInfosViewModel<DroneInfosState>?

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
        navigationDelegate?.openDroneInfos()
    }
}

// MARK: - Private Funcs
private extension HUDDroneInfoViewController {
    /// Sets up view model and initial state.
    func setupViewModel() {
        droneInfosViewModel = DroneInfosViewModel(batteryLevelDidChange: { [weak self] batteryLevel in
            self?.onBatteryLevelChanged(batteryLevel)
            }, wifiStrengthDidChange: { [weak self] wifiStrength in
                self?.onWifiStrengthChanged(wifiStrength)
            }, gpsStrengthDidChange: { [weak self] gpsStrength in
                self?.onGpsStrengthChanged(gpsStrength)
            }, cellularStateDidChange: { [weak self] cellularIcon in
                self?.cellularIconChanged(cellularIcon)
            }, isCellularAvailabilityChange: { [weak self] isAvailable in
                self?.updateCellularIconVisibility(isAvailable)
            }
        )
        if let state = droneInfosViewModel?.state.value {
            onWifiStrengthChanged(state.wifiStrength.value)
            onGpsStrengthChanged(state.gpsStrength.value)
            cellularIconChanged(state.cellularNetworkIcon.value)
            updateCellularIconVisibility(state.isCellularAvailable.value)
        }
    }

    /// Called when current battery level changes.
    func onBatteryLevelChanged(_ batteryLevel: BatteryValueModel) {
        if let value = batteryLevel.currentValue {
            droneBatteryLabel.attributedText = NSMutableAttributedString(withBatteryLevel: value)
        } else {
            droneBatteryLabel.text = Style.dash
        }
        batteryAlertBackgroundView.backgroundColor = batteryLevel.alertLevel.color
    }

    /// Called when wifi signal strength changes.
    func onWifiStrengthChanged(_ wifiStrength: WifiStrength) {
        droneWifiImageView.image = wifiStrength.image
        let backgroundAlertColor = wifiStrength.alertLevel == .warning
            ? ColorName.orangePeel50.color
            : wifiStrength.alertLevel.color
        wifiAlertBackgroundView.cornerRadiusedWith(backgroundColor: backgroundAlertColor,
                                                   borderColor: wifiStrength.alertLevel.color,
                                                   radius: Style.smallCornerRadius,
                                                   borderWidth: Style.mediumBorderWidth)
        wifiAlertBackgroundView.isHidden = !wifiStrength.alertLevel.isWarningOrCritical
    }

    /// Called when gps signal strength changes.
    func onGpsStrengthChanged(_ gpsStrength: GpsStrength) {
        droneGpsImageView.image = gpsStrength.image
    }

    /// Called when cellular access icon changes.
    ///
    /// - Parameters:
    ///     - icon: current drone network image
    func cellularIconChanged(_ icon: UIImage?) {
        droneCellularImageView.image = icon
    }

    /// Called when cellular availability changes.
    ///
    /// - Parameters:
    ///     - isCellularAvailable: Verifies if 4G network available on the current drone
    func updateCellularIconVisibility(_ isCellularAvailable: Bool) {
        droneCellularImageView.isHidden = !isCellularAvailable
    }
}
