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

/// Displays a view with informations about the drone (system, imei etc).
final class DroneDetailsInformationsViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var serialContainerView: DeviceInformationsView!
    @IBOutlet private weak var hardwareVersionContainerView: DeviceInformationsView!
    @IBOutlet private weak var firmwareVersionContainerView: DeviceInformationsView!
    @IBOutlet private weak var imeiContainerView: DeviceInformationsView!
    @IBOutlet private weak var resetButton: ActionButton!

    // MARK: - Private Properties
    private weak var coordinator: Coordinator?
    private var viewModel = DroneDetailsInformationsViewModel()

    // MARK: - Setup
    static func instantiate(coordinator: Coordinator) -> DroneDetailsInformationsViewController {
        let viewController = StoryboardScene.DroneDetailsInformations.initialScene.instantiate()
        viewController.coordinator = coordinator

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
        resetButton.setup(title: L10n.commonReset, style: .default2)
    }

    /// Sets up view model.
    func setupViewModel() {
        viewModel.state.valueChanged = { [weak self] state in
            self?.updateView(state)
        }
        updateView(viewModel.state.value)
    }

    /// Updates the view with given state.
    ///
    /// - Parameters:
    ///    - state: current state
    func updateView(_ state: DroneDetailsInformationsState) {
        resetButton.isEnabled = state.isConnected()
        let resetColor: ColorName = state.isConnected() ? ColorName.defaultTextColor : ColorName.disabledTextColor

        resetButton.makeup(with: .large, color: resetColor)
        resetButton.cornerRadiusedWith(backgroundColor: ColorName.whiteAlbescent.color,
                                       borderColor: .clear,
                                       radius: Style.largeCornerRadius,
                                       borderWidth: Style.noBorderWidth)

        serialContainerView.model = DeviceInformationsModel(title: L10n.remoteDetailsSerialNumber,
                                                            description: state.serialNumber)
        hardwareVersionContainerView.model = DeviceInformationsModel(title: L10n.droneDetailsHardwareVersion,
                                                                     description: state.hardwareVersion)
        firmwareVersionContainerView.model = DeviceInformationsModel(title: L10n.droneDetailsFirmwareCharles,
                                                                     description: state.firmwareVersion)
        imeiContainerView.model = DeviceInformationsModel(title: L10n.droneDetailsImei,
                                                          description: state.imei)
    }
}
