//
//  Copyright (C) 2020 Parrot Drones SAS.
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

/// Provider for classic Flight Plan.
struct ClassicFlightPlanProvider: FlightPlanProvider {
    // MARK: - Internal Properties
    var typeKey: String {
        return FlightPlanConstants.defaultType
    }

    var filterPredicate: NSPredicate? {
        // Filter on type: default or nil.
        return NSPredicate(format: "%K == %@",
                           #keyPath(FlightPlanModel.type),
                           typeKey)
    }

    var settingsProvider: FlightPlanSettingsProvider? {
        return ClassicFlightPlanSettingsProvider()
    }

    var settingsAlwaysDisplayed: Bool {
        return false
    }

    var flightPlanCoordinator: FlightPlanCoordinator? {
        return nil
    }

    // MARK: - Internal Funcs
    func graphicsWithFlightPlan(_ flightPlanObject: FlightPlanObject) -> [FlightPlanGraphic] {
        return flightPlanObject.allLinesAndMarkersGraphics
    }

    func graphicsLabelsWithFlightPlan(_ flightPlanObject: FlightPlanObject) -> [FlightPlanLabelGraphic] {
        return flightPlanObject.allLabelsGraphics
    }
}

/// Setting types for Classic Flight Plan.
public enum ClassicFlightPlanSettingType: String, FlightPlanSettingType, CaseIterable {
    case continueMode
    case lastPointRth
    case obstacleAvoidance
    // TODO: fix the following settings in next gerrit (values, display, etc.)
    case imageMode
    case resolution
    case framerate

    // MARK: - Internal Properties
    public var title: String {
        switch self {
        case .continueMode:
            return L10n.flightPlanSettingsProgressiveRace
        case .lastPointRth:
            return L10n.flightPlanSettingsRthOnLastPoint
        case .obstacleAvoidance:
            return L10n.flightPlanSettingsAvoidance
        case .imageMode:
            return L10n.commonMode
        case .resolution:
            return L10n.flightPlanSettingsResolution
        case .framerate:
            return L10n.flightPlanSettingsFramerate
        }
    }

    public var shortTitle: String? {
        switch self {
        case .continueMode:
            return L10n.flightPlanSettingsProgressiveRaceShort
        case .lastPointRth:
            return L10n.flightPlanSettingsRthOnLastPointShort
        case .obstacleAvoidance:
            return L10n.flightPlanSettingsAvoidanceShort
        case .imageMode,
             .resolution,
             .framerate:
            return nil
        }
    }

    public var allValues: [Int] {
        switch self {
        case .framerate:
            return Camera2RecordingFramerate.allValues.indices.map { $0 }
        case .imageMode:
            return [0, 1, 2]
        default:
            return [0, 1]
        }
    }

    public var valueDescriptions: [String]? {
        switch self {
        case .continueMode,
             .lastPointRth,
             .obstacleAvoidance:
            return [L10n.commonYes, L10n.commonNo]
        case .framerate:
            return Camera2RecordingFramerate.allValues.map { $0.title }
        case .resolution:
            return [L10n.videoSettingsResolution1080p, L10n.videoSettingsResolution4k]
        case .imageMode:
            return [L10n.cameraModeVideo, L10n.cameraModeTimelapse, L10n.cameraModeGpslapse]

        }
    }

    public var currentValue: Int? {
        switch self {
        case .continueMode:
            return currentFlightPlan?.plan.shouldContinue == true ? 0 : 1
        case .lastPointRth:
            return currentFlightPlan?.plan.lastPointRth == true ? 0 : 1
        case .obstacleAvoidance:
            /// Obstacle avoidance enabled by default.
            guard let oaSetting = currentFlightPlan?.obstacleAvoidanceActivated else { return 0 }

            return oaSetting == true ? 0 : 1
        case .framerate:
            return allValues.first
        case .resolution:
            return 0
        case .imageMode:
            return 0
        }
    }

    public var type: FlightPlanSettingCellType {
        switch self {
        case .continueMode,
             .lastPointRth,
             .obstacleAvoidance,
             .imageMode,
             .resolution:
            return .choice
        case .framerate:
            return .centeredRuler
        }
    }

    public var key: String {
        return self.rawValue
    }

    public var unit: UnitType {
        return .none
    }

    public var step: Double {
        return 1.0
    }

    public var isDisabled: Bool {
        switch self {
        case .imageMode,
             .resolution,
             .framerate:
            return true
        default:
            return false
        }
    }

    public var category: FlightPlanSettingCategory {
        switch self {
        case .imageMode,
             .resolution,
             .framerate:
            return .image
        default:
            return .common
        }
    }

    // MARK: - Private Properties
    private var currentFlightPlan: SavedFlightPlan? {
        return FlightPlanManager.shared.currentFlightPlanViewModel?.flightPlan
    }
}

/// Settings provider for classic Flight Plan.
final class ClassicFlightPlanSettingsProvider: FlightPlanSettingsProvider {
    // MARK: - Internal Properties
    var currentType: FlightPlanType? {
        return nil
    }

    var allTypes: [FlightPlanType] = []

    var settings: [FlightPlanSetting] {
        guard let savedFlightPlan = currentFlightPlan else { return [] }

        return settings(for: savedFlightPlan)
    }

    var settingsCategories: [FlightPlanSettingCategory] {
        return [.image, .common]
    }

    weak var delegate: FlightPlanSettingsProviderDelegate?

    // MARK: - Private Properties
    private var currentFlightPlan: SavedFlightPlan? {
        return FlightPlanManager.shared.currentFlightPlanViewModel?.flightPlan
    }

    // MARK: - Internal Funcs
    func updateType(tag: Int) {
        // No types for classic Flight Plan.
    }

    func updateType(key: String) {
        // No types for classic Flight Plan.
    }

    func updateSettingValue(for key: String, value: Int) {
        // No value setting for classic Flight Plan.
    }

    func updateChoiceSetting(for key: String, value: Bool) {
        switch key {
        case ClassicFlightPlanSettingType.continueMode.key:
            currentFlightPlan?.plan.setShouldContinue(value)
        case ClassicFlightPlanSettingType.lastPointRth.key:
            currentFlightPlan?.plan.setLastPointRth(value)
        case ClassicFlightPlanSettingType.obstacleAvoidance.key:
            currentFlightPlan?.obstacleAvoidanceActivated = value
        default:
            break
        }
    }

    func settings(for flightPlan: SavedFlightPlan) -> [FlightPlanSetting] {
        return [ClassicFlightPlanSettingType.continueMode.toFlightPlanSetting(),
                ClassicFlightPlanSettingType.lastPointRth.toFlightPlanSetting(),
                ClassicFlightPlanSettingType.obstacleAvoidance.toFlightPlanSetting(),
                ClassicFlightPlanSettingType.imageMode.toFlightPlanSetting(),
                ClassicFlightPlanSettingType.resolution.toFlightPlanSetting(),
                ClassicFlightPlanSettingType.framerate.toFlightPlanSetting()]
    }

    func settings(for type: FlightPlanType) -> [FlightPlanSetting] {
        return []
    }
}

/// Settings provider for classic Flight Plan's waypoint.
final class WayPointSettingsProvider: FlightPlanSettingsProvider {
    // MARK: - Internal Properties
    var currentType: FlightPlanType? {
        return nil
    }

    var allTypes: [FlightPlanType] = []

    var settings: [FlightPlanSetting] {
        guard let wayPoint = wayPoint else { return [] }

        return [AltitudeSettingType(altitude: Int(wayPoint.altitude)).toFlightPlanSetting()]
    }

    var settingsCategories: [FlightPlanSettingCategory] {
        return []
    }

    weak var delegate: FlightPlanSettingsProviderDelegate?

    // MARK: - Private Properties
    private weak var wayPoint: WayPoint?

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - wayPoint: the waypoint
    init(wayPoint: WayPoint) {
        self.wayPoint = wayPoint
    }

    // MARK: - Internal Funcs
    func updateType(tag: Int) { }

    func updateType(key: String) { }

    func updateSettingValue(for key: String, value: Int) {
        if key == AltitudeSettingType().key {
            self.wayPoint?.altitude = Double(value)
        }
    }

    func updateChoiceSetting(for key: String, value: Bool) { }

    func settings(for flightPlan: SavedFlightPlan) -> [FlightPlanSetting] {
        return []
    }

    func settings(for type: FlightPlanType) -> [FlightPlanSetting] {
        return []
    }
}

/// Settings provider for classic Flight Plan.
final class WayPointSegmentSettingsProvider: FlightPlanSettingsProvider {
    // MARK: - Internal Properties
    var currentType: FlightPlanType? {
        return nil
    }

    var allTypes: [FlightPlanType] = []

    var settings: [FlightPlanSetting] {
        guard let wayPoint = wayPoint else { return [] }

        return [SpeedSettingType(speed: Int(wayPoint.speed)).toFlightPlanSetting()]
    }

    var settingsCategories: [FlightPlanSettingCategory] {
        return []
    }

    weak var delegate: FlightPlanSettingsProviderDelegate?

    // MARK: - Private Properties
    private weak var wayPoint: WayPoint?

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - wayPoint: the waypoint
    init(wayPoint: WayPoint) {
        self.wayPoint = wayPoint
    }

    // MARK: - Internal Funcs
    func updateType(tag: Int) { }

    func updateType(key: String) { }

    func updateSettingValue(for key: String, value: Int) {
        if key == SpeedSettingType().key {
            self.wayPoint?.speed = Double(value)
        }
    }

    func updateChoiceSetting(for key: String, value: Bool) {
        switch key {
        default:
            break
        }
    }

    func settings(for flightPlan: SavedFlightPlan) -> [FlightPlanSetting] {
        return []
    }

    func settings(for type: FlightPlanType) -> [FlightPlanSetting] {
        return []
    }
}

/// Settings provider for classic Flight Plan's point of interest.
final class PoiPointSettingsProvider: FlightPlanSettingsProvider {
    // MARK: - Internal Properties
    var currentType: FlightPlanType? {
        return nil
    }

    var allTypes: [FlightPlanType] = []

    var settings: [FlightPlanSetting] {
        guard let poiPoint = poiPoint else { return [] }

        return [AltitudeSettingType(altitude: Int(poiPoint.altitude)).toFlightPlanSetting()]
    }

    var settingsCategories: [FlightPlanSettingCategory] {
        return []
    }

    weak var delegate: FlightPlanSettingsProviderDelegate?

    // MARK: - Private Properties
    private weak var poiPoint: PoiPoint?

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - poiPoint: the point of interest
    init(poiPoint: PoiPoint) {
        self.poiPoint = poiPoint
    }

    // MARK: - Internal Funcs
    func updateType(tag: Int) { }

    func updateType(key: String) { }

    func updateSettingValue(for key: String, value: Int) {
        switch key {
        case AltitudeSettingType().key:
            self.poiPoint?.altitude = Double(value)
        default:
            break
        }
    }

    func updateChoiceSetting(for key: String, value: Bool) { }

    func settings(for flightPlan: SavedFlightPlan) -> [FlightPlanSetting] {
        return []
    }

    func settings(for type: FlightPlanType) -> [FlightPlanSetting] {
        return []
    }
}

/// Setting type for altitutde.
final class AltitudeSettingType: FlightPlanSettingType {
    // MARK: - Internal Properties
    var title: String {
        return L10n.flightPlanPointSettingsAltitude
    }

    var allValues: [Int] {
        return Array(3...150)
    }

    var valueDescriptions: [String]?

    var currentValue: Int?

    var type: FlightPlanSettingCellType {
        return .centeredRuler
    }

    var key: String {
        return "flightPlanAltitudeKey"
    }

    var unit: UnitType {
        return .distance
    }

    var step: Double {
        return 1.0
    }

    var isDisabled: Bool {
        return false
    }

    var category: FlightPlanSettingCategory {
        return .custom(title)
    }

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - altitude: the altitude
    init(altitude: Int? = nil) {
        self.currentValue = altitude
    }
}

/// Setting type for speed.
final class SpeedSettingType: FlightPlanSettingType {
    // MARK: - Internal Properties
    var title: String {
        return L10n.commonSpeed
    }

    var allValues: [Int] {
        return Array(1...15)
    }

    var valueDescriptions: [String]?

    var currentValue: Int?

    var type: FlightPlanSettingCellType {
        return .centeredRuler
    }

    var key: String {
        return "flightPlanSpeedKey"
    }

    var unit: UnitType {
        return .speed
    }

    var step: Double {
        return 1.0
    }

    var isDisabled: Bool {
        return false
    }

    var category: FlightPlanSettingCategory {
        return .custom(title)
    }

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - speed: the speed
    init(speed: Int? = nil) {
        self.currentValue = speed
    }
}
