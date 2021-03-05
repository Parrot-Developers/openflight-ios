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

/// Flight details ViewController.

final class FlightDetailsViewController: UIViewController, FileShare {
    // MARK: - Outlets
    @IBOutlet private weak var bgView: UIView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var nameTextfield: UITextField!
    @IBOutlet private weak var locationLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var durationLabel: UILabel!
    @IBOutlet private weak var batteryLabel: UILabel!
    @IBOutlet private weak var distanceLabel: UILabel!
    @IBOutlet private weak var diagnosticsStackView: UIStackView!
    @IBOutlet private weak var editButton: UIButton!
    @IBOutlet private weak var exportButton: UIButton!
    @IBOutlet private weak var portraitContainer: UIView!
    @IBOutlet private weak var landscapeContainer: UIView!
    @IBOutlet private weak var scrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var contentStackViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var overviewView: UIView!
    @IBOutlet private weak var executionView: UIView!
    @IBOutlet private weak var executionLabel: UILabel!
    @IBOutlet private weak var executionCountLabel: UILabel!
    @IBOutlet private weak var executionStackView: UIStackView!

    // MARK: - Private Properties
    private weak var coordinator: Coordinator?
    private var viewModel: FlightDataViewModel?
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
    static func instantiate(coordinator: Coordinator, viewModel: FlightDataViewModel) -> FlightDetailsViewController {
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

        // Load all data used to display flight details.
        viewModel?.loadGutmaContent()

        loadExecutedPlans()

        updateContainers()

        viewModel?.state.valueChanged = { [weak self] state in
            self?.updateContent(state)
        }
        self.updateContent(viewModel?.state.value)

        updateMapDisplay()
        viewModel?.requestPlacemark()

        let gesture = UITapGestureRecognizer(target: self, action: #selector(editTitle))
        nameLabel.addGestureRecognizer(gesture)
        nameLabel.isUserInteractionEnabled = true
        nameTextfield.delegate = self

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
        return .all
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
    @IBAction func exportButtonTouchedUpInside(_ sender: Any) {
        shareFile(data: self.viewModel?.gutma?.asData(),
                  name: self.viewModel?.state.value.title,
                  fileExtension: GutmaConstants.extensionName)
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
        bgView.backgroundColor = ColorName.black80.color
        nameLabel.makeUp(with: .huge)
        nameTextfield.makeUp(style: .huge)
        nameTextfield.tintColor = .white
        nameTextfield.backgroundColor = .clear
        nameTextfield.isHidden = true
        dateLabel.makeUp(with: .large)
        locationLabel.makeUp(with: .large, and: .white50)
        distanceLabel.makeUp(with: .large)
        batteryLabel.makeUp(with: .large)
        durationLabel.makeUp(with: .large)
        executionLabel.makeUp(with: .huge)
        executionLabel.text = L10n.dashboardMyFlightsPlanExecution
        executionView.applyCornerRadius(Style.largeCornerRadius)
        executionView.setBorder(borderColor: ColorName.white20.color,
                                borderWidth: Style.smallBorderWidth)
        overviewView.applyCornerRadius(Style.largeCornerRadius)
        overviewView.setBorder(borderColor: ColorName.white20.color,
                               borderWidth: Style.smallBorderWidth)
        executionCountLabel.makeUp(with: .huge, and: .white20)
    }

    /// Update content regarding FlightDatasState.
    ///
    /// - Parameters:
    ///    - state: flight data state
    func updateContent(_ state: FlightDataState? = nil) {
        nameLabel.text = state?.title
        nameTextfield.text = nameLabel.text
        locationLabel.text = state?.formattedPosition
        dateLabel.text = state?.formattedDate
        durationLabel.text = state?.formattedDuration
        batteryLabel.text = state?.batteryConsumption
        distanceLabel.text = state?.formattedDistance

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
        guard let relatedFlightPlan = self.viewModel?.relatedFlightPlan,
              !relatedFlightPlan.isEmpty else {
            executionView.isHidden = true
            return
        }

        executionCountLabel.text = "\(relatedFlightPlan.count)"
        relatedFlightPlan.forEach { (flightPlan) in
            let fpExecutions = flightPlan.executions
            guard let title = flightPlan.state.value.title,
                  let flightId = self.viewModel?.gutma?.flightId,
                  let fpExecution = fpExecutions.filter({ $0.flightId == flightId }).first else {
                return
            }

            let cell = ExecutionTableViewCell.loadFromNib()
            var icon: UIImage?
            if let type = flightPlan.state.value.type {
                icon = FlightPlanTypeManager.shared.missionIcon(for: type)
            }
            cell.setup(name: title,
                       icon: icon,
                       fpExecution: fpExecution)
            cell.selectionHandler = { [weak self] in
                 (self?.coordinator as? DashboardCoordinator)?.startFlightPlanDashboard(viewModel: flightPlan)
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
        if let mapViewController = mapController as? MapViewController {
            mapViewController.displayFlightCourse(viewModel: self.viewModel)
        }
    }
}

// MARK: - UITextField Delegate
extension FlightDetailsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if let newTitle = textField.text, !newTitle.isEmpty {
            viewModel?.updateTitle(newTitle)
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
