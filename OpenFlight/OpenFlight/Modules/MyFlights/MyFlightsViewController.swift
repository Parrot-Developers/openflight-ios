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
/// Describes MyFlights panels.
/// MyFlights screen is split in two parts.
/// Each parts is identified by a MyFlightsPanelType.
enum MyFlightsPanelType: Int, CaseIterable {
    case completedFlights
    case plans
}

extension MyFlightsPanelType {
    /// Defines default panel.
    static var defaultPanel: MyFlightsPanelType {
        return .completedFlights
    }

    /// Gives panel regarding index.
    static func type(at index: Int) -> MyFlightsPanelType {
        guard index >= 0, index < MyFlightsPanelType.allCases.count
            else { return MyFlightsPanelType.defaultPanel }
        return MyFlightsPanelType.allCases[index]
    }

    /// Gives index regarding panel.
    static func index(for panel: MyFlightsPanelType) -> Int {
        switch panel {
        case .completedFlights:
            return 0
        case .plans:
            return 1
        }
    }

    ///  Provides panel name.
    var title: String {
        switch self {
        case .completedFlights:
            return L10n.dashboardMyFlightsSectionCompleted
        case .plans:
            return L10n.dashboardMyFlightsSectionPlans
        }
    }
}

/// MyFlights entry view controller.
/// Contains ans manages the two MyFlights panels (completedFlights and plans).
final class MyFlightsViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var segmentedControl: UISegmentedControl!
    @IBOutlet private weak var topBar: UIView!
    private weak var viewAccount: MyFlightsAccountView?

    // MARK: - Private Properties
    private var flightsViewController: FlightsViewController?
    private var flightPlanViewController: FlightPlansListViewController?
    private var numberOfFlights: Int = 0
    private weak var coordinator: DashboardCoordinator?
    private var selectedPanel: MyFlightsPanelType {
        MyFlightsPanelType.type(at: segmentedControl?.selectedSegmentIndex ?? 0)
    }

    // MARK: - Private Enums
    private enum Constants {
        static let heightAccountView: CGFloat = 40
        static let trailingAccountView: CGFloat = -20
    }

    // MARK: - Setup
    static func instantiate(coordinator: DashboardCoordinator) -> MyFlightsViewController {
        let viewController = StoryboardScene.MyFlightsViewController.initialScene.instantiate()
        viewController.coordinator = coordinator

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.setNavigationBarHidden(true, animated: false)
        initUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewAccount?.viewWillAppear()
        LogEvent.logAppEvent(screen: selectedPanel == .completedFlights
                                ? LogEvent.EventLoggerScreenConstants.myFlightsFlightList
                                : LogEvent.EventLoggerScreenConstants.myFlightsPlans,
                             logType: .screen)
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
private extension MyFlightsViewController {
    /// Close button clicked.
    @IBAction func closeButtonTouchedUpInside(_ sender: AnyObject) {
        self.coordinator?.back()
    }

    /// UISegmentedControl's segment changed.
    @IBAction func segmentDidChange(_ sender: UISegmentedControl) {
        reloadContainerView()
        LogEvent.logAppEvent(screen: selectedPanel == .completedFlights
                                ? LogEvent.EventLoggerScreenConstants.myFlightsFlightList
                                : LogEvent.EventLoggerScreenConstants.myFlightsPlans,
                             logType: .screen)
    }
}

// MARK: - Private Funcs
private extension MyFlightsViewController {
    /// Instantiate basic UI.
    func initUI() {
        topBar.addShadow(shadowColor: ColorName.defaultTextColor.color)
        setupSegmentedControl()
        reloadContainerView()
        setupAccountView()
    }

    /// Setup account view.
    func setupAccountView() {
        if let currentAccount = AccountManager.shared.currentAccount,
           let viewAccount = currentAccount.myFlightsAccountView {
            viewAccount.delegate = self
            viewAccount.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(viewAccount)
            NSLayoutConstraint.activate([
                viewAccount.trailingAnchor.constraint(equalTo: topBar.trailingAnchor, constant: Constants.trailingAccountView),
                viewAccount.heightAnchor.constraint(equalToConstant: Constants.heightAccountView),
                viewAccount.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
                viewAccount.leadingAnchor.constraint(equalTo: segmentedControl.trailingAnchor)
            ])
            self.viewAccount = viewAccount
        }
    }

    /// Setup segmented control.
    func setupSegmentedControl() {
        self.segmentedControl.removeAllSegments()
        for panelType in MyFlightsPanelType.allCases {
            self.segmentedControl.insertSegment(withTitle: panelType.title,
                                                at: self.segmentedControl.numberOfSegments,
                                                animated: false)
        }
        self.segmentedControl.selectedSegmentIndex = MyFlightsPanelType.index(for: selectedPanel)
        segmentedControl.customMakeup()
    }

    /// Remove all child views and viewControllers and insert the new ones
    func insertContainerView(controller: UIViewController) {
        for view in containerView.subviews {
            view.removeFromSuperview()
        }
        for childVC in children {
            childVC.removeFromParent()
        }
        addChild(controller)
        controller.view.frame = containerView.bounds
        containerView.addSubview(controller.view)
        controller.didMove(toParent: self)
    }

    /// Reload container view.
    func reloadContainerView() {
        switch selectedPanel {
        case .completedFlights:
            var controller: FlightsViewController
            if let flightsViewController = self.flightsViewController {
                controller = flightsViewController
            } else {
                // Initial case
                guard let coordinator = coordinator else { return }
                let viewModel = FlightsViewModel(service: Services.hub.flight.service, coordinator: coordinator)
                let newViewController = FlightsViewController.instantiate(viewModel: viewModel)
                self.flightsViewController = newViewController
                controller = newViewController
            }
            insertContainerView(controller: controller)
        case .plans:
            var controller: FlightPlansListViewController
            if let flightPlanViewController = self.flightPlanViewController {
                controller = flightPlanViewController
            } else {
                // Initial case
                let newViewController = StoryboardScene.FlightPlansList.flightPlansListViewController.instantiate()
                newViewController.setupViewModel(with: FlightPlansListViewModel(manager: Services.hub.flightPlan.projectManager,
                                                                                flightPlanTypeStore: Services.hub.flightPlan.typeStore),
                                                 delegate: self)
                self.flightPlanViewController = newViewController
                controller = newViewController
            }
            insertContainerView(controller: controller)
        }

    }
}

// MARK: - MyFlightsAccountViewDelegate
extension MyFlightsViewController: MyFlightsAccountViewDelegate {
    func didClickOnAccount() {
        coordinator?.startMyFlightsAccountView()
    }
}

// MARK: - FlightPlansListViewControllerDelegate
extension MyFlightsViewController: FlightPlansListViewModelDelegate {
    func didSelect(project: ProjectModel) {
        coordinator?.startFlightPlanDashboard(projectModel: project)
    }

    func didDoubleTapOn(project: ProjectModel) { }
}
