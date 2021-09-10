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
import CoreData

protocol ManagePlansViewModelDelegate: AnyObject {
    /// End manage plans
    ///
    /// - Parameters:
    ///     - editionPreference: value of corresponding perefrence edition
    ///     - shouldCenter: should center position on map
    ///     - flightPlan: flight plan model
    func endManagePlans(editionPreference: ManagePlansViewModel.EndManageEditionPreference, shouldCenter: Bool)

    /// Displays popup to delelte project.
    ///
    /// - Parameters:
    ///     - actionHandler: delete action
    func displayDeletePopup(actionHandler: @escaping () -> Void)
}

/// Protocol allow to communicate from UIViewController to ViewModel
protocol ManagePlansViewModelInput {

    /// Child flight plan list ViewModel
    var flightPlanListviewModel: FlightPlansListViewModelParentInput! { get }

    /// Publisher that give new value of flight plan state
    var statePublisher: AnyPublisher<ManagePlansState, Never> { get }

    /// User asks for a flight plan renaming
    ///
    /// - Parameters:
    ///     - name: String value of corresponding name
    func renameSelectedFlightPlan(_ name: String?)

    /// User asks for opening the currently selected flight plan
    func openSelectedFlightPlan()

    /// User asks for closing the "manage plans" view
    func closeManagePlans()

    /// User asks for duplicating the currently selected flight plan
    func duplicateSelectedFlightPlan()

    /// Asks deleting the currently selected flight plan
    func deleteFlightPlan()

    /// User asks for creating a new flight plan
    func newFlightPlan()

    /// Set compact mode
    func setToCompactMode()
}

/// State flight plan type
public enum ManagePlansState {
    case none
    case project(name: ProjectModel)
}

class ManagePlansViewModel {

    /// Own delegate
    private weak var delegate: ManagePlansViewModelDelegate?

    /// Mainly providing the type of the FPs
    private let flightPlanProvider: FlightPlanProvider

    /// Child flight plan list ViewModel
    private(set) var flightPlanListviewModel: FlightPlansListViewModelParentInput!

    /// Main manager, providing the "current flight plan" management. Do not confuse with the selected flight plan of this VM
    private let manager: ProjectManager

    /// State machine of current mode
    private var stateMachine: FlightPlanStateMachine

    /// Current mission manager
    private var currentMission: CurrentMissionManager

    /// Flying project
    private var idFlyingProject: String?

    /// State of flight plan
    @Published private var state: ManagePlansState = .none

    /// Current search query name
    @Published private var searchQuery: String?

    /// Any Cancellables
    private var cancellables = [AnyCancellable]()

    /// Delete current
    private var didDeleteCurrent = false

    /// Published selected project model
    private var selectedProject = CurrentValueSubject<ProjectModel?, Never>(nil)

    /// Constructor
    /// - Parameters:
    ///   - delegate: delegate handling the end of this subprocess
    ///   - flightPlanProvider: contextual provider determining the type of flight plans displayed
    ///   - manager: flight plan project
    init(delegate: ManagePlansViewModelDelegate,
         flightPlanProvider: FlightPlanProvider,
         manager: ProjectManager,
         stateMachine: FlightPlanStateMachine,
         currentMission: CurrentMissionManager ) {
        // Set properties
        self.delegate = delegate
        self.flightPlanProvider = flightPlanProvider
        self.manager = manager
        self.stateMachine = stateMachine
        self.currentMission = currentMission
    }

    func setupFlightPlanListviewModel(viewModel: FlightPlansListViewModelParentInput) {
        self.flightPlanListviewModel = viewModel
        self.flightPlanListviewModel.setupDelegate(with: self)

        selectedProject
            .sink { [weak self] project in
                guard let self = self else { return }
                if let project = project {
                    self.state = .project(name: project)
                    self.flightPlanListviewModel.updateUUID(with: project.uuid)
                } else {
                    self.state = .none
                    self.flightPlanListviewModel.updateUUID(with: nil)
                }
            }
            .store(in: &cancellables)

        if manager.currentProject == nil,
           let project = self.manager.loadProjects(type: currentMission.mode.flightPlanProvider?.projectType).first {
            self.manager.setCurrent(project)
        }

        manager.currentProjectPublisher.sink { [unowned self] in
            selectedProject.value = $0
        }
        .store(in: &cancellables)

        self.manager.projectsPublisher
            .sink { [weak self] updatedProjects in
                self?.flightPlanListviewModel.setupProjects(with: updatedProjects)
            }
            .store(in: &cancellables)

        self.stateMachine.state
            .sink(receiveValue: { [unowned self] state in
                switch state {
                case let .flying(flightPlan):
                    idFlyingProject = flightPlan.projectUuid
                default:
                    idFlyingProject = nil
                }
            })
            .store(in: &cancellables)

        $searchQuery
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink(receiveValue: { [unowned self] text in
                storeCurrentText(text)
            })
            .store(in: &cancellables)
    }
}

// MARK: - ManagePlansViewControllerDelegate
extension ManagePlansViewModel: ManagePlansViewModelInput {

    enum EndManageEditionPreference {
        case start
        case stop
        case keep
    }

    var statePublisher: AnyPublisher<ManagePlansState, Never> {
        $state.eraseToAnyPublisher()
    }

    func renameSelectedFlightPlan(_ name: String?) {
        searchQuery = name
    }

    func openSelectedFlightPlan() {
        guard let project = selectedProject.value,
              let flightPlan = manager.lastFlightPlan(for: project) else { return }
        if project.uuid != idFlyingProject {
            manager.loadEverythingAndOpen(flightPlan: flightPlan)
        }
        delegate?.endManagePlans(editionPreference: .stop, shouldCenter: flightPlan.isEmpty)
    }

    func closeManagePlans() {
        delegate?.endManagePlans(editionPreference: didDeleteCurrent ? .stop : .keep, shouldCenter: false)
    }

    func duplicateSelectedFlightPlan() {
        guard let project = selectedProject.value else { return }
        manager.duplicate(project: project)
    }

    func deleteFlightPlan() {
        guard canDeleteProject() else { return }

        delegate?.displayDeletePopup { [weak self] in
            self?.performDeleteSelectedFlightPlan()
        }
    }

    func canDeleteProject() -> Bool {
        guard
            let project = selectedProject.value,
            project.uuid != idFlyingProject else {
            return false
        }
        return true
    }

    func performDeleteSelectedFlightPlan() {
        guard
            let project = selectedProject.value else { return }
        if project.uuid == manager.currentProject?.uuid {
            didDeleteCurrent = true
        }
        selectedProject.value = nil
        manager.delete(project: project)
        selectedProject.value = manager.currentProject
        if selectedProject.value == nil {
            selectedProject.value = manager.loadProjects(type: project.type).first
        }
    }

    func newFlightPlan() {
        let newProject = manager.newProject(flightPlanProvider: self.flightPlanProvider)
        manager.loadEverythingAndOpen(project: newProject)
        delegate?.endManagePlans(editionPreference: .start, shouldCenter: true)
    }

    func setToCompactMode() {
        flightPlanListviewModel.setupDisplayMode(with: .compact)
    }

    private func storeCurrentText(_ text: String?) {
        if let text = text,
           !text.isEmpty,
           let project = selectedProject.value {
            manager.rename(project, title: text)
        }
    }
}

// MARK: - FlightPlansListViewControllerDelegate
extension ManagePlansViewModel: FlightPlansListViewModelDelegate {
    func didSelect(project: ProjectModel) {
        selectedProject.value = project
    }

    func didDoubleTapOn(project: ProjectModel) {
        openSelectedFlightPlan()
    }
}
