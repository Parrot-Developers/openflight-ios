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
    @IBOutlet private weak var openProjectButton: ActionButton!
    @IBOutlet private weak var bottomGradientView: BottomGradientView!
    private var isFirstLoad: Bool = true

    typealias ViewModel = (FlightPlansListViewModelUIInput & FlightPlanListHeaderDelegate & FlightPlansListViewModelParentInput)

    // MARK: - Internal Properties
    private var viewModel: ViewModel!
    private var cancellables = [AnyCancellable]()

    struct SelectedProject {
        let project: ProjectModel
        let executions: [FlightPlanModel]
        let index: Int
        var selectedExecutionUuid: String?
    }
    private var selectedProject: SelectedProject? {
        didSet {
            tableView.reloadData()
            emptyExecutionLabel.isHidden = selectedProject?.executions.count ?? 0 > 0
            openProjectButton.isHidden = selectedProject == nil
            bottomGradientView.isHidden = selectedProject == nil
            updateTableViewBottomInset(isButtonVisible: !openProjectButton.isHidden)
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
        viewModel.allProjectsPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.collectionView?.reloadData()
                self.emptyLabelContainer.isHidden = self.viewModel.projectsCount() > 0
                self.emptyExecutionLabel.isHidden = self.selectedProject?.executions.count ?? 0 > 0
            }
            .store(in: &cancellables)

        viewModel.uuidPublisher
            .receive(on: RunLoop.main)
            .dropFirst() // do not fire on initialization
            .sink { [unowned self] _ in
                collectionView?.reloadData()
            }
            .store(in: &cancellables)
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        // Collection view setup
        collectionView.register(FlightPlanListReusableHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: FlightPlanListReusableHeaderView.identifier)
        collectionView.register(cellType: FlightPlanCollectionViewCell.self)
        collectionView.delegate = self
        collectionView.dataSource = self

        // Add double tap gesture recognizer for flight plan quick open action.
        collectionView.addDoubleTapRecognizer(target: self, action: #selector(didDoubleTap))

        // Table view setup
        tableView.register(cellType: FlightPlanExecutionCell.self)
        tableView.register(cellType: FlightPlanListExecutionHeaderCell.self)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.insetsContentViewsToSafeArea = false
        tableView.preservesSuperviewLayoutMargins = false
        updateTableViewBottomInset()
        emptyFlightPlansTitleLabel.text = L10n.dashboardMyFlightsEmptyProjectExecutionsTitle
        emptyFlightPlansDescriptionLabel.text = L10n.dashboardMyFlightsEmptyListDesc
        emptyExecutionLabel.text = L10n.dashboardMyFlightsEmptyProjectExecutionsList
        emptyLabelContainer.isHidden = true

        // Right panel button button
        openProjectButton.setup(title: L10n.dashboardMyFlightsProjectExecutionOpenProject,
                                style: .validate)
        openProjectButton.isHidden = true

        bottomGradientView.shortGradient()
        bottomGradientView.isHidden = true

        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // If a prject was already selected, refresh his execution list.
        if let selectedProject = selectedProject {
            didSelectProject(selectedProject.project,
                             at: selectedProject.index,
                             selectedExecutionUuid: selectedProject.selectedExecutionUuid)
        }
        LogEvent.log(.screen(LogEvent.Screen.flightPlanList))
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        if isFirstLoad {
            scrollToSelectedProject()
            isFirstLoad = false
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        // Update layout when orientation changed.
        collectionView.collectionViewLayout.invalidateLayout()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    /// Handles collectionView item selection.
    ///
    /// - Parameters:
    ///    - index: The collectionView's index of selected item.
    func didSelectItemAt(_ index: Int) {
        guard let projectProvider = viewModel.projectProvider(at: index) else {
            return
        }
        didSelectProject(projectProvider.project, at: index)
        viewModel?.updateNavigationStack(with: projectProvider.project)
    }

    func didSelectProject(_ project: ProjectModel, at index: Int, selectedExecutionUuid: String? = nil) {
        let executions = viewModel.flightPlanExecutions(ofProject: project)
        selectedProject = SelectedProject(project: project,
                                          executions: executions,
                                          index: index,
                                          selectedExecutionUuid: selectedExecutionUuid)
        viewModel.selectProject(project)
    }

    func didSelectProject(_ project: ProjectModel) {
        let index = viewModel.indexOfProject(project)
        didSelectProject(project, at: index)
    }

    func didDeselectProject() {
        selectedProject = nil
        viewModel.deselectProject()
    }

    func scrollToSelectedProject() {
        guard let selectedProject = selectedProject else {
            return
        }
        if let index = viewModel.getProjectIndex(forSelectedProject: selectedProject.project) {
            collectionView.reloadData()
            collectionView.scrollToItem(at: IndexPath(row: index, section: 0),
                                        at: .centeredVertically,
                                        animated: true)
        } else {
            self.didDeselectProject()
        }
    }

    @IBAction private func openProjectAction() {
        guard let selectedProject = selectedProject else { return }
        viewModel.openProject(at: selectedProject.index)
    }

    /// Updates the tableView bottom inset according to bottom button state.
    ///
    /// - Parameters:
    ///    - isButtonVisible: `true` if bottom action button is visible, `false` otherwise
    private func updateTableViewBottomInset(isButtonVisible: Bool = false) {
        let bottomPadding = isButtonVisible
        ? Layout.buttonIntrinsicHeight(isRegularSizeClass) + Layout.mainSpacing(isRegularSizeClass)
        : 0
        tableView.contentInset.bottom = Layout.mainContainerInnerMargins(isRegularSizeClass).bottom + bottomPadding
    }
}

// MARK: - UICollectionViewDataSource
extension FlightPlanDashboardListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.projectsCount()
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(for: indexPath) as FlightPlanCollectionViewCell
        guard let cellProvider = viewModel.projectProvider(at: indexPath.row) else { return cell }
        cell.configureCell(project: cellProvider.project,
                           isSelected: cellProvider.isSelected)

        viewModel.shouldGetMoreProjects(fromIndexPath: indexPath)

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
        header.configure(provider: viewModel.headerCellProvider(), delegate: viewModel)
        return header
    }

}

// MARK: - UICollectionViewDelegate
extension FlightPlanDashboardListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        didSelectItemAt(indexPath.item)
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        didDeselectProject()
        viewModel?.updateNavigationStack(with: nil)
    }
}

// MARK: - UICollectionViewDataSource
extension FlightPlanDashboardListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let selectedProject = selectedProject else { return 0 }
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

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard indexPath.row > 0 else { return }
        if let selectedExecutionUuid = selectedProject?.selectedExecutionUuid,
               selectedExecutionUuid == selectedProject?.executions[indexPath.row - 1].uuid {
                cell.setSelected(true, animated: true)
        }
    }
}

// MARK: - UITableViewDelegate
extension FlightPlanDashboardListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let execution = selectedProject?.executions[indexPath.row - 1] else {
            return
        }
        selectedProject?.selectedExecutionUuid = execution.uuid
        viewModel.selectExecution(execution)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension FlightPlanDashboardListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        collectionView.gridItemSize()
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        switch viewModel.displayMode {
        case .dashboard:
            return .init(width: collectionView.bounds.width,
                         height: Layout.fileFilterCollectionViewCellHeight(isRegularSizeClass) +
                         Layout.mainBottomMargin(isRegularSizeClass))
        default:
            return .zero
        }
    }
}

extension FlightPlanDashboardListViewController {
    /// Collectionview's double tap action.
    /// Opens a filght plan if a double tap is detected on corresponding cell.
    ///
    /// - Parameters:
    ///    - sender: The double tap gesture recognizer.
    @objc func didDoubleTap(_ sender: UIGestureRecognizer) {
        // Get cell's index.
        guard let index = collectionView.indexPathForItem(at: sender.location(in: collectionView))?.item else { return }
        didSelectItemAt(index)
        viewModel.openProject(at: index)
    }
}
