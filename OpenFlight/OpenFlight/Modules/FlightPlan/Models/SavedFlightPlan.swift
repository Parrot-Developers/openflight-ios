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

import UIKit
import GroundSdk
import CoreLocation

/// Class representing a FlightPlan saved on disk.
public final class SavedFlightPlan: Codable {
    // MARK: - Public Properties
    public var title: String
    public var type: String?
    public var uuid: String
    public var plan: FlightPlanObject
    public var polygonPoints: [PolygonPoint] = []
    public var settings: [FlightPlanLightSetting] = []
    public var remoteFlightPlanId: Int?
    public var obstacleAvoidanceActivated: Bool? = true
    public var lastModifiedDate: Date? {
        get {
            guard lastModified > 0 else { return nil }
            return Date(timeIntervalSince1970: TimeInterval(lastModified) / Constants.dateTimeIntervalDivider)
        }
        set {
            guard let strongNewValue = newValue else {
                lastModified = 0
                return
            }
            lastModified = Int(strongNewValue.timeIntervalSince1970 * Constants.dateTimeIntervalDivider)
        }
    }

    // MARK: - Internal Properties
    var version: Int
    var progressiveCourseActivated: Bool?
    var dirty: Bool
    var canGenerateMavlink: Bool?
    var zoomLevel: Double?
    var rotation: Double?
    var tilt: Double?

    var coordinate: CLLocationCoordinate2D? {
        get {
            guard let latitude = latitude,
                  let longitude = longitude else {
                // FIXME: location to be defined. Now using initial point.
                return plan.wayPoints.first?.coordinate
            }

            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        set {
            latitude = newValue?.latitude
            longitude = newValue?.longitude
        }
    }

    var product: Drone.Model? {
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

    var savedDate: Date {
        get {
            return Date(timeIntervalSince1970: TimeInterval(date) / Constants.dateTimeIntervalDivider)
        }
        set {
            date = Int(newValue.timeIntervalSince1970 * Constants.dateTimeIntervalDivider)
        }
    }

    public var asData: Data? {
        return try? JSONEncoder().encode(self)
    }

    // MARK: - Private Properties
    private var date: Int
    private var lastModified: Int
    private var productName: String
    private var productId: Int
    private var longitude: Double?
    private var latitude: Double?
    // TODO: Add "lastUse" property later to be ISO with Android.
    // private var lastUse: Int?

    // MARK: - Private Enums
    private enum CodingKeys: String, CodingKey {
        case version
        case title
        case type
        case productName = "product"
        case productId
        case uuid
        case date
        case progressiveCourseActivated = "progressive_course_activated"
        case settings
        case polygonPoints
        case dirty
        case longitude
        case latitude
        // TODO: Add "lastUse" property later to be ISO with Android.
        // case lastUse
        case zoomLevel
        case rotation
        case tilt
        case plan
        case canGenerateMavlink
        case remoteFlightPlanId
        case obstacleAvoidanceActivated
    }

    private enum Constants {
        static let dateTimeIntervalDivider: TimeInterval = 1000.0
    }

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - version: version of FlightPlan
    ///    - title: title of FlightPlan
    ///    - type: FlightPlan type
    ///    - uuid: unique identifier for FlightPlan
    ///    - lastModified: last modification date
    ///    - product: drone used to execute FlightPlan
    ///    - plan: structure of FlightPlan
    ///    - settings: settings of FlightPlan
    ///    - polygonPoints: list of polygon points
    public init(version: Int,
                title: String,
                type: String?,
                uuid: String,
                lastModified: Date? = nil,
                product: Drone.Model,
                plan: FlightPlanObject,
                settings: [FlightPlanLightSetting],
                polygonPoints: [PolygonPoint]? = nil) {
        self.version = version
        self.title = title
        self.uuid = uuid
        self.dirty = false
        self.plan = plan
        self.type = type
        self.date = Int(Date().timeIntervalSince1970 * Constants.dateTimeIntervalDivider)
        self.productName = product.description
        self.productId = product.internalId
        self.settings = settings
        self.polygonPoints = polygonPoints ?? []

        // Set Flight Plan object relations.
        self.plan.setRelations()

        if let strongLastModified = lastModified {
            self.lastModified = Int(strongLastModified.timeIntervalSince1970 * Constants.dateTimeIntervalDivider)
        } else {
            self.lastModified = 0
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Mandatory properties.
        self.title = try container.decode(String.self, forKey: .title)
        self.productName = try container.decode(String.self, forKey: .productName)
        self.productId = try container.decode(Int.self, forKey: .productId)
        self.uuid = try container.decode(String.self, forKey: .uuid)
        self.date = try container.decode(Int.self, forKey: .date)
        self.plan = try container.decode(FlightPlanObject.self, forKey: .plan)
        self.version = try container.decode(Int.self, forKey: .version)
        self.dirty = try container.decode(Bool.self, forKey: .dirty)
        self.settings = try container.decode([FlightPlanLightSetting].self, forKey: .settings)
        self.polygonPoints = try container.decode([PolygonPoint].self, forKey: .polygonPoints)
        self.lastModified = 0
        // Allow non-containing fpExecutions files for old format support.

        // Optional properties.
        self.type = try? container.decode(String.self, forKey: .type)
        self.progressiveCourseActivated = try? container.decode(Bool.self, forKey: .progressiveCourseActivated)
        self.zoomLevel = try? container.decode(Double.self, forKey: .zoomLevel)
        self.longitude = try? container.decode(Double.self, forKey: .longitude)
        self.latitude = try? container.decode(Double.self, forKey: .latitude)
        self.rotation = try? container.decode(Double.self, forKey: .rotation)
        self.tilt = try? container.decode(Double.self, forKey: .tilt)
        self.canGenerateMavlink = try? container.decode(Bool.self, forKey: .canGenerateMavlink)
        self.remoteFlightPlanId = try? container.decode(Int.self, forKey: .remoteFlightPlanId)

        // Set Flight Plan object relations.
        self.plan.setRelations()
    }
}

/// Data utility extention for 'SavedFlightPlan'.

extension Data {
    /// Returns FlightPlan object from JSON data.
    var asFlightPlan: SavedFlightPlan? {
        return try? JSONDecoder().decode(SavedFlightPlan.self, from: self)
    }
}

// MARK: - `SavedFlightPlan` helpers
extension SavedFlightPlan {
    /// Returns default mavlink Url.
    public var mavlinkDefaultUrl: URL? {
        let urlString = NSTemporaryDirectory() + self.uuid
        return URL(fileURLWithPath: urlString).appendingPathExtension(FlightPlanConstants.mavlinkExtension)
    }

    /// Copies Mavlink file to Flight Plan's Mavlink dedicated Url.
    ///
    /// - Parameters:
    ///    - sourceUrl: source Url.
    ///    - isGeneratableMavlink: if the Mavlink is mutable, flight plan can generate one.
    func copyMavlink(from sourceUrl: URL, isGeneratableMavlink: Bool = false) {
        if let destination = self.mavlinkDefaultUrl {
            do {
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.copyItem(atPath: sourceUrl.path, toPath: destination.path)
                self.canGenerateMavlink = isGeneratableMavlink
            } catch {
                ULog.e(ULogTag(name: "Flight Plan"),
                       "Could not copy mavlink file to intended destination: "
                        + error.localizedDescription)
            }
        }
    }

    /// Returns a SavedFlightPlan copy.
    func copy() -> SavedFlightPlan? {
        self.asData?.asFlightPlan
    }
}
