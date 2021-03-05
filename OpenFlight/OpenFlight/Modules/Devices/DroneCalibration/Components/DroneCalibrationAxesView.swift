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
import GroundSdk

/// Custom view for drone calibration axes.
final class DroneCalibrationAxesView: UIView, NibOwnerLoadable {

    // MARK: - Outlets
    @IBOutlet private weak var axeZTickBox: DroneCalibrationAxeTickBoxView!
    @IBOutlet private weak var axeYTickBox: DroneCalibrationAxeTickBoxView!
    @IBOutlet private weak var axeXTickBox: DroneCalibrationAxeTickBoxView!

    // MARK: - Private Properties
    private var items = [Magnetometer3StepCalibrationProcessState.Axis: DroneCalibrationAxeTickBoxView]()

    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInitDroneCalibrationAxesView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInitDroneCalibrationAxesView()
    }
}

// MARK: - Internal Funcs
extension DroneCalibrationAxesView {
    /// Display the current axis.
    ///
    /// - Parameters:
    ///    - currentAxis: the current axis to display.
    func displayCurrentAxis(currentAxis: Magnetometer3StepCalibrationProcessState.Axis) {
        for item in items where item.key == currentAxis {
            item.value.viewModel.tickBoxImage = Asset.Common.Checks.icCheckUnchecked.image
        }
    }

    /// Show that the axis is calibrated.
    ///
    /// - Parameters:
    ///    - axis: axis calibrated.
    func markAsCalibrated(axis: Magnetometer3StepCalibrationProcessState.Axis) {
        items[axis]?.viewModel.tickBoxImage = Asset.Pairing.icPairingCheck.image
    }

    /// Resets all tickboxes to their initial state.
    /// Should be called on failure to handle retry properly.
    func reset() {
        items
            .compactMap { return $1 }
            .forEach { $0.viewModel.tickBoxImage = Asset.Common.Checks.icCheckUnchecked.image }
    }
}

// MARK: - Private Funcs
private extension DroneCalibrationAxesView {

    /// Basic init.
    func commonInitDroneCalibrationAxesView() {
        self.loadNibContent()
        self.setupViewModels()
    }

    /// Sets up view models associated with the view.
    func setupViewModels() {
        self.axeZTickBox.viewModel = DroneCalibrationAxeTickboxModel(tickBoxImage: Asset.Common.Checks.icCheckDisabled.image,
                                                                     axeLabel: L10n.droneCalibrationYawLabel.uppercased())
        self.axeYTickBox.viewModel = DroneCalibrationAxeTickboxModel(tickBoxImage: Asset.Common.Checks.icCheckDisabled.image,
                                                                     axeLabel: L10n.droneCalibrationPitchLabel.uppercased())
        self.axeXTickBox.viewModel = DroneCalibrationAxeTickboxModel(tickBoxImage: Asset.Common.Checks.icCheckDisabled.image,
                                                                     axeLabel: L10n.droneCalibrationRollLabel.uppercased())
        items[.yaw] = axeZTickBox
        items[.pitch] = axeYTickBox
        items[.roll] = axeXTickBox
    }
}
