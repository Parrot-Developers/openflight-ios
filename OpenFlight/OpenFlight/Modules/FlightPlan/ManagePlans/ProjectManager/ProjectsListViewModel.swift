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

public class ProjectsListViewModel {
    @Published private(set) var filteredProjectUuids: [String] = []
    @Published private(set) var selectedProject: ProjectModel?

    let manager: ProjectManager
    private weak var projectManagerViewModel: ProjectManagerViewModel?
    private let synchroService: SynchroService?
    private weak var coordinator: ProjectManagerCoordinator?
    private var filteredProjectType: ProjectType = .classic
    private var cancellables = Set<AnyCancellable>()

    init(coordinator: ProjectManagerCoordinator?,
         manager: ProjectManager,
         synchroService: SynchroService?,
         projectManagerViewModel: ProjectManagerViewModel) {
        self.coordinator = coordinator
        self.manager = manager
        self.projectManagerViewModel = projectManagerViewModel
        self.synchroService = synchroService

        selectedProject = nil
        listenProjectTypeChange()
        listenProjectsPublisher()
        listenProjectsChange()
    }

    // MARK: - Private funcs
    private func listenProjectTypeChange() {
        projectManagerViewModel?.isFlightPlanProjectType
            .sink { [weak self] isFlightPlanType in
                guard let self = self else { return }
                self.selectedProject = nil
                self.filteredProjectType = isFlightPlanType ? ProjectType.classic : ProjectType.pgy
                self.refreshProjects(forLimit: self.manager.numberOfProjectsPerPage)
            }
            .store(in: &cancellables)
    }

    private func listenProjectsPublisher() {
        manager.projectsDidChangePublisher
            .sink { [weak self] in
                guard let self = self else { return }
                self.refreshProjects()
            }
            .store(in: &cancellables)
    }

    private func listenProjectsChange() {
        projectManagerViewModel?.projectDidUpdate
            .sink { [weak self] projectUpdated in
                guard let self = self else { return }
                self.refreshProjects()
                self.selectedProject = self.project(with: projectUpdated?.uuid)
            }
            .store(in: &cancellables)

        projectManagerViewModel?.projectAdded
            .sink { [weak self] projectAdded in
                guard let self = self else { return }
                self.refreshProjects()
                self.selectedProject = self.project(with: projectAdded?.uuid)
           }
            .store(in: &cancellables)
    }

    private func project(with uuid: String?) -> ProjectModel? {
        guard let uuid = uuid,
              let projectUuid = filteredProjectUuids.first(where: { $0 == uuid }) else {
            return nil
        }
        return manager.getProject(byUuid: projectUuid)
    }

    // MARK: - Public funcs
    func selectProjectByDoubleTap(forIndexPath: IndexPath) {
        guard forIndexPath.row < filteredProjectUuids.count else {
            return
        }
        let projectUuid = filteredProjectUuids[forIndexPath.row]
        selectedProject = manager.getProject(byUuid: projectUuid)
        if let selectedProject = selectedProject {
            projectManagerViewModel?.openProject(selectedProject)
        }
    }

    func selectProject(forIndexPath: IndexPath) {
        guard forIndexPath.row < filteredProjectUuids.count else {
            return
        }
        let projectUuid = filteredProjectUuids[forIndexPath.row]
        selectedProject = manager.getProject(byUuid: projectUuid)
    }

    func selectProject(_ project: ProjectModel) {
        selectedProject = self.project(with: project.uuid) ?? project
    }

    func removeSelectedProject() {
        selectedProject = nil
    }

    func isProjectSelected(_ project: ProjectModel) -> Bool {
        project.uuid == selectedProject?.uuid
    }

    func getSelectedProjectIndex() -> Int? {
        guard let selectedProject = selectedProject else {
            return nil
        }
        var result: Int?

        if let index = filteredProjectUuids.firstIndex(where: { $0 == selectedProject.uuid }) {
            result = index
        } else {
            while getMoreProjects() {
                if let index = filteredProjectUuids.firstIndex(where: { $0 == selectedProject.uuid }) {
                    result = index
                    break
                }
            }
        }

        return result
    }

    func shouldGetMoreProjects(fromIndexPath indexPath: IndexPath) {
        if indexPath.row == filteredProjectUuids.count - 1 {
            getMoreProjects()
        }
    }

    @discardableResult
    func getMoreProjects() -> Bool {
        let projectsCount = manager.getProjectsCount(withType: filteredProjectType)
        guard filteredProjectUuids.count < projectsCount else {
            return false
        }
        let moreProjectUuids = manager.loadProjects(type: filteredProjectType,
                                                    offset: filteredProjectUuids.count,
                                                    limit: manager.numberOfProjectsPerPage).map { $0.uuid }
        if !moreProjectUuids.isEmpty {
            filteredProjectUuids.append(contentsOf: moreProjectUuids)
        }
        return true
    }

    func refreshProjects(forLimit: Int? = nil) {
        guard let forLimit = forLimit else {
            filteredProjectUuids = manager.loadProjects(type: filteredProjectType, limit: filteredProjectUuids.count).map { $0.uuid }
            return
        }

        filteredProjectUuids = manager.loadProjects(type: filteredProjectType, limit: forLimit).map { $0.uuid }
    }

    func projectProvider(for uuid: String) -> CellProjectListProvider? {
        guard let projectUuid = filteredProjectUuids.first(where: { $0 == uuid }),
              let project = manager.getProject(byUuid: projectUuid) else {
            return nil
        }
        return CellProjectListProvider(isSelected: isProjectSelected(project), project: project)
    }

    func getProject(byUuid: String) -> ProjectModel? {
        manager.getProject(byUuid: byUuid)
    }

    /// Returns a project table view cell model for a specific project.
    ///
    /// - Parameter uuid: the project uuid
    /// - Returns: the corresponding project table view cell model
    func cellViewModel(for uuid: String) -> ProjectCellModel? {
        guard let project = manager.getProject(byUuid: uuid) else { return nil }
        var icon: UIImage?
        if !project.isSimpleFlightPlan,
           let executionType = Services.hub.flightPlan.typeStore.typeForKey(project.editableFlightPlan?.flightPlanType) {
            icon = executionType.icon
        }

        return ProjectCellModel(title: project.title,
                                date: project.lastUpdated?.commonFormattedString,
                                isExecuted: project.latestExecutedFlightPlan != nil,
                                icon: icon,
                                thumbnail: project.editableFlightPlan?.thumbnail?.image,
                                isSelected: isProjectSelected(project))
    }
}
