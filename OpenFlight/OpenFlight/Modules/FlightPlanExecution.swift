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

/// Flight Plan execution states.
public enum FlightPlanExecutionState: String, Codable {
    case initialized
    case completed
    case stopped
    case error
}

/// Class used to link a Gutma flight file with a Flight Plan.
public final class FlightPlanExecution: Codable, Equatable {
    // MARK: - Public Properties
    public var flightPlanId: String
    public var flightId: String?
    public var startDate: Date
    public var endDate: Date?
    public var state: FlightPlanExecutionState
    public var settings: [FlightPlanLightSetting]?
    /// Used to resume flight plan execution.
    public var latestItemExecuted: Int?
    // Property used to get the medias of a flight plan execution.
    public let executionId: String

    // MARK: - Private Enums
    enum CodingKeys: String, CodingKey {
        case flightPlanId
        case flightId
        case startDate
        case endDate
        case state
        case settings
        case latestItemExecuted
        case executionId
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - flightPlanId: Flight Plan Id
    ///    - flightId: flight Id
    ///    - startDate: start date
    ///    - endDate: end date
    ///    - state: Flight Plan execution state
    ///    - settings: list of Flight Plan settings
    ///    - projectId: project Id
    init(flightPlanId: String,
         flightId: String?,
         startDate: Date,
         endDate: Date? = nil,
         state: FlightPlanExecutionState = .initialized,
         settings: [FlightPlanLightSetting]? = nil,
         projectId: Int64? = nil,
         latestItemExecuted: Int? = nil) {
        self.flightPlanId = flightPlanId
        self.flightId = flightId
        self.startDate = startDate
        self.endDate = endDate
        self.state = state
        self.settings = settings
        self.latestItemExecuted = latestItemExecuted

        executionId = String(format: "%@:%@",
                             flightPlanId,
                             ISO8601DateFormatter().string(from: startDate))
    }

    // MARK: - Equatable
    public static func == (lhs: FlightPlanExecution, rhs: FlightPlanExecution) -> Bool {
        return lhs.flightPlanId == rhs.flightPlanId
            && lhs.flightId == rhs.flightId
            && lhs.startDate == rhs.startDate
            && lhs.endDate == rhs.endDate
            && lhs.state == rhs.state
            && lhs.settings == rhs.settings
            && lhs.latestItemExecuted == rhs.latestItemExecuted
    }
}

// MARK: - Internal Properties
/// Provides helpers for `FlightPlanExecution`.
extension FlightPlanExecution {
    /// Returns fomatted execution date.
    ///
    /// - Parameters:
    ///     - isShort: result string should be short
    /// - Returns: fomatted execution date or dash if formatting failed.
    func fomattedExecutionDate(isShort: Bool) -> String {
        let fomattedDate = isShort ? self.startDate.shortFormattedString : self.startDate.shortWithTimeFormattedString
        return fomattedDate ?? Style.dash
    }
}
