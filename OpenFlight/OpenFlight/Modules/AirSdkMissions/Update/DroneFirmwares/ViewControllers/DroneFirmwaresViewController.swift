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
import GroundSdk
import Combine

private extension ULogTag {
    static let tag = ULogTag(name: "FirmwareUpdateService")
}

/// The view controller that displays the firmware and the AirSdk missions to be updated.
final class DroneFirmwaresViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var popupLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var popupTrailingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var contentView: UIView!

    // MARK: - Private Properties
    private weak var coordinator: DroneFirmwaresCoordinator?
    private var viewModel: DroneFirmwaresViewModel!
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Private Enums
    enum Constants {
        static let tableViewHeight: CGFloat = 45
        static let cornerRadius: CGFloat = 18.0
    }

    // MARK: - Setup
    static func instantiate(
        coordinator: DroneFirmwaresCoordinator,
        viewModel: DroneFirmwaresViewModel) -> DroneFirmwaresViewController {
        let viewController = StoryboardScene.DroneFirmwares.initialScene.instantiate()
        viewController.coordinator = coordinator
        viewController.viewModel = viewModel
        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initUI()
        setupTableView()
        observeViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        UIView.animate(withDuration: Style.shortAnimationDuration,
                       delay: Style.shortAnimationDuration,
                       animations: {
            self.view.backgroundColor = ColorName.nightRider80.color
        })
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
}

// MARK: - UITableViewDataSource
extension DroneFirmwaresViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return viewModel.elements.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let element = viewModel.elements[indexPath.row]
        let cell = tableView.dequeueReusableCell(for: indexPath) as DroneFirmwaresTableViewCell
        cell.setup(with: element,
                   delegate: self,
                   numberOfFiles: viewModel.elements.count - 1,
                   droneIsConnected: viewModel.isDroneConnected)

        return cell
    }
}

// MARK: - UITableViewDelegate
extension DroneFirmwaresViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.tableViewHeight
    }
}

// MARK: - DroneFirmwaresTableViewCellDelegate
extension DroneFirmwaresViewController: DroneFirmwaresTableViewCellDelegate {
    /// Starts the update for the update choice.
    ///
    /// - Parameters:
    ///    - updateChoice: The current update choice
    func startUpdate(for updateChoice: FirmwareAndMissionUpdateChoice) {
        switch updateChoice {
        case .batteryGaugeUpdate:
            // For the battery gauge update, the requirements are handled in the checklist view.
            redirectToUpdatingViewController(updateChoice: updateChoice)
        default:
            let currentRequirement = viewModel.prepareUpdates(updateChoice: updateChoice)
            switch currentRequirement {
            case .readyForUpdate:
                redirectToUpdatingViewController(updateChoice: updateChoice)
            case .droneIsFlying,
                    .droneIsNotConnected,
                    .noInternetConnection,
                    .notEnoughBattery,
                    .notEnoughSpace,
                    .ongoingUpdate:
                presentRequirementAlert(for: currentRequirement,
                                        updateChoice: updateChoice)
            }
        }

    }
}

// MARK: - Actions
private extension DroneFirmwaresViewController {
    @IBAction func closeButtonTouchedUpInside(_ sender: Any) {
        closeView()
    }

    @IBAction func backgroundButtonTouchedUpInside(_ sender: Any) {
        closeView()
    }

    func closeView() {
        view.backgroundColor = .clear
        _ = viewModel.cancelAllUpdates(removeData: true)
        coordinator?.quitUpdateProcesses()
    }
}

// MARK: - Private Funcs
private extension DroneFirmwaresViewController {
    /// Inits the UI.
    func initUI() {
        popupLeadingConstraint.constant = Layout.popupHMargin(isRegularSizeClass)
        popupTrailingConstraint.constant = popupLeadingConstraint.constant
        titleLabel.text = L10n.firmwareMissionUpdateFirmwareVersionPlural
        contentView.customCornered(corners: [.topLeft, .topRight], radius: Constants.cornerRadius)
    }

    /// Sets up the table view.
    func setupTableView() {
        tableView.allowsSelection = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.register(cellType: DroneFirmwaresTableViewCell.self)
        tableView.reloadData()
    }

    /// Observes firmwares update view model.
    func observeViewModel() {
        viewModel.elementsPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
    }

    /// Redirects to the pertinent updating view controller.
    ///
    /// - Parameters:
    ///    - updateChoice: The current update choice
    func redirectToUpdatingViewController(updateChoice: FirmwareAndMissionUpdateChoice) {

        switch updateChoice {
        case .upToDateAirSdkMission:
            break
        case let .airSdkMission(_, missionOnDrone: _, compatibility: compatibility):
            switch compatibility {
            case .compatible:
                coordinator?.goToUpdatingViewController(functionalUpdateChoice: .airSdkMissions)
            case .tooOld:
                if viewModel.isFirmwareUpdateNeeded {
                    presentCompatibilityAlert()
                }
            case .tooRecent:
                // Should not happen
                break
            }
        case let .firmware(firmwareToUpdateData):
            if firmwareToUpdateData.allOperationsNeeded.isEmpty {
                break
            } else {
                coordinator?.goToUpdatingViewController(functionalUpdateChoice: .firmware)
            }
        case let .firmwareAndAirSdkMissions(firmware: firmwareToUpdateData, missions: missionsToUpdate):
            if missionsToUpdate.isEmpty && firmwareToUpdateData.allOperationsNeeded.isEmpty {
                break
            } else if !missionsToUpdate.isEmpty && firmwareToUpdateData.allOperationsNeeded.isEmpty {
                coordinator?.goToUpdatingViewController(functionalUpdateChoice: .airSdkMissions)
            } else if missionsToUpdate.isEmpty && !firmwareToUpdateData.allOperationsNeeded.isEmpty {
                coordinator?.goToUpdatingViewController(functionalUpdateChoice: .firmware)
            } else {
                coordinator?.goToUpdatingViewController(functionalUpdateChoice: .firmwareAndAirSdkMissions)
            }
        case .batteryGaugeUpdate:
            coordinator?.goToUpdatingViewController(functionalUpdateChoice: .batteryGauge)
        }
    }
}

// MARK: - Utils for Alert View management
private extension DroneFirmwaresViewController {
    /// Shows an alert view for a missing requirement.
    ///
    /// - Parameters:
    ///    - missingRequirement: The current missing requirement
    ///    - updateChoice: The current update choice
    func presentRequirementAlert(
        for missingRequirement: FirmwareAndMissionUpdateRequirements,
        updateChoice: FirmwareAndMissionUpdateChoice) {
        var validateAction: AlertAction?

        if let validateActionTitle = missingRequirement.validateActionTitle {
            validateAction = AlertAction(
                title: validateActionTitle,
                actionHandler: { self.validateActionHandler(for: missingRequirement,
                                                            updateChoice: updateChoice) })
        }

        let cancelAction = AlertAction(
            title: missingRequirement.cancelActionTitle,
            actionHandler: { self.cancelActionHandler(for: missingRequirement) })

        let alert = AlertViewController.instantiate(title: missingRequirement.title,
                                                    message: missingRequirement.message,
                                                    cancelAction: cancelAction,
                                                    validateAction: validateAction)

        present(alert, animated: true, completion: nil)
    }

    /// Alert View Validation action for a missing requirement.
    ///
    /// - Parameters:
    ///    - missingRequirement: The current missing requirement
    ///    - updateChoice: The current update choice
    func validateActionHandler(for missingRequirement: FirmwareAndMissionUpdateRequirements,
                               updateChoice: FirmwareAndMissionUpdateChoice) {
        switch missingRequirement {
        case .readyForUpdate,
             .droneIsFlying,
             .droneIsNotConnected,
             .notEnoughBattery,
             .ongoingUpdate:
            break
        case .noInternetConnection:
            startUpdate(for: updateChoice)
        case .notEnoughSpace:
            break
        // TODO: Erase internal memory
        }
    }

    /// Alert View Cancelation action for a missing requirement.
    ///
    /// - Parameters:
    ///    - missingRequirement: The current missing requirement
    ///    - updateChoice: The current update choice
    func cancelActionHandler(for missingRequirement: FirmwareAndMissionUpdateRequirements) {
        switch missingRequirement {
        case .noInternetConnection,
             .readyForUpdate,
             .droneIsFlying,
             .droneIsNotConnected,
             .notEnoughBattery:
            coordinator?.quitUpdateProcesses()
        case .notEnoughSpace,
             .ongoingUpdate:
            break
        }
    }

    /// Shows an alert view for a compatibility issue.
    func presentCompatibilityAlert() {
        let validateAction = AlertAction(
            title: L10n.firmwareMissionUpdateInstallAll,
            actionHandler: { [weak self] in
                // The first update choice is always firmware and missions update
                if self?.viewModel.elements.isEmpty == false,
                   let updateChoice = self?.viewModel.elements[0] {
                    self?.startUpdate(for: updateChoice)
                }
            })
        let cancelAction = AlertAction(title: L10n.cancel, actionHandler: nil)

        let alert = AlertViewController.instantiate(title: L10n.firmwareAndMissionUpdateFirmwareRequiredTitle,
                                                    message: L10n.firmwareAndMissionUpdateFirmwareRequiredMessage,
                                                    cancelAction: cancelAction,
                                                    validateAction: validateAction)

        present(alert, animated: true, completion: nil)
    }
}
