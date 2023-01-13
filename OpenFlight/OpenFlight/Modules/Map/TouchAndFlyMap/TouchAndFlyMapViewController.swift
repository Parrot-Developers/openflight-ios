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
import CoreLocation
import ArcGIS

/// View controller for touch and fly map.
open class TouchAndFlyMapViewController: AGSMapViewController {
    // MARK: - Public Properties
    public var touchAndFlyViewModel = TouchAndFlyViewModel()
    /// Touch and fly overlay
    public var touchAndFlyOverlay: TouchAndFlyGraphicsOverlay?

    // MARK: - Private Properties
    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()
    /// User location overlay
    private var userLocationOverlay: UserLocationGraphicsOverlay?
    /// Drone location overlay
    private var droneLocationOverlay: DroneLocationGraphicsOverlay?
    /// Return home overlay
    private var returnHomeOverlay: ReturnHomeGraphicsOverlay?
    private var oldDroneLocation: Location3D?
    private var canUpdateDroneLocation = true

    private enum OverlayOrder: Int, Comparable {

        case rthPath
        case home
        case user
        case touchAndFly
        case drone // must always be last in mapView. This is only for information.

        static func < (lhs: TouchAndFlyMapViewController.OverlayOrder, rhs: TouchAndFlyMapViewController.OverlayOrder) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }

        /// Set containing all possible overlays.
        public static let allCases: Set<OverlayOrder> = [
            .rthPath, .home, .user, .touchAndFly, .drone]
    }

    // MARK: - Setup
    /// Instantiates the view controller.
    ///
    /// - Returns: the touch and fly map view controller
    public static func instantiate(mapMode: MapMode = .standard,
                                   isMiniMap: Bool = false) -> TouchAndFlyMapViewController {
        let viewController = StoryboardScene.TouchAndFlyMap.initialScene.instantiate()

        return viewController
    }

    // MARK: - Override Funcs
    open override func viewDidLoad() {
        super.viewDidLoad()

        // Add overlays according to their `OverlayOrder`, as `mapView.graphicsOverlays` is
        // an empty array at load time (which means that inserting `.user` and then `.home`
        // whould lead to an incorrect [.user, .home] array).
        addReturnHomeOverlay()
        addHomeOverlay(at: OverlayOrder.home.rawValue)
        addUserOverlay()
        addTouchAndFlyOverlay()
        addDroneOverlay()

        droneLocationOverlay?.viewModel.droneLocationPublisher
            .sink(receiveValue: { [weak self] location in
            if let coordinates = location.coordinates {
                self?.updateDroneLocationGraphic(location: coordinates)
            }
            self?.oldDroneLocation = location.coordinates
        }).store(in: &cancellables)

        touchAndFlyViewModel.centerStatePublisher.sink { [weak self] centerState in
            self?.splitControls?.updateCenterMapButtonStatus(state: centerState)

        }.store(in: &cancellables)
    }

    public override func miniMapChanged(value: Bool) {
        super.miniMapChanged(value: value)
        droneLocationOverlay?.viewModel.update(isMiniMap: value)
        userLocationOverlay?.viewModel.isMiniMap.value = value
    }

    open override func getCenter(completion: @escaping(AGSViewpoint?) -> Void) {
        if droneLocationOverlay?.isActive.value == true, let coordinate = droneLocationOverlay?.viewModel.droneLocation.coordinates?.coordinate {
                completion(AGSViewpoint(center: AGSPoint(clLocationCoordinate2D: coordinate),
                                        scale: CommonMapConstants.cameraDistanceToCenterLocation))
        } else {
            if let coordinate = userLocationOverlay?.viewModel.userLocation?.coordinates?.coordinate {
                completion(AGSViewpoint(center: AGSPoint(clLocationCoordinate2D: coordinate),
                                        scale: CommonMapConstants.cameraDistanceToCenterLocation))
            } else {
                completion(nil)
            }
        }
    }

    override func identify(screenPoint: CGPoint, _ completion: @escaping (AGSIdentifyGraphicsOverlayResult?) -> Void) {
        guard let touchAndFlyOverlay = touchAndFlyOverlay else { return }

        self.mapView.identify(touchAndFlyOverlay,
                              screenPoint: screenPoint,
                              tolerance: CommonMapConstants.viewIdentifyTolerance,
                              returnPopupsOnly: false,
                              maximumResults: CommonMapConstants.viewIdentifyMaxResults) { (result: AGSIdentifyGraphicsOverlayResult) in
                completion(result)
            }
    }

    override func handleCustomMapTap(mapPoint: AGSPoint, screenPoint: CGPoint, identifyResult: AGSIdentifyGraphicsOverlayResult?) {
        touchAndFlyViewModel.touchAndFlyUiService.handleCustomMapTap(mapPoint: mapPoint, identifyResult: identifyResult)
    }

    override func handleCustomMapLongPress(mapPoint: AGSPoint, identifyResult: AGSIdentifyGraphicsOverlayResult?) {
        touchAndFlyViewModel.touchAndFlyUiService.handleCustomMapLongPress(mapPoint: mapPoint, identifyResult: identifyResult)
    }

    override func handleCustomMapTouchDown(mapPoint: AGSPoint, identifyResult: AGSIdentifyGraphicsOverlayResult?, completion: @escaping (Bool) -> Void) {
        touchAndFlyViewModel.touchAndFlyUiService.handleCustomMapTouchDown(mapPoint: mapPoint, identifyResult: identifyResult) { result in
            completion(result)
        }
    }

    override func handleCustomMapDrag(mapPoint: AGSPoint) {
        touchAndFlyViewModel.touchAndFlyUiService.handleCustomMapDrag(mapPoint: mapPoint)
    }

    override func handleCustomMapTouchUp(screenPoint: CGPoint, mapPoint: AGSPoint) {
        touchAndFlyViewModel.touchAndFlyUiService.handleCustomMapTouchUp(mapPoint: mapPoint)
    }

    // MARK: - Private Funcs
    /// Add user location overlay
    private func addUserOverlay() {
        // User Overlay
        userLocationOverlay = UserLocationGraphicsOverlay()
        userLocationOverlay?.sceneProperties?.surfacePlacement = .drapedFlat

        if let userLocationOverlay = userLocationOverlay {
            self.mapView.graphicsOverlays.insert(userLocationOverlay, at: OverlayOrder.user.rawValue)
        }
    }

    /// Add drone location overlay
    private func addDroneOverlay() {
        // Drone Overlay
        droneLocationOverlay = DroneLocationGraphicsOverlay()
        droneLocationOverlay?.sceneProperties?.surfacePlacement = .drapedFlat

        droneLocationOverlay?.isActivePublisher
            .sink { [weak self] isActive in
            guard let self = self, let droneLocationOverlay = self.droneLocationOverlay else { return }
            if isActive {
                self.mapView.graphicsOverlays.insert(droneLocationOverlay, at: OverlayOrder.drone.rawValue)
                self.checkOrderAndInsertOverlay()
            } else {
                self.mapView.graphicsOverlays.remove(droneLocationOverlay)
            }
        }.store(in: &cancellables)
    }

    /// Add return home overlay
    private func addReturnHomeOverlay() {
        // Return home overlay
        returnHomeOverlay = ReturnHomeGraphicsOverlay()
        returnHomeOverlay?.sceneProperties?.surfacePlacement = .drapedFlat

        returnHomeOverlay?.isActivePublisher
            .sink { [weak self] isActive in
            guard let self = self, let returnHomeOverlay = self.returnHomeOverlay else { return }
            if isActive {
                self.mapView.graphicsOverlays.insert(returnHomeOverlay, at: OverlayOrder.rthPath.rawValue)
                self.checkOrderAndInsertOverlay()
            } else {
                self.mapView.graphicsOverlays.remove(returnHomeOverlay)
            }
        }.store(in: &cancellables)
    }

    /// Add touch and fly overlay
    private func addTouchAndFlyOverlay() {
        touchAndFlyOverlay = TouchAndFlyGraphicsOverlay()
        touchAndFlyOverlay?.isActivePublisher
            .sink { [weak self] isActive in
            guard let self = self, let touchAndFlyOverlay = self.touchAndFlyOverlay else { return }
            if isActive {
                self.checkOrderAndInsertOverlay()
                self.touchAndFlyViewModel.touchAndFlyUiService.commonMapViewController = self
            } else {
                self.mapView.graphicsOverlays.remove(touchAndFlyOverlay)
            }
        }.store(in: &cancellables)

    }

    /// Check overlays order and insert them if necessary
    private func checkOrderAndInsertOverlay() {
        OverlayOrder.allCases.sorted().forEach { overlay in
            switch overlay {
            case .rthPath:
                if let returnHomeOverlay = returnHomeOverlay, returnHomeOverlay.isActive.value,
                   self.mapView.graphicsOverlays.index(of: returnHomeOverlay) != OverlayOrder.rthPath.rawValue {
                    self.mapView.graphicsOverlays.remove(returnHomeOverlay)
                    self.mapView.graphicsOverlays.add(returnHomeOverlay)
                }
            case .user:
                if let userLocationOverlay = userLocationOverlay,
                   self.mapView.graphicsOverlays.index(of: userLocationOverlay) != OverlayOrder.user.rawValue {
                    self.mapView.graphicsOverlays.remove(userLocationOverlay)
                    self.mapView.graphicsOverlays.add(userLocationOverlay)
                }
            case .drone:
                if let droneLocationOverlay = droneLocationOverlay, droneLocationOverlay.isActive.value,
                   self.mapView.graphicsOverlays.index(of: droneLocationOverlay) != OverlayOrder.drone.rawValue {
                    self.mapView.graphicsOverlays.remove(droneLocationOverlay)
                    self.mapView.graphicsOverlays.add(droneLocationOverlay)
                }
            case .touchAndFly:
                if let touchAndFlyOverlay = touchAndFlyOverlay, touchAndFlyOverlay.isActive.value,
                   self.mapView.graphicsOverlays.index(of: touchAndFlyOverlay) != OverlayOrder.touchAndFly.rawValue {
                    self.mapView.graphicsOverlays.remove(touchAndFlyOverlay)
                    self.mapView.graphicsOverlays.add(touchAndFlyOverlay)
                }
            default: break
            }
        }
    }

    /// Updates drone location graphic.
    ///
    /// - Parameters:
    ///    - location: new drone location
    ///    - heading: new drone heading
    func updateDroneLocationGraphic(location: Location3D) {
        // TODO: put all calculations in viewModel
        guard canUpdateDroneLocation, let oldDroneLocation = oldDroneLocation,
              isVisible(), isInside(point: oldDroneLocation.agsPoint), !centering else {
            return
        }
        var scrollToTarget = true

        // T&F
        if touchAndFlyOverlay?.isActive.value == true, let waypoint = touchAndFlyOverlay?.wayPointGraphic,
           let agsPoint = waypoint.location?.agsPoint, isInside(point: agsPoint) {
            scrollToTarget = false
        }

        // RTH
        if Services.hub.drone.rthService.isActive,
           let rthLocation = touchAndFlyViewModel.locationsTracker.returnHomeLocation,
           isInside(point: AGSPoint(clLocationCoordinate2D: rthLocation)) {
            scrollToTarget = false
        }

        // When the drone is leaving the screen and we scroll just enough to keep it on the screen, sometimes it happens that in the next iteration
        // the drone is seen as off screen in the oldDroneLocation and we stop autoscrolling.
        // The variable scrollFurther is meant to move the drone from the border
        // with a bigger offset.
        var scrollFurther = false
        if !isInside(point: location.agsPoint) {
            scrollFurther = true
            scrollToTarget = true
        }
        guard scrollToTarget else { return }

        let offSetLongitude = (location.coordinate.longitude - oldDroneLocation.coordinate.longitude) * (scrollFurther ? 1.3 : 1.0)
        let offSetLatitude = (location.coordinate.latitude - oldDroneLocation.coordinate.latitude) * (scrollFurther ? 1.3 : 1.0)

        guard offSetLatitude != 0 || offSetLongitude != 0 else { return }

        if !mapView.isNavigating {
            canUpdateDroneLocation = false
            if let centerMap = mapView.visibleArea?.extent.center.toCLLocationCoordinate2D() {
                let newLocation = CLLocationCoordinate2D(latitude: centerMap.latitude + offSetLatitude,
                                                         longitude: centerMap.longitude + offSetLongitude)

                mapView.setViewpointCenter(AGSPoint(clLocationCoordinate2D: newLocation), scale: mapView.mapScale) { [weak self]_ in
                    self?.canUpdateDroneLocation = true
                }
            } else {
                canUpdateDroneLocation = true
            }
        }
    }
}
