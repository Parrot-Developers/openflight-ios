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
import Combine

/// Manages a flight plan list.
final class FlightPlanDashboardListViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var emptyFlightPlansTitleLabel: UILabel!
    @IBOutlet private weak var emptyFlightPlansDescriptionLabel: UILabel!
    @IBOutlet private weak var emptyLabelContainer: UIView!
    @IBOutlet private weak var emptyExecutionLabel: UILabel!
    @IBOutlet private weak var openProjectButton: UIButton!

    typealias ViewModel = (FlightPlansListViewModelUIInput & FlightPlanListHeaderDelegate & FlightPlansListViewModelParentInput)

    // MARK: - Internal Properties
    private var viewModel: ViewModel!
    private var cancellables = [AnyCancellable]()

    struct SelectedProject {
        let project: ProjectModel
        let executions: [FlightPlanModel]
        let index: Int
    }
    private var selectedProject: SelectedProject? {
        didSet {
            tableView.reloadData()
            emptyExecutionLabel.isHidden = selectedProject?.executions.count ?? 0 > 0
            openProjectButton.isHidden = selectedProject == nil
        }
    }

    func setupViewModel(with viewModel: ViewModel) {
        self.viewModel = viewModel
        self.viewModel.initViewModel()
    }

    func setupViewModel(with viewModel: ViewModel,
                        delegate: FlightPlansListViewModelDelegate) {
        self.viewModel = viewModel
        viewModel.setupDisplayMode(with: .dashboard)
        self.viewModel.setupDelegate(with: delegate)
        self.viewModel.initViewModel()
    }

    private func bindViewModel() {
        viewModel.allFlightPlansPublisher
            .sink { [unowned self] allFlightPlans in
                // Keep current selection if project still exist
                if let project = selectedProject?.project,
                   let projectIndex = allFlightPlans.firstIndex(where: { $0.uuid == project.uuid }) {
                    didSelectProject(allFlightPlans[projectIndex], at: projectIndex)
                } else {
                    didDeselectProject()
                }
                collectionView?.reloadData()
                emptyLabelContainer.isHidden = self.viewModel.modelsCount() > 0
                emptyExecutionLabel.isHidden = self.selectedProject?.executions.count ?? 0 > 0
            }
            .store(in: &cancellables)

        viewModel.uuidPublisher
            .sink { [unowned self] _ in
                self.collectionView?.reloadData()
            }
            .store(in: &cancellables)
    }

    // MARK: - Private Enums
    private enum Constants {
        static let nbColumnsLandscapeFull: CGFloat = 4.0
        static let nbColumnsLandscapeCompact: CGFloat = 3.0
        static let nbColumnsPortrait: CGFloat = 2.0
        static let itemSpacing: CGFloat = 10.0
        static let headerHeight: CGFloat = 50.0
        static let topTableInset: CGFloat = 5.0
        static let bottomTableInset: CGFloat = 10.0
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(FlightPlanListReusableHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: FlightPlanListReusableHeaderView.identifier)
        collectionView.register(cellType: FlightPlanCollectionViewCell.self)
        collectionView.delegate = self
        collectionView.dataSource = self
        tableView.register(cellType: FlightPlanExecutionCell.self)
        tableView.register(cellType: FlightPlanListExecutionHeaderCell.self)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.contentInset = UIEdgeInsets(top: Constants.topTableInset,
                                              left: 0,
                                              bottom: Constants.bottomTableInset + openProjectButton.bounds.height,
                                              right: 0)
        emptyFlightPlansTitleLabel.text = L10n.flightPlanEmptyListTitle
        emptyFlightPlansDescriptionLabel.text = L10n.flightPlanEmptyListDesc
        emptyExecutionLabel.text = L10n.dashboardMyFlightsEmptyProjectExecutionsList

        openProjectButton.layer.cornerRadius = Style.largeCornerRadius
        openProjectButton.titleLabel?.makeUp(with: .large, and: .white)
        openProjectButton.setTitle(L10n.dashboardMyFlightsProjectExecutionOpenProject,
                                   for: .normal)
        openProjectButton.isHidden = true
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.collectionView.reloadData()
        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.flightPlanList,
                             logType: .screen)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        // Update layout when orientation changed.
        collectionView.collectionViewLayout.invalidateLayout()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    func didSelectProject(_ project: ProjectModel, at index: Int) {
        let executions = viewModel.flightPlanExecutions(ofProject: project)
        selectedProject = SelectedProject(project: project,
                                          executions: executions,
                                          index: index)
        viewModel.selectedProject(project)
    }

    func didDeselectProject() {
        selectedProject = nil
        viewModel.deselectProject()
    }

    @IBAction private func openProjectAction() {
        guard let selectedProject = selectedProject else { return }
        viewModel.openProject(at: selectedProject.index)
    }
}

// MARK: - UICollectionViewDataSource
extension FlightPlanDashboardListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.modelsCount()
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(for: indexPath) as FlightPlanCollectionViewCell
        guard let cellProvider = viewModel.getFlightPlan(at: indexPath.row) else { return cell }
        cell.configureCell(project: cellProvider.project,
                           isSelected: cellProvider.isSelected,
                           index: indexPath.row)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        guard let header = collectionView
                .dequeueReusableSupplementaryView(ofKind: kind,
                                                  withReuseIdentifier: FlightPlanListReusableHeaderView.identifier,
                                                  for: indexPath) as? FlightPlanListReusableHeaderView
        else { return UICollectionReusableView() }
        header.configure(provider: viewModel.getHeaderProvider(), delegate: viewModel)
        return header
    }

}

// MARK: - UICollectionViewDelegate
extension FlightPlanDashboardListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let projectProvider = viewModel.getFlightPlan(at: indexPath.row) else {
            return
        }
        didSelectProject(projectProvider.project, at: indexPath.row)
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        didDeselectProject()
    }
}

// MARK: - UICollectionViewDataSource
extension FlightPlanDashboardListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let selectedProject = self.selectedProject else { return 0 }
        // header + executions
        return 1 + selectedProject.executions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let header: FlightPlanListExecutionHeaderCell = tableView.dequeueReusableCell(for: indexPath)
            if let selected = selectedProject {
                header.fill(project: selected.project,
                            executions: selected.executions.count)
            }
            return header
        } else {
            let cell: FlightPlanExecutionCell = tableView.dequeueReusableCell(for: indexPath)
            if let execution = selectedProject?.executions[indexPath.row - 1] {
                cell.fill(execution: execution)
            }
            return cell
        }
    }
}

// MARK: - UITableViewDelegate
extension FlightPlanDashboardListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let execution = selectedProject?.executions[indexPath.row - 1] else {
            return
        }
        viewModel.selectedExecution(execution)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension FlightPlanDashboardListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // remove left and right insets.
        let collectionViewWidth = collectionView.frame.width
            - 2 * Constants.itemSpacing
            - (collectionView.safeAreaInsets.left + collectionView.safeAreaInsets.right)
        let nbColumnsLadscape = (viewModel.displayMode == .full || viewModel.displayMode == .dashboard)
            ? Constants.nbColumnsLandscapeFull : Constants.nbColumnsLandscapeCompact
        let nbColumns = UIApplication.isLandscape ? nbColumnsLadscape : Constants.nbColumnsPortrait
        let width = (collectionViewWidth / nbColumns - Constants.itemSpacing).rounded(.down)
        let size = CGSize(width: width, height: width)
        return size
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        switch viewModel.displayMode {
        case .full, .dashboard:
            return .init(width: self.collectionView.frame.width, height: Constants.headerHeight)
        default:
            return .zero
        }
    }
}
