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

import GameplayKit.GKComponent
import GroundSdk
import SceneKit
import simd

private let tag = ULogTag(name: "Occupancy")

private class BeamRing: SCNNode {
    var ringNode: SCNNode!

    /// Color the segment to show a possible danger
    /// - Parameter isDanger: true to show a possible danger, else otherwise.
    fileprivate func setDanger(_ isDanger: Bool, dummyBeam: Bool) {
        let safeColor = dummyBeam ? UIColor(red: 50 / 255, green: 50 / 255, blue: 255 / 255, alpha: 1) :  Occupancy.safeColor
        ringNode.geometry?.firstMaterial?.emission.contents = isDanger ? Occupancy.dangerColor : safeColor
        for node in ringNode.childNodes {
            node.geometry?.firstMaterial?.diffuse.contents = isDanger ? Occupancy.dangerColor : safeColor
        }
    }

    override var opacity: CGFloat {
        get {
            return self.ringNode.opacity
        }
        set {
            self.ringNode.opacity = newValue
        }
    }

    override var isHidden: Bool {
        get {
            return ringNode.isHidden
        }
        set {
            ringNode.isHidden = newValue
        }
    }

    override init() {
        super.init()
        // create model with an ring as child
        var ringScene: SCNScene?
        if let sceneCatalog = Bundle(for: type(of: self)).url(forResource: "SceneCatalog", withExtension: "scnassets") {
            do {
                ringScene = try SCNScene(url: sceneCatalog.appendingPathComponent("cadreblender.dae"), options: nil)
            } catch {
                ULog.e(tag, "Can't access scene catalog")
            }
        }
        let nodeWithRing = ringScene?.rootNode ?? SCNNode()
        nodeWithRing.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
        let flatRing = nodeWithRing.flattenedClone()
        // material
        let material = SCNMaterial()
        material.locksAmbientWithDiffuse = true
        material.isDoubleSided = false
        material.ambient.contents = UIColor.black
        material.diffuse.contents = UIColor.black
        flatRing.geometry?.materials = [material]
        // final node
        self.ringNode = SCNNode()
        flatRing.scale = SCNVector3(0.8, 0.8, 0.5)
        self.ringNode.addChildNode(flatRing)
        self.addChildNode(ringNode)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class BeamComponent: GKComponent {

    let rootBeam = SCNNode()
    let lenght = Occupancy.maxBeamSegments

    private let voxelStorage: VoxelStorage

    private var segments = [BeamRing]()
    private weak var sceneRoot: SCNNode?

    private let dangerSphereNode: SCNNode = {
        let dangerGeometry = SCNSphere(radius: 1.1)
        dangerGeometry.isGeodesic = true
        dangerGeometry.segmentCount = 12
        dangerGeometry.firstMaterial?.diffuse.contents = Occupancy.dangerColor
        dangerGeometry.firstMaterial?.emission.contents = Occupancy.dangerColor
        let node = SCNNode(geometry: dangerGeometry)
        node.opacity = 0.2
        node.isHidden = true
        return node
    }()

    private let obstacles: Obstacles
    private var refChunkCache: ChunkStorage?
    private var refChunkCacheKey: Point?
    private var currentMove = Float(0)
    private var dummyBeam = false

    // MARK: - Initialization
    init(parentNode: SCNNode, voxelStorage: VoxelStorage, sceneRoot: SCNNode) {
        self.obstacles = Obstacles(sceneRoot: sceneRoot)
        self.sceneRoot = sceneRoot
        self.voxelStorage = voxelStorage
        super.init()
        rootBeam.position = SCNVector3(0, 0, 0)
        parentNode.addChildNode(rootBeam)
        var parent = rootBeam
        for _ in 1...lenght {
            let addSegment = BeamRing()
            addSegment.position = SCNVector3(0, 0, 2)
            parent.addChildNode(addSegment)
            parent = addSegment
            segments.append(addSegment)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func updateTrajectory(moveVector: simd_float3, rotationY: Float32) {

        refChunkCacheKey = nil
        refChunkCache = nil

        var opacity = Occupancy.beamGlobalOpacity
        let decOpacity = CGFloat(0.01)

        let movePerSegment: simd_float3
        let rotationPerSegment: Float32
        let move: simd_float3

        if simd_length(moveVector) < Occupancy.minBeamSpeedDisplay {
            move = simd_float3(0, 0, 2)
            movePerSegment = move * Occupancy.beamSpacingCoef
            rotationPerSegment = 0
            dummyBeam = true
            opacity /= 2
        } else {
            // don't display beam if speed is too small
            move = moveVector
            movePerSegment = simd_length(move) > Occupancy.minBeamSpeedDisplay ? move * Occupancy.beamSpacingCoef
                : simd_float3.zero
            rotationPerSegment = rotationY * Occupancy.beamSpacingCoef
            dummyBeam = false
        }

        var currentMoveVisible = simd_float3(0, 0, 0)

        var danger = false
        if dangerSphereNode.parent != nil {
            dangerSphereNode.removeFromParentNode()
        }

        let firstSegment = segments[0]

        var moveOfTheSecondSegment: simd_float3?
        for index in 1..<lenght {
            currentMoveVisible += movePerSegment
            segments[index].position = SCNVector3(movePerSegment)
            segments[index].eulerAngles.y = rotationPerSegment

            if !danger && abs(currentMoveVisible.z) >= Occupancy.beamMinDistanceBetweenRings {
                // remember the first segment displayed (this is the second visible segment)
                if moveOfTheSecondSegment == nil {
                    moveOfTheSecondSegment = movePerSegment * Float(index)
                }
                currentMoveVisible = simd_float3(0, 0, 0)
                opacity -= decOpacity
                segments[index].opacity = opacity

                segments[index].isHidden = false
            } else {
                segments[index].isHidden = true
            }

            if danger == false && checkObstacleOnSegment(segments[index]) {
                danger = true
                segments[index].addChildNode(dangerSphereNode)
            }
        }

        // Move the beam
        let maxSlidingMove: Float
        let addSlidingMove: simd_float3
        if move == simd_float3(0, 0, 0) {
            addSlidingMove = simd_float3(0, 0, 0)
        } else {
            let slidingNormalized = simd_normalize(move)
            addSlidingMove = slidingNormalized * currentMove
        }
        if let moveOfTheSecondSegment = moveOfTheSecondSegment {
            maxSlidingMove = simd_length(moveOfTheSecondSegment)
        } else {
            maxSlidingMove = simd_length(movePerSegment)
        }
        let ratioCurrentMove = CGFloat(currentMove / (maxSlidingMove == 0 ? 1 : maxSlidingMove))
        let moveFirst = Occupancy.beamAnchor + addSlidingMove
        rootBeam.eulerAngles.y = rotationPerSegment
        firstSegment.position = SCNVector3(moveFirst)
        firstSegment.eulerAngles.y = rotationPerSegment * Float(ratioCurrentMove)
        firstSegment.opacity = ratioCurrentMove * opacity
        firstSegment.isHidden = false
        // animate the beam
        if dummyBeam {
            currentMove += maxSlidingMove / 10
            if currentMove >= maxSlidingMove {
                currentMove -= maxSlidingMove
                if currentMove < 0 {
                    currentMove = 0
                }
            }
        } else {
            currentMove -= maxSlidingMove / 10
            if currentMove <= 0 {
                currentMove += maxSlidingMove
                if currentMove > maxSlidingMove {
                    currentMove = maxSlidingMove
                }
            }
        }

        // set color
        segments.forEach { $0.setDanger(danger, dummyBeam: dummyBeam) }
        dangerSphereNode.isHidden = !danger
        obstacles.updateVisibility()

        // change segments orientations to have a tunnel effect
        var previousSegment: BeamRing?
        for index in 0..<lenght {
            let currentSegment = segments[index]
            if currentSegment.isHidden == true {
                continue
            }
            if let previousSegment = previousSegment {
                // previousSegment.planeNode.// look(at: currentSegment.worldPosition)
                previousSegment.ringNode.look(
                    at: currentSegment.worldPosition, up: previousSegment.worldUp, localFront: SCNVector3(0, 0, 1))
            }
            previousSegment = currentSegment
        }
        // hide the last one
        if let previousSegment = previousSegment {
            previousSegment.isHidden = true
        }
    }

    /// returns a set of possible obstacles around a voxel
    private func setOfObstacles(centerPoint: Point) -> Set<Point> {
        var retSet = Set<Point>()
        retSet.insert(centerPoint)
        retSet.insert(Point(centerPoint.x - 1, centerPoint.y, centerPoint.z))
        retSet.insert(Point(centerPoint.x + 1, centerPoint.y, centerPoint.z))
        retSet.insert(Point(centerPoint.x, centerPoint.y - 1, centerPoint.z))
        retSet.insert(Point(centerPoint.x, centerPoint.y + 1, centerPoint.z))
        retSet.insert(Point(centerPoint.x, centerPoint.y, centerPoint.z - 1))
        retSet.insert(Point(centerPoint.x, centerPoint.y, centerPoint.z + 1))
        return retSet
    }

    private func checkObstacleOnSegment(_ segment: SCNNode) -> Bool {
        let worldPositon = segment.worldPosition
        // get the chunk
        let coords = voxelStorage.convertWorldPosition(simd_float3(worldPositon))

        // in order to get sucessively the same chunk reference
        // we keep the previous chunk ref during the beam update
        if refChunkCacheKey != coords.chunkKey {
            refChunkCache = voxelStorage[coords.chunkKey]
            refChunkCacheKey = coords.chunkKey
        }

        var retValueHit = false
        if let chunk = refChunkCache {
            let setHits = setOfObstacles(centerPoint: coords.voxelKey).filter { chunk[$0] }
            if !setHits.isEmpty {
                obstacles.add(refPoint: coords.voxelKey, coords: setHits)
                retValueHit = true
            }
        }
        return retValueHit
    }
}

private class Obstacles {

    private let decOpacity = CGFloat(0.1)
    private weak var sceneRoot: SCNNode?
    private var setOfDangers = [Point: SCNNode]()
    private lazy var redVoxel: SCNNode = {
        let dangerGeometry = Occupancy.dangerVoxelGeometry
        dangerGeometry.firstMaterial?.diffuse.contents = Occupancy.dangerColor
        dangerGeometry.firstMaterial?.lightingModel = .constant
        let node = SCNNode(geometry: dangerGeometry)
        return node
    }()

    init(sceneRoot: SCNNode) {
        self.sceneRoot = sceneRoot
    }

    func updateVisibility() {
        setOfDangers.forEach { $0.value.opacity -= decOpacity }
        var removedKeys = Set<Point>()
        setOfDangers.forEach { point, node in
            if node.opacity <= 0 {
                node.removeFromParentNode()
                removedKeys.insert(point)
            }
        }
        removedKeys.forEach { setOfDangers.removeValue(forKey: $0) }
    }

    func add(refPoint: Point, coords: Set<Point>) {
        let containerNode = SCNNode()
        coords.forEach { point in
            let redNode = redVoxel.clone()
            redNode.position = point.toVector()
            containerNode.addChildNode(redNode)
        }
        let finalNode = containerNode.flattenedClone()
        sceneRoot?.addChildNode(finalNode)
        if let oldNode = setOfDangers[refPoint] {
            oldNode.removeFromParentNode()
        }
        setOfDangers[refPoint] = finalNode
    }
}
