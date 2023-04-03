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

/// View controller for piloting map.
open class PilotingMapViewController: MapWithOverlaysViewController {

    // MARK: - Private Properties
    private var pilotingViewModel = PilotingViewModel()

    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()

    private var userLocationOverlay: UserLocationGraphicsOverlay?
    private var droneLocationOverlay: DroneLocationGraphicsOverlay?
    private var returnHomeOverlay: ReturnHomeGraphicsOverlay?

    // MARK: - Setup
    /// Instantiates the view controller.
    ///
    /// - Returns: the piloting map view controller
    public static func instantiate(mapMode: MapMode = .standard,
                                   isMiniMap: Bool = false) -> PilotingMapViewController {
        let viewController = StoryboardScene.PilotingMap.initialScene.instantiate()

        return viewController
    }

    // MARK: - Override Funcs
    open override func viewDidLoad() {
        super.viewDidLoad()
        // Add overlays in order from bottom to top:
        // RTH, Home, User, Drone
        returnHomeOverlay = addReturnHomeOverlay()
        addHomeOverlay()
        userLocationOverlay = addUserOverlay()
        droneLocationOverlay = addDroneOverlay()
        mapViewModel.enableAutoScroll(delegate: self)

        pilotingViewModel.centerStatePublisher.sink { [weak self] centerState in
            self?.splitControls?.updateCenterMapButtonStatus(state: centerState)

        }.store(in: &cancellables)
    }

    open override func getCenter(completion: @escaping(AGSViewpoint?) -> Void) {
        var viewPoint: AGSViewpoint?

        if droneLocationOverlay?.isDroneConnected == true,
            let droneCoordinate = droneLocationOverlay?.droneLocation?.coordinates?.coordinate {
            viewPoint = AGSViewpoint(center: AGSPoint(clLocationCoordinate2D: droneCoordinate), scale: CommonMapConstants.cameraDistanceToCenterLocation)
        } else {
            if let userCoordinate = userLocationOverlay?.userLocation?.coordinates?.coordinate {
                viewPoint = AGSViewpoint(center: AGSPoint(clLocationCoordinate2D: userCoordinate), scale: CommonMapConstants.cameraDistanceToCenterLocation)
            }
        }
        completion(viewPoint)
    }

    deinit {
        cancellables.removeAll()
    }
}
