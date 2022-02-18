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

// TODO: Add a local unique identifier

public struct FlightPlanFlightsModel {
    // MARK: __ User's ID
    public var apcId: String

    // MARK: __ Academy
    public var cloudId: Int
    public var flightplanUuid: String
    public var flightUuid: String
    public var dateExecutionFlight: Date

    // MARK: __ Synchronization
    ///  Boolean to know if it delete locally but needs to be deleted on server
    public var isLocalDeleted: Bool
    ///  Synchro status
    public var synchroStatus: SynchroStatus?
    ///  Synchro error
    public var synchroError: SynchroError?
    ///  Date of last tried synchro
    public var latestSynchroStatusDate: Date?
    ///  Date of local modification
    public var latestLocalModificationDate: Date?

    // MARK: - Public init
    public init(apcId: String,
                cloudId: Int,
                flightplanUuid: String,
                flightUuid: String,
                dateExecutionFlight: Date,
                isLocalDeleted: Bool,
                synchroStatus: SynchroStatus?,
                synchroError: SynchroError?,
                latestSynchroStatusDate: Date?,
                latestLocalModificationDate: Date?) {
        // User's ID
        self.apcId = apcId
        // Academy
        self.cloudId = cloudId
        self.flightplanUuid = flightplanUuid
        self.flightUuid = flightUuid
        self.dateExecutionFlight = dateExecutionFlight
        // Synchronization
        self.isLocalDeleted = isLocalDeleted
        self.synchroStatus = synchroStatus
        self.synchroError = synchroError
        self.latestSynchroStatusDate = latestSynchroStatusDate
        self.latestLocalModificationDate = latestLocalModificationDate
    }
}

extension FlightPlanFlightsModel {
    public init(apcId: String,
                flightplanUuid: String,
                flightUuid: String,
                dateExecutionFlight: Date) {
        self.init(apcId: apcId,
                  cloudId: 0,
                  flightplanUuid: flightplanUuid,
                  flightUuid: flightUuid,
                  dateExecutionFlight: dateExecutionFlight,
                  isLocalDeleted: false,
                  synchroStatus: .notSync,
                  synchroError: .noError,
                  latestSynchroStatusDate: nil,
                  latestLocalModificationDate: nil)
    }
}
