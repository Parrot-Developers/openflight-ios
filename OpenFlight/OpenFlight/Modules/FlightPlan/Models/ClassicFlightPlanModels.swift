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
import ArcGIS

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
    func executionSummaryVC(execution: FlightPlanExecution, coordinator: FlightPlanPanelCoordinator) -> UIViewController? {
        return nil
    }

    func graphicsWithFlightPlan(_ flightPlanObject: FlightPlanObject) -> [FlightPlanGraphic] {
        return flightPlanObject.allLinesAndMarkersGraphics
    }
}

/// Enum describing classic flight plan type
public enum ClassicFlightPlanType: String, FlightPlanType, CaseIterable {
    case standard

    /// Not used
    public var title: String { "" }

    public var icon: UIImage { missionMode.icon }

    /// Not used
    public var tag: Int { 0 }

    public var key: String { FlightPlanConstants.defaultType }

    public var canGenerateMavlink: Bool { false }

    public var mavLinkType: FlightPlanInterpreter { .standard }

    public var missionProvider: MissionProvider { FlightPlanMission() }

    public var missionMode: MissionMode { FlightPlanMissionMode.standard.missionMode }

}

/// Setting types for Classic Flight Plan.
public enum ClassicFlightPlanSettingType: String, FlightPlanSettingType, CaseIterable {
    case continueMode
    case lastPointRth
    case obstacleAvoidance
    case imageMode
    case resolution
    case framerate
    case timeLapseCycle
    case gpsLapseDistance
    case exposure
    case whiteBalance
    case photoResolution

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
        case .timeLapseCycle:
            return L10n.commonDuration
        case .gpsLapseDistance:
            return L10n.commonDistance
        case .exposure:
            return L10n.flightPlanSettingsExposure
        case .photoResolution:
            return L10n.flightPlanSettingsResolution
        case .whiteBalance:
            return L10n.flightPlanSettingsWhiteBalance
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
             .framerate,
             .timeLapseCycle,
             .gpsLapseDistance,
             .exposure,
             .whiteBalance,
             .photoResolution:
            return nil
        }
    }

    public var allValues: [Int] {
        switch self {
        case .framerate:
            guard let currentFlightPlan = currentFlightPlan else { return [] }

            let resolution = currentFlightPlan.plan.resolution
            return Camera2Params.supportedRecordingFramerate(for: resolution).indices.map { $0 }
        case .imageMode:
            return FlightPlanCaptureMode.allCases.indices.map { $0 }
        case .resolution:
            return Camera2Params.supportedRecordingResolution().indices.map { $0 }
        case .timeLapseCycle:
            guard let currentFlightPlan = currentFlightPlan else { return [] }

            let resolution = currentFlightPlan.plan.photoResolution
            let supportedTimelapses = TimeLapseMode.supportedValuesForResolution(for: resolution)
            return supportedTimelapses.compactMap { $0.value }
        case .gpsLapseDistance:
            return GpsLapseMode.allValues.compactMap { ($0 as? GpsLapseMode)?.value }
        case .whiteBalance:
            return Camera2WhiteBalanceMode.availableModes.indices.map { $0 }
        case .photoResolution:
            return Camera2PhotoResolution.availableResolutions.indices.map { $0 }
        case .exposure:
            return Camera2EvCompensation.availableValues.indices.map { $0 }
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
            guard let currentFlightPlan = currentFlightPlan else { return nil }

            let resolution = currentFlightPlan.plan.resolution
            return Camera2Params.supportedRecordingFramerate(for: resolution).map { $0.title }
        case .resolution:
            return Camera2Params.supportedRecordingResolution().map { $0.title }
        case .imageMode:
            return FlightPlanCaptureMode.allCases.map { $0.title }
        case .timeLapseCycle:
            guard let currentFlightPlan = currentFlightPlan else { return [] }

            let resolution = currentFlightPlan.plan.photoResolution
            let supportedTimelapses = TimeLapseMode.supportedValuesForResolution(for: resolution)
            return supportedTimelapses.compactMap { $0.title }
        case .gpsLapseDistance:
            return GpsLapseMode.allValues.compactMap { ($0 as? GpsLapseMode)?.title }
        case .whiteBalance:
            return Camera2WhiteBalanceMode.availableModes.map { $0.title }
        case .photoResolution:
            return Camera2PhotoResolution.availableResolutions.map { $0.title }
        case .exposure:
            return Camera2EvCompensation.availableValues.map { $0.title }
        }
    }

    public var valueImages: [UIImage]? {
        switch self {
        case .imageMode:
            return FlightPlanCaptureMode.allCases.map { $0.image }
        default:
            return nil
        }
    }

    public var currentValue: Int? {
        guard let currentFlightPlan = currentFlightPlan else { return nil }

        switch self {
        case .continueMode:
            return currentFlightPlan.plan.shouldContinue == true ? 0 : 1
        case .lastPointRth:
            return currentFlightPlan.plan.lastPointRth == true ? 0 : 1
        case .obstacleAvoidance:
            /// Obstacle avoidance enabled by default.
            guard let oaSetting = currentFlightPlan.obstacleAvoidanceActivated else { return 0 }

            return oaSetting == true ? 0 : 1
        case .framerate:
            let resolution = currentFlightPlan.plan.resolution
            let framerate = currentFlightPlan.plan.framerate
            return Camera2Params.supportedRecordingFramerate(for: resolution).firstIndex(of: framerate)
        case .resolution:
            let resolution = currentFlightPlan.plan.resolution
            return Camera2Params.supportedRecordingResolution().firstIndex(of: resolution)
        case .imageMode:
            let mode = currentFlightPlan.plan.captureModeEnum
            return FlightPlanCaptureMode.allCases.firstIndex(where: { $0 == mode })
        case .gpsLapseDistance:
            guard let value = currentFlightPlan.plan.gpsLapseDistance else {
                return allValues.first ?? 0
            }

            return value
        case .timeLapseCycle:
            guard let value = currentFlightPlan.plan.timeLapseCycle else {
                return allValues.first ?? 0
            }

            return value
        case .exposure:
            let value = currentFlightPlan.plan.exposure
            return Camera2EvCompensation.availableValues.firstIndex(where: { $0 == value })
        case .photoResolution:
            let value = currentFlightPlan.plan.photoResolution
            return Camera2PhotoResolution.availableResolutions.firstIndex(where: { $0 == value })
        case .whiteBalance:
            let value = currentFlightPlan.plan.whiteBalanceMode
            return Camera2WhiteBalanceMode.availableModes.firstIndex(where: { $0 == value })
        }
    }

    public var type: FlightPlanSettingCellType {
        switch self {
        case .continueMode,
             .lastPointRth,
             .obstacleAvoidance:
            return .choice
        case .framerate,
             .resolution,
             .imageMode,
             .gpsLapseDistance,
             .timeLapseCycle,
             .exposure,
             .whiteBalance,
             .photoResolution:
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

    public var divider: Double {
        return 1.0
    }

    public var isDisabled: Bool {
        return false
    }

    public var category: FlightPlanSettingCategory {
        switch self {
        case .imageMode,
             .resolution,
             .framerate,
             .gpsLapseDistance,
             .timeLapseCycle,
             .exposure,
             .photoResolution,
             .whiteBalance:
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
        return ClassicFlightPlanType.standard
    }

    var allTypes: [FlightPlanType] = [ ClassicFlightPlanType.standard ]

    var settings: [FlightPlanSetting] {
        guard let savedFlightPlan = currentFlightPlan else { return [] }

        return settings(for: savedFlightPlan)
    }

    var settingsCategories: [FlightPlanSettingCategory] {
        return [.image, .common]
    }

    // MARK: - Private Properties
    private var currentFlightPlan: SavedFlightPlan? {
        return FlightPlanManager.shared.currentFlightPlanViewModel?.flightPlan
    }

    // MARK: - Internal Funcs
    func updateType(tag: Int) {
        // Only one type for classic Flight Plan.
    }

    func updateType(key: String) {
        // Only one type for classic Flight Plan.
    }

    func updateSettingValue(for key: String, value: Int) {
        guard let currentFlightPlan = currentFlightPlan else { return }

        switch key {
        case ClassicFlightPlanSettingType.gpsLapseDistance.key:
            currentFlightPlan.plan.gpsLapseDistance = value
        case ClassicFlightPlanSettingType.timeLapseCycle.key:
            currentFlightPlan.plan.timeLapseCycle = value
        case ClassicFlightPlanSettingType.framerate.key:
            let currentResolution = currentFlightPlan.plan.resolution
            let allValues = Camera2Params.supportedRecordingFramerate(for: currentResolution)
            if value < allValues.count {
                currentFlightPlan.plan.framerate = allValues[value]
            }
        case ClassicFlightPlanSettingType.resolution.key:
            let allValues = Camera2Params.supportedRecordingResolution()
            if value < allValues.count {
                currentFlightPlan.plan.resolution = allValues[value]
                currentFlightPlan.plan.framerate = Camera2RecordingFramerate.defaultFramerate
            }
        case ClassicFlightPlanSettingType.imageMode.key where value < FlightPlanCaptureMode.allCases.count:
            currentFlightPlan.plan.captureModeEnum = FlightPlanCaptureMode.allCases[value]
        case ClassicFlightPlanSettingType.photoResolution.key where value < Camera2PhotoResolution.availableResolutions.count:
            currentFlightPlan.plan.photoResolution =  Camera2PhotoResolution.resolutionForIndex(value)
        case ClassicFlightPlanSettingType.exposure.key where value < Camera2EvCompensation.availableValues.count:
            currentFlightPlan.plan.exposure =  Camera2EvCompensation.compensationForIndex(value)
        case ClassicFlightPlanSettingType.whiteBalance.key where value < Camera2WhiteBalanceMode.availableModes.count:
            currentFlightPlan.plan.whiteBalanceMode =  Camera2WhiteBalanceMode.modeForIndex(value)
        default:
            break
        }
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
        var planSettings: [FlightPlanSetting] = [ClassicFlightPlanSettingType.continueMode.toFlightPlanSetting(),
                ClassicFlightPlanSettingType.lastPointRth.toFlightPlanSetting(),
                ClassicFlightPlanSettingType.obstacleAvoidance.toFlightPlanSetting(),
                ClassicFlightPlanSettingType.imageMode.toFlightPlanSetting()]

        switch flightPlan.plan.captureModeEnum {
        case .video:
            planSettings.append(ClassicFlightPlanSettingType.resolution.toFlightPlanSetting())
            planSettings.append(ClassicFlightPlanSettingType.framerate.toFlightPlanSetting())
        case .gpsLapse:
            planSettings.append(ClassicFlightPlanSettingType.gpsLapseDistance.toFlightPlanSetting())
            planSettings.append(ClassicFlightPlanSettingType.photoResolution.toFlightPlanSetting())
        case .timeLapse:
            planSettings.append(ClassicFlightPlanSettingType.timeLapseCycle.toFlightPlanSetting())
            planSettings.append(ClassicFlightPlanSettingType.photoResolution.toFlightPlanSetting())
        }

        planSettings.append(ClassicFlightPlanSettingType.exposure.toFlightPlanSetting())
        planSettings.append(ClassicFlightPlanSettingType.whiteBalance
                                .toFlightPlanSetting())

        return planSettings
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

        let wayPointSetting = AltitudeSettingType(altitude: Int(wayPoint.altitude),
                                                  range: FlightPlanObjectConstants.wayPointAltitudeRange)

        return [wayPointSetting.toFlightPlanSetting(),
                TiltAngleSettingType(tiltAngle: Int(wayPoint.tilt),
                                     isDisabled: wayPoint.poiIndex != nil).toFlightPlanSetting()]
    }

    var settingsCategories: [FlightPlanSettingCategory] {
        return []
    }

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

    // MARK: - Public Funcs
    // Find closest valid angle for the requested camera tilt
    // An angle is considered valid when it is a multiple of 5
    class func closestAngle(value: Double) -> Int {
        let mult: Double = value / 5.0
        return 5 * Int(mult.rounded())
    }

    // MARK: - Internal Funcs
    func updateType(tag: Int) { }

    func updateType(key: String) { }

    func updateSettingValue(for key: String, value: Int) {
        if key == AltitudeSettingType().key {
            self.wayPoint?.altitude = Double(value)
            self.wayPoint?.updateTiltRelation()
        } else if key == TiltAngleSettingType().key {
            self.wayPoint?.tilt = Double(value)
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

        let setting = AltitudeSettingType(altitude: Int(poiPoint.altitude),
                                          range: FlightPlanObjectConstants.poiPointAltitudeRange)

        return [setting.toFlightPlanSetting()]
    }

    var settingsCategories: [FlightPlanSettingCategory] {
        return []
    }

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
            if let wayPoints = self.poiPoint?.wayPoints {
                wayPoints.forEach {
                    $0.updateTiltRelation()
                }
            }
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

/// Setting type for altitude.
final class AltitudeSettingType: FlightPlanSettingType {
    // MARK: - Internal Properties
    var title: String {
        return L10n.flightPlanPointSettingsAltitude
    }

    var allValues: [Int] = []

    var valueDescriptions: [String]?

    var valueImages: [UIImage]?

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

    var divider: Double {
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
    init(altitude: Int? = nil, range: [Int] = FlightPlanObjectConstants.wayPointAltitudeRange) {
        self.currentValue = altitude
        self.allValues = range
    }
}

/// Setting type for tilt angle.
final class TiltAngleSettingType: FlightPlanSettingType {
    // MARK: - Internal Properties
    var title: String {
        return L10n.flightPlanPointSettingsCameraAngle
    }

    var allValues: [Int] {
        return Array(-90...90).stepFiltered(with: Int(step))
    }

    var valueDescriptions: [String]?

    var valueImages: [UIImage]?

    var currentValue: Int?

    var type: FlightPlanSettingCellType {
        return .centeredRuler
    }

    var key: String {
        return "flightPlanTiltAngleKey"
    }

    var unit: UnitType {
        return .degree
    }

    var step: Double {
        return 5.0
    }

    var divider: Double {
        return 1.0
    }

    var isDisabled: Bool

    var category: FlightPlanSettingCategory {
        return .custom(title)
    }

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - tiltAngle: the tilt angle
    ///    - isDisabled: whether setting is currently disabled
    init(tiltAngle: Int? = nil,
         isDisabled: Bool = false) {
        self.currentValue = tiltAngle
        self.isDisabled = isDisabled
    }
}

/// Setting type for speed.
final class SpeedSettingType: FlightPlanSettingType {
    // MARK: - Internal Properties
    var title: String {
        return L10n.commonSpeed
    }

    var allValues: [Int] {
        // speed values range from 5 to 120 with a 5 step increment (step/divider)
        return Array(5...120).stepFiltered(with: Int(step/divider))
    }

    var valueDescriptions: [String]?

    var valueImages: [UIImage]?

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
        return 0.5
    }

    var divider: Double {
        return 0.1
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
