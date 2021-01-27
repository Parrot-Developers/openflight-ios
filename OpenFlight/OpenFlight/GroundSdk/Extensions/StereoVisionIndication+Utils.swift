//
//  Copyright (C) 2020 Parrot Drones SAS.
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

/// Utility for `StereoVisionIndication`.
extension StereoVisionIndication {
    /// Title of stereo vision indication.
    var title: String {
        switch self {
        case .none:
            return L10n.loveCalibrationMoveBoardToFillFrame
        case .checkBoardAndCameras:
            return L10n.loveCalibrationTargetPartiallyHidden
        case .placeWithinSight:
            return L10n.sensorCalibrationOutFrame
        case .moveAway:
            return L10n.sensorCalibrationTooClose
        case .moveCloser:
            return L10n.sensorCalibrationTooFar
        case .moveLeft:
            return L10n.sensorCalibrationMoveLeft
        case .moveRight:
            return L10n.sensorCalibrationMoveRight
        case .moveUpward:
            return L10n.sensorCalibrationMoveUp
        case .moveDownward:
            return L10n.sensorCalibrationMoveDown
        case .turnClockwise:
            return L10n.sensorCalibrationRotateRight
        case .turnCounterClockwise:
            return L10n.sensorCalibrationRotateLeft
        case .tiltLeft:
            return L10n.sensorCalibrationTiltLeft
        case .tiltRight:
            return L10n.sensorCalibrationTiltRight
        case .tiltForward:
            return L10n.sensorCalibrationTiltTowards
        case .tiltBackward:
            return L10n.sensorCalibrationTiltBackwards
        case .stop:
            return L10n.loveCalibrationHoldPosition
        }
    }
}
