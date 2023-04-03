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

open class SceneWithOverlaysViewController: AGSSceneViewController {

    // MARK: - Common overlays
    /// Add home overlay
    open func addHomeOverlay() {
        // TODO: Injection.
        let homeLocationOverlay = HomeLocationGraphicsOverlay(rthService: Services.hub.drone.rthService,
                                                              mapViewModel: mapViewModel)
        sceneView.graphicsOverlays.add(homeLocationOverlay)
    }

    /// Add user overlay
    open func addUserOverlay() -> UserLocationGraphicsOverlay {
        let userLocationOverlay = UserLocationGraphicsOverlay()
        userLocationOverlay.sceneProperties?.surfacePlacement = .drapedFlat
        sceneView.graphicsOverlays.add(userLocationOverlay)
        return userLocationOverlay
    }

    /// Add drone overlay
    open func addDroneOverlay() -> DroneLocationGraphicsOverlay {
        let droneLocationOverlay = DroneLocationGraphicsOverlay(isScene: true)
        droneLocationOverlay.sceneProperties?.surfacePlacement = .drapedFlat
        sceneView.graphicsOverlays.add(droneLocationOverlay)
        return droneLocationOverlay
    }

    /// Add return home overlay
    open func addReturnHomeOverlay() -> ReturnHomeGraphicsOverlay {
        let returnHomeOverlay = ReturnHomeGraphicsOverlay()
        returnHomeOverlay.sceneProperties?.surfacePlacement = .drapedFlat
        sceneView.graphicsOverlays.add(returnHomeOverlay)
        return returnHomeOverlay
    }
}
