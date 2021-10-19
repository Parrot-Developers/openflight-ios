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

import Foundation
import Combine

/// Describes FlightPlansList ViewController display mode.
enum FlightPlansListDisplayMode {
    /// Full screen.
    case full
    /// Part of a sub view controller.
    case compact
    /// Part of of the view controller is visible but all executions should be loaded
    case dashboard
}

/// Struct used in order to pass the necessary information to the `CellFlightPlanList`
struct CellFlightPlanListProvider {
    /// Selected state
    var isSelected: Bool
    /// project model
    var project: ProjectModel
}

// MARK: - Protocols
protocol FlightPlansListViewModelDelegate: AnyObject {
    /// Called when user selects a `ProjectModel`.
    func didSelect(project: ProjectModel)
    /// Called when user selects a `FlightPlanModel`.
    func didSelect(execution: FlightPlanModel)
    /// Called when user double tap on a project
    func didDoubleTap(on project: ProjectModel)
}

/// Protocol allow to communicate from UIViewController to ViewModel
protocol FlightPlansListViewModelUIInput {

    /// Displaying Controller on `Compact` or `Full`
    var displayMode: FlightPlansListDisplayMode { get }

    /// Publisher that give new value of UUID
    var uuidPublisher: AnyPublisher<String?, Never> { get }

    /// Publisher that give  value of changed array of `ProjectModel`
    var allFlightPlansPublisher: AnyPublisher<[ProjectModel], Never> { get }

    /// Select flight plan from flight Plans array.
    ///
    /// - Parameters:
    ///     - index: Choosed index
    func selectedItem(at index: Int)

    /// Select project.
    ///
    /// - Parameters:
    ///     - project: The project model
    func selectedProject(_ project: ProjectModel)

    /// Deselect project.
    func deselectProject()

    /// Select flight plan execution from flight Plans executions array.
    ///
    /// - Parameters:
    ///     - execution: the flight plan model representing the execution
    func selectedExecution(_ execution: FlightPlanModel)

    /// Setup corresponding delegate of type `FlightPlansListViewModelDelegate`
    ///
    /// - Parameters:
    ///     - delegate: Handle selection of flight plan
    func setupDelegate(with delegate: FlightPlansListViewModelDelegate)

    /// Initialize ViewModel at beginning
    func initViewModel()

    /// Select flight plan from flight Plans array.
    ///
    /// - Parameters:
    ///     - delegate: Handle selection of flight plan
    func getFlightPlan(at index: Int) -> CellFlightPlanListProvider?

    /// Retrieve flight plan executions from project.
    ///
    /// - Parameters:
    ///     - project: The project to retrieve execution for.
    func flightPlanExecutions(ofProject project: ProjectModel) -> [FlightPlanModel]

    /// Return number of flight plan available
    func modelsCount() -> Int

    /// Return corresponding Header provider to display it on Header
    func getHeaderProvider() -> [FlightPlanListHeaderCellProvider]

    /// Double tap on a flight plan
    ///
    /// - Parameters:
    ///     - index: index of selected flight plan
    func openProject(at index: Int)
}

/// Protocol allow to communicate from Parent ViewModel to Child ViewModel
protocol FlightPlansListViewModelParentInput {

    /// Update uuid with corresponding entry.
    ///
    /// - Parameters:
    ///     - uuid: Optioanl String value, to update new uuid
    func updateUUID(with uuid: String?)

    /// Update array of flight plans
    ///
    /// - Parameters:
    ///     - models: Array of `ProjectModel`
    func setupProjects(with models: [ProjectModel])

    /// Setup new display mode to corresponding View
    ///
    /// - Parameters:
    ///     - mode: FlightPlansListDisplayMode
    func setupDisplayMode(with mode: FlightPlansListDisplayMode)

    /// Setup corresponding delegate of type `FlightPlansListViewModelDelegate`
    ///
    /// - Parameters:
    ///     - delegate: Handle selection of flight plan
    func setupDelegate(with delegate: FlightPlansListViewModelDelegate)
}

final class FlightPlansListViewModel {

    // MARK: - Private variables
    @Published private var uuid: String?
    @Published private var filteredFlightPlan: [ProjectModel] = [ProjectModel]()
    private var allFlightPlans: [ProjectModel] = [ProjectModel]()
    private var headerProvider: [FlightPlanListHeaderCellProvider] = []
    private(set) var displayMode: FlightPlansListDisplayMode = .full
    private weak var delegate: FlightPlansListViewModelDelegate?
    private var flightPlanTypeStore: FlightPlanTypeStore
    private let manager: ProjectManager
    private var cancellable = Set<AnyCancellable>()

    init(manager: ProjectManager,
         flightPlanTypeStore: FlightPlanTypeStore,
         cloudSynchroWatcher: CloudSynchroWatcher?) {
        self.manager = manager
        self.flightPlanTypeStore = flightPlanTypeStore

        cloudSynchroWatcher?.isSynchronizingDataPublisher.sink(receiveValue: { [unowned self] isSynchronizingData in
            if !isSynchronizingData {
                self.initViewModel()
            }
        }).store(in: &cancellable)
    }

    // MARK: - Private funcs
    private func getAllFlightPlans() -> [ProjectModel] {
        if displayMode == .compact {
            return manager.loadProjects(type: Services.hub.currentMissionManager.mode.flightPlanProvider?.projectType)
        } else {
            return manager.loadExecutedProjects()
        }
    }

    private func didSelect(project: ProjectModel) {
        updateUUID(with: project.uuid)
    }

    private func didDeselectProjects() {
        updateUUID(with: nil)
    }

    /// Construct array of `FlightPlanListHeaderCellProvider` from given array of `ProjectModel`
    private func buildHeader(_ projects: [ProjectModel]) {
        headerProvider = projects
            // Return array of `FlightPlanListHeaderCellProvider`
            .reduce([FlightPlanListHeaderCellProvider](), { result, value in
                // Updating cell provider if existing
                let flightStoreProvider = getFligthPlanType(with: manager.lastFlightPlan(for: value)?.type)
                if let provider = result.first(where: { $0.missionType == flightStoreProvider?.missionProvider.mission.name }) {
                    var otherProvider = provider
                    otherProvider.count = provider.count + 1
                    var otherResult = result
                    otherResult.removeAll { $0.missionType == provider.missionType }
                    otherResult.append(otherProvider)
                    return otherResult
                }

                // Creat new cell provider
                let provider = FlightPlanListHeaderCellProvider(
                    uuid: value.uuid,
                    count: 1,
                    missionType: flightStoreProvider?.missionProvider.mission.name,
                    logo: flightStoreProvider?.missionProvider.mission.icon,
                    isSelected: false
                )
                var otherResult = result
                otherResult.append(provider)
                return otherResult
            })
    }
}

// MARK: - FlightPlansListViewModelUIInput
extension FlightPlansListViewModel: FlightPlansListViewModelUIInput {

    func flightPlanExecutions(ofProject project: ProjectModel) -> [FlightPlanModel] {
        manager.executedFlightPlans(for: project)
    }

    func selectedProject(_ project: ProjectModel) {
        didSelect(project: project)
    }

    func deselectProject() {
        didDeselectProjects()
    }

    func openProject(at index: Int) {
        self.selectedItem(at: index)
        self.delegate?.didDoubleTap(on: filteredFlightPlan[index])
    }

    var uuidPublisher: AnyPublisher<String?, Never> {
        $uuid.eraseToAnyPublisher()
    }

    var allFlightPlansPublisher: AnyPublisher<[ProjectModel], Never> {
        $filteredFlightPlan.eraseToAnyPublisher()
    }

    func selectedItem(at index: Int) {
        guard index < filteredFlightPlan.count else { return }
        let flightPlan = filteredFlightPlan[index]
        didSelect(project: flightPlan)
        delegate?.didSelect(project: flightPlan)
    }

    func selectedExecution(_ execution: FlightPlanModel) {
        delegate?.didSelect(execution: execution)
    }

    func setupDelegate(with delegate: FlightPlansListViewModelDelegate) {
        self.delegate = delegate
    }

    func initViewModel() {
        let flight = getAllFlightPlans()
        switch displayMode {
        case .full, .dashboard:
            allFlightPlans = flight
            buildHeader(allFlightPlans)
            filteredFlightPlan = allFlightPlans
        case .compact:
            filteredFlightPlan = flight
        }
    }

    func getFlightPlan(at index: Int) -> CellFlightPlanListProvider? {
        if index < filteredFlightPlan.count {
            let project = filteredFlightPlan[index]
            let isSelected = displayMode == .full ? false : uuid == project.uuid
            return CellFlightPlanListProvider(isSelected: isSelected, project: project)
        }

        return nil
    }

    func modelsCount() -> Int {
        filteredFlightPlan.count
    }

    func getHeaderProvider() -> [FlightPlanListHeaderCellProvider] {
        return headerProvider
    }
}

// MARK: - FlightPlansListViewModelParentInput
extension FlightPlansListViewModel: FlightPlansListViewModelParentInput {
    func updateUUID(with selectedUUID: String?) {
        uuid = selectedUUID
    }

    func setupProjects(with models: [ProjectModel]) {
        allFlightPlans = getAllFlightPlans()
        buildHeader(getAllFlightPlans())
        filteredFlightPlan = allFlightPlans
    }

    func setupDisplayMode(with mode: FlightPlansListDisplayMode) {
        displayMode = mode
    }
}

// MARK: - FlightPlanListHeaderDelegate
extension FlightPlansListViewModel: FlightPlanListHeaderDelegate {
    func didSelectItemAt(_ provider: FlightPlanListHeaderCellProvider) {
        // get currentProvider and index
        guard let currentProvider = headerProvider.first(where: { $0.uuid == provider.uuid }),
              let index = headerProvider.firstIndex(of: currentProvider) else { return }

        // Set all element to false
        headerProvider = headerProvider.map { value in
            var element = value
            element.isSelected = false
            return element
        }

        // Set selected element on current selected value
        headerProvider[index].isSelected = provider.isSelected

        // if `currentProvider` was `false` before selection then filter the flight plans
        if currentProvider.isSelected == false {
            filteredFlightPlan = allFlightPlans.filter {
                let type = getFligthPlanType(with: manager.lastFlightPlan(for: $0)?.type)
                return provider.missionType == type?.missionProvider.mission.name
            }
        }

        // if `currentProvider` was `true` before selection then rollback to all flight plan
        else {
            filteredFlightPlan = allFlightPlans
        }
    }
}

private extension FlightPlansListViewModel {
    func getFligthPlanType(with type: String?) -> FlightPlanType? {
        return Services.hub.flightPlan.typeStore.typeForKey(type)
    }
}
