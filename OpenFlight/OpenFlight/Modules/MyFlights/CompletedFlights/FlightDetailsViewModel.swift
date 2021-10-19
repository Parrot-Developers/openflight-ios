// Copyright (C) 2021 Parrot Drones SAS
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
import CoreLocation
import GroundSdk
import MapKit

open class FlightDetailsViewModel {

    public struct FlightPlanCellModel {
        public let icon: UIImage?
        public let flightPlan: FlightPlanModel
    }

    private let service: FlightService
    private let currentDroneHolder = Services.hub.currentDroneHolder
    private var coordinator: DashboardCoordinator?
    private var cancellables = Set<AnyCancellable>()
    private var sdCardRef: Ref<RemovableUserStorage>?
    private var mediaListRef: Ref<[MediaItem]>?

    @Published private(set) var name: String?
    @Published private(set) var sdcardAvailableSpace: String = Style.dash
    @Published private(set) var memoryUsed: String = Style.dash

    open private(set) var flight: FlightModel
    public let flightPlanCells: [FlightPlanCellModel]
    /// Flight trajectory points.
    public let flightPoints: [TrajectoryPoint]
    /// Whether trajectory points altitudes are in ASML.
    public let hasAsmlAltitude: Bool

    open var shareFileName: String? {
        name
    }
    open var shareFileData: Data? {
        flight.gutmaFile?.data(using: .utf8)
    }

    var actions: [FlightDetailsActionCellModel] {
        return [FlightDetailsActionCellModel(buttonTitle: L10n.dashboardMyFlightShareFlight,
                                                    action: .share),
                FlightDetailsActionCellModel(buttonTitle: L10n.dashboardMyFlightDeleteFlight,
                                                            action: .delete)]
    }

    init(service: FlightService, flight: FlightModel, flightPlanTypeStore: FlightPlanTypeStore, coordinator: DashboardCoordinator? = nil) {
        self.service = service
        self.flight = flight
        self.coordinator = coordinator
        flightPlanCells = service.flightPlans(flight: flight).map {
            FlightPlanCellModel(icon: flightPlanTypeStore.typeForKey($0.type)?.icon, flightPlan: $0)
        }

        let gutma = Gutma.instantiate(with: flight.gutmaFile)
        flightPoints = gutma?.points() ?? []
        hasAsmlAltitude = gutma?.hasAsmlAltitude ?? false

        name = flight.title
        currentDroneHolder.dronePublisher
            .sink { [unowned self] drone in
                listenRemovableStorage(drone: drone)
            }
            .store(in: &cancellables)
        CLGeocoder().reverseGeocodeLocation(flight.location) { [weak self] (placemarks: [CLPlacemark]?, error: Error?) in
            guard let place = placemarks?.first,
                  error == nil,
                  let strongSelf = self,
                  (strongSelf.name == nil || strongSelf.name?.isEmptyOrWhitespace() == true)
            else { return }
            strongSelf.name = place.addressDescription
        }
    }
}

public extension FlightDetailsViewModel {
    /// Return flight plan models of current Flight
    var flightPlans: [FlightPlanModel] {
        service.flightPlans(flight: flight)
    }

    func set(name: String) {
        flight = service.update(flight: flight, title: name)
        self.name = flight.title
    }

    /// Delete flight.
    func deleteFlight() {
        service.delete(flight: flight)
    }

    /// Back button tapped.
    func didTapBack() {
        coordinator?.back()
    }

    /// Ask confirmation to delete flight.
    func askForDeletion() {
        coordinator?.showDeleteFlightPopupConfirmation(didTapDelete: {
            self.service.delete(flight: self.flight)
            self.coordinator?.back()
        })
     }

    /// Show details of a Flight Execution.
    func showFlightDetailsExecution(at index: Int) {
        coordinator?.startFlightExecutionDetails(flightPlans[index])
     }
}

private extension FlightDetailsViewModel {

    /// Listens removable media storage peripheral.
    func listenRemovableStorage(drone: Drone) {
        sdCardRef = drone.getPeripheral(Peripherals.removableUserStorage) { [weak self] storage in
            guard let storage = storage, storage.availableSpace >= 0 else {
                self?.sdcardAvailableSpace = Style.dash
                return
            }
            self?.sdcardAvailableSpace = StorageUtils.sizeForFile(size: UInt64(storage.availableSpace))
        }
    }
    /// Starts watcher on MediaList from mediaStore peripherial.
    func listenMedias(_ drone: Drone) {
        mediaListRef = drone.getPeripheral(Peripherals.mediaStore)?.newList { [weak self] droneMediaList in
            guard let droneMedias = droneMediaList else { return }

            self?.updateMemoryUsed(medias: droneMedias)
        }
    }

    /// Updates memory used during a flight.
    ///
    /// - Parameters:
    ///     - medias: list of drone medias
    func updateMemoryUsed(medias: [MediaItem]) {
        let correspondingMedias = medias.filter { $0.runUid == flight.uuid }
        let memoryUsedInBytes = correspondingMedias.reduce(0) {
            $0 + $1.resources.reduce(0) { $0 + $1.size }
        }
        memoryUsed = StorageUtils.sizeForFile(size: memoryUsedInBytes)
    }
}
