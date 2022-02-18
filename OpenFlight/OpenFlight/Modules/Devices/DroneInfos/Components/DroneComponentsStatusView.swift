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

import UIKit
import Reusable
import GroundSdk

// MARK: - Internal Structs
/// Model for `DroneComponentsStatusView`.
struct DroneComponentsStatusModel {
    var isDroneConnected: Bool = false
    var gimbalErrorImage: UIImage?
    var frontStereoGimbalErrorImage: UIImage?
    var stereoVisionStatus: StereoVisionSensorCalibrationState?
    var frontLeftMotorStatus: DroneMotorStatus?
    var frontRightMotorStatus: DroneMotorStatus?
    var rearLeftMotorStatus: DroneMotorStatus?
    var rearRightMotorStatus: DroneMotorStatus?

    // MARK: - Internal Funcs
    /// Updates model with given set of motor errors.
    ///
    /// - Parameters:
    ///    - motorErrors: set of motor errors
    mutating func update(with motorErrors: Set<CopterMotor>?) {
        frontLeftMotorStatus = motorErrors?.contains(.frontLeft) == true ? .error : .ready
        frontRightMotorStatus = motorErrors?.contains(.frontRight) == true ? .error : .ready
        rearLeftMotorStatus = motorErrors?.contains(.rearLeft) == true ? .error : .ready
        rearRightMotorStatus = motorErrors?.contains(.rearRight) == true ? .error : .ready
    }
}

/// Displays a drone image with status for motors & gimbal.

final class DroneComponentsStatusView: UIView, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var droneImageView: UIImageView!
    @IBOutlet private weak var gimbalImageView: UIImageView!
    @IBOutlet private weak var stereoVisionImageView: UIImageView!
    @IBOutlet private weak var frontLeftMotorImageView: UIImageView!
    @IBOutlet private weak var frontRightMotorImageView: UIImageView!
    @IBOutlet private weak var rearLeftMotorImageView: UIImageView!
    @IBOutlet private weak var rearRightMotorImageView: UIImageView!
    @IBOutlet private var allStatusView: [UIImageView]!

    // MARK: - Internal Properties
    var model = DroneComponentsStatusModel() {
        didSet {
            fill(with: model)
        }
    }

    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.loadNibContent()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadNibContent()
    }
}

// MARK: - Private Funcs
private extension DroneComponentsStatusView {
    /// Fills view with given model.
    ///
    /// - Parameters:
    ///    - model: drone components status model
    func fill(with model: DroneComponentsStatusModel) {
        droneImageView.image = model.isDroneConnected ? Asset.Drone.icDroneDetailsAvailable.image : Asset.Drone.icDroneDetailsUnavailable.image
        allStatusView.forEach { $0.isHidden = !model.isDroneConnected }
        gimbalImageView.image = model.gimbalErrorImage
        stereoVisionImageView.image = model.frontStereoGimbalErrorImage
        frontLeftMotorImageView.image = model.frontLeftMotorStatus?.image
        frontRightMotorImageView.image = model.frontRightMotorStatus?.image
        rearLeftMotorImageView.image = model.rearLeftMotorStatus?.image
        rearRightMotorImageView.image = model.rearRightMotorStatus?.image
    }
}
