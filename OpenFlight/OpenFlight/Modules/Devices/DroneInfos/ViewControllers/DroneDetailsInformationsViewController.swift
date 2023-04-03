//    Copyright (C) 2020 Parrot Drones SAS
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

/// Displays a view with informations about the drone (system, imei etc).
final class DroneDetailsInformationsViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var serialContainerView: DeviceInformationsView!
    @IBOutlet private weak var hardwareVersionContainerView: DeviceInformationsView!
    @IBOutlet private weak var firmwareVersionContainerView: DeviceInformationsView!
    @IBOutlet private weak var imeiContainerView: DeviceInformationsView!
    @IBOutlet private weak var resetButton: ActionButton!

    // MARK: - Private Properties
    private var viewModel: DroneDetailsInformationsViewModel!
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Setup
    static func instantiate(viewModel: DroneDetailsInformationsViewModel) -> DroneDetailsInformationsViewController {
        let viewController = StoryboardScene.DroneDetailsInformations.initialScene.instantiate()
        viewController.viewModel = viewModel
        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        setupViewModel()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        resetButton.isHidden = !UIApplication.isLandscape
    }
}

// MARK: - Actions
private extension DroneDetailsInformationsViewController {
    @IBAction func resetButtonTouchedUpInside(_ sender: Any) {
        let validateAction = AlertAction(title: L10n.remoteDetailsReset, actionHandler: { [weak self] in
            self?.viewModel.resetDrone()
            LogEvent.log(.simpleButton(LogEvent.LogKeyDroneDetailsInformationsButton.resetDroneInformations))
        })

        self.showAlert(title: L10n.droneDetailsResetTitle,
                       message: L10n.droneDetailsResetDescription,
                       validateAction: validateAction)
    }
}

// MARK: - Private Funcs
private extension DroneDetailsInformationsViewController {
    /// Sets up the view.
    func setupView() {
        resetButton.cornerRadiusedWith(backgroundColor: ColorName.whiteAlbescent.color,
                                       borderColor: .clear,
                                       radius: Style.largeCornerRadius,
                                       borderWidth: Style.noBorderWidth)
    }

    /// Sets up view model.
    func setupViewModel() {
        viewModel.resetButtonEnabled
            .removeDuplicates()
            .sink { [weak self] isEnabled in
                guard let self = self else { return }
                self.resetButton.isEnabled = isEnabled
                let resetColor: ColorName = isEnabled ? ColorName.defaultTextColor : ColorName.disabledTextColor
                self.resetButton.setup(title: L10n.commonReset, style: .default2)
                self.resetButton.makeup(with: .large, color: resetColor)
            }
            .store(in: &cancellables)

        viewModel.$firmwareVersion
            .removeDuplicates()
            .sink { [weak self] firmwareVersion in
                guard let self = self else { return }
                self.firmwareVersionContainerView.model = DeviceInformationsModel(title: L10n.droneDetailsFirmwareCharles,
                                                                                  description: firmwareVersion)
            }
            .store(in: &cancellables)

        viewModel.$hardwareVersion
            .removeDuplicates()
            .sink { [weak self] hardwareVersion in
                guard let self = self else { return }
                self.hardwareVersionContainerView.model = DeviceInformationsModel(title: L10n.droneDetailsHardwareVersion,
                                                                                  description: hardwareVersion)
            }
            .store(in: &cancellables)

        viewModel.$serialNumber
            .removeDuplicates()
            .sink { [weak self] serialNumber in
                guard let self = self else { return }
                self.serialContainerView.model = DeviceInformationsModel(title: L10n.commonProductReference,
                                                                         description: serialNumber)
            }
            .store(in: &cancellables)

        viewModel.$imei
            .removeDuplicates()
            .sink { [weak self] imei in
                guard let self = self else { return }
                self.imeiContainerView.model = DeviceInformationsModel(title: L10n.droneDetailsImei,
                                                                       description: imei)
            }
            .store(in: &cancellables)
    }
}
