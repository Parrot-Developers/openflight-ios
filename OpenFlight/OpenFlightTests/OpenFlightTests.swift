// Copyright (C) 2020 Parrot Drones SAS
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

import XCTest
import CoreLocation

class OpenFlightTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSimpleFlightDataState() {
        let state = FlightDataState(placemark: nil,
                                    location: nil,
                                    flightDescription: nil,
                                    date: nil,
                                    duration: "1",
                                    batteryConsumption: "1",
                                    distance: "1",
                                    gutmaFileKey: nil,
                                    thumbnail: nil)
        XCTAssertTrue(state.placemark == nil)
        XCTAssertTrue(state.location == nil)
        XCTAssertTrue(state.flightDescription == nil)
        XCTAssertTrue(state.date == nil)
        XCTAssertTrue(state.duration == "1")
        XCTAssertFalse(state.duration == "2")
        XCTAssertTrue(state.batteryConsumption == "1")
        XCTAssertFalse(state.batteryConsumption == "2")
        XCTAssertTrue(state.distance == "1")
        XCTAssertFalse(state.distance == "2")
        XCTAssertTrue(state.gutmaFileKey == nil)
        XCTAssertTrue(state.thumbnail == nil)
    }

    func testComplexFlightDataState() {
        let location = CLLocation(latitude: 48.879185, longitude: 2.367446)
        let flightDesc = "Current flight"
        let date = Date()
        let gutmaFK = "GutmaFileKey"
        let state = FlightDataState(placemark: nil,
                                    location: location,
                                    flightDescription: flightDesc,
                                    date: date,
                                    duration: "2",
                                    batteryConsumption: "3",
                                    distance: "4",
                                    gutmaFileKey: gutmaFK,
                                    thumbnail: nil)
        XCTAssertTrue(state.placemark == nil)
        XCTAssertTrue(state.location?.coordinate.latitude == 48.879185)
        XCTAssertTrue(state.location?.coordinate.longitude == 2.367446)
        XCTAssertTrue(state.location?.altitude == 0.0)
        XCTAssertFalse(state.flightDescription == nil)
        XCTAssertTrue(state.flightDescription == flightDesc)
        XCTAssertFalse(state.date == nil)
        XCTAssertTrue(state.date == date)
        XCTAssertTrue(state.duration == "2")
        XCTAssertFalse(state.duration == "1")
        XCTAssertTrue(state.batteryConsumption == "3")
        XCTAssertFalse(state.batteryConsumption == "4")
        XCTAssertTrue(state.distance == "4")
        XCTAssertFalse(state.distance == "2")
        XCTAssertFalse(state.gutmaFileKey == nil)
        XCTAssertTrue(state.gutmaFileKey == gutmaFK)
        XCTAssertTrue(state.thumbnail == nil)
    }

    func testFlightDataViewModel() {
        let location = CLLocation(latitude: 48.879185, longitude: 2.367446)
        // State
        let flightDesc = "Current flight"
        let date = Date()
        let gutmaFK = "GutmaFileKey"
        let state = FlightDataState(placemark: nil,
                                    location: location,
                                    flightDescription: flightDesc,
                                    date: date,
                                    duration: "2",
                                    batteryConsumption: "3",
                                    distance: "4",
                                    gutmaFileKey: gutmaFK,
                                    thumbnail: nil)

        // Model
        let model = FlightDataViewModel(state: state)
        XCTAssertTrue(model.state.value.flightDescription == flightDesc)
        XCTAssertTrue(model.state.value.thumbnail == nil)

        // Update title
        let newTitle = "Updated flight name"
        model.updateTitle(newTitle)
        XCTAssertFalse(model.state.value.flightDescription == flightDesc)
        XCTAssertTrue(model.state.value.flightDescription == newTitle)
    }
}
