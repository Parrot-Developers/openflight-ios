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
protocol HUDControllerInfoViewControllerNavigation: AnyObject {
    /// Called when remote control informations screen should be opened.
    func openRemoteControlInfos()
}

/// View controller for top bar controller info (either phone or remote control).
final class HUDControllerInfoViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var controllerImageView: UIImageView! {
        didSet {
            // Workaround for tint color issues.
            controllerImageView.tintColorDidChange()
        }
    }
    @IBOutlet private weak var gpsImageView: UIImageView!
    @IBOutlet private weak var batteryLevelLabel: UILabel!
    @IBOutlet private weak var batteryAlertBackgroundView: UIView! {
        didSet {
            batteryAlertBackgroundView.applyCornerRadius(Style.mediumCornerRadius)
        }
    }

    // MARK: - Internal Properties
    weak var navigationDelegate: HUDControllerInfoViewControllerNavigation?

    // MARK: - Private Properties
    private let viewModel = ControllerInfosViewModel()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        bindToViewModel()
        setupLayout()
    }

    private func setupLayout() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            // Image of device
            controllerImageView.contentMode = .scaleAspectFit

            // Battery Label
            batteryLevelLabel.font = ParrotFontStyle.huge.font

            // Image of GPS
            gpsImageView.contentMode = .scaleAspectFit
        }
    }
}

// MARK: - Actions
private extension HUDControllerInfoViewController {
    /// Called when user taps the view.
    @IBAction func controllerInfoTouchedUpInside(_ sender: Any) {
        LogEvent.logAppEvent(itemName: LogEvent.LogKeyHUDTopBarButton.remoteControlDetails,
                             logType: .simpleButton)
        navigationDelegate?.openRemoteControlInfos()
    }
}

// MARK: - Private Funcs
private extension HUDControllerInfoViewController {

    func bindToViewModel() {
        viewModel.$batteryLevel
            .sink { [unowned self] batteryLevel in
                if let level = batteryLevel.currentValue {
                    batteryLevelLabel.attributedText = NSMutableAttributedString(withBatteryLevel: level)
                } else {
                    batteryLevelLabel.text = Style.dash
                }

                batteryAlertBackgroundView.backgroundColor = batteryLevel.alertLevel.color
            }
            .store(in: &cancellables)

        viewModel.$currentController
            .sink { [unowned self] controller in
                self.view.isUserInteractionEnabled = controller == .remoteControl
                controllerImageView.image = controller.batteryImage
            }
            .store(in: &cancellables)

        viewModel.$gpsStrength
            .sink { [unowned self] gpsStrength in
                gpsImageView.image = gpsStrength.image
            }
            .store(in: &cancellables)
    }
}
