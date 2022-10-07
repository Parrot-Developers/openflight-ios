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

import Foundation
import SceneKit

public enum Occupancy {
    public static let width = Int32(64)
    public static let height = Int32(32)
    public static let depth = Int32(64)

    public static let droneScene = "Parrot-Anafi.scn"
    public static let droneScale = SCNVector3(0.00342857, 0.00342857, 0.00342857) // SCNVector3(0.0055, 0.0055, 0.0055)
    public static let droneModelRotation = SCNVector3(0, Float.pi, 0)
    public static let droneOpacity = CGFloat(0.35)

    public static let voxelGeometry = SCNBox(width: 0.94, height: 0.94, length: 0.94, chamferRadius: 0)
    public static let voxelColor = UIColor.init(red: 25/255, green: 168/255, blue: 126/255, alpha: 1)
    public static let voxelRealSize = Float(0.4)

    public enum Storage {
        public static let maxDropFrameForUpdate = 4
        public static let chunkSize = Int32(32)
        public static let maximumChunkQueries = UInt(6)
    }

    // Background
    /// backgroundColor - If nil, a SkyBox  is displayed instead
    public static let backgroundColor: UIColor? = nil // UIColor(rgbaValue:0xd0d0e0ff)

    // Trajectory Beam
    public static let beamAnchor = simd_float3(0, 0, 0)
    public static let framesPerSec = 30
    public static let framesUsedForSpeed = 60
    public static let framesUsedForRotation = 60
    public static let maxBeamSegments = 8
    public static let minBeamSpeedDisplay = Float(0.4)
    public static let beamSpacingCoef = Float(1) // increase the value to increase the space between two arrows
    public static let beamMinDistanceBetweenRings = Float(1)
    public static let beamGlobalOpacity = CGFloat(0.65)
    public static let dangerColor = UIColor(red: 255 / 255, green: 0 / 255, blue: 0 / 255, alpha: 1)
    // safe color #ffdc02
    public static let safeColor = UIColor(red: 255 / 255, green: 220 / 255, blue: 2 / 255, alpha: 1) // UIColor.yellow
    public static let dangerVoxelGeometry = SCNBox(width: 0.98, height: 0.98, length: 0.98, chamferRadius: 0)

    // Camera Target -
    public static let targetSpacingCoef = Float(1)
    // refresh rate for beam
    public static let beamRefreshRate = Double(15)
    // refresh rate for Following Camera
    public static let followingCameraRefreshRate = Double(10)
    // Camera Motion minimum speed trigger
    public static let minCameraSpeedTargetTriger = Float(0.3)
    public static let minSpeedHorizontalTriger = Float(0.6)
    public static let minSpeedVerticalTriger = Float(0.0)
}
