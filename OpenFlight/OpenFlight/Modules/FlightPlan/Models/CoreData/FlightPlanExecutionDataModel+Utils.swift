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

/// Helpers for `FlightPlanExecutionDataModel`.
extension FlightPlanExecutionDataModel {
    /// Returns FlightPlanExecution object.
    var asFlightPlanExecution: FlightPlanExecution {
        let execution = FlightPlanExecution(flightPlanId: self.flightPlanId,
                                            flightId: self.flightId,
                                            startDate: self.startDate,
                                            endDate: self.endDate,
                                            state: self.stateEnum,
                                            settings: self.lightSettings,
                                            projectId: self.projectIdAsInt64)
        return execution
    }

    /// Helper to deal with Core Data's Number and Int64.
    var projectIdAsInt64: Int64? {
        return self.projectId?.int64Value
    }

    /// Helper to deal with Core Data's Data and FlightPlanLightSetting.
    var lightSettings: [FlightPlanLightSetting]? {
        guard let settings = settings else { return nil }

        return try? JSONDecoder().decode([FlightPlanLightSetting].self, from: settings)
    }

    /// Helper to deal with Core Data's String and FlightPlanExecutionState.
    var stateEnum: FlightPlanExecutionState? {
        guard let state = state,
              let enumValue = FlightPlanExecutionState(rawValue: state)
        else { return nil }

        return enumValue
    }

    /// Returns NSPredicate regarding value.
    ///
    /// - Parameters:
    ///     - sortValue: sort value
    static func fileKeyPredicate(sortValue: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@",
                           #keyPath(FlightPlanExecutionDataModel.executionId),
                           sortValue)
    }
}

/// FlightPlanExecution's utilities for `FlightPlanExecutionDataModel`.
extension FlightPlanExecution {
    /// Project id as string.
    var stateForPersistance: String? {
        return state?.rawValue
    }

    /// Light settings as Data.
    var settingsForPersistance: Data? {
        return try? JSONEncoder().encode(settings)
    }

    /// projectId as NSNumber.
    var projectIdForPersistance: NSNumber? {
        guard let value = projectId else { return nil }

        return NSNumber(value: value)
    }
}
