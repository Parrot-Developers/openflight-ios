// Copyright (C) 2020 Parrot Drones SAS
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

/// Instrument utility extension for Drone.

public extension Drone {
    // MARK: - Internal Properties
    /// Returns true if drone has flying state at call time.
    var isStateFlying: Bool {
        let state = getInstrument(Instruments.flyingIndicators)?.state
        return state == .flying
    }

    /// Returns true if drone is landed at call time.
    var isStateLanded: Bool {
        return getInstrument(Instruments.flyingIndicators)?.state == .landed
    }

    /// Returns true if drone is landed or disconnected at call time.
    var isLandedOrDisconnected: Bool {
        return isStateLanded || !isConnected
    }

    /// Returns true if drone is landing at call time.
    var isLanding: Bool {
        return getInstrument(Instruments.flyingIndicators)?.flyingState == .landing
    }

    /// Returns true if drone is landed or landing at call time.
    var isLandedOrLanding: Bool {
        return isLanding || isStateLanded
    }

    /// Returns true if drone is taking off at call time.
    var isTakingOff: Bool {
        return getInstrument(Instruments.flyingIndicators)?.flyingState == .takingOff
    }

    /// Returns the current landed state.
    var landedState: FlyingIndicatorsLandedState {
        return getInstrument(Instruments.flyingIndicators)?.landedState ?? .none
    }
}
