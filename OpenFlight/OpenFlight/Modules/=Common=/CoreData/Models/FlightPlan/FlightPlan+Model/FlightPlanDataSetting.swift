// Copyright (C) 2021 Parrot Drones SAS
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
    public var shouldContinue: Bool? = true
    public var lastPointRth: Bool? = true
    public var captureMode: String?
    public var captureSettings: [String: String]?
    public var disablePhotoSignature: Bool = false
    public var freeSettings = [String: String]()
    public var notPropagatedSettings = [String: String]()
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
    var dirty: Bool
    var zoomLevel: Double?
    var rotation: Double?
    var tilt: Double?

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

    // MARK: - Private Enums
    private enum CodingKeys: String, CodingKey {
        case productName = "product"
        case productId
        case settings
        case polygonPoints
        case dirty
        case longitude
        case latitude
        case zoomLevel
        case rotation
        case tilt
        case obstacleAvoidanceActivated
        case mavlinkDataFile
        case disablePhotoSignature

        // Plan
        case takeoffActions = "takeoff"
        case wayPoints
        case pois = "poi"
        case shouldContinue = "continue"
        case lastPointRth = "RTH"
        case captureMode
        case captureSettings
        case freeSettings
        case notPropagatedSettings
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
    ///    - disablePhotoSignature: wether to disable photo siganture during the
    ///    flight plan
    public init(product: Drone.Model?,
                settings: [FlightPlanLightSetting],
                freeSettings: [String: String],
                polygonPoints: [PolygonPoint]? = nil,
                mavlinkDataFile: Data? = nil,
                takeoffActions: [Action] = [],
                pois: [PoiPoint] = [],
                wayPoints: [WayPoint] = [],
                disablePhotoSignature: Bool) {
        self.takeoffActions = takeoffActions
        self.pois = pois
        self.wayPoints = wayPoints
        self.dirty = false
        self.productName = product?.description ?? ""
        self.productId = product?.internalId ?? 0
        self.settings = settings
        self.freeSettings = freeSettings
        self.polygonPoints = polygonPoints ?? []
        self.mavlinkDataFile = mavlinkDataFile
        self.disablePhotoSignature = disablePhotoSignature

        // Set Flight Plan object relations.
        self.setRelations()
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Mandatory properties.
        self.productName = try container.decode(String.self, forKey: .productName)
        self.productId = try container.decode(Int.self, forKey: .productId)
        self.dirty = try container.decode(Bool.self, forKey: .dirty)
        self.settings = try container.decode([FlightPlanLightSetting].self, forKey: .settings)
        self.polygonPoints = try container.decode([PolygonPoint].self, forKey: .polygonPoints)
        self.captureMode = (try? container.decode(String.self, forKey: .captureMode)) ?? FlightPlanCaptureMode.defaultValue.rawValue
        // Allow non-containing fpExecutions files for old format support.

        // Optional properties.
        self.shouldContinue = try? container.decode(Bool.self, forKey: .shouldContinue)
        self.zoomLevel = try? container.decode(Double.self, forKey: .zoomLevel)
        self.longitude = try? container.decode(Double.self, forKey: .longitude)
        self.latitude = try? container.decode(Double.self, forKey: .latitude)
        self.rotation = try? container.decode(Double.self, forKey: .rotation)
        self.tilt = try? container.decode(Double.self, forKey: .tilt)
        self.obstacleAvoidanceActivated = (try? container.decode(Bool.self, forKey: .obstacleAvoidanceActivated)) ?? true
        self.mavlinkDataFile = try? container.decode(Data.self, forKey: .mavlinkDataFile)
        self.disablePhotoSignature = try container.decode(Bool.self, forKey: .disablePhotoSignature)
        self.captureSettings = try? container.decode([String: String].self, forKey: .captureSettings)
        self.freeSettings = (try? container.decode([String: String].self, forKey: .freeSettings)) ?? [:]
        self.notPropagatedSettings  = (try? container.decode([String: String].self, forKey: .notPropagatedSettings)) ?? [:]
        self.lastPointRth = try? container.decode(Bool.self, forKey: .lastPointRth)

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
        try container.encode(dirty, forKey: .dirty)
        try container.encode(settings, forKey: .settings)
        try container.encode(polygonPoints, forKey: .polygonPoints)
        try container.encode(captureMode, forKey: .captureMode)
        try container.encode(shouldContinue, forKey: .shouldContinue)
        try container.encode(zoomLevel, forKey: .zoomLevel)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(rotation, forKey: .rotation)
        try container.encode(tilt, forKey: .tilt)
        try container.encode(obstacleAvoidanceActivated, forKey: .obstacleAvoidanceActivated)
        try container.encode(mavlinkDataFile, forKey: .mavlinkDataFile)
        try container.encode(disablePhotoSignature, forKey: .disablePhotoSignature)
        try container.encode(captureSettings, forKey: .captureSettings)
        try container.encode(freeSettings, forKey: .freeSettings)
        try container.encode(notPropagatedSettings, forKey: .notPropagatedSettings)
        try container.encode(lastPointRth, forKey: .lastPointRth)
        try container.encode(takeoffActions, forKey: .takeoffActions)
        try container.encode(pois, forKey: .pois)
        try container.encode(wayPoints, forKey: .wayPoints)
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
