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
import Combine

class FlightsViewModel {
    /// The publisher for data reloading (in case of flights update).
    var needReloadDataPublisher: AnyPublisher<Void, Never> { needReloadDataSubject.eraseToAnyPublisher() }
    /// The flight UUIDs publisher.
    var flightUuidsPublisher: AnyPublisher<[String], Never> { flightUuidsSubject.eraseToAnyPublisher() }
    /// The flight UUIDs.
    private(set) var flightUuids: [String] {
        get { flightUuidsSubject.value }
        set { flightUuidsSubject.value = newValue }
    }
    /// The selected flight's UUID (if any).
    var selectedFlightIdPublisher: AnyPublisher<String?, Never> { selectedFlightIdSubject.eraseToAnyPublisher() }

    // MARK: - Private
    private let service: FlightService
    private let thumbnailGeneratorService: ThumbnailGeneratorService
    private let navigationStack: NavigationStackService
    private weak var coordinator: MyFlightsCoordinator?

    /// The flight UUIDs subject.
    private var flightUuidsSubject = CurrentValueSubject<[String], Never>([])
    /// The selected flight's UUID subject.
    private var selectedFlightIdSubject = CurrentValueSubject<String?, Never>(nil)
    /// The selected flight's UUID.
    private var selectedFlightId: String? {
        get { selectedFlightIdSubject.value }
        set { selectedFlightIdSubject.value = newValue }
    }
    private var needReloadDataSubject = PassthroughSubject<Void, Never>()

    private var currentOffset: Int = 0
    private var cancellable = Set<AnyCancellable>()
    private enum Constants {
        static let numberOfFlightsPerPage: Int = 100
    }

    init(service: FlightService,
         thumbnailGeneratorService: ThumbnailGeneratorService,
         coordinator: MyFlightsCoordinator,
         navigationStack: NavigationStackService) {
        self.service = service
        self.thumbnailGeneratorService = thumbnailGeneratorService
        self.coordinator = coordinator
        self.navigationStack = navigationStack
        self.flightUuids = service.getFlights(count: Constants.numberOfFlightsPerPage).map { $0.uuid }

        Services.hub.synchroService.statusPublisher
            .sink { [weak self] in
                // Ensure there is no sync on-going.
                guard let self = self, !$0.isSyncing  else { return }
                Task {
                    // Request empty title flights models only.
                    let emptyTitleFlights = self.flightModels(from: self.flightUuids).filter { $0.title.isEmpty }
                    await self.service.handleFlightsUnknownLocationTitle(inFlights: emptyTitleFlights)
                }
            }
            .store(in: &cancellable)

        service.flightsDidCreatePublisher
            .merge(with: service.flightsDidDeletePublisher)
            .sink { [weak self] _ in
                self?.refreshAllFlights()
            }
            .store(in: &cancellable)

        service.flightsDidUpdatePublisher
            .sink { [weak self] _ in
                self?.needReloadDataSubject.send()
            }
            .store(in: &cancellable)

    }

    func getSelectedFlightIndex() -> Int? {
        guard let uuid = selectedFlightId else { return nil }
        return flightUuids.firstIndex(where: { $0 == uuid })
    }

    func didTapOn(indexPath: IndexPath) {
        guard indexPath.row < flightUuids.count,
              let flight = service.getFlight(byUuid: flightUuids[indexPath.row])
        else { return }
        navigationStack.updateLast(with: .myFlights(selectedFlight: flight))
        coordinator?.startFlightDetails(flight: flight)
        didSelectFlight(flight)
    }

    func askForDeletion(forIndexPath indexPath: IndexPath) {
        guard indexPath.row < flightUuids.count,
              let flight = service.getFlight(byUuid: flightUuids[indexPath.row])
        else { return }
        coordinator?.showDeleteFlightPopupConfirmation(didTapDelete: { [weak self] in
            self?.service.delete(flight: flight)
        })
    }

    func didSelectFlight(_ flight: FlightModel) {
        selectedFlightId = flight.uuid
    }

    /// Returns a flight table view cell model for a specific flight details information item.
    ///
    /// - Parameter uuid: the flight uuid
    /// - Returns: the corresponding flight table view cell model
    func cellViewModel(for uuid: String) -> FlightTableViewCellModel? {
        guard let flight = service.getFlight(byUuid: uuid) else { return nil}

        let title = flight.title.isEmpty ? L10n.dashboardMyFlightUnknownLocation : flight.title
        let startTime = flight.startTime
        let formattedDate = flight.shortFormattedDate
        let formattedDuration = flight.shortFormattedDuration
        let photoCount = flight.photoCount
        let videoCount = flight.videoCount
        var thumbnail = Asset.MyFlights.mapPlaceHolder.image
        if let flightThumbnail = flight.thumbnail, flight.isLocationValid {
            thumbnail = flightThumbnail.image
        }
        return FlightTableViewCellModel(title: title,
                                        startTime: startTime,
                                        formattedDate: formattedDate,
                                        formattedDuration: formattedDuration,
                                        photoCount: photoCount,
                                        videoCount: videoCount,
                                        thumbnail: thumbnail,
                                        isSelected: uuid == selectedFlightId)
    }

    func getMoreFlights() {
        let allFlightsCount = service.getAllFlightsCount()
        guard flightUuids.count < allFlightsCount else {
            return
        }
        let moreFlightsUuids = service.getFlights(offset: flightUuids.count, count: Constants.numberOfFlightsPerPage)
            .map { $0.uuid }
        flightUuids.append(contentsOf: moreFlightsUuids)
    }

    func refreshAllFlights() {
        flightUuids = service.getFlights(count: flightUuids.count).map { $0.uuid }
    }

    func getThumbnails(forIndexPaths indexPaths: [IndexPath]) {
        let uuids = indexPaths
            .compactMap { flightUuids[$0.row] }
        let flightModels = flightModels(from: uuids)
            .filter { $0.thumbnail == nil }
        thumbnailGeneratorService.generate(for: flightModels)
    }
}

// MARK: - Helpers
private extension FlightsViewModel {

    /// Gathers from flight service the `FlightModel` array corresponding the a specific `FlightDetailsInfo` array.
    ///
    /// - Parameter infos: the flight details information array to build the flight models array from
    /// - Returns: the corresponding flight models array
    func flightModels(from uuids: [String]) -> [FlightModel] {
        service.getFlights(byUuids: uuids)
    }
}
