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
    static let firstVesionWithAmsl: String = "1.0.1"
    static let eventInfoFlightPlan: String = "FLIGHTPLAN"
    static let eventTypeFlightPlan: String = "CONTROLLER_FLIGHTPLAN"
    static let eventStepMissionItem: String = "MISSION_ITEM"
    static let eventStepTakeOff: String = "TOF"
    static let eventStepFlightDate: String = "FLIGHTDATE"
    static let eventStepStart: String = "START"
    static let eventStepPause: String = "PAUSE"
    static let eventStepResume: String = "RESUME"
    static let eventStepStop: String = "STOP"
    static let eventStepPathStop: String = "PATH_STOP"
    static let eventInfoPhoto = "PHOTO"
    static let eventInfoVideo = "VIDEO"
    static let eventMediaTypeSaved = "saved"
    static let eventMediaTypeStarted = "start"
    static let eventMediaTypeTaken = "taken"
    static let eventMediaTypeDeleted = "deleted"
}

// MARK: - Gutma helpers.

extension Gutma {

    public struct Model {
        public let flight: FlightModel
        public let flightPlanFlights: [FlightPlanFlightsModel]
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
    ///   - mavlinkCommands: the flight plan's mavlink commands
    /// - Returns: trajectory points for the given execution.
    func flightPlanPoints(_ flightPlan: FlightPlanModel, mavlinkCommands: [MavlinkStandard.MavlinkCommand]?) -> [TrajectoryPoint] {
        exchange?.message?.flightLogging?.flightPlanPoints(flightPlan, mavlinkCommands: mavlinkCommands) ?? []
    }

    /// Whether file contains point with altitudes in AMSL coordinates.
    var hasAmslAltitude: Bool {
        // compare file version with first version containing AMSL altitudes
        if let parrotVersion = exchange?.message?.file?.parrotVersion,
           let version = FirmwareVersion.parse(versionStr: parrotVersion),
           let firstVesionWithAmsl = FirmwareVersion.parse(versionStr: GutmaConstants.firstVesionWithAmsl) {
            return !(version < firstVesionWithAmsl)
        }
        return false
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
    ///   - mavlinkCommands: the flight plan's mavlink commands
    /// - Returns: flight plan start timestamps if found, or empty array if no event related to this
    /// executions is found.
    func flightPlanStartTimestamps(_ flightPlan: FlightPlanModel, mavlinkCommands: [MavlinkStandard.MavlinkCommand]?) -> [Double] {
        exchange?.message?.flightLogging?.flightPlanStartTimestamps(flightPlan, mavlinkCommands: mavlinkCommands) ?? []
    }

    /// Extracts timestamp of events indicating flight plan ends.
    /// There maybe multiple end for an FP execution (same uuid).
    ///
    /// - Parameters:
    ///   - flightPlan: the flight plan
    ///   - mavlinkCommands: the flight plan's mavlink commands
    /// - Returns: flight plan end timestamps if found, or empty array if not found.
    func flightPlanEndTimestamps(_ flightPlan: FlightPlanModel, mavlinkCommands: [MavlinkStandard.MavlinkCommand]?) -> [Double] {
        exchange?.message?.flightLogging?.flightPlanEndTimestamps(flightPlan, mavlinkCommands: mavlinkCommands) ?? []
    }

    /// Calculates the duration of an FP execution with a given uuid.
    ///
    /// - Parameters:
    ///   - flightPlan: the flight plan
    ///   - mavlinkCommands: the flight plan's mavlink commands
    /// - Returns: the duration for the given execution if found in the receiver, `nil` otherwise.
    func flightPlanDuration(_ flightPlan: FlightPlanModel, mavlinkCommands: [MavlinkStandard.MavlinkCommand]?) -> TimeInterval? {
        exchange?.message?.flightLogging?.flightPlanDuration(flightPlan, mavlinkCommands: mavlinkCommands)
    }

    /// Calculates the battery of an FP execution with a given uuid.
    ///
    /// - Parameters:
    ///   - flightPlan: the flight plan
    ///   - mavlinkCommands: the flight plan's mavlink commands
    /// - Returns: the total battery consumption for the given execution if found in the receiver,
    /// `nil` otherwise.
    func flightPlanBatteryConsumption(_ flightPlan: FlightPlanModel, mavlinkCommands: [MavlinkStandard.MavlinkCommand]?) -> Double? {
        exchange?.message?.flightLogging?.flightPlanBatteryConsumption(flightPlan, mavlinkCommands: mavlinkCommands)
    }

    /// Calculates the total distance of an FP execution with a given uuid.
    ///
    /// - Parameters:
    ///   - flightPlan: the flight plan
    ///   - mavlinkCommands: the flight plan's mavlink commands
    /// - Returns: the total distance for the given execution if found in the receiver,
    /// `nil` otherwise.
    func flightPlanDistance(_ flightPlan: FlightPlanModel, mavlinkCommands: [MavlinkStandard.MavlinkCommand]?) -> Double? {
        exchange?.message?.flightLogging?.flightPlanDistance(flightPlan, mavlinkCommands: mavlinkCommands)
    }

    /// Calculates the number of photos taken during a FP execution.
    ///
    /// - Parameters:
    ///   - flightPlan: the flight plan
    ///   - mavlinkCommands: the flight plan's mavlink commands
    /// - Returns: the total number of photos,
    /// `nil` otherwise.
    func flightPlanPhotoCount(_ flightPlan: FlightPlanModel, mavlinkCommands: [MavlinkStandard.MavlinkCommand]?) -> Int? {
        exchange?.message?.flightLogging?.flightPlanPhotoCount(flightPlan, mavlinkCommands: mavlinkCommands)
    }

    /// Calculates the number of videos taken during a FP execution.
    ///
    /// - Parameters:
    ///   - flightPlan: the flight plan
    ///   - mavlinkCommands: the flight plan's mavlink commands
    /// - Returns: the total number of videos,
    /// `nil` otherwise.
    func flightPlanVideoCount(_ flightPlan: FlightPlanModel, mavlinkCommands: [MavlinkStandard.MavlinkCommand]?) -> Int? {
        exchange?.message?.flightLogging?.flightPlanVideoCount(flightPlan, mavlinkCommands: mavlinkCommands)
    }
}

// MARK: - FlightLogging private helpers.

private extension Gutma.FlightLogging {
    /// Take off time.
    var takeOffTimestamp: TimeInterval {
        let takeOff = events?.first(where: { $0.eventInfo == GutmaConstants.eventStepTakeOff })
        return TimeInterval(takeOff?.eventTimestamp ?? "") ?? 0
    }

    /// Flight time based on flight date event.
    var flightDateTimestamp: TimeInterval? {
        let flightDate = events?.first(where: { $0.eventInfo == GutmaConstants.eventStepFlightDate })
        return TimeInterval(flightDate?.eventTimestamp ?? "")
    }

    /// Flight duration.
    var duration: TimeInterval? {
        guard let first = itemValue(forKey: .timestamp, at: flightLoggingItems?.startIndex ?? 0),
              let last = itemValue(forKey: .timestamp, at: (flightLoggingItems?.endIndex ?? 1) - 1) else {
            return nil
        }
        return last - first - takeOffTimestamp
    }

    /// Flight battery consumption.
    var batteryConsumption: Double? {
        let items = items(startingFrom: takeOffTimestamp)
        return calculateBatteryConsumption(ofItems: items)
    }

    /// Returns start position
    var startPosition: CLLocation? {
        let items = items(startingFrom: takeOffTimestamp)
        guard let index = (items.startIndex..<items.endIndex).firstIndex(where: { index in
            location(ofItems: items, at: index)?.isValid ?? false
        }),
              let location = location(ofItems: items, at: index)
        else { return nil }
        return CLLocation(latitude: location.latitude, longitude: location.longitude)
    }

    /// Extracts flight plan execution points.
    ///
    /// - Parameters:
    ///   - flightPlan: the flight plan
    ///   - mavlinkCommands: the flight plan's mavlink commands
    /// - Returns: trajectory points for the given execution.
    func flightPlanPoints(_ flightPlan: FlightPlanModel, mavlinkCommands: [MavlinkStandard.MavlinkCommand]?) -> [TrajectoryPoint] {
        // start times of trajectory to draw
        let starts = flightPlanStartTimestamps(flightPlan, mavlinkCommands: mavlinkCommands)
        // end times of trajectory to draw
        let ends = flightPlanEndTimestamps(flightPlan, mavlinkCommands: mavlinkCommands)
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
        let items = items(startingFrom: takeOffTimestamp)
        guard let timestampIndex = valueIndex(forKey: .timestamp) else { return [] }

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
        let items = items(startingFrom: takeOffTimestamp)
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

        /// Stopped state. A stop was found.
        ///
        /// - Parameters:
        ///  - atIndex: The index where the subexecution stopped.
        ///  - startedAtIndex:The index where the subexecution started.
        case stopped(atIndex: Array<Gutma.Event>.Index, startedAtIndex: Array<Gutma.Event>.Index)

        /// Paused state. A pause was found.
        ///
        /// - Parameters:
        ///  - atIndex: The index where the subexecution paused.
        ///  - startedAtIndex:The index where the subexecution started.
        case paused(atIndex: Array<Gutma.Event>.Index, startedAtIndex: Array<Gutma.Event>.Index)

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

        /// Transitions the state machine to the paused state, if possible.
        ///
        /// It is possible to transition to the paused state only if the state machine is in
        /// the started state.
        ///
        /// - Parameter atIndex: The index at which stops the subexecution.
        mutating func pause(atIndex index: Array<Gutma.Event>.Index) {
            switch self {
            case let .started(atIndex: startIndex):
                self = .paused(atIndex: index, startedAtIndex: startIndex)
            default:
                break
            }
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
            case .started, .paused, .stopped:
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
    ///   - mavlinkCommands: the flight plan's mavlink commands
    /// - Returns: A list of subexecutions. A subexecution is considered an array of Gutma events.
    func flightPlanSubexecutionsEvents(_ flightPlan: FlightPlanModel, mavlinkCommands: [MavlinkStandard.MavlinkCommand]?) -> [[Gutma.Event]] {
        guard let events = events,
              let mavlinkCommands = mavlinkCommands,
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
                                                                      GutmaConstants.eventStepPathStop,
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

            // reaching an ending step
            if event.isEndingStep {
                if case let .started(atIndex: startIndex) = state {
                    subexecutionIndices.append((startIndex, index))
                    state.reset()
                }
                continue
            }

            if event.step == GutmaConstants.eventStepMissionItem {
                if event.missionItem.map({ Int($0) }) == firstWPIndex {
                    // override with first WP index
                    state.start(atIndex: index)
                } else if event.missionItem.map({ Int($0) }) == lastWPIndex,
                          case let .started(atIndex: startIndex) = state {
                    // when finding a last WP index mark as the end of the subexecution
                    subexecutionIndices.append((startIndex, index))
                    state.reset()
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
    ///   - mavlinkCommands: the flight plan's mavlink commands
    /// - Returns: A list of all starting timestamps of all sub-executions of the given flight plan.
    func flightPlanStartTimestamps(_ flightPlan: FlightPlanModel, mavlinkCommands: [MavlinkStandard.MavlinkCommand]?) -> [Double] {
        return flightPlanSubexecutionsEvents(flightPlan, mavlinkCommands: mavlinkCommands).compactMap { subexecutionEvents in
            subexecutionEvents.first?.eventTimestamp
        }.compactMap { Double($0) }
    }

    /// Extracts all 'end' events timestamps related to a flight plan execution.
    ///
    /// - Parameters:
    ///   - flightPlan: the flight plan
    ///   - mavlinkCommands: the flight plan's mavlink commands
    /// - Returns: A list of all ending timestamps of all sub-executions of the given flight plan.
    func flightPlanEndTimestamps(_ flightPlan: FlightPlanModel, mavlinkCommands: [MavlinkStandard.MavlinkCommand]?) -> [Double] {
        flightPlanSubexecutionsEvents(flightPlan, mavlinkCommands: mavlinkCommands).compactMap { subexecutionEvents in
            subexecutionEvents.last?.eventTimestamp
        }.compactMap { Double($0) }
    }

    /// Calculates the duration of an FP execution with a given uuid.
    ///
    /// - Parameters:
    ///   - flightPlan: the flight plan
    ///   - mavlinkCommands: the flight plan's mavlink commands
    /// - Returns: the duration for the given execution if found in the receiver, `nil` otherwise.
    func flightPlanDuration(_ flightPlan: FlightPlanModel, mavlinkCommands: [MavlinkStandard.MavlinkCommand]?) -> TimeInterval? {
        let starts = flightPlanStartTimestamps(flightPlan, mavlinkCommands: mavlinkCommands)
        let ends = flightPlanEndTimestamps(flightPlan, mavlinkCommands: mavlinkCommands)
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
    ///   - mavlinkCommands: the flight plan's mavlink commands
    /// - Returns: the total battery consumption for the given execution if found in the receiver,
    /// `nil` otherwise.
    func flightPlanBatteryConsumption(_ flightPlan: FlightPlanModel, mavlinkCommands: [MavlinkStandard.MavlinkCommand]?) -> Double? {
        let starts = flightPlanStartTimestamps(flightPlan, mavlinkCommands: mavlinkCommands)
        let ends = flightPlanEndTimestamps(flightPlan, mavlinkCommands: mavlinkCommands)
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
    /// - Parameters:
    ///   - flightPlan: the flight plan
    ///   - mavlinkCommands: the flight plan's mavlink commands
    /// - Returns: the total distance for the given execution if found in the receiver,
    /// `nil` otherwise.
    func flightPlanDistance(_ flightPlan: FlightPlanModel, mavlinkCommands: [MavlinkStandard.MavlinkCommand]?) -> Double? {
        let starts = flightPlanStartTimestamps(flightPlan, mavlinkCommands: mavlinkCommands)
        let ends = flightPlanEndTimestamps(flightPlan, mavlinkCommands: mavlinkCommands)
        guard !starts.isEmpty, !ends.isEmpty, starts.count == ends.count else {
            return nil
        }
        return zip(starts, ends).reduce(TimeInterval(0), { sum, pair in
            let items = itemsInTimestampRange(start: pair.0, end: pair.1)
            return sum + calculateDistance(ofItems: items)
        })
    }

    /// Calculates the number of photos taken during a FP execution.
    ///
    /// - Parameters:
    ///   - flightPlan: the flight plan
    ///   - mavlinkCommands: the flight plan's mavlink commands
    /// - Returns: the total number of photos,
    /// `nil` otherwise.
    func flightPlanPhotoCount(_ flightPlan: FlightPlanModel, mavlinkCommands: [MavlinkStandard.MavlinkCommand]?) -> Int {
        let photoEventsByCustomId = events?.filter {
            $0.eventInfo == GutmaConstants.eventInfoPhoto
            && $0.customId == flightPlan.uuid
        }

        if photoEventsByCustomId?.isEmpty == false {
            let total = (photoEventsByCustomId?.filter { $0.mediaEvent == GutmaConstants.eventMediaTypeTaken }.count ?? 0)
            - (photoEventsByCustomId?.filter {$0.mediaEvent == GutmaConstants.eventMediaTypeDeleted }.count ?? 0)
            return max(total, 0)
        } else {
            // Keep compatibility with old executions that does not have customId on photo events
            let starts = flightPlanStartTimestamps(flightPlan, mavlinkCommands: mavlinkCommands)
            let ends = flightPlanEndTimestamps(flightPlan, mavlinkCommands: mavlinkCommands)
            guard !starts.isEmpty, !ends.isEmpty, starts.count == ends.count else {
                return 0
            }
            return zip(starts, ends).reduce(0, { sum, pair in
                let photoCount = photoCountInRange(start: pair.0, end: pair.1)
                return sum + photoCount
            })
        }
    }

    /// Calculates the number of videos taken during a FP execution.
    ///
    /// - Parameters:
    ///   - flightPlan: the flight plan
    ///   - mavlinkCommands: the flight plan's mavlink commands
    /// - Returns: the total number of videos,
    /// `nil` otherwise.
    func flightPlanVideoCount(_ flightPlan: FlightPlanModel, mavlinkCommands: [MavlinkStandard.MavlinkCommand]?) -> Int {
        let starts = flightPlanStartTimestamps(flightPlan, mavlinkCommands: mavlinkCommands)
        let ends = flightPlanEndTimestamps(flightPlan, mavlinkCommands: mavlinkCommands)
        guard !starts.isEmpty, !ends.isEmpty, starts.count == ends.count else {
            return 0
        }
        return zip(starts, ends).reduce(0, { sum, pair in
            let videoCount = videoCountInRange(start: pair.0, end: pair.1)
            return sum + videoCount
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

    func items(startingFrom timestamp: TimeInterval) -> [Gutma.FlightLogging.Item] {
        guard let items = flightLoggingItems,
              let timestampindex = valueIndex(forKey: .timestamp)
        else { return [] }
        return items.filter { $0[timestampindex] >= timestamp }
    }

    /// Calculates the number of photos taken in a range of time.
    ///
    /// - Parameters:
    ///   - start: the execution start time.
    ///   - end: the execution end time.
    /// - Returns: the total number of photos taken
    func photoCountInRange(start: Double, end: Double) -> Int {
        guard let events = events else { return 0 }
        let photosInRange = events.filter { event in
            guard event.eventInfo == GutmaConstants.eventInfoPhoto,
                  let eventTimestamp = event.eventTimestamp,
                  let timestamp = Double(eventTimestamp),
                  start <= timestamp,
                  timestamp <= end
            else { return false }
            return true
        }
        return photosInRange.count
    }

    /// Calculates the number of videos taken in a range of time.
    ///
    /// - Parameters:
    ///   - start: the execution start time.
    ///   - end: the execution end time.
    /// - Returns: the total number of videos taken
    func videoCountInRange(start: Double, end: Double) -> Int {
        guard let events = events else { return 0 }

        var counter: Int = 0
        var videoStart: Double = 0.0
        var recording = false

        let videoEvents = events.filter {
            $0.eventInfo == GutmaConstants.eventInfoVideo
            && ($0.mediaEvent == GutmaConstants.eventMediaTypeStarted
                || $0.mediaEvent == GutmaConstants.eventMediaTypeSaved)
        }

        for (index, event) in videoEvents.enumerated() {
            guard let eventTimestamp = event.eventTimestamp,
                  let timestamp = Double(eventTimestamp)
            else { continue }
            if event.mediaEvent == GutmaConstants.eventMediaTypeStarted {
                videoStart = timestamp
                recording = true
            } else if event.mediaEvent == GutmaConstants.eventMediaTypeSaved {
                let videoRange = videoStart...timestamp
                let missionRange = start...end
                if (videoRange.contains(start) && videoRange.contains(end))
                    || missionRange.contains(videoStart)
                    || missionRange.contains(timestamp) {
                    counter += 1
                }
                recording = false
                videoStart = timestamp
            }
            if index == videoEvents.count-1  && recording && videoStart < end {
                counter += 1
            }
        }
        return counter
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
        step == GutmaConstants.eventStepStop || step == GutmaConstants.eventStepPathStop
    }

    var isStartingStep: Bool {
        step == GutmaConstants.eventStepStart
    }
}
