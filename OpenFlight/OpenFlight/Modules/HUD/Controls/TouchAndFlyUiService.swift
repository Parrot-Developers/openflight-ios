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

import UIKit
import SwiftyUserDefaults
import Combine
import ArcGIS

public protocol TouchAndFlyUiService: CustomHUDControls {
    var didTapTargetWhileEditingEvent: AnyPublisher<Bool, Never> { get }
    func set(editing: Bool)
    var commonMapViewController: TouchAndFlyMapViewController? { get set }
}

/// Class that manages Touch and Fly related UI on HUD.
class TouchAndFlyUiServiceImpl {
    // MARK: - Private Properties
    private let service: TouchAndFlyService
    private let locations: LocationsTracker
    private let currentMissionManager: CurrentMissionManager
    private var cancellables = Set<AnyCancellable>()
    private var editing = false
    private var lastDroneLocation: CLLocation?
    private var draggingStartPoint: CLLocationCoordinate2D?
    private var didTapTargetWhileEditingSubject = PassthroughSubject<Bool, Never>()
    private weak var mapViewController: TouchAndFlyMapViewController?

    init(service: TouchAndFlyService,
         locations: LocationsTracker,
         currentMissionManager: CurrentMissionManager) {
        self.service = service
        self.locations = locations
        self.currentMissionManager = currentMissionManager
    }

    private func shouldHandleGesture() -> Bool {
        guard currentMissionManager.mode.key == MissionsConstants.classicMissionTouchAndFlyKey else { return false }
        switch service.runningState {
        case .noTarget(droneConnected: let droneConnected):
            return droneConnected
        case .running, .ready:
            return true
        case .blocked(let issue):
            return issue != .droneNotConnected
        }
    }
}

// MARK: - TouchAndFlyUiService conformance
extension TouchAndFlyUiServiceImpl: TouchAndFlyUiService {
    var commonMapViewController: TouchAndFlyMapViewController? {
        get {
            return mapViewController
        }
        set {
            mapViewController = newValue
        }
    }

    func set(editing: Bool) {
        self.editing = editing
    }

    var didTapTargetWhileEditingEvent: AnyPublisher<Bool, Never> { didTapTargetWhileEditingSubject.eraseToAnyPublisher() }
}

// MARK: - CustomHUDControls conformance
extension TouchAndFlyUiServiceImpl {
    /// Starts Touch and Fly controls.
    func start() {
        editing = false
        cancellables = []

        service.targetPublisher
            .removeDuplicates()
            .combineLatest(locations.droneLocationPublisher.removeDuplicates())
            .sink { [weak self] (target, droneOrientedLocation) in
                guard let self = self, self.draggingStartPoint == nil else { return }

                if let droneCoordinates = droneOrientedLocation.coordinates?.coordinate {
                    self.lastDroneLocation = CLLocation(latitude: droneCoordinates.latitude, longitude: droneCoordinates.longitude)
                }
                if target == .none {
                    self.commonMapViewController?.touchAndFlyOverlay?.viewModel.clearTouchAndFly()
                }
                self.display(target: target)
            }
            .store(in: &cancellables)
    }

    private func display(target: TouchAndFlyTarget) {
        switch target {
        case .none:
            return
        case .wayPoint(location: let location, altitude: let altitude, _):
            commonMapViewController?.touchAndFlyOverlay?.viewModel.displayWayPoint(at: Location3D(coordinate: location, altitude: altitude))
        case .poi(location: let location, altitude: let altitude):
            commonMapViewController?.touchAndFlyOverlay?.viewModel.displayPoiPoint(at: Location3D(coordinate: location, altitude: altitude))
        }
    }

    private func containsTarget(identifyResult: AGSIdentifyGraphicsOverlayResult?) -> Bool {
        return identifyResult?.selectedWayPoint != nil || identifyResult?.selectedPoiPoint != nil
    }

    private func handleTapIdentifyResult(identifyResult: AGSIdentifyGraphicsOverlayResult?) -> Bool {
        if editing, containsTarget(identifyResult: identifyResult) {
            didTapTargetWhileEditingSubject.send(true)
            return true
        }
        return false
    }

    private func dragResult(location: CLLocationCoordinate2D) -> TouchAndFlyTarget {
        guard let start = draggingStartPoint else { return .none }
        let offsetLatitude = location.latitude - start.latitude
        let offsetLongitude = location.longitude - start.longitude
        switch service.target {
        case .none:
            return .none
        case .wayPoint(location: let location, altitude: let altitude, speed: let speed):
            let newLocation = CLLocationCoordinate2D(latitude: location.latitude + offsetLatitude,
                                                     longitude: location.longitude + offsetLongitude)
            return .wayPoint(location: newLocation, altitude: altitude, speed: speed)
        case .poi(location: let location, altitude: let altitude):
            let newLocation = CLLocationCoordinate2D(latitude: location.latitude + offsetLatitude,
                                                     longitude: location.longitude + offsetLongitude)
            return .poi(location: newLocation, altitude: altitude)
        }
    }

    func handleCustomMapTap(mapPoint: AGSPoint, identifyResult: AGSIdentifyGraphicsOverlayResult?) {
        guard shouldHandleGesture(), !handleTapIdentifyResult(identifyResult: identifyResult) else { return }
        let location = mapPoint.toCLLocationCoordinate2D()

        if case .wayPoint = service.target {
            // There is already a WP on map => move it.
            service.moveWayPoint(to: location, altitude: nil)
        } else {
            // No active WP on map => create new WP.
            service.setWayPoint(location, altitude: nil)
        }
    }

    func handleCustomMapLongPress(mapPoint: AGSPoint, identifyResult: AGSIdentifyGraphicsOverlayResult?) {
        guard shouldHandleGesture(), !handleTapIdentifyResult(identifyResult: identifyResult) else { return }
        let location = mapPoint.toCLLocationCoordinate2D()

        if case .poi = service.target {
            // There is already a POI on map => move it.
            service.movePoi(to: location, altitude: nil)
        } else {
            // No active POI on map => create new POI.
            service.setPoi(location, altitude: nil)
        }
    }

    func handleCustomMapTouchDown(mapPoint: AGSPoint, identifyResult: AGSIdentifyGraphicsOverlayResult?, completion: @escaping (Bool) -> Void) {

        guard shouldHandleGesture(), containsTarget(identifyResult: identifyResult) else {
            completion(false)
            return
        }
        draggingStartPoint = mapPoint.toCLLocationCoordinate2D()
        completion(true)
    }

    func handleCustomMapDrag(mapPoint: AGSPoint) {
        guard shouldHandleGesture() else { return }
        display(target: dragResult(location: mapPoint.toCLLocationCoordinate2D()))
    }

    func handleCustomMapTouchUp(mapPoint: AGSPoint) {
        guard shouldHandleGesture() else { return }
        let newTarget = dragResult(location: mapPoint.toCLLocationCoordinate2D())
        draggingStartPoint = nil
        switch newTarget {
        case .none:
            break
        case .wayPoint(location: let location, _, _):
            service.moveWayPoint(to: location, altitude: nil)
        case .poi(location: let location, _):
            service.movePoi(to: location, altitude: nil)
        }
    }
}
