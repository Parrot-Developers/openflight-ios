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

    /// `AllFlightsSummary`'s default values
    public static let defaultValues = AllProjectsSummary()

    private func summaryForProjects(_ projects: [ProjectModel]) -> (numberOfProjects: Int, totalFlightPlan: Int, totalPgy: Int) {
        (projects.count,
         projects.filter { $0.isSimpleFlightPlan }.count,
         projects.filter { !$0.isSimpleFlightPlan }.count)
    }

    public mutating func addProjects(_ projects: [ProjectModel]) {
        let summary = summaryForProjects(projects)
        numberOfProjects += summary.numberOfProjects
        totalFlightPlan += summary.totalFlightPlan
        totalPgy += summary.totalPgy
    }

    public mutating func removeProjects(_ projects: [ProjectModel]) {
        let summary = summaryForProjects(projects)
        numberOfProjects -= summary.numberOfProjects
        totalFlightPlan -= summary.totalFlightPlan
        totalPgy -= summary.totalPgy
    }

    public mutating func removeAllProjects() {
        numberOfProjects = 0
        totalFlightPlan = 0
        totalPgy = 0
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

    /// Whether the current project has just been created.
    var isCurrentProjectBranNew: Bool { get set }

    /// Loads Projects.
    /// - Returns: the created project
    func loadProjects(type: ProjectType?) -> [ProjectModel]

    /// Loads executed projects, ordered by last execution date desc
    func loadExecutedProjects() -> [ProjectModel]

    /// Loads all projects
    func loadAllProjects() -> [ProjectModel]

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

    /// Get the last flight plan used for a specific project
    ///
    /// - Parameters:
    ///     - project:project to consider
    /// - Returns: the last flight plan used or nil if there 's no flight plan in this project
    func lastFlightPlan(for project: ProjectModel) -> FlightPlanModel?

    /// Deletes a flight plan.
    ///
    /// - Parameters:
    ///     - project: project to delete
    func delete(project: ProjectModel)

    /// Duplicates Flight Plan.
    ///
    /// - Parameters:
    ///     - project: project to duplicate
    @discardableResult
    func duplicate(project: ProjectModel) -> ProjectModel

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
    func rename(_ project: ProjectModel, title: String)

    /// Sets up selcted project as last used.
    ///
    /// - Parameters:
    ///     - project: project model
    func setAsLastUsed(_ project: ProjectModel) -> ProjectModel

    /// Sets up project as current.
    ///
    /// - Parameters:
    ///     - project: project model
    func setCurrent(_ project: ProjectModel)

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

    /// Starts edition of current project.
    func startEdition()

    /// Update a Flight Plan's `customTitle` according his execution position.
    ///
    /// - Parameters:
    ///    - flightPlan: The flight plan execution.
    ///
    /// - Returns: The updated `FlightPlanModel`.
    @discardableResult
    func updateExecutionCustomTitle(for flightPlan: FlightPlanModel) -> FlightPlanModel

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
}

private extension ULogTag {
    static let tag = ULogTag(name: "ProjectManager")
}

public class ProjectManagerImpl {

    private enum Constants {
        public static let defaultFlightPlanVersion: Int = 1
    }

    private let flightPlanTypeStore: FlightPlanTypeStore
    private let flightPlanRepo: FlightPlanRepository
    private let persistenceProject: ProjectRepository
    private let editionService: FlightPlanEditionService
    private let currentMissionManager: CurrentMissionManager
    private let userService: UserService
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

    public var isCurrentProjectBranNew: Bool = false

    // MARK: - Private Properties
    private var currentProjectSubject = CurrentValueSubject<ProjectModel?, Never>(nil)
    private var projectsDidChangeSubject = PassthroughSubject<Void, Never>()
    private var allProjectSummarySubject = CurrentValueSubject<AllProjectsSummary, Never>(AllProjectsSummary())
    private var hideExecutionsListSubject = PassthroughSubject<Void, Never>()
    private var startEditionSubject = PassthroughSubject<Void, Never>()

    init(missionsStore: MissionsStore,
         flightPlanTypeStore: FlightPlanTypeStore,
         persistenceProject: ProjectRepository,
         flightPlanRepo: FlightPlanRepository,
         editionService: FlightPlanEditionService,
         currentMissionManager: CurrentMissionManager,
         userService: UserService,
         filesManager: FlightPlanFilesManager,
         flightPlanManager: FlightPlanManager,
         flightPlanRunManager: FlightPlanRunManager) {
        self.missionsStore = missionsStore
        self.flightPlanTypeStore = flightPlanTypeStore
        self.persistenceProject = persistenceProject
        self.flightPlanRepo = flightPlanRepo
        self.editionService = editionService
        self.currentMissionManager = currentMissionManager
        self.userService = userService
        self.filesManager = filesManager
        self.flightPlanManager = flightPlanManager
        self.flightPlanRunManager = flightPlanRunManager

        refreshAllProjectsSummary()

        listenUserEvent()
        listenProjectsListChanges()
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

    public func loadAllProjects() -> [ProjectModel] {
        loadProjects(type: nil)
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

        newProjectAndFlightPlan(
            flightPlanProvider: flightPlanProvider,
            title: url.deletingPathExtension().lastPathComponent,
            completion: { [weak self] project, flightPlan in
                guard let self = self,
                      let newProject = project,
                      let newFlightPlan = flightPlan else {
                          ULog.e(.tag, "New project from Mavlink file: failed")
                          completion(nil)
                          return
                }

                var flightPlan = newFlightPlan

                flightPlan = MavlinkToFlightPlanParser
                    .generateFlightPlanFromMavlinkStandard(url: url,
                                                           flightPlan: flightPlan) ?? flightPlan
                flightPlan.dataSetting?.readOnly = true
                flightPlan.dataSetting?.mavlinkDataFile = try? Data(contentsOf: url)
                self.flightPlanRepo.saveOrUpdateFlightPlan(flightPlan,
                                                           byUserUpdate: true,
                                                           toSynchro: true,
                                                           withFileUploadNeeded: true,
                                                           completion: { didSave in
                    if didSave {
                        completion(newProject)
                    } else {
                        completion(nil)
                    }
                })
            })
    }

    public func flightPlans(for project: ProjectModel) -> [FlightPlanModel] {
        persistenceProject.getFlightPlans(ofProject: project)
    }

    public func executedFlightPlans(for project: ProjectModel) -> [FlightPlanModel] {
        executions(for: project, excludeFlyingFlightPlan: true)
    }

    public func executions(for project: ProjectModel) -> [FlightPlanModel] {
        executions(for: project, excludeFlyingFlightPlan: false)
    }

    public func lastFlightPlan(for project: ProjectModel) -> FlightPlanModel? {
        flightPlans(for: project).first
    }

    public func loadProjects(type: ProjectType?) -> [ProjectModel] {
        if let type = type {
            return persistenceProject.getProjects(withType: type.rawValue)
        } else {
            return persistenceProject.getAllProjects()
        }
    }

    public func loadExecutedProjects() -> [ProjectModel] {
        persistenceProject.getExecutedProjectsWithFlightPlans()
    }

    public func delete(project: ProjectModel) {
        ULog.i(.tag, "Deleting project '\(project.uuid)' '\(project.title ?? "")'")
        for flightPlan in flightPlans(for: project) {
            // There are side effects to manage (delete mavlink,...), let the manager do the job
            flightPlanManager.delete(flightPlan: flightPlan)
        }
        persistenceProject.deleteOrFlagToDeleteProject(withUuid: project.uuid)
        if project.uuid == currentProject?.uuid {
            resetLoadedProject()
            loadLastProject(type: project.type)
        }
    }

    public func rename(_ project: ProjectModel, title: String) {
        // Ensure the new name is different from the previous one.
        guard project.title != title else { return }
        // Generate an unique title.
        // If the new title is already used by another project,
        // use the same rule than for a project creation (adding ' ({index})' suffix).
        let newTitle = renamedProjectTitle(for: title, of: project)
        ULog.i(.tag, "Rename project '\(project.uuid)' from '\(project.title ?? "")' to '\(newTitle)' (expected: \(title)")
        var project = project
        // Update the title and save the project.
        project.title = newTitle
        persistenceProject.saveOrUpdateProject(project, byUserUpdate: true, toSynchro: true)
        // Rename the customTitle of the project's editable FP.
        if var flightPlan = lastFlightPlan(for: project),
           flightPlan.state == .editable {
            flightPlan.customTitle = newTitle
            flightPlanRepo.saveOrUpdateFlightPlan(flightPlan, byUserUpdate: true, toSynchro: true)
            editionService.setupFlightPlan(flightPlan)
        }
        // Update the current project
        if project.uuid == currentProject?.uuid {
            currentProject?.title = newTitle
        }
    }

    @discardableResult
    public func duplicate(project: ProjectModel) -> ProjectModel {
        let duplicatedProjectID = UUID().uuidString
        var duplicatedFlightPlans: [FlightPlanModel] = []

        // Generate the duplicated project's title.
        let title = nextDuplicatedProjectTitle(for: project)

        // Get the last project's FP (a project must always contains at least one FP) to duplicate it.
        if let flightPlan = lastFlightPlan(for: project) {
            var duplicatedFlightPlan = flightPlanManager.newFlightPlan(basedOn: flightPlan,
                                                                       save: false)
            duplicatedFlightPlan.customTitle = title
            duplicatedFlightPlan.projectUuid = duplicatedProjectID
            duplicatedFlightPlan.apcId = userService.currentUser.apcId
            duplicatedFlightPlans.append(duplicatedFlightPlan)
        }

        let duplicatedProject = ProjectModel(duplicateProject: project,
                                             withApcId: userService.currentUser.apcId,
                                             uuid: duplicatedProjectID,
                                             title: title)

        persistenceProject.saveOrUpdateProject(duplicatedProject, byUserUpdate: true, toSynchro: true)
        flightPlanRepo.saveOrUpdateFlightPlans(duplicatedFlightPlans, byUserUpdate: true, toSynchro: true)
        currentProject = duplicatedProject
        // A duplicated project is treated as 'brand new' project.
        isCurrentProjectBranNew = true
        ULog.i(.tag, "Duplicate project '\(project.uuid)' '\(project.title ?? "")' -> '\(duplicatedProject.uuid)'."
               + " Duplicated flightPlans: " + duplicatedFlightPlans.map({ "'\($0.uuid)'" }).joined(separator: ", "))
        return duplicatedProject
    }

    public func setCurrent(_ project: ProjectModel) {
        currentProject = setAsLastUsed(project)
        // Reset the flag informing about the project creation.
        isCurrentProjectBranNew = false
    }

    public func setLastOpenedProjectAsCurrent(type: ProjectType) {
        currentProject = loadProjects(type: type).sorted(by: { $0.lastOpened ?? $0.lastUpdated > $1.lastOpened ?? $1.lastUpdated }).first
        // Reset the flag informing about the project creation.
        isCurrentProjectBranNew = false
    }

    public func setAsLastUsed(_ project: ProjectModel) -> ProjectModel {
        // Save date in file.
        var newProject = project
        newProject.lastUpdated = Date()
        // Save Flight Plan.
        persistenceProject.saveOrUpdateProject(newProject, byUserUpdate: true, toSynchro: true)
        return newProject
    }

    public func project(for flightPlan: FlightPlanModel) -> ProjectModel? {
        persistenceProject.getProject(withUuid: flightPlan.projectUuid)
    }

    public func clearCurrentProject() {
        currentProject = nil
        // Reset the flag informing about the project creation.
        isCurrentProjectBranNew = false
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

        // Update `lastOpened` date in order to be able to correctly reload latest project when needed.
        // (Used in `setLastOpenedProjectAsCurrent` and `loadLastProject()`)
        project.lastOpened = Date()

        var missionProvider: MissionProvider?
        var missionMode: MissionMode?
        for provider in missionsStore.allMissions {
            if provider.mission.defaultMode.flightPlanProvider?.hasFlightPlanType(flightPlan.type) ?? false {
                missionProvider = provider
                missionMode = provider.mission.defaultMode
            }
        }
        guard let mPovider = missionProvider, let mMode = missionMode else { return }
        ULog.i(.tag, "Opening flightPlan '\(flightPlan.uuid)' of project '\(project.uuid)' '\(project.title ?? "")'")

        // Locally save project with updated `lastOpened` date.
        // (Do not need to be synchronized, as information is only intended to be locally used.)
        persistenceProject.saveOrUpdateProject(project, byUserUpdate: false, toSynchro: false)

        // Setup Mission as a Flight Plan mission (may be custom).
        currentMissionManager.set(provider: mPovider)
        currentMissionManager.set(mode: mMode)
        currentProject = project
        isCurrentProjectBranNew = isBrandNew
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
        guard let flightPlan = lastFlightPlan(for: project) else {
            ULog.i(.tag, "No Flight Plan found for project '\(project.uuid)' '\(project.title ?? "")'")
            return
        }
        ULog.i(.tag, "Opening \(isBrandNew ? "brand new" : "") project '\(project.uuid)' '\(project.title ?? "")' will continue"
               + " opening flightPlan '\(flightPlan.uuid)'")
        loadEverythingAndOpen(flightPlan: flightPlan,
                              autoStart: false,
                              isBrandNew: isBrandNew)
    }

    public func startEdition() {
        startEditionSubject.send()
    }

    @discardableResult
    public func updateExecutionCustomTitle(for flightPlan: FlightPlanModel) -> FlightPlanModel {
        // Ensure Flight Plan has a project.
        guard let project = project(for: flightPlan) else { return flightPlan }
        // Generate the execution name then update the flight plan customTitle.
        let customTitle = nextExecutionName(for: project)
        return flightPlanManager.update(flightplan: flightPlan, with: customTitle)
    }

    @discardableResult
    public func resetExecutionCustomTitle(for flightPlan: FlightPlanModel) -> FlightPlanModel {
        // Ensure Flight Plan has a project with a title.
        guard let project = project(for: flightPlan),
        let projectTitle = project.title else { return flightPlan }
        // Update the FP with the project's title.
        return flightPlanManager.update(flightplan: flightPlan, with: projectTitle)
    }

    public func mediaTag(for flightPlan: FlightPlanModel) -> String? {
        // Ensure the FP is linked to a project with a name.
        guard let project = project(for: flightPlan),
              let projectTitle = project.title
        else { return nil }
        // Returns the media tag with the following format:
        // "{project name} - {execution name}"
        // Examples:
        //    • "My FP - Execution 1"
        //    • "Flight Plan (3) - Execution 2"
        //    • "My FP - copy (3) - Execution 5"
        let mediaTag = projectTitle + " - " + flightPlan.customTitle
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
        persistenceProject.getAllProjects()
            .compactMap(\.title)
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
}

private extension ProjectManagerImpl {

    func newProjectAndFlightPlan(flightPlanProvider: FlightPlanProvider,
                                 title: String? = nil,
                                 completion: @escaping ((_ project: ProjectModel?, _ flightPlan: FlightPlanModel?) -> Void)) {
        let uuid = UUID().uuidString

        // Generate the title according the current projects stored.
        // If a project with the same name already exists, add a suffix with the correct index.
        let title = newProjectTitle(for: title ?? flightPlanProvider.defaultProjectName)

        let dataSetting = FlightPlanDataSetting(product: FlightPlanConstants.defaultDroneModel,
                                                settings: [],
                                                freeSettings: [:],
                                                polygonPoints: [],
                                                mavlinkDataFile: nil,
                                                takeoffActions: [],
                                                pois: [],
                                                wayPoints: [],
                                                disablePhotoSignature: false)

        let flightPlan = FlightPlanModel(apcId: userService.currentUser.apcId,
                                         type: flightPlanProvider.typeKey,
                                         uuid: UUID().uuidString,
                                         version: String(Constants.defaultFlightPlanVersion),
                                         customTitle: title,
                                         thumbnailUuid: nil,
                                         projectUuid: uuid,
                                         dataStringType: "json",
                                         dataString: dataSetting.toJSONString(),
                                         pgyProjectId: nil,
                                         state: .editable,
                                         lastMissionItemExecuted: nil,
                                         mediaCount: 0,
                                         uploadedMediaCount: nil,
                                         lastUpdate: Date(),
                                         synchroStatus: .notSync,
                                         fileSynchroStatus: 0,
                                         latestSynchroStatusDate: nil,
                                         cloudId: nil,
                                         parrotCloudUploadUrl: nil,
                                         isLocalDeleted: false,
                                         latestCloudModificationDate: nil,
                                         uploadAttemptCount: nil,
                                         lastUploadAttempt: nil,
                                         thumbnail: nil,
                                         flightPlanFlights: [],
                                         latestLocalModificationDate: Date(),
                                         synchroError: .noError)

        let project = ProjectModel(apcId: userService.currentUser.apcId,
                                   uuid: uuid,
                                   title: title,
                                   type: flightPlanProvider.projectType)

        let dispatchGroup = DispatchGroup()
        var didSaveProject = false
        var didSaveFlightPlan = false

        dispatchGroup.enter()
        persistenceProject.saveOrUpdateProject(project, byUserUpdate: true, toSynchro: true, completion: { didSave in
            didSaveProject = didSave
            dispatchGroup.leave()
        })

        dispatchGroup.enter()
        flightPlanRepo.saveOrUpdateFlightPlan(flightPlan, byUserUpdate: true, toSynchro: true, withFileUploadNeeded: false, completion: { didSave in
            didSaveFlightPlan = didSave
            dispatchGroup.leave()
        })

        dispatchGroup.notify(queue: .main) { [unowned self] in
            if didSaveProject && didSaveFlightPlan {
                completion(project, flightPlan)
            } else {
                ULog.e(.tag, "newProjectAndFlightPlan: Couldn't create project \(project.uuid) and associated flightPlan \(flightPlan.uuid)")
                persistenceProject.deleteProjects(withUuids: [project.uuid])
                flightPlanRepo.deleteFlightPlans(withUuids: [flightPlan.uuid])
                completion(nil, nil)
            }
        }
    }

    func listenUserEvent() {
        userService.userEventPublisher
            .sink { [unowned self] userEvent in
                refreshAllProjectsSummary()

                if userEvent == .didLogout {
                    resetLoadedProject()
                }
            }
            .store(in: &cancellables)
    }

    func listenProjectsListChanges() {

        persistenceProject.projectsDidChangePublisher
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [unowned self] in
                projectsDidChangeSubject.send()
            }
            .store(in: &cancellables)

        // Listen when some Projects are added.
        persistenceProject.projectsAddedPublisher
            .sink { [unowned self] addedProjects in
                allProjectSummarySubject.value.addProjects(addedProjects)
            }
            .store(in: &cancellables)

        // Listen when some Projects are removed.
        persistenceProject.projectsRemovedPublisher
            .sink { [unowned self] removedProjects in
                allProjectSummarySubject.value.removeProjects(removedProjects)
            }
            .store(in: &cancellables)

        // Listen all Projects deletion.
        persistenceProject.allProjectsRemovedPublisher
            .sink { [unowned self] in
                allProjectSummarySubject.value.removeAllProjects()
            }
            .store(in: &cancellables)

    }

    func resetLoadedProject() {
        clearCurrentProject()
        currentMissionManager.mode.stateMachine?.reset()
        editionService.resetFlightPlan()
    }

    func loadLastProject(type: ProjectType) {
        guard let newProject = loadProjects(type: type)
                .sorted(by: { $0.lastOpened ?? $0.lastUpdated > $1.lastOpened ?? $1.lastUpdated })
                .first,
              let flightPlan = lastFlightPlan(for: newProject) else { return }
        ULog.i(.tag, "Opening flightPlan '\(flightPlan.uuid)' of project '\(newProject.uuid)' '\(newProject.title ?? "")'")
        setCurrent(newProject)
        currentMissionManager.mode.stateMachine?.open(flightPlan: flightPlan)
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
        var executions = persistenceProject.getExecutedFlightPlans(ofProject: project)
        // Exclude, if needed, the flying FP.
        if excludeFlyingFlightPlan {
            executions = executions.filter { $0.uuid != flightPlanRunManager.playingFlightPlan?.uuid }
        }
        // Re-order executions with no associated Flight at top of the list.
        // Note: A FP is linked to a Flight only after the Drone landed and Gutma received.
        let syncedExecutions = executions.filter { !($0.flightPlanFlights?.isEmpty ?? true) }
        let unsyncedExecutions = executions.filter { $0.flightPlanFlights?.isEmpty ?? true }
        return unsyncedExecutions + syncedExecutions
    }

    /// Returns the next execution customTitle for a project.
    ///
    /// - Parameter project: the project
    /// - Returns: the execution name (the FP's customTitle)
    func nextExecutionName(for project: ProjectModel) -> String {
        // Get the project's executions list.
        let executions = executions(for: project)
        // Extract customTitles and generate the next execution name.
        return executions.map(\.customTitle).nextExecutionName
    }

    /// Returns the next duplicated project title.
    ///
    /// - Parameter project: the project to duplicate
    /// - Returns: the duplicated project name (the Project's title)
    func nextDuplicatedProjectTitle(for project: ProjectModel) -> String {
        // Get the current project name.
        // If his format doesn't match an already duplicated project, takes his complete title.
        let projectName = project.title?.duplicatedProjectNameAndIndex?.name ?? project.title
        guard let projectName = projectName else {
            ULog.e(.tag, "Trying to duplicated a project without name.")
            // Should never occurs.
            return Style.dash
        }
        // 1 - Get the existing Projects' titles list.
        // 2 - Extract titles.
        // 3 - Generate the duplicated project title.
        return persistenceProject.getAllProjects()
            .compactMap(\.title)
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
        persistenceProject.getAllProjects()
            .filter { $0.uuid != project?.uuid }
            .compactMap(\.title)
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
        persistenceProject.getAllProjects()
            .compactMap(\.title)
            .newProjectTitle(for: name)
    }

    /// Refresh all projects summary
    func refreshAllProjectsSummary() {
        let allProjects = persistenceProject.getAllProjects()
        let totalFlightPlan = allProjects.filter { $0.isSimpleFlightPlan }.count
        let totalPgy = allProjects.filter { !$0.isSimpleFlightPlan }.count

        allProjectSummarySubject.value = AllProjectsSummary(numberOfProjects: allProjects.count,
                                                            totalFlightPlan: totalFlightPlan,
                                                            totalPgy: totalPgy)
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
private extension String {

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
        guard let result = try? search(regexPattern: RexgexPattern.duplicatedProjectIndex(for: projectName)),
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
        guard let result = try? search(regexPattern: RexgexPattern.newProjectTitle(for: name)),
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

private extension Array where Element == String {

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
