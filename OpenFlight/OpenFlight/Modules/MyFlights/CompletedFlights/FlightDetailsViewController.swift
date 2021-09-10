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

/// Flight details ViewController.

final class FlightDetailsViewController: UIViewController, FileShare {
    // MARK: - Outlets
    @IBOutlet private weak var backButton: UIButton!
    @IBOutlet private weak var flightLogLabel: UILabel!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var nameTextfield: UITextField!
    @IBOutlet private weak var locationLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var durationLabel: UILabel!
    @IBOutlet private weak var batteryLabel: UILabel!
    @IBOutlet private weak var distanceLabel: UILabel!
    @IBOutlet private weak var diagnosticsStackView: UIStackView!
    @IBOutlet private weak var editButton: UIButton!
    @IBOutlet private weak var shareFlightButton: UIButton!
    @IBOutlet private weak var deleteFlightButton: UIButton!
    @IBOutlet private weak var portraitContainer: UIView!
    @IBOutlet private weak var landscapeContainer: UIView!
    @IBOutlet private weak var scrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var contentStackViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var executionView: UIView!
    @IBOutlet private weak var executionLabel: UILabel!
    @IBOutlet private weak var executionCountLabel: UILabel!
    @IBOutlet private weak var executionStackView: UIStackView!

    // MARK: - Private Properties
    private weak var coordinator: Coordinator?
    private var cancellables = Set<AnyCancellable>()
    private var viewModel: FlightDetailsViewModel!
    private var mapController: UIViewController?

    // MARK: - Internal Properties
    var temporaryShareUrl: URL?

    // MARK: - Private Enums
    private enum Constants {
        static let landscapeContentLeading: CGFloat = 40.0
    }

    // MARK: - Setup
    /// Instantiate.
    ///
    /// - Parameters:
    ///    - coordinator: a coordinator
    ///    - data: flight datas
    static func instantiate(coordinator: Coordinator, viewModel: FlightDetailsViewModel) -> FlightDetailsViewController {
        let viewController = StoryboardScene.FlightsViewController.flightDetailsViewController.instantiate()
        viewController.coordinator = coordinator
        viewController.viewModel = viewModel

        return viewController
    }

    // MARK: - Deinit
    deinit {
        cleanTemporaryFile()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()

        loadExecutedPlans()

        updateContainers()

        updateMapDisplay()

        let gesture = UITapGestureRecognizer(target: self, action: #selector(editTitle))
        nameLabel.addGestureRecognizer(gesture)
        nameLabel.isUserInteractionEnabled = true
        nameTextfield.delegate = self
        bindViewModel()
        // Manage keyboard appearance.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(sender:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(sender:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.flightDetails,
                             logType: .screen)
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    /// Update display when orientation changed.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        updateContainers()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension FlightDetailsViewController {
    /// Back button touched.
    @IBAction func backButtonTouchedUpInside(_ sender: Any) {
        coordinator?.back()
    }

    /// Edit button touched.
    @IBAction func editButtonTouchedUpInside(_ sender: Any) {
        editTitle()
    }

    /// Export button touched.
    @IBAction func shareFlightTouchedUpInside(_ sender: Any) {
        shareFile(data: viewModel.shareFileData,
                  name: viewModel.shareFileName,
                  fileExtension: GutmaConstants.extensionName)
    }

    @IBAction func deleteFlightTouchedUpInside(_ sender: Any) {
        // TODO - To implement
    }

    @objc func editTitle() {
        nameTextfield.becomeFirstResponder()
        nameLabel.isHidden.toggle()
        editButton.isHidden.toggle()
        nameTextfield.isHidden.toggle()
    }
}

// MARK: - Private Funcs
private extension FlightDetailsViewController {
    /// Init view.
    func initView() {
        flightLogLabel.text = L10n.dashboardMyFlightFlightLog
        nameTextfield.isHidden = true
        executionLabel.text = L10n.dashboardMyFlightsPlanExecution
        shareFlightButton.setTitle(L10n.dashboardMyFlightShareFlight, for: .normal)
        shareFlightButton.customCornered(corners: [.allCorners], radius: Style.largeCornerRadius)
        deleteFlightButton.setTitle(L10n.dashboardMyFlightDeleteFlight, for: .normal)
        deleteFlightButton.customCornered(corners: [.allCorners], radius: Style.largeCornerRadius)
        executionView.customCornered(corners: [.allCorners],
                                     radius: Style.largeCornerRadius)
    }

    /// Update content regarding view model.
    func bindViewModel() {
        viewModel.$name
            .sink { [unowned self] in
                nameLabel.text = $0
            }
            .store(in: &cancellables)
        nameTextfield.text = nameLabel.text
        locationLabel.text = viewModel.flight.coordinateDescription
        dateLabel.text = viewModel.flight.formattedDate
        durationLabel.text = viewModel.flight.formattedDuration
        batteryLabel.text = viewModel.flight.batteryConsumptionPercents
        distanceLabel.text = viewModel.flight.formattedDistance

        // TODO: replace this with actual diagnostics from gutma.
        //        diagnosticsStackView.safelyRemoveArrangedSubviews()
        //        let diagnosticView = FlightDetailsDiagnosticView()
        //        diagnosticView.model = FlightDetailsDiagnosticModel(image: Asset.Common.Icons.icWarningRed.image,
        //                                                            mainText: "Battery problem detected on that flight",
        //                                                            subText: "Battery #1489395",
        //                                                            supportButtonText: "Get support",
        //                                                            supportURL: nil)
        //        diagnosticView.delegate = self
        //        let secondDiagosticView = FlightDetailsDiagnosticView()
        //        secondDiagosticView.model = FlightDetailsDiagnosticModel(image: Asset.Common.Icons.icWarningRed.image,
        //                                                            mainText: "Propeller broken",
        //                                                            subText: nil,
        //                                                            supportButtonText: "See tutorial",
        //                                                            supportURL: nil)
        //        secondDiagosticView.delegate = self
        //        diagnosticsStackView.addArrangedSubview(diagnosticView)
        //        diagnosticsStackView.addArrangedSubview(secondDiagosticView)
    }

    /// Loads executed plans (if exists).
    func loadExecutedPlans() {
        // TODO loadExecutedPlans
        let flightPlanCells = viewModel.flightPlanCells
        guard !flightPlanCells.isEmpty else {
            executionView.isHidden = true
            return
        }

        executionCountLabel.text  = "\(flightPlanCells.count)"
        flightPlanCells.forEach { (flightPlanCell) in
            let cell = ExecutionTableViewCell.loadFromNib()
            cell.setup(name: flightPlanCell.flightPlan.customTitle,
                       icon: flightPlanCell.icon,
                       flightPlan: flightPlanCell.flightPlan)
            cell.selectionHandler = { [weak self] in
                (self?.coordinator as? DashboardCoordinator)?.startFlightPlanDashboard(flightPlan: flightPlanCell.flightPlan)
            }
            // A stackView is used here instead of a tableview to ease integration in global scrollview.
            // Moreover the number of view won't be numerous here.
            executionStackView.addArrangedSubview(cell)
        }
    }

    /// Update containers display, regarding orientation.
    func updateContainers() {
        if mapController == nil {
            initMap()
        }
        backButton.tintColor = UIApplication.isLandscape ? ColorName.defaultTextColor.color : .white
        portraitContainer.isHidden = UIApplication.isLandscape
        landscapeContainer.isHidden = !UIApplication.isLandscape
        contentStackViewLeadingConstraint.constant = UIApplication.isLandscape ? Constants.landscapeContentLeading : Constants.landscapeContentLeading / 2.0

        let container: UIView = UIApplication.isLandscape ? landscapeContainer : portraitContainer
        addMap(to: container)
    }

    /// Init map controller.
    func initMap() {
        let controller = MapViewController.instantiate(mapMode: .myFlights)
        controller.view.backgroundColor = .clear
        addChild(controller)
        mapController = controller
        addMap(to: landscapeContainer)
        mapController?.didMove(toParent: self)
    }

    /// Add Map view to dedicated container view.
    ///
    /// - Parameters:
    ///     - destinationContainerView: destination container view
    func addMap(to destinationContainerView: UIView) {
        guard let mapController = mapController,
            mapController.view.superview != destinationContainerView
            else {
                return
        }
        mapController.view.removeFromSuperview()
        mapController.view.frame = destinationContainerView.bounds
        destinationContainerView.addSubview(mapController.view)
        self.view.layoutIfNeeded()
    }

    /// Updates the current map display with current flight.
    func updateMapDisplay() {
        if let mapViewController = mapController as? MapViewController,
           let gutma = viewModel.gutma {
            mapViewController.displayFlightCourse(gutma: gutma)
        }
    }
}

// MARK: - UITextField Delegate
extension FlightDetailsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if let newTitle = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
           !newTitle.isEmpty {
            viewModel.set(name: newTitle)
        }
        nameLabel.isHidden.toggle()
        editButton.isHidden.toggle()
        nameTextfield.isHidden.toggle()
        return true
    }
}

// MARK: - FlightDetailsDiagnosticViewDelegate
extension FlightDetailsViewController: FlightDetailsDiagnosticViewDelegate {
    func openSupportURL(_ url: URL) {
        // TODO: open safari vc with URL.
    }
}

// MARK: - Keyboard Helpers
private extension FlightDetailsViewController {
    /// Manages view display when keyboard is displayed.
    @objc func keyboardWillShow(sender: NSNotification) {
        // Only active in portrait.
        if UIApplication.isLandscape == false,
            let userInfo = sender.userInfo,
            let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            // Move view upward.
            scrollViewBottomConstraint.constant = keyboardFrame.size.height
        }
    }

    /// Manages view display after keyboard was displayed.
    @objc func keyboardWillHide(sender: NSNotification) {
        // Move view to original position.
        scrollViewBottomConstraint.constant = 0
    }
}
