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

public protocol ProjectManager {

    /// Current project publisher
    var currentProjectPublisher: AnyPublisher<ProjectModel?, Never> { get }

    /// All Projects publisher
    var projectsPublisher: AnyPublisher<[ProjectModel], Never> { get }

    /// Current project
    var currentProject: ProjectModel? { get }

    /// Loads Projects.
    /// - Returns: the created project
    func loadProjects(type: String?) -> [ProjectModel]

    /// Loads executed projects, ordered by last execution date desc
    func loadExecutedProjects() -> [ProjectModel]

    /// Creates new Project.
    ///
    /// - Parameters:
    ///     - flightPlanProvider: Flight Plan provider
    /// - Returns: the created project
    func newProject(flightPlanProvider: FlightPlanProvider) -> ProjectModel

    /// Fetch ordered flight plans for a project
    /// - Parameter project: the project
    func flightPlans(for project: ProjectModel) -> [FlightPlanModel]

    /// Fetch ordered executed flight plans for a project
    /// - Parameter project: the project
    func executedFlightPlans(for project: ProjectModel) -> [FlightPlanModel]

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
    func duplicate(project: ProjectModel)

    /// Loads last opened project (if exists).
    ///
    /// - Parameters:
    ///     - state: mission state
    func setLastOpenedProjectAsCurrent(type: String)

    /// Sets up title project.
    ///
    /// - Parameters:
    ///     - project: the project
    ///     - title: optional string
    func rename(_ project: ProjectModel, title: String?)

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

    /// Setup everything (mission, project, flight plan) to open the project's flight plan
    /// - Parameter project: the project
    func loadEverythingAndOpen(project: ProjectModel)
}

public class ProjectManagerImpl {

    private enum Constants {
        public static let regexInt: String = "\\d+"
        public static let regexNameSuffix: String = " \\(\\d+\\)"
        public static let defaultFlightPlanVersion: Int = 1
    }

    private let flightPlanTypeStore: FlightPlanTypeStore
    private let flightPlanRepo: FlightPlanRepository
    private let persistenceProject: ProjectRepository
    private let editionService: FlightPlanEditionService
    private let currentMissionManager: CurrentMissionManager
    private let currentUser: UserInformation
    private let filesManager: FlightPlanFilesManager
    private let missionsStore: MissionsStore

    /// Publisher of `ProjectModel` array
    public var projectsPublisher: AnyPublisher<[ProjectModel], Never> {
        return persistenceProject.projectsPublisher
    }

    private var cancellables = [AnyCancellable]()

    // MARK: - Public Properties
    private var currentProjectSubject = CurrentValueSubject<ProjectModel?, Never>(nil)

    init(missionsStore: MissionsStore,
         flightPlanTypeStore: FlightPlanTypeStore,
         persistenceProject: ProjectRepository,
         flightPlanRepo: FlightPlanRepository,
         editionService: FlightPlanEditionService,
         currentMissionManager: CurrentMissionManager,
         currentUser: UserInformation,
         filesManager: FlightPlanFilesManager) {
        self.missionsStore = missionsStore
        self.flightPlanTypeStore = flightPlanTypeStore
        self.persistenceProject = persistenceProject
        self.flightPlanRepo = flightPlanRepo
        self.editionService = editionService
        self.currentMissionManager = currentMissionManager
        self.currentUser = currentUser
        self.filesManager = filesManager
    }
}

extension ProjectManagerImpl: ProjectManager {

    public var currentProjectPublisher: AnyPublisher<ProjectModel?, Never> {
        currentProjectSubject.eraseToAnyPublisher()
    }

    private(set) public var currentProject: ProjectModel? {
        get {
            currentProjectSubject.value
        }
        set {
            currentProjectSubject.value = newValue
        }
    }

    public func newProject(flightPlanProvider: FlightPlanProvider) -> ProjectModel {
        let uuid = UUID().uuidString
        let newTitle = titleFromDuplicateTitle(L10n.flightPlanNewProject)
        let flightPlanTitle = titleFromDuplicateTitle(L10n.flightPlanNewFlightPlan)
        let dataSetting = FlightPlanDataSetting(product: FlightPlanConstants.defaultDroneModel,
                                                settings: flightPlanProvider.settingsProvider?.settings.toLightSettings() ?? [],
                                                freeSettings: [:],
                                                polygonPoints: [],
                                                mavelinkDataFile: nil,
                                                takeoffActions: [],
                                                pois: [],
                                                wayPoints: [],
                                                disablePhotoSignature: false)

        let flightplan = FlightPlanModel(apcId: currentUser.apcId,
                                          type: flightPlanProvider.typeKey,
                                          uuid: UUID().uuidString,
                                          version: String(Constants.defaultFlightPlanVersion),
                                          customTitle: flightPlanTitle,
                                          thumbnailUuid: nil,
                                          projectUuid: uuid,
                                          dataStringType: "json",
                                          dataString: dataSetting.toJSONString(),
                                          pgyProjectId: nil,
                                          mediaCustomId: nil,
                                          state: .editable,
                                          lastMissionItemExecuted: nil,
                                          mediaCount: 0,
                                          uploadedMediaCount: nil,
                                          lastUpdate: Date(),
                                          synchroStatus: 0,
                                          fileSynchroStatus: 0,
                                          synchroDate: nil,
                                          parrotCloudId: nil,
                                          parrotCloudUploadUrl: nil,
                                          parrotCloudToBeDeleted: false,
                                          cloudLastUpdate: nil,
                                          uploadAttemptCount: nil,
                                          lastUploadAttempt: nil,
                                          thumbnail: nil,
                                          flightPlanFlights: [])

        let project = ProjectModel(
            apcId: currentUser.apcId,
            uuid: uuid,
            title: newTitle,
            type: flightPlanProvider.projectType,
            lastUpdated: Date()
        )
        persistenceProject.persist(project, true)
        flightPlanRepo.persist(flightplan, true)
        return project
    }

    public func flightPlans(for project: ProjectModel) -> [FlightPlanModel] {
        persistenceProject.flightPlans(of: project)
    }

    public func executedFlightPlans(for project: ProjectModel) -> [FlightPlanModel] {
        persistenceProject.executedFlightPlan(of: project)
    }

    public func lastFlightPlan(for project: ProjectModel) -> FlightPlanModel? {
        flightPlans(for: project).first
    }

    public func loadProjects(type: String?) -> [ProjectModel] {
        if let type = type {
            return persistenceProject.loadAllProjects()
                .filter { $0.type == type }
        } else {
            return persistenceProject.loadAllProjects()
        }
    }

    public func loadExecutedProjects() -> [ProjectModel] {
        persistenceProject.executedProjects()
    }

    public func delete(project: ProjectModel) {
        for flightPlan in flightPlans(for: project) {
            filesManager.deleteMavlink(of: flightPlan)
        }
        persistenceProject.removeProject(project.uuid)
        if project.uuid == currentProject?.uuid {
            clearCurrentProject()
            currentMissionManager.mode.stateMachine?.reset()
            editionService.resetFlightPlan()
            guard let newProject = loadProjects(type: project.type).sorted(by: { $0.lastUpdated > $1.lastUpdated }).first,
                  let flightplan = lastFlightPlan(for: newProject) else { return }
            setCurrent(newProject)
            currentMissionManager.mode.stateMachine?.open(flightPlan: flightplan)
        }
    }

    public func rename(_ project: ProjectModel, title: String?) {
        var project = project
        guard let oldTitle = project.title else { return }
        let newTitle = titleFromRenameTitle(title, oldTitle: oldTitle)
        guard newTitle != oldTitle else { return }
        project.title = newTitle
        persistenceProject.persist(project, true)
        if let flightPlan = lastFlightPlan(for: project) {
            editionService.rename(flightPlan, title: newTitle)
        }
        if project.uuid == currentProject?.uuid {
            currentProject?.title = newTitle
        }
    }

    public func duplicate(project: ProjectModel) {

        let projectID = UUID().uuidString
        var duplicatedFlightPlans: [FlightPlanModel] = []

        if let flightPlan = lastFlightPlan(for: project) {
            flightPlan.dataSetting?.mavelinkDataFile = nil
            let thumbnailUUID = UUID().uuidString

            var duplicatedFlightPlan = flightPlan
            duplicatedFlightPlan.customTitle = titleFromDuplicateTitle(project.title)
            duplicatedFlightPlan.uuid = UUID().uuidString
            duplicatedFlightPlan.lastUpdate = Date()
            duplicatedFlightPlan.state = .editable
            duplicatedFlightPlan.projectUuid = projectID
            duplicatedFlightPlan.lastMissionItemExecuted = 0
            duplicatedFlightPlan.pgyProjectId = 0
            duplicatedFlightPlan.uploadedMediaCount = 0
            duplicatedFlightPlan.parrotCloudId = 0
            duplicatedFlightPlan.parrotCloudToBeDeleted = false
            duplicatedFlightPlan.parrotCloudUploadUrl = nil
            duplicatedFlightPlan.synchroDate = nil
            duplicatedFlightPlan.thumbnail = ThumbnailModel(apcId: currentUser.apcId,
                                                            uuid: thumbnailUUID,
                                                            thumbnailImage: flightPlan.thumbnail?.thumbnailImage)
            duplicatedFlightPlan.thumbnailUuid = thumbnailUUID
            duplicatedFlightPlan.flightPlanFlights = []

            duplicatedFlightPlans.append(duplicatedFlightPlan)
            // Duplicate the Mavlink if it exists
            let sourceUrl = filesManager.defaultUrl(flightPlan: flightPlan)
            filesManager.copyMavlink(of: duplicatedFlightPlan, from: sourceUrl)
        }

        let duplicatedProject = ProjectModel(
            apcId: currentUser.apcId,
            uuid: projectID,
            title: titleFromDuplicateTitle(project.title),
            type: project.type,
            lastUpdated: Date(),
            parrotCloudId: project.parrotCloudId,
            parrotCloudToBeDeleted: project.parrotCloudToBeDeleted,
            synchroDate: nil,
            synchroStatus: 0
        )

        persistenceProject.persist(duplicatedProject, true)
        duplicatedFlightPlans.forEach { flightPlanRepo.persist($0, true) }
        currentProject = duplicatedProject
    }

    /// Loads last opened Flight Plan (if exists).
    ///
    /// - Parameters:
    ///     - state: mission state
   public  func selectLastOpenedProject(state: MissionProviderState) {
    self.currentProject = loadProjects(type: state.mode?.flightPlanProvider?.projectType).first
    }

    public func setCurrent(_ project: ProjectModel) {
        self.currentProject = setAsLastUsed(project)
    }

    public func setLastOpenedProjectAsCurrent(type: String) {
        self.currentProject = loadProjects(type: type).sorted(by: { $0.lastUpdated > $1.lastUpdated }).first
    }

    public func setAsLastUsed(_ project: ProjectModel) -> ProjectModel {
        let now = Date()
        // Save date in file.
        var newProject = project
        newProject.lastUpdated = now

        // Save Flight Plan.
        persistenceProject.persist(newProject, true)
        return newProject
    }

    public func project(for flightPlan: FlightPlanModel) -> ProjectModel? {
        persistenceProject.loadProject(flightPlan.projectUuid)
    }

    public func clearCurrentProject() {
        currentProject = nil
    }

    public func loadEverythingAndOpen(flightPlan: FlightPlanModel) {
        guard let projectModel = project(for: flightPlan) else { return }
        var missionProvider: MissionProvider?
        var missionMode: MissionMode?
        for provider in missionsStore.allMissions {
            for mode in provider.mission.modes {
                if mode.flightPlanProvider?.hasFlightPlanType(flightPlan.type) ?? false {
                    missionProvider = provider
                    missionMode = mode
                }
            }
        }
        guard let mPovider = missionProvider, let mMode = missionMode else { return }
        // Setup Mission as a Flight Plan mission (may be custom).
        currentMissionManager.set(provider: mPovider)
        currentMissionManager.set(mode: mMode)
        setCurrent(projectModel)
        mMode.stateMachine?.open(flightPlan: flightPlan)
    }

    public func loadEverythingAndOpen(project: ProjectModel) {
        guard let flightPlan = lastFlightPlan(for: project) else { return }
        loadEverythingAndOpen(flightPlan: flightPlan)
    }
}

private extension ProjectManagerImpl {
    /// Returns new title from an original and old titles.
    ///
    /// - Parameters:
    ///     - title: original title
    ///     - oldTitle: current title
    /// - Returns: new title
    func titleFromRenameTitle(_ title: String?, oldTitle: String) -> String {
        guard let title = title else { return L10n.flightPlanNewProject }
        let titleWithoutSuffix = textWithoutSuffix(title)
        // 1 - Find similar titles.
        let similarTitles: [String] = loadProjects(type: nil)
            .compactMap(\.title)
            .filter({ oldTitle != $0 && titleWithoutSuffix == textWithoutSuffix($0) })

        guard !similarTitles.isEmpty else {
            return title
        }
        // 2 - Find higher suffix increment.
        let increment = highestIncrement(on: similarTitles)
        // 3 - Add incremented suffix.
        return String(format: "%@ (%d)", titleWithoutSuffix, increment + 1)
    }

    /// Returns new title from an original title.
    ///
    /// - Parameters:
    ///     - title: original title
    /// - Returns: new title
    func titleFromDuplicateTitle(_ title: String?) -> String {
        guard let title = title else { return L10n.flightPlanNewProject }
        let titleWithoutSuffix = textWithoutSuffix(title)
        // 1 - Find similar titles.
        let similarTitles: [String] = loadProjects(type: nil)
            .compactMap(\.title)
            .filter({ titleWithoutSuffix == textWithoutSuffix($0) })

        guard !similarTitles.isEmpty else {
            return title
        }
        // 2 - Find higher suffix increment.
        let increment = highestIncrement(on: similarTitles)
        // 3 - Add incremented suffix.
        return String(format: "%@ (%d)", titleWithoutSuffix, increment + 1)
    }

    /// Returns highest Increment from an arry of titles.
    ///
    /// - Parameters:
    ///     - titles: array of titles
    /// - Returns: highest Increment Integer
    func highestIncrement(on titles: [String]) -> Int {
        var highestIncrement = 1
        titles.forEach { text in
            // Find suffix.
            if let subString = matching(regexString: Constants.regexNameSuffix, text: text),
               // Find integer in suffix.
               let incrementString = matching(regexString: Constants.regexInt, text: subString),
               let increment = Int(incrementString) {
                highestIncrement = increment > highestIncrement ? increment : highestIncrement
            }
        }
        return highestIncrement
    }

    /// Returns last regex matching string from text.
    ///
    /// - Parameters:
    ///     - regexString: regex as string
    ///     - text: text to search in
    /// - Returns: matching sub string
    func matching(regexString: String, text: String) -> String? {
        if let regex = try? NSRegularExpression(pattern: regexString) {
            let nsrange = NSRange(location: 0, length: text.count)
            if let patternRange = regex.matches(in: text, options: [], range: nsrange).last?.range,
               let range = Range(patternRange, in: text) {
                return String(text[range])
            }
        }
        return nil
    }

    /// Returns text without copyNameSuffix (if pattern matches).
    ///
    /// - Parameters:
    ///     - text: text entry
    /// - Returns: text without suffix
    func textWithoutSuffix(_ text: String) -> String {
        guard let suffix = matching(regexString: Constants.regexNameSuffix, text: text) else {
            return text
        }

        return String(text.prefix(text.count - suffix.count))
    }
}
