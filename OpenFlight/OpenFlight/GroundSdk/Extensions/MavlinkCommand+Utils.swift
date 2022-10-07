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

import GroundSdk

/// `[MavlinkStandard.MavlinkCommand]` Array commands helpers.
public extension Array where Element == MavlinkStandard.MavlinkCommand {

    // Returns the first way point index.
    var firstWayPointIndex: Int? {
        firstIndex(where: { $0 is MavlinkStandard.NavigateToWaypointCommand })
    }

    // Returns the last way point index.
    var lastWayPointIndex: Int? {
        lastIndex(where: { $0 is MavlinkStandard.NavigateToWaypointCommand })
    }

    // Returns the number of way points.
    var wayPointsCount: Int {
        filter { $0 is MavlinkStandard.NavigateToWaypointCommand }.count
    }

    /// Returns whether an index is greater or equal than the first mavlink commands' way point index.
    ///  - Parameter index: the index to check
    ///  - Returns  `true` if index is greater or equal than the first way point index, `false` otherwise
    func hasReachedFirstWayPoint(index: Int) -> Bool {
        // Ensure the first way point index is available in the mavlink commands.
        guard let firstWayPointIndex = firstWayPointIndex else { return false }
        // Check if the current index is, or has passed, the first way point index.
        return index >= firstWayPointIndex
    }

    /// Returns whether an index is greater or equal than the last mavlink commands' way point index.
    ///  - Parameter index: the index to check
    ///  - Returns  `true` if index is greater or equal than the last way point index, `false` otherwise
    func hasReachedLastWayPoint(index: Int) -> Bool {
        // Ensure the last way point index is available in the mavlink commands.
        guard let lastWayPointIndex = lastWayPointIndex else { return false }
        // Check if the current index is, or has passed, the last way point index.
        return index >= lastWayPointIndex
    }

    /// Returns the last passed way point index according the specified item index.
    ///  - Parameter itemIndex: the index to check
    ///  - Returns  the last passed way point index
    func lastPassedWayPointIndex(for itemIndex: Int) -> Int? {
        // Ensure the first Way Point has been reached reached.
        guard hasReachedFirstWayPoint(index: itemIndex) else { return nil }
        // Calculate the number of NavigateToWaypointCommand commands executed until the lastMissionItemExecuted
        return prefix(Int(itemIndex) + 1)
            .filter { $0 is MavlinkStandard.NavigateToWaypointCommand }
            .count - 1
    }

    private enum Constants {
        static let progressRoundPrecision: Int = 4
    }

    /// Returns the flight plan percent completion.
    ///  - Parameters:
    ///     - itemIndex: the index to check
    ///     - flightPlan: the flight plan
    ///  - Returns  the flight plan percent completion
    func percentCompleted(for itemIndex: Int, flightPlan: FlightPlanModel) -> Double {
        // Ensure a `lastPassedWayPointIndex` exists
        guard let lastPassedWayPointIndex = lastPassedWayPointIndex(for: itemIndex) else { return 0 }

        // Get the last drone location of the FP run.
        // This location is updated by the `FlightPlanRunManager`during the flight.
        guard let droneLocation = flightPlan.dataSetting?.lastDroneLocation else {
            // Handle the backward compatibility and cases where the drone position is not knwon.
            // Calculate an estimated progress with the number of passed way points.
            if wayPointsCount > 0 {
                return Double(lastPassedWayPointIndex + 1) / Double(wayPointsCount) * 100
            }
            return 0
        }

        // Calculate the progress
        let progress = flightPlan.dataSetting?.completionProgress(with: droneLocation.agsPoint,
                                                                  lastWayPointIndex: lastPassedWayPointIndex) ?? 0
        return progress.rounded(toPlaces: Constants.progressRoundPrecision) * 100.0
    }
}
