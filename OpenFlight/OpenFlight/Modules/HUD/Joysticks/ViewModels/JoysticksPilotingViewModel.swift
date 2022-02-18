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

/// ViewModel in charge of piloting drone with joysticks.

final class JoysticksPilotingViewModel: DroneStateViewModel<DeviceConnectionState> {
    // MARK: - Private Properties
    private var manualPilotingItf: ManualCopterPilotingItf? {
        return drone?.getPilotingItf(PilotingItfs.manualCopter)
    }
    private var guidedPilotedItf: GuidedPilotingItf? {
        return drone?.getPilotingItf(PilotingItfs.guided)
    }
    private var pilotedPOIItf: PointOfInterestPilotingItf? {
        return drone?.getPilotingItf(PilotingItfs.pointOfInterest)
    }
    private var lookAtItf: LookAtPilotingItf? {
        return drone?.getPilotingItf(PilotingItfs.lookAt)
    }
    private var followMeItf: FollowMePilotingItf? {
        return drone?.getPilotingItf(PilotingItfs.followMe)
    }
    private var returnHomeItf: ReturnHomePilotingItf? {
        return drone?.getPilotingItf(PilotingItfs.returnHome)
    }
    private var flightPlanItf: FlightPlanPilotingItf? {
        return drone?.getPilotingItf(PilotingItfs.flightPlan)
    }
    private var gimbal: Gimbal? {
        return drone?.getPeripheral(Peripherals.gimbal)
    }

    // MARK: - Private Enums
    private enum Constants {
        static let cameraTiltRange: ClosedRange<CGFloat> = (-1.0...1.0)
    }

    // MARK: - Internal Funcs
    /// Apply new motor consign to the drone.
    ///
    /// - Parameters:
    ///     - foregroundView: foreground view
    ///     - backgroundView: background view
    ///     - type: current joystick type
    func newMotorConsignFrom(foregroundView: UIView,
                             backgroundView: UIView,
                             type: JoystickType) {
        // Consigns on Y axis.
        let yDelta = backgroundView.center.y - foregroundView.center.y
        let yMultiplier = (backgroundView.bounds.height / 2.0) - (foregroundView.bounds.height / 4.0)
        let yPercent = (yDelta / yMultiplier) * CGFloat(Values.oneHundred)
        let yCsgn = MathUtils.quadraticEaseIn(currentValue: yPercent)

        // Consigns on X axis.
        let xDelta = backgroundView.center.x - foregroundView.center.x
        let xMultiplier = (backgroundView.bounds.width / 2.0) - (foregroundView.bounds.width / 4.0)
        let xPercent = (xDelta / xMultiplier) * CGFloat(Values.oneHundred)
        let xCsgn = MathUtils.quadraticEaseIn(currentValue: xPercent)

        // Apply consign for the current type.
        switch type {
        case .pitchYaw:
            setPitchValue(pitch: Int(-yCsgn))
            setYawRotationSpeed(yawRotationSpeed: Int(-xCsgn))
        case .gazRoll:
            setVerticalSpeed(verticalSpeed: Int(yCsgn))
            setRollValue(roll: Int(-xCsgn))
        case .gazYaw:
            setVerticalSpeed(verticalSpeed: Int(yCsgn))
            setYawRotationSpeed(yawRotationSpeed: Int(-xCsgn))
        case .pitchRoll:
            setPitchValue(pitch: Int(-yCsgn))
            setRollValue(roll: Int(-xCsgn))
        case .cameraTilt:
            setPithCameraTilt(pitchCameraTilt: yDelta / yMultiplier)
        case .invalid:
            break
        }
    }

    /// Release joysticks in order to stabilise the drone.
    ///
    /// - Parameters:
    ///     - type: type of the selected joystick
    func releaseJoystick(type: JoystickType) {
        switch type {
        case .pitchYaw:
            setPitchValue(pitch: 0)
            setYawRotationSpeed(yawRotationSpeed: 0)
        case .gazRoll:
            setVerticalSpeed(verticalSpeed: 0)
            setRollValue(roll: 0)
        case .gazYaw:
            setVerticalSpeed(verticalSpeed: 0)
            setYawRotationSpeed(yawRotationSpeed: 0)
        case .pitchRoll:
            setPitchValue(pitch: 0)
            setRollValue(roll: 0)
        case .cameraTilt:
            setPithCameraTilt(pitchCameraTilt: 0)
        case .invalid:
            break
        }
    }
}

// MARK: - Private Funcs
private extension JoysticksPilotingViewModel {
    /// Set pitch value for the current pilotingItf.
    ///
    /// - Parameters:
    ///    - pitch: pitch value
    func setPitchValue(pitch: Int) {
        if manualPilotingItf?.state == .active {
            manualPilotingItf?.set(pitch: pitch)
        } else if pilotedPOIItf?.state == .active {
            pilotedPOIItf?.set(pitch: pitch)
        } else if lookAtItf?.state == .active {
            lookAtItf?.set(pitch: pitch)
        } else if followMeItf?.state == .active {
            followMeItf?.set(pitch: pitch)
        } else if guidedPilotedItf?.state == .active
            || flightPlanItf?.state == .active {
            _ = manualPilotingItf?.activate()
            manualPilotingItf?.set(pitch: pitch)
        } else if returnHomeItf?.state == .active {
            // RTH piloting special case.
            _ = returnHomeItf?.deactivate()
            manualPilotingItf?.set(pitch: pitch)
        }
    }

    /// Set roll value for the current pilotingItf.
    ///
    /// - Parameters:
    ///     - roll: roll value
    func setRollValue(roll: Int) {
        if manualPilotingItf?.state == .active {
            manualPilotingItf?.set(roll: roll)
        } else if pilotedPOIItf?.state == .active {
            pilotedPOIItf?.set(roll: roll)
        } else if lookAtItf?.state == .active {
            lookAtItf?.set(roll: roll)
        } else if followMeItf?.state == .active {
            followMeItf?.set(roll: roll)
        } else if guidedPilotedItf?.state == .active
            || flightPlanItf?.state == .active {
            _ = manualPilotingItf?.activate()
            manualPilotingItf?.set(roll: roll)
        } else if returnHomeItf?.state == .active {
            // RTH piloting special case.
            _ = returnHomeItf?.deactivate()
            manualPilotingItf?.set(roll: roll)
        }
    }

    /// Set vertical speed value for the current pilotingItf.
    ///
    /// - Parameters:
    ///     - verticalSpeed: vertical speed value
    func setVerticalSpeed(verticalSpeed: Int) {
        if manualPilotingItf?.state == .active {
            manualPilotingItf?.set(verticalSpeed: verticalSpeed)
        } else if pilotedPOIItf?.state == .active {
            pilotedPOIItf?.set(verticalSpeed: verticalSpeed)
        } else if lookAtItf?.state == .active {
            lookAtItf?.set(verticalSpeed: verticalSpeed)
        } else if followMeItf?.state == .active {
            followMeItf?.set(verticalSpeed: verticalSpeed)
        } else if guidedPilotedItf?.state == .active
            || flightPlanItf?.state == .active {
            _ = manualPilotingItf?.activate()
            manualPilotingItf?.set(verticalSpeed: verticalSpeed)
        } else if returnHomeItf?.state == .active {
            // RTH piloting special case.
            _ = returnHomeItf?.deactivate()
            manualPilotingItf?.set(verticalSpeed: verticalSpeed)
        }
    }

    /// Set yaw rotation speed value for the current pilotingItf.
    ///
    /// - Parameters:
    ///     - yawRotationSpeed: yaw rotation speed value
    func setYawRotationSpeed(yawRotationSpeed: Int) {
        if manualPilotingItf?.state == .active {
            manualPilotingItf?.set(yawRotationSpeed: yawRotationSpeed)
        } else if guidedPilotedItf?.state == .active
            || flightPlanItf?.state == .active {
            _ = manualPilotingItf?.activate()
            manualPilotingItf?.set(yawRotationSpeed: yawRotationSpeed)
        } else if returnHomeItf?.state == .active {
            // RTH piloting special case
            _ = returnHomeItf?.deactivate()
            manualPilotingItf?.set(yawRotationSpeed: yawRotationSpeed)
        }
    }

    /// Set pitch camera tilt value for the current pilotingItf.
    ///
    /// - Parameters:
    ///     - pitchCameraTilt: pitch camera tilt value
    func setPithCameraTilt(pitchCameraTilt: CGFloat) {
        guard let gimbal = gimbal else { return }
        gimbal.control(mode: .velocity,
                       yaw: nil,
                       pitch: Double(Constants.cameraTiltRange.clamp(pitchCameraTilt)),
                       roll: nil)
    }
}
