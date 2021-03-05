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
    @IBOutlet private weak var bgView: UIView!
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var segmentedControl: UISegmentedControl!
    @IBOutlet private weak var topBar: UIView!
    @IBOutlet private weak var accountView: UIView!

    // MARK: - Private Properties
    private var flightsViewController: FlightsViewController?
    private var flightPlanViewController: FlightPlansListViewController?
    private var numberOfFlights: Int = 0
    private weak var coordinator: DashboardCoordinator?
    private var myFlightsViewModel: MyFlightsViewModel?
    private var selectedPanel: MyFlightsPanelType {
        MyFlightsPanelType.type(at: segmentedControl?.selectedSegmentIndex ?? 0)
    }

    // MARK: - Setup
    static func instantiate(coordinator: DashboardCoordinator, viewModel: MyFlightsViewModel) -> MyFlightsViewController {
        let viewController = StoryboardScene.MyFlightsViewController.initialScene.instantiate()
        viewController.coordinator = coordinator
        viewController.myFlightsViewModel = viewModel

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.setNavigationBarHidden(true, animated: false)
        initUI()
        listenMyFlightsViewModel()
        setupSegmentedControl()
        reloadContainerView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        setupAccountView()
        LogEvent.logAppEvent(screen: selectedPanel == .completedFlights
                                ? LogEvent.EventLoggerScreenConstants.myFlightsFlightList
                                : LogEvent.EventLoggerScreenConstants.myFlightsPlans,
                             logType: .screen)
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
        segmentedControl.customMakeup()
        bgView.backgroundColor = ColorName.black80.color
    }

    /// Listen MyFlights ViewModel.
    func listenMyFlightsViewModel() {
        myFlightsViewModel?.state.valueChanged = { [weak self] state in
            if state.numberOfFlights != self?.numberOfFlights {
                self?.flightsViewController?.loadAllFlights()
            }
            self?.numberOfFlights = state.numberOfFlights
        }
    }

    /// Setup account view.
    func setupAccountView() {
        if let currentAccount = AccountManager.shared.currentAccount,
            let myFlightsAccountView = currentAccount.myFlightsAccountView {
            self.accountView.removeSubViews()
            myFlightsAccountView.frame = self.accountView.bounds
            // Correct frame size issue when the device orientation is updated.
            myFlightsAccountView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            myFlightsAccountView.delegate = self
            self.accountView.addSubview(myFlightsAccountView)
        } else {
            self.accountView.isHidden = true
        }
    }

    /// Setup segmented control.
    func setupSegmentedControl() {
        segmentedControl.customMakeup()
        self.segmentedControl.removeAllSegments()
        for panelType in MyFlightsPanelType.allCases {
            self.segmentedControl.insertSegment(withTitle: panelType.title,
                                                at: self.segmentedControl.numberOfSegments,
                                                animated: false)
        }
        self.segmentedControl.selectedSegmentIndex = MyFlightsPanelType.index(for: selectedPanel)
    }

    /// Reload container view.
    func reloadContainerView() {
        let controller: UIViewController
        switch selectedPanel {
        case .completedFlights:
            if let flightsViewController = self.flightsViewController {
                controller = flightsViewController
            } else {
                // Initial case
                let newViewController = FlightsViewController.instantiate(coordinator: coordinator)
                self.flightsViewController = newViewController
                controller = newViewController
            }
        case .plans:
            if let flightPlanViewController = self.flightPlanViewController {
                controller = flightPlanViewController
            } else {
                // Initial case
                let newViewController = StoryboardScene.FlightPlansList.flightPlansListViewController.instantiate()
                newViewController.delegate = self
                self.flightPlanViewController = newViewController
                controller = newViewController
            }
        }

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
}

// MARK: - MyFlightsAccountViewDelegate
extension MyFlightsViewController: MyFlightsAccountViewDelegate {
    func didClickOnAccount() {
        coordinator?.startMyFlightsAccountView()
    }
}

// MARK: - FlightPlansListViewControllerDelegate
extension MyFlightsViewController: FlightPlansListViewControllerDelegate {
    func didSelect(flightPlan: FlightPlanViewModel) {
        coordinator?.startFlightPlanDashboard(viewModel: flightPlan)
    }
}
