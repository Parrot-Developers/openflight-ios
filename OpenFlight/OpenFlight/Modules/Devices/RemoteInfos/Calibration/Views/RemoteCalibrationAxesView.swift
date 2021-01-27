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

import UIKit
import Reusable

/// View wich display x, y, z progress view for remote calibration.

final class RemoteCalibrationAxesView: UIView, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var xAxeProgressView: RemoteCalibrationAxeProgressView!
    @IBOutlet private weak var yAxeProgressView: RemoteCalibrationAxeProgressView!
    @IBOutlet private weak var zAxeProgressView: RemoteCalibrationAxeProgressView!

    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInitRemoteCalibrationAxesView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInitRemoteCalibrationAxesView()
    }

    // MARK: - Internal Funcs
    /// Update yaw progress value.
    /// - Parameters:
    ///     - yaw: yaw value
    func updateYawProgress(yaw: Float?) {
        zAxeProgressView.model?.progress = yaw
    }

    /// Update roll progress value.
    /// - Parameters:
    ///     - roll: roll value
    func updateRollProgress(roll: Float?) {
        xAxeProgressView.model?.progress = roll
    }

    /// Update pitch progress value.
    /// - Parameters:
    ///     - pitch: pitch value
    func updatePitchProgress(pitch: Float?) {
        yAxeProgressView.model?.progress = pitch
    }
}

// MARK: - Private Funcs
private extension RemoteCalibrationAxesView {
    func commonInitRemoteCalibrationAxesView() {
        self.loadNibContent()

        xAxeProgressView.model = CalibrationProgressModel(title: L10n.remoteCalibrationRollAxe, progress: 0.0)
        yAxeProgressView.model = CalibrationProgressModel(title: L10n.remoteCalibrationPitchAxe, progress: 0.0)
        zAxeProgressView.model = CalibrationProgressModel(title: L10n.remoteCalibrationYawAxe, progress: 0.0)
    }
}
