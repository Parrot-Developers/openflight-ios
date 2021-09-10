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
import MapKit

open class FlightDetailsViewModel {

    public struct FlightPlanCellModel {

        public let icon: UIImage?
        public let flightPlan: FlightPlanModel

    }

    private let service: FlightService

    @Published private(set) public var name: String?

    open private(set) var flight: FlightModel
    public let flightPlanCells: [FlightPlanCellModel]
    public let gutma: Gutma?

    open var shareFileName: String? {
        name
    }
    open var shareFileData: Data? {
        flight.gutmaFile?.data(using: .utf8)
    }

    init(service: FlightService, flight: FlightModel, flightPlanTypeStore: FlightPlanTypeStore) {
        self.service = service
        self.flight = flight
        self.flightPlanCells = service.flightPlans(flight: flight).map {
            FlightPlanCellModel(icon: flightPlanTypeStore.typeForKey($0.type)?.icon, flightPlan: $0)
        }
        gutma = Gutma.instantiate(with: flight.gutmaFile)
        name = flight.title
        CLGeocoder().reverseGeocodeLocation(flight.location) { [weak self] (placemarks: [CLPlacemark]?, error: Error?) in
            guard let place = placemarks?.first, error == nil, self?.name == nil else { return }
            self?.name = place.addressDescription
        }
    }
}

public extension FlightDetailsViewModel {
    func set(name: String) {
        flight = service.update(flight: flight, title: name)
        self.name = flight.title
    }
}
