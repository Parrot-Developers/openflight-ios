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

import Foundation
import Combine

/// Screen types enum
public enum NavigationStackScreen {
    case dashboard
    case projectManager(selectedProject: ProjectModel?)
    case myFlights(selectedFlight: FlightModel?)
    case myFlightsExecutedProjects(selectedProject: ProjectModel?)
    case flightDetails(flight: FlightModel)
    case flightPlanDetails(flightPlan: FlightPlanModel)

    var description: String {
        switch self {
        case .dashboard:
            return "Dashboard"
        case .projectManager(let selectedProject):
            return "projectManager (selectedProject: \(selectedProject?.uuid ?? ""))"
        case .myFlights(let selectedFlight):
            return "myFlights (selectedFlight: \(selectedFlight?.uuid ?? ""))"
        case .myFlightsExecutedProjects(let selectedProject):
            return "myFlights (selectedProject: \(selectedProject?.uuid ?? ""))"
        case .flightDetails(let flight):
            return "flightDetails (flight: \(flight.uuid))"
        case .flightPlanDetails(let flightPlan):
            return "flightPlanDetails (flightPlan: \(flightPlan.uuid))"
        }
    }
}

/// App Navigation Stack Service: Handle different kind of scenario to go back
/// to previous presented view.
public protocol NavigationStackService: AnyObject {

    /// Indicates if user has already performed a navigation action
    var startedToNavigate: Bool { get }
    /// Publisher of startedToNavigate
    var startedToNavigatePublisher: AnyPublisher<Bool, Never> { get }
    /// Stack containing previous displayed screens
    var stack: [NavigationStackScreen] { get }
    /// Publisher for stack
    var stackPublisher: AnyPublisher<[NavigationStackScreen], Never> { get }
    /// Returns the previous stack before a clearStack
    var stackBeforeClear: [NavigationStackScreen] { get }

    /// Add a screen to the stack
    func add(_ screen: NavigationStackScreen)
    /// Update the last stack's screen
    func updateLast(with screen: NavigationStackScreen)
    /// Remove last inserted screen from the Stack
    func removeLast()
    /// Remove all screens from the stack
    func clearStack()
    /// Set the stack to the state before the clear command
    func reloadStackBeforeClear()

    /// Returns a list of stack's screens' coordinators
    func coordinators(services: ServiceHub, hudCoordinator: HUDCoordinator?) -> [Coordinator]
    /// Returns last screen's parent if exists
    var parentScreen: NavigationStackScreen? { get }
}

/// Implementation of `NavigationStackService`
class NavigationStackServiceImpl {

    private var stackSubject = CurrentValueSubject<[NavigationStackScreen], Never>([])
    private var startedToNavigateSubject = CurrentValueSubject<Bool, Never>(false)
    private var coordinatorsStackBeforeClear = [NavigationStackScreen]()
}

// MARK: NavigationStackService conformance
extension NavigationStackServiceImpl: NavigationStackService {

    var startedToNavigate: Bool { startedToNavigateSubject.value }

    var startedToNavigatePublisher: AnyPublisher<Bool, Never> { startedToNavigateSubject.eraseToAnyPublisher() }

    var stack: [NavigationStackScreen] { stackSubject.value }

    var stackPublisher: AnyPublisher<[NavigationStackScreen], Never> { stackSubject.eraseToAnyPublisher() }

    var stackBeforeClear: [NavigationStackScreen] { coordinatorsStackBeforeClear }

    func add(_ screen: NavigationStackScreen) {
        startedToNavigateSubject.value = true
        stackSubject.value.append(screen)
    }

    func updateLast(with screen: NavigationStackScreen) {
        removeLast()
        add(screen)
    }

    func removeLast() {
        guard !stackSubject.value.isEmpty else { return }
        stackSubject.value.removeLast()
    }

    func clearStack() {
        coordinatorsStackBeforeClear = stackSubject.value
        stackSubject.value.removeAll()
    }

    func reloadStackBeforeClear() {
        stackSubject.value = coordinatorsStackBeforeClear
        coordinatorsStackBeforeClear = []
    }

    func coordinators(services: ServiceHub, hudCoordinator: HUDCoordinator? = nil) -> [Coordinator] {
        return stack.compactMap { $0.coordinator(services, hudCoordinator: hudCoordinator) }
    }

    var parentScreen: NavigationStackScreen? {
        guard stackSubject.value.count > 1 else { return nil }
        return stackSubject.value[stackSubject.value.endIndex - 2]
    }
}

extension NavigationStackScreen {
    /// Returns the screen's coordinator
    func coordinator(_ services: ServiceHub, hudCoordinator: HUDCoordinator? = nil) -> Coordinator? {
        switch self {
        case .dashboard:
            return hudCoordinator?.dashboardCoordinator() ?? DashboardCoordinator(services: services)
        case .projectManager(let selectedProject):
            return ProjectManagerCoordinator(flightPlanServices: services.flightPlan,
                                             uiServices: services.ui,
                                             cloudSynchroWatcher: services.cloudSynchroWatcher,
                                             defaultSelectedProject: selectedProject)
        case .myFlights(let selectedFlight):
            return MyFlightsCoordinator(flightServices: services.flight,
                                        flightPlanServices: services.flightPlan,
                                        uiServices: services.ui,
                                        repos: services.repos,
                                        drone: services.currentDroneHolder,
                                        defaultSelectedFlight: selectedFlight)
        case .myFlightsExecutedProjects(let selectedProject):
            return MyFlightsCoordinator(flightServices: services.flight,
                                        flightPlanServices: services.flightPlan,
                                        uiServices: services.ui,
                                        repos: services.repos,
                                        drone: services.currentDroneHolder,
                                        defaultSelectedProject: selectedProject)
        case .flightDetails(let flight):
            return FlightDetailsCoordinator(flight: flight,
                                            flightServices: services.flight,
                                            flightPlanServices: services.flightPlan,
                                            uiServices: services.ui,
                                            drone: services.currentDroneHolder)
        case .flightPlanDetails(let flightPlan):
            return FlightPlanExecutionDetailsCoordinator(flightPlan: flightPlan,
                                                         flightServices: services.flight,
                                                         flightPlanServices: services.flightPlan,
                                                         uiServices: services.ui,
                                                         repos: services.repos,
                                                         drone: services.currentDroneHolder)
        }
    }
}
