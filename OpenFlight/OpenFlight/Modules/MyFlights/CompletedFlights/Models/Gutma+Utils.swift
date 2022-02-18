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
import CoreLocation
import ArcGIS
import GroundSdk

// MARK: - Internal Enums
enum GutmaConstants {
    static let dateFormatLogging: String = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
    static let dateFormatFile: String = "yyyy-MM-dd'T'HH:mm:ssZ"
    static let extensionName: String = "gutma"
    static let unknownCoordinate: Double = 500
    static let firstVesionWithAsml: String = "1.0.1"
    static let eventInfoFlightPlan: String = "FLIGHTPLAN"
    static let eventTypeFlightPlan: String = "CONTROLLER_FLIGHTPLAN"
    static let eventStepMissionItem: String = "MISSION_ITEM"
    static let eventStepStart: String = "START"
    static let eventStepPause: String = "PAUSE"
    static let eventStepResume: String = "RESUME"
    static let eventStepStop: String = "STOP"
    static let eventInfoPhoto = "PHOTO"
    static let eventInfoVideo = "VIDEO"
    static let eventMediaTypeSaved = "saved"
    static let eventMediaTypeStarted = "start"
}

// MARK: - Gutma helpers.

extension Gutma {

    public struct Model {
        public let flight: FlightModel
        public let flightPlanFlights: [FlightPlanFlightsModel]
    }

    var startDate: Date? {
        if let dateString = exchange?.message?.flightLogging?.loggingStartDtg {
            let formatter = DateFormatter()
            formatter.dateFormat = GutmaConstants.dateFormatFile
            return formatter.date(from: dateString)
        }
        return nil
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

    /// Extracts trajectory points.
    ///
    /// - Parameters:
    ///   - startTime: minimal timestamp of trajectory points to include, if not `nil`
    ///   - endTime: maximal timestamp of trajectory points to include, if not `nil`
    /// - Returns: trajectory points in the time range provided
    func points(startTime: Double? = nil, endTime: Double? = nil) -> [TrajectoryPoint] {
        exchange?.message?.flightLogging?.points(startTime: startTime, endTime: endTime) ?? []
    }

    /// Extracts flight plan execution points.
    ///
    /// - Parameters:
    ///   - flightPlan: the flight plan
    /// - Returns: trajectory points for the given execution.
    func flightPlanPoints(_ flightPlan: FlightPlanModel) -> [TrajectoryPoint] {
        exchange?.message?.flightLogging?.flightPlanPoints(flightPlan) ?? []
    }

    /// Whether file contains point with altitudes in ASML coordinates.
    var hasAsmlAltitude: Bool {
        // compare file version with first version containing ASML altitudes
        if let parrotVersion = exchange?.message?.file?.parrotVersion,
           let version = FirmwareVersion.parse(versionStr: parrotVersion),
           let firstVesionWithAsml = FirmwareVersion.parse(versionStr: GutmaConstants.firstVesionWithAsml) {
            return !(version < firstVesionWithAsml)
        }
        return false
    }

    var photoCount: Int { exchange?.message?.flightLogging?.events?.filter { $0.eventInfo == GutmaConstants.eventInfoPhoto }.count ?? 0 }

    var videoCount: Int {
        guard let videoEvents = exchange?.message?.flightLogging?.events?.filter({ $0.eventInfo == GutmaConstants.eventInfoVideo }),
              !videoEvents.isEmpty else {
                  return 0
              }
        var videosAffectingFlight = 0
        var videoSavePending = false
        for videoEvent in videoEvents {
            switch videoEvent.mediaEvent {
            case GutmaConstants.eventMediaTypeStarted:
                videoSavePending = true
                videosAffectingFlight += 1
            case GutmaConstants.eventMediaTypeSaved:
                if videoSavePending {
                    // already counted this video in "start" event
                    videoSavePending = false
                    continue
                }
                videosAffectingFlight += 1
            default:
                continue
            }
        }
        return videosAffectingFlight
    }

    func flightPlanExecutions(apcId: String, flightUuid: String) -> [FlightPlanFlightsModel] {
        guard let startDate = startDate else { return [] }
        let fpfs: [FlightPlanFlightsModel] = exchange?.message?.flightLogging?.events?
            .compactMap {
                if $0.eventInfo == GutmaConstants.eventInfoFlightPlan,
                   $0.eventType == GutmaConstants.eventTypeFlightPlan,
                   $0.step == GutmaConstants.eventStepMissionItem,
                   let flightPlanUuid = $0.customId,
                   let timestampString = $0.eventTimestamp,
                   let timestamp = Double(timestampString) {
                    let dateExecutionFlight = startDate.addingTimeInterval(timestamp)
                    return FlightPlanFlightsModel(apcId: apcId,
                                                  flightplanUuid: flightPlanUuid,
                                                  flightUuid: flightUuid,
                                                  dateExecutionFlight: dateExecutionFlight)
                }
                return nil
            } ?? []
        // Keep only one FPF by flightPlan (the earliest)
        let dict = Dictionary(fpfs.map { ($0.flightplanUuid, $0) },
                              uniquingKeysWith: { $0.dateExecutionFlight < $1.dateExecutionFlight ? $0 : $1 })
        return Array(dict.values)
    }

    public func toFlight(apcId: String, gutmaFile: Data) -> Model? {
        guard let uuid = flightId else {
            return nil
        }
        guard let parrotVersion = file?.parrotVersion else { return nil }
        let startPosition = exchange?.message?.flightLogging?.startPosition
        let flight = FlightModel(apcId: apcId,
                                 uuid: uuid,
                                 version: parrotVersion,
                                 startTime: startDate,
                                 photoCount: Int16(photoCount),
                                 videoCount: Int16(videoCount),
                                 startLatitude: startPosition?.coordinate.latitude ?? 0,
                                 startLongitude: startPosition?.coordinate.longitude ?? 0,
                                 batteryConsumption: Int16(batteryConsumption ?? 0),
                                 distance: distance,
                                 duration: duration,
                                 gutmaFile: gutmaFile)
        return Model(flight: flight, flightPlanFlights: flightPlanExecutions(apcId: apcId, flightUuid: uuid))
    }

    public func update(flight: inout FlightModel) {
        guard let parrotVersion = file?.parrotVersion else { return }
        flight.version = parrotVersion
        let startPosition = exchange?.message?.flightLogging?.startPosition
        flight.photoCount = Int16(photoCount)
        flight.videoCount = Int16(videoCount)
        flight.startLatitude = startPosition?.coordinate.latitude ?? 0
        flight.startLongitude = startPosition?.coordinate.longitude ?? 0
        flight.startTime = startDate
        flight.batteryConsumption = Int16(batteryConsumption ?? 0)
        flight.distance = distance
        flight.duration = duration
    }

    /// Extracts timestamps indicating flight plan (execution) starts.
    ///
    /// There maybe multiple starts for an FP execution (same uuid).
    ///
    /// - Parameters:
    ///   - flightPlan: the flight plan
    /// - Returns: flight plan start timestamps if found, or empty array if no event related to this
    /// executions is found.
    func flightPlanStartTimestamps(_ flightPlan: FlightPlanModel) -> [Double] {
        exchange?.message?.flightLogging?.flightPlanStartTimestamps(flightPlan) ?? []
    }

    /// Extracts timestamp of events indicating flight plan ends.
    /// There maybe multiple end for an FP execution (same uuid).
    ///
    /// - Parameters:
    ///   - flightPlan: the flight plan
    /// - Returns: flight plan end timestamps if found, or empty array if not found.
    func flightPlanEndTimestamps(_ flightPlan: FlightPlanModel) -> [Double] {
        exchange?.message?.flightLogging?.flightPlanEndTimestamps(flightPlan) ?? []
    }

    /// Calculates the duration of an FP execution with a given uuid.
    ///
    /// - Parameters:
    ///   - flightPlan: the flight plan
    /// - Returns: the duration for the given execution if found in the receiver, `nil` otherwise.
    func flightPlanDuration(_ flightPlan: FlightPlanModel) -> TimeInterval? {
        exchange?.message?.flightLogging?.flightPlanDuration(flightPlan)
    }

    /// Calculates the battery of an FP execution with a given uuid.
    ///
    /// - Parameters:
    ///   - flightPlan: the flight plan
    /// - Returns: the total battery consumption for the given execution if found in the receiver,
    /// `nil` otherwise.
    func flightPlanBatteryConsumption(_ flightPlan: FlightPlanModel) -> Double? {
        exchange?.message?.flightLogging?.flightPlanBatteryConsumption(flightPlan)
    }

    /// Calculates the total distance of an FP execution with a given uuid.
    ///
    /// - Parameters:
    ///   - flightPlan: the flight plan
    /// - Returns: the total distance for the given execution if found in the receiver,
    /// `nil` otherwise.
    func flightPlanDistance(_ flightPlan: FlightPlanModel) -> Double? {
        exchange?.message?.flightLogging?.flightPlanDistance(flightPlan)
    }
}

// MARK: - FlightLogging private helpers.

private extension Gutma.FlightLogging {
    /// Start flight date.
    var startDate: Date? {
        guard let dateString = loggingStartDtg else {
            return nil
        }
        return Gutma.FlightLogging.formatter.date(from: dateString)
    }

    /// Flight duration.
    var duration: TimeInterval? {
        guard let first = itemValue(forKey: .timestamp, at: flightLoggingItems?.startIndex ?? 0),
              let last = itemValue(forKey: .timestamp, at: (flightLoggingItems?.endIndex ?? 1) - 1) else {
                  return nil
              }
        return last - first
    }

    /// Flight battery consumption.
    var batteryConsumption: Double? {
        guard let items = flightLoggingItems else {
            return nil
        }
        return calculateBatteryConsumption(ofItems: items)
    }

    /// Returns start position
    var startPosition: CLLocation? {
        guard let items = flightLoggingItems,
              let index = (items.startIndex..<items.endIndex).firstIndex(where: { index in
                  location(ofItems: items, at: index)?.isValid ?? false
              }),
              let location = location(ofItems: items, at: index) else {
                  return nil
              }
        return CLLocation(latitude: location.latitude, longitude: location.longitude)
    }

    /// Extracts flight plan execution points.
    ///
    /// - Parameters:
    ///   - flightPlan: the flight plan
    /// - Returns: trajectory points for the given execution.
    func flightPlanPoints(_ flightPlan: FlightPlanModel) -> [TrajectoryPoint] {
        // start times of trajectory to draw
        let starts = flightPlanStartTimestamps(flightPlan)
        // end times of trajectory to draw
        let ends = flightPlanEndTimestamps(flightPlan)
        return zip(starts, ends).flatMap { (start, end) in
            points(startTime: start, endTime: end)
        }
    }

    /// Extracts trajectory points.
    ///
    /// - Parameters:
    ///   - startTime: minimal timestamp of trajectory points to include, if not `nil`
    ///   - endTime: maximal timestamp of trajectory points to include, if not `nil`
    /// - Returns: trajectory points in the given time range
    func points(startTime: Double?, endTime: Double?) -> [TrajectoryPoint] {
        guard let items = flightLoggingItems,
              let timestampIndex = valueIndex(forKey: .timestamp) else {
                  return []
              }
        let subItems = items.filter { item in
            startTime.map { $0 <= item[timestampIndex] } ?? true
            && endTime.map { item[timestampIndex] <= $0 } ?? true
        }
        return (subItems.startIndex..<subItems.endIndex).compactMap { index -> TrajectoryPoint? in
            agsPoint(ofItems: subItems, at: index).map { point in
                TrajectoryPoint(point: point, isFirstPoint: (startTime == nil && endTime == nil && index == subItems.startIndex))
            }
        }
    }

    /// Add distance between all points.
    var distance: Double {
        guard let items = flightLoggingItems else {
            return 0
        }
        return calculateDistance(ofItems: items)
    }

    /// Filter an FP event bassed on a uuid and a step.
    ///
    /// - Parameters:
    ///   - event: the Gutma event
    ///   - uuid: the flight plan execution uuid to filter with
    ///   - steps: the steps to consider
    /// - Returns: Whether the `event` satisfying the given criteria
    func filter(event: Gutma.Event, uuid: String, steps: [String]) -> Bool {
        event.eventInfo == GutmaConstants.eventInfoFlightPlan
        && event.eventType == GutmaConstants.eventTypeFlightPlan
        && event.customId == uuid
        && event.step.map { steps.contains($0) } ?? false
    }

    /// Subexecution parse state machine
    enum ExecutionParseStateMachine {
        /// Uninitialized state.
        case notStarted
        /// Started state. A start/resume or a WP mission item was found.
        ///
        /// - Parameter atIndex: The index at which starts the subexecution.
        case started(atIndex: Array<Gutma.Event>.Index)
        ///
        ///
        case stopped(atIndex: Array<Gutma.Event>.Index, startedAtIndex: Array<Gutma.Event>.Index)

        /// Constructs the state machine in an uninitialized state.
        init() {
            self = .notStarted
        }

        /// Resets the state machine
        mutating func reset() {
            self = .notStarted
        }

        /// Transitions the state machine to the started state.
        ///
        /// - Parameter atIndex: The index at which starts the subexecution.
        mutating func start(atIndex index: Array<Gutma.Event>.Index) {
            self = .started(atIndex: index)
        }

        /// Transitions the state machine to the stopped state, if possible.
        ///
        /// It is only possible to transition to the stopped state only if the state machine is in
        /// the started state.
        ///
        /// - Parameter atIndex: The index at which stops the subexecution.
        mutating func stop(atIndex index: Array<Gutma.Event>.Index) {
            switch self {
            case let .started(atIndex: startIndex):
                self = .stopped(atIndex: index, startedAtIndex: startIndex)
            default:
                break
            }
        }

        /// Whether the state machine has started, i.e. is not in an uninitialized state.
        var isInitialized: Bool {
            switch self {
            case .started, .stopped:
                return true
            default:
                return false
            }
        }
    }

    /// Extracts all Gutma events related to a flight plan execution.
    ///
    /// A flight plan execution can contain multiple subexecutions (either completed or partial) in
    /// the same Gutma file.
    ///
    /// - Parameters:
    ///   - flightPlan: the flight plan
    /// - Returns: A list of subexecutions. A subexecution is considered an array of Gutma events.
    func flightPlanSubexecutionsEvents(_ flightPlan: FlightPlanModel) -> [[Gutma.Event]] {
        guard let events = events,
              let mavlinkCommands = flightPlan.dataSetting?.mavlinkCommands,
              let firstWPIndex = mavlinkCommands.firstIndex(where: { $0 is MavlinkStandard.NavigateToWaypointCommand }),
              let lastWPIndex = mavlinkCommands.lastIndex(where: { $0 is MavlinkStandard.NavigateToWaypointCommand })
        else {
            return []
        }

        // The array of (startIndex,endIndex) tuples. Each tuple describes a range of indices in
        // `events` that makes a subexecution.
        var subexecutionIndices = [(start: Array<Gutma.Event>.Index, end: Array<Gutma.Event>.Index)]()
        var state = ExecutionParseStateMachine()
        for (index, event) in zip(events.indices, events) {
            // filter unrelated events to execution
            guard filter(event: event, uuid: flightPlan.uuid, steps: [GutmaConstants.eventStepStart,
                                                                      GutmaConstants.eventStepResume,
                                                                      GutmaConstants.eventStepPause,
                                                                      GutmaConstants.eventStepStop,
                                                                      GutmaConstants.eventStepMissionItem]) else {
                continue
            }

            // if the event is a mission item corresponding to a WP and we have not already
            // initialized the state machine, then we can consider this the start of the
            // subexecution
            if (event.step == GutmaConstants.eventStepMissionItem
                && event.missionItem
                    .flatMap(Int.init)
                    .map({ mavlinkCommands[$0] is MavlinkStandard.NavigateToWaypointCommand }) ?? false),
               !state.isInitialized {
                state.start(atIndex: index)
            }

            // reaching an ending step like pause or stop
            if event.isEndingStep {
                switch state {
                case .notStarted:
                    // do nothing. can't consider subexecution
                    break
                case let .started(atIndex: startIndex):
                    // if already started, then treat the current index as a stop
                    subexecutionIndices.append((startIndex, index))
                    state.reset()

                case let .stopped(atIndex: stoppedIndex, startedAtIndex: startIndex):
                    // if already stopped (with a last WP), then consider `stoppedIndex` as stop
                    // and not the current index
                    subexecutionIndices.append((startIndex, stoppedIndex))
                    state.reset()
                }
                continue
            }

            if event.step == GutmaConstants.eventStepMissionItem {
                if event.missionItem.map({ Int($0) }) == firstWPIndex {
                    // override with first WP index
                    state.start(atIndex: index)
                }
                if event.missionItem.map({ Int($0) }) == lastWPIndex {
                    // when finding a last WP index mark as the end of the subexecution
                    state.stop(atIndex: index)
                }
            }
        }
        return subexecutionIndices.map { tuple in
            Array(events[tuple.start...tuple.end])
        }
    }

    /// Extracts all 'start' events timestamps related to a flight plan execution.
    ///
    /// - Parameters:
    ///   - flightPlan: the flight plan
    /// - Returns: A list of all starting timestamps of all sub-executions of the given flight plan.
    func flightPlanStartTimestamps(_ flightPlan: FlightPlanModel) -> [Double] {
        return flightPlanSubexecutionsEvents(flightPlan).compactMap { subexecutionEvents in
            subexecutionEvents.first?.eventTimestamp
        }.compactMap { Double($0) }
    }

    /// Extracts all 'end' events timestamps related to a flight plan execution.
    ///
    /// - Parameters:
    ///   - flightPlan: the flight plan
    /// - Returns: A list of all ending timestamps of all sub-executions of the given flight plan.
    func flightPlanEndTimestamps(_ flightPlan: FlightPlanModel) -> [Double] {
        flightPlanSubexecutionsEvents(flightPlan).compactMap { subexecutionEvents in
            subexecutionEvents.last?.eventTimestamp
        }.compactMap { Double($0) }
    }

    /// Calculates the duration of an FP execution with a given uuid.
    ///
    /// - Parameters:
    ///   - flightPlan: the flight plan
    /// - Returns: the duration for the given execution if found in the receiver, `nil` otherwise.
    func flightPlanDuration(_ flightPlan: FlightPlanModel) -> TimeInterval? {
        let starts = flightPlanStartTimestamps(flightPlan)
        let ends = flightPlanEndTimestamps(flightPlan)
        guard !starts.isEmpty, !ends.isEmpty, starts.count == ends.count else {
            return nil
        }
        return zip(ends, starts).reduce(TimeInterval(0), { sum, pair in
            sum + TimeInterval(pair.0 - pair.1)
        })
    }

    /// Calculates the battery of an FP execution with a given uuid.
    ///
    /// - Parameters:
    ///   - flightPlan: the flight plan
    /// - Returns: the total battery consumption for the given execution if found in the receiver,
    /// `nil` otherwise.
    func flightPlanBatteryConsumption(_ flightPlan: FlightPlanModel) -> Double? {
        let starts = flightPlanStartTimestamps(flightPlan)
        let ends = flightPlanEndTimestamps(flightPlan)
        guard !starts.isEmpty, !ends.isEmpty, starts.count == ends.count else {
            return nil
        }
        return zip(starts, ends).reduce(TimeInterval(0), { sum, pair in
            let items = itemsInTimestampRange(start: pair.0, end: pair.1)
            return sum + calculateBatteryConsumption(ofItems: items)
        })
    }

    /// Calculates the total distance of an FP execution with a given uuid.
    ///
    /// - Parameters
    ///   - flightPlan: the flight plan
    /// - Returns: the total distance for the given execution if found in the receiver,
    /// `nil` otherwise.
    func flightPlanDistance(_ flightPlan: FlightPlanModel) -> Double? {
        let starts = flightPlanStartTimestamps(flightPlan)
        let ends = flightPlanEndTimestamps(flightPlan)
        guard !starts.isEmpty, !ends.isEmpty, starts.count == ends.count else {
            return nil
        }
        return zip(starts, ends).reduce(TimeInterval(0), { sum, pair in
            let items = itemsInTimestampRange(start: pair.0, end: pair.1)
            return sum + calculateDistance(ofItems: items)
        })
    }
}

// MARK: - Private items helpers

private extension Gutma.FlightLogging {
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
    func location(ofItems items: [Gutma.FlightLogging.Item], at index: Int) -> CLLocationCoordinate2D? {
        let longitude = itemValue(ofItems: items, at: index, forKey: .longitude) ?? 0.0
        let latitude = itemValue(ofItems: items, at: index, forKey: .latitude) ?? 0.0
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        return coordinate.isValid ? coordinate : nil
    }

    /// Extracts coordinates of a trajectory points.
    ///
    /// - Parameters:
    ///   - items: the filght logging items
    ///   - index: the index in items
    /// - Returns: trajectory point coordinates if found and within given timestamp bounds, `nil` otherwise
    func agsPoint(ofItems items: [Gutma.FlightLogging.Item], at index: Int) -> AGSPoint? {
        guard let latitude =  itemValue(ofItems: items, at: index, forKey: .latitude),
              let longitude = itemValue(ofItems: items, at: index, forKey: .longitude),
              latitude != GutmaConstants.unknownCoordinate,
              longitude != GutmaConstants.unknownCoordinate else {
                  return nil
              }
        let altitude = itemValue(ofItems: items, at: index, forKey: .altitudeAmsl)
        ?? itemValue(ofItems: items, at: index, forKey: .altitude)
        ?? 0.0
        return AGSPoint(x: longitude,
                        y: latitude,
                        z: altitude,
                        spatialReference: AGSSpatialReference.wgs84())
    }

    /// Calculates the battery consumption of the given items.
    ///
    /// - Parameter items: the filght logging items.
    /// - Returns: the total battery consumption in the given items
    func calculateBatteryConsumption(ofItems items: [Gutma.FlightLogging.Item]) -> Double {
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

    /// Calculates the battery consumption of the given items.
    ///
    /// - Parameter items: the filght logging items.
    /// - Returns: the total distance in the given items
    func calculateDistance(ofItems items: [Gutma.FlightLogging.Item]) -> Double {
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
    func itemsInTimestampRange(start: Double, end: Double) -> [Gutma.FlightLogging.Item] {
        guard let items = flightLoggingItems,
              let timestampIndex = valueIndex(forKey: .timestamp),
              let firstItemIndex = items.firstIndex(where: { item in item[timestampIndex] >= start }),
              let lastItemIndex = items.firstIndex(where: { item in item[timestampIndex] >= end }) else {
                  return []
              }
        let itemsOfTimestampRange = items[firstItemIndex..<lastItemIndex]
        return Array(itemsOfTimestampRange)
    }

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
    func itemValue(ofItems items: [Gutma.FlightLogging.Item],
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
}

extension Gutma.Event {
    var isEndingStep: Bool {
        step == GutmaConstants.eventStepPause || step == GutmaConstants.eventStepStop
    }

    var isStartingStep: Bool {
        step == GutmaConstants.eventStepStart || step == GutmaConstants.eventStepResume
    }
}
