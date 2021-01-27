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

extension SCNQuaternion {
    /// yaw equivalent to rotation
    var yaw: Float {
        let sinyCosp: Float = 2 * (self.w * self.z + self.x * self.y)
        let cosyCosp: Float = 1 - 2 * (self.y * self.y + self.z * self.z)
        return atan2(sinyCosp, cosyCosp)
    }

    /// pitch equivalent to rotation
    var pitch: Float {
        let sinp: Float = 2 * (self.w * self.y - self.z * self.x)
        if abs(sinp) >= 1 {
            return copysign(Float.pi / 2, sinp) // use 90 degrees if out of range
        } else {
            return asin(sinp)
        }
    }

    /// roll equivalent to rotation
    var roll: Float {
        let sinrCosp: Float = 2 * (self.w * self.x + self.y * self.z)
        let cosrCosp: Float = 1 - 2 * (self.x * self.x + self.y * self.y)

        return atan2(sinrCosp, cosrCosp)
    }

    /// init `SCNQuaternion` from eulerAngles
    ///
    /// - Parameters:
    ///     - eulerAngles: pitch, yaw and roll angles
    init(eulerAngles: simd_float3) {
        var cosYaw = Float(0)
        var sinYaw = Float(0)
        var cosPitch = Float(0)
        var sinPitch = Float(0)
        var cosRoll = Float(0)
        var sinRoll = Float(0)

        __sincosf(eulerAngles.z * 0.5, &sinYaw, &cosYaw)
        __sincosf(eulerAngles.y * 0.5, &sinPitch, &cosPitch)
        __sincosf(eulerAngles.x * 0.5, &sinRoll, &cosRoll)
        self.init(
            x: cosYaw * cosPitch * sinRoll - sinYaw * sinPitch * cosRoll,
            y: sinYaw * cosPitch * sinRoll + cosYaw * sinPitch * cosRoll,
            z: sinYaw * cosPitch * cosRoll - cosYaw * sinPitch * sinRoll,
            w: cosYaw * cosPitch * cosRoll + sinYaw * sinPitch * sinRoll
        )
    }
}
