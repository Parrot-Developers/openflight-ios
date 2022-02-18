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

private extension ULogTag {
     static let tag = ULogTag(name: "StereoCalibrationProgressView")
}

class StereoCalibrationProgressView: UIView, NibOwnerLoadable {

    // MARK: - Outlet

    @IBOutlet weak var missionResultLabel: UILabel!
    @IBOutlet weak var missionStateLabel: UILabel!
    @IBOutlet weak var progressViewContainer: UIView!
    @IBOutlet weak var calibrationTitle: UILabel!
    @IBOutlet weak var finishedButton: ActionButton!
    @IBOutlet weak var stopButton: ActionButton!
    @IBOutlet weak var calibrationCompleteImageView: UIImageView!
    @IBOutlet weak var calibrationErrorLabel: UILabel!
    @IBOutlet weak var landingStackView: UIStackView!
    @IBOutlet weak var landingButton: ActionButton!
    @IBOutlet weak var landingTitle: UILabel!
    @IBOutlet private weak var panelTitleLabel: UILabel!

    private var progressView = CircleProgressView()
    private var cancellables = Set<AnyCancellable>()
    private var stereoCalibViewModel: StereoCalibrationViewModel! {
        didSet {
            bindViewModel()
            setupUI()
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

        stopButton.setup(image: Asset.Common.Icons.stop.image, title: nil, style: .destructive)
        finishedButton.setup(title: L10n.ok, style: .validate)
        landingButton.model = actionButtonModel
        landingButton.setBackgroundImage(Asset.Alertes.AutoLanding.icAutoLanding.image, for: .normal)
        progressViewContainer.addWithConstraints(subview: progressView)
        progressView.backgroundColor = .clear
        panelTitleLabel.text = L10n.loveCalibrationTitle
        landingTitle.text = L10n.loveCalibrationDone
    }

    /// Loads the view from a xib.
    func commonInit() {
        loadNibContent()
    }

    /// Binds the view model to the view.
    func bindViewModel() {
        stereoCalibViewModel.calibrationStateMessage
            .compactMap { $0 }
            .sink { [unowned self] calibrationMessage in
                missionStateLabel.text = calibrationMessage
            }
            .store(in: &cancellables)

        stereoCalibViewModel.calibrationPercentage
            .compactMap { $0 }
            .sink { [unowned self] percentage in
                progressView.setProgress(percentage/100)
            }
            .store(in: &cancellables)

        stereoCalibViewModel.$shouldHideProgressView
            .sink { [unowned self] shouldHideProgressView in
                progressView.isHidden = shouldHideProgressView
            }
            .store(in: &cancellables)

        stereoCalibViewModel.$stopButtonHidden
            .sink { [unowned self] stopButtonHidden in
                stopButton.isHidden = stopButtonHidden
            }
            .store(in: &cancellables)

        stereoCalibViewModel.$finishedButtonHidden
            .sink { [unowned self] finishedButtonHidden in
                finishedButton.isHidden = finishedButtonHidden
            }
            .store(in: &cancellables)

        stereoCalibViewModel.$missionStateHidden
            .sink { [unowned self] missionStateHidden in
                missionStateLabel.isHidden = missionStateHidden
            }
            .store(in: &cancellables)

        stereoCalibViewModel.$calibrationCompleteImageHidden
            .sink { [unowned self] calibrationCompleteImageHidden in
                calibrationCompleteImageView.isHidden = calibrationCompleteImageHidden
            }
            .store(in: &cancellables)

        stereoCalibViewModel.$calibrationTitle
            .sink { [unowned self] title in
                calibrationTitle.text = title
            }
            .store(in: &cancellables)

        stereoCalibViewModel.$calibrationTitleHidden
            .sink { [unowned self] missionTitleHidden in
                calibrationTitle.isHidden = missionTitleHidden
            }
            .store(in: &cancellables)

        stereoCalibViewModel.$calibrationTitleColor
            .sink { [unowned self] calibrationTitleColor in
                calibrationTitle.textColor = calibrationTitleColor
            }
            .store(in: &cancellables)

        stereoCalibViewModel.$landingButtonHidden
            .sink { [unowned self] landingButtonHidden in
                landingStackView.isHidden = landingButtonHidden
            }
            .store(in: &cancellables)

        stereoCalibViewModel.$calibrationMessageColor
            .sink { [unowned self] messageColor in
                missionStateLabel.textColor = messageColor
            }
            .store(in: &cancellables)

        stereoCalibViewModel.$calibrationResultHidden
            .sink { [unowned self] calibrationResultHidden in
                missionResultLabel.isHidden = calibrationResultHidden
            }
            .store(in: &cancellables)

        stereoCalibViewModel.$calibrationResultColor
            .sink { [unowned self] calibrationResultColor in
                missionResultLabel.textColor = calibrationResultColor
            }
            .store(in: &cancellables)

        stereoCalibViewModel.$calibrationResultText
            .sink { [unowned self] calibrationResultText in
                missionResultLabel.text = calibrationResultText
            }
            .store(in: &cancellables)

        stereoCalibViewModel.$finishedButtonHighlighted
            .sink { [unowned self] finishedButtonHighlighted in
                if finishedButtonHighlighted {
                    finishedButton.setTitleColor(ColorName.white.color, for: .normal)
                    finishedButton.customCornered(corners: [.allCorners],
                                                  radius: Style.largeCornerRadius,
                                                  backgroundColor: ColorName.highlightColor.color,
                                                  borderColor: ColorName.clear.color,
                                                  borderWidth: Style.mediumBorderWidth)
                } else {
                    finishedButton.setTitleColor(ColorName.defaultTextColor.color, for: .normal)
                    finishedButton.customCornered(corners: [.allCorners],
                                                  radius: Style.largeCornerRadius,
                                                  backgroundColor: ColorName.whiteAlbescent.color,
                                                  borderColor: ColorName.defaultTextColor20.color,
                                                  borderWidth: Style.mediumBorderWidth)
                }
            }
            .store(in: &cancellables)

        stereoCalibViewModel.$calibrationErrorText
            .sink { [unowned self] calibrationErrorText in
                calibrationErrorLabel.text = calibrationErrorText
            }
            .store(in: &cancellables)

        stereoCalibViewModel.$calibrationErrorHidden
            .sink { [unowned self] calibrationErrorHidden in
                calibrationErrorLabel.isHidden = calibrationErrorHidden
            }
            .store(in: &cancellables)
    }
}

// MARK: - Action

extension StereoCalibrationProgressView {

    @IBAction func cancelCalibration(_ sender: Any) {
        stereoCalibViewModel.cancelCalibration()
        stereoCalibViewModel.dismissProgressView(endState: .aborted)
    }

    @IBAction func closeAfterCalibration(_ sender: Any) {
        stereoCalibViewModel.askingForBack()
    }

    @IBAction func landingDrone(_ sender: Any) {
        stereoCalibViewModel.landDrone()
    }
}
