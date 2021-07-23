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

/// Screen which launchs device update screen.
final class DeviceConfirmUpdateViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var continueButton: UIButton!
    @IBOutlet private weak var laterButton: UIButton!
    @IBOutlet private weak var backButton: UIButton!
    @IBOutlet private weak var deviceImageView: UIImageView!

    // MARK: - Private Properties
    private weak var coordinator: UpdateCoordinator?
    private var model: DeviceUpdateModel = .remote
    private var viewModel: DeviceConfirmUpdateViewModel?

    // MARK: - Setup
    static func instantiate(coordinator: UpdateCoordinator, model: DeviceUpdateModel) -> DeviceConfirmUpdateViewController {
        let viewController = StoryboardScene.DeviceUpdate.deviceConfirmUpdate.instantiate()
        viewController.model = model
        viewController.coordinator = coordinator
        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        viewModel = DeviceConfirmUpdateViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.confirmUpdate, logType: .screen)
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
private extension DeviceConfirmUpdateViewController {
    @IBAction func backButtonTouchedUpInside(_ sender: Any) {
        coordinator?.dismissDeviceUpdate()
    }

    @IBAction func continueButtonTouchedUpInside(_ sender: Any) {
        if let viewModel = viewModel,
            viewModel.canUpdate(model: model) == true {
            coordinator?.startUpdate(deviceUpdateType: viewModel.getUpdateType(model: model))
        } else {
            // Error case.
            showAlert()
        }
    }

    @IBAction func laterButtonTouchedUpInside(_ sender: Any) {
        coordinator?.dismissDeviceUpdate()
    }
}

// MARK: - Private Funcs
private extension DeviceConfirmUpdateViewController {
    /// Init the view.
    func initView() {
        laterButton.setTitle(L10n.commonLater, for: .normal)
        continueButton.setTitle(L10n.commonContinue, for: .normal)
        backButton.setTitle(L10n.cancel, for: .normal)
        deviceImageView.image = model.image
        titleLabel.text = model.title
        descriptionLabel.text = model.description
    }

    /// Presents an alert when there is an unavailability reason for the current model.
    func showAlert() {
        switch model {
        case .remote:
            if let reason = viewModel?.unavailabilityRemoteReason {
                self.showAlert(title: reason.title,
                               message: reason.message)
            }
        case .drone:
            if let reason = viewModel?.unavailabilityDroneReason {
                self.showAlert(title: reason.title,
                               message: reason.message)
            }
        }
    }
}
