//    Copyright (C) 2023 Parrot Drones SAS
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

import CoreLocation
import Combine
import GroundSdk

/// View model for `HomeStreamView`
class HomeStreamViewModel {
    private let locationsTracker: LocationsTracker = Services.hub.locationsTracker
    private let connectedDroneHolder: ConnectedDroneHolder = Services.hub.connectedDroneHolder
    private let rthService: RthService = Services.hub.drone.rthService
    private var altimeterInstrumentRef: Ref<Altimeter>?
    private var altimeterSubject = CurrentValueSubject<Altimeter?, Never>(nil)
    private let lic = SdkCoreLic()
    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()
    /// Current home location.
    private var homeDestination: RthService.ReturnHomeDestination?
    /// True if curent home indicator state is hidden.
    private var isHidden: Bool = false

    /// The home position in the stream.
    @Published private(set) var homePosition: CGPoint?
    /// The home indicator state.
    @Published private(set) var homeImage: UIImage?

    // MARK: - Init
    init() {
        rthService.homeDestinationPublisher
            .removeDuplicates { return $0?.location == $1?.location && $0?.target == $1?.target }
            .combineLatest(rthService.homeIndicatorStatePublisher.removeDuplicates(),
                           altimeterSubject.compactMap { $0 })
            .sink { [weak self] homeDestination, indicatorState, altimeter in
                guard let self = self else { return }

                self.homeImage = indicatorState.image(size: .regular)
                self.isHidden = indicatorState == .hidden

                // Don't need to recalculate the altitude if homeDestination is same
                if self.homeDestination?.location.coordinate == homeDestination?.location.coordinate &&
                    self.homeDestination?.target == homeDestination?.target {
                    return
                }

                self.homeDestination = homeDestination

                if let coordinates = self.homeDestination?.location.coordinate,
                   let altitude = self.homeDestination?.location.altitude,
                   CLLocationCoordinate2DIsValid(coordinates) {
                    // When target is Take off position, the location altitude is the take off altitude, so near 0, not relevant.
                    // We need to calculate the altitude based on the drone amsl altitude
                    if self.homeDestination?.target == .takeOffPosition || altitude == 0.0 {
                        let takeOffAltitudeDrone = altimeter.takeoffRelativeAltitude ?? 0
                        let absoluteAltitudeDrone = altimeter.absoluteAltitude ?? 0
                        self.homeDestination?.location.altitude = absoluteAltitudeDrone - takeOffAltitudeDrone
                    }
                }
            }
            .store(in: &cancellables)

        connectedDroneHolder.dronePublisher
            .sink { [weak self] drone in
                guard let self = self, let drone = drone else { return }
                self.altimeterInstrumentRef = drone.getInstrument(Instruments.altimeter) { altimeter in
                    self.altimeterSubject.send(altimeter)
                }
            }
            .store(in: &cancellables)
    }

    /// frame metadata update
    ///
    /// Called by `HUDCameraStreamingViewController for each frame update of the stream view.
    /// The metatdata is used by `liblic` to convert positions and geolocations in the stream.
    /// - Parameters:
    ///   - mediaInfoHandle: `Overlayer` context data used by liblic
    ///   - metadataHandle: `Overlayer` context data used by liblic
    func frameUpdate(mediaInfoHandle: UnsafeRawPointer?, metadataHandle: UnsafeRawPointer?) {
        guard !isHidden else {
            homePosition = nil
            return
        }
        lic.update(mediaInfo: mediaInfoHandle, metadata: metadataHandle)
        if let coordinates = homeDestination?.location.coordinate,
           let altitude = homeDestination?.location.altitude,
           CLLocationCoordinate2DIsValid(coordinates) {
            do {
                let newLocation = CLLocation(coordinate: coordinates,
                                             altitude: altitude,
                                             horizontalAccuracy: 0, verticalAccuracy: 0, timestamp: Date())
                let position = try lic.position(from: newLocation)
                if position.x.isFinite && position.y.isFinite {
                    homePosition = CGPoint(x: position.x, y: position.y)
                } else {
                    homePosition = nil
                }
            } catch {
                // home position is not on screen
                homePosition = nil
            }
        } else {
            // no valid coordinates for home
            homePosition = nil
        }
    }
}
