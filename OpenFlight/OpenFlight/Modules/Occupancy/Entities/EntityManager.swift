//    Copyright (C) 2019 Parrot Drones SAS
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

import Foundation
import SceneKit
import GameplayKit

class EntityManager {

    /// entities
    var entities = Set<GKEntity>()
    /// SceneKit scene
    let scene: SCNScene?

    /// Setup component systems to call update methods of specific compoment at each SceneKit renderer call
    lazy var componentSystems: [GKComponentSystem] = {
        let gridSystem = GKComponentSystem(componentClass: GridComponent.self)
        return [gridSystem]
    }()

    init(scene: SCNScene?) {
        self.scene = scene
    }

    /// add an entity to the entities array
    /// if the given entity hold a SceneComponent, add it to the SceneKit scene
    /// setup components to update according to the component systems
    ///
    /// - Parameters:
    ///     - entity: entity to handle
    func add(_ entity: GKEntity) {
        entities.insert(entity)

        if let sceneNode = entity.component(ofType: SceneComponent.self)?.node {
            scene?.rootNode.addChildNode(sceneNode)
        }

        for componentSystem in componentSystems {
            componentSystem.addComponent(foundIn: entity)
        }
    }

    /// Update each component systems and remove entities to remove
    func update(_ deltaTime: TimeInterval) {
        for componentSystem in componentSystems {
            componentSystem.update(deltaTime: deltaTime)
        }
    }
}
