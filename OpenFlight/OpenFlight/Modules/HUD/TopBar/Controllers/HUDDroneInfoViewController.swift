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
    @IBOutlet private weak var cellularBackgroundView: UIView!

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
        LogEvent.logAppEvent(itemName: LogEvent.LogKeyHUDTopBarButton.droneDetails, logType: .simpleButton)
        navigationDelegate?.openDroneInfos()
    }
}

// MARK: - Private Funcs
private extension HUDDroneInfoViewController {
    /// Sets up view model and initial state.
    func setupViewModel() {
        droneInfosViewModel = DroneInfosViewModel(batteryLevelDidChange: { [weak self] batteryLevel in
            self?.onBatteryLevelChanged(batteryLevel)
        }, wifiStrengthDidChange: { [weak self] _ in
            self?.updateNetworkIcons()
        }, gpsStrengthDidChange: { [weak self] gpsStrength in
            self?.onGpsStrengthChanged(gpsStrength)
        }, cellularStrengthDidChange: { [weak self] _ in
            self?.updateNetworkIcons()
        }, currentLinkDidChange: { [weak self] _ in
            self?.updateNetworkIcons()
        })

        if let state = droneInfosViewModel?.state.value {
            onGpsStrengthChanged(state.gpsStrength.value)
        }
        updateNetworkIcons()
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
    ///
    /// - Parameters:
    ///     - wifiStrength: wifi strength
    ///     - isWlanActive: tells if wlan is the active link
    func onWifiStrengthChanged(_ wifiStrength: WifiStrength, isWlanActive: Bool = true) {
        droneWifiImageView.image = wifiStrength.signalIcon(isLinkActive: isWlanActive)
        wifiAlertBackgroundView.isHidden = !isWlanActive || wifiStrength == .none
        if isWlanActive {
            wifiAlertBackgroundView.cornerRadiusedWith(backgroundColor: wifiStrength.backgroundColor.color,
                                                       borderColor: wifiStrength.borderColor.color,
                                                       radius: Style.smallCornerRadius,
                                                       borderWidth: Style.mediumBorderWidth)
        }
    }

    /// Called when gps signal strength changes.
    func onGpsStrengthChanged(_ gpsStrength: GpsStrength) {
        droneGpsImageView.image = gpsStrength.image
    }

    /// Called when 4G signal changes.
    ///
    /// - Parameters:
    ///     - cellularStrength: cellular strength
    ///     - isCellularActive: tells if cellular is the active link
    func onCellularStrengthChanged(_ cellularStrength: CellularStrength,
                                   isCellularActive: Bool = false) {
        droneCellularImageView.image = cellularStrength.signalIcon(isLinkActive: isCellularActive)
        cellularBackgroundView.isHidden = !isCellularActive || cellularStrength == .none
        if isCellularActive {
            cellularBackgroundView.cornerRadiusedWith(backgroundColor: cellularStrength.backgroundColor.color,
                                                      borderColor: cellularStrength.borderColor.color,
                                                      radius: Style.smallCornerRadius,
                                                      borderWidth: Style.mediumBorderWidth)
        }
    }

    /// Update network icons when link did change.
    func updateNetworkIcons() {
        if let state = droneInfosViewModel?.state.value {
            onCellularStrengthChanged(state.cellularStrength.value,
                                      isCellularActive: state.currentLink.value == .cellular)
            onWifiStrengthChanged(state.wifiStrength.value,
                                  isWlanActive: state.currentLink.value == .wlan)
        }
    }
}
