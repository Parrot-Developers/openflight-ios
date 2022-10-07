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

/// Summary about all flights
public struct AllFlightsSummary {
    /// Total number of flights
    public var numberOfFlights: Int
    public var totalDuration: Double
    public var totalDistance: Double
    /// Total flights duration.
    public var totalFlightsDuration: String {
        totalDuration.formattedHmsString ?? Style.dash
    }
    /// Total flights distance.
    public var totalFlightsDistance: String {
        UnitHelper.stringDistanceWithDouble(totalDistance)
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
    var numberOfFlightsPerPage: Int { get }
    var allFlightsSummary: AnyPublisher<AllFlightsSummary, Never> { get }
    var flightsDidChangePublisher: AnyPublisher<Void, Never> { get }
    func getAllFlights() -> [FlightModel]
    func getFlights(offset: Int, limit: Int) -> [FlightModel]
    func getFlights(limit: Int) -> [FlightModel]
    func getAllFlightsCount() -> Int
    func update(flight: FlightModel, title: String) -> FlightModel
    func delete(flight: FlightModel)
    func save(gutmaOutput: [Gutma.Model])
    func thumbnail(flight: FlightModel, _ completion: @escaping (UIImage?) -> Void)
    func flightPlans(flight: FlightModel) -> [FlightPlanModel]
    func gutma(flight: FlightModel) -> Gutma?
    /// Gutma from data. Bypasses cache, don't use except on first retrieval from drone
    /// - Parameter data: gutma's data
    func gutma(data: Data) -> Gutma?
    func handleFlightsUnknownLocationTitle(inFlights: [FlightModel]) async

    /// Update the Cloud Synchro Watcher.
    ///
    /// - Parameter cloudSynchroWatcher: the cloudSynchroWatcher to update
    ///
    /// - Note:
    ///     If the cloud synchro watcher service is not yet instatiated during this service's init,
    ///     this method can be called to update and configure his watcher.
    func updateCloudSynchroWatcher(_ cloudSynchroWatcher: CloudSynchroWatcher?)
}

open class FlightServiceImpl {
    private let repo: FlightRepository
    private let fpFlightRepo: FlightPlanFlightsRepository
    private let thumbnailRepo: ThumbnailRepository
    private var userService: UserService
    private var thumbnailsRequests = [String: [((UIImage?) -> Void)]]()
    private var flightsDidChangeSubject = PassthroughSubject<Void, Never>()
    private var allFlightSummarySubject = CurrentValueSubject<AllFlightsSummary, Never>(AllFlightsSummary())
    private var cancellables = Set<AnyCancellable>()
    private var gutmaCache = NSCache<NSString, Gutma>()
    private let flightPlanRunManager: FlightPlanRunManager
    private var cloudSynchroWatcher: CloudSynchroWatcher?
    public var numberOfFlightsPerPage: Int = 100

    init(repo: FlightRepository,
         fpFlightRepo: FlightPlanFlightsRepository,
         thumbnailRepo: ThumbnailRepository,
         userService: UserService,
         cloudSynchroWatcher: CloudSynchroWatcher?,
         flightPlanRunManager: FlightPlanRunManager) {
        self.repo = repo
        self.fpFlightRepo = fpFlightRepo
        self.thumbnailRepo = thumbnailRepo
        self.userService = userService
        self.flightPlanRunManager = flightPlanRunManager
        updateCloudSynchroWatcher(cloudSynchroWatcher)
        refreshAllFlightsSummary()

        userService.userEventPublisher
            .sink { [unowned self] _ in
                refreshAllFlightsSummary()
            }
            .store(in: &cancellables)

        repo.flightsDidChangePublisher
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [unowned self] in
                flightsDidChangeSubject.send()
            }.store(in: &cancellables)

        repo.flightsAddedPublisher
            .sink { [unowned self] flightsAdded in
                allFlightSummarySubject.value.addFlights(flightsAdded)
            }.store(in: &cancellables)

        repo.flightsRemovedPublisher
            .sink { [unowned self] flightsRemoved in
                allFlightSummarySubject.value.removeFlights(flightsRemoved)
            }.store(in: &cancellables)

        repo.allFlightsRemovedPublisher
            .sink { [unowned self] in
                allFlightSummarySubject.value.removeAllFlights()
            }.store(in: &cancellables)
    }

    public func updateCloudSynchroWatcher(_ cloudSynchroWatcher: CloudSynchroWatcher?) {
        self.cloudSynchroWatcher = cloudSynchroWatcher
        self.cloudSynchroWatcher?.isSynchronizingDataPublisher.sink { [unowned self] isSynchronizingData in
            if !isSynchronizingData {
                flightsDidChangeSubject.send()
                refreshAllFlightsSummary()
            }
        }.store(in: &cancellables)
    }

}

private extension FlightServiceImpl {

    enum Constants {
        static let coordinateSpan: CLLocationDegrees = 0.005
        static let lineWidth: CGFloat = 5.0
        static let thumbnailMarginRatio: Double = 0.2
        static let thumbnailSize: CGSize = CGSize(width: 180.0, height: 160.0)
    }

    func computeThumbnail(forFlight flight: FlightModel, center: CLLocationCoordinate2D) {

        let mapSnapshotterOptions = MKMapSnapshotter.Options()
        let region = MKCoordinateRegion(center: center,
                                        span: MKCoordinateSpan(latitudeDelta: Constants.coordinateSpan,
                                                               longitudeDelta: Constants.coordinateSpan))
        mapSnapshotterOptions.region = region
        mapSnapshotterOptions.mapType = .satellite
        mapSnapshotterOptions.size = Constants.thumbnailSize

        let currentUser = userService.currentUser
        let snapShotter = MKMapSnapshotter(options: mapSnapshotterOptions)
        snapShotter.start(with: DispatchQueue.main) { [unowned self] (snapshot: MKMapSnapshotter.Snapshot?, _) in
            let image = snapshot?.image
            let thumbnail = ThumbnailModel(apcId: currentUser.apcId,
                                           uuid: UUID().uuidString,
                                           flightUuid: flight.uuid,
                                           thumbnailImage: image)
            var flight = flight
            flight.thumbnail = thumbnail
            // Flight's thumbnail is not synced with the Cloud.
            // `latestLocalModificationDate` should not be set
            repo.saveOrUpdateFlight(flight, byUserUpdate: false, toSynchro: false)
        }
    }

    func getTitleLocation(forFlight flight: FlightModel) async -> String {
        let flightTitle = flight.title ?? ""

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
}

extension FlightServiceImpl: FlightService {
    public var flightsDidChangePublisher: AnyPublisher<Void, Never> {
        flightsDidChangeSubject.eraseToAnyPublisher()
    }

    public var allFlightsSummary: AnyPublisher<AllFlightsSummary, Never> {
        allFlightSummarySubject.eraseToAnyPublisher()
    }

    public func getAllFlights() -> [FlightModel] {
        repo.getAllFlights()
    }

    public func getAllFlightsCount() -> Int {
        repo.getAllFlightsCount()
    }

    public func getFlights(offset: Int, limit: Int) -> [FlightModel] {
        repo.getFlights(offset: offset, limit: limit)
    }

    public func getFlights(limit: Int) -> [FlightModel] {
        repo.getFlights(offset: 0, limit: limit)
    }

    public func refreshAllFlightsSummary() {
        let allFlight = repo.getAllFlightLites()
        var duration: Double = 0
        var distance: Double = 0
        allFlight.forEach({
            duration += $0.duration
            distance += $0.distance
        })

        allFlightSummarySubject.value = AllFlightsSummary(numberOfFlights: allFlight.count,
                                                          totalDuration: duration,
                                                          totalDistance: distance)
    }

    public func update(flight: FlightModel, title: String) -> FlightModel {
        var flight = flight
        flight.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        repo.saveOrUpdateFlight(flight,
                                byUserUpdate: true,
                                toSynchro: true,
                                withFileUploadNeeded: false)
        return flight
    }

    public func delete(flight: FlightModel) {
        repo.deleteOrFlagToDeleteFlight(withUuid: flight.uuid)
    }

    public func save(gutmaOutput: [Gutma.Model]) {
        for gutma in gutmaOutput {
            // Flights are never updated once created
            if repo.getFlight(withUuid: gutma.flight.uuid) == nil {
                Task {
                    do {
                        var flight = gutma.flight
                        flight.title = await getTitleLocation(forFlight: gutma.flight)

                        repo.saveOrUpdateFlight(flight,
                                                byUserUpdate: true,
                                                toSynchro: true,
                                                withFileUploadNeeded: true)
                        fpFlightRepo.saveOrUpdateFPlanFlights(gutma.flightPlanFlights, byUserUpdate: true, toSynchro: true)
                    }
                }
            }
        }
    }

    public func thumbnail(flight: FlightModel, _ completion: @escaping (UIImage?) -> Void) {
        if let thumbnail = flight.thumbnail {
            completion(thumbnail.thumbnailImage)
            return
        }
        let currentRequests = thumbnailsRequests[flight.uuid] ?? []
        thumbnailsRequests[flight.uuid] = currentRequests + [completion]
        if currentRequests.isEmpty {
            let center = CLLocationCoordinate2D(latitude: flight.startLatitude, longitude: flight.startLongitude)
            computeThumbnail(forFlight: flight, center: center)
        }
    }

    public func flightPlans(flight: FlightModel) -> [FlightPlanModel] {
        repo.getFlightPlans(ofFlightModel: flight)
            .filter { $0.uuid != flightPlanRunManager.playingFlightPlan?.uuid } // Exclude flying FP
    }

    public func gutma(flight: FlightModel) -> Gutma? {
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

    public func gutma(data: Data) -> Gutma? {
        do {
            return try JSONDecoder().decode(Gutma.self, from: data)
        } catch {
            // Hack for Gutma encoding issue.
            if let data = String(data: data, encoding: String.Encoding.ascii)?
                .data(using: String.Encoding.utf8) {
                return try? JSONDecoder().decode(Gutma.self, from: data)
            }
        }
        return nil
    }

    public func handleFlightsUnknownLocationTitle(inFlights: [FlightModel]) async {
        var modifiedFlights: [FlightModel] = []
        let flightsWithUnknownLocation = inFlights.filter({ flight in
            let flightTitle = flight.title ?? ""
            return (flightTitle.isEmpty && flight.startLatitude != 0 && flight.startLongitude != 0)
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
            repo.saveOrUpdateFlights(modifiedFlights, byUserUpdate: true, toSynchro: true)
        }
    }
}
