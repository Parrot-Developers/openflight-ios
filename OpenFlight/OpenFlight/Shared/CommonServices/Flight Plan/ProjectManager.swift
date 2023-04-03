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

// swiftlint:disable file_length

import Foundation
import Combine
import SdkCore
import Pictor

/// Summary about all projects
public struct AllProjectsSummary {
    /// Total number of flights
    public var numberOfProjects: Int
    public var totalFlightPlan: Int
    public var totalPgy: Int

    /// Init
    public init(numberOfProjects: Int = 0,
                totalFlightPlan: Int = 0,
                totalPgy: Int = 0) {
        self.numberOfProjects = numberOfProjects
        self.totalFlightPlan = totalFlightPlan
        self.totalPgy = totalPgy
    }

    mutating func update(numberOfProjects: Int,
                         totalFlightPlan: Int,
                         totalPgy: Int) {
        self.numberOfProjects = numberOfProjects
        self.totalFlightPlan = totalFlightPlan
        self.totalPgy = totalPgy
    }
}

/// Project Manager Errors
enum ProjectManagerError: Error {
    /// Indicates a project is trying to be renamed with a already used name.
    /// An alternative can be proposed thanks to the `alternativeName`parameter.
    case enableToRenameProject(alternativeName: String?)
    /// A project name is trying to be renamed with the same name.
    case nameNotChanged
}

public protocol ProjectManager {
    /// Maximum of projects to get for each loading
    var numberOfProjectsPerPage: Int { get }

    /// Current project publisher
    var currentProjectPublisher: AnyPublisher<ProjectModel?, Never> { get }

    /// Projects did change
    var projectsDidChangePublisher: AnyPublisher<Void, Never> { get }

    /// All projects summary
    var allProjectsSummaryPublisher: AnyPublisher<AllProjectsSummary, Never> { get }
    var allProjectsSummary: AllProjectsSummary { get }

    /// Project must close its history list
    var hideExecutionsListPublisher: AnyPublisher<Void, Never> { get }

    /// Publisher notifying to start edition of current project.
    var startEditionPublisher: AnyPublisher<Void, Never> { get }

    /// Current project
    var currentProject: ProjectModel? { get }

    /// Whether the current project has some executions.
    var hasCurrentProjectExecutions: Bool { get }

    /// Whether the current project has just been created.
    var isCurrentProjectBrandNew: Bool { get set }

    /// Loads Projects.
    ///
    /// - Parameters:
    ///    - type: project type to specified
    ///    - offset: offset start
    ///    - limit: maximum number of project to get
    /// - Returns: list of projects
    func loadProjects(type: ProjectType?, offset: Int, limit: Int) -> [ProjectModel]

    /// Loads Projects.
    ///
    /// - Parameters:
    ///    - type: project type to specified
    ///    - limit: maximum number of project to get
    /// - Returns: list of projects
    func loadProjects(type: ProjectType?, limit: Int) -> [ProjectModel]

    /// Loads executed projects, ordered by last execution date desc
    ///
    /// - Parameters:
    ///    - offset: offset start
    ///    - limit: maximum number of project to get
    /// - Returns: list of projects
    func loadExecutedProjects(offset: Int, limit: Int, withType: ProjectType?) -> [ProjectModel]

    /// Loads executed projects, ordered by last execution date desc
    ///
    /// - Parameters:
    ///    - limit: maximum number of project to get
    /// - Returns: list of projects
    func loadExecutedProjects(limit: Int, withType: ProjectType?) -> [ProjectModel]

    /// Get count of all projects
    func getAllProjectsCount() -> Int

    /// Get count of all projects with a specific type
    /// - Parameters:
    ///     - withType: type of project to specidified
    func getProjectsCount(withType: ProjectType) -> Int

    /// Get count of all executed projects with a specific type
    /// - Parameters:
    ///     - withType: type of project to specidified
    /// - Returns: Count of projects with matching type
    func getExecutedProjectsCount(withType: ProjectType?) -> Int

    /// Get executed flight plan from specified project
    /// - Parameters:
    ///     - project: project to specified
    /// - Returns: List of executed flight plans with hasReachedFirstWaypoint to true
    func getExecutedFlightPlans(ofProject project: ProjectModel) -> [FlightPlanModel]

    /// Creates new Project.
    ///
    /// - Parameters:
    ///     - flightPlanProvider: Flight Plan provider
    /// - Returns: the created project
    func newProject(flightPlanProvider: FlightPlanProvider, completion: @escaping ((ProjectModel?) -> Void))

    /// Creates a new project from a mavlink file
    /// - Parameter url: the mavlink file URL
    func newProjectFromMavlinkFile(_ url: URL?, completion: @escaping ((ProjectModel?) -> Void))

    /// Fetch ordered flight plans for a project
    /// - Parameter project: the project
    func flightPlans(for project: ProjectModel) -> [FlightPlanModel]

    /// Fetch ordered executed flight plans for a project
    /// - Parameter project: the project
    func executedFlightPlans(for project: ProjectModel) -> [FlightPlanModel]

    /// Returns the Project's executions INCLUDING the flying one.
    /// - Parameters:
    ///    - project: the project.
    /// - Returns: The executions list.
    func executions(for project: ProjectModel) -> [FlightPlanModel]

    /// Returns the project's pending execution (if any).
    /// An execution is pending if and only if:
    ///    - it is the latest execution of the project AND
    ///    - it has not been completed (state is `.stopped` or `.flying`)
    ///
    /// - Parameter project: the project
    /// - Returns: the latest pending execution (if any)
    func pendingExecution(for project: ProjectModel) -> FlightPlanModel?

    /// Get the editable's flight plan used for a specific project
    ///
    /// - Parameters:
    ///     - project:project to consider
    /// - Returns: the editable's flight plan used or nil if there 's no flight plan in this project
    func editableFlightPlan(for project: ProjectModel) -> FlightPlanModel?

    /// Deletes a flight plan.
    ///
    /// - Parameters:
    ///     - project: project to delete
    ///     - completion: closure called on completion
    func delete(project: ProjectModel, completion: ((Bool) -> Void)?)

    /// Duplicates Flight Plan.
    ///
    /// - Parameters:
    ///     - project: project to duplicate
    ///     - completion: closure called on completion
    func duplicate(project: ProjectModel, completion: ((ProjectModel?) -> Void)?)

    /// Loads last opened project (if exists).
    ///
    /// - Parameters:
    ///     - state: mission state
    func setLastOpenedProjectAsCurrent(type: ProjectType)

    /// Sets up title project.
    ///
    /// - Parameters:
    ///    - project: the project
    ///    - title: the new title
    ///    - completion: closure called on completion
    func rename(_ project: ProjectModel, title: String, completion: ((ProjectModel) -> Void)?)

    /// Sets up selcted project as last used.
    ///
    /// - Parameters:
    ///     - project: project model
    ///     - completion: closure called on completion
    func setAsLastUsed(_ project: ProjectModel, completion: ((ProjectModel?) -> Void)?)

    /// Sets up project as current.
    ///
    /// - Parameters:
    ///     - project: project model
    ///     - completion: closure called on completion
    func setCurrent(_ project: ProjectModel, completion: (() -> Void)?)

    /// Clears the current project
    func clearCurrentProject()

    /// Get the project of a given flight plan
    /// - Parameter flightPlan: the flight plan
    func project(for flightPlan: FlightPlanModel) -> ProjectModel?

    /// Setup everything (mission, project, flight plan) to open a flight plan
    /// - Parameter flightPlan: the flight plan
    func loadEverythingAndOpen(flightPlan: FlightPlanModel)

    /// Setup everything (mission, project, flight plan) to open a flight plan
    /// - Parameters:
    ///    - flightPlan: the flight plan
    ///    - autoStart: automatically start the flight plan if `true`
    ///    - isBrandNew: indicates whether a project has just been created or duplicated
    func loadEverythingAndOpen(flightPlan: FlightPlanModel,
                               autoStart: Bool,
                               isBrandNew: Bool)

    /// Setup everything (mission, project, flight plan) to open the project's flight plan
    /// - Parameter project: the project
    func loadEverythingAndOpen(project: ProjectModel)

    /// Setup everything (mission, project, flight plan) to open the project's flight plan
    /// - Parameters:
    ///  -  project: the project
    ///  - isBrandNew: indicates whether a project has just been created or duplicated
    func loadEverythingAndOpen(project: ProjectModel, isBrandNew: Bool)

    /// Loads latest opened project of a specific type.
    ///
    /// - Parameter type: the type of the latest opened project to load
    func loadLastOpenedProject(type: ProjectType)

    /// Starts edition of current project.
    func startEdition()

    /// Get the execution custom title with executionRank
    ///
    /// - Parameters:
    ///    - executionRank: The executionRank to specified
    ///
    /// - Returns: The custom title for an execution with its rank
    func executionCustomTitle(for executionRank: Int) -> String

    /// Reset a Flight Plan's `customTitle` to his project's title.
    ///
    /// - Parameters:
    ///    - flightPlan: The flight plan execution.
    ///
    /// - Returns: The updated `FlightPlanModel`.
    @discardableResult
    func resetExecutionCustomTitle(for flightPlan: FlightPlanModel) -> FlightPlanModel

    /// Returns the Flight Plan Media Tag sent to the Drone during the configuration.
    ///
    /// - Parameters:
    ///    - flightPlan: The flight plan execution.
    ///
    /// - Returns: The `mediaTag`  or `nil` if the FP's project is not found.
    func mediaTag(for flightPlan: FlightPlanModel) -> String?

    /// Indicates whether a project can be renamed with the specified name.
    ///
    /// - Parameter name: the new name
    /// - Returns: `true` if new name can be applied or `false` if a project has already this name
    func isProjectCanBeRenamed(with name: String) -> Bool

    /// Returns a valid title for a renamed project.
    /// If a project already exists with the same name, increment his index as it's done when creating a new project.
    ///
    /// - Parameters:
    ///    - name: the wished project name
    ///    - project: the project to rename
    /// - Returns: the new project name (the Project's title)
    func renamedProjectTitle(for name: String, of project: ProjectModel?) -> String

    /// Update project and associated lfight plans executionRank if needed
    /// If an executed flight plan has a nil executionRank, all of the executed flighplans executionRank is reordered
    /// - Parameters:
    ///     - project: the specified project
    /// - Returns: The updated project
    /// - Description:
    ///     - If a project has executed flight plan and one of them has no executionRank, all executed flight plan
    ///     will be sorted by their custom title in ascending order and the executionRank will be set according to that order.
    ///     Project's 'latestExecutionRank' will be set with the highest executionRank if nil.
    func updateFlightPlansExecutionRankIfNeeded(for project: ProjectModel) -> ProjectModel

    /// Set the next executionRank for project with specified UUID
    /// - Parameters
    ///     - projectId: project's UUID to specified
    /// - Returns:
    ///     - The next executionRank of the project
    func setNextExecutionRank(forProjectId projectId: String) -> Int

    /// Cancel the last execution for project with specified UUID
    /// - Parameters:
    ///     - projectId: project's UUID to specified
    /// - Description:
    ///     - Project's latestExecutionRank is decremented by 1
    func cancelLastExecution(forProjectId projectId: String)
}

private extension ULogTag {
    static let tag = ULogTag(name: "ProjectManager")
}

public class ProjectManagerImpl {
    public var numberOfProjectsPerPage: Int = 40

    private let flightPlanTypeStore: FlightPlanTypeStore
    private let flightPlanRepository: PictorFlightPlanRepository
    private let projectRepository: PictorProjectRepository
    private let editionService: FlightPlanEditionService
    private let currentMissionManager: CurrentMissionManager
    private let userService: PictorUserService
    private let filesManager: FlightPlanFilesManager
    private let missionsStore: MissionsStore
    private let flightPlanManager: FlightPlanManager
    private let flightPlanRunManager: FlightPlanRunManager
    private var cancellables = Set<AnyCancellable>()

    public var projectsDidChangePublisher: AnyPublisher<Void, Never> {
        return projectsDidChangeSubject.eraseToAnyPublisher()
    }

    public var hideExecutionsListPublisher: AnyPublisher<Void, Never> {
        return hideExecutionsListSubject.eraseToAnyPublisher()
    }

    public var startEditionPublisher: AnyPublisher<Void, Never> {
        return startEditionSubject.eraseToAnyPublisher()
    }

    public var isCurrentProjectBrandNew: Bool = false

    // MARK: - Private Properties
    private var currentProjectSubject = CurrentValueSubject<ProjectModel?, Never>(nil)
    private var projectsDidChangeSubject = PassthroughSubject<Void, Never>()
    private var allProjectSummarySubject = CurrentValueSubject<AllProjectsSummary, Never>(AllProjectsSummary())
    private var hideExecutionsListSubject = PassthroughSubject<Void, Never>()
    private var startEditionSubject = PassthroughSubject<Void, Never>()

    init(missionsStore: MissionsStore,
         flightPlanTypeStore: FlightPlanTypeStore,
         projectRepository: PictorProjectRepository,
         flightPlanRepository: PictorFlightPlanRepository,
         editionService: FlightPlanEditionService,
         currentMissionManager: CurrentMissionManager,
         userService: PictorUserService,
         filesManager: FlightPlanFilesManager,
         flightPlanManager: FlightPlanManager,
         flightPlanRunManager: FlightPlanRunManager) {
        self.missionsStore = missionsStore
        self.flightPlanTypeStore = flightPlanTypeStore
        self.projectRepository = projectRepository
        self.flightPlanRepository = flightPlanRepository
        self.editionService = editionService
        self.currentMissionManager = currentMissionManager
        self.userService = userService
        self.filesManager = filesManager
        self.flightPlanManager = flightPlanManager
        self.flightPlanRunManager = flightPlanRunManager

        updateProjectSummary()

        listenUserEvent()
        listenProjectRepository()
    }
}

extension ProjectManagerImpl: ProjectManager {

    public var currentProjectPublisher: AnyPublisher<ProjectModel?, Never> {
        currentProjectSubject.eraseToAnyPublisher()
    }

    public var allProjectsSummaryPublisher: AnyPublisher<AllProjectsSummary, Never> {
        allProjectSummarySubject.eraseToAnyPublisher()
    }
    public var allProjectsSummary: AllProjectsSummary {
        allProjectSummarySubject.value
    }

    private(set) public var currentProject: ProjectModel? {
        get {
            currentProjectSubject.value
        }
        set {
            currentProjectSubject.value = newValue
        }
    }

    public var hasCurrentProjectExecutions: Bool {
        // Ensure Project Manager has a current project.
        guard let project = currentProject else { return false }
        // Check if project has executed flight plans.
        var excludedUuids: [String] = []
        if let flyingUuid = flightPlanRunManager.playingFlightPlan?.uuid {
            excludedUuids = [flyingUuid]
        }
        return flightPlanRepository.count(uuids: nil,
                                          excludedUuids: excludedUuids,
                                          projectUuids: [project.uuid],
                                          projectPix4dUuids: nil,
                                          states: nil,
                                          types: nil,
                                          excludedTypes: nil,
                                          hasReachedFirstWaypoint: true) > 0
    }

    public func newProject(flightPlanProvider: FlightPlanProvider, completion: @escaping ((ProjectModel?) -> Void)) {
        newProjectAndFlightPlan(flightPlanProvider: flightPlanProvider) { project, _ in
            guard let project = project else {
                ULog.e(.tag, "New project: failed")
                completion(nil)
                return
            }
            completion(project)
        }
    }

    public func newProjectFromMavlinkFile(_ url: URL?, completion: @escaping ((ProjectModel?) -> Void)) {
        guard let url = url,
              let flightPlanProvider = FlightPlanMissionMode.standard.missionMode.flightPlanProvider else {
                  completion(nil)
                  return
              }

        newProjectAndFlightPlan(flightPlanProvider: flightPlanProvider,
                                title: url.deletingPathExtension().lastPathComponent) { project, flightPlan in
                guard let newProject = project,
                      let newFlightPlan = flightPlan else {
                          ULog.e(.tag, "New project from Mavlink file: failed")
                          completion(nil)
                          return
                }
                // Synchronize project
                let pictorContext = PictorContext.new()
                pictorContext.update([newProject])

                var flightPlan = newFlightPlan
                flightPlan = MavlinkToFlightPlanParser
                    .generateFlightPlanFromMavlinkStandard(url: url,
                                                           flightPlan: flightPlan) ?? flightPlan
                var dataSetting = flightPlan.dataSetting
                dataSetting?.readOnly = true
                // To support iCloud URLs we must grant access to the ressource.
                let mavlinkData = try? url.accessResource { url in try Data(contentsOf: url) }
                dataSetting?.mavlinkDataFile = mavlinkData
                flightPlan.dataSetting = dataSetting

                pictorContext.update([flightPlan.pictorModel])
                pictorContext.commit()
                completion(newProject)
            }
    }

    public func flightPlans(for project: ProjectModel) -> [FlightPlanModel] {
        let pictorFlightPlans = flightPlanRepository.get(uuids: nil,
                                                         excludedUuids: nil,
                                                         projectUuids: [project.uuid],
                                                         projectPix4dUuids: nil,
                                                         states: nil,
                                                         types: nil,
                                                         excludedTypes: nil,
                                                         hasReachedFirstWaypoint: nil)
        return pictorFlightPlans.map { $0.flightPlanModel }
    }

    public func executedFlightPlans(for project: ProjectModel) -> [FlightPlanModel] {
        executions(for: project, excludeFlyingFlightPlan: true)
    }

    public func executions(for project: ProjectModel) -> [FlightPlanModel] {
        executions(for: project, excludeFlyingFlightPlan: false)
    }

    public func pendingExecution(for project: ProjectModel) -> FlightPlanModel? {
        let flightPlans = flightPlanRepository.get(uuids: nil,
                                                   excludedUuids: nil,
                                                   projectUuids: [project.uuid],
                                                   projectPix4dUuids: nil,
                                                   states: nil,
                                                   types: nil,
                                                   excludedTypes: nil,
                                                   hasReachedFirstWaypoint: true)
        let latestExecution = flightPlans.sorted(by: {
            $0.lastUpdated > $1.lastUpdated
        }).first

        // Latest execution is pending only if its state is `.stopped` or `.flying`.
        guard latestExecution?.state == .stopped || latestExecution?.state == .flying else { return nil }

        return latestExecution?.flightPlanModel
    }

    public func editableFlightPlan(for project: ProjectModel) -> FlightPlanModel? {
        let pictorFp = flightPlanRepository.get(uuids: nil,
                                                excludedUuids: nil,
                                                projectUuids: [project.uuid],
                                                projectPix4dUuids: nil,
                                                states: [FlightPlanState.editable],
                                                types: nil,
                                                excludedTypes: nil,
                                                hasReachedFirstWaypoint: nil).first
        guard let pictorFp = pictorFp else {
            return nil
        }
        return pictorFp.flightPlanModel
    }

    public func loadProjects(type: ProjectType?, offset: Int, limit: Int) -> [ProjectModel] {
        projectRepository.get(from: offset, count: limit, type: type, hasExecutedFlightPlans: nil)
    }

    public func loadProjects(type: ProjectType?, limit: Int) -> [ProjectModel] {
        projectRepository.get(from: 0, count: limit, type: type, hasExecutedFlightPlans: nil)
    }

    public func loadExecutedProjects(offset: Int, limit: Int, withType: ProjectType?) -> [ProjectModel] {
        projectRepository.get(from: offset, count: limit, type: withType, hasExecutedFlightPlans: true)
    }

    public func loadExecutedProjects(limit: Int, withType: ProjectType?) -> [ProjectModel] {
        projectRepository.get(from: 0, count: limit, type: withType, hasExecutedFlightPlans: true)
    }

    public func getProjectsCount(withType: ProjectType) -> Int {
        projectRepository.count(type: withType, hasExecutedFlightPlans: nil)
    }

    public func getExecutedProjectsCount(withType: ProjectType?) -> Int {
        projectRepository.count(type: withType, hasExecutedFlightPlans: true)
    }

    public func getAllProjectsCount() -> Int {
        projectRepository.count()
    }

    public func getExecutedFlightPlans(ofProject project: ProjectModel) -> [FlightPlanModel] {
        let project = updateFlightPlansExecutionRankIfNeeded(for: project)
        let pictorFlightPlans = flightPlanRepository.get(uuids: nil,
                                                         excludedUuids: nil,
                                                         projectUuids: [project.uuid],
                                                         projectPix4dUuids: nil,
                                                         states: nil,
                                                         types: nil,
                                                         excludedTypes: nil,
                                                         hasReachedFirstWaypoint: true)
        
        return pictorFlightPlans
            .compactMap { $0 }
            .sorted {
                /// Sort FlightPlan by executionRank in descending order
                /// if executionRank is nil, sort by custom title in descending order
                guard let executionRank0 = $0.executionRank else {
                    return $0.name.compare(
                        $1.name,
                        options: [.diacriticInsensitive, .numeric, .caseInsensitive])
                    == .orderedDescending }
                guard let executionRank1 = $1.executionRank else { return true }
                return executionRank0 > executionRank1
            }
            .map { $0.flightPlanModel }
    }

    public func delete(project: ProjectModel, completion: ((_ success: Bool) -> Void)?) {
        ULog.i(.tag, "Deleting project '\(project.uuid)' '\(project.title)'")
        for flightPlan in flightPlans(for: project) {
            // There are side effects to manage (delete mavlink,...), let the manager do the job
            flightPlanManager.delete(flightPlan: flightPlan)
        }

        let pictorContext = PictorContext.new()
        pictorContext.delete([project])
        pictorContext.commit()

        ULog.i(.tag, "delete project \(project.uuid)")
        resetLoadedProject()
        loadLastOpenedProject(type: project.type)

        completion?(true)
    }

    public func rename(_ project: ProjectModel, title: String, completion: ((ProjectModel) -> Void)?) {
        // Ensure the new name is different from the previous one.
        guard project.title != title else {
            completion?(project)
            return
        }
        // Generate an unique title.
        // If the new title is already used by another project,
        // use the same rule than for a project creation (adding ' ({index})' suffix).
        let newTitle = renamedProjectTitle(for: title, of: project)
        var project = project
        // Update the title and save the project.
        let logStr = "Rename project '\(project.uuid)' from '\(project.title)' to '\(newTitle)' (expected: \(title))"
        project.title = newTitle
        ULog.i(.tag, logStr)
        let pictorContext = PictorContext.new()
        pictorContext.update([project])

        if var flightPlan = editableFlightPlan(for: project),
           flightPlan.pictorModel.name != newTitle {
            flightPlan.pictorModel.name = newTitle

            pictorContext.update([flightPlan.pictorModel])
            ULog.i(.tag, "Rename project update for flight plan \(flightPlan.uuid)")
            editionService.setupFlightPlan(flightPlan)
        }

        // Update the current project
        if project.uuid == currentProject?.uuid {
            currentProject?.title = newTitle
        }

        pictorContext.commit()
        completion?(project)
    }

    public func duplicate(project: ProjectModel, completion: ((ProjectModel?) -> Void)?) {
        let pictorContext = PictorContext.new()

        // Generate the duplicated project's title.
        let title = nextDuplicatedProjectTitle(for: project)
        let duplicatedProject = project.duplicate(title: title)
        pictorContext.create([duplicatedProject])

        // Get the editable's FP (a project must always contains at least one FP) to duplicate it.
        if let flightPlan = editableFlightPlan(for: project) {
            var duplicatedFlightPlan = flightPlanManager.newFlightPlan(basedOn: flightPlan)
            duplicatedFlightPlan.pictorModel.name = title
            duplicatedFlightPlan.pictorModel.projectUuid = duplicatedProject.uuid
            pictorContext.create([duplicatedFlightPlan.pictorModel])
        }
        pictorContext.commit()

        currentProject = duplicatedProject
        // A duplicated project is treated as 'brand new' project.
        isCurrentProjectBrandNew = true
        completion?(duplicatedProject)
    }

    public func setCurrent(_ project: ProjectModel, completion: (() -> Void)?) {
        setAsLastUsed(project) { [unowned self] project in
            guard let project = project else {
                completion?()
                return
            }
            currentProject = project
            // Reset the flag informing about the project creation.
            isCurrentProjectBrandNew = false
            completion?()
        }
    }

    public func setLastOpenedProjectAsCurrent(type: ProjectType) {
        currentProject = projectRepository.getLatestOpened(type: type)

        // Update, if needed, the order of executed flight plan of project by their executionRank
        // if old flight plans have their executionRank to nil
        if let project = currentProject {
            currentProject = updateFlightPlansExecutionRankIfNeeded(for: project)
        } else {
            ULog.i(.tag, "No project found for type '\(type)'")
        }

        // Reset the flag informing about the project creation.
        isCurrentProjectBrandNew = false
    }

    public func setAsLastUsed(_ project: ProjectModel, completion: ((_ project: ProjectModel?) -> Void)?) {
        // Save date in file.
        var project = project
        project.lastUpdated = Date()

        let pictorContext = PictorContext.new()
        pictorContext.update([project])
        pictorContext.commit()
        completion?(project)
    }

    public func project(for flightPlan: FlightPlanModel) -> ProjectModel? {
        return projectRepository.get(byUuid: flightPlan.pictorModel.projectUuid)
    }

    public func clearCurrentProject() {
        currentProject = nil
        // Reset the flag informing about the project creation.
        isCurrentProjectBrandNew = false
    }

    public func loadEverythingAndOpen(flightPlan: FlightPlanModel) {
        loadEverythingAndOpen(flightPlan: flightPlan,
                              autoStart: false,
                              isBrandNew: false)
    }

    public func loadEverythingAndOpen(flightPlan: FlightPlanModel,
                                      autoStart: Bool,
                                      isBrandNew: Bool) {
        guard var project = project(for: flightPlan) else { return }

        // Update, if needed, the order of executed flight plan of project by their executionRank
        // if old flight plans have their executionRank to nil
        project = updateFlightPlansExecutionRankIfNeeded(for: project)

        // Update `lastOpened` date in order to be able to correctly reload latest project when needed.
        // (Used in `setLastOpenedProjectAsCurrent` and `loadLastProject()`)
        project.lastOpened = Date()

        // Update `lastUpdated` date only if the execution is launched.
        if autoStart { project.lastUpdated = Date() }

        var missionProvider: MissionProvider?
        var missionMode: MissionMode?
        for provider in missionsStore.allMissions {
            if provider.mission.defaultMode.flightPlanProvider?.hasFlightPlanType(flightPlan.pictorModel.flightPlanType) ?? false {
                missionProvider = provider
                missionMode = provider.mission.defaultMode
            }
        }
        guard let mPovider = missionProvider, let mMode = missionMode else { return }
        ULog.i(.tag, "Opening flightPlan '\(flightPlan.uuid)' of project '\(project.uuid)' '\(project.title)'")

        // Locally save project with updated `lastOpened` date.
        // (Do not need to be synchronized, as information is only intended to be locally used.)
        let pictorContext = PictorContext.new()
        pictorContext.updateLocal([project])
        pictorContext.commit()

        // Setup Mission as a Flight Plan mission (may be custom).
        currentMissionManager.set(provider: mPovider)
        currentMissionManager.set(mode: mMode)
        currentProject = project
        isCurrentProjectBrandNew = isBrandNew
        mMode.stateMachine?.open(flightPlan: flightPlan)
        if autoStart {
            mMode.stateMachine?.start()
        }
        hideExecutionsListSubject.send()
    }

    public func loadEverythingAndOpen(project: ProjectModel) {
        loadEverythingAndOpen(project: project, isBrandNew: false)
    }

    public func loadEverythingAndOpen(project: ProjectModel, isBrandNew: Bool) {
        guard let flightPlan = editableFlightPlan(for: project) else {
            ULog.i(.tag, "No Flight Plan found for project '\(project.uuid)' '\(project.title)'")
            return
        }
        ULog.i(.tag, "Opening \(isBrandNew ? "brand new" : "") project '\(project.uuid)' '\(project.title)' will continue"
               + " opening flightPlan '\(flightPlan.uuid)'")
        loadEverythingAndOpen(flightPlan: flightPlan,
                              autoStart: false,
                              isBrandNew: isBrandNew)
    }

    public func loadLastOpenedProject(type: ProjectType) {
        setLastOpenedProjectAsCurrent(type: type)

        guard let project = currentProject,
              let flightPlan = editableFlightPlan(for: project) else { return }

        ULog.i(.tag, "Opening flightPlan '\(flightPlan.uuid)' of project '\(project.uuid)' '\(project.title)'")
        currentMissionManager.mode.stateMachine?.open(flightPlan: flightPlan)
    }

    public func startEdition() {
        startEditionSubject.send()
    }

    public func executionCustomTitle(for executionRank: Int) -> String {
        "\(L10n.flightPlanExecutionName) \(executionRank)"
    }

    @discardableResult
    public func resetExecutionCustomTitle(for flightPlan: FlightPlanModel) -> FlightPlanModel {
        // Ensure Flight Plan has a project with a title.
        guard let project = project(for: flightPlan) else { return flightPlan }
        // Update the FP with the project's title.
        return flightPlanManager.update(flightplan: flightPlan, with: project.title)
    }

    public func mediaTag(for flightPlan: FlightPlanModel) -> String? {
        // Ensure the FP is linked to a project with a name.
        guard let project = project(for: flightPlan) else { return nil }
        // Returns the media tag with the following format:
        // "{project name} - {execution name}"
        // Examples:
        //    • "My FP - Execution 1"
        //    • "Flight Plan (3) - Execution 2"
        //    • "My FP - copy (3) - Execution 5"
        let mediaTag = project.title + " - " + flightPlan.pictorModel.name
        // Remove the diacritics which are not supported by the Drone.
        return mediaTag.folding(options: .diacriticInsensitive,
                                locale: Locale.current)
    }

    /// Indicates whether a project can be renamed with the specified name.
    ///
    /// - Parameter name: the new name
    /// - Returns: `true` if new name can be applied or `false` if a project has already this name
    public func isProjectCanBeRenamed(with name: String) -> Bool {
        // 1 - Get the existing Projects' titles list.
        // 2 - Extract titles.
        // 3 - Filter titles with exactly, ignoring the Case, the same name.
        // 4 - Check if a project already exists with the same name.
        projectRepository.getAllTitles()
            .filter { $0.compare(name, options: .caseInsensitive) == .orderedSame }
            .isEmpty
    }

    /// Returns a valid title for a renamed project.
    /// If a project already exists with the same name, increment his index as it's done when creating a new project.
    ///
    /// - Parameters:
    ///    - name: the wished project name
    ///    - project: the project to rename
    /// - Returns: the new project name (the Project's title)
    public func renamedProjectTitle(for name: String, of project: ProjectModel? = nil) -> String {
        // Start by trimming whitespace.
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        // If no project already has this name. Use it.
        guard !isProjectCanBeRenamed(with: trimmedName) else { return trimmedName }
        // Generate an alternative name.
        return alternativeName(for: trimmedName, of: project)
    }

    public func updateFlightPlansExecutionRankIfNeeded(for project: ProjectModel) -> ProjectModel {
        guard var project = projectRepository.get(byUuid: project.uuid, isUpdateExecutionRankNeeded: true) else {
            ULog.i(.tag, "updateExecutionRankIfNeeded for projectId \(project.uuid) not required")
            return project
        }

        let flightPlans = flightPlanRepository.get(uuids: nil,
                                                   excludedUuids: nil,
                                                   projectUuids: [project.uuid],
                                                   projectPix4dUuids: nil,
                                                   states: nil,
                                                   types: nil,
                                                   excludedTypes: nil,
                                                   hasReachedFirstWaypoint: nil)
        guard !flightPlans.isEmpty else {
            ULog.e(.tag, "updateExecutionRankIfNeeded error : no flight plans found for projectId \(project.uuid)")
            return project
        }

        var executedFlightPlans = flightPlans.filter { $0.state != .editable }
            .sorted {
                $0.name.compare(
                    $1.name,
                    options: [.diacriticInsensitive, .numeric, .caseInsensitive])
                == .orderedAscending
            }

        guard !executedFlightPlans.isEmpty else {
            ULog.e(.tag, "updateExecutionRankIfNeeded error : no executed flight plans found for projectId \(project.uuid)")
            return project
        }

        let pictorContext = PictorContext.new()
        var rank = 0
        // - Reorder all project's flight plans if a nil executionRank is found
        // if flight plans are already reorder, set the rank to the highest executionRank found
        if executedFlightPlans.first(where: { $0.executionRank == nil || $0.executionRank == 0 }) != nil {
            rank = 0

            for index in executedFlightPlans.indices {
                rank += 1
                executedFlightPlans[index].executionRank = rank
            }

            // Extract the possible highest index from custom title
            // executionRank will bet set with the index if higher
            // this will avoid weird behavior if executions is reorder and
            // the last execution has title "Execution 54" but has a lower rank like 42
            // the next execution will be "Execution 43" instead of "Execution 55"
            let customTitles = executedFlightPlans.compactMap { $0.name }
            if let highestExecutionTitleIndex = customTitles.highestExecutionIndex,
               rank < highestExecutionTitleIndex {
                rank = highestExecutionTitleIndex
                executedFlightPlans[executedFlightPlans.count - 1].executionRank = rank
            }

            for (index, flightPlan) in executedFlightPlans.enumerated() {
                // Set the executionRank in the json dataSettings
                if let data = flightPlan.dataSetting {
                    let dataStr = String(decoding: data, as: UTF8.self)
                    if var dataSetting = FlightPlanDataSetting.instantiate(with: dataStr) {
                        dataSetting.executionRank = flightPlan.executionRank
                        executedFlightPlans[index].dataSetting = dataSetting.asData
                    }
                }
            }

            pictorContext.update(executedFlightPlans)
        } else {
            rank = executedFlightPlans.compactMap { $0.executionRank }.max() ?? 0
        }

        let latestExecutionIndex = project.latestExecutionIndex ?? 0
        if latestExecutionIndex < rank {
            project.latestExecutionIndex = rank
            pictorContext.update([project])
        }

        pictorContext.commit()
        ULog.i(.databaseUpdate,
               "updateExecutionRankIfNeeded: Project \(project.uuid) has reordered its executed flight plans with latestExecutionIndex = \(rank)")

        return project
    }

    public func setNextExecutionRank(forProjectId projectId: String) -> Int {
        guard var project = projectRepository.get(byUuid: projectId) else {
            ULog.e(.tag, "getNextExecutionRank for projectId \(projectId) not found")
            return 1
        }
        let latestExecutionRank = project.latestExecutionIndex ?? 0
        let nextExecutionRank = latestExecutionRank + 1
        project.latestExecutionIndex = nextExecutionRank
        project.lastUpdated = Date()

        let pictorContext = PictorContext.new()
        pictorContext.update([project])
        pictorContext.commit()
        ULog.i(.tag, "setNextExecutionRank for projectId \(projectId) with execution rank = \(nextExecutionRank)")
        return nextExecutionRank
    }

    public func cancelLastExecution(forProjectId projectId: String) {
        guard var project = projectRepository.get(byUuid: projectId) else {
            ULog.e(.tag, "cancelLastExecution for projectId \(projectId) not found")
            return
        }

        guard let latestExecutionRank = project.latestExecutionIndex else {
            ULog.i(.tag, "cancelLastExecution for projectId \(projectId) not needed: execution rank is already nil")
            return
        }
        if latestExecutionRank > 1 {
            project.latestExecutionIndex = latestExecutionRank - 1
        } else {
            project.latestExecutionIndex = nil
        }
        project.lastUpdated = Date()

        let pictorContext = PictorContext.new()
        pictorContext.update([project])
        pictorContext.commit()
        ULog.i(.tag, "cancelLastExecution for projectId \(projectId), new execution rank = \(project.latestExecutionIndex ?? -1)")
    }
}

private extension ProjectManagerImpl {

    func newProjectAndFlightPlan(flightPlanProvider: FlightPlanProvider,
                                 title: String? = nil,
                                 completion: @escaping ((_ project: ProjectModel?, _ flightPlan: FlightPlanModel?) -> Void)) {
        let pictorContext = PictorContext.new()

        // Generate the title according the current projects stored.
        // If a project with the same name already exists, add a suffix with the correct index.
        let title = newProjectTitle(for: title ?? flightPlanProvider.defaultProjectName)
        let captureMode = flightPlanProvider.defaultCaptureMode

        let dataSetting = FlightPlanDataSetting(product: FlightPlanConstants.defaultDroneModel,
                                                settings: [],
                                                freeSettings: [:],
                                                polygonPoints: [],
                                                mavlinkDataFile: nil,
                                                takeoffActions: [],
                                                pois: [],
                                                wayPoints: [],
                                                disablePhotoSignature: false,
                                                isPhotoSignatureEnabled: UserDefaults.photoDigitalSignature.isEnabled,
                                                captureMode: captureMode)

        let project = ProjectModel(title: title,
                                   type: flightPlanProvider.projectType,
                                   latestExecutionIndex: nil,
                                   lastUpdated: Date(),
                                   lastOpened: nil)
        pictorContext.createLocal([project])

        let pictorFlightPlan = PictorFlightPlanModel(name: title,
                                                     state: .editable,
                                                     flightPlanType: flightPlanProvider.typeKey,
                                                     formatVersion: FlightPlanModelVersion.latest,
                                                     lastUpdated: Date(),
                                                     fileType: "json",
                                                     dataSetting: dataSetting.asData,
                                                     mediaCount: 0,
                                                     uploadedMediaCount: 0,
                                                     lastMissionItemExecuted: 0,
                                                     executionRank: nil,
                                                     hasReachedFirstWaypoint: nil,
                                                     projectUuid: project.uuid,
                                                     projectPix4dUuid: nil,
                                                     thumbnail: nil)
        pictorContext.createLocal([pictorFlightPlan])
        pictorContext.commit()

        ULog.i(.tag, "newProjectAndFlightPlan: create project \(project.uuid) and associated flightPlan \(pictorFlightPlan.uuid)")
        completion(project, pictorFlightPlan.flightPlanModel)
    }

    func listenUserEvent() {
        userService.userEventPublisher
            .sink { [unowned self] userEvent in
                switch userEvent {
                case .didLogout:
                    resetLoadedProject()
                    updateProjectSummary()
                case .didLogin:
                    updateProjectSummary()
                    if currentProject == nil,
                       let flightPlanProvider = currentMissionManager.mode.flightPlanProvider {
                        // User just logged in, load latest opened project if no active one.
                        loadLastOpenedProject(type: flightPlanProvider.projectType)
                    }
                default:
                    // Nothing to do
                    break
                }
            }
            .store(in: &cancellables)
    }

    func listenProjectRepository() {
        projectRepository.didChangePublisher
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [unowned self] in
                projectsDidChangeSubject.send()
            }
            .store(in: &cancellables)

        flightPlanRepository.didCreatePublisher
            .merge(with: flightPlanRepository.didUpdatePublisher)
            .sink { [unowned self] _ in
                // - Update summary when a flight plan is created, updated or deleted
                // since count of projects is based on number of editable flight plan
                updateProjectSummary()
            }
            .store(in: &cancellables)

        projectRepository.didDeletePublisher
            .sink { [unowned self] _ in
                // - Update summary when a project is deleted with its assigned flight plans
                // since count of projects is based on number of editable flight plan
                updateProjectSummary()
            }
            .store(in: &cancellables)

        projectRepository.didDeleteAllPublisher
            .sink { [unowned self] in
                // - Update summary when all project are deleted with its assigned flight plans
                // since count of projects is based on number of editable flight plan
                updateProjectSummary()
            }
            .store(in: &cancellables)
    }

    func updateProjectSummary() {
        let countFlightPlans = flightPlanRepository.count(uuids: nil,
                                                          excludedUuids: nil,
                                                          projectUuids: nil,
                                                          projectPix4dUuids: nil,
                                                          states: [FlightPlanState.editable],
                                                          types: ["default"],
                                                          excludedTypes: nil,
                                                          hasReachedFirstWaypoint: nil)

        let countOtherFlightPlans = flightPlanRepository.count(uuids: nil,
                                                               excludedUuids: nil,
                                                               projectUuids: nil,
                                                               projectPix4dUuids: nil,
                                                               states: [FlightPlanState.editable],
                                                               types: nil,
                                                               excludedTypes: ["default"],
                                                               hasReachedFirstWaypoint: nil)

        allProjectSummarySubject.value.update(numberOfProjects: countFlightPlans + countOtherFlightPlans,
                                              totalFlightPlan: countFlightPlans,
                                              totalPgy: countOtherFlightPlans)
    }

    func resetLoadedProject() {
        clearCurrentProject()
        currentMissionManager.mode.stateMachine?.reset()
        editionService.resetFlightPlan()
    }

    /// Returns the project's executions.
    ///
    /// - Parameters:
    ///    - project: The project.
    ///    - excludeFlyingFlightPlan: Indicates if the flyng Flight Plan must be excluded.
    ///
    /// - Returns: The executions list.
    func executions(for project: ProjectModel, excludeFlyingFlightPlan: Bool) -> [FlightPlanModel] {
        // Get the list of executed FP (FP has reached first way point).
        var executions = getExecutedFlightPlans(ofProject: project)
        // Exclude, if needed, the flying FP.
        if excludeFlyingFlightPlan {
            executions = executions.filter { $0.uuid != flightPlanRunManager.playingFlightPlan?.uuid }
        }
        return executions
    }

    /// Returns the next execution customTitle for a project.
    ///
    /// - Parameter project: the project
    /// - Returns: the execution name (the FP's customTitle)
    func executionName(for rank: Int) -> String {
        "\(L10n.flightPlanExecutionName) \(rank)"
    }

    /// Returns the next duplicated project title.
    ///
    /// - Parameter project: the project to duplicate
    /// - Returns: the duplicated project name (the Project's title)
    func nextDuplicatedProjectTitle(for project: ProjectModel) -> String {
        // Get the current project name.
        // If his format doesn't match an already duplicated project, takes his complete title.
        let projectName = project.title.duplicatedProjectNameAndIndex?.name ?? project.title

        // 1 - Get the existing Projects' titles list.
        // 2 - Extract titles.
        // 3 - Generate the duplicated project title.
        return projectRepository.getTitles(like: projectName, excludedUuids: nil)
            .nextDuplicatedProjectTitle(for: projectName)
    }

    /// Returns a name by adding a suffix if needed.
    ///
    /// - Parameter name: the new name
    /// - Returns: the validated new name
    func alternativeName(for name: String, of project: ProjectModel?) -> String {
        // 1 - Get the existing Projects' titles list.
        // 2 - Exclude the project to rename.
        // 3 - Extract titles.
        // 4 - Generate the new project title.
        var excludeUuids: [String]?
        if let uuid = project?.uuid {
            excludeUuids = [uuid]
        }
        return projectRepository.getTitles(like: name, excludedUuids: excludeUuids)
            .newProjectTitle(for: name)
    }

    /// Returns the next new project title.
    /// If a project already exists with the same name, increment his index as it's done when creating a new project.
    ///
    /// - Parameter name: the wished project name
    /// - Returns: the new project name (the Project's title)
    func newProjectTitle(for name: String) -> String {
        // 1 - Get the existing Projects' titles list.
        // 2 - Extract titles.
        // 3 - Generate the new project title.
        projectRepository.getTitles(like: name, excludedUuids: nil)
            .newProjectTitle(for: name)
    }
}

/// ### New Project Naming Convention ###
///
/// An new created project takes the default project name returned by  `flightPlanProvider.defaultProjectName`.
/// His name is stored in the Project's `title` property. In case of a project with same default project name exists, a suffix index is added.
/// *Format*: `"{defaultProjectName} ({index})"` with index starting from 1.
/// The index 1 is not displayed (e.g. "FlightPlan", "FlightPlan (2)" ...).
///
///
/// ### Duplicated Project Naming Convention ###
///
/// An duplicated project adds a suffix to the duplicated project's title.
/// *Format*: `"{defaultProjectName} - copy ({index})"` with index starting from 1.
/// The index 1 is not displayed (e.g. "FlightPlan - copy", "FlightPlan - copy (2)" ...).
///
///
/// ### Project Executions Naming Convention ###
///
/// An execution name is stored in the FP's `customTitle` property.
/// *Format*: `"Execution {index}"` with index starting from 1 (e.g. "Execution 1", "Execution 2" ...)
/// An editable FP has a `customTitle` equals to his Project's `title`.
/// The FP's `customTitle` is updated to the execution name at the start of the FP.
/// If stopped before the first way point, the `customTitle` is resetted to his Project's `title`.
/// A resumed FP must keep the `customTitle` generated during the first launch.
///
///
/// ### Flight Plan Media Tag Naming Convention ###
///
/// The media tag is a string, sent to the drone, dedicated to identify the media stored in the Drone's memory.
/// *Format*: `"{project title} - {execution customTitle}"` (e.g. "My FP - Execution 1" ...)
extension String {

    /// Regex patterns used to handle Project and FP names.
    private struct RexgexPattern {
        /// Search for an execution name (e.g. `Execution 6`) and capture his index .
        static let executionName = "^" + L10n.flightPlanExecutionName + #" (\d+)$"#
        /// Search for a project title (e.g. `Flight Plan`, `Flight Plan (4)`) and capture his index.
        static func newProjectTitle(for name: String) -> String {
            #"^\#(NSRegularExpression.escapedPattern(for: name))(?: \((\d+)\))?"#
        }
        /// Search for a **duplicated** project title and capture his name and index (e.g. `Project Title - copy (5)`).
        static let duplicatedProjectNameAndIndex = #"(.*) - \#(L10n.flightPlanDuplicatedProjectSuffix)(?: \((\d+)\))?$"#
        /// Search for a **duplicated** project with a specific name, and capture his index.
        static func duplicatedProjectIndex(for name: String) -> String {
            let projectName = NSRegularExpression.escapedPattern(for: name)
            let duplicateSuffixName = NSRegularExpression.escapedPattern(for: L10n.flightPlanDuplicatedProjectSuffix)
            return #"^\#(projectName) - \#(duplicateSuffixName)(?: \((\d+)\))?$"#
        }
    }

    /// Returns the execution's index if the string is formatted as an execution name.
    ///
    /// ### Examples: ###
    ///          • `Execution 1`: returns `1`
    ///     • `Execution 23`: returns `23`
    ///     • `MyExecution 3`: returns `nil`
    ///     • `Flight Plan`: returns `nil`
    var executionIndex: Int? {
        // 1 - Check if the string match the execution name pattern.
        // 2 - Get the last match (should have just one).
        // 3 - Get the last catched group from this match (should have just one).
        // 4 - Convert String to Int.
        guard let result = try? search(regexPattern: RexgexPattern.executionName),
              let match = result.matches.last,
              let group = match.groups.last,
              let index = Int(group)
        else { return nil }
        return index
     }

    /// Returns the project's name and duplication index if it has already been duplicated.
    ///
    /// ### Examples: ###
    ///          • `Flight Plan (3)`: returns `nil`
    ///     • `My FP (23) - copy`: returns `("My FP (23)", 1)`
    ///     • `Flight Plan - copy (2)`: returns `("Flight Plan", 2)`
    var duplicatedProjectNameAndIndex: (name: String, index: Int)? {
        // 1 - Check if the string match the duplicated project name pattern.
        // 2 - Get the last match (should have just one).
        // 3 - Ensure at least one group have been catched (one for the name and the optional second for the index).
        guard let result = try? search(regexPattern: RexgexPattern.duplicatedProjectNameAndIndex),
              let match = result.matches.last,
              !match.groups.isEmpty else {
                  // It's not a title formatted as expected.
                  return nil
              }
        // 4 - Get the project name (should be the first catched group).
        guard let projectName = match.groups.first else { return nil }
        // 5 - Get the index if exists.
        // If there is no index but the pattern matched ('Flight Plan - copy') set current index to 1.
        let duplicationIndex = Int(match.groups.last ?? "1") ?? 1
        return (projectName, duplicationIndex)
    }

    /// Returns the duplication project's index, if it has already been duplicated, for a specific project name.
    ///
    ///  - Parameter projectName: the project's name to match
    ///  - Returns: the index if the title matches the pattern, `nil`in other cases
    func duplicatedProjectIndex(for projectName: String) -> Int? {
        // 1 - Check if the string match the duplicated project name pattern.
        // 2 - Get the last match (should have just one).
        guard let result = try? search(regexPattern: RexgexPattern.duplicatedProjectIndex(for: projectName),
                                       isCaseInsensitive: true),
              let match = result.matches.last else {
                  // It's not a title formatted as expected.
                  return nil
              }
        // 3 - Get the last catched group from this match (can be empty or contains one value).
        // 4 - Convert String to Int.
        guard let group = match.groups.last,
              let index = Int(group)
        else {
            // The title match the pattern but without index (The index 1 is not shown: 'Flight Plan - copy').
            return 1
        }
        return index
    }

    /// Returns the project's index if the string is formatted as a new project name.
    ///
    ///  - Parameter name: the new project name
    ///  - Returns: the index if the project is found, or `nil`in other cases
    ///
    /// ### Examples: ###
    ///          • `Flight Plan (3)`: returns `3`
    ///     • `My FP (23)`: returns `nil`
    ///     • `Flight Plan`: returns `1`
    func newProjectTitleIndex(for name: String) -> Int? {
        // 1 - Check if the string match the new project name pattern.
        // 2 - Get the last match (should have just one).
        guard let result = try? search(regexPattern: RexgexPattern.newProjectTitle(for: name),
                                       isCaseInsensitive: true),
              let match = result.matches.last else {
                  // It's not a title formatted as a new project name.
                  return nil
              }
        // 3 - Get the last catched group from this match (can be empty or contains one value).
        // 4 - Convert String to Int.
        guard let group = match.groups.last,
              let index = Int(group)
        else {
            // The title match the pattern but without index (The index 1 is not shown: 'Flight Plan').
            return 1
        }
        return index
    }
}

extension Array where Element == String {

    /// Returns the highest execution index for a given list of execution name.
    var highestExecutionIndex: Int? {
        compactMap { $0.executionIndex }.max()
    }

    /// Returns the next execution name according the titles list.
    /// If no execution index is found, start the count to 1, else increment the highest index.
    var nextExecutionName: String {
        L10n.flightPlanExecutionName + " \((highestExecutionIndex ?? 0) + 1)"
    }

    /// Returns the next duplicated project name for a specified project name according titles list.
    ///
    ///  - Parameter projectName: the project's name to match
    ///  - Returns: the duplicated project's title
    func nextDuplicatedProjectTitle(for projectName: String) -> String {
        let title = projectName + " - " + L10n.flightPlanDuplicatedProjectSuffix
        // Search the highest duplicated project index.
        guard let maxIndex = compactMap({ $0.duplicatedProjectIndex(for: projectName) }).max()
        else {
            // The project is not yet duplicated.
            return title
        }
        return title + " (\(maxIndex + 1))"
    }

    /// Returns the new project name by checking the provided projects' titles list.
    ///
    ///  - Parameter name: the project  name
    ///  - Returns: the new project's name
    func newProjectTitle(for name: String) -> String {
        let title = name
        // Serach the highest new project index.
        guard let maxIndex = compactMap({ $0.newProjectTitleIndex(for: name) }).max()
        else {
            // There is currently no project. Returns the default project name without Index.
            return title
        }
        return title + " (\(maxIndex + 1))"
    }
}
