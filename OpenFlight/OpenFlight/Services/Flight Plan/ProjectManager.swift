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
import SdkCore

public protocol ProjectManager {

    /// Current project publisher
    var currentProjectPublisher: AnyPublisher<ProjectModel?, Never> { get }

    /// Projects did change
    var projectsDidChangePublisher: AnyPublisher<Void, Never> { get }

    /// Project must close its history list
    var hideExecutionsListPublisher: AnyPublisher<Void, Never> { get }

    /// Publisher notifying to start edition of current project.
    var startEditionPublisher: AnyPublisher<Void, Never> { get }

    /// Current project
    var currentProject: ProjectModel? { get }

    /// Loads Projects.
    /// - Returns: the created project
    func loadProjects(type: String?) -> [ProjectModel]

    /// Loads executed projects, ordered by last execution date desc
    func loadExecutedProjects() -> [ProjectModel]

    /// Loads all projects
    func loadAllProjects() -> [ProjectModel]

    /// Creates new Project.
    ///
    /// - Parameters:
    ///     - flightPlanProvider: Flight Plan provider
    /// - Returns: the created project
    func newProject(flightPlanProvider: FlightPlanProvider) -> ProjectModel

    /// Creates a new project from a mavlink file
    /// - Parameter url: the mavlink file URL
    func newProjectFromMavlinkFile(_ url: URL?) -> ProjectModel?

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

    /// Setup everything (mission, project, flight plan) to open a flight plan
    /// - Parameters:
    ///    - flightPlan: the flight plan
    ///    - autoStart: automatically start the flight plan if `true`
    func loadEverythingAndOpen(flightPlan: FlightPlanModel, autoStart: Bool)

    /// Setup everything (mission, project, flight plan) to open the project's flight plan
    /// - Parameter project: the project
    func loadEverythingAndOpen(project: ProjectModel)

    /// Setup everything (mission, project, flight plan) to open the project's flight plan but do
    /// not mark it as last used.
    ///
    /// This method is usefull for newly created/duplicated projects.
    /// - Parameter project: the project
    func loadEverythingAndOpenWhileNotSettingAsLastUsed(project: ProjectModel)

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

}

private extension ULogTag {
    static let tag = ULogTag(name: "ProjectManager")
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
    private let flightPlanManager: FlightPlanManager
    private let flightPlanRunManager: FlightPlanRunManager

    public var projectsDidChangePublisher: AnyPublisher<Void, Never> {
        return persistenceProject.projectsDidChangePublisher
    }

    public var hideExecutionsListPublisher: AnyPublisher<Void, Never> {
        return hideExecutionsListSubject.eraseToAnyPublisher()
    }

    public var startEditionPublisher: AnyPublisher<Void, Never> {
        return startEditionSubject.eraseToAnyPublisher()
    }

    // MARK: - Private Properties
    private var currentProjectSubject = CurrentValueSubject<ProjectModel?, Never>(nil)
    private var hideExecutionsListSubject = PassthroughSubject<Void, Never>()
    private var startEditionSubject = PassthroughSubject<Void, Never>()

    init(missionsStore: MissionsStore,
         flightPlanTypeStore: FlightPlanTypeStore,
         persistenceProject: ProjectRepository,
         flightPlanRepo: FlightPlanRepository,
         editionService: FlightPlanEditionService,
         currentMissionManager: CurrentMissionManager,
         currentUser: UserInformation,
         filesManager: FlightPlanFilesManager,
         flightPlanManager: FlightPlanManager,
         flightPlanRunManager: FlightPlanRunManager) {
        self.missionsStore = missionsStore
        self.flightPlanTypeStore = flightPlanTypeStore
        self.persistenceProject = persistenceProject
        self.flightPlanRepo = flightPlanRepo
        self.editionService = editionService
        self.currentMissionManager = currentMissionManager
        self.currentUser = currentUser
        self.filesManager = filesManager
        self.flightPlanManager = flightPlanManager
        self.flightPlanRunManager = flightPlanRunManager
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

    public func loadAllProjects() -> [ProjectModel] {
        loadProjects(type: nil)
    }

    public func newProject(flightPlanProvider: FlightPlanProvider) -> ProjectModel {
        newProjectAndFlightPlan(flightPlanProvider: flightPlanProvider).project
    }

    public func newProjectFromMavlinkFile(_ url: URL?) -> ProjectModel? {
        guard let url = url,
              let flightPlanProvider = FlightPlanMissionMode.standard.missionMode.flightPlanProvider else { return nil }

        var (project, flightPlan) = newProjectAndFlightPlan(flightPlanProvider: flightPlanProvider,
                                                            title: url.deletingPathExtension().lastPathComponent)

        flightPlan = MavlinkToFlightPlanParser
            .generateFlightPlanFromMavlinkStandard(url: url,
                                                   flightPlan: flightPlan) ?? flightPlan
        flightPlan.dataSetting?.readOnly = true
        flightPlan.dataSetting?.mavlinkDataFile = try? Data(contentsOf: url)
        flightPlanRepo.saveOrUpdateFlightPlan(flightPlan,
                                              byUserUpdate: true,
                                              toSynchro: true,
                                              withFileUploadNeeded: true)
        return project
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

    public func loadProjects(type: String?) -> [ProjectModel] {
        if let type = type {
            return persistenceProject.getProjects(withType: type)
        } else {
            return persistenceProject.getAllProjects()
        }
    }

    public func loadExecutedProjects() -> [ProjectModel] {
        persistenceProject.getExecutedProjects()
    }

    public func delete(project: ProjectModel) {
        ULog.i(.tag, "Deleting project '\(project.uuid)' '\(project.title ?? "")'")
        for flightPlan in flightPlans(for: project) {
            // There are side effects to manage (delete mavlink,...), let the manager do the job
            flightPlanManager.delete(flightPlan: flightPlan)
        }
        persistenceProject.deleteOrFlagToDeleteProject(withUuid: project.uuid)
        if project.uuid == currentProject?.uuid {
            clearCurrentProject()
            currentMissionManager.mode.stateMachine?.reset()
            editionService.resetFlightPlan()
            guard let newProject = loadProjects(type: project.type).sorted(by: { $0.lastUpdated > $1.lastUpdated }).first,
                  let flightPlan = lastFlightPlan(for: newProject) else { return }
            ULog.i(.tag, "Opening flightPlan '\(flightPlan.uuid)' of project '\(newProject.uuid)' '\(newProject.title ?? "")'")
            setCurrent(newProject)
            currentMissionManager.mode.stateMachine?.open(flightPlan: flightPlan)
        }
    }

    public func rename(_ project: ProjectModel, title: String?) {
        guard let oldTitle = project.title else { return }
        let newTitle = titleFromRenameTitle(title, oldTitle: oldTitle)
        guard newTitle != oldTitle else { return }

        var project = project
        project.title = newTitle
        persistenceProject.saveOrUpdateProject(project, byUserUpdate: true, toSynchro: true)
        ULog.i(.tag, "Rename project '\(project.uuid)' from '\(oldTitle)' to '\(newTitle)'")
        // Rename the customTitle of the project's editable FP.
        if var flightPlan = lastFlightPlan(for: project),
           flightPlan.state == .editable {
            flightPlan.customTitle = newTitle
            flightPlanRepo.saveOrUpdateFlightPlan(flightPlan, byUserUpdate: true, toSynchro: true)
            editionService.setupFlightPlan(flightPlan)
        }
        if project.uuid == currentProject?.uuid {
            currentProject?.title = newTitle
        }
    }

    @discardableResult
    public func duplicate(project: ProjectModel) -> ProjectModel {
        let duplicatedProjectID = UUID().uuidString
        var duplicatedFlightPlans: [FlightPlanModel] = []

        if let flightPlan = lastFlightPlan(for: project) {
            var duplicatedFlightPlan = flightPlanManager.newFlightPlan(basedOn: flightPlan,
                                                                       save: false)
            duplicatedFlightPlan.customTitle = titleFromDuplicateTitle(project.title)
            duplicatedFlightPlan.projectUuid = duplicatedProjectID
            duplicatedFlightPlans.append(duplicatedFlightPlan)
        }

        let duplicatedProject = ProjectModel(duplicateProject: project,
                                             withApcId: currentUser.apcId,
                                             uuid: duplicatedProjectID,
                                             title: titleFromDuplicateTitle(project.title))

        persistenceProject.saveOrUpdateProject(duplicatedProject, byUserUpdate: true, toSynchro: true)
        flightPlanRepo.saveOrUpdateFlightPlans(duplicatedFlightPlans, byUserUpdate: true, toSynchro: true)
        currentProject = duplicatedProject
        ULog.i(.tag, "Duplicate project '\(project.uuid)' '\(project.title ?? "")' -> '\(duplicatedProject.uuid)'."
               + " Duplicated flightPlans: " + duplicatedFlightPlans.map({ "'\($0.uuid)'" }).joined(separator: ", "))
        return duplicatedProject
    }

    public func setCurrent(_ project: ProjectModel) {
        currentProject = setAsLastUsed(project)
    }

    public func setLastOpenedProjectAsCurrent(type: String) {
        currentProject = loadProjects(type: type).sorted(by: { $0.lastUpdated > $1.lastUpdated }).first
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
    }

    public func loadEverythingAndOpen(flightPlan: FlightPlanModel) {
        loadEverythingAndOpen(flightPlan: flightPlan, autoStart: false)
    }

    public func loadEverythingAndOpen(flightPlan: FlightPlanModel, autoStart: Bool) {
        loadEverythingAndOpen(flightPlan: flightPlan, touch: true, autoStart: autoStart)
    }

    private func loadEverythingAndOpen(flightPlan: FlightPlanModel, touch: Bool, autoStart: Bool = false) {
        guard let project = project(for: flightPlan) else { return }
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
        // Setup Mission as a Flight Plan mission (may be custom).
        currentMissionManager.set(provider: mPovider)
        currentMissionManager.set(mode: mMode)
        if touch {
            setCurrent(project)
        } else {
            currentProject = project
        }
        mMode.stateMachine?.open(flightPlan: flightPlan)
        if autoStart {
            mMode.stateMachine?.start()
        }
        hideExecutionsListSubject.send()
    }

    public func loadEverythingAndOpen(project: ProjectModel) {
        loadEverythingAndOpen(project: project, touch: true)
    }

    public func loadEverythingAndOpenWhileNotSettingAsLastUsed(project: ProjectModel) {
        loadEverythingAndOpen(project: project, touch: false)
    }

    private func loadEverythingAndOpen(project: ProjectModel, touch: Bool) {
        guard let flightPlan = lastFlightPlan(for: project) else { return }
        ULog.i(.tag, "Opening project '\(project.uuid)' '\(project.title ?? "")' will continue"
               + " opening flightPlan '\(flightPlan.uuid)'")
        loadEverythingAndOpen(flightPlan: flightPlan, touch: touch)
    }

    public func startEdition() {
        startEditionSubject.send()
    }

    @discardableResult
    public func updateExecutionCustomTitle(for flightPlan: FlightPlanModel) -> FlightPlanModel {
        let customTitle = executionCustomTitle(for: flightPlan)
        return flightPlanManager.update(flightplan: flightPlan, with: customTitle)
    }

    @discardableResult
    public func resetExecutionCustomTitle(for flightPlan: FlightPlanModel) -> FlightPlanModel {
        guard let project = project(for: flightPlan),
        let projectTitle = project.title else { return flightPlan }
        return flightPlanManager.update(flightplan: flightPlan, with: projectTitle)
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

    func newProjectAndFlightPlan(flightPlanProvider: FlightPlanProvider,
                                 title: String = L10n.flightPlanNewProject) -> (project: ProjectModel, flightPlan: FlightPlanModel) {
        let uuid = UUID().uuidString
        let title = titleFromDuplicateTitle(title)
        let dataSetting = FlightPlanDataSetting(product: FlightPlanConstants.defaultDroneModel,
                                                settings: flightPlanProvider.settingsProvider?.settings.toLightSettings() ?? [],
                                                freeSettings: [:],
                                                polygonPoints: [],
                                                mavlinkDataFile: nil,
                                                takeoffActions: [],
                                                pois: [],
                                                wayPoints: [],
                                                disablePhotoSignature: false)

        let flightPlan = FlightPlanModel(apcId: currentUser.apcId,
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

        let project = ProjectModel(apcId: currentUser.apcId,
                                   uuid: uuid,
                                   title: title,
                                   type: flightPlanProvider.projectType)

        persistenceProject.saveOrUpdateProject(project, byUserUpdate: true, toSynchro: true)
        flightPlanRepo.saveOrUpdateFlightPlan(flightPlan,
                                              byUserUpdate: true,
                                              toSynchro: true,
                                              withFileUploadNeeded: false)
        return (project, flightPlan)
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

    /// Returns an execution `customTitle` according his run position.
    ///
    /// - Parameters:
    ///    - flightPlan: The flight plan execution.
    ///
    /// - Returns: The `customTitle`.
    ///
    ///  Note: There is no check on the FP state at this level.
    func executionCustomTitle(for flightPlan: FlightPlanModel) -> String {
        // Ensure the FP is linked to a project.
        guard let project = project(for: flightPlan) else {
            return flightPlan.customTitle
        }
        // Get the project's executions list excluding the current FP.
        let executions = executions(for: project)
            .filter { $0.uuid != flightPlan.uuid }
        // The current FP execution index is the number of project's executions + 1 for the current one.
        let executionIndex = executions.count + 1
        // Returns the new customTitle by appending the executionIndex to the project title.
        return "\(project.title ?? flightPlan.customTitle) (\(executionIndex))"
    }
}
