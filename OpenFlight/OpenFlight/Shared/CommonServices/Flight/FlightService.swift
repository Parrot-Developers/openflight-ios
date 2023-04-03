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
import MapKit
import CoreLocation
import Combine
import Pictor

/// Summary about all flights
public struct AllFlightsSummary {
    /// Total number of flights
    public var numberOfFlights: Int
    public var totalDuration: Double
    public var totalDistance: Double
    /// Total flights duration.
    public var totalFlightsDuration: String {
        guard totalDuration > 0 else { return Style.dash }
        return totalDuration.formattedHmsString ?? Style.dash
    }
    /// Total flights distance.
    public var totalFlightsDistance: String {
        guard totalDistance > 0 else { return Style.dash }
        return totalDistance.distanceString
    }

    /// Init
    public init(numberOfFlights: Int = 0,
                totalDuration: Double = 0,
                totalDistance: Double = 0) {
        self.numberOfFlights = numberOfFlights
        self.totalDuration = totalDuration
        self.totalDistance = totalDistance
    }

    /// `AllFlightsSummary`'s default values
    public static let defaultValues = AllFlightsSummary()

    private func summaryForFlights(_ flights: [FlightModel]) -> (numberOfFlights: Int, totalDuration: Double, totalDistance: Double) {
        (flights.count,
         Double(flights.reduce(0) { $0 + $1.duration }),
         Double(flights.reduce(0) { $0 + $1.distance }))
    }

    public mutating func addFlights(_ flights: [FlightModel]) {
        let summary = summaryForFlights(flights)
        numberOfFlights += summary.numberOfFlights
        totalDuration += Double(summary.totalDuration)
        totalDistance += Double(summary.totalDistance)
    }

    public mutating func removeFlights(_ flights: [FlightModel]) {
        let summary = summaryForFlights(flights)
        numberOfFlights -= summary.numberOfFlights
        totalDuration -= Double(summary.totalDuration)
        totalDistance -= Double(summary.totalDistance)
    }

    public mutating func removeAllFlights() {
        numberOfFlights = 0
        totalDuration = 0
        totalDistance = 0
    }
}

public protocol FlightService: AnyObject {
    var allFlightsSummaryPublisher: AnyPublisher<AllFlightsSummary, Never> { get }
    var flightsDidChangePublisher: AnyPublisher<Void, Never> { get }
    var flightsDidCreatePublisher: AnyPublisher<[String], Never> { get }
    var flightsDidDeletePublisher: AnyPublisher<[String], Never> { get }
    var flightsDidUpdatePublisher: AnyPublisher<[String], Never> { get }

    func getAllFlights() -> [FlightModel]
    func getFlight(byUuid uuid: String) -> FlightModel?
    func getFlights(byUuids uuids: [String]) -> [FlightModel]
    func getFlights(offset: Int, count: Int) -> [FlightModel]
    func getFlights(count: Int) -> [FlightModel]
    func getAllFlightsCount() -> Int
    func update(flight: FlightModel, title: String) -> FlightModel
    func delete(flight: FlightModel)
    func save(gutmaOutput: [PictorGutma.Model])
    func flightPlans(flight: FlightModel) -> [FlightPlanModel]
    func gutma(flight: FlightModel) -> PictorGutma?
    /// Gutma from data. Bypasses cache, don't use except on first retrieval from drone
    /// - Parameter data: gutma's data
    func gutma(data: Data) -> PictorGutma?
    func handleFlightsUnknownLocationTitle(inFlights: [FlightModel]) async
}

open class FlightServiceImpl {
    private let flightRepository: PictorFlightRepository
    private let gutmaLinkRepository: PictorGutmaLinkRepository
    private let userService: PictorUserService
    private let flightPlanRunManager: FlightPlanRunManager
    private var flightsDidChangeSubject = PassthroughSubject<Void, Never>()
    private var allFlightSummarySubject = CurrentValueSubject<AllFlightsSummary, Never>(AllFlightsSummary())
    private var cancellables = Set<AnyCancellable>()
    private var gutmaCache = NSCache<NSString, PictorGutma>()

    init(flightRepository: PictorFlightRepository,
         gutmaLinkRepository: PictorGutmaLinkRepository,
         userService: PictorUserService,
         flightPlanRunManager: FlightPlanRunManager) {
        self.flightRepository = flightRepository
        self.gutmaLinkRepository = gutmaLinkRepository
        self.userService = userService
        self.flightPlanRunManager = flightPlanRunManager

        refreshAllFlightsSummary()

        userService.userEventPublisher
            .sink { [unowned self] _ in
                refreshAllFlightsSummary()
            }
            .store(in: &cancellables)

        flightRepository.didDeleteAllPublisher
            .sink { [unowned self] in
                refreshAllFlightsSummary()
            }.store(in: &cancellables)

        flightsDidChangePublisher
            .sink { [unowned self] _ in
                refreshAllFlightsSummary()
            }.store(in: &cancellables)
    }
}

private extension FlightServiceImpl {

    func getTitleLocation(forFlight flight: FlightModel) async -> String {
        let flightTitle = flight.title

        guard flightTitle.isEmpty else {
            return flightTitle
        }

        let location = CLLocation(latitude: flight.startLatitude, longitude: flight.startLongitude)

        do {
            let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
            var title = ""

            if let place = placemarks.first, let placeTitle = place.addressDescription {
                title = placeTitle
            }

            return title
        } catch {
            return ""
        }
    }

    func summary(for flights: [FlightModel]) -> AllFlightsSummary {
        let numberOfFlights = flights.count
        let duration = Double(flights.reduce(0) { $0 + $1.duration })
        let distance = Double(flights.reduce(0) { $0 + $1.distance })
        return AllFlightsSummary(numberOfFlights: numberOfFlights,
                                 totalDuration: duration,
                                 totalDistance: distance)
    }

    private func refreshAllFlightsSummary() {
        let allSummary = flightRepository.getAllSummary()
        allFlightSummarySubject.value = AllFlightsSummary(numberOfFlights: allSummary.count,
                                                          totalDuration: allSummary.duration,
                                                          totalDistance: allSummary.distance)
    }
}

extension FlightServiceImpl: FlightService {
    public var flightsDidChangePublisher: AnyPublisher<Void, Never> {
        flightRepository.didChangePublisher
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    public var flightsDidCreatePublisher: AnyPublisher<[String], Never> {
        flightRepository.didCreatePublisher
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    public var flightsDidUpdatePublisher: AnyPublisher<[String], Never> {
        flightRepository.didUpdatePublisher
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    public var flightsDidDeletePublisher: AnyPublisher<[String], Never> {
        flightRepository.didDeletePublisher
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    public var allFlightsSummaryPublisher: AnyPublisher<AllFlightsSummary, Never> {
        allFlightSummarySubject.eraseToAnyPublisher()
    }

    public func getAllFlights() -> [FlightModel] {
        flightRepository.getAll()
    }

    public func getAllFlightsCount() -> Int {
        flightRepository.count()
    }

    public func getFlights(offset: Int, count: Int) -> [FlightModel] {
        flightRepository.get(from: offset, count: count)
    }

    public func getFlights(count: Int) -> [FlightModel] {
        getFlights(offset: 0, count: count)
    }

    /// Returns flight model gathered from repository for a specific UUID.
    ///
    /// - Parameter uuid: the UUID of the flight model to get
    /// - Returns: the flight model with provided UUID (if any)
    public func getFlight(byUuid uuid: String) -> FlightModel? {
        flightRepository.get(byUuid: uuid)
    }

    /// Returns a flight models array gathered from repository for a specific UUIDs array.
    ///
    /// - Parameter uuids: the UUIDs array of the flight models to get
    /// - Returns: the flight models array with provided UUIDs
    public func getFlights(byUuids uuids: [String]) -> [FlightModel] {
        flightRepository.get(byUuids: uuids)
    }

    public func update(flight: PictorFlightModel, title: String) -> PictorFlightModel {
        var flight = flight
        flight.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let pictorContext = PictorContext.new()
        pictorContext.update([flight])
        pictorContext.commit()
        return flight
    }

    public func delete(flight: PictorFlightModel) {
        let pictorContext = PictorContext.new()
        pictorContext.delete([flight])
        pictorContext.commit()
    }

    public func save(gutmaOutput: [PictorGutma.Model]) {
        // Flights are never updated once created
        for gutma in gutmaOutput where flightRepository.get(byUuid: gutma.flight.uuid) == nil {
            Task {
                do {
                    var flight = gutma.flight
                    flight.title = await getTitleLocation(forFlight: gutma.flight)
                    let pictorContext = PictorContext.new()
                    pictorContext.create([flight])
                    pictorContext.create(gutma.gutmaLinks)
                    pictorContext.commit()
                }
            }
        }
    }

    public func flightPlans(flight: PictorFlightModel) -> [FlightPlanModel] {
        return gutmaLinkRepository.getRelatedFlightPlans(byFlightUuid: flight.uuid)
            .filter { $0.uuid != flightPlanRunManager.playingFlightPlan?.uuid } // Exclude flying FP
            .map { $0.flightPlanModel }
    }

    public func gutma(flight: FlightModel) -> PictorGutma? {
        if let gutma = gutmaCache.object(forKey: flight.uuid as NSString) {
            return gutma
        }
        if let data = flight.gutmaFile,
           let gutma = gutma(data: data) {
            gutmaCache.setObject(gutma, forKey: flight.uuid as NSString)
            return gutma
        }
        return nil
    }

    public func gutma(data: Data) -> PictorGutma? {
        do {
            return try JSONDecoder().decode(PictorGutma.self, from: data)
        } catch {
            // Hack for Gutma encoding issue.
            if let data = String(data: data, encoding: String.Encoding.ascii)?
                .data(using: String.Encoding.utf8) {
                return try? JSONDecoder().decode(PictorGutma.self, from: data)
            }
        }
        return nil
    }

    public func handleFlightsUnknownLocationTitle(inFlights: [FlightModel]) async {
        var modifiedFlights: [FlightModel] = []
        let flightsWithUnknownLocation = inFlights.filter({ flight in
            let flightTitle = flight.title
            return (flightTitle.isEmpty
                    && flight.startLatitude != GutmaConstants.unknownCoordinate
                    && flight.startLongitude != GutmaConstants.unknownCoordinate)
        })

        for var flightItem in flightsWithUnknownLocation {
            do {
                let locationTitle = await getTitleLocation(forFlight: flightItem)

                if !locationTitle.isEmpty {
                    flightItem.title = locationTitle
                    modifiedFlights.append(flightItem)
                }
            }
        }

        if !modifiedFlights.isEmpty {
            let pictorContext = PictorContext.new()
            pictorContext.update(modifiedFlights)
            pictorContext.commit()
        }
    }
}
