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
import GroundSdk
import Combine

/// View Controller used to display the horizon correction screen.
final class HorizonCorrectionViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var horizonCorrectionTitle: UILabel!
    @IBOutlet private weak var backButton: UIButton!
    @IBOutlet private var horizonLevels: [UIView]!
    @IBOutlet private weak var rulerBarView: UIView!

    // MARK: - Private Properties
    private var viewModel: HorizonCorrectionViewModel!
    private var centeredRulerBarView: CorrectionRulerView?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Private Enums
    private enum Constants {
        static let currentOrientation: String = "orientation"
    }

    // MARK: - Setup
    /// Instantiate View controller.
    ///
    /// - Parameters:
    ///     - viewModel: the view model
    /// - Returns: the newly view controller created.
    static func instantiate(viewModel: HorizonCorrectionViewModel) -> HorizonCorrectionViewController {
        let viewController = StoryboardScene.HorizonCorrection.horizonCorrectionViewController.instantiate()
        viewController.viewModel = viewModel
        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        self.initUI()
        self.observeViewModel()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension HorizonCorrectionViewController {
    /// Function called when the back button is clicked.
    @IBAction func backButtonTouchedUpInside(_ sender: UIButton) {
        self.viewModel.userDidTapBack()
    }
}

// MARK: - Private Funcs
private extension HorizonCorrectionViewController {
    /// updates ruler bar with new offset.
    ///
    /// - Parameters:
    ///     - offset: Correction gimbal offset.
    /// - Returns: Correction ruler model.
    func getRulerBarModel(offset: GimbalOffsetsCorrectionProcess) -> CorrectionRulerModel {
        guard let roll = offset.offsetsCorrection[.roll] else { return CorrectionRulerModel() }
        let minValue = roll.min
        let maxValue = roll.max
        let value = roll.value
        return CorrectionRulerModel(value: value,
                                    minValue: minValue,
                                    maxValue: maxValue,
                                    step: 0.1,
                                    unit: .degree,
                                    orientation: .horizontal)
    }

    /// Adds ruler bar to view controller.
    ///
    /// - Parameters:
    ///     - offset: Correction gimbal offset.
    func createRulerBar(offset: GimbalOffsetsCorrectionProcess) {
        let model = getRulerBarModel(offset: offset)
        let ruler = CorrectionRulerView(orientation: .horizontal, model: model)
        ruler.delegate = self
        rulerBarView.addWithConstraints(subview: ruler)
        centeredRulerBarView = ruler
    }

    /// Initializes all the UI for the view controller.
    func initUI() {
        backButton.addShadow(shadowOpacity: 1.0)
        horizonCorrectionTitle.text = L10n.droneHorizonCalibration
        horizonCorrectionTitle.font = FontStyle.title.font(isRegularSizeClass)
        horizonCorrectionTitle.addShadow(shadowOpacity: 1.0)
        horizonLevels.forEach { $0.layer.cornerRadius = $0.frame.size.height / 2.0 }

        if !UIApplication.isLandscape {
            let value = UIInterfaceOrientation.landscapeRight.rawValue
            UIDevice.current.setValue(value, forKey: Constants.currentOrientation)
        }
    }

    /// Observe view model associated to the view controller.
    func observeViewModel() {
        viewModel.$offsetsCorrectionProcess
            .removeDuplicates()
            .compactMap { $0 }
            .first()
            .sink { [unowned self] offset in
                createRulerBar(offset: offset)
            }
            .store(in: &cancellables)
    }

    /// Updates ruler view with selected value
    ///
    /// - Parameters:
    ///     - value: correction value
    func updateCorrectionValue(value: Double) {
        guard let offset = self.viewModel.offsetsCorrectionProcess,
              offset.correctableAxes.contains(.roll) == true,
              let rollSetting = offset.offsetsCorrection[.roll] else {
            return
        }

        rollSetting.value = value
    }
}

// MARK: - SettingValueRulerViewDelegate
extension HorizonCorrectionViewController: CorrectionRulerViewDelegate {
    func valueDidChange(_ value: Double) {
        updateCorrectionValue(value: value)
    }
}
