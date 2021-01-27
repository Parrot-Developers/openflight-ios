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

import GameplayKit.GKComponent
import SceneKit

class GridComponent: GKComponent {

    private let nodeName = "GridNode"

    /// Voxel geometry used on grid
    private lazy var voxelNode: SCNNode = {
        let shapeGeo = Occupancy.voxelGeometry
        shapeGeo.firstMaterial?.diffuse.contents = Occupancy.voxelColor
        shapeGeo.firstMaterial?.emission.contents = Occupancy.voxelColor
        shapeGeo.firstMaterial?.emission.intensity = 0.2
        let retNode =  SCNNode(geometry: shapeGeo)
        return retNode
    }()

    /// Voxel storage asked to update the grid
    private let voxelStorage: VoxelStorageCore

    /// Query id to ask for voxel storage update
    private var queryId = UInt(0)

    // MARK: - Initialization
    init(voxelStorage: VoxelStorageCore) {
        self.voxelStorage = voxelStorage
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - GKComponent overrides

    override func update(deltaTime seconds: TimeInterval) {
        updateGridNode()
    }

    // MARK: - Methods

    /// ask the voxel storage for new chunks and update SceneKit nodes
    private func updateGridNode() {
        guard let gridNode = entity?.component(ofType: SceneComponent.self)?.node
            else { return }

        let node = SCNNode()
        node.name = nodeName

        voxelStorage.getSetOfUpdatedChunks(fromQuery: &queryId).forEach { point in
            let chunkNode = SCNNode()
            let chunkName = point.uid

            chunkNode.name = chunkName
            voxelStorage[point]?.forEach { point in
                let addVoxelNode = voxelNode.clone()
                addVoxelNode.position = point.toVector()
                chunkNode.addChildNode(addVoxelNode)
            }

            gridNode.childNode(withName: chunkName, recursively: false)?.removeFromParentNode()
            let addChunk = chunkNode.flattenedClone()
            gridNode.addChildNode(addChunk)
        }
    }
}
