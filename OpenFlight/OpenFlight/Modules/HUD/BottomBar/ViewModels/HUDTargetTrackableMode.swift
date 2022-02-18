//    Copyright (C) 2020 Parrot Drones SAS
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

import GroundSdk

// MARK: - Protocols
/// Protocol for controller tracking management.
public protocol HUDTargetTrackableMode: AnyObject {
    /// TargetTracker reference.
    var trackerRef: Ref<TargetTracker>? { get set }

    /// Enable controller tracking if not already enable in case we update to a mode that require controller tracking.
    ///
    /// - Parameters:
    ///    - drone: drone on which we want to enable controller tracking
    func keepControllerTrackingEnabled(drone: Drone)

    /// Stop controller tracking.
    ///
    /// - Parameters:
    ///    - drone: drone on which we want to disable controller tracking
    func stopTracking(drone: Drone)
}

// MARK: - Internal Funcs
public extension HUDTargetTrackableMode {
    func keepControllerTrackingEnabled(drone: Drone) {
        self.trackerRef = drone.getPeripheral(Peripherals.targetTracker) { tracker in
            guard tracker?.targetIsController == false else { return }
            tracker?.enableControllerTracking()
        }
    }

    func stopTracking(drone: Drone) {
        self.trackerRef = nil
        drone.getPeripheral(Peripherals.targetTracker)?.disableControllerTracking()
    }
}
