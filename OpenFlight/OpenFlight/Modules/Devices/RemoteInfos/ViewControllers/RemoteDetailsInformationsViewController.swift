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

/// Remote details screen which displays informations like serial or hardware version.
final class RemoteDetailsInformationsViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var serialNumberView: DeviceInformationsView!
    @IBOutlet private weak var hardwareVersionView: DeviceInformationsView!
    @IBOutlet private weak var firmwareVersionView: DeviceInformationsView!
    @IBOutlet private weak var resetButton: ActionButton!

    // MARK: - Private Properties
    private var viewModel: RemoteDetailsInformationsViewModel!
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Setup
    /// Instantiate the view controller.
    ///
    /// - Parameters:
    ///     - coordinator: the coordinator
    ///     - viewModel: the view model
    /// - Returns: the newly created controller.
    static func instantiate(viewModel: RemoteDetailsInformationsViewModel) -> RemoteDetailsInformationsViewController {
        let viewController = StoryboardScene.RemoteDetailsInformations.initialScene.instantiate()
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
}

// MARK: - Actions
private extension RemoteDetailsInformationsViewController {
    @IBAction func resetButtonTouchedUpInside(_ sender: Any) {
        let validateAction = AlertAction(title: L10n.remoteDetailsReset, actionHandler: { [weak self] in
            self?.viewModel.resetRemote()
            LogEvent.log(.simpleButton(LogEvent.LogKeyRemoteInfosButton.remoteReset.name))
        })

        self.showAlert(title: L10n.remoteDetailsResetTitle,
                       message: L10n.remoteDetailsResetDescription,
                       validateAction: validateAction)
    }
}

// MARK: - Private Funcs
private extension RemoteDetailsInformationsViewController {
    /// Sets up the view.
    func setupView() {
        resetButton.cornerRadiusedWith(backgroundColor: ColorName.whiteAlbescent.color,
                                       borderColor: .clear,
                                       radius: Style.largeCornerRadius,
                                       borderWidth: Style.noBorderWidth)
    }

    func setupViewModel() {
        viewModel.resetButtonEnabled
            .sink { [weak self] isEnabled in
                guard let self = self else { return }
                self.resetButton.isEnabled = isEnabled
                let resetColor: ColorName = isEnabled ? ColorName.defaultTextColor : ColorName.disabledTextColor
                self.resetButton.setup(title: L10n.commonReset, style: .default2)
                self.resetButton.makeup(with: .large, color: resetColor)
            }
            .store(in: &cancellables)

        viewModel.$serialNumber
            .removeDuplicates()
            .sink { [weak self] serialNumber in
                guard let self = self else { return }
                self.serialNumberView.model = DeviceInformationsModel(title: L10n.commonProductReference, description: serialNumber)
            }
            .store(in: &cancellables)

        viewModel.$firmwareVersion
            .removeDuplicates()
            .sink { [weak self] firmwareVersion in
                guard let self = self else { return }
                self.firmwareVersionView.model = DeviceInformationsModel(title: L10n.remoteDetailsFirmwareVersion, description: firmwareVersion)
            }
            .store(in: &cancellables)

        viewModel.$hardwareVersion
            .removeDuplicates()
            .sink { [weak self] hardwareVersion in
                guard let self = self else { return }
                self.hardwareVersionView.model = DeviceInformationsModel(title: L10n.droneDetailsHardwareVersion, description: hardwareVersion)
            }
            .store(in: &cancellables)
    }
}
