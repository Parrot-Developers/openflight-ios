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
import Combine

/// View in charge of landing animation in HUD.

final class HUDLandingView: UIView, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var rthImageView: UIImageView!
    @IBOutlet private weak var customMessageLabel: UILabel!
    @IBOutlet private weak var customImage: UIImageView!
    @IBOutlet private weak var customView: UIView!

    // MARK: - Private Properties
    private let viewModel = HUDLandingViewModel()
    private var customIndicatorViewModel: CustomIndicatorProvider?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.loadNibContent()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadNibContent()
    }

    func updateView(customMessage: String?, shouldShowLoader: Bool, image: UIImage?) {
        if customMessage == nil {
            rthImageView.isHidden = !viewModel.isLandingOrRth
            rthImageView.image = image
            customView.isHidden = true

            UIView.animate(withDuration: Style.longAnimationDuration,
                           delay: 0.0,
                           options: [.repeat, .autoreverse],
                           animations: {
                            self.rthImageView.alpha = 0.0
                           })

        } else {
            rthImageView.isHidden = !viewModel.isLandingOrRth
            rthImageView.image = image
            customView.isHidden = !viewModel.isLandingOrRth
            customMessageLabel.text = customMessage
            customImage.isHidden = !shouldShowLoader
            customImage.startRotate()

            UIView.animate(withDuration: Style.longAnimationDuration,
                           delay: 0.0,
                           options: [.repeat, .autoreverse],
                           animations: {
                            self.rthImageView.alpha = 0.0
                           })
        }
    }

    func hideAllView() {
        rthImageView.isHidden = true
        customView.isHidden = true
        customImage.stopRotate()
    }

    func setCustomProvider(customIndicatorProvider: CustomIndicatorProvider?) {
        customIndicatorViewModel = customIndicatorProvider
    }

    func commonInitHUDRTHAnimationView() {
        if let customIndicatorViewModel = customIndicatorViewModel {
            customIndicatorViewModel.customMissionActive
                .removeDuplicates()
                .combineLatest(viewModel.isLanding.removeDuplicates(),
                               viewModel.isReturnHomeActive.removeDuplicates())
                .combineLatest(customIndicatorViewModel.customMessage.removeDuplicates(),
                               customIndicatorViewModel.shouldShowLoader.removeDuplicates(),
                               viewModel.image.removeDuplicates())
                .sink { [unowned self] (arg0, customMessage, shouldShowLoader, image) in
                    let (customMissionActive, isLanding, isReturnHomeActive) = arg0
                    if isLanding || isReturnHomeActive {
                        if customMissionActive {
                            updateView(customMessage: customMessage, shouldShowLoader: shouldShowLoader, image: image)
                        } else {
                            updateView(customMessage: nil, shouldShowLoader: false, image: image)
                        }
                    } else {
                        hideAllView()
                    }
                }
                .store(in: &cancellables)

        } else {
            viewModel.isLanding
                .removeDuplicates()
                .combineLatest(viewModel.isReturnHomeActive.removeDuplicates(),
                               viewModel.image.removeDuplicates())
                .sink { [unowned self] (isLanding, isReturnHomeActive, image) in
                    if isLanding || isReturnHomeActive {
                        updateView(customMessage: nil, shouldShowLoader: false, image: image)
                    } else {
                        hideAllView()
                    }
                }
                .store(in: &cancellables)
        }
    }
}
