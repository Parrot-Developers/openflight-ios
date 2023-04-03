//    Copyright (C) 2023 Parrot Drones SAS
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

// MARK: - Internal Enums
public enum GutmaConstants {
    public static let dateFormatLogging: String = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
    public static let dateFormatFile: String = "yyyy-MM-dd'T'HH:mm:ssZ"
    public static let unknownCoordinate: Double = 500
    public static let firstVersionWithAmsl: String = "1.0.1"
    public static let eventStepStart: String = "START"
    public static let eventStepPause: String = "PAUSE"
    public static let eventStepResume: String = "RESUME"
    public static let eventStepStop: String = "STOP"
    public static let eventStepPathStop: String = "PATH_STOP"
    public static let eventInfoFlightPlan: String = "FLIGHTPLAN"
    public static let eventTypeFlightPlan: String = "CONTROLLER_FLIGHTPLAN"
    public static let eventStepMissionItem: String = "MISSION_ITEM"
    public static let eventStepTakeOff: String = "TOF"
    public static let eventStepFlightDate: String = "FLIGHTDATE"
    public static let eventInfoPhoto = "PHOTO"
    public static let eventInfoVideo = "VIDEO"
    public static let eventMediaTypeSaved = "saved"
    public static let eventMediaTypeStarted = "start"
    public static let eventMediaTypeTaken = "taken"
    public static let eventMediaTypeDeleted = "deleted"
}

// MARK: - CLLocationCoordinate2D helpers.
public extension CLLocationCoordinate2D {
    /// Returns true if the coordinate is valid.
    var isValid: Bool {
        return CLLocationCoordinate2DIsValid(self)
    }
}

// MARK: - Gutma helpers.

public extension PictorGutma {

    struct Model {
        public let flight: PictorFlightModel
        public let gutmaLinks: [PictorGutmaLinkModel]
    }

    var startDate: Date? {
        guard let dateString = exchange?.message?.flightLogging?.loggingStartDtg else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = GutmaConstants.dateFormatFile
        // Handle both 24-h and 12-h format.
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let date = formatter.date(from: dateString)
        return date?.addingTimeInterval(flightDateTimestamp ?? takeOffTimestamp)
    }

    var duration: TimeInterval {
        return exchange?.message?.flightLogging?.duration ?? 0.0
    }

    var flightId: String? {
        return exchange?.message?.flightData?.flightID
    }

    var batteryConsumption: Double? {
        return exchange?.message?.flightLogging?.batteryConsumption
    }

    var distance: Double {
        return exchange?.message?.flightLogging?.distance ?? 0.0
    }

    var file: File? {
        return exchange?.message?.file
    }

    var takeOffTimestamp: TimeInterval {
        return exchange?.message?.flightLogging?.takeOffTimestamp ?? 0
    }

    var flightDateTimestamp: TimeInterval? {
        guard let time = exchange?.message?.flightLogging?.flightDateTimestamp else { return nil }
        return floor(time)
    }

    var photoCount: Int {
        let photos = (exchange?.message?.flightLogging?.events?.filter {
            guard let photoTimestamp = TimeInterval($0.eventTimestamp ?? "") else { return false }
            return $0.eventInfo == GutmaConstants.eventInfoPhoto
            && $0.mediaEvent == GutmaConstants.eventMediaTypeTaken
            && photoTimestamp > takeOffTimestamp
        })
        return photos?.count ?? 0
    }

    var videoCount: Int {
        let autoRecordTolerance: TimeInterval = 0.5
        let videos = (exchange?.message?.flightLogging?.events?
            .filter {
                $0.eventInfo == GutmaConstants.eventInfoVideo
                && $0.mediaEvent == GutmaConstants.eventMediaTypeStarted
            }
            .filter {
                guard let photoTimestamp = TimeInterval($0.eventTimestamp ?? "") else { return false }
                return photoTimestamp > takeOffTimestamp - autoRecordTolerance
            })
        return videos?.count ?? 0
    }

    func flightPlanExecutions(flightUuid: String) -> [PictorGutmaLinkModel] {
        guard let startDate = startDate else { return [] }
        let fpfs: [PictorGutmaLinkModel] = exchange?.message?.flightLogging?.events?
            .compactMap {
                if $0.eventInfo == GutmaConstants.eventInfoFlightPlan,
                   $0.eventType == GutmaConstants.eventTypeFlightPlan,
                   $0.step == GutmaConstants.eventStepMissionItem,
                   let flightPlanUuid = $0.customId,
                   let timestampString = $0.eventTimestamp,
                   let timestamp = Double(timestampString) {
                    let dateExecutionFlight = startDate.addingTimeInterval(timestamp)
                    return PictorGutmaLinkModel(executionDate: dateExecutionFlight,
                                                flightPlanUuid: flightPlanUuid,
                                                flightUuid: flightUuid)
                }
                return nil
            } ?? []
        // Keep only one FPF by flightPlan (the earliest)
        let dict = Dictionary(fpfs.map { ($0.flightPlanUuid, $0) },
                              uniquingKeysWith: { $0.executionDate < $1.executionDate ? $0 : $1 })
        return Array(dict.values)
    }

    func toFlight(gutmaFile: Data) -> Model? {
        guard let uuid = flightId else {
            return nil
        }
        guard let parrotVersion = file?.parrotVersion else { return nil }
        let startPosition = exchange?.message?.flightLogging?.startPosition
        let aircraft = exchange?.message?.flightData?.aircraft
        let flight = PictorFlightModel(uuid: uuid,
                                       cloudId: 0,
                                       formatVersion: parrotVersion,
                                       title: "",
                                       parseError: false,
                                       runDate: startDate,
                                       serial: aircraft?.serialNumber ?? "unknown",
                                       firmware: aircraft?.firmwareVersion ?? "unknown",
                                       modelId: aircraft?.productId ?? "unknown",
                                       gutmaFile: gutmaFile,
                                       photoCount: Int16(photoCount),
                                       videoCount: Int16(videoCount),
                                       startLatitude: startPosition?.coordinate.latitude ?? GutmaConstants.unknownCoordinate,
                                       startLongitude: startPosition?.coordinate.longitude ?? GutmaConstants.unknownCoordinate,
                                       batteryConsumption: Int16(batteryConsumption ?? 0),
                                       distance: distance,
                                       duration: duration,
                                       thumbnail: nil)
        return Model(flight: flight, gutmaLinks: flightPlanExecutions(flightUuid: uuid))
    }

    func update(flight: PictorFlightModel) -> PictorFlightModel {
        guard let parrotVersion = file?.parrotVersion else { return flight }

        let startPosition = exchange?.message?.flightLogging?.startPosition
        var flight = flight
        flight.formatVersion = parrotVersion
        flight.runDate = startDate
        flight.photoCount = Int16(photoCount)
        flight.videoCount = Int16(videoCount)
        flight.startLatitude = startPosition?.coordinate.latitude ?? GutmaConstants.unknownCoordinate
        flight.startLongitude = startPosition?.coordinate.longitude ?? GutmaConstants.unknownCoordinate
        flight.batteryConsumption = Int16(batteryConsumption ?? 0)
        flight.distance = distance
        flight.duration = duration

        return flight
    }
}

// MARK: - FlightLogging private helpers.

public extension PictorGutma.FlightLogging {
    /// Flight logging keys.
    enum LoggingKeys: String {
        case timestamp = "timestamp"
        case longitude = "gps_lon"
        case latitude = "gps_lat"
        case altitude = "gps_altitude"
        case altitudeAmsl = "gps_amsl_altitude"
        case speedVx = "speed_vx"
        case speedVy = "speed_vy"
        case speedVz = "speed_vz"
        case batteryVoltage = "battery_voltage"
        case batteryCurrent = "battery_current"
        case batteryCapacity = "battery_capacity"
        case batteryPercent = "battery_percent"
        case batteryCellVoltage0 = "battery_cell_voltage_0"
        case batteryCellVoltage1 = "battery_cell_voltage_1"
        case batteryCellVoltage2 = "battery_cell_voltage_2"
        case wifiSignal = "wifi_signal"
        case productGpsAvailable = "product_gps_available"
        case productGpsSvNumber = "product_gps_sv_number"
        case anglePhi = "angle_phi"
        case anglePsi = "angle_psi"
        case angleTheta = "angle_theta"
    }

    /// Extracts the item value of Gutma.FlightLogging.Item, contained in the receiver, for a given
    /// key at a given index.
    ///
    /// - Parameters:
    ///     - key: flightLoggingKeys
    ///     - index: flightLoggingItems index
    func itemValue(forKey key: LoggingKeys, at index: Int) -> Double? {
        guard let items = flightLoggingItems else { return nil }
        return itemValue(ofItems: items, at: index, forKey: key)
    }

    /// Extracts the item value of Gutma.FlightLogging.Item, from a given array of items, for a
    /// given key, at a given index.
    ///
    /// - Parameters:
    ///     - items: the flight logging items
    ///     - index: the index in items
    ///     - key: the key flight logging key
    /// - Returns: the value associated to key at index of items or `nil` if the index is out of
    /// range or the key is not present.
    func itemValue(ofItems items: [PictorGutma.FlightLogging.Item],
                   at index: Int,
                   forKey key: LoggingKeys) -> Double? {
        if items.startIndex <= index, index < items.endIndex,
           let valueIndex = valueIndex(forKey: key) {
            let item = items[index]
            return item[valueIndex]
        }
        return nil
    }

    /// Returns value index for the corresponding key.
    ///
    /// - Parameter key: The flight logging key
    func valueIndex(forKey key: LoggingKeys) -> Int? {
        return flightLoggingKeys?.firstIndex(of: key.rawValue)
    }

    func items(startingFrom timestamp: TimeInterval) -> [PictorGutma.FlightLogging.Item] {
        guard let items = flightLoggingItems,
              let timestampindex = valueIndex(forKey: .timestamp)
        else { return [] }
        return items.filter { $0[timestampindex] >= timestamp }
    }

    /// Extracts location regarding flight logging index
    ///
    /// - Parameters:
    ///     - index: FlightLogging index
    /// - Returns: location in the receiver at the given index
    func location(at index: Int) -> CLLocationCoordinate2D? {
        guard let items = flightLoggingItems else { return nil }
        return location(ofItems: items, at: index)
    }

    /// Extracts location of items at a given index.
    ///
    /// - Parameters:
    ///   - items: the flight logging items
    ///   - index: the index in items
    /// - Returns: the location at a given index as CLLocationCoordinate2D
    func location(ofItems items: [PictorGutma.FlightLogging.Item], at index: Int) -> CLLocationCoordinate2D? {
        guard let longitude = itemValue(ofItems: items, at: index, forKey: .longitude),
              let latitude = itemValue(ofItems: items, at: index, forKey: .latitude),
              (latitude != 0.0 || longitude != 0.0) else {
            return nil
        }
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        return coordinate.isValid ? coordinate : nil
    }

    /// Take off time based on take off event.
    var takeOffTimestamp: TimeInterval? {
        // Sometimes, the take off event doesn't present in gutma file, in that case, return the first timestamp.
        let takeOff = events?.first(where: { $0.eventInfo == GutmaConstants.eventStepTakeOff })
        let first = itemValue(forKey: .timestamp, at: flightLoggingItems?.startIndex ?? 0)
        return TimeInterval(takeOff?.eventTimestamp ?? "") ?? first
    }

    /// Flight time based on flight date event.
    var flightDateTimestamp: TimeInterval? {
        let flightDate = events?.first(where: { $0.eventInfo == GutmaConstants.eventStepFlightDate })
        return TimeInterval(flightDate?.eventTimestamp ?? "")
    }

    /// Flight duration.
    var duration: TimeInterval? {
        guard let takeOffTimestamp = takeOffTimestamp,
              let last = itemValue(forKey: .timestamp, at: (flightLoggingItems?.endIndex ?? 1) - 1) else {
            return nil
        }
        return last - takeOffTimestamp
    }

    /// Flight battery consumption.
    var batteryConsumption: Double? {
        guard let takeOffTimestamp = takeOffTimestamp else { return nil }
        let items = items(startingFrom: takeOffTimestamp)
        return calculateBatteryConsumption(ofItems: items)
    }

    /// Returns start position
    var startPosition: CLLocation? {
        guard let takeOffTimestamp = takeOffTimestamp else { return nil }
        let items = items(startingFrom: takeOffTimestamp)
        guard let index = (items.startIndex..<items.endIndex).firstIndex(where: { index in
            location(ofItems: items, at: index)?.isValid ?? false
        }),
              let location = location(ofItems: items, at: index)
        else { return nil }
        return CLLocation(latitude: location.latitude, longitude: location.longitude)
    }

    /// Add distance between all points.
    var distance: Double? {
        guard let takeOffTimestamp = takeOffTimestamp else { return nil }
        let items = items(startingFrom: takeOffTimestamp)
        return calculateDistance(ofItems: items)
    }

    /// Calculates the battery consumption of the given items.
    ///
    /// - Parameter items: the filght logging items.
    /// - Returns: the total distance in the given items
    func calculateDistance(ofItems items: [PictorGutma.FlightLogging.Item]) -> Double {
        var previousLocation: CLLocation?
        return (items.startIndex..<items.endIndex).reduce(0.0) { computedDistance, index in
            let prvLocation = previousLocation
            if let loc = location(ofItems: items, at: index) {
                let location = CLLocation(latitude: loc.latitude, longitude: loc.longitude)
                previousLocation = location
                return computedDistance + (prvLocation?.distance(from: location) ?? 0)
            }
            return computedDistance
        }
    }

    /// Calculates the battery consumption of the given items.
    ///
    /// - Parameter items: the filght logging items.
    /// - Returns: the total battery consumption in the given items
    func calculateBatteryConsumption(ofItems items: [PictorGutma.FlightLogging.Item]) -> Double {
        guard let batteryPercentIndex = valueIndex(forKey: .batteryPercent) else {
            return 0
        }
        // Find real battery value (0 is not a real one for an initial value).
        let initialBatteryValue = items.first { item in
            item[batteryPercentIndex] > 0.0
        }?[batteryPercentIndex] ?? 1.0
        let finalBatteryValue = itemValue(ofItems: items, at: items.endIndex - 1, forKey: .batteryPercent) ?? 0.0
        return ceil(initialBatteryValue - finalBatteryValue)
    }
}
