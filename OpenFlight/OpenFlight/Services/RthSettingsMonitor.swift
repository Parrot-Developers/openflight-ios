//    Copyright (C) 2022 Parrot Drones SAS
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
import GroundSdk
import Combine
import SwiftyUserDefaults

extension ULogTag {
    static let rthSettingsMonitor = ULogTag(name: "rthSettingsMonitor")
}

/// Return home settings handler.
/// Manages return home settings to apply according to context.
public protocol RthSettingsMonitor: AnyObject {
    /// Publishes the user rth settings
    var userPreferredRthSettingsPublisher: AnyPublisher<RthSettings, Never> { get }
    /// Edits return home settings because of user action
    func updateUserRthSettings(rthSettings: RthSettings)
    /// Returns home settings from advanced settings
    func getUserRthSettings() -> RthSettings
}

/// Implementation of `RthSettingsMonitor`.
public class RthSettingsMonitorImpl: RthSettingsMonitor {
    // MARK: Private vars
    private var cancellables: Set<AnyCancellable> = []
    private weak var activeFlightPlanWatcher: ActiveFlightPlanExecutionWatcher?
    private var returnHomeRef: Ref<ReturnHomePilotingItf>?
    private weak var returnHome: ReturnHomePilotingItf?
    private lazy var userPreferredRthSettingsSubject = CurrentValueSubject<RthSettings, Never>(getUserRthSettings())

    // MARK: Public vars
    public var userPreferredRthSettingsPublisher: AnyPublisher<RthSettings, Never> {
        userPreferredRthSettingsSubject.eraseToAnyPublisher()
    }

    // MARK: Public funcs
    /// Inits.
    ///
    /// - Parameters:
    ///   - activeFlightPlanWatcher: the active flight plan watcher
    init(currentDroneHolder: CurrentDroneHolder, activeFlightPlanWatcher: ActiveFlightPlanExecutionWatcher) {
        self.activeFlightPlanWatcher = activeFlightPlanWatcher
        listen(dronePublisher: currentDroneHolder.dronePublisher)
        listenActiveFlightPlan()
    }

    /// Edits return home settings because of user action.
    ///
    /// - Parameters:
    ///   - rthSettings: return home settings
    public func updateUserRthSettings(rthSettings: RthSettings) {
        Defaults.userPreferredRthSettings = try? JSONEncoder().encode(rthSettings)
        userPreferredRthSettingsSubject.value = rthSettings
        applyRelevantRthSettings(rthSettings: rthSettings)
    }

    /// Returns user rth settings
    public func getUserRthSettings() -> RthSettings {
        guard let data = Defaults[\.userPreferredRthSettings],
              let rthSettings = try? JSONDecoder().decode(RthSettings.self, from: data)
        else { return RthSettings() }
        return rthSettings
    }
}

// MARK: - Private funcs
private extension RthSettingsMonitorImpl {
    /// Listens current drone.
    ///
    /// - Parameters:
    ///   - dronePublisher: drone publisher
    func listen(dronePublisher: AnyPublisher<Drone, Never>) {
        dronePublisher.sink { [weak self] drone in
            self?.listenReturnHome(drone: drone)
        }
        .store(in: &cancellables)
    }

    /// Listens return home piloting interface.
    ///
    /// - Parameters:
    ///   - drone: current drone
    func listenReturnHome(drone: Drone) {
        returnHomeRef = drone.getPilotingItf(PilotingItfs.returnHome) { [weak self] returnHome in
            guard let self = self, let returnHome = returnHome else { return }
            self.returnHome = returnHome
        }
    }

    /// Listens for flight plan state.
    func listenActiveFlightPlan() {
        activeFlightPlanWatcher?.activeFlightPlanStatePublisher.sink { [weak self] _ in
            guard let self = self else { return }
            self.applyRelevantRthSettings()
        }
        .store(in: &cancellables)
    }

    /// Applies relevant return home settings.
    ///
    /// - Parameters:
    ///   - rthSettings: RTH settings
    func applyRelevantRthSettings(rthSettings: RthSettings? = nil) {
        setToDrone(rthSettings ?? selectSettingsToApply().rthSettings)
    }

    /// Returns relevant return home settings.
    func selectSettingsToApply() -> AppliedRthSettings {
        switch activeFlightPlanWatcher?.activeFlightPlanState ?? .none {
        case .activating(let flightPlan),
             .active(let flightPlan):
            guard flightPlan.dataSetting?.customRth == true else { fallthrough }
            let rthSettings = RthSettings(from: flightPlan.dataSetting)
            return .flightPlan(settings: rthSettings)
        case .none:
            return .userDefined(settings: getUserRthSettings())
        }
    }

    /// Gives RthSettings data to the return home piloting interface.
    /// - Parameters:
    ///  - rthSettings: RTH Settings
    func setToDrone(_ rthSettings: RthSettings) {
        guard let returnHome = returnHome else { return }
        if returnHome.preferredTarget.target != rthSettings.rthReturnTarget {
            ULog.i(.rthSettingsMonitor, "RTH preferredTarget: \(returnHome.preferredTarget.target) => \(rthSettings.rthReturnTarget)")
            returnHome.preferredTarget.target = rthSettings.rthReturnTarget
        }
        if let minAltitude = returnHome.minAltitude?.value,
           round(minAltitude) != round(rthSettings.rthHeight) {
            ULog.i(.rthSettingsMonitor, "RTH minAltitude: \(minAltitude) => \(rthSettings.rthHeight)")
            returnHome.minAltitude?.value = rthSettings.rthHeight
        }
        if returnHome.endingBehavior.behavior != rthSettings.rthEndBehaviour {
            ULog.i(.rthSettingsMonitor, "RTH endingBehavior: \(returnHome.endingBehavior.behavior) => \(rthSettings.rthEndBehaviour)")
            returnHome.endingBehavior.behavior = rthSettings.rthEndBehaviour
        }
        if let endingHoveringAltitude = returnHome.endingHoveringAltitude?.value,
           endingHoveringAltitude != rthSettings.rthHoveringHeight {
            ULog.i(.rthSettingsMonitor, "RTH endingHoveringAltitude: \(endingHoveringAltitude) => \(rthSettings.rthHoveringHeight)")
            returnHome.endingHoveringAltitude?.value = rthSettings.rthHoveringHeight
        }
    }
}

/// Enum which exposes the source of return mode settings used.
public enum AppliedRthSettings {
    case flightPlan(settings: RthSettings)
    case userDefined(settings: RthSettings)

    var rthSettings: RthSettings {
        switch self {
        case .flightPlan(settings: let rthSettings),
             .userDefined(settings: let rthSettings):
            return rthSettings
        }
    }
}

/// User Defaults keys for `RthSettingsMonitor`.
private extension DefaultsKeys {
    /// return home settings set in advanced settings
    var userPreferredRthSettings: DefaultsKey<Data?> {
        .init("key_userPreferredRthSettings")
    }
}

/// Model of return home settings used by `RthSettingsMonitor`.
public struct RthSettings: Codable {
    let rthReturnTarget: ReturnHomeTarget
    let rthHeight: Double
    public let rthEndBehaviour: ReturnHomeEndingBehavior
    let rthHoveringHeight: Double

    /// Available values for return home target.
    static var returnTargetValues: [ReturnHomeTarget] {
        return [ReturnHomeTarget.takeOffPosition,
                ReturnHomeTarget.controllerPosition]
    }

    /// Available values for return home end behaviors.
    static var returnEndBehaviors: [ReturnHomeEndingBehavior] {
        return [ReturnHomeEndingBehavior.hovering,
                ReturnHomeEndingBehavior.landing]
    }

    /// Inits.
    ///
    /// - Parameters:
    ///     - rthReturnTarget: return home target
    ///     - rthHeight: return home altitude
    ///     - rthEndBehaviour: return home end behavior
    ///     - rthHoveringHeight: return home hovering altitude
    init(rthReturnTarget: ReturnHomeTarget,
         rthHeight: Double,
         rthEndBehaviour: ReturnHomeEndingBehavior,
         rthHoveringHeight: Double) {
        self.rthReturnTarget = rthReturnTarget
        self.rthHeight = rthHeight
        self.rthEndBehaviour = rthEndBehaviour
        self.rthHoveringHeight = rthHoveringHeight
    }

    /// Inits with return home settings from mission.
    ///
    /// - Parameters:
    ///     - flightPlanSettings: mission settings
    init(from flightPlanSettings: FlightPlanDataSetting? = nil) {
        rthReturnTarget = flightPlanSettings?.rthReturnTarget ?? true
            ? .takeOffPosition
            : .controllerPosition
        let rthHeightValue = flightPlanSettings?.rthHeight ?? Int(RthPreset.defaultAltitude)
        rthHeight = Double(rthHeightValue)
        rthEndBehaviour = flightPlanSettings?.rthEndBehaviour ?? true
            ? .hovering
            : .landing
        let rthHoveringHeightValue = flightPlanSettings?.rthHoveringHeight ?? Int(RthPreset.defaultHoveringAltitude)
        rthHoveringHeight = Double(rthHoveringHeightValue)
    }

    /// Inits from data.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let returnTargetIndex = try container.decode(Int.self, forKey: .rthReturnTarget)
        rthReturnTarget = Self.returnTargetValues[returnTargetIndex]
        rthHeight = try container.decode(Double.self, forKey: .rthHeight)
        let returnEndBehaviorIndex = try container.decode(Int.self, forKey: .rthEndBehaviour)
        rthEndBehaviour = Self.returnEndBehaviors[returnEndBehaviorIndex]
        rthHoveringHeight = try container.decode(Double.self, forKey: .rthHoveringHeight)
    }

    /// Encodes to data.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let returnTargetIndex = Self.returnTargetValues.firstIndex(of: rthReturnTarget) ?? 0
        try container.encodeIfPresent(returnTargetIndex, forKey: .rthReturnTarget)
        try container.encodeIfPresent(rthHeight, forKey: .rthHeight)
        let returnEndBehaviorIndex = Self.returnEndBehaviors.firstIndex(of: rthEndBehaviour) ?? 0
        try container.encodeIfPresent(returnEndBehaviorIndex, forKey: .rthEndBehaviour)
        try container.encodeIfPresent(rthHoveringHeight, forKey: .rthHoveringHeight)
    }

    /// RthSettings coding keys.
    enum CodingKeys: CodingKey {
        case rthReturnTarget
        case rthHeight
        case rthEndBehaviour
        case rthHoveringHeight
    }
}
