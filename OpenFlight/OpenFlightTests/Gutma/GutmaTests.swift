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
import CoreLocation
@testable import OpenFlight

class GutmaTests: XCTestCase {
    func get(gutma: String) -> Data? {
        guard let json = Bundle(for: Self.self).url(forResource: gutma, withExtension: "json", subdirectory: "flights"),
              let data = try? Data(contentsOf: json)
        else { return nil }
        return data
    }

    func get(flight: String, gutma: Data? = nil) -> FlightModel? {
        guard let json = Bundle(for: Self.self).url(forResource: flight, withExtension: "flight", subdirectory: "flights"),
              let data = try? Data(contentsOf: json),
              let flight = try? JSONDecoder().decode(FlightTestModel.self, from: data)
        else { return nil }
        return flight.flightModel(gutma: gutma)
    }

    func get(flightPlan: String) -> FlightPlanModel? {
        guard let json = Bundle(for: Self.self).url(forResource: flightPlan, withExtension: "flightplan", subdirectory: "flightplans"),
              let data = try? Data(contentsOf: json),
              let flightPlan = try? JSONDecoder().decode(FlightPlanTest.self, from: data)
        else { return nil }
        return flightPlan.flightPlanModel()
    }

    func getExecutionDetailsProvider(flightPlan: FlightPlanModel, flights: [FlightModel]) -> FlightPlanExecutionInfoCellProvider {
        return FlightPlanExecutionInfoCellProviderImpl(
            title: "",
            executionTitle: "",
            flightPlan: flightPlan, date: "",
            location: CLLocationCoordinate2D(),
            flights: flights,
            flightService: Services.hub.flight.service,
            mavlinkCommands: flightPlan.mavlinkCommands)
    }

    func testFlights() {
        let bundleURL = Bundle(for: Self.self).bundleURL
        let files = Bundle.urls(forResourcesWithExtension: "flight", subdirectory: "flights", in: bundleURL)!
        assertThat(files.count, not(equalTo(0)))

        for file in files {
            let fileName = file.deletingPathExtension().lastPathComponent
            guard let flight = get(flight: fileName),
                  let data = flight.gutmaFile,
                  let gutma = try? JSONDecoder().decode(Gutma.self, from: data)
            else {
                XCTFail("flight or gutma not found")
                return
            }

            assertThat(gutma.photoCount, equalTo(Int(flight.photoCount)))
            assertThat(gutma.videoCount, equalTo(Int(flight.videoCount)))
            assertThat(gutma.duration, closeTo(flight.duration, 0.5))
            assertThat(gutma.distance, closeTo(flight.distance, 0.5))
            assertThat(Int(gutma.batteryConsumption!), equalTo(Int(flight.batteryConsumption)))
        }
    }

    func testFlightPlanTimelapseBasic() {
        let flightPlan = get(flightPlan: "BasicTimelapse48Mp2Sec")!
        let flights = [get(flight: "0E5C29D2EB45A4E329A04361F7D0F90D")!]
        let result = getExecutionDetailsProvider(flightPlan: flightPlan, flights: flights).summaryProvider

        assertThat(result.photoCount, equalTo(28))
        assertThat(result.videoCount, equalTo(0))
        assertThat(Int(result.duration), equalTo(54))
        assertThat(Int(result.distance), equalTo(224))
        assertThat(result.batteryConsumption, equalTo(3))
    }

    func testFlightPlanVideoBasic() {
        let flightPlan = get(flightPlan: "BasicVideo4k30fps")!
        let flights = [get(flight: "BEBB4CF6AE9BC9E0DB738F1622B6B874")!]
        let result = getExecutionDetailsProvider(flightPlan: flightPlan, flights: flights).summaryProvider

        assertThat(result.photoCount, equalTo(0))
        assertThat(result.videoCount, equalTo(1))
        assertThat(Int(result.duration), equalTo(22))
        assertThat(Int(result.distance), equalTo(65))
        assertThat(result.batteryConsumption, equalTo(1))
    }

    func testFlightPlanGpslapseBasic() {
        let flightPlan = get(flightPlan: "BasicGpslapse48Mp05m")!
        let flights = [get(flight: "0F5DBAE884C61A723A19A3FCDC7FED78")!]
        let result = getExecutionDetailsProvider(flightPlan: flightPlan, flights: flights).summaryProvider

        assertThat(result.photoCount, equalTo(126))
        assertThat(result.videoCount, equalTo(0))
        assertThat(Int(result.duration), equalTo(22))
        assertThat(Int(result.distance), equalTo(65))
        assertThat(result.batteryConsumption, equalTo(1))
    }

    func testFlightPlanTimelapseWithSeveralVoluntaryStopsAndResumesWithoutLanding() {
        let flightPlan = get(flightPlan: "StopsResumesTimelapse48Mp2sec")!
        let flights = [get(flight: "86B0597BC7E1F472C957DA2AA8BABB8F")!]
        let result = getExecutionDetailsProvider(flightPlan: flightPlan, flights: flights).summaryProvider

        assertThat(result.photoCount, equalTo(22))
        assertThat(result.videoCount, equalTo(0))
        assertThat(Int(result.duration), equalTo(39))
        assertThat(Int(result.distance), equalTo(113))
        assertThat(result.batteryConsumption, equalTo(0))
    }

    func testFlightPlanVideoWithSeveralVoluntaryStopsAndResumesWithoutLanding() {
        let flightPlan = get(flightPlan: "StopsResumesVideo4k30fps")!
        let flights = [get(flight: "2F19FE29C1B5462BF161FFA85481E1B4")!]
        let result = getExecutionDetailsProvider(flightPlan: flightPlan, flights: flights).summaryProvider

        assertThat(result.photoCount, equalTo(0))
        assertThat(result.videoCount, equalTo(4))
        assertThat(Int(result.duration), equalTo(54))
        assertThat(Int(result.distance), equalTo(155))
        assertThat(result.batteryConsumption, equalTo(4))
    }

    func testFlightPlanGpslapseWithSeveralVoluntaryStopsAndResumesWithoutLanding() {
        let flightPlan = get(flightPlan: "StopsResumesGpslapse48Mp1m")!
        let flights = [get(flight: "86CA7D66525A2D10623F982C379C14DF")!]
        let result = getExecutionDetailsProvider(flightPlan: flightPlan, flights: flights).summaryProvider

        assertThat(result.photoCount, equalTo(139))
        assertThat(result.videoCount, equalTo(0))
        assertThat(Int(result.duration), equalTo(49))
        assertThat(Int(result.distance), equalTo(136))
        assertThat(result.batteryConsumption, equalTo(4))
    }

    func testFlightPlanVideoWithOverpiloting() {
        let flightPlan = get(flightPlan: "OverpilotingVideo1080p120fps")!
        let flights = [get(flight: "85974A281512DBE62E265A2E220A7DFE")!]
        let result = getExecutionDetailsProvider(flightPlan: flightPlan, flights: flights).summaryProvider

        assertThat(result.photoCount, equalTo(0))
        assertThat(result.videoCount, equalTo(1))
        assertThat(Int(result.duration), equalTo(48))
        assertThat(Int(result.distance), equalTo(203))
        assertThat(result.batteryConsumption, equalTo(0))
    }

    func testFlightPlanGpslapseWithOverpiloting() {
        let flightPlan = get(flightPlan: "OverpilotingGpslapse48Mp05m")!
        let flights = [get(flight: "9CF1400EF75951D43AE5D1C3A391234E")!]
        let result = getExecutionDetailsProvider(flightPlan: flightPlan, flights: flights).summaryProvider

        assertThat(result.photoCount, equalTo(98))
        assertThat(result.videoCount, equalTo(0))
        assertThat(Int(result.duration), equalTo(26))
        assertThat(Int(result.distance), equalTo(61))
        assertThat(result.batteryConsumption, equalTo(2))
    }

    func testFlightPlanTimelapseWithOverpiloting() {
        let flightPlan = get(flightPlan: "OverpilotingTimelapse48Mp1s")!
        let flights = [get(flight: "955CFCA69C9A24972508A5BD6761E2FC")!]
        let result = getExecutionDetailsProvider(flightPlan: flightPlan, flights: flights).summaryProvider

        assertThat(result.photoCount, equalTo(23))
        assertThat(result.videoCount, equalTo(0))
        assertThat(Int(result.duration), equalTo(41))
        assertThat(Int(result.distance), equalTo(86))
        assertThat(result.batteryConsumption, equalTo(2))
    }

    func testFlightPlanTimelapseWithOverpilotingLandingThenResume() {
        let flightPlan = get(flightPlan: "OverpilotingTimelapse2Flights")!
        let flights = [get(flight: "148CA25E4386B5B7581AEDD092CBC0E5")!,
                       get(flight: "10395BF51561A6A7D979B35A5BF061CB")!]
        let result = getExecutionDetailsProvider(flightPlan: flightPlan, flights: flights).summaryProvider

        let totalPhotoCount = Int(flights.reduce(0) { $0 + $1.photoCount })
        let totalVideoCount = Int(flights.reduce(0) { $0 + $1.videoCount })
        let totalDuration = Int(flights.reduce(0) { $0 + $1.duration })
        let totalDistance = Int(flights.reduce(0) { $0 + $1.distance })
        let totalBatteryConsumption = Int(flights.reduce(0) { $0 + $1.batteryConsumption })

        assertThat(totalPhotoCount, equalTo(72))
        assertThat(totalVideoCount, equalTo(0))
        assertThat(totalDuration, equalTo(739))
        assertThat(totalDistance, equalTo(1184))
        assertThat(totalBatteryConsumption, equalTo(35))

        assertThat(result.photoCount, equalTo(36))
        assertThat(result.videoCount, equalTo(0))
        assertThat(Int(result.duration), equalTo(129))
        assertThat(Int(result.distance), equalTo(392))
        assertThat(result.batteryConsumption, equalTo(6))
    }

    func testFlightPlanGpslapseWithOverpilotingLandingThenResume() {
        let flightPlan = get(flightPlan: "OverpilotingGpslapse48Mp1m2Flights")!
        let flights = [get(flight: "D29220344EA33B7AFEBFBCABCCB27330")!,
                       get(flight: "BCE0A430D1A60A3CFE720AC9F4DE4BBA")!]
        let result = getExecutionDetailsProvider(flightPlan: flightPlan, flights: flights).summaryProvider

        let totalPhotoCount = Int(flights.reduce(0) { $0 + $1.photoCount })
        let totalVideoCount = Int(flights.reduce(0) { $0 + $1.videoCount })
        let totalDuration = Int(flights.reduce(0) { $0 + $1.duration })
        let totalDistance = Int(flights.reduce(0) { $0 + $1.distance })
        let totalBatteryConsumption = Int(flights.reduce(0) { $0 + $1.batteryConsumption })

        assertThat(totalPhotoCount, equalTo(69))
        assertThat(totalVideoCount, equalTo(0))
        assertThat(totalDuration, equalTo(229))
        assertThat(totalDistance, equalTo(229))
        assertThat(totalBatteryConsumption, equalTo(12))

        assertThat(result.photoCount, equalTo(69))
        assertThat(result.videoCount, equalTo(0))
        assertThat(Int(result.duration), equalTo(100))
        assertThat(Int(result.distance), equalTo(152))
        assertThat(result.batteryConsumption, equalTo(5))
    }

    func testFlightPlanVideoWithOverpilotingLandingThenResume() {
        let flightPlan = get(flightPlan: "OverpilotingVideo4k30fps2Flights")!
        let flights = [get(flight: "7E37EDF424EC2B0CDCEE2DAB9EAA75F0")!,
                       get(flight: "63C000C6189606D2917D65B3ADFD01D4")!]
        let result = getExecutionDetailsProvider(flightPlan: flightPlan, flights: flights).summaryProvider

        let totalPhotoCount = Int(flights.reduce(0) { $0 + $1.photoCount })
        let totalVideoCount = Int(flights.reduce(0) { $0 + $1.videoCount })
        let totalDuration = Int(flights.reduce(0) { $0 + $1.duration })
        let totalDistance = Int(flights.reduce(0) { $0 + $1.distance })
        let totalBatteryConsumption = Int(flights.reduce(0) { $0 + $1.batteryConsumption })

        assertThat(totalPhotoCount, equalTo(0))
        assertThat(totalVideoCount, equalTo(2))
        assertThat(totalDuration, equalTo(188))
        assertThat(totalDistance, equalTo(250))
        assertThat(totalBatteryConsumption, equalTo(9))

        assertThat(result.photoCount, equalTo(0))
        assertThat(result.videoCount, equalTo(2))
        assertThat(Int(result.duration), equalTo(42))
        assertThat(Int(result.distance), equalTo(114))
        assertThat(result.batteryConsumption, equalTo(3))
    }

    func testFlightPlanVideoInterruptedByControllerShutdown() {
        let flightPlan = get(flightPlan: "LinkLossVideo4k30fps2Flights")!
        let flights = [get(flight: "E0C1FD8D901D8CDA3A1FB4397EADC3B3")!,
                       get(flight: "AD148CE23FF437E9209E8888BA649285")!]
        let result = getExecutionDetailsProvider(flightPlan: flightPlan, flights: flights).summaryProvider

        let totalPhotoCount = Int(flights.reduce(0) { $0 + $1.photoCount })
        let totalVideoCount = Int(flights.reduce(0) { $0 + $1.videoCount })
        let totalDuration = Int(flights.reduce(0) { $0 + $1.duration })
        let totalDistance = Int(flights.reduce(0) { $0 + $1.distance })
        let totalBatteryConsumption = Int(flights.reduce(0) { $0 + $1.batteryConsumption })

        assertThat(totalPhotoCount, equalTo(0))
        assertThat(totalVideoCount, equalTo(0))
        assertThat(totalDuration, equalTo(212))
        assertThat(totalDistance, equalTo(389))
        assertThat(totalBatteryConsumption, equalTo(11))

        assertThat(result.photoCount, equalTo(0))
        assertThat(result.videoCount, equalTo(0))
        assertThat(Int(result.duration), equalTo(58))
        assertThat(Int(result.distance), equalTo(222))
        assertThat(result.batteryConsumption, equalTo(4))
    }

    func testFlightPlanTimelapseInterruptedByControllerShutdown() {
        let flightPlan = get(flightPlan: "LinkLossTimelapse48Mp1s2Flights")!
        let flights = [get(flight: "6E8F26603CF77DA08676E6096B883D7D")!,
                       get(flight: "CD26E002B53D08729943B11F6093BAE4")!]
        let result = getExecutionDetailsProvider(flightPlan: flightPlan, flights: flights).summaryProvider

        let totalPhotoCount = Int(flights.reduce(0) { $0 + $1.photoCount })
        let totalVideoCount = Int(flights.reduce(0) { $0 + $1.videoCount })
        let totalDuration = Int(flights.reduce(0) { $0 + $1.duration })
        let totalDistance = Int(flights.reduce(0) { $0 + $1.distance })
        let totalBatteryConsumption = Int(flights.reduce(0) { $0 + $1.batteryConsumption })

        assertThat(totalPhotoCount, equalTo(25))
        assertThat(totalVideoCount, equalTo(0))
        assertThat(totalDuration, equalTo(168))
        assertThat(totalDistance, equalTo(148))
        assertThat(totalBatteryConsumption, equalTo(10))

        assertThat(result.photoCount, equalTo(25))
        assertThat(result.videoCount, equalTo(0))
        assertThat(Int(result.duration), equalTo(26))
        assertThat(Int(result.distance), equalTo(62))
        assertThat(result.batteryConsumption, equalTo(2))
    }

    func testFlightPlanGpslapseInterruptedByControllerShutdown() {
        let flightPlan = get(flightPlan: "LinkLossGpslapse12Mp1m2Flights")!
        let flights = [get(flight: "82DD6DE479B4EB3B29D8616F6ECFBF1B")!,
                       get(flight: "ED8426BB8121C3314EB1AE923DD779A5")!]
        let result = getExecutionDetailsProvider(flightPlan: flightPlan, flights: flights).summaryProvider

        let totalPhotoCount = Int(flights.reduce(0) { $0 + $1.photoCount })
        let totalVideoCount = Int(flights.reduce(0) { $0 + $1.videoCount })
        let totalDuration = Int(flights.reduce(0) { $0 + $1.duration })
        let totalDistance = Int(flights.reduce(0) { $0 + $1.distance })
        let totalBatteryConsumption = Int(flights.reduce(0) { $0 + $1.batteryConsumption })

        assertThat(totalPhotoCount, equalTo(70))
        assertThat(totalVideoCount, equalTo(0))
        assertThat(totalDuration, equalTo(170))
        assertThat(totalDistance, equalTo(143))
        assertThat(totalBatteryConsumption, equalTo(8))

        assertThat(result.photoCount, equalTo(70))
        assertThat(result.videoCount, equalTo(0))
        assertThat(Int(result.duration), equalTo(28))
        assertThat(Int(result.distance), equalTo(68))
        assertThat(result.batteryConsumption, equalTo(2))
    }

    func testFlightPlanVideoInterruptedByStopButton() {
        let flightPlan = get(flightPlan: "StopLandingResumeVideo4k2Flights")!
        let flights = [get(flight: "406E3B2A9BE576B57155B906ECF18616")!,
                       get(flight: "786654DE69BFED88832BBEB73AFDBDD4")!]
        let result = getExecutionDetailsProvider(flightPlan: flightPlan, flights: flights).summaryProvider

        let totalPhotoCount = Int(flights.reduce(0) { $0 + $1.photoCount })
        let totalVideoCount = Int(flights.reduce(0) { $0 + $1.videoCount })
        let totalDuration = Int(flights.reduce(0) { $0 + $1.duration })
        let totalDistance = Int(flights.reduce(0) { $0 + $1.distance })
        let totalBatteryConsumption = Int(flights.reduce(0) { $0 + $1.batteryConsumption })

        assertThat(totalPhotoCount, equalTo(0))
        assertThat(totalVideoCount, equalTo(0))
        assertThat(totalDuration, equalTo(239))
        assertThat(totalDistance, equalTo(333))
        assertThat(totalBatteryConsumption, equalTo(12))

        assertThat(result.photoCount, equalTo(0))
        assertThat(result.videoCount, equalTo(0))
        assertThat(Int(result.duration), equalTo(47))
        assertThat(Int(result.distance), equalTo(173))
        assertThat(result.batteryConsumption, equalTo(3))
    }

    func testFlightPlanTimelapseInterruptedByStopButton() {
        let flightPlan = get(flightPlan: "StopLandingResumeTimelapse12Mp1s2Flights")!
        let flights = [get(flight: "064E3DE1EDDD8ACB29CADD3E827A4301")!,
                       get(flight: "40F115D36E0081D06CE48EBDE22F85D9")!]
        let result = getExecutionDetailsProvider(flightPlan: flightPlan, flights: flights).summaryProvider

        let totalPhotoCount = Int(flights.reduce(0) { $0 + $1.photoCount })
        let totalVideoCount = Int(flights.reduce(0) { $0 + $1.videoCount })
        let totalDuration = Int(flights.reduce(0) { $0 + $1.duration })
        let totalDistance = Int(flights.reduce(0) { $0 + $1.distance })
        let totalBatteryConsumption = Int(flights.reduce(0) { $0 + $1.batteryConsumption })

        assertThat(totalPhotoCount, equalTo(32))
        assertThat(totalVideoCount, equalTo(0))
        assertThat(totalDuration, equalTo(177))
        assertThat(totalDistance, equalTo(188))
        assertThat(totalBatteryConsumption, equalTo(10))

        assertThat(result.photoCount, equalTo(32))
        assertThat(result.videoCount, equalTo(0))
        assertThat(Int(result.duration), equalTo(33))
        assertThat(Int(result.distance), equalTo(84))
        assertThat(result.batteryConsumption, equalTo(3))
    }

    func testFlightPlanGpslapseInterruptedByStopButton() {
        let flightPlan = get(flightPlan: "StopLandingResumeGpslapse12Mp05m2Flights")!
        let flights = [get(flight: "A93E9C82224EBE5F2AEF5528FF68CC9A")!,
                       get(flight: "985CFA39DDD996D95C170AA068B49B29")!]
        let result = getExecutionDetailsProvider(flightPlan: flightPlan, flights: flights).summaryProvider

        let totalPhotoCount = Int(flights.reduce(0) { $0 + $1.photoCount })
        let totalVideoCount = Int(flights.reduce(0) { $0 + $1.videoCount })
        let totalDuration = Int(flights.reduce(0) { $0 + $1.duration })
        let totalDistance = Int(flights.reduce(0) { $0 + $1.distance })
        let totalBatteryConsumption = Int(flights.reduce(0) { $0 + $1.batteryConsumption })

        assertThat(totalPhotoCount, equalTo(109))
        assertThat(totalVideoCount, equalTo(0))
        assertThat(totalDuration, equalTo(153))
        assertThat(totalDistance, equalTo(103))
        assertThat(totalBatteryConsumption, equalTo(8))

        assertThat(result.photoCount, equalTo(109))
        assertThat(result.videoCount, equalTo(0))
        assertThat(Int(result.duration), equalTo(22))
        assertThat(Int(result.distance), equalTo(52))
        assertThat(result.batteryConsumption, equalTo(2))
    }

    func testFlightPlanWithStartDateEvent() {
        let flightPlan = get(flightPlan: "BasicTimelapse48Mp2Sec")!
        let customGutma = get(gutma: "BasicTimelapse48Mp2SecWithFlightDateEvent")
        let flight = get(flight: "0E5C29D2EB45A4E329A04361F7D0F90D", gutma: customGutma)!
        let result = getExecutionDetailsProvider(flightPlan: flightPlan, flights: [flight]).summaryProvider

        guard let data = flight.gutmaFile,
              let gutma = try? JSONDecoder().decode(Gutma.self, from: data)
        else {
            XCTFail("flight or gutma not found")
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "y-MM-dd H:mm:ss.SSS Z"
        let date = formatter.date(from: "1969-12-31 22:00:41.000 UTC")

        assertThat(gutma.startDate!, equalTo(date!))
        assertThat(result.photoCount, equalTo(28))
        assertThat(result.videoCount, equalTo(0))
        assertThat(Int(result.duration), equalTo(54))
        assertThat(Int(result.distance), equalTo(224))
        assertThat(result.batteryConsumption, equalTo(3))
    }
}
