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
    var temporaryShareUrl: URL?

    enum Section: Int, CaseIterable {
        case info
        case status
        case settings
        case flights
        case executions
        case actions
    }

    enum ViewModel {
        case details(FlightDetailsViewModel)
        case execution(FlightPlanExecutionViewModel)
    }

    // MARK: - Outlets
    @IBOutlet private weak var backButton: UIButton!
    @IBOutlet weak var mapContainerView: UIView!
    @IBOutlet weak var rightTableView: UITableView!

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var viewModel: ViewModel!
    private var mapController: UIViewController!

    // MARK: - Setup
    /// Instantiate.
    ///
    /// - Parameters:
    ///    - data: flight datas
    static func instantiate(viewModel: ViewModel) -> FlightDetailsViewController {
        let viewController = StoryboardScene.FlightDetailsViewController.flightDetailsViewController.instantiate()
        viewController.viewModel = viewModel
        return viewController
    }

    // MARK: - Deinit
    deinit {
        cleanTemporaryFile()
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        updateMapDisplay()
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.flightDetails,
                             logType: .screen)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        switch viewModel {
        case .details(let viewModel):
            viewModel.$name.sink { [unowned self] _ in
                rightTableView.reloadRows(at: [IndexPath(row: 0, section: Section.info.rawValue)],
                                          with: .automatic)
            }.store(in: &cancellables)
        default:
            break
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    // MARK: - Constants
    enum Constants {
        static let tableViewHeaderLineHeight: CGFloat = 1
        static let tableViewHeaderLineTopMargin: CGFloat = 6
        static let tableViewHeaderLineBottomMargin: CGFloat = 15
        static let tableViewHeaderBottomMargin: CGFloat = 6
        static let tableViewHeaderLabelSize: CGFloat = 30
        static let tableViewHeaderLabelHorizontalMargin: CGFloat = 10
    }
}

// MARK: - Actions
private extension FlightDetailsViewController {
    /// Back button touched.
    @IBAction func backButtonTouchedUpInside(_ sender: Any) {
        switch viewModel {
        case .details(let viewModel):
            viewModel.didTapBack()
        case .execution(let viewModel):
            viewModel.didTapBack()
        case .none:
            break
        }
    }
}

// MARK: - Private Funcs
private extension FlightDetailsViewController {
    /// Init view.
    func initView() {
        initMap()
        backButton.tintColor = ColorName.white.color
        rightTableView.contentInsetAdjustmentBehavior = .never
        rightTableView.contentInset = UIEdgeInsets(top: 15, left: 0, bottom: 0, right: 0)
        rightTableView.backgroundColor = ColorName.defaultBgcolor.color
        rightTableView.rowHeight = UITableView.automaticDimension
        rightTableView.estimatedRowHeight = 70
        // Workaround to remove the top grouped tableview extra space.
        rightTableView.tableHeaderView =
            UIView(frame: CGRect(origin: .zero,
                                 size: CGSize(width: 0.0, height: Double.leastNormalMagnitude)))
        rightTableView.delegate = self
        registerTableViewCellTypes()
    }

    func registerTableViewCellTypes() {
        rightTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        rightTableView.register(cellType: FlightDetailsInfoCell.self)
        rightTableView.register(cellType: FlightDetailsActionCell.self)
        rightTableView.register(cellType: FlightDetailsExecutionsCell.self)
        rightTableView.register(cellType: FlightExecutionDetailsSettingsCell.self)
        rightTableView.register(cellType: FlightDetailsSectionHeaderCell.self)
        rightTableView.register(cellType: FlightExecutionDetailsFlightsCell.self)
        rightTableView.register(cellType: FlightExecutionDetailsStatusCell.self)
    }

    /// Updates content regarding view model.
    func bindViewModel() {
        rightTableView.dataSource = self
    }

    /// Init map controller.
    func initMap() {
        let controller = MapViewController.instantiate(mapMode: .myFlights)
        controller.view.backgroundColor = .clear
        mapController = controller
        add(mapViewController: controller, to: mapContainerView)
    }

    /// Adds Map view to dedicated container view.
    ///
    /// - Parameters:
    ///     - destinationContainerView: destination container view
    func add(mapViewController: UIViewController, to destinationContainerView: UIView) {
        guard mapViewController.view.superview != destinationContainerView else {
            return
        }
        addChild(mapViewController)
        destinationContainerView.addSubview(mapViewController.view)
        mapViewController.view.frame = destinationContainerView.bounds
        mapController?.didMove(toParent: self)
        self.view.layoutIfNeeded()
    }

    /// Updates the current map display with current flight.
    func updateMapDisplay() {
        switch viewModel {
        case .details(let viewModel):
            if let mapViewController = mapController as? MapViewController {
               mapViewController.displayFlightCourse(flightsPoints: [viewModel.flightPoints],
                                                     hasAsmlAltitude: viewModel.hasAsmlAltitude)
            }
        case .execution(let viewModel):
            if let mapViewController = mapController as? MapViewController {
                mapViewController.flightPlan = viewModel.flightPlan
                mapViewController.displayFlightPlan(viewModel.flightPlan)
                mapViewController.displayFlightCourse(flightsPoints: viewModel.flightsPoints,
                                                      hasAsmlAltitude: viewModel.hasAsmlAltitude)
            }
        case .none:
            break
        }
    }
}

// MARK: - FlightDetailsDiagnosticViewDelegate
extension FlightDetailsViewController: FlightDetailsDiagnosticViewDelegate {
    func openSupportURL(_ url: URL) {
        // TODO: open safari vc with URL.
    }
}

extension FlightDetailsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch viewModel {
        case .details(let viewModel):
            switch Section(rawValue: section) {
            case .none, .status, .settings, .flights:
                return  0
            case .info:
                return 1
            case .executions:
                return viewModel.flightPlans.count
            case .actions:
                return viewModel.actions.count
            }
        case .execution(let viewModel):
            switch Section(rawValue: section) {
            case .none, .executions:
                return  0
            case .info:
                return 1
            case .status:
                return 1
            case .settings:
                return 1
            case .flights:
                // +1 row is for section header: Should be handled as TableView Header
                return viewModel.executionInfoProvider.flights.isEmpty ? 0 : 1 + viewModel.executionInfoProvider.flights.count
            case .actions:
                return viewModel.actions.count
            }
        case .none:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section) {
        case .none:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.textLabel?.text = indexPath.description
            cell.backgroundColor = .clear
            return cell
        case .info:
            return infoCell(forIndexPath: indexPath,
                            tableView: tableView)
        case .executions:
            return executionsCell(forIndexPath: indexPath,
                                  tableView: tableView)
        case .settings:
            return settingsCell(forIndexPath: indexPath,
                                tableView: tableView)
        case .flights:
            return flightsCell(forIndexPath: indexPath,
                                tableView: tableView)
        case .actions:
            return actionsCell(forIndexPath: indexPath,
                               tableView: tableView)
        case .status:
            return statusCell(forIndexPath: indexPath,
                               tableView: tableView)
        }
    }

    private func infoCell(forIndexPath indexPath: IndexPath,
                          tableView: UITableView) -> UITableViewCell {
        let cell: FlightDetailsInfoCell = tableView.dequeueReusableCell(for: indexPath)
        switch viewModel {
        case .details(let viewModel):
            cell.configure(with: viewModel)
        case .execution(let viewModel):
            cell.configure(with: viewModel.executionInfoProvider)
        case .none:
            break
        }
        return cell
    }

    private func executionsCell(forIndexPath indexPath: IndexPath,
                                tableView: UITableView) -> UITableViewCell {
        let cell: FlightDetailsExecutionsCell = tableView.dequeueReusableCell(for: indexPath)
        switch viewModel {
        case .details(let viewModel):
            cell.fill(with: viewModel, at: indexPath.row)
        default:
            break
        }
        return cell
    }

    private func settingsCell(forIndexPath indexPath: IndexPath,
                              tableView: UITableView) -> UITableViewCell {
        let cell: FlightExecutionDetailsSettingsCell = tableView.dequeueReusableCell(for: indexPath)
        switch viewModel {
        case .execution(let viewModel):
            let provider = viewModel.executionSettingsProvider
            cell.fill(provider: provider)
        default:
            break
        }
        return cell
    }

    private func flightsCell(forIndexPath indexPath: IndexPath,
                             tableView: UITableView) -> UITableViewCell {
        guard case .execution(let viewModel) = viewModel else { return UITableViewCell() }
        if indexPath.row == 0 {
            let header: FlightDetailsSectionHeaderCell = tableView.dequeueReusableCell(for: indexPath)
            header.fill(with: viewModel.flightsSectionHeaderModel)
            return header
        } else {
            let cell: FlightExecutionDetailsFlightsCell = tableView.dequeueReusableCell(for: indexPath)
            cell.fill(with: viewModel.flightCellModelForFlight(at: indexPath.row - 1))
            return cell
        }
    }

    private func actionsCell(forIndexPath indexPath: IndexPath,
                             tableView: UITableView) -> UITableViewCell {
        let cell: FlightDetailsActionCell = tableView.dequeueReusableCell(for: indexPath)
        cell.delegate = self
        switch viewModel {
        case .none:
            break
        case .details(let viewModel):
            cell.configure(with: viewModel.actions[indexPath.row])
        case .execution(let viewModel):
            cell.configure(with: viewModel.actions[indexPath.row])
        }

        return cell
    }

    private func statusCell(forIndexPath indexPath: IndexPath,
                            tableView: UITableView) -> UITableViewCell {
        guard case .execution(let viewModel) = viewModel else { return UITableViewCell() }
        let cell: FlightExecutionDetailsStatusCell = tableView.dequeueReusableCell(for: indexPath)
        cell.fill(with: viewModel.statusCellModel)
        return cell
    }
}

// MARK: - UITableViewDelegate
// TODO: Improve this quick way to add a separator
extension FlightDetailsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch Section(rawValue: section) {
        case .actions:
            return header()
        case .status:
            guard case .execution = viewModel else { return nil }
            return header()
        case .executions:
            guard case let .details(viewModel) = viewModel, !viewModel.flightPlans.isEmpty else { return nil }
            return header(with: L10n.dashboardMyFlightsSectionPlans)
        default:
            break
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch Section(rawValue: section) {
        case .actions:
            return header().frame.height
        case .status:
            guard case .execution = viewModel else { return CGFloat.leastNonzeroMagnitude }
            return header().frame.height
        case .executions:
            guard case let .details(viewModel) = viewModel, !viewModel.flightPlans.isEmpty else { return CGFloat.leastNonzeroMagnitude }
            return header(with: L10n.dashboardMyFlightsSectionPlans).frame.height
        default:
            break
        }
        return CGFloat.leastNonzeroMagnitude
    }

    private func header(with title: String? = nil) -> UIView {
        let headerSize = CGSize(width: rightTableView.frame.width,
                                height: Constants.tableViewHeaderLineTopMargin +
                                    Constants.tableViewHeaderLineHeight +
                                    Constants.tableViewHeaderLineBottomMargin +
                                    (title == nil ? 0 : Constants.tableViewHeaderLabelSize + Constants.tableViewHeaderBottomMargin ))

        let header = UIView(frame: CGRect(origin: .zero,
                                          size: headerSize))
        header.backgroundColor = .clear

        let line = UIView(frame: CGRect(origin: CGPoint(x: 0,
                                                        y: Constants.tableViewHeaderLineTopMargin),
                                        size: CGSize(width: rightTableView.frame.width,
                                                     height: Constants.tableViewHeaderLineHeight)))
        line.backgroundColor = ColorName.defaultTextColor20.color
        header.addSubview(line)

        if let title = title {
            let label = UILabel(frame: CGRect(origin: CGPoint(x: Constants.tableViewHeaderLabelHorizontalMargin,
                                                              y: Constants.tableViewHeaderLineTopMargin +
                                                                Constants.tableViewHeaderLineHeight +
                                                                Constants.tableViewHeaderLineBottomMargin),
                                              size: CGSize(width: rightTableView.frame.width - Constants.tableViewHeaderLabelHorizontalMargin*2,
                                                           height: Constants.tableViewHeaderLabelSize)))
            label.makeUp(with: .largeMedium, and: .defaultTextColor80)
            label.text = title
            header.addSubview(label)
        }
        return header
    }
}

extension FlightDetailsViewController: FlightDetailsActionCellDelegate {
    func flightDetailsCellAction(_ action: FlightDetailsActionCellModel.Action) {
        switch (viewModel, action) {
        case (.details(let viewModel), .share):
            shareFile(data: viewModel.shareFileData,
                      name: viewModel.shareFileName,
                      fileExtension: GutmaConstants.extensionName)
        case (.details(let viewModel), .delete):
            viewModel.askForDeletion()
        case (.execution(let viewModel), .delete):
            viewModel.askForDeletion()
        default:
            break
        }
    }
}
