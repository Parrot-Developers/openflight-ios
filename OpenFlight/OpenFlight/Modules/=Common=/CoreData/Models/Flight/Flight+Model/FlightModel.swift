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

public struct FlightModel {

    // MARK: - Properties

    public var uuid: String
    public var title: String?
    public var version: String
    public var gutmaFile: String
    public var photoCount: Int16
    public var videoCount: Int16
    public var startLatitude: Double
    public var startLongitude: Double
    public var startTime: Date?
    public var batteryConsumption: Int16
    public var distance: Double
    public var duration: Double

    /// - parrotCloudId: Id of Flight on server: Set only if synchronized
    public var parrotCloudId: Int64

    /// - parrotCloudToBeDeleted: True if a Delete Request was triguerred without success
    public var parrotCloudToBeDeleted: Bool?

    /// - parrotCloudUploadUrl: Url to upload Gutma File
    public var parrotCloudUploadUrl: String?

    /// - fileSynchroStatus: Contains 0 if not yet synchronized, 1 if yes
        /// statusCode if sync failed
    public var fileSynchroStatus: Int16?

    /// - cloudLastUpdate: Last modification date of Flight
    public var cloudLastUpdate: Date?

    /// - synchroDate: contains the Date of last synchro trying if is not succeeded
    public var synchroDate: Date?

    /// - synchroStatus: Contains 0 if not yet synchronized, 1 if yes
        /// statusCode if sync failed
    public var synchroStatus: Int16?

    // MARK: - Relationship

    /// Date of Flight's Execution
    /// managed by FlightPlanFlights entity
    public var dateExecutionFlight: Date?

    /// UUID of the executed FlightPlan
    /// managed by FlightPlan entity
    public var flightPlanUuid: String?

    public var flightPlanFlights: [FlightPlanFlightsModel]?

    // MARK: - Public init

    public init(title: String?,
                uuid: String,
                version: String,
                flightPlanUuid: String?,
                photoCount: Int16,
                videoCount: Int16,
                startLatitude: Double,
                startLongitude: Double,
                startTime: Date?,
                batteryConsumption: Int16,
                distance: Double,
                duration: Double,
                gutmaFile: String,
                parrotCloudId: Int64 = 0,
                parrotCloudToBeDeleted: Bool = false,
                parrotCloudUploadUrl: String?,
                synchroDate: Date? = nil,
                synchroStatus: Int16? = 0,
                cloudLastUpdate: Date?,
                fileSynchroStatus: Int16? = 0,
                dateExecutionFlight: Date?,
                flightPlanFlights: [FlightPlanFlightsModel]? = nil) {

        self.title = title
        self.uuid = uuid
        self.version = version
        self.flightPlanUuid = flightPlanUuid
        self.photoCount = photoCount
        self.videoCount = videoCount
        self.startLatitude = startLatitude
        self.startLongitude = startLongitude
        self.startTime = startTime
        self.batteryConsumption = batteryConsumption
        self.distance = distance
        self.duration = duration
        self.gutmaFile = gutmaFile
        self.parrotCloudId = parrotCloudId
        self.parrotCloudToBeDeleted = parrotCloudToBeDeleted
        self.parrotCloudUploadUrl = parrotCloudUploadUrl
        self.synchroDate = synchroDate
        self.synchroStatus = synchroStatus
        self.fileSynchroStatus = fileSynchroStatus
        self.dateExecutionFlight = dateExecutionFlight
        self.cloudLastUpdate = cloudLastUpdate
        self.flightPlanFlights = flightPlanFlights
    }
}
