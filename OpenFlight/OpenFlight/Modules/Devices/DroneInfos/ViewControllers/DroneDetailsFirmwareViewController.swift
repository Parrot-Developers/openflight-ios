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

// MARK: - Internal Enums
/// Describes type drone version screen.
enum DroneDetailsUpdateType {
    /// Screen which displays only version number.
    case upToDate
    /// Screen which displays only information about  an available update.
    case needUpdate

    /// Title.
    var title: String {
        switch self {
        case .upToDate:
            return L10n.deviceDetailsSoftwareVersion
        case .needUpdate:
            return L10n.droneUpdateControllerUpdate
        }
    }

    /// Description.
    var description: String {
        switch self {
        case .upToDate:
            return L10n.remoteDetailsUpToDate
        case .needUpdate:
            return L10n.droneUpdateConfirmDescription
        }
    }
}

// FIXME: never used anymore with Missions and Firmware refactor.
// It needs to be added after cliking on firmware cell in the update list.
/// Displays infos about the version or a transition screen for update.
final class DroneDetailsFirmwareViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var mainView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var upToDateView: UIView!
    @IBOutlet private weak var updateView: UIView!
    @IBOutlet private weak var softwareVersionLabel: UILabel!
    @IBOutlet private weak var upToDateLabel: UILabel!
    @IBOutlet private weak var updateDescriptionLabel: UILabel!
    @IBOutlet private weak var cancelButton: UIButton!
    @IBOutlet private weak var updateButton: UIButton!
    @IBOutlet private weak var errorLabel: UILabel!

    // MARK: - Private Properties
    private weak var coordinator: DroneCoordinator?
    private let viewModel = DeviceConfirmUpdateViewModel()
    /// Current version.
    private var versionNumber: String?
    /// Target firmware version needed.
    private var versionNeeded: String?
    /// Current drone details update model.
    private var model: DroneDetailsUpdateType = .upToDate

    // MARK: - Setup
    /// Instantiates the view controller.
    ///
    /// - Parameters:
    ///     - coordinator: drone details coordinator
    ///     - versionNumber: current version number if drone is up to date
    ///     - versionNeeded: drone version number needed to update
    ///     - model: current drone details update model.
    /// - Returns: The drone details update view controller
    static func instantiate(coordinator: DroneCoordinator,
                            versionNumber: String? = nil,
                            versionNeeded: String? = nil,
                            model: DroneDetailsUpdateType) -> DroneDetailsFirmwareViewController {
        let viewController = StoryboardScene.DroneDetailsFirmware.initialScene.instantiate()
        viewController.coordinator = coordinator
        viewController.versionNumber = versionNumber
        viewController.versionNeeded = versionNeeded
        viewController.model = model

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        initViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.confirmUpdate,
                             logType: .screen)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        UIView.animate(withDuration: Style.shortAnimationDuration) {
            self.view.backgroundColor = ColorName.greyDark60.color
        }
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
private extension DroneDetailsFirmwareViewController {
    @IBAction func closeButtonTouchedUpInside(_ sender: Any) {
        LogEvent.logAppEvent(itemName: LogEvent.LogKeyCommonButton.close, logType: .simpleButton)
        closeView()
    }

    @IBAction func backgroundButtonTouchedUpInside(_ sender: Any) {
        LogEvent.logAppEvent(itemName: LogEvent.LogKeyCommonButton.tapToDismiss, logType: .simpleButton)
        closeView()
    }

    @IBAction func cancelButtonTouchedUpInside(_ sender: Any) {
        logEvent(with: LogEvent.LogKeyCommonButton.cancel, and: self.versionNumber)
        closeView()
    }

    @IBAction func updateButtonTouchedUpInside(_ sender: Any) {
        logEvent(with: LogEvent.LogKeyDroneDetailsFirmwareUpdate.update, and: self.versionNeeded)
        guard viewModel.canUpdate(model: .drone) == true else {
            return
        }

        closeView()
        coordinator?.startUpdate(deviceUpdateType: viewModel.getUpdateType(model: .drone))
    }
}

// MARK: - Private Funcs
private extension DroneDetailsFirmwareViewController {
    /// Inits the view.
    func initView() {
        mainView.applyCornerRadius(Style.largeCornerRadius,
                                   maskedCorners: [.layerMinXMinYCorner,
                                                   .layerMaxXMinYCorner])
        titleLabel.makeUp(with: .huge)
        upToDateLabel.makeUp(with: .large, and: .greenSpring)
        updateDescriptionLabel.makeUp(with: .big)

        titleLabel.makeUp(with: .huge)
        updateView.isHidden = model == .upToDate
        upToDateView.isHidden = model == .needUpdate
        cancelButton.cornerRadiusedWith(backgroundColor: .clear,
                                        borderColor: .white,
                                        radius: Style.largeCornerRadius,
                                        borderWidth: Style.mediumBorderWidth)
        updateButton.cornerRadiusedWith(backgroundColor: ColorName.greenSpring20.color,
                                        radius: Style.largeCornerRadius)
        cancelButton.makeup(with: .regular, color: .white)
        updateButton.makeup(with: .regular, color: .greenSpring)
        cancelButton.setTitle(L10n.cancel, for: .normal)
        updateButton.setTitle(L10n.dashboardUpdate, for: .normal)
        softwareVersionLabel.text = versionNumber
        titleLabel.text = model.title
        upToDateLabel.text = model.description
        updateDescriptionLabel.text = model.description
        errorLabel.makeUp(with: .large, and: .redTorch)
    }

    /// Inits the view model.
    func initViewModel() {
        viewModel.state.valueChanged = { [weak self] _ in
            self?.updateErrorLabel()
        }
        updateErrorLabel()
    }

    /// Updates error level according to view model state.
    func updateErrorLabel() {
        errorLabel.text = viewModel.unavailabilityDroneReason?.title
        errorLabel.isHidden = viewModel.unavailabilityDroneReason == nil
    }

    /// Closes the view.
    func closeView() {
        self.view.backgroundColor = .clear
        coordinator?.dismiss()
    }

    /// Calls log event.
    ///
    /// - Parameters:
    ///     - itemName: button name
    ///     - newValue: changed value
    func logEvent(with itemName: String, and newValue: String?) {
        LogEvent.logAppEvent(itemName: itemName,
                             newValue: newValue,
                             logType: .button)
    }
}
