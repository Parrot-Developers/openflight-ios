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
open class TouchAndFlyMapViewController: MapWithOverlaysViewController {
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

        touchAndFlyViewModel.touchAndFlyUiService.commonMapViewController = self

        // Add overlays in order from bottom to top:
        // TouchAndFly, RTH, Home, User, Drone
        addTouchAndFlyOverlay()
        returnHomeOverlay = addReturnHomeOverlay()
        addHomeOverlay()
        userLocationOverlay = addUserOverlay()
        droneLocationOverlay = addDroneOverlay()
        mapViewModel.enableAutoScroll(delegate: self)

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
        if droneLocationOverlay?.isDroneConnected == true,
           droneLocationOverlay?.droneGpsFixed == true,
           let coordinate = droneLocationOverlay?.droneLocation?.coordinates?.coordinate {
                completion(AGSViewpoint(center: AGSPoint(clLocationCoordinate2D: coordinate),
                                        scale: CommonMapConstants.cameraDistanceToCenterLocation))
        } else {
            if let coordinate = userLocationOverlay?.userLocation?.coordinates?.coordinate {
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
}

// MARK: Specific overlays
private extension TouchAndFlyMapViewController {
    /// Add touch and fly overlay
    private func addTouchAndFlyOverlay() {
        touchAndFlyOverlay = TouchAndFlyGraphicsOverlay()
        if let touchAndFlyOverlay = touchAndFlyOverlay {
            touchAndFlyOverlay.sceneProperties?.surfacePlacement = .drapedFlat
            mapView.graphicsOverlays.add(touchAndFlyOverlay)
        }
    }
}
