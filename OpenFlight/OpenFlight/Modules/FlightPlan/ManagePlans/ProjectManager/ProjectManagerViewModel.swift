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
import Pictor
import SwiftyUserDefaults

public class ProjectManagerViewModel {

    // MARK: - Public properties
    public var isSynchronizingData: AnyPublisher<Bool, Never> { isSynchronizingSubject.eraseToAnyPublisher() }
    public var isFlightPlanProjectType: AnyPublisher<Bool, Never> { isFlightPlanProjectTypeSubject.eraseToAnyPublisher() }
    public var projectDidUpdate: AnyPublisher<ProjectModel?, Never> { projectDidUpdateSubject.eraseToAnyPublisher() }
    public var projectAdded: AnyPublisher<ProjectModel?, Never> { projectAddedSubject.eraseToAnyPublisher() }
    public var segmentedControlSelectedIndex: Int {
        (!isFlightPlanProjectTypeSubject.value).toInt
    }

    let manager: ProjectManager
    let synchroService: SynchroService?
    /// Whether project type selection is enabled in manager.
    let canSelectProjectType: Bool

    // MARK: - Private properties
    private weak var coordinator: ProjectManagerCoordinator?
    private let projectManagerUiProvider: ProjectManagerUiProvider!
    private let flightPlanStateMachine: FlightPlanStateMachine?
    private var isSynchronizingSubject = CurrentValueSubject<Bool, Never>(false)
    private var isFlightPlanProjectTypeSubject = CurrentValueSubject<Bool, Never>(Defaults.isFlightPlanProjectType)
    private var projectDidUpdateSubject = PassthroughSubject<ProjectModel?, Never>()
    private var projectAddedSubject = PassthroughSubject<ProjectModel?, Never>()
    private var idFlyingProject: String?
    private var cancellables = Set<AnyCancellable>()

    init(coordinator: ProjectManagerCoordinator?,
         manager: ProjectManager,
         synchroService: SynchroService?,
         projectManagerUiProvider: ProjectManagerUiProvider,
         flightPlanStateMachine: FlightPlanStateMachine?,
         canSelectProjectType: Bool) {
        self.manager = manager
        self.synchroService = synchroService
        self.coordinator = coordinator
        self.projectManagerUiProvider = projectManagerUiProvider
        self.flightPlanStateMachine = flightPlanStateMachine
        self.canSelectProjectType = canSelectProjectType

        listenDataSynchronization()
        listenFlightPlanStateMachine()
    }

    // MARK: - Private funcs
    private func listenDataSynchronization() {
        synchroService?.statusPublisher
            .sink { [unowned self] status in
                isSynchronizingSubject.value = status.isSyncing
            }
            .store(in: &cancellables)
    }

    private func listenFlightPlanStateMachine() {
        flightPlanStateMachine?.statePublisher
            .sink { [unowned self] state in
                if case .flying(let flightPlan) = state {
                    idFlyingProject = flightPlan.pictorModel.projectUuid
                } else {
                    idFlyingProject = nil
                }
            }
            .store(in: &cancellables)
    }

 }

extension ProjectManagerViewModel {
    func updateProjectType(_ projectType: ProjectManagerUiParameters.ProjectType) {
        isFlightPlanProjectTypeSubject.value = projectType.isStantardFlightPlan
        Defaults.isFlightPlanProjectType = projectType.isStantardFlightPlan
    }

    var projectTypes: [ProjectManagerUiParameters.ProjectType] { projectManagerUiProvider.uiParameters().projectTypes }

    func index(of projectType: ProjectManagerUiParameters.ProjectType?) -> Int? {
        guard let projectType = projectType else { return nil }
        return projectTypes.firstIndex(where: { $0.title == projectType.title })
    }

    func projectType(for index: Int?) -> ProjectManagerUiParameters.ProjectType? {
        guard let index = index else { return projectTypes.first }
        return projectTypes[min(max(index, 0), projectTypes.count)]
    }

    func projectTypeIndex(of project: ProjectModel?) -> Int? {
        guard let project = project else { return nil }
        return projectTypes.firstIndex(where: { $0.flightPlanProvider?.projectType == project.type })
    }
}

// MARK: - Project actions
extension ProjectManagerViewModel {

    func openProject(_ project: ProjectModel) {
        // If we are trying to open the currently opened project,
        // show directly the HUD without loading anything.
        // This prevents to stop a running flight plan.
        guard manager.currentProject?.uuid != project.uuid else {
            coordinator?.showCurrentProject()

            return
        }
        coordinator?.open(project: project, startEdition: false, isBrandNew: false)
    }

    func renameProject(_ project: ProjectModel, with title: String) {
        manager.rename(project, title: title) { [weak self] in
            self?.projectDidUpdateSubject.send($0)
        }
    }

    func duplicateProject(_ project: ProjectModel) {
        manager.duplicate(project: project) { [weak self] duplicatedProject in
            guard let self = self, let duplicatedProject = duplicatedProject else { return }

            self.projectAddedSubject.send(self.manager.currentProject)
            self.coordinator?.open(project: duplicatedProject, startEdition: false, isBrandNew: true)
        }
   }

    func createNewProject(for flightPlanProvider: FlightPlanProvider) {
        manager.newProject(flightPlanProvider: flightPlanProvider) { [weak self] project in
            guard let self = self,
                  let project = project else { return }
            self.projectAddedSubject.send(project)
            self.coordinator?.open(project: project, startEdition: true, isBrandNew: true)
        }
    }

    func showDeletionConfirmation(for project: ProjectModel) {
        coordinator?.showDeleteProjectPopupConfirmation(didTapDelete: {
            self.deleteProject(project)
        })
     }

    func deleteProject(_ project: ProjectModel) {
        // TODO: Inform user he can't delete a project in use.
        guard canDeleteProject(project) else { return }
        manager.delete(project: project) { [weak self] _ in
            self?.projectDidUpdateSubject.send(nil)
        }
    }

    func canDeleteProject(_ project: ProjectModel) -> Bool {
        project.uuid != idFlyingProject
    }

 }
