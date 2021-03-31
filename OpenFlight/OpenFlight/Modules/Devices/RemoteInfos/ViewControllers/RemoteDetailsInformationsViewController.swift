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

/// Remote details screen which displays informations like serial or hardware version.
final class RemoteDetailsInformationsViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var serialNumberView: DeviceInformationsView!
    @IBOutlet private weak var hardwareVersionView: DeviceInformationsView!
    @IBOutlet private weak var resetButton: UIButton!

    // MARK: - Private Properties
    private var viewModel: RemoteDetailsInformationsViewModel = RemoteDetailsInformationsViewModel()
    private weak var coordinator: RemoteCoordinator?

    // MARK: - Setup
    static func instantiate(coordinator: RemoteCoordinator) -> RemoteDetailsInformationsViewController {
        let viewController = StoryboardScene.RemoteDetailsInformations.initialScene.instantiate()
        viewController.coordinator = coordinator

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        initViewModel()
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

// MARK: - Actions
private extension RemoteDetailsInformationsViewController {
    @IBAction func resetButtonTouchedUpInside(_ sender: Any) {
        let validateAction = AlertAction(title: L10n.remoteDetailsReset, actionHandler: { [weak self] in
            self?.viewModel.resetRemote()
            LogEvent.logAppEvent(itemName: LogEvent.LogKeyRemoteInfosButton.remoteReset.name,
                                 newValue: nil,
                                 logType: .button)
        })

        self.showAlert(title: L10n.remoteDetailsResetTitle,
                       message: L10n.remoteDetailsResetDescription,
                       validateAction: validateAction)
    }
}

// MARK: - Private Funcs
private extension RemoteDetailsInformationsViewController {
    /// Inits the view.
    func initView() {
        resetButton.cornerRadiusedWith(backgroundColor: UIColor(named: .white20),
                                       radius: Style.largeCornerRadius)
        resetButton.setTitle(L10n.commonReset,
                             for: .normal)
    }

    /// Inits the remote information view model.
    func initViewModel() {
        viewModel.state.valueChanged = { [weak self] state in
            self?.updateView(state)
        }
        updateView(viewModel.state.value)
    }

    /// Updates the view with given state.
    ///
    /// - Parameters:
    ///    - state: current remote information state
    func updateView(_ state: RemoteDetailsInformationsState) {
        resetButton.isEnabled = state.isConnected()
        let resetColor: ColorName = state.isConnected() ? ColorName.white : ColorName.white20

        resetButton.makeup(with: .large, color: resetColor)
        resetButton.cornerRadiusedWith(backgroundColor: .clear,
                                       borderColor: resetColor.color,
                                       radius: Style.largeCornerRadius,
                                       borderWidth: Style.largeBorderWidth)

        serialNumberView.model = DeviceInformationsModel(title: L10n.remoteDetailsSerialNumber,
                                                         description: state.serialNumber)
        hardwareVersionView.model = DeviceInformationsModel(title: L10n.droneDetailsHardwareVersion,
                                                            description: state.hardwareVersion)
    }
}
