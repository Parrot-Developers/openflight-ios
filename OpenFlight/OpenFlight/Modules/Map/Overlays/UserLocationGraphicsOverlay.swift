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

import ArcGIS
import GroundSdk
import CoreLocation
import Combine

private extension ULogTag {
    static let tag = ULogTag(name: "UserLocationGraphicsOverlay")
}

/// User location overlay.
public final class UserLocationGraphicsOverlay: CommonGraphicsOverlay {

    static let Key = "UserLocationGraphicsOverlayKey"

    // MARK: - Private Properties
    private var userGraphic: FlightPlanUserLocationGraphic?

    // MARK: - Public Properties
    public var viewModel = UserLocationGraphicsOverlayViewModel()

    // MARK: - Override Funcs
    override public init() {
        super.init()
        isActive.value = true
        viewModel.userLocationPublisher
            .sink { [weak self] userLocation in
                self?.update(location: userLocation)
            }
            .store(in: &cancellables)

        viewModel.isMiniMapPublisher.removeDuplicates()
            .sink { [weak self] isMiniMap in
                self?.userGraphic?.setReduced(isMiniMap)
            }
            .store(in: &cancellables)
    }

    // MARK: - Private Funcs
    /// Update the location of the agsGraphic
    ///
    /// - Parameter location : the new location
    private func update(location: OrientedLocation) {
        guard let location2D = location.coordinates?.coordinate else { return }
        let geometry = AGSPoint(clLocationCoordinate2D: location2D)

        if let userGraphic = userGraphic {
            userGraphic.geometry = geometry
        } else {
            // create graphic for user location, if it does not exist
            let attributes = ["type": "userLocation"]
            userGraphic = FlightPlanUserLocationGraphic(geometry: geometry, attributes: attributes)
            userGraphic?.setReduced(viewModel.isMiniMap.value)
            if let userGraphic = userGraphic {
                graphics.add(userGraphic)
            }
        }
    }
}
