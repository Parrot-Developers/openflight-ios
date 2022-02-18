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
import CoreData

/// - Intermediate to join (ManyToMany relationship) between FlightPlan and Flight

@objc(FlightPlanFlights)
public class FlightPlanFlights: NSManagedObject {

    // MARK: - Utils
    func model() -> FlightPlanFlightsModel {
        return FlightPlanFlightsModel(apcId: apcId,
                                      cloudId: Int(cloudId),
                                      flightplanUuid: flightplanUuid,
                                      flightUuid: flightUuid,
                                      dateExecutionFlight: dateExecutionFlight,
                                      isLocalDeleted: isLocalDeleted,
                                      synchroStatus: SynchroStatus(status: synchroStatus),
                                      synchroError: SynchroError(error: synchroError),
                                      latestSynchroStatusDate: latestSynchroStatusDate,
                                      latestLocalModificationDate: latestLocalModificationDate)
    }

    func update(fromFPlanFlightsModel fPlanFlights: FlightPlanFlightsModel, withFlightPlan: FlightPlan, withFlight: Flight) {
        ofFlight = withFlight
        ofFlightPlan = withFlightPlan

        apcId = fPlanFlights.apcId
        cloudId = Int64(fPlanFlights.cloudId)
        flightplanUuid = fPlanFlights.flightplanUuid
        flightUuid = fPlanFlights.flightUuid
        dateExecutionFlight = fPlanFlights.dateExecutionFlight

        isLocalDeleted = fPlanFlights.isLocalDeleted
        latestSynchroStatusDate = fPlanFlights.latestSynchroStatusDate
        latestLocalModificationDate = fPlanFlights.latestLocalModificationDate

        // To ensure synchronisation
        // reset `synchroStatus´ when the modifications are made by User
        synchroStatus = fPlanFlights.synchroStatus?.rawValue ?? 0
        synchroError = fPlanFlights.synchroError?.rawValue ?? 0
    }
}
