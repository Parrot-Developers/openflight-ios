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

class MavlinkGenerationTest: XCTestCase {
    var testBundle: Bundle!

    func stringDash(_ val: Double?) -> String {
        if let val = val {
            return String(format: "%.6f", val)
        }
        return Style.dash
    }

    func stringDash(_ val: Int?) -> String {
        if let val = val {
            return String(val)
        }
        return Style.dash
    }

    func printFlightPlanData(flightPlan: FlightPlanModel, mavlink: String) {
        print("UUID: \(flightPlan.uuid )")
        if let takeOffactions = flightPlan.dataSetting?.takeoffActions, !takeOffactions.isEmpty {
            print("FlightPlan take off actions:")
            for action in takeOffactions {
                let line = "\(action.type)"
                print(line)
            }
        }
        if let captureMode = flightPlan.dataSetting?.captureMode {
            print("Capture mode:\t", captureMode)
        }
        print("RTH:\t\(flightPlan.dataSetting?.returnToLaunchCommand != nil ? "ON":"OFF")")
        print("Waypoints:")
        if let count = flightPlan.dataSetting?.wayPoints.count {
            print("index\tlatitude\tlongitude\taltitude\tyaw\ttilt\tspeed\tpoi\tviewMode")
            for index in 0..<count {
                let waypoint = flightPlan.dataSetting?.wayPoints[index]
                let latitude = stringDash(waypoint?.coordinate.latitude)
                let longitude = stringDash(waypoint?.coordinate.longitude)
                let altitude = waypoint?.altitude ?? 0
                let yaw = stringDash(waypoint?.yaw)
                let tilt = waypoint?.tilt ?? 0
                let speed = waypoint?.speed ?? 0
                let poi = stringDash(waypoint?.poiPoint?.index)
                let viewModeCommand = waypoint?.viewModeCommand.mode.description ?? Style.dash
                let line = "\(index)\t\(latitude)\t\(longitude)\t\(altitude)"
                + "\t\(yaw)\t\(tilt)\t\(speed)\t\(poi)\t\(viewModeCommand)"
                print(line)
            }
        }
        if let pois = flightPlan.dataSetting?.pois {
            print("POIs")
            print("index\tlatitude\tlongitude\taltitude")
            for poi in pois {
                let index = stringDash(poi.index)
                let latitude = stringDash(poi.coordinate.latitude)
                let longitude = stringDash(poi.coordinate.longitude)
                let line = "\(index)\t\(latitude)\t\(longitude)"
                + "\t\(poi.altitude)"
                print(line)
            }
        }
        print("Mavlink:")
        print(mavlink)
    }

    override func setUpWithError() throws {
        // bundle to get test data
        testBundle = Bundle(for: type(of: self))
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testMavlinkGenerator() {
        // services and mocks
        let flightPlanRepo = MockFlightPlanRepository()
        let flightPlanFilesManager = Services.hub.flightPlan.filesManager
        let flightPlanTypeStore = Services.hub.flightPlan.typeStore
        let projectManager = Services.hub.flightPlan.projectManager
        let planFileGenerator = PlanFileGeneratorImpl(typeStore: flightPlanTypeStore,
                                                      filesManager: flightPlanFilesManager,
                                                      projectManager: projectManager,
                                                      repo: flightPlanRepo)
        // urls for test data
        guard let urls = testBundle.urls(forResourcesWithExtension: "flightplan", subdirectory: "") else { return }
        for url in urls {
            // An expectation is needed because mavlink generation is asynchronous.
            let expectation = expectation(description: "Generate mavlink")
            do {
                // load and check test data
                assertNotThrows(try Data(contentsOf: url))
                let data = try Data(contentsOf: url)
                assertThat(data, present())

                // decode and check test data
                assertNotThrows(try JSONDecoder().decode(FlightPlanTestModel.self, from: data))
                let flightPlan = try JSONDecoder().decode(FlightPlanTestModel.self, from: data)
                assertThat(flightPlan.uuid, present())
                assertThat(flightPlan.dataSetting?.mavlinkDataFile, present())
                // Delete previous generated mavlink
                flightPlanFilesManager.deleteMavlink(of: flightPlan.flightPlanModel())

                // convert original mavlink from the test data
                let originalMavlinkDataFile = String(
                    decoding: (flightPlan.dataSetting?.mavlinkDataFile)!,
                    as: UTF8.self)

                printFlightPlanData(flightPlan: flightPlan.flightPlanModel(),
                                    mavlink: originalMavlinkDataFile)

                // generate mavlink
                Task {
                    do {
                        let generatedMavlinkData = try await planFileGenerator.generateMavlink(for: flightPlan.flightPlanModel(), with: nil)
                        // convert generated mavlink
                        let generatedMavlinkDataFile = String(decoding: generatedMavlinkData, as: UTF8.self)

                        // check and compare original and generated mavlinks
                        assertThat(generatedMavlinkDataFile, not(equalTo("")))
                        assertThat(generatedMavlinkDataFile, equalTo(originalMavlinkDataFile))

                        expectation.fulfill()
                   } catch {
                        assertThat(error.localizedDescription, nilValue())
                    }
                }
                wait(for: [expectation], timeout: 5.0)
            } catch {}
        }
    }
}
