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
import CoreLocation
import GroundSdk
import MapKit
import Pictor

open class FlightDetailsViewModel {

    private unowned let service: FlightService
    private unowned let drone: CurrentDroneHolder
    private unowned var coordinator: FlightDetailsCoordinator?
    private var cancellables = Set<AnyCancellable>()
    private var sdCardRef: Ref<RemovableUserStorage>?

    @Published private(set) var name: String?
    @Published private(set) var sdcardAvailableSpace: String = Style.dash

    open private(set) var flight: FlightModel
    /// Flight trajectory points.
    public let flightPoints: [TrajectoryPoint]
    /// Whether trajectory points altitudes are in AMSL.
    public let hasAmslAltitude: Bool

    open var shareFileName: String? {
        name
    }
    open var shareFileData: Data? {
        flight.gutmaFile
    }

    var actions: [FlightDetailsActionCellModel] {
        return [FlightDetailsActionCellModel(buttonTitle: L10n.dashboardMyFlightShareFlight,
                                                    action: .share),
                FlightDetailsActionCellModel(buttonTitle: L10n.dashboardMyFlightDeleteFlight,
                                                            action: .delete)]
    }

    init(service: FlightService,
         flight: FlightModel,
         drone: CurrentDroneHolder,
         coordinator: FlightDetailsCoordinator? = nil) {
        self.service = service
        self.flight = flight
        self.drone = drone
        self.coordinator = coordinator

        let gutma = service.gutma(flight: flight)
        flightPoints = gutma?.points() ?? []
        hasAmslAltitude = gutma?.hasAmslAltitude ?? false

        name = flight.title
        drone.dronePublisher
            .sink { [unowned self] drone in
                listenRemovableStorage(drone: drone)
            }
            .store(in: &cancellables)
        if let name = name, name.isEmptyOrWhitespace {
            CLGeocoder().reverseGeocodeLocation(flight.location) { [weak self] (placemarks: [CLPlacemark]?, error: Error?) in
                guard let place = placemarks?.first, error == nil,
                      let strongSelf = self,
                      let addressDescription = place.addressDescription else {
                    return
                }
                strongSelf.name = addressDescription
                self?.flight = service.update(flight: flight, title: addressDescription)
            }
        }
    }
}

public extension FlightDetailsViewModel {
    func set(name: String) {
        flight = service.update(flight: flight, title: name)
        self.name = flight.title
    }

    /// Back button tapped.
    func didTapBack() {
        coordinator?.dismissDetails()
    }

    /// Ask confirmation to delete flight.
    func askForDeletion() {
        coordinator?.showDeleteFlightPopupConfirmation(didTapDelete: {
            self.service.delete(flight: self.flight)
            self.coordinator?.dismissDetails()
        })
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
}
