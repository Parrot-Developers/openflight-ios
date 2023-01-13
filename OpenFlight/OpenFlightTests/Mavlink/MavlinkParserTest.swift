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

import XCTest
import Hamcrest
@testable import OpenFlight
import CoreLocation

class MavlinkParserTest: XCTestCase {
    // bundle for access to test files
    var testBundle: Bundle!
    // precision when comparing doubles
    let delta =  0.000001
    override func setUpWithError() throws {
        // bundle to get test data
        testBundle = Bundle(for: type(of: self))
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testMavlinkParser() throws {
        // urls for test data
        guard let urls = testBundle.urls(forResourcesWithExtension: "flightplan", subdirectory: "") else { return }
        for url in urls {
            do {
                // load and check test data
                assertNotThrows(try Data(contentsOf: url))
                let data = try Data(contentsOf: url)
                assertThat(data, present())

                // decode and check test data
                assertNotThrows(try JSONDecoder().decode(FlightPlanTestModel.self, from: data))
                let flightPlan = try JSONDecoder().decode(FlightPlanTestModel.self, from: data)
                assertThat(flightPlan.uuid, present())
                assertThat(flightPlan.dataSetting, present())
                guard let dataSetting = flightPlan.dataSetting else {
                    continue
                }
                assertThat(dataSetting.mavlinkDataFile, present())
                let mavlinkString = String(
                    decoding: (dataSetting.mavlinkDataFile)!,
                    as: UTF8.self)

                // generate flight plan with parser
                let generatedFlightPlan = MavlinkToFlightPlanParser.generateFlightPlanFromMavlinkStandard(url: nil, mavlinkString: mavlinkString, flightPlan: flightPlan.flightPlanModel())
                assertThat(generatedFlightPlan?.dataSetting, present())
                guard let generatedDataSetting = generatedFlightPlan?.dataSetting else {
                    continue
                }

                // check dataSetting.takeoffActions
//                assertThat(generatedDataSetting.takeoffActions, equalTo(dataSetting.takeoffActions))

                // check wayPoints
                assertThat(generatedDataSetting.wayPoints.count == dataSetting.wayPoints.count)
                for index in 0..<dataSetting.wayPoints.count {
                    assertThat(generatedDataSetting.wayPoints[index], describedAs("waypoint #\(index)", matchesWayPoint(dataSetting.wayPoints[index])))
                }

                // check POIs
                if generatedDataSetting.pois.count == dataSetting.pois.count {
                    for index in 0..<dataSetting.pois.count {
                        assertThat(generatedDataSetting.pois[index], matchesPoi(dataSetting.pois[index]))
                    }
                }
            } catch {}
        }
    }

    func matchesWayPoint(_ waypoint: WayPoint) -> Matcher<WayPoint> {
        return Matcher("waypoint matches") { [self] (generatedWaypoint) -> MatchResult in
            // check altitude
            guard closeTo(waypoint.altitude, delta).matches(generatedWaypoint.altitude).boolValue else {
                return .mismatch("altitude got \(generatedWaypoint.altitude), expected \(waypoint.altitude)")
            }
            // check longitude
            guard closeTo(waypoint.coordinate.longitude, delta)
                    .matches(generatedWaypoint.coordinate.longitude).boolValue else {
                return .mismatch("longitude got \(generatedWaypoint.coordinate.longitude), expected \(waypoint.coordinate.longitude)")
            }
            // check latitude
            guard closeTo(waypoint.coordinate.latitude, delta)
                    .matches(generatedWaypoint.coordinate.latitude).boolValue else {
                return .mismatch("latitude got \(generatedWaypoint.coordinate.latitude), expected \(waypoint.coordinate.latitude)")
            }
            // check yaw
            if let wayPointYaw = waypoint.yaw, let valueYaw = generatedWaypoint.yaw {
                guard closeTo(wayPointYaw, delta).matches(valueYaw).boolValue else {
                    return .mismatch("yaw got \(valueYaw), expected \(wayPointYaw)")
                }
            } else {
                return .mismatch("Yaw value is missing")
            }
            // check shouldContinue
            guard equalTo(waypoint.shouldContinue).matches(generatedWaypoint.shouldContinue).boolValue else {
                return .mismatch("shouldContinue got \(generatedWaypoint.shouldContinue), expected \(waypoint.shouldContinue)")
            }
            // check speed
            guard closeTo(waypoint.speed, delta).matches(generatedWaypoint.speed).boolValue else {
                return .mismatch("speed got \(generatedWaypoint.speed), expected \(waypoint.speed)")
            }
            // all tests passed
            return .match
        }
    }

    func matchesPoi(_ poi: PoiPoint) -> Matcher<PoiPoint> {
        return Matcher("poi matches") { [self] (generatedPoi) -> MatchResult in
            guard closeTo(poi.altitude, delta).matches(generatedPoi.altitude).boolValue else {
                return .mismatch("altitude")
            }
            guard closeTo(poi.coordinate.longitude, delta).matches(generatedPoi.coordinate.longitude).boolValue else {
                return .mismatch("longitude")
            }
            guard closeTo(poi.coordinate.latitude, delta).matches(generatedPoi.coordinate.latitude).boolValue else {
                return .mismatch("latitude")
            }
            return .match
        }
    }
}
