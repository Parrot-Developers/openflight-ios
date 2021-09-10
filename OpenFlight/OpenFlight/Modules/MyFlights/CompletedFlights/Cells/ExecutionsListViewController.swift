//
//  Copyright (C) 2021 Parrot Drones SAS.
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

// MARK: - Protocol
public protocol ExecutionsListDelegate: AnyObject {
    func startFlightDetails(flightPlan: FlightPlanModel)
    func handleHistoryCellAction(with: FlightPlanModel, actionType: HistoryMediasActionType?)
    func backDisplay()
    func open(flightPlan: FlightPlanModel)
}

// MARK: - Public Enums
/// Stores different type of history table view.
public enum HistoryTableType {
    /// Table view is in a mini display mode.
    case miniHistory
    /// Table view is in a full display mode.
    case fullHistory
}

/// Executions list ViewController.
final class ExecutionsListViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var emptyFlightsTitleLabel: UILabel!
    @IBOutlet private weak var emptyFlightsDecriptionLabel: UILabel!
    @IBOutlet private weak var emptyLabelStack: UIStackView!
    @IBOutlet weak var logoType: UIImageView!
    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.makeUp(with: .huge, and: .defaultTextColor)
        }
    }
    @IBOutlet weak var separator: UIView!

    private enum Constant {
        static let height: CGFloat = 80
        static let heightMini: CGFloat = 80
        static let estimationHeight: CGFloat = 200.0
        static let headerHeight: CGFloat = 35.0
        static let headerHeightMini: CGFloat = 0
    }

    // MARK: - Private Properties
    private var flightPlanHandler: FlightPlanManager!
    private var flightItems: [FlightPlanModel] = []
    private var projectModel: ProjectModel!
    private weak var delegate: ExecutionsListDelegate?

    /// List of history views for each flight plan execution.
    var fpExecutionsViews: [String: HistoryMediasView] = [:]
    var tableType: HistoryTableType = .fullHistory

    // MARK: - Setup
    static func instantiate(delegate: ExecutionsListDelegate?,
                            flightPlanHandler: FlightPlanManager,
                            projectModel: ProjectModel,
                            tableType: HistoryTableType) -> ExecutionsListViewController {
        let viewController = StoryboardScene.ExecutionsListViewController.initialScene.instantiate()
        viewController.delegate = delegate
        viewController.flightPlanHandler = flightPlanHandler
        viewController.projectModel = projectModel
        viewController.tableType = tableType
        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup tableView.
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = Constant.estimationHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(cellType: ExecutionsTableViewCell.self)
        emptyFlightsTitleLabel.text = L10n.dashboardMyFlightsEmptyListTitle
        emptyFlightsDecriptionLabel.text = L10n.dashboardMyFlightsEmptyListDesc
        view.backgroundColor = ColorName.white.color
        tableView.backgroundColor = ColorName.defaultBgcolor.color
        separator.backgroundColor = ColorName.greySilver.color
        if tableType == .miniHistory {
            tableView.insetsContentViewsToSafeArea = false // Safe area is handled in this VC, not in content
            tableView.allowsSelection = true
        }
        loadAllFlights(tableType: tableType)

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.tableView.reloadData()
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

    func getFligthPlanType(with type: String?) -> FlightPlanType? {
        return Services.hub.flightPlan.typeStore.typeForKey(type)
    }

    // MARK: - Public Funcs
    /// Load all flights saved in local database.
    public func loadAllFlights(tableType: HistoryTableType) {
        flightItems = Services.hub.flightPlan.projectManager.executedFlightPlans(for: projectModel)
        emptyLabelStack.isHidden = !flightItems.isEmpty
        titleLabel.text = projectModel.title
        fpExecutionsViews = FlightPlanHistorySyncManager.shared.syncProvider?.historySyncViews(
            type: tableType,
            projectModel: projectModel) ?? [:]
        tableView.reloadData()
    }

    @IBAction func didTapBackButton(_ sender: UIButton) {
        delegate?.backDisplay()
    }
}

// MARK: - UITableView DataSource
extension ExecutionsListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return flightItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as ExecutionsTableViewCell

        var showDate: Bool = true
        let item = flightItems[indexPath.row]
        if indexPath.row > 0 {
            let startDate = item.dataSetting?.estimations.duration
            let previousItemDate = flightItems[indexPath.row - 1].lastUpdate
            showDate = !previousItemDate.isInSameMonth(date: Date(timeIntervalSinceNow: startDate ?? 0))
        }

        let mediaView = fpExecutionsViews[item.uuid]
        cell.configureCell(flightPlan: item,
                           mediasView: mediaView,
                           tableType: tableType,
                           showDate: showDate)
        cell.layoutIfNeeded()
        cell.delegate = self
        return cell
    }
}

// MARK: - UITableView Delegate
extension ExecutionsListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.startFlightDetails(flightPlan: flightItems[indexPath.row])
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let item = flightItems.remove(at: indexPath.row)
            [item].forEach { flightPlan in
                flightPlanHandler.delete(flightPlan: flightPlan)
            }
            tableView.reloadData()
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableType == .fullHistory ? Constant.height : Constant.heightMini
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard tableType == .fullHistory else { return nil }
        let headerTitle = UILabel()
        headerTitle.text = L10n.flightPlanExecutionPlural(self.flightItems.count)
        headerTitle.makeUp(and: ColorName.greyDark)
        let headerView = UIView()
        headerTitle.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(headerTitle)
        NSLayoutConstraint.activate([
            headerTitle.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            headerTitle.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 60),
            headerTitle.widthAnchor.constraint(equalToConstant: 150)
        ])
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return tableType == .fullHistory ? Constant.headerHeight : Constant.headerHeightMini
    }
}

extension ExecutionsListViewController: FlightPlanHistoryCellDelegate {
    func didTapOnResume(flightModel: FlightPlanModel) {
        delegate?.open(flightPlan: flightModel)
    }

    func didTapOnMedia(flightModel: FlightPlanModel, action: HistoryMediasActionType?) {
        guard let strongAction = action else { return }
        delegate?.handleHistoryCellAction(with: flightModel, actionType: strongAction)
    }
}
