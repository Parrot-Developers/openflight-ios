//
//  Copyright (C) 2021 Parrot Drones SAS.
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
}

public protocol FlightService: AnyObject {

    var lastFlight: AnyPublisher<FlightModel?, Never> { get }
    var allFlights: AnyPublisher<[FlightModel], Never> { get }
    var allFlightsSummary: AnyPublisher<AllFlightsSummary, Never> { get }
    var allFlightsCount: Int { get }
    func update(flight: FlightModel, title: String) -> FlightModel
    func delete(flight: FlightModel)
    func save(gutmaOutput: [Gutma.Model])
    func thumbnail(flight: FlightModel, _ completion: @escaping (UIImage?) -> Void)
    func flightPlans(flight: FlightModel) -> [FlightPlanModel]
}

open class FlightServiceImpl {
    private let repo: FlightRepository
    private let fpFlightRepo: FlightPlanFlightsRepository
    private let thumbnailRepo: ThumbnailRepository
    private var userInformation: UserInformation
    private var thumbnailsRequests = [String: [((UIImage?) -> Void)]]()
    private var allFlightsSubject = CurrentValueSubject<[FlightModel], Never>([])

    init(repo: FlightRepository,
         fpFlightRepo: FlightPlanFlightsRepository,
         thumbnailRepo: ThumbnailRepository,
         userInformation: UserInformation) {
        self.repo = repo
        self.fpFlightRepo = fpFlightRepo
        self.thumbnailRepo = thumbnailRepo
        self.userInformation = userInformation
        updateFlights()
    }
}

private extension FlightServiceImpl {

    enum Constants {
        static let coordinateSpan: CLLocationDegrees = 0.005
        static let lineWidth: CGFloat = 5.0
        static let thumbnailMarginRatio: Double = 0.2
        static let thumbnailSize: CGSize = CGSize(width: 180.0, height: 160.0)
    }

    func updateFlights() {
        allFlightsSubject.value = repo.loadAllFlights()
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
                                           thumbnailImage: image,
                                           flightUuid: uuid)
            thumbnailRepo.persist(thumbnail, true)
            thumbnailsRequests[uuid]?.forEach { $0(image) }
            thumbnailsRequests[uuid] = []
        }
    }
}

extension FlightServiceImpl: FlightService {
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
                let distance = Double(flights.reduce(0) { $0 + $1.distance })
                let totalFlightsDistance = UnitHelper.stringDistanceWithDouble(distance)
                let duration = Double(flights.reduce(0) { $0 + $1.duration })
                let totalFlightsDuration = duration.formattedHmsString ?? Style.dash
                return AllFlightsSummary(numberOfFlights: numberOfFlights,
                                         totalFlightsDuration: totalFlightsDuration,
                                         totalFlightsDistance: totalFlightsDistance)
            }
            .eraseToAnyPublisher()
    }

    public var allFlights: AnyPublisher<[FlightModel], Never> {
        allFlightsSubject.eraseToAnyPublisher()
    }

    public func update(flight: FlightModel, title: String) -> FlightModel {
        var flight = flight
        flight.title = title
        repo.persist(flight, true)
        updateFlights()
        return flight
    }

    public func delete(flight: FlightModel) {
        repo.removeFlight(flight.uuid)
        updateFlights()
    }

    public func save(gutmaOutput: [Gutma.Model]) {
        for flight in gutmaOutput {
            // Flights are never updated once created
            guard repo.loadFlight(flight.flight.uuid) == nil else { return }
            repo.persist(flight.flight, true)
            for fpFlight in flight.flightPlanFlights {
                fpFlightRepo.persist(fpFlight, true)
            }
        }
        updateFlights()
    }

    public func thumbnail(flight: FlightModel, _ completion: @escaping (UIImage?) -> Void) {
        if let thumbnail = thumbnailRepo.thumbnail(for: flight) {
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
        repo.loadFlightPlans(for: flight)
    }
}
