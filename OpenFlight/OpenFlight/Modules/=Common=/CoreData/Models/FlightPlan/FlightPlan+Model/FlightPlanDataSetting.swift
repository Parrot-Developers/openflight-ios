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
import CoreLocation
import GroundSdk

public enum FlightPlanCaptureMode: String, CaseIterable {
    case video
    case timeLapse
    case gpsLapse

    static var defaultValue: FlightPlanCaptureMode {
        return .video
    }

    var title: String {
        switch self {
        case .video:
            return L10n.cameraModeVideo
        case .timeLapse:
            return L10n.cameraModeTimelapse
        case .gpsLapse:
            return L10n.cameraModeGpslapse
        }
    }

    var image: UIImage {
        switch self {
        case .video:
            return Asset.Common.Icons.iconCamera.image
        case .timeLapse:
            return Asset.BottomBar.CameraModes.icCameraModeTimeLapse.image
        case .gpsLapse:
            return Asset.BottomBar.CameraModes.icCameraModeGpsLapse.image
        }
    }
}

/// Class representing a Data Setting saved on disk.
public final class FlightPlanDataSetting: Codable {
    // MARK: - Public Properties
    public var polygonPoints: [PolygonPoint] = []
    public var settings: [FlightPlanLightSetting] = []
    public var obstacleAvoidanceActivated: Bool = true
    public var mavlinkDataFile: Data?
    public var takeoffActions: [Action]
    public var pois: [PoiPoint]
    public var wayPoints: [WayPoint]
    public var isBuckled: Bool?
    public var shouldContinue: Bool = false
    public var lastPointRth: Bool = true
    public var disconnectionRth: Bool = true
    public var captureMode: String?
    public var captureSettings: [String: String]?
    public var disablePhotoSignature: Bool = false
    public var freeSettings = [String: String]()
    public var notPropagatedSettings = [String: String]()
    /// Pgy data
    public var pgyProjectId: Int64?
    public var uploadAttemptCount: Int16?
    public var lastUploadAttempt: Date?
    /// Identifier of first media resource captured after the drone has passed the `lastMissionItemExecuted`.
    public var recoveryResourceId: String?
    /// Mavlink
    private var _mavlinkCommands: [MavlinkStandard.MavlinkCommand]?
    public var mavlinkCommands: [MavlinkStandard.MavlinkCommand]? {
        if let commands = _mavlinkCommands {
            return commands
        }
        guard let data = mavlinkDataFile,
              let str = String(data: data, encoding: .utf8),
              let commands = try? MavlinkStandard.MavlinkFiles.parse(mavlinkString: str) else {
            return nil
        }
        _mavlinkCommands = commands
        return commands
    }

    // MARK: - Internal Properties

    var coordinate: CLLocationCoordinate2D? {
        get {
            guard let latitude = latitude,
                  let longitude = longitude else {
                // FIXME: location to be defined. Now using initial point.
                return wayPoints.first?.coordinate
            }

            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        set {
            latitude = newValue?.latitude
            longitude = newValue?.longitude
        }
    }

    /// Returns the last known drone location during a flight
    /// This value is updated by `FlightPlanRunManager` during the FP execution.
    var lastDroneLocation: CLLocation? {
        get {
            guard let latitude = droneLatitude,
                  let longitude = droneLongitude,
                  let altitude = droneAltitude,
                  let horizontalAccuracy = droneLocaltionHorizontalAccuracy,
                  let verticalAccuracy = droneLocaltionVerticalAccuracy,
                  let timestamp = droneLocaltionTimestamp
            else { return nil }

            return CLLocation(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                              altitude: altitude,
                              horizontalAccuracy: horizontalAccuracy,
                              verticalAccuracy: verticalAccuracy,
                              timestamp: timestamp)
        }
        set {
            droneLatitude = newValue?.coordinate.latitude
            droneLongitude = newValue?.coordinate.longitude
            droneAltitude = newValue?.altitude
            droneLocaltionHorizontalAccuracy = newValue?.horizontalAccuracy
            droneLocaltionVerticalAccuracy = newValue?.verticalAccuracy
            droneLocaltionTimestamp = newValue?.timestamp
        }
    }

    public private(set) var product: Drone.Model? {
        get {
            switch DeviceModel.from(internalId: productId) {
            case let .drone(droneModel):
                return droneModel
            default:
                return nil
            }
        }
        set {
            productName = newValue?.description ?? ""
            productId = newValue?.internalId ?? 0
        }
    }

    public var asData: Data? {
        return try? JSONEncoder().encode(self)
    }

    // MARK: - Private Properties
    private var productName: String
    private var productId: Int
    private var longitude: Double?
    private var latitude: Double?
    // Drone location
    private var droneLatitude: Double?
    private var droneLongitude: Double?
    private var droneAltitude: Double?
    private var droneLocaltionHorizontalAccuracy: Double?
    private var droneLocaltionVerticalAccuracy: Double?
    private var droneLocaltionTimestamp: Date?

    // MARK: - Private Enums
    private enum CodingKeys: String, CodingKey {
        case productName = "product"
        case productId
        case settings
        case polygonPoints
        case longitude
        case latitude
        case obstacleAvoidanceActivated
        case mavlinkDataFile
        case disablePhotoSignature

        // Plan
        case takeoffActions = "takeoff"
        case wayPoints
        case pois = "poi"
        case shouldContinue = "continue"
        case lastPointRth = "RTH"
        case disconnectionRth
        case captureMode
        case captureSettings
        case freeSettings
        case notPropagatedSettings

        // PGY
        case pgyProjectId
        case uploadAttemptCount
        case lastUploadAttempt

        // Recovery
        case recoveryResourceId

        // Drone
        case droneLatitude
        case droneLongitude
        case droneAltitude
        case droneLocaltionHorizontalAccuracy
        case droneLocaltionVerticalAccuracy
        case droneLocaltionTimestamp
    }

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - type: FlightPlan type
    ///    - lastModified: last modification date
    ///    - product: drone used to execute FlightPlan
    ///    - settings: settings of FlightPlan
    ///    - polygonPoints: list of polygon points
    ///    - disablePhotoSignature: whether to disable photo siganture during the
    ///    flight plan
    ///    - pgyProjectId: the pgy project ID.
    ///    - uploadAttemptCount: the number of pgy pics upload attempts.
    ///    - lastUploadAttempt: the last pgy upload attempt date.
    ///    - lastUploadAttempt: the last pgy upload attempt date.
    ///    - lastDroneLocation: the last known drone location.
    ///    - recoveryResourceId: identifier of first media resource captured after the drone has
    ///     passed the `lastMissionItemExecuted`.
    public init(product: Drone.Model?,
                settings: [FlightPlanLightSetting],
                freeSettings: [String: String],
                polygonPoints: [PolygonPoint]? = nil,
                mavlinkDataFile: Data? = nil,
                takeoffActions: [Action] = [],
                pois: [PoiPoint] = [],
                wayPoints: [WayPoint] = [],
                disablePhotoSignature: Bool,
                pgyProjectId: Int64? = nil,
                uploadAttemptCount: Int16? = nil,
                lastUploadAttempt: Date? = nil,
                lastDroneLocation: CLLocation? = nil,
                recoveryResourceId: String? = nil) {
        self.takeoffActions = takeoffActions
        self.pois = pois
        self.wayPoints = wayPoints
        self.productName = product?.description ?? ""
        self.productId = product?.internalId ?? 0
        self.settings = settings
        self.freeSettings = freeSettings
        self.polygonPoints = polygonPoints ?? []
        self.mavlinkDataFile = mavlinkDataFile
        self.disablePhotoSignature = disablePhotoSignature
        self.pgyProjectId = pgyProjectId
        self.uploadAttemptCount = uploadAttemptCount
        self.lastUploadAttempt = lastUploadAttempt
        self.lastDroneLocation = lastDroneLocation
        self.recoveryResourceId = recoveryResourceId

        // Set Flight Plan object relations.
        self.setRelations()
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Mandatory properties.
        self.productName = try container.decode(String.self, forKey: .productName)
        self.productId = try container.decode(Int.self, forKey: .productId)
        self.settings = try container.decode([FlightPlanLightSetting].self, forKey: .settings)
        self.polygonPoints = try container.decode([PolygonPoint].self, forKey: .polygonPoints)
        self.captureMode = (try? container.decode(String.self, forKey: .captureMode)) ?? FlightPlanCaptureMode.defaultValue.rawValue
        // Allow non-containing fpExecutions files for old format support.

        // Optional properties.
        self.shouldContinue = (try? container.decode(Bool.self, forKey: .shouldContinue)) ?? false
        self.longitude = try? container.decode(Double.self, forKey: .longitude)
        self.latitude = try? container.decode(Double.self, forKey: .latitude)
        self.droneLatitude = try? container.decode(Double.self, forKey: .droneLatitude)
        self.droneLongitude = try? container.decode(Double.self, forKey: .droneLongitude)
        self.droneAltitude = try? container.decode(Double.self, forKey: .droneAltitude)
        self.droneLocaltionHorizontalAccuracy = try? container.decode(Double.self, forKey: .droneLocaltionHorizontalAccuracy)
        self.droneLocaltionVerticalAccuracy = try? container.decode(Double.self, forKey: .droneLocaltionVerticalAccuracy)
        self.droneLocaltionTimestamp = try? container.decode(Date.self, forKey: .droneLocaltionTimestamp)
        self.obstacleAvoidanceActivated = (try? container.decode(Bool.self, forKey: .obstacleAvoidanceActivated)) ?? true
        self.mavlinkDataFile = try? container.decode(Data.self, forKey: .mavlinkDataFile)
        self.disablePhotoSignature = try container.decode(Bool.self, forKey: .disablePhotoSignature)
        self.captureSettings = try? container.decode([String: String].self, forKey: .captureSettings)
        self.freeSettings = (try? container.decode([String: String].self, forKey: .freeSettings)) ?? [:]
        self.notPropagatedSettings  = (try? container.decode([String: String].self, forKey: .notPropagatedSettings)) ?? [:]
        self.lastPointRth = (try? container.decode(Bool.self, forKey: .lastPointRth)) ?? true
        self.disconnectionRth = (try? container.decode(Bool.self, forKey: .disconnectionRth)) ?? true
        self.pgyProjectId = try? container.decode(Int64.self, forKey: .pgyProjectId)
        self.uploadAttemptCount = try? container.decode(Int16.self, forKey: .uploadAttemptCount)
        self.lastUploadAttempt = try? container.decode(Date.self, forKey: .lastUploadAttempt)
        self.recoveryResourceId = try? container.decode(String.self, forKey: .recoveryResourceId)

        // Plan
        self.takeoffActions = try container.decode([Action].self, forKey: .takeoffActions)
        self.pois = try container.decode([PoiPoint].self, forKey: .pois)
        self.wayPoints = try container.decode([WayPoint].self, forKey: .wayPoints)
        // Set Flight Plan object relations.
        self.setRelations()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(productName, forKey: .productName)
        try container.encode(productId, forKey: .productId)
        try container.encode(settings, forKey: .settings)
        try container.encode(polygonPoints, forKey: .polygonPoints)
        try container.encode(captureMode, forKey: .captureMode)
        try container.encode(shouldContinue, forKey: .shouldContinue)

        try container.encode(longitude, forKey: .longitude)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(droneLatitude, forKey: .droneLatitude)
        try container.encode(droneLongitude, forKey: .droneLongitude)
        try container.encode(droneAltitude, forKey: .droneAltitude)
        try container.encode(droneLocaltionHorizontalAccuracy, forKey: .droneLocaltionHorizontalAccuracy)
        try container.encode(droneLocaltionVerticalAccuracy, forKey: .droneLocaltionVerticalAccuracy)
        try container.encode(droneLocaltionTimestamp, forKey: .droneLocaltionTimestamp)
        try container.encode(obstacleAvoidanceActivated, forKey: .obstacleAvoidanceActivated)
        try container.encode(mavlinkDataFile, forKey: .mavlinkDataFile)
        try container.encode(disablePhotoSignature, forKey: .disablePhotoSignature)
        try container.encode(captureSettings, forKey: .captureSettings)
        try container.encode(freeSettings, forKey: .freeSettings)
        try container.encode(notPropagatedSettings, forKey: .notPropagatedSettings)
        try container.encode(lastPointRth, forKey: .lastPointRth)
        try container.encode(disconnectionRth, forKey: .disconnectionRth)
        try container.encode(takeoffActions, forKey: .takeoffActions)
        try container.encode(pois, forKey: .pois)
        try container.encode(wayPoints, forKey: .wayPoints)
        try container.encode(pgyProjectId, forKey: .pgyProjectId)
        try container.encode(uploadAttemptCount, forKey: .uploadAttemptCount)
        try container.encode(lastUploadAttempt, forKey: .lastUploadAttempt)
        try container.encode(recoveryResourceId, forKey: .recoveryResourceId)
    }

    public func copy() -> FlightPlanDataSetting {
        let copy = FlightPlanDataSetting(product: product,
                                         settings: settings,
                                         freeSettings: freeSettings,
                                         polygonPoints: polygonPoints,
                                         mavlinkDataFile: mavlinkDataFile,
                                         takeoffActions: takeoffActions,
                                         pois: pois,
                                         wayPoints: wayPoints,
                                         disablePhotoSignature: disablePhotoSignature,
                                         pgyProjectId: pgyProjectId,
                                         uploadAttemptCount: uploadAttemptCount,
                                         lastUploadAttempt: lastUploadAttempt,
                                         lastDroneLocation: lastDroneLocation,
                                         recoveryResourceId: recoveryResourceId)
        copy.isBuckled = isBuckled
        copy.shouldContinue = shouldContinue
        copy.lastPointRth = lastPointRth
        copy.disconnectionRth = disconnectionRth
        copy.captureMode = captureMode
        copy.captureSettings = captureSettings
        copy.captureModeEnum = captureModeEnum
        copy.resolution = resolution
        copy.whiteBalanceMode = whiteBalanceMode
        copy.framerate = framerate
        copy.photoResolution = photoResolution
        copy.exposure = exposure
        copy.timeLapseCycle = timeLapseCycle
        copy.gpsLapseDistance = gpsLapseDistance
        copy.obstacleAvoidanceActivated = obstacleAvoidanceActivated
        copy.settings = settings
        copy.freeSettings = freeSettings
        copy.disablePhotoSignature = disablePhotoSignature
        copy._mavlinkCommands = _mavlinkCommands
        copy.coordinate = coordinate
        copy.pgyProjectId = pgyProjectId
        copy.uploadAttemptCount = uploadAttemptCount
        copy.lastUploadAttempt = lastUploadAttempt
        copy.lastDroneLocation = lastDroneLocation
        copy.recoveryResourceId = recoveryResourceId
        return copy
    }
}

// MARK: - `FlightPlanDataSetting` helpers
public extension FlightPlanDataSetting {
    func toJSONString() -> String? {
        guard
            let jsonData = try? JSONEncoder().encode(self),
            let stringJson = String(data: jsonData, encoding: .utf8) else { return nil }
        return stringJson
    }

    static func instantiate(with jsonString: String?) -> Self? {
        guard
            let jsonString = jsonString,
            let json = jsonString.data(using: .utf8),
            let result = try? JSONDecoder().decode(Self.self, from: json) else { return nil }
        return result
    }
}

/// Log helper
/// Displays the number of way points and pois in the Logs.
extension FlightPlanDataSetting: CustomStringConvertible {
    public var description: String {
        return "WP: \(wayPoints.count), POIs: \(pois.count)"
    }
}
