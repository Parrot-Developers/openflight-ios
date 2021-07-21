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

/// Handles HUD's top banner that displays alerts and some specific informations (hdr, precise home, etc).
final class HUDTopBannerViewController: UIViewController, DelayedTaskProvider {
    // MARK: - Outlets
    @IBOutlet private weak var cameraLabelsContainer: UIView!
    @IBOutlet private weak var homeLabelsContainer: UIView!
    @IBOutlet private weak var hdrInfoView: HUDTopBannerInfoView!
    @IBOutlet private weak var lockAeInfoView: HUDTopBannerInfoView!
    @IBOutlet private weak var homeInfoView: HUDTopBannerInfoView!

    // MARK: - Internal Properties
    var delayedTaskComponents = DelayedTaskComponents()

    // MARK: - Private Properties
    private var viewModel = HUDTopBannerViewModel()

    // MARK: - Private Enums
    private enum Constants {
        static let homeSetDisplayDuration: TimeInterval = 5.0
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        setupModels()
        setupViewModel()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Private Funcs
private extension HUDTopBannerViewController {
    /// Sets up subviews models.
    func setupModels() {
        hdrInfoView.model = HUDTopBannerInfoModel(image: nil,
                                                  text: L10n.cameraHdr,
                                                  backgroundColor: ColorName.yellowSea.color)
        lockAeInfoView.model = HUDTopBannerInfoModel(image: Asset.Common.Icons.iconLock.image,
                                                     text: L10n.lockAe,
                                                     backgroundColor: ColorName.yellowSea.color)
        homeInfoView.model = HUDTopBannerInfoModel(image: Asset.Common.Icons.iconHome.image,
                                                   text: nil,
                                                   backgroundColor: ColorName.greenSpring.color)
    }

    /// Sets up view model.
    func setupViewModel() {
        viewModel.state.valueChanged = { [weak self] state in
            self?.updateInfoBanner(state: state)
        }
        updateInfoBanner(state: viewModel.state.value)
    }

    /// Updates banner display.
    ///
    /// - Parameters:
    ///    - state: top banner state
    func updateInfoBanner(state: HUDTopBannerState) {
        guard state.isConnected(),
              !state.isDisplayingAlert else {
            cameraLabelsContainer.isHidden = true
            homeLabelsContainer.isHidden = true
            return
        }

        hdrInfoView.isHidden = !state.hdrOn
        lockAeInfoView.isHidden = !state.shouldDisplayAutoExposureLock
        cameraLabelsContainer.isHidden = !state.lockAeMode.locked && !state.hdrOn
        updateHomeInfo(homeState: state.homeState)
    }

    /// Updates home info.
    ///
    /// - Parameters:
    ///    - homeState: home state
    func updateHomeInfo(homeState: HUDTopBannerHomeState) {
        homeLabelsContainer.isHidden = homeState == .none && !isTaskPending()
        if let homeDisplayText = homeState.displayText {
            // Avoid removing text if state is none but a home info is currently shown.
            homeInfoView.model?.text = homeDisplayText
        }
        switch homeState {
        case .preciseHomeSet, .homePositionSet:
            setupDelayedTask(hideHomeInfoIfNeeded, delay: Constants.homeSetDisplayDuration)
        case .preciseRthInProgress, .preciseLandingInProgress:
            cancelDelayedTask()
        case .none:
            break
        }
    }

    /// Hides home info if needed.
    func hideHomeInfoIfNeeded() {
        homeLabelsContainer.isHidden = viewModel.state.value.homeState == .none
    }
}
