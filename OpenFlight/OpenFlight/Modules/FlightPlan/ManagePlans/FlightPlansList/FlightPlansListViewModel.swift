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
}

/// Struct used in order to pass the necessary information to the `CellFlightPlanList`
struct CellFlightPlanListProvider {
    /// Selected state
    var isSelected: Bool
    /// flightPlan model
    var flightPlan: FlightPlanViewModel
}

// MARK: - Protocols
protocol FlightPlansListViewModelDelegate: AnyObject {
    /// Called when user selects a Flight Plan.
    func didSelect(flightPlan: FlightPlanViewModel)
    /// Called when user double tap on a flight plan
    func didDoubleTapOn(flightplan: FlightPlanViewModel)
}

/// Protocol allow to communicate from UIViewController to ViewModel
protocol FlightPlansListViewModelUIInput {

    /// Displaying Controller on `Compact` or `Full`
    var displayMode: FlightPlansListDisplayMode { get }

    /// Publisher that give new value of UUID
    var uuidPublisher: AnyPublisher<String?, Never> { get }

    /// Publisher that give  value of changed array of flight plan ViewModel
    var allFlightPlansPublisher: AnyPublisher<[FlightPlanViewModel], Never> { get }

    /// Select flight plan from flight Plans array.
    ///
    /// - Parameters:
    ///     - index: Choosed index
    func selectedItem(at index: Int)

    /// Setup corresponding delegate of type `FlightPlansListViewModelDelegate`
    ///
    /// - Parameters:
    ///     - delegate: Handle selection of flight plan
    func setupDelegate(with delegate: FlightPlansListViewModelDelegate)

    /// Initialize ViewModel at beginning
    func initialized()

    /// Select flight plan from flight Plans array.
    ///
    /// - Parameters:
    ///     - delegate: Handle selection of flight plan
    func getFlightPlan(at index: Int) -> CellFlightPlanListProvider?

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
    ///     - models: Array of FlightplanViewModel
    func setupFlightPlans(with models: [FlightPlanViewModel])

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
    @Published private var filtredFlightPlan: [FlightPlanViewModel] = [FlightPlanViewModel]()
    private var allFlightPlans: [FlightPlanViewModel] = [FlightPlanViewModel]()
    private var headerProvider: [FlightPlanListHeaderCellProvider] = []
    private(set) var displayMode: FlightPlansListDisplayMode = .full
    private let persistence: FlightPlanDataProtocol
    private weak var delegate: FlightPlansListViewModelDelegate?

    init(persistence: FlightPlanDataProtocol) {
        self.persistence = persistence
    }

    // MARK: - Private funcs
    private func getAllFlightPlans() -> [FlightPlanViewModel] {
        return persistence.loadAllFlightPlanViewModels(predicate: nil)
    }

    private func didSelect(flightPlan: FlightPlanViewModel) {
        uuid = flightPlan.state.value.uuid
    }

    /// Construct array of `FlightPlanListHeaderCellProvider` from given array of `FlightPlanViewModel`
    private func buildHeader(_ flights: [FlightPlanViewModel]) {
        headerProvider = flights
            // Return array of `FlightPlanState`
            .compactMap { $0.state.value }
            // Return array of `FlightPlanListHeaderCellProvider`
            .reduce([FlightPlanListHeaderCellProvider](), { result, value in
                // Updating cell provider if existing
                if let provider = result.first(where: { $0.missionType == value.type?.missionProvider.mission.name }) {
                    var otherProvider = provider
                    otherProvider.count = provider.count + 1
                    var otherResult = result
                    otherResult.removeAll { $0.missionType == provider.missionType }
                    otherResult.append(otherProvider)
                    return otherResult
                }

                // Creat new cell provider
                let provider = FlightPlanListHeaderCellProvider(
                    uuid: value.uuid ?? UUID().uuidString,
                    count: 1,
                    missionType: value.type?.missionProvider.mission.name,
                    logo: value.type?.missionProvider.mission.icon,
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
    func openProject(at index: Int) {
        self.selectedItem(at: index)
        self.delegate?.didDoubleTapOn(flightplan: filtredFlightPlan[index])
    }

    var uuidPublisher: AnyPublisher<String?, Never> {
        $uuid.eraseToAnyPublisher()
    }

    var allFlightPlansPublisher: AnyPublisher<[FlightPlanViewModel], Never> {
        $filtredFlightPlan.eraseToAnyPublisher()
    }

    func selectedItem(at index: Int) {
        guard index < filtredFlightPlan.count else { return }
        let flightPlan = filtredFlightPlan[index]
        didSelect(flightPlan: flightPlan)
        delegate?.didSelect(flightPlan: flightPlan)
    }

    func setupDelegate(with delegate: FlightPlansListViewModelDelegate) {
        self.delegate = delegate
    }

    func initialized() {
        let flight = getAllFlightPlans()
        switch displayMode {
        case .full:
            allFlightPlans = flight
            buildHeader(allFlightPlans)
            filtredFlightPlan = allFlightPlans
        case .compact:
            filtredFlightPlan = flight
        }
    }

    func getFlightPlan(at index: Int) -> CellFlightPlanListProvider? {
        if index < filtredFlightPlan.count {
            let flightPlan = filtredFlightPlan[index]
            let isSelected = displayMode == .full ? false : uuid == flightPlan.state.value.uuid
            return CellFlightPlanListProvider(isSelected: isSelected, flightPlan: flightPlan)
        }

        return nil
    }

    func modelsCount() -> Int {
        filtredFlightPlan.count
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

    func setupFlightPlans(with models: [FlightPlanViewModel]) {
        allFlightPlans = models
        buildHeader(models)
        filtredFlightPlan = allFlightPlans
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

            filtredFlightPlan = allFlightPlans.filter({ provider.missionType == $0.state.value.type?.missionProvider.mission.name })
        }

        // if `currentProvider` was `true` before selection then rollback to all flight plan
        else {
            filtredFlightPlan = allFlightPlans
        }
    }
}
