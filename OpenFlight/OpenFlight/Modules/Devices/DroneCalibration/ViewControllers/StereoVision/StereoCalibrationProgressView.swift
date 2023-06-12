//    Copyright (C) 2021 Parrot Drones SAS
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

import Foundation
import Combine
import UIKit
import Reusable
import GroundSdk

class StereoCalibrationProgressView: UIView, NibOwnerLoadable {

    // MARK: - Outlet

    @IBOutlet weak var mainProgressViewContainer: UIView!
    @IBOutlet weak var progressViewContainer: UIView!
    @IBOutlet weak var containerStackView: MainContainerStackView!
    @IBOutlet weak var circleProgressView: CircleProgressView!
    @IBOutlet weak var missionStateLabel: UILabel!
    @IBOutlet weak var finishedButton: ActionButton!
    @IBOutlet weak var stopView: StopView!
    @IBOutlet weak var calibrationCompleteImageView: UIImageView!
    @IBOutlet weak var calibrationErrorLabel: UILabel!
    @IBOutlet weak var landingStackView: UIStackView!
    @IBOutlet weak var landingButton: ActionButton!
    @IBOutlet weak var landingTitle: UILabel!

    private var cancellables = Set<AnyCancellable>()
    private var stereoCalibViewModel: StereoCalibrationViewModel! {
        didSet {
            setupUI()
            bindViewModel()
        }
    }

    // MARK: - Init

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    // MARK: - Static func

    func setup(viewModel: StereoCalibrationViewModel) {
        cancellables = []
        stereoCalibViewModel = viewModel
    }
}

// MARK: - UI Setup

private extension StereoCalibrationProgressView {

    /// Initializes the UI.
    func setupUI() {
        let actionButtonModel = ActionButtonModel(image: Asset.Alertes.AutoLanding.icAutoLanding.image,
                                                  backgroundColor: .clear,
                                                  borderColor: .clear,
                                                  hasShadow: true,
                                                  style: .secondary1)
        landingButton.model = actionButtonModel
        landingTitle.makeUp(with: .big, color: .defaultTextColor)
        landingTitle.text = L10n.loveCalibrationDone

        stopView.style = .classic
        stopView.delegate = self

        finishedButton.setup(title: L10n.ok, style: .validate)

        calibrationErrorLabel.makeUp(with: .current, color: .errorColor)
        calibrationCompleteImageView.heightAnchor.constraint(equalToConstant: Layout.buttonIntrinsicHeight(isRegularSizeClass)).isActive = true

        containerStackView.screenBorders = [.bottom, .right]
    }

    /// Loads the view from a xib.
    func commonInit() {
        loadNibContent()
    }

    /// Binds the view model to the view.
    func bindViewModel() {
        stereoCalibViewModel.calibrationStateMessage
            .compactMap { $0 }
            .removeDuplicates()
            .sink { [unowned self] in
                mainProgressViewContainer.accessibilityLabel = $0
                missionStateLabel.text = $0
            }
            .store(in: &cancellables)

        stereoCalibViewModel.calibrationPercentagePublisher
            .compactMap { $0 }
            .removeDuplicates()
            .sink { [unowned self] in
                mainProgressViewContainer.accessibilityValue = "\($0)"
                circleProgressView.setProgress($0 / 100)
            }
            .store(in: &cancellables)

        stereoCalibViewModel.$shouldHideCircleProgressView
            .removeDuplicates()
            .sink { [unowned self] in
                progressViewContainer.isHidden = $0
            }
            .store(in: &cancellables)

        stereoCalibViewModel.$stopButtonHidden
            .removeDuplicates()
            .sink { [unowned self] in
                stopView.isHidden = $0
            }
            .store(in: &cancellables)

        stereoCalibViewModel.$finishedButtonHidden
            .removeDuplicates()
            .sink { [unowned self] in
                finishedButton.isHidden = $0
            }
            .store(in: &cancellables)

        stereoCalibViewModel.$finishedButtonStyle
            .removeDuplicates()
            .sink { [unowned self] in
                finishedButton.updateStyle($0)
            }
            .store(in: &cancellables)

        stereoCalibViewModel.$missionStateHidden
            .removeDuplicates()
            .sink { [unowned self] in
                missionStateLabel.isHidden = $0
            }
            .store(in: &cancellables)

        stereoCalibViewModel.$calibrationCompleteImage
            .removeDuplicates()
            .sink { [unowned self] in
                calibrationCompleteImageView.image = $0
            }
            .store(in: &cancellables)

        stereoCalibViewModel.$calibrationCompleteImageHidden
            .removeDuplicates()
            .sink { [unowned self] in
                calibrationCompleteImageView.isHidden = $0
            }
            .store(in: &cancellables)

        stereoCalibViewModel.$landingButtonHidden
            .removeDuplicates()
            .sink { [unowned self] in
                landingStackView.isHidden = $0
            }
            .store(in: &cancellables)

        stereoCalibViewModel.$calibrationMessageColor
            .removeDuplicates()
            .sink { [unowned self] in
                missionStateLabel.textColor = $0
            }
            .store(in: &cancellables)

        stereoCalibViewModel.$calibrationErrorText
            .removeDuplicates()
            .sink { [unowned self] in
                calibrationErrorLabel.text = $0
            }
            .store(in: &cancellables)

        stereoCalibViewModel.$calibrationErrorHidden
            .removeDuplicates()
            .sink { [unowned self] in
                calibrationErrorLabel.isHidden = $0
            }
            .store(in: &cancellables)
    }
}

// MARK: - Action

extension StereoCalibrationProgressView {

    @IBAction func finishedButtonTouchedUpInside(_ sender: Any) {
        stereoCalibViewModel.finishCalibration()
    }

    @IBAction func landingButtonTouchedUpInside(_ sender: Any) {
        stereoCalibViewModel.landDrone()
    }
}

// MARK: - StopViewDelegate
extension StereoCalibrationProgressView: StopViewDelegate {
    func didClickOnStop() {
        stereoCalibViewModel.cancelCalibration()
    }
}
