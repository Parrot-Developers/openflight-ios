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

open class FlightTableViewCellModel {

    private let service: FlightService
    private var location: CLLocation {
        CLLocation(latitude: flight.startLatitude, longitude: flight.startLongitude)
    }

    @Published private(set) public var name: String?
    @Published private(set) var thumbnail: UIImage?

    open private(set) var flight: FlightModel

    init(service: FlightService, flight: FlightModel) {
        self.service = service
        self.flight = flight
        if let title = flight.title, !title.isEmpty {
            name = title
        } else {
            CLGeocoder().reverseGeocodeLocation(location) { [weak self] (placemarks: [CLPlacemark]?, error: Error?) in
                guard let place = placemarks?.first, error == nil, self?.name == nil else {
                    self?.name = L10n.dashboardMyFlightUnknownLocation
                    return
                }
                self?.name = place.addressDescription
            }
        }
        service.thumbnail(flight: flight) { [weak self] in
            self?.thumbnail = $0
        }
    }
}
