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
    public let numberOfFlights: Int
    /// Total flights duration.
    public let totalFlightsDuration: String
    /// Total flights distance.
    public let totalFlightsDistance: String

    /// Init
    public init(numberOfFlights: Int = 0,
                totalDuration: Double = 0,
                totalDistance: Double = 0) {
        self.numberOfFlights = numberOfFlights
        self.totalFlightsDuration = totalDuration.formattedHmsString ?? Style.dash
        self.totalFlightsDistance = UnitHelper.stringDistanceWithDouble(totalDistance)
    }

    /// `AllFlightsSummary`'s default values
    public static let defaultValues = AllFlightsSummary()
}

public protocol FlightService: AnyObject {

    var lastFlight: AnyPublisher<FlightModel?, Never> { get }
    var allFlights: AnyPublisher<[FlightModel], Never> { get }
    var allFlightsSummary: AnyPublisher<AllFlightsSummary, Never> { get }
    var allFlightsCount: Int { get }
    var flightsDidChange: AnyPublisher<Void, Never> { get }
    func updateFlights()
    func update(flight: FlightModel, title: String) -> FlightModel
    func delete(flight: FlightModel)
    func save(gutmaOutput: [Gutma.Model])
    func thumbnail(flight: FlightModel, _ completion: @escaping (UIImage?) -> Void)
    func flightPlans(flight: FlightModel) -> [FlightPlanModel]
    func gutma(flight: FlightModel) -> Gutma?
    /// Gutma from data. Bypasses cache, don't use except on first retrieval from drone
    /// - Parameter data: gutma's data
    func gutma(data: Data) -> Gutma?
    func handleFlightsUnknownLocationTitle() async
}

open class FlightServiceImpl {
    private let repo: FlightRepository
    private let fpFlightRepo: FlightPlanFlightsRepository
    private let thumbnailRepo: ThumbnailRepository
    private var userInformation: UserInformation
    private var thumbnailsRequests = [String: [((UIImage?) -> Void)]]()
    private var allFlightsSubject = CurrentValueSubject<[FlightModel], Never>([])
    private var cancellable = Set<AnyCancellable>()
    private var gutmaCache = NSCache<NSString, Gutma>()
    private let flightPlanRunManager: FlightPlanRunManager

    init(repo: FlightRepository,
         fpFlightRepo: FlightPlanFlightsRepository,
         thumbnailRepo: ThumbnailRepository,
         userInformation: UserInformation,
         cloudSynchroWatcher: CloudSynchroWatcher?,
         flightPlanRunManager: FlightPlanRunManager) {
        self.repo = repo
        self.fpFlightRepo = fpFlightRepo
        self.thumbnailRepo = thumbnailRepo
        self.userInformation = userInformation
        self.flightPlanRunManager = flightPlanRunManager
        updateFlights()
        cloudSynchroWatcher?.isSynchronizingDataPublisher.sink { isSynchronizingData in
            if !isSynchronizingData {
                self.updateFlights()
            }
        }.store(in: &cancellable)
        repo.flightsDidChangePublisher.sink {
            self.updateFlights()
        }.store(in: &cancellable)
    }
}

private extension FlightServiceImpl {

    enum Constants {
        static let coordinateSpan: CLLocationDegrees = 0.005
        static let lineWidth: CGFloat = 5.0
        static let thumbnailMarginRatio: Double = 0.2
        static let thumbnailSize: CGSize = CGSize(width: 180.0, height: 160.0)
    }

    func computeThumbnail(uuid: String, center: CLLocationCoordinate2D) {

        let mapSnapshotterOptions = MKMapSnapshotter.Options()
        let region = MKCoordinateRegion(center: center,
                                        span: MKCoordinateSpan(latitudeDelta: Constants.coordinateSpan,
                                                               longitudeDelta: Constants.coordinateSpan))
        mapSnapshotterOptions.region = region
        mapSnapshotterOptions.mapType = .satellite
        mapSnapshotterOptions.size = Constants.thumbnailSize

        let snapShotter = MKMapSnapshotter(options: mapSnapshotterOptions)
        snapShotter.start(with: DispatchQueue.main) { [unowned self] (snapshot: MKMapSnapshotter.Snapshot?, _) in
            let image = snapshot?.image
            let thumbnail = ThumbnailModel(apcId: userInformation.apcId,
                                           uuid: UUID().uuidString,
                                           flightUuid: uuid,
                                           thumbnailImage: image)
            // Flight's thumbnail is not synced with the Cloud.
            // `latestLocalModificationDate` should not be set
            thumbnailRepo.saveOrUpdateThumbnail(thumbnail, byUserUpdate: false, toSynchro: false)
            thumbnailsRequests[uuid]?.forEach { $0(image) }
            thumbnailsRequests[uuid] = []
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
}

extension FlightServiceImpl: FlightService {
    public func updateFlights() {
        allFlightsSubject.value = repo.getAllFlights()
    }

    public var allFlightsCount: Int {
        allFlightsSubject.value.count
    }

    public var lastFlight: AnyPublisher<FlightModel?, Never> {
        allFlights.map { $0.first }.eraseToAnyPublisher()
    }

    public var allFlightsSummary: AnyPublisher<AllFlightsSummary, Never> {
        allFlights
            .map { flights in
                let numberOfFlights = flights.count
                let duration = Double(flights.reduce(0) { $0 + $1.duration })
                let distance = Double(flights.reduce(0) { $0 + $1.distance })
                return AllFlightsSummary(numberOfFlights: numberOfFlights,
                                         totalDuration: duration,
                                         totalDistance: distance)
            }
            .eraseToAnyPublisher()
    }

    public var allFlights: AnyPublisher<[FlightModel], Never> {
        allFlightsSubject.eraseToAnyPublisher()
    }

    public var flightsDidChange: AnyPublisher<Void, Never> {
        repo.flightsDidChangePublisher.eraseToAnyPublisher()
    }

    public func update(flight: FlightModel, title: String) -> FlightModel {
        var flight = flight
        flight.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        repo.saveOrUpdateFlight(flight,
                                byUserUpdate: true,
                                toSynchro: true,
                                withFileUploadNeeded: false)
        updateFlights()
        return flight
    }

    public func delete(flight: FlightModel) {
        repo.deleteOrFlagToDeleteFlight(withUuid: flight.uuid)
        updateFlights()
    }

    public func save(gutmaOutput: [Gutma.Model]) {
        var shouldUpdateFlights = true

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
            } else {
                shouldUpdateFlights = false
                break
            }
        }

        if shouldUpdateFlights {
            updateFlights()
        }
    }

    public func thumbnail(flight: FlightModel, _ completion: @escaping (UIImage?) -> Void) {
        if let thumbnail = thumbnailRepo.getThumbnail(withFlightUuid: flight.uuid) {
            completion(thumbnail.thumbnailImage)
            return
        }
        let currentRequests = thumbnailsRequests[flight.uuid] ?? []
        thumbnailsRequests[flight.uuid] = currentRequests + [completion]
        if currentRequests.isEmpty {
            let center = CLLocationCoordinate2D(latitude: flight.startLatitude, longitude: flight.startLongitude)
            computeThumbnail(uuid: flight.uuid, center: center)
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

    public func handleFlightsUnknownLocationTitle() async {
        var modifiedFlights: [FlightModel] = []
        let flightsWithUnknownLocation = allFlightsSubject.value.filter({ flight in
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
