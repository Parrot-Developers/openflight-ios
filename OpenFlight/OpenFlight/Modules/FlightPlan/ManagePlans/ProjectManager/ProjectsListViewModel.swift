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
import SwiftyUserDefaults

public class ProjectsListViewModel {

    @Published private(set) var filteredProjects: [ProjectModel] = [ProjectModel]()
    @Published private(set) var selectedProject: ProjectModel?

    let manager: ProjectManager
    private weak var projectManagerViewModel: ProjectManagerViewModel?
    private let cloudSynchroWatcher: CloudSynchroWatcher?
    private weak var coordinator: ProjectManagerCoordinator?
    private var filteredProjectType: ProjectType = .classic
    private var cancellables = Set<AnyCancellable>()

    init(coordinator: ProjectManagerCoordinator?,
         manager: ProjectManager,
         cloudSynchroWatcher: CloudSynchroWatcher?,
         projectManagerViewModel: ProjectManagerViewModel) {
        self.coordinator = coordinator
        self.manager = manager
        self.projectManagerViewModel = projectManagerViewModel
        self.cloudSynchroWatcher = cloudSynchroWatcher

        selectedProject = nil
        refreshProjects()
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
        guard let uuid = uuid else { return nil }
        return filteredProjects.first { $0.uuid == uuid }
    }

    // MARK: - Public funcs
    func selectProjectByDoubleTap(forIndexPath: IndexPath) {
        guard forIndexPath.row < filteredProjects.count else {
            return
        }

        selectedProject = filteredProjects[forIndexPath.row]
        projectManagerViewModel?.openProject(filteredProjects[forIndexPath.row])
    }

    func selectProject(forIndexPath: IndexPath) {
        guard forIndexPath.row < filteredProjects.count else {
            return
        }
        selectedProject = filteredProjects[forIndexPath.row]
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

        if let index = filteredProjects.firstIndex(where: { $0.uuid == selectedProject.uuid }) {
            result = index
        } else {
            while getMoreProjects() {
                if let index = filteredProjects.firstIndex(where: { $0.uuid == selectedProject.uuid }) {
                    result = index
                    break
                }
            }
        }

        return result
    }

    func shouldGetMoreProjects(fromIndexPath indexPath: IndexPath) {
        if indexPath.row == filteredProjects.count - 1 {
            getMoreProjects()
        }
    }

    @discardableResult
    func getMoreProjects() -> Bool {
        let allFlightsCount = manager.getProjectsCount(withType: filteredProjectType)
        guard filteredProjects.count < allFlightsCount else {
            return false
        }
        let moreProjects = manager.loadProjects(type: filteredProjectType, offset: filteredProjects.count, limit: manager.numberOfProjectsPerPage)
        if !moreProjects.isEmpty {
            filteredProjects.append(contentsOf: moreProjects)
        }
        return true
    }

    func refreshProjects(forLimit: Int? = nil) {
        guard let forLimit = forLimit else {
            filteredProjects = manager.loadProjects(type: filteredProjectType, limit: filteredProjects.count)
            return
        }

        filteredProjects = manager.loadProjects(type: filteredProjectType, limit: forLimit)
    }
}
