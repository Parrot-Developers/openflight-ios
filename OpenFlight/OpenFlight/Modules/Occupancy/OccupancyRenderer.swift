// Copyright (C) 2019 Parrot Drones SAS
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

// FIXME: Occupancy / WIP

import GroundSdk
import GameplayKit
import SceneKit

class OccupancyRenderer: NSObject, SCNSceneRendererDelegate {

    /// ULog tag
    let tag = ULogTag(name: "Occupancy")

    /// Time interval used to update components system
    var lastRendering = TimeInterval(0)
    /// Class instance to manage entities
    var entityManager: EntityManager!
    /// SceneKit view
    var sceneView: SCNView!
    /// World voxel storage
    var worldStorage: VoxelStorageCore

    /// Drone position
    var dronePosition = SCNVector3Zero
    /// Drone orientation
    var droneEulerAngles = SCNVector3Zero
    /// Drone atitude
    var isDroneStationary = true

    /// Anafi2 model
    private var droneModelNode = SCNNode()
    /// Camera Node
    private var cameraNode: SCNNode

    /// World grid voxels entity
    private var worldGridEntity: GridEntity!

    /// Drone reference Node
    private var droneRootNode = SCNNode()
    /// computed SpeedoMeter for trajectory Beam or following camera
    var ogSpeedometer = OGSpeedometer()
    /// computed RotationMeter for trajectory Beam or following camera
    var ogRotationmeter = OGRotatiometer()
    /// value computed with the ogSpeedometer
    private var droneLocalSpeedVector = simd_float3()
    /// value computed with the ogRotationmeter
    private var droneLocalRotationVector = simd_float3()

    /// Trajectory beam Entity
    private var beamEntity: BeamEntity!
    /// Following Camera
    private var ogFollowingCamera = OGFollowingCamera()
    private var previousDroneUpdateTime = TimeInterval(0)

    /// - Parameters:
    ///     - sceneView: SceneKit view
    init(sceneView: SCNView) {
        // Setup sceneView
        self.sceneView = sceneView
        self.sceneView.backgroundColor = .black
        self.sceneView.autoenablesDefaultLighting = false
        self.sceneView.scene = SCNScene()
        self.sceneView.isPlaying = true
        self.sceneView.scene?.fogStartDistance = 30
        self.sceneView.scene?.fogEndDistance = 50
        self.sceneView.scene?.fogDensityExponent = 1
        self.sceneView.scene?.fogColor = UIColor.init(red: 110/255, green: 154/255, blue: 188/255, alpha: 1)
        if let color = Occupancy.backgroundColor {
            self.sceneView.scene?.background.contents = color
        } else {
             self.sceneView.scene?.background.contents = [
                Asset.Occupancy.deepsky2nz.image, // right
                Asset.Occupancy.deepsky2pz.image, // left
                Asset.Occupancy.deepsky2py.image, // top
                Asset.Occupancy.deepsky2ny.image, // bottom
                Asset.Occupancy.deepsky2px.image, // back
                Asset.Occupancy.deepsky2nx.image] // front
        }

        // Setup voxel storage
        worldStorage = VoxelStorageCore(size: Point(x: Occupancy.width, y: Occupancy.height, z: Occupancy.depth))
        entityManager = EntityManager(scene: self.sceneView.scene)
        // Drone Root Node
        sceneView.scene?.rootNode.addChildNode(droneRootNode)
        // Setup drone model
        droneModelNode.addChildNode(Anafi2Model.node().flattenedClone())
        droneRootNode.addChildNode(droneModelNode)

        // Setup camera entity
        self.cameraNode = OGCamera.node()
        self.sceneView.pointOfView = cameraNode
        sceneView.scene?.rootNode.addChildNode(cameraNode)

        // Create a Beam
        if let sceneRoot = sceneView.scene?.rootNode {
            beamEntity = BeamEntity(refNode: droneRootNode, voxelStorage: worldStorage, sceneRoot: sceneRoot)
        }

        // Create world grid
        worldGridEntity = GridEntity(voxelStorage: worldStorage)
        entityManager.add(worldGridEntity)
    }

    /// SceneKit renderer method, called approximately 60 times per second
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {

        // Drone data update
        droneRootNode.position = dronePosition
        droneRootNode.eulerAngles = SCNVector3(
            0,
            droneEulerAngles.y,
            0
        )
        if let speedVector = sceneView.scene?.rootNode.simdConvertVector(ogSpeedometer.speed, to: droneRootNode) {
            droneLocalSpeedVector = speedVector
        }
        droneLocalRotationVector = ogRotationmeter.average

        // update drone orienttion and camera
        updateDroneAndCamera(atTime: time)

        // reduce the refresh rate for the Beam
        let elpasedTime = time - previousDroneUpdateTime
        if elpasedTime > (1 / Occupancy.beamRefreshRate) {
            previousDroneUpdateTime = time
            updateBeam()
        }

        // always try to update the grid
        entityManager.update(time - lastRendering)
        lastRendering = time
    }

    /// Update drone entity position and orientation
    func updateDroneAndCamera(atTime: TimeInterval) {
        // update pitch et roll
        droneModelNode.eulerAngles = SCNVector3(
            droneEulerAngles.x,
            0,
            droneEulerAngles.z)
        /// Update camera position and orientation
        ogFollowingCamera.update(
            cameraNode: cameraNode, targetNode: droneRootNode, targetSpeed: droneLocalSpeedVector,
            targetRotationSpeed: droneLocalRotationVector, isStationary: isDroneStationary, atTime: atTime)
    }

    /// Update beam
    func updateBeam() {
        beamEntity.updateTrajectory(move: droneLocalSpeedVector, rotationY: droneLocalRotationVector.y)
    }

}
