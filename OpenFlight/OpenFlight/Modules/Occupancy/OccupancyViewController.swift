//
//  Copyright (C) 2020 Parrot Drones SAS.
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
import SceneKit
import GroundSdk
import simd

/// Occupancy main view controller.
final class OccupancyViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var sceneKitView: SCNView!

    // MARK: - Private Properties
    private var renderer: OccupancyRenderer?
    private var occupancyViewModel: OccupancyViewModel?

    // MARK: - Setup
    static func instantiate() -> OccupancyViewController {
        return StoryboardScene.Occupancy.initialScene.instantiate()
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        renderer = OccupancyRenderer(sceneView: sceneKitView)
        sceneKitView.delegate = renderer
        self.setupViewModels()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        enableMonitoring(true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        enableMonitoring(false)
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Private Funcs
private extension OccupancyViewController {
    /// Sets up view models associated with the view.
    func setupViewModels() {
        guard let worldStorage = renderer?.worldStorage else {
            return
        }

        occupancyViewModel = OccupancyViewModel(worldStorage: worldStorage)
        occupancyViewModel?.enableMonitoring(true)
        occupancyViewModel?.state.valueChanged = { [weak self] state in
            self?.renderer?.dronePosition = SCNVector3(
                x: state.origin[0],
                y: state.origin[1],
                z: state.origin[2]
            )
            let quaternion = SCNQuaternion(
                x: state.quaternion[1],
                y: state.quaternion[2],
                z: state.quaternion[3],
                w: state.quaternion[0]
            )
            self?.renderer?.isDroneStationary = state.isDroneStationary

            self?.renderer?.droneEulerAngles = SCNVector3(x: -quaternion.pitch, y: -quaternion.yaw, z: quaternion.roll)
            self?.renderer?.ogSpeedometer.setNewSpeed(simd_float3(-state.speedVector.x, -state.speedVector.y, state.speedVector.z))
            self?.renderer?.ogRotationmeter.setNewRotation(simd_float3(x: -quaternion.pitch, y: -quaternion.yaw, z: quaternion.roll))
        }
    }

    /// Enable or disable monitoring for all view models.
    ///
    /// - Parameters:
    ///    - enabled: boolean that enable or disable monitoring.
    func enableMonitoring(_ enabled: Bool) {
        self.occupancyViewModel?.enableMonitoring(enabled)
    }

    /// Removes all traces from occupancy functionnality.
    func clearOccupancy() {
        self.occupancyViewModel?.enableMonitoring(false)
        self.occupancyViewModel = nil
    }
}
