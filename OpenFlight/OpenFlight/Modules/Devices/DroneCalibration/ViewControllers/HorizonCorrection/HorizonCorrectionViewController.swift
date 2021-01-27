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
import GroundSdk

/// View Controller used to display the horizon correction screen.
final class HorizonCorrectionViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var horizonCorrectionTitle: UILabel!
    @IBOutlet private weak var backButton: UIButton!
    @IBOutlet private var horizonLevels: [UIView]!
    @IBOutlet private weak var rulerBarView: UIView!

    // MARK: - Private Properties
    private weak var coordinator: DroneCalibrationCoordinator?
    private var viewModel = HorizonCorrectionViewModel()
    private var centeredRulerBarView: CorrectionRulerView?

    // MARK: - Private Enums
    private enum Constants {
        static let currentOrientation: String = "orientation"
    }

    // MARK: - Setup
    /// Instantiate View controller.
    ///
    /// - Parameters:
    ///     - coordinator: navigation coordinator
    static func instantiate(coordinator: DroneCalibrationCoordinator) -> HorizonCorrectionViewController {
        let viewController = StoryboardScene.HorizonCorrection.horizonCorrectionViewController.instantiate()
        viewController.coordinator = coordinator

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        self.initUI()
        self.setupViewModels()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.viewModel.startCalibration()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.viewModel.cancelCalibration()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension HorizonCorrectionViewController {
    /// Function called when the back button is clicked.
    @IBAction func backButtonTouchedUpInside(_ sender: UIButton) {
        self.viewModel.cancelCalibration()
        self.coordinator?.back()
    }
}

// MARK: - Private Funcs
private extension HorizonCorrectionViewController {
    /// updates ruler bar with new offset.
    ///
    /// - Parameters:
    ///     - offset: Correction gimbal offset.
    func updateRulerBar(offset: GimbalOffsetsCorrectionProcess?) {
        if let correctionProcess = offset, let roll = correctionProcess.offsetsCorrection[.roll] {
            let minValue = roll.min
            let maxValue = roll.max
            centeredRulerBarView?.model = CorrectionRulerModel(value: roll.value,
                                                               range: Array(stride(from: minValue, through: maxValue, by: 0.1)),
                                                               unit: .degree,
                                                               orientation: .horizontal)
        }
    }
    /// Adds ruler bar to view controller.
    func createRulerBar() {
        let ruler = CorrectionRulerView(orientation: .horizontal)
        ruler.delegate = self
        rulerBarView.addWithConstraints(subview: ruler)
        centeredRulerBarView = ruler
    }

    /// Initializes all the UI for the view controller.
    func initUI() {
        rulerBarView.addBlurEffect()
        createRulerBar()
        self.horizonCorrectionTitle.text = L10n.droneHorizonCalibration
        horizonLevels.forEach { $0.layer.cornerRadius = $0.frame.size.height / 2.0 }

        if !UIApplication.isLandscape {
            let value = UIInterfaceOrientation.landscapeRight.rawValue
            UIDevice.current.setValue(value, forKey: Constants.currentOrientation)
        }
    }

    /// Sets up view models associated with the view.
    func setupViewModels() {
        self.viewModel.state.valueChanged = { [weak self] state in
            guard state.isConnected(),
                  state.flyingState != .flying else {
                self?.closeCalibrationView()
                return
            }

            if let offsetCorrectionProcess = state.offsetCorrectionProcess {
                self?.updateRulerView(offset: offsetCorrectionProcess)
            }
        }
    }

    /// Updates ruler view with values from ground sdk.
    ///
    /// - Parameters:
    ///     - offset: Correction gimbal offset.
    func updateRulerView(offset: GimbalOffsetsCorrectionProcess?) {
        updateRulerBar(offset: offset)
    }

    /// Updates ruler view with selected value
    ///
    /// - Parameters:
    ///     - offset: Correction gimbal offset.
    func updateCorrectionValue(offset: GimbalOffsetsCorrectionProcess?) {
        guard offset?.correctableAxes.contains(.roll) == true,
              let rollSetting = offset?.offsetsCorrection[.roll] else {
            return
        }

        if let barValue = centeredRulerBarView?.model.value {
            rollSetting.value = barValue
        }
    }

    /// Close the view controller.
    func closeCalibrationView() {
        self.viewModel.cancelCalibration()
        self.coordinator?.back()
    }
}

// MARK: - SettingValueRulerViewDelegate
extension HorizonCorrectionViewController: CorrectionRulerViewDelegate {
    func valueDidChange(_ value: Double) {
        updateCorrectionValue(offset: self.viewModel.state.value.offsetCorrectionProcess)
    }
}
