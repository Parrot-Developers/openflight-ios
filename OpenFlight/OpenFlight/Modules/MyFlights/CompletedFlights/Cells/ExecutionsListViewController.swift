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
import CoreData
import Combine
import Pictor

// MARK: - Protocol
public protocol ExecutionsListDelegate: AnyObject {
    func startFlightExecutionDetails(_ flightPlan: FlightPlanModel, animated: Bool)
    func backDisplay()
    func open(flightPlan: FlightPlanModel)
}

/// Executions list ViewController.
final class ExecutionsListViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var topBar: SideNavigationBarView!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var emptyFlightsTitleLabel: UILabel!
    @IBOutlet private weak var emptyFlightsDecriptionLabel: UILabel!
    @IBOutlet private weak var emptyLabelStack: UIStackView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var projectTitleLabel: UILabel!

    private enum Constant {
        static let height: CGFloat = 80
        static let estimationHeight: CGFloat = 200.0
    }

    // MARK: - Private Properties
    private var flightPlanHandler: FlightPlanManager!
    private var projectManager: ProjectManager!
    private var flightItems: [FlightPlanModel] = []
    private var selectedFlightItem: FlightPlanModel?
    private var projectModel: ProjectModel!
    private var flightService: FlightService!
    private var flightPlanRepository: PictorFlightPlanRepository!
    private var topBarService: HudTopBarService!
    private weak var delegate: ExecutionsListDelegate?
    private var cancellables: [AnyCancellable] = []
    private var backButtonPublisher: AnyPublisher<Void, Never>?

    // MARK: - Setup
    static func instantiate(delegate: ExecutionsListDelegate?,
                            flightPlanHandler: FlightPlanManager,
                            projectManager: ProjectManager,
                            projectModel: ProjectModel,
                            flightService: FlightService,
                            flightPlanRepository: PictorFlightPlanRepository,
                            topBarService: HudTopBarService,
                            backButtonPublisher: AnyPublisher<Void, Never>) -> ExecutionsListViewController {
        let viewController = StoryboardScene.ExecutionsListViewController.initialScene.instantiate()
        viewController.delegate = delegate
        viewController.flightPlanHandler = flightPlanHandler
        viewController.projectManager = projectManager
        viewController.projectModel = projectModel
        viewController.flightService = flightService
        viewController.flightPlanRepository = flightPlanRepository
        viewController.topBarService = topBarService
        viewController.backButtonPublisher = backButtonPublisher
        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        bindViewModel()

        // Setup tableView.
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = Constant.estimationHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(cellType: FlightPlanExecutionCell.self)
        tableView.register(cellType: FlightPlanListExecutionHeaderCell.self)
        emptyFlightsTitleLabel.text = L10n.dashboardMyFlightsEmptyListTitle
        emptyFlightsDecriptionLabel.text = L10n.dashboardMyFlightsEmptyListDesc
        view.backgroundColor = ColorName.white.color
        tableView.backgroundColor = ColorName.defaultBgcolor.color
        tableView.insetsContentViewsToSafeArea = false // Safe area is handled in this VC, not in content
        tableView.allowsSelection = true
        loadAllExecutions()
        listenBackDisplay()
        listenExecutionsChange()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadAllExecutions()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    /// Update display when orientation changed.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // Reload data source.
        tableView.reloadData()
        DispatchQueue.main.async {
            // Compute cell height correctly.
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    // MARK: - Public Funcs
    /// Load all flights saved in local database.
    public func loadAllExecutions() {
        flightItems = Services.hub.flightPlan.projectManager.executedFlightPlans(for: projectModel)
        emptyLabelStack.isHidden = !flightItems.isEmpty
        tableView.isHidden = flightItems.isEmpty
        titleLabel.text = L10n.flightPlanHistory
        projectTitleLabel.text = projectModel.title
        tableView.reloadData()
    }

    @IBAction func didTapBackButton(_ sender: UIButton) {
        delegate?.backDisplay()
    }

    private func listenBackDisplay() {
        projectManager.hideExecutionsListPublisher
            .sink { [unowned self] _ in
                delegate?.backDisplay()
            }
            .store(in: &cancellables)
    }

    /// Reload flights when there is a change
    private func listenExecutionsChange() {
        // Update the executions list Flights (new Gutma available) have changed.
        flightService.flightsDidChangePublisher
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadAllExecutions()
            }
            .store(in: &cancellables)
    }
}

// MARK: - UI
extension ExecutionsListViewController {

    func setupUI() {
        // Top Bar
        topBar.backgroundColor = ColorName.white.color
        topBar.layer.zPosition = 1
        topBar.addShadow()

        // Labels
        projectTitleLabel.makeUp(with: .big, color: .defaultTextColor)
        titleLabel.makeUp(with: .smallText, color: .defaultTextColor)
        emptyFlightsTitleLabel.makeUp(with: .huge, and: .defaultTextColor)
        emptyFlightsDecriptionLabel.makeUp(with: .large, and: .defaultTextColor)
    }

    /// Binds view model.
    private func bindViewModel() {
        // Listen to back button publisher.
        backButtonPublisher?.sink { [weak self] in
            guard let self = self else { return }
            self.delegate?.backDisplay()
        }
        .store(in: &cancellables)
    }
}

// MARK: - UITableView DataSource
extension ExecutionsListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // header + executions
        return 1 + flightItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let header: FlightPlanListExecutionHeaderCell = tableView.dequeueReusableCell(for: indexPath)
            header.fill(exeuctions: flightItems.count)
            return header
        } else {
            let cell = tableView.dequeueReusableCell(for: indexPath) as FlightPlanExecutionCell
            let execution = flightItems[indexPath.row - 1]
            cell.fill(execution: execution)
            if let selectedFlightItem = selectedFlightItem,
               execution.uuid == selectedFlightItem.uuid {
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            }
            return cell
        }
    }
}

// MARK: - UITableView Delegate
extension ExecutionsListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let flightItem = flightItems[indexPath.row - 1]
        selectedFlightItem = flightItem
        delegate?.startFlightExecutionDetails(flightItem, animated: true)
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard indexPath.row != 0 else { return false } // Prevent "Header" deletion
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let item = flightItems.remove(at: indexPath.row - 1)
            [item].forEach { flightPlan in
                flightPlanHandler.delete(flightPlan: flightPlan)
            }
            tableView.reloadData()
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
