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

public struct ProjectModel {

    // MARK: - Properties

    public var uuid: String
    public var title: String?
    public var type: String

    // MARK: - Synchro Properties

    /// - lastUpdated: local modification date
    public var lastUpdated: Date

    /// - cloudLastUpdate: remote modification date
    public var cloudLastUpdate: Date?

    /// - parrotCloudId: Id of project on server: Set only if synchronized
    public var parrotCloudId: Int64

    /// - parrotCloudToBeDeleted: True if a Delete Request was triguerred without success
    public var parrotCloudToBeDeleted: Bool?

    /// - synchroDate: contains the Date of last synchro trying if is not succeeded
    public var synchroDate: Date?

    /// - synchroStatus: Contains 0 if not yet synchronized, 1 if yes
        /// statusCode if sync failed
    public var synchroStatus: Int16?

    // MARK: - Relashionship

    public var flightPlanModels: [FlightPlanModell]?

    // MARK: - Public init

    public init(uuid: String,
                title: String?,
                type: String,
                lastUpdated: Date,
                parrotCloudId: Int64 = 0,
                cloudLastUpdate: Date? = nil,
                parrotCloudToBeDeleted: Bool = false,
                synchroDate: Date? = nil,
                synchroStatus: Int16? = 0,
                flightPlanModels: [FlightPlanModell]?) {

        self.uuid = uuid
        self.title = title
        self.type = type
        self.lastUpdated = lastUpdated
        self.cloudLastUpdate = cloudLastUpdate
        self.parrotCloudId = parrotCloudId
        self.parrotCloudToBeDeleted = parrotCloudToBeDeleted
        self.synchroDate = synchroDate
        self.synchroStatus = synchroStatus
        self.flightPlanModels = flightPlanModels
    }
}
