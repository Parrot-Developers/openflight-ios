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

import Foundation

import Combine
import ArcGIS
import GroundSdk

/// ViewModel for `DroneLocationGraphicsOverlay`
public class DroneLocationGraphicsOverlayViewModel {
    // MARK: Private Properties
    /// Combine cancellables
    private var cancellables = Set<AnyCancellable>()
    private let locationsTracker: LocationsTracker
    private var droneConnectionStateSubject = CurrentValueSubject<Bool, Never>(false)
    private var droneModelSceneSymbolWithGPS = AGSModelSceneSymbol(name: "Drone3DOK", extension: "dae", scale: 1)
    private let droneModelSceneSymbolNoGPS = AGSModelSceneSymbol(name: "Drone3DKO", extension: "dae", scale: 1)

    /// Whether the drone location is displayed in a scene or a map.

    public var droneIconSubject = CurrentValueSubject<AssetImageTypeAlias?, Never>(nil)
    public var droneIconSubject3D = CurrentValueSubject<AGSModelSceneSymbol?, Never>(nil)

    // MARK: Public Properties
    /// Drone location publisher
    public var droneLocationPublisher: AnyPublisher<OrientedLocation, Never> { locationsTracker.droneAbsoluteLocationPublisher }
    public var droneIconPublisher: AnyPublisher<AssetImageTypeAlias?, Never> { droneIconSubject.eraseToAnyPublisher() }
    public var droneIcon3DPublisher: AnyPublisher<AGSModelSceneSymbol?, Never> { droneIconSubject3D.eraseToAnyPublisher() }

    public var isMiniMapPublisher: AnyPublisher<Bool, Never> { isMiniMap.eraseToAnyPublisher() }
    public var isMiniMap = CurrentValueSubject<Bool, Never>(false)

    public var isScenePublisher: AnyPublisher<Bool, Never> { isScene.eraseToAnyPublisher() }
    public var isScene = CurrentValueSubject<Bool, Never>(false)

    /// Drone connection state publisher
    public var droneConnectionStatePublisher: AnyPublisher<Bool, Never> {
        droneConnectionStateSubject.eraseToAnyPublisher() }
    public var droneLocation: OrientedLocation {
        locationsTracker.droneLocation
    }
    /// Reference to GPS Instrument
    private var gpsRef: Ref<Gps>?

    /// Init
    /// - Parameters:
    ///  - networkService: the network service
    init(connectedDroneHolder: ConnectedDroneHolder, locationsTracker: LocationsTracker) {
        self.locationsTracker = locationsTracker

        connectedDroneHolder.dronePublisher
            .sink { [weak self] drone in
                guard let self = self else { return }
                self.droneConnectionStateSubject.value = drone != nil
                self.listenGps(drone: drone)
            }
            .store(in: &cancellables)

    }

    /// Starts observing changes for gps strength and updates the gps Strength published property.
    ///
    /// - Parameter drone: the current drone
    func listenGps(drone: Drone?) {
        guard let drone = drone else {
            updateDroneIcon(gps: .none)
            return
        }
        gpsRef = drone.getInstrument(Instruments.gps) { [weak self] gps in
            self?.updateDroneIcon(gps: gps?.gpsStrength ?? .none)
        }
    }

    /// Updates drone icon according to its gps strength
    ///
    /// - Parameter gps: the current gps strength
    func updateDroneIcon(gps: GpsStrength) {
        if !isScene.value {
            droneIconSubject3D.value = nil
            droneIconSubject.value = (gps == .none || gps == .notFixed)
            ? (isMiniMap.value ? Asset.Map.mapDroneDisconnectedMiniMap.image: Asset.Map.mapDroneDisconnected.image )
            : (isMiniMap.value ? Asset.Map.mapDroneMiniMap.image : Asset.Map.mapDrone.image)
        } else {
            droneIconSubject.value = nil
            droneIconSubject3D.value = (gps == .none || gps == .notFixed) ? droneModelSceneSymbolNoGPS : droneModelSceneSymbolWithGPS
        }
    }

    /// Updates the value of isMiniMap
    ///
    /// - Parameter isMiniMap: the new value of isMiniMap
    func update(isMiniMap: Bool) {
        self.isMiniMap.value = isMiniMap
        updateDroneIcon(gps: gpsRef?.value?.gpsStrength ?? .none)
    }
}
