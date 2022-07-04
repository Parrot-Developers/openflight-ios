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
import simd

public class OGSpeedometer {
    private let averageNumber = Occupancy.framesUsedForSpeed
    private var historySpeed = [simd_float3]()
    private var lastEntryTime: Date?
    private let acccessQueue = DispatchQueue(label: "OGSpeedometer.access", qos: .userInteractive)

    public var speed: simd_float3 {
        let oneFrameTime = Float32(1) / Float32(Occupancy.framesPerSec)
        var retValue: simd_float3?
        acccessQueue.sync {
            let atAtime = Date()
            if let lastEntryTime = self.lastEntryTime {
                let elapsedTime = Float(atAtime.timeIntervalSince(lastEntryTime))
                if elapsedTime > 2 * oneFrameTime && !self.historySpeed.isEmpty {
                    // the array was not refresh -> drop the oldest value
                    self.historySpeed.removeFirst()
                }
            }
            let nbcount = self.historySpeed.count
            if nbcount > 0 {
                let averageCoef = Float32(1) / Float32(nbcount)
                retValue = historySpeed.reduce(simd_float3(), +) * simd_float3(averageCoef, averageCoef, averageCoef)
            }
        }
        return retValue ?? simd_float3()
    }

    public func setNewSpeed(_ speed: simd_float3) {
        acccessQueue.async {
            self.lastEntryTime = Date()
            self.historySpeed.append(speed)
            if self.historySpeed.count > self.averageNumber {
                self.historySpeed.removeFirst()
            }
        }
    }

    init() {
    }
}

public class OGRotatiometer {
    private let averageNumber = Occupancy.framesUsedForRotation
    private var history = [simd_float3]()
    private var lastEntry: simd_float3?
    private var lastEntryTime: Date?
    private let acccessQueue = DispatchQueue(label: "OGRotatiometer.access", qos: .userInteractive)

    public var average: simd_float3 {
        let oneFrameTime = Float32(1) / Float32(Occupancy.framesPerSec)

        var retValue: simd_float3?
        acccessQueue.sync {
            let atAtime = Date()
            if let lastEntryTime = self.lastEntryTime {
                let elapsedTime = Float(atAtime.timeIntervalSince(lastEntryTime))
                if elapsedTime > 2*oneFrameTime && !self.history.isEmpty {
                    // the array was not refresh -> drop the oldest value
                    self.history.removeFirst()
                }
            }
            let nbcount = self.history.count
            if nbcount > 0 {
                let averageCoef = Float32(1) / Float32(nbcount)
                retValue = history.reduce(simd_float3(), +) * simd_float3(averageCoef, averageCoef, averageCoef)
            }
        }
        let debugRotation = (retValue?.y ?? simd_float3().y)

        return retValue ?? simd_float3()
    }

    public func setNewRotation(_ eulerRotation: simd_float3) {
        let atAtime = Date()
        acccessQueue.async                                                                                                   {
            if let lastEntry = self.lastEntry, let lastEntryTime = self.lastEntryTime {

                var deltaRotation = eulerRotation - lastEntry
                if deltaRotation.y > 2*Float.pi {
                    deltaRotation.y -= 2*Float.pi
                } else if deltaRotation.y < -2*Float.pi {
                    deltaRotation.y += 2*Float.pi
                }
                if deltaRotation.y > Float.pi {
                    deltaRotation.y -= (2 * Float.pi)
                } else if deltaRotation.y < -Float.pi {
                    deltaRotation.y = 2 * Float.pi + deltaRotation.y
                }

                let elapsedTime = Float(atAtime.timeIntervalSince(lastEntryTime))
                let eulerRotationPerSecond = elapsedTime != 0 ? deltaRotation / elapsedTime : simd_float3(repeating: 3)
                self.history.append(eulerRotationPerSecond)
                if self.history.count > self.averageNumber {
                    self.history.removeFirst()
                }
            }
            self.lastEntry = eulerRotation
            self.lastEntryTime = atAtime
        }
    }

    init() {
    }
}
