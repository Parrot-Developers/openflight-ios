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
import ArcGIS
import GroundSdk
import Combine

extension ULogTag {
    static let fixedLocationMonitor = ULogTag(name: "fixedLocationMonitor")
}

/// Drone location monitor.
/// Monitor drone location fix and update the AMSL reference used by the drone.
public protocol FixedLocationMonitor: AnyObject {
}

/// Implementation of `FixedLocationMonitor`.
public class FixedLocationMonitorImpl: FixedLocationMonitor {
    private var sceneView: AGSSceneView?
    private var cancellables: Set<AnyCancellable> = []
    private var currentDroneHolder: CurrentDroneHolder
    private var networkService: NetworkService
    private var drone: Drone { currentDroneHolder.drone }
    private var flyingInstrumentRef: Ref<FlyingIndicators>?

    private var droneElevation: Double?
    private var lastGpsFixed: Bool = false
    private var lastFlyingState: FlyingIndicatorsFlyingState?
    private var shouldSendRef: Bool = false
    private var droneCoordinate: CLLocationCoordinate2D?

    private var elevationLoadedCancellable: AnyCancellable?
    private var elevationSource: MapElevationSource?
    private var elevationLoaded: Bool = false
    private var amslAltitudeRequest: AGSCancelable? {
        willSet {
            if amslAltitudeRequest?.isCanceled() == false {
                amslAltitudeRequest?.cancel()
            }
        }
    }
    /// Key observer for scene loading status.
    private var sceneLoadStatusObservation: NSKeyValueObservation?

    /// Inits.
    ///
    /// - Parameters:
    ///   - currentDroneHolder: Current drone holder
    ///   - locationsTracker: Service providing drone location
    ///   - networkService: Network service
    init(currentDroneHolder: CurrentDroneHolder, locationsTracker: LocationsTracker, networkService: NetworkService) {
        self.currentDroneHolder = currentDroneHolder
        self.networkService = networkService
        locationsTracker.droneGpsFixedPublisher.sink {
            let droneGpsFixed = $0
            if self.lastGpsFixed != droneGpsFixed {
                if droneGpsFixed, self.shouldSendRef {
                    self.shouldSendRef = false
                    self.droneCoordinate = Services.hub.locationsTracker.droneLocation

                    let droneConnected = self.drone.state.connectionState == .connected

                    if droneConnected, self.droneCoordinate != nil {
                        self.sendElevationToDrone()
                    }
                }
                self.lastGpsFixed = droneGpsFixed
            }
        }
        .store(in: &cancellables)

        locationsTracker.droneAltitudePublisher(absoluteAltitude: true)
            .combineLatest(locationsTracker.droneAltitudePublisher(absoluteAltitude: false))
            .sink { [weak self] in
                self?.droneElevation = $0 - $1
        }
        .store(in: &cancellables)

        self.currentDroneHolder.dronePublisher.sink { [unowned self] drone in
            listenFlyingIndicators(drone: drone)
        }
        .store(in: &cancellables)
    }

    func listenFlyingIndicators(drone: Drone) {
        flyingInstrumentRef = drone.getInstrument(Instruments.flyingIndicators) { [weak self] intruments in
            guard let self = self else { return }
            guard let intruments = intruments else { return }

            let isDroneFlyingOrWaiting = intruments.flyingState.isFlyingOrWaiting
            self.droneCoordinate = Services.hub.locationsTracker.droneLocation
            let droneConnected = drone.state.connectionState == .connected

            if isDroneFlyingOrWaiting, self.lastFlyingState == .takingOff {
                if self.lastGpsFixed {
                    if droneConnected, self.droneCoordinate != nil {
                        self.sendElevationToDrone()
                    }
                } else {
                    self.shouldSendRef = true
                }
            }
            self.lastFlyingState = intruments.flyingState
        }
    }

    /// Set scene to get elevation
    private func setSceneIfNecessary() {
        guard sceneView == nil else {
            return
        }
        self.shouldSendRef = true
        sceneView = AGSSceneView()
        sceneView?.scene = AGSScene(basemapStyle: SettingsMapDisplayType.current.agsBasemapStyle)
        sceneView?.scene?.baseSurface?.isEnabled = true
        elevationSource = MapElevationSource(networkService: networkService)
        guard let elevationSource = elevationSource else { return }
        sceneView?.scene?.baseSurface?.elevationSources.append(elevationSource)
        listenElevation()

        sceneLoadStatusObservation = sceneView?.scene?.observe(\.loadStatus, options: .initial) { [weak self] (_, _) in
            DispatchQueue.main.async {
                self?.sceneLoadStatusChanged()
            }
        }
    }

    /// Called when load status of scene has changed.
    private func sceneLoadStatusChanged() {
        guard sceneView?.scene?.loadStatus == .loaded else { return }
        if shouldSendRef {
            sendElevationToDrone()
        }
    }

    /// Listen elevation of the ags scene view
    private func listenElevation() {
        elevationLoadedCancellable = elevationSource?.$elevationLoaded
            .prepend(true)
            .filter { $0 }
            .sink { [weak self] loadStatus in
            guard loadStatus, let self = self else { return }
            // Send altitude
            if self.shouldSendRef {
                self.sendElevationToDrone()
            }
        }
    }

    // Send the elevation to the drone.
    private func sendElevationToDrone() {
        setSceneIfNecessary()
        guard let scene = sceneView?.scene, scene.loadStatus == .loaded else { return }
        guard let droneCoordinate = self.droneCoordinate else { return }
        amslAltitudeRequest = nil
        amslAltitudeRequest = self.getElevation(coordinate: AGSPoint(clLocationCoordinate2D: droneCoordinate),
                                                     completion: { [weak self] altitude in
            self?.amslAltitudeRequest = nil
            self?.updateDroneAmslReference(altitude: altitude)
        })
    }
}

// MARK: - Private funcs
private extension FixedLocationMonitorImpl {
    /// Send AMSL reference to drone
    func updateDroneAmslReference(altitude: Double?) {
        guard let altitude = altitude, let coord = droneCoordinate else { return }
        if let terrain = drone.getPeripheral(Peripherals.terrainControl) {

            terrain.sendAmsl(elevation: altitude, latitude: coord.latitude,
                             longitude: coord.longitude)
        }
    }

    /// Get elevation terrain elevation given by ArcGIS
    func getElevation(coordinate: AGSPoint, completion: @escaping (_ altitude: Double?) -> Void) -> AGSCancelable? {
        guard let baseSurface = sceneView?.scene?.baseSurface else {
            completion(nil)
            return nil
        }

        return baseSurface.elevation(for: coordinate, completion: { [weak self] altitude, error in
            guard error == nil else {
                ULog.w(.fixedLocationMonitor, "Failed to get elevation for PGY: \(String(describing: error))")
                completion(nil)
                return
            }
            if let droneElevation = self?.droneElevation {
                let infos = [
                    "arcGisElevation": "\(altitude)",
                    "droneElevation": "\(droneElevation)"
                ]
                LogEvent.log(LogEvent.Event.sanityCheck("ground_elevation", info: infos))
                ULog.i(.fixedLocationMonitor, "ground_elevation : \(infos)")
            }
            completion(altitude)
        })
    }
}
