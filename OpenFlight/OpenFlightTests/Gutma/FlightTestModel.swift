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
@testable import OpenFlight
@testable import Pictor

struct FlightTestModel: Codable {
    var uuid: String
    var photoCount: Int16
    var videoCount: Int16
    var batteryConsumption: Int16
    var distance: Double
    var duration: Double
    var gutmaFile: Data?

    func flightModel(gutma: Data?) -> FlightModel {
        return FlightModel(uuid: uuid,
                           cloudId: 0,
                           formatVersion: "",
                           title: "",
                           parseError: false,
                           runDate: nil,
                           serial: "",
                           firmware: "",
                           modelId: "",
                           gutmaFile: gutma ?? gutmaFile,
                           photoCount: photoCount,
                           videoCount: videoCount,
                           startLatitude: 0,
                           startLongitude: 0,
                           batteryConsumption: batteryConsumption,
                           distance: distance,
                           duration: duration,
                           thumbnail: nil)
    }

    /// Exports all flights currently in the repository.
    /// Stores them as files in the document directory of the app
    static func export() {
        let flights = Services.hub.repos.flight.getAll()
        for flight in flights {
            let flightExport = FlightTestModel(
                uuid: flight.uuid,
                photoCount: flight.photoCount,
                videoCount: flight.videoCount,
                batteryConsumption: flight.batteryConsumption,
                distance: flight.distance,
                duration: flight.duration,
                gutmaFile: flight.gutmaFile)
            do {
                let data = try JSONEncoder().encode(flightExport)
                var url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                url.appendPathComponent("flights")
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                url.appendPathComponent("\(flight.uuid).flight")
                try data.write(to: url)
            } catch { }
        }
    }
}

struct FlightPlanTest: Codable {
    var uuid: String
    var dataSetting: FlightPlanDataSetting?

    /// Exports all flight plans currently in the repository.
    /// Stores them as files in the document directory of the app
    func flightPlanModel() -> FlightPlanModel {
        let pictorfpm = PictorFlightPlanModel(uuid: uuid,
                                              cloudId: 0,
                                              name: "",
                                              state: .editable,
                                              flightPlanType: "",
                                              formatVersion: "1",
                                              lastUpdated: Date(),
                                              fileType: "",
                                              dataSetting: nil,
                                              mediaCount: 0,
                                              uploadedMediaCount: 0,
                                              lastMissionItemExecuted: 0,
                                              executionRank: nil,
                                              hasReachedFirstWaypoint: nil,
                                              projectUuid: nil,
                                              projectPix4dUuid: nil,
                                              thumbnail: nil)
        var fpm = FlightPlanModel(pictorModel: pictorfpm)
        fpm.dataSetting = dataSetting
        return fpm
    }
}
