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
import Combine

/// Shows information about drone cellular access.
final class DroneDetailsCellularViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var mainView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var actionButton: UIButton!
    @IBOutlet private weak var connectionSubtitleLabel: UILabel!
    @IBOutlet private weak var reinitializeButton: UIButton!
    @IBOutlet private weak var connectionStateLabel: UILabel!
    @IBOutlet private weak var connectionStateDescriptionLabel: UILabel!
    @IBOutlet private weak var accessSubtitleLabel: UILabel!
    @IBOutlet private weak var usersCountLabel: UILabel!
    @IBOutlet private weak var usersCountDescriptionLabel: UILabel!
    @IBOutlet private weak var forgotErrorLabel: UILabel!
    @IBOutlet private weak var showDebugButton: UIButton!

    // MARK: - Private Properties
    private weak var coordinator: DroneCoordinator?
    private let viewModel = DroneDetailsCellularViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var currentDrone = Services.hub.currentDroneHolder

    // MARK: - Setup
    static func instantiate(coordinator: DroneCoordinator) -> DroneDetailsCellularViewController {
        let viewController = StoryboardScene.DroneDetailsCellular.initialScene.instantiate()
        viewController.coordinator = coordinator
        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
        bindToViewModel()
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
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension DroneDetailsCellularViewController {
    @IBAction func closeButtonTouchedUpInside(_ sender: Any) {
        closeView()
    }

    @IBAction func backgroundViewTouchedUpInside(_ sender: Any) {
        closeView()
    }

    @IBAction func actionButtonTouchedUpInside(_ sender: Any) {
        switch viewModel.cellularStatus {
        case .simLocked:
            logEvent(with: LogEvent.LogKeyDroneDetailsCellular.enterPinCode)
            self.view.backgroundColor = .clear
            coordinator?.dismiss {
                self.coordinator?.displayCellularPinCode()
            }
        case .userNotPaired:
            logEvent(with: LogEvent.LogKeyDroneDetailsCellular.pairDevice)
            coordinator?.pairUser()

        case .noData:
            self.view.backgroundColor = .clear
            coordinator?.dismiss {
                self.viewModel.activateLTE()
                if self.viewModel.shouldDisplayPinCodeModal() {
                    self.coordinator?.displayCellularPinCode()
                }
            }
        default:
            break
        }
    }

    @IBAction func reinitializeButtonTouchedUpInside(_ sender: Any) {
        logEvent(with: LogEvent.LogKeyDroneDetailsCellular.reinitialize)
        viewModel.unpairAllUsers()
    }

    @IBAction func showDebugButtonTouchedUpInside(_ sender: Any) {
        coordinator?.dismiss {
            self.coordinator?.displayCellularDebug()
        }
    }
}

// MARK: - Private Funcs
private extension DroneDetailsCellularViewController {
    /// Inits the view.
    func initView() {
        mainView.applyCornerRadius(Style.largeCornerRadius,
                                   maskedCorners: [.layerMinXMinYCorner,
                                                   .layerMaxXMinYCorner])
        // Labels.
        titleLabel.text = L10n.droneDetailsCellularAccess
        forgotErrorLabel.makeUp(and: ColorName.redTorch)
        connectionSubtitleLabel.text = L10n.commonConnectionState
        accessSubtitleLabel.text = L10n.cellularInfoAccess
        usersCountDescriptionLabel.text = L10n.drone4gUserAccessSingular(0)

        // Buttons.
        actionButton.titleLabel?.textAlignment = .center
        actionButton.cornerRadiusedWith(backgroundColor: UIColor(named: .whiteAlbescent),
                                        radius: Style.largeCornerRadius)

        reinitializeButton.setTitle(L10n.drone4gReinitializeConnections, for: .normal)
        reinitializeButton.setTitleColor(ColorName.defaultTextColor.color, for: .normal)
        reinitializeButton.setTitleColor(ColorName.disabledTextColor.color, for: .disabled)
        reinitializeButton.titleLabel?.textAlignment = .center
        reinitializeButton.cornerRadiusedWith(backgroundColor: UIColor(named: .whiteAlbescent),
                                              radius: Style.largeCornerRadius)

        showDebugButton.setTitle(L10n.drone4gShowDebug, for: .normal)
        showDebugButton.titleLabel?.textAlignment = .center
        showDebugButton.cornerRadiusedWith(backgroundColor: .clear,
                                           borderColor: .black,
                                           radius: Style.largeCornerRadius,
                                           borderWidth: Style.mediumBorderWidth)
    }

    /// Calls the different function to bind the view model.
    func bindToViewModel() {
        viewModel.updatesPairedUsersCount()
        updateView()
    }

    /// Closes the view.
    func closeView() {
        self.view.backgroundColor = .clear
        coordinator?.dismiss()
    }

    /// Binds the view model to the views.
    func updateView() {
        viewModel.$unpairState
            .sink { [unowned self] unpairState in
                if unpairState.shouldShowError {
                    forgotErrorLabel.isHidden = false
                    forgotErrorLabel.text = unpairState.title
                } else {
                    forgotErrorLabel.isHidden = true
                }
            }
            .store(in: &cancellables)

        viewModel.$cellularStatus
            .sink { [unowned self] cellularStatus in
                bindCellularStatus(cellularStatus: cellularStatus)
            }
            .store(in: &cancellables)

        viewModel.$usersCount
            .sink { [unowned self] usersCount in
                if usersCount > 1 {
                    usersCountDescriptionLabel.text = L10n.drone4gUserAccessPlural(usersCount)
                } else {
                    usersCountDescriptionLabel.text = L10n.drone4gUserAccessSingular(usersCount)
                }
                usersCountLabel.text = "\(usersCount)"
            }
            .store(in: &cancellables)
    }

    /// Binds the cellular status to the controller views.
    ///
    /// - Parameter cellularStatus: The current cellular status.
    func bindCellularStatus(cellularStatus: DetailsCellularStatus) {
        actionButton.isHidden = !cellularStatus.shouldShowActionButton
        reinitializeButton.isEnabled = cellularStatus == .cellularConnected
        connectionStateLabel.text = cellularStatus.cellularDetailsTitle
        connectionStateLabel.textColor = cellularStatus.detailsTextColor.color

        if cellularStatus.isStatusError {
            connectionStateDescriptionLabel.text = cellularStatus.cellularDetailsDescription
            usersCountDescriptionLabel.text = Style.dash
        } else {
            connectionStateDescriptionLabel.text = viewModel.operatorName
        }

        actionButton.setTitle(cellularStatus.actionButtonTitle, for: .normal)
    }

    /// Calls log event.
    ///
    /// - Parameters:
    ///     - itemName: Button name
    func logEvent(with itemName: String) {
        LogEvent.logAppEvent(itemName: itemName,
                             newValue: nil,
                             logType: .button)
    }
}
