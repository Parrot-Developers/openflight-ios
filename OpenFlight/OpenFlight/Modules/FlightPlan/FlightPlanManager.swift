// Copyright (C) 2020 Parrot Drones SAS
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

import CoreLocation
import GroundSdk
import SwiftyUserDefaults

// MARK: - Public Enums
public enum FlightPlanConstants {
    public static let flightPlanDirectory: String = "FlightPlan"
    public static let mavlinkExtension: String = "mavlink"
    public static let jsonExtension: String = "json"
    public static let defaultType: String = "default"
    public static let defaultDroneModel: Drone.Model = .anafi2
    public static let defaultFlightPlanVersion: Int = 1
    public static let regexNameSuffix: String = " \\(\\d+\\)"
    public static let regexInt: String = "\\d+"
    public static let flightPlanNameNotificationKey: String = "FlightPlanName"
    public static let fpExecutionNotificationKey: String = "FlightPlanExecution"
}

// MARK: - FlightPlan Helpers
/// Flight plan listener.

final class FlightPlanListener: NSObject {
    let didChange: FlightPlanListenerClosure
    init(didChange: @escaping FlightPlanListenerClosure) {
        self.didChange = didChange
    }
}

typealias FlightPlanListenerClosure = (FlightPlanViewModel?) -> Void

// MARK: - Flight Plan Manager
/// Manages flight plans.

public final class FlightPlanManager {
    // MARK: - Private Properties
    private var listeners: Set<FlightPlanListener> = []
    /// SavedFlightPlan stack used for undo actions.
    // FIXME: do not stack whole flight plan, just the changes done.
    private var undoStack: [Data] = []

    // MARK: - Private Enums
    private enum Constants {
        // Maximum items in undo stack.
        static let maximumUndoStack: Int = 30
    }

    // MARK: - Public Properties
    public var currentFlightPlanViewModel: FlightPlanViewModel? {
        didSet {
            // Notifies on currentFlightPlanViewModel changes.
            currentFlightPlanViewModel?.state.valueChanged = { [weak self] _ in
                self?.listeners.forEach {
                    $0.didChange(self?.currentFlightPlanViewModel)
                }
            }
            // Notifies currentFlightPlanViewModel did change.
            listeners.forEach {
                $0.didChange(currentFlightPlanViewModel)
            }
            resetUndoStack()
        }
    }

    public static var shared: FlightPlanManager = FlightPlanManager()

    // MARK: - Internal Properties
    let jsonDecoder = JSONDecoder()
    let jsonEncoder = JSONEncoder()

    // MARK: - Init
    // Singleton: shared static var must be used to access to manager.
    private init() {}

    // MARK: - Internal Funcs
    /// Add flight plan listener.
    ///
    /// - Parameters:
    ///     - didChange: flight plan listener closure
    /// - Returns: Flight Plan Listener
    func register(didChange: @escaping FlightPlanListenerClosure) -> FlightPlanListener {
        let listener = FlightPlanListener(didChange: didChange)
        listeners.insert(listener)
        // Notify listener to automatically set currentFlightPlanViewModel.
        listener.didChange(currentFlightPlanViewModel)
        return listener
    }

    /// Remove flight plan listener.
    ///
    /// - Parameters:
    ///     - listener: flight plan listener
    func unregister(_ listener: FlightPlanListener?) {
        if let listener = listener {
            listeners.remove(listener)
        }
    }

    /// Persist current flight plan.
    func persistCurrentFlightPlan() {
        currentFlightPlanViewModel?.updateFlightPlanExtraData()
    }

    /// Deletes a flight plan.
    ///
    /// - Parameters:
    ///     - flightPlan: flight plan to delete
    func delete(flightPlan: FlightPlanViewModel) {
        let uuid = flightPlan.state.value.uuid
        flightPlan.removeFlightPlan()

        if uuid == currentFlightPlanViewModel?.state.value.uuid {
            let currentMissionMode = Services.hub.currentMissionManager.mode
            if let predicate = currentMissionMode.flightPlanProvider?.filterPredicate {
                currentFlightPlanViewModel = CoreDataManager.shared.lastFlightPlan(predicate: predicate)
            } else {
                currentFlightPlanViewModel = nil
            }
        }
    }

    /// Creates new Flight Plan.
    ///
    /// - Parameters:
    ///     - flightPlanProvider: Flight Plan provider
    func new(flightPlanProvider: FlightPlanProvider) {
        let newTitle = titleFromDuplicateTitle(L10n.flightPlanNewProject)
        let savedFlightPlan = SavedFlightPlan(version: FlightPlanConstants.defaultFlightPlanVersion,
                                              title: newTitle,
                                              type: flightPlanProvider.typeKey,
                                              uuid: UUID().uuidString,
                                              lastModified: Date(),
                                              product: FlightPlanConstants.defaultDroneModel,
                                              plan: FlightPlanObject(),
                                              settings: flightPlanProvider.settingsProvider?.settings.toLightSettings() ?? [])
        let fpvm = FlightPlanViewModel(flightPlan: savedFlightPlan)
        fpvm.save()
        currentFlightPlanViewModel = fpvm
    }

    /// Duplicates Flight Plan.
    ///
    /// - Parameters:
    ///     - flightPlan: flight plan to duplicate
    func duplicate(flightPlan: FlightPlanViewModel) {
        let savedFlightPlan = flightPlan.flightPlan?.copy()
        savedFlightPlan?.uuid = UUID().uuidString
        savedFlightPlan?.title = titleFromDuplicateTitle(savedFlightPlan?.title)
        let fpvm = FlightPlanViewModel(flightPlan: savedFlightPlan)
        fpvm.deleteExecutions() // Clean history.
        fpvm.save()
        currentFlightPlanViewModel = fpvm
    }

    /// Loads last opened Flight Plan (if exists).
    ///
    /// - Parameters:
    ///     - state: mission state
    func loadLastOpenedFlightPlan(state: MissionProviderState) {
        let predicate = state.mode?.flightPlanProvider?.filterPredicate
        CoreDataManager.shared.loadLastFlightPlan(predicate: predicate,
                                                  completion: { [weak self] flightPlan in
            if flightPlan?.state.value.uuid != self?.currentFlightPlanViewModel?.state.value.uuid {
                self?.currentFlightPlanViewModel = flightPlan
            }
        })
    }

    /// Setup title from renamed title and old title
    ///
    /// - Parameters:
    ///     - title: new title
    ///     - oldTitle: current title
    func setupTitle(_ title: String?, oldTitle: String) -> String {
        titleFromRenameTitle(title, oldTitle: oldTitle)
    }
}

// MARK: - Public Funcs
public extension FlightPlanManager {
    /// Updates current Flight Plan with new Mavlink.
    ///
    /// - Parameters:
    ///     - url: Mavlink url
    ///     - type: Flight Plan type
    ///     - createCopy: To force create copy
    ///     - settings: Flight plan settings
    ///     - polygonPoints: List of polygon points
    func updateCurrentFlightPlanWithMavlink(url: URL,
                                            type: FlightPlanType,
                                            createCopy: Bool,
                                            settings: [FlightPlanLightSetting],
                                            polygonPoints: [PolygonPoint]? = nil) {
        guard let currentFP = currentFlightPlanViewModel,
              let uuid = currentFlightPlanViewModel?.state.value.uuid,
              createCopy == false else {
            // Create new FP.
            let title = titleFromDuplicateTitle(L10n.flightPlanNewProject)
            // Generate flightPlanData from mavlink.
            let flightPlanData = type.mavLinkType.generateFlightPlanFromMavlink(url: url,
                                                                                mavlinkString: nil,
                                                                                title: title,
                                                                                type: type.key,
                                                                                uuid: nil,
                                                                                settings: settings,
                                                                                polygonPoints: polygonPoints,
                                                                                version: FlightPlanConstants.defaultFlightPlanVersion,
                                                                                model: FlightPlanConstants.defaultDroneModel)
            // Save Mavlink into the intended Mavlink url if needed.
            if type.canGenerateMavlink == false {
                flightPlanData?.copyMavlink(from: url)
            }
            let model = FlightPlanViewModel(flightPlan: flightPlanData)
            model.save()
            currentFlightPlanViewModel = model
            return
        }

        let title = currentFP.state.value.title ?? titleFromDuplicateTitle(L10n.flightPlanNewProject)
        let currentType = currentFP.state.value.type
        let product = currentFP.flightPlan?.product ?? FlightPlanConstants.defaultDroneModel
        // Generate flightPlanData from mavlink.
        let flightPlanData = type.mavLinkType.generateFlightPlanFromMavlink(url: url,
                                                                            mavlinkString: nil,
                                                                            title: title,
                                                                            type: currentType?.key,
                                                                            uuid: nil,
                                                                            settings: settings,
                                                                            polygonPoints: polygonPoints,
                                                                            version: FlightPlanConstants.defaultFlightPlanVersion,
                                                                            model: product)
        // Keep uuid.
        flightPlanData?.uuid = uuid
        // Save Mavlink into the intended Mavlink url if needed.
        if type.canGenerateMavlink == false {
            flightPlanData?.copyMavlink(from: url)
        }

        // Backup OA settings.
        flightPlanData?.obstacleAvoidanceActivated = currentFlightPlanViewModel?.flightPlan?.obstacleAvoidanceActivated

        // Backup capture settings.
        let captureSettings = currentFlightPlanViewModel?.flightPlan?.plan.captureSettings
        flightPlanData?.plan.captureSettings = captureSettings

        // Update flight plan view model points.
        currentFlightPlanViewModel?.points = flightPlanData?.plan.wayPoints.compactMap({ $0.coordinate }) ?? []

        // Update FP data.
        currentFlightPlanViewModel?.flightPlan = flightPlanData
    }
}

// MARK: - Undo management
extension FlightPlanManager {
    /// Reset undo stack.
    func resetUndoStack() {
        undoStack.removeAll()
        appendUndoStack(with: currentFlightPlanViewModel?.flightPlan)
    }

    /// Add flight plan in the undo stack.
    ///
    /// - Parameters:
    ///     - flightPlan: flightPlan to backup at some moment
    func appendUndoStack(with flightPlan: SavedFlightPlan?) {
        guard let flightPlanData = flightPlan?.asData else { return }

        // Store flight plan as data to make a copy.
        // FlightPlan's currentFlightPlanViewModel must not point on undo stack.
        if undoStack.count >= Constants.maximumUndoStack {
            undoStack.removeFirst()
        }

        undoStack.append(flightPlanData)
    }

    /// Can undo.
    func canUndo() -> Bool {
        return undoStack.count > 1
    }

    /// Undo.
    func undo() {
        guard canUndo() else { return }

        // get setting from last and apply them.
        let oldFlightPlan = undoStack.last?.asFlightPlan
        // Dump last.
        undoStack.removeLast()

        // Restore flight plan from data to make another copy.
        // FlightPlan's currentFlightPlanViewModel must not point on undo stack.
        if var flightPlan = undoStack.last?.asFlightPlan,
           // TODO missing injection
           let fpType = Services.hub.flightPlanTypeStore.typeForKey(flightPlan.type) {
            // copying all the settings from last in undostack
            if let oldFlightPlan = oldFlightPlan {
                // copy settings of the deleted flight plan in the new one.
                flightPlan = copySettings(oldFlightPlan: oldFlightPlan, flightPlan: flightPlan)

                // replace flight plan in stack.
                if let flightPlanData = flightPlan.asData {
                    undoStack.removeLast()
                    undoStack.append(flightPlanData)
                }
            }
            let state = FlightPlanState(flightPlan: flightPlan, type: fpType)
            currentFlightPlanViewModel?.flightPlan = flightPlan
            currentFlightPlanViewModel?.state.set(state)
        }
    }

    /// Copy settings from an old flight plan to another one.
    ///
    /// - Parameters:
    ///     - oldFlightPlan: flight plan  to copy.
    ///     - flightPlan: flight plan  to update.
    /// - Returns flight plan updated.
    private func copySettings(oldFlightPlan: SavedFlightPlan, flightPlan: SavedFlightPlan) -> SavedFlightPlan {
        flightPlan.plan.isBuckled = oldFlightPlan.plan.isBuckled
        flightPlan.plan.shouldContinue = oldFlightPlan.plan.shouldContinue
        flightPlan.plan.lastPointRth = oldFlightPlan.plan.lastPointRth
        flightPlan.plan.captureMode = oldFlightPlan.plan.captureMode
        flightPlan.plan.captureSettings = oldFlightPlan.plan.captureSettings
        flightPlan.plan.captureModeEnum = oldFlightPlan.plan.captureModeEnum
        flightPlan.plan.resolution = oldFlightPlan.plan.resolution
        flightPlan.plan.whiteBalanceMode = oldFlightPlan.plan.whiteBalanceMode
        flightPlan.plan.framerate = oldFlightPlan.plan.framerate
        flightPlan.plan.photoResolution = oldFlightPlan.plan.photoResolution
        flightPlan.plan.exposure = oldFlightPlan.plan.exposure
        flightPlan.plan.timeLapseCycle = oldFlightPlan.plan.timeLapseCycle
        flightPlan.plan.gpsLapseDistance = oldFlightPlan.plan.gpsLapseDistance
        flightPlan.obstacleAvoidanceActivated = oldFlightPlan.obstacleAvoidanceActivated
        flightPlan.settings = oldFlightPlan.settings

        return flightPlan
    }

    /// Update only global settings of current flight plan and replace it in stack
    ///
    /// - Parameters:
    ///     - flightPlan: flight plan  to update.
    func updateGlobalSettings(with flightPlan: SavedFlightPlan?) {

        guard let flightPlanData = flightPlan?.asData else { return }
        if !undoStack.isEmpty {
            undoStack.removeLast()
        }
        undoStack.append(flightPlanData)
    }
}

// MARK: - Private Funcs
private extension FlightPlanManager {
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
        let similarTitles: [String] = CoreDataManager.shared.loadAllFlightPlanViewModels(predicate: nil)
            .compactMap(\.state.value.title)
            .filter({ oldTitle != $0 && titleWithoutSuffix == textWithoutSuffix($0) })

        guard !similarTitles.isEmpty else {
            return title
        }
        // 2 - Find higher suffix increment.
        let highestInc = highestIncrement(on: similarTitles)
        // 3 - Add incremented suffix.
        return String(format: "%@ (%d)", titleWithoutSuffix, highestInc + 1)
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
        let similarTitles: [String] = CoreDataManager.shared.loadAllFlightPlanViewModels(predicate: nil)
            .compactMap(\.state.value.title)
            .filter({ titleWithoutSuffix == textWithoutSuffix($0) })

        guard !similarTitles.isEmpty else {
            return title
        }
        // 2 - Find higher suffix increment.
        let highestInc = highestIncrement(on: similarTitles)
        // 3 - Add incremented suffix.
        return String(format: "%@ (%d)", titleWithoutSuffix, highestInc + 1)
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
            if let subString = matching(regexString: FlightPlanConstants.regexNameSuffix, text: text),
               // Find integer in suffix.
               let incrementString = matching(regexString: FlightPlanConstants.regexInt, text: subString),
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
        guard let suffix = matching(regexString: FlightPlanConstants.regexNameSuffix, text: text) else {
            return text
        }

        return String(text.prefix(text.count - suffix.count))
    }
}

/// Utility extension for `FlightPlanInterpreter` MAVLink to Flight Plan conversion.
// TODO: remove this when all Flight Plans use MavlinkStandard.
private extension FlightPlanInterpreter {
    /// Generates FlightPlan from MAVLink file at given URL or MAVLink string.
    ///
    /// - Parameters:
    ///    - url: url of MAVLink file to parse
    ///    - mavlinkString: MAVLink string to parse
    ///    - title: title of FlightPlan to generate
    ///    - type: Flight Plan type
    ///    - uuid: Flight Plan ID
    ///    - settings: Flight Plan settings
    ///    - polygonPoints:Flight Plan polygon points
    ///    - version: version of FlightPlan
    ///    - model: model of drone for generated FlightPlan
    ///
    /// - Returns: generated `SavedFlightPlan` is operation succeeded, `nil` otherwise
    func generateFlightPlanFromMavlink(url: URL? = nil,
                                       mavlinkString: String? = nil,
                                       title: String,
                                       type: String? = nil,
                                       uuid: String? = nil,
                                       settings: [FlightPlanLightSetting] = [],
                                       polygonPoints: [PolygonPoint]? = nil,
                                       version: Int = FlightPlanConstants.defaultFlightPlanVersion,
                                       model: Drone.Model) -> SavedFlightPlan? {
        switch self {
        case .legacy:
            return MavlinkToFlightPlanParser.generateFlightPlanFromMavlinkLegacy(url: url,
                                                                                 mavlinkString: mavlinkString,
                                                                                 title: title,
                                                                                 type: type,
                                                                                 uuid: uuid,
                                                                                 settings: settings,
                                                                                 polygonPoints: polygonPoints,
                                                                                 version: version,
                                                                                 model: model)
        case .standard:
            return MavlinkToFlightPlanParser.generateFlightPlanFromMavlinkStandard(url: url,
                                                                                   mavlinkString: mavlinkString,
                                                                                   title: title,
                                                                                   type: type,
                                                                                   uuid: uuid,
                                                                                   settings: settings,
                                                                                   polygonPoints: polygonPoints,
                                                                                   version: version,
                                                                                   model: model)
        }
    }
}
