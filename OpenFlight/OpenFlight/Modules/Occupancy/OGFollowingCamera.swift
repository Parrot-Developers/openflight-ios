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

import Foundation
import simd
import SceneKit

private class CameraAngle {
    /// The maximum speed never to be exceeded exceeded. Expressed as the time required to rotate pi radians. In rad/s
    let maxSpeed: Float
    /// Increment (added or subtracted) at the current speed. This is the acceleration / deceleration factor. In rad/s
    let incSpeed: Float
    /// Specify the plane to consider (h or v)
    let cameraPlane: CameraPlane

    var computedAngle: Float {
        if currentAngle > Float.pi {
            return currentAngle - Float.pi * 2
        } else {
            return currentAngle
        }
    }
    private var currentAngle = Float()
    var targetAngle = Float() {
        didSet {
            if targetAngle != oldValue {
                targetAngle = targetAngle.truncatingRemainder(dividingBy: Float.pi * 2)
                if targetAngle < 0 {
                    targetAngle += (Float.pi * 2)
                }
            }
        }
    }
    private var deltaToTarget = Float()
    // current rotation speed (in rad/s)
    private var currentSpeed = Float()
    private var previousUpdateTime = TimeInterval(0)

    /// Constructor
    init(cameraPlane: CameraPlane) {
        self.cameraPlane = cameraPlane
        switch cameraPlane {
        case .horizontal:
            maxSpeed = Float.pi * 0.6
            incSpeed = Float.pi * 0.006 * 60
            currentAngle = Float.pi
        case .vertical:
            maxSpeed = Float.pi * 0.4 * 60
            incSpeed = Float.pi * 0.004
        }
    }

    private func computeDeltaToTarget() {
        // compute closest way to go to this target
        deltaToTarget = (targetAngle - currentAngle).truncatingRemainder(dividingBy: Float.pi * 2)
        if deltaToTarget < -Float.pi {
            deltaToTarget += (Float.pi * 2)
        } else if deltaToTarget > Float.pi {
            deltaToTarget -= (Float.pi * 2)
        }
    }

    func update(atTime: TimeInterval) {

        let elpasedTime = atTime - previousUpdateTime
        previousUpdateTime = atTime

        // compute the diff : currentAngle vs targetAngle
        computeDeltaToTarget()

        // currentMaxSpped is a ratio (deltaToTarget / Float.pi)
        // if delta is Float.pi -> 100 % of max speed
        // if delta is (Float.pi / 2) -> 50% max speed
        //
        // the '% value' is smmoothed
        let normMaxSpeed = abs(deltaToTarget) / Float.pi
        // let smoothNormMaxSpeed = simd_smoothstep(0, Float(1), normMaxSpeed * 0.5)
        let realIncSpeed = incSpeed * Float(elpasedTime)
        let currentMaxSpeed = max(maxSpeed * normMaxSpeed, realIncSpeed)

        if abs(deltaToTarget) < abs(currentSpeed) && deltaToTarget.sign == currentSpeed.sign {
            currentAngle = targetAngle
            currentSpeed = 0
        } else {
            if deltaToTarget != 0 {
                if deltaToTarget < 0 {
                    currentSpeed -= realIncSpeed
                    if abs(currentSpeed) > currentMaxSpeed {
                        currentSpeed = -currentMaxSpeed
                    }
                } else {
                    currentSpeed += realIncSpeed
                    if abs(currentSpeed) > currentMaxSpeed {
                        currentSpeed = currentMaxSpeed
                    }
                }
            }
        }
        // the speed is in rad / sec. Apply the delta time
        currentAngle += currentSpeed * Float(elpasedTime)
        currentAngle = currentAngle.truncatingRemainder(dividingBy: Float.pi * 2)
    }
}

public class OGFollowingCamera {

    private var targetSphere: TargetSphere?
    private var previousUpdateTime = TimeInterval(0)
    private var horizontalCameraAngle = CameraAngle(cameraPlane: .horizontal)
    private var verticalCameraAngle = CameraAngle(cameraPlane: .vertical)
    private var hSightAngleAnalyser = SightAngleAnalyser(slicesNumber: 6, plane: .horizontal)
    private var vSightAngleAnalyser = SightAngleAnalyser(slicesNumber: 6, plane: .vertical)

    func update(cameraNode: SCNNode, targetNode: SCNNode, targetSpeed: simd_float3,
                targetRotationSpeed: simd_float3, isStationary: Bool, atTime: TimeInterval) {

        // target sphere
        if targetSphere == nil {
            targetSphere = TargetSphere()
            if let debugSphere = targetSphere {
                targetNode.addChildNode(debugSphere)
                debugSphere.position = SCNVector3(0, 0, 0)
            }
        }

        // optimization: reduce the refresh rate for the following camra system
        let elpasedTime = atTime - previousUpdateTime
        if elpasedTime > (1 / Occupancy.followingCameraRefreshRate) {
            previousUpdateTime = atTime
            var goToDestination = TargetDestination.compute(speed: targetSpeed, rotationSpeed: targetRotationSpeed)

            if let destination = goToDestination {
                goToDestination = destination + simd_float3(0, 0, 0)
            }
            let hAngle = hSightAngleAnalyser.update(targetPosition: goToDestination) ?? Float.pi
            let vAngle = vSightAngleAnalyser.update(targetPosition: goToDestination) ?? 0

            horizontalCameraAngle.targetAngle = hAngle
            verticalCameraAngle.targetAngle = vAngle

            if let debugSphere = targetSphere {
                if let goToDestination = goToDestination {
                    debugSphere.position = SCNVector3(goToDestination)
                    debugSphere.isHidden = false
                } else {
                    debugSphere.isHidden = true
                }
            }
        }

        horizontalCameraAngle.update(atTime: atTime)
        verticalCameraAngle.update(atTime: atTime)

        // set camera position
        let aboveDrone = Float(0.6)
        cameraNode.position = SCNVector3(
            targetNode.position.x,
            targetNode.position.y + aboveDrone,
            targetNode.position.z + 3.5
        )
        cameraNode.eulerAngles = SCNVector3Zero
        let targetQuaternion = getTargetQuaternion(targetNode: targetNode)
        cameraNode.rotate(by: targetQuaternion, aroundTarget: targetNode.position)
        let targetForCamera = SCNVector3(targetNode.position.x,
                                         targetNode.position.y + aboveDrone,
                                         targetNode.position.z)
        cameraNode.look(at: targetForCamera)

    }

    private func getTargetQuaternion(targetNode: SCNNode) -> SCNQuaternion {
        return SCNQuaternion(eulerAngles: simd_float3(
            verticalCameraAngle.computedAngle,
            targetNode.eulerAngles.y + horizontalCameraAngle.computedAngle,
            0
        ))
    }
}

private class TargetSphere: SCNNode {
    let sphereGeometry: SCNGeometry = {
        let geoSphere = SCNSphere(radius: 0.35)
        geoSphere.segmentCount = 12
        geoSphere.isGeodesic = true
        geoSphere.firstMaterial?.diffuse.contents = UIColor.yellow
        geoSphere.firstMaterial?.emission.contents = UIColor.yellow
        geoSphere.firstMaterial?.lightingModel = .constant
        return geoSphere
    }()

    override init() {
        super.init()
        self.geometry = sphereGeometry
        self.opacity = 0.55
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class TargetDestination {
    static let discreteNumber: Int = 5 // Occupancy.maxBeamSegments

    static func compute(speed: simd_float3, rotationSpeed: simd_float3) -> simd_float3? {
        guard simd_length(speed) > Occupancy.minCameraSpeedTargetTriger else {
            return nil
        }

        var currentVector = simd_float3.zero
        let expandCoef = Float(1.5)
        var movePerSegment = speed * expandCoef
        let rotateYAngle = rotationSpeed.y * expandCoef
        let quaternion = simd_quatf(angle: rotateYAngle, axis: simd_float3(0, 1, 0))

        for _ in 0..<discreteNumber {
            // Returns a vector rotated by a quaternion.
            movePerSegment = simd_act(quaternion, movePerSegment)
            currentVector += movePerSegment
        }
        return currentVector
    }
}

private enum CameraPlane {
    case horizontal, vertical
}
private protocol SightAngleAnalysis {
    init(slicesNumber: UInt, plane: CameraPlane)
    func update(targetPosition: simd_float3?) -> Float?
}

private class SightAngleAnalyser: SightAngleAnalysis {

    let cameraPlane: CameraPlane
    let nbSlices: UInt

    required init(slicesNumber: UInt, plane: CameraPlane) {
        self.cameraPlane = plane
        self.nbSlices = slicesNumber
    }

    func update(targetPosition: simd_float3?) -> Float? {
        guard let targetPosition = targetPosition else {
            return nil
        }
        let normVectorOnPlane: simd_float2
        var angle: Float
        switch cameraPlane {
        case .horizontal:
            let planeVector = simd_float2(targetPosition.x, targetPosition.z)
            // we check that the horizontal component is significant
            guard simd_length(planeVector) > Occupancy.minSpeedHorizontalTriger else {
                return nil
            }
            normVectorOnPlane = simd_normalize(planeVector)
            angle = acos(normVectorOnPlane.y)
            if !angle.isNaN {
                if normVectorOnPlane.x < 0 {
                    angle = (Float.pi * 2) - angle
                }
                angle += Float.pi

                let indiceSlice = getSliceFromAngle(angle)
                return Float(indiceSlice) * ((Float.pi * 2) / Float(nbSlices))
            } else {
                return nil
            }
        case .vertical:
            // we use abs(z), because we don't want that the camera is on the opposite side
            // (for the opposite side (in front of drone), we use the .horizontal slice)
            let maxAway = max(abs(targetPosition.z), abs(targetPosition.x))
            let verticalVector = simd_float2(maxAway, targetPosition.y)
            // we check that the vertical component is significant
            guard abs(verticalVector.y) > Occupancy.minSpeedVerticalTriger else {
                return nil
            }
            normVectorOnPlane = simd_normalize(verticalVector)
            angle = acos(normVectorOnPlane.x)
            if !angle.isNaN {
                if verticalVector.y < 0 {
                    angle = (Float.pi * 2) - angle
                }
                let indiceSlice = getSliceFromAngle(angle)
                var retVerticalAngle = Float(indiceSlice) * ((Float.pi * 2) / Float(nbSlices))
                if retVerticalAngle > Float.pi {
                    retVerticalAngle -= Float.pi * 2
                }
                return retVerticalAngle
            } else {
                return nil
            }
        }
    }

    func getSliceFromAngle(_ angle: Float) -> Int {
        var newAngle = angle
        if angle < 0 {
            newAngle += (Float.pi * 2)
        } else if angle >= (Float.pi * 2) {
            newAngle -= (Float.pi * 2)
        }
        let nbHalfSlice = Int(nbSlices) * 2
        let halfSliceAngle = (Float.pi * 2) / Float(nbHalfSlice)
        let halfSliceIndice =  Int((newAngle / halfSliceAngle).rounded(.towardZero)) % nbHalfSlice
        // last and 0 as half_indicices is the indice 0
        let correctedIndex = (halfSliceIndice + 1) == nbHalfSlice ? 0 : (halfSliceIndice + 1)
        return correctedIndex / 2
    }
}
