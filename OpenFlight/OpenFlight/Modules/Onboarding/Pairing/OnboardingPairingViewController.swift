//
//  Copyright (C) 2021 Parrot Drones SAS.
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
import CoreLocation

/// Dedicated view controller to show configure drone screen.
public final class OnboardingPairingViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var droneImageView: UIImageView!
    @IBOutlet private weak var configureButton: UIButton!
    @IBOutlet private weak var laterButton: UIButton!

    // MARK: - Private Properties
    private var coordinator: OnboardingCoordinator?

    // MARK: - Init
    static func instantiate(coordinator: OnboardingCoordinator) -> OnboardingPairingViewController {
        let viewController = StoryboardScene.OnboardingPairing.initialScene.instantiate()
        viewController.coordinator = coordinator

        return viewController
    }

    // MARK: - Override Funcs
    public override func viewDidLoad() {
        super.viewDidLoad()

        initUI()
    }

    public override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    public override var prefersStatusBarHidden: Bool {
        return UIApplication.isLandscape
    }

    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

// MARK: - Actions
private extension OnboardingPairingViewController {
    @IBAction func configureButtonTouchedUpInside(_ sender: Any) {
        // TODO viewModel responsibility
        guard Services.hub.connectedDroneHolder.drone != nil else {
            coordinator?.showPairingProcess()
            return
        }

        coordinator?.showHUDScreen()
    }

    @IBAction func laterButtonTouchedUpInside(_ sender: Any) {
        coordinator?.showHUDScreen()
    }
}

// MARK: - Private Funcs
private extension OnboardingPairingViewController {
    /// Initializes UI and wordings.
    func initUI() {
        droneImageView.image = Asset.Alertes.TakeOff.icDroneCalibrationNeeded.image
        titleLabel.makeUp(with: .huge, and: .greenSpring)
        if let targetName = Bundle.main.infoDictionary?["CFBundleName"] as? String {
            titleLabel.text = L10n.configurationConfigureText(targetName)
        }
        descriptionLabel.makeUp(with: .huge)
        descriptionLabel.text = L10n.configurationConfigureYourDrone
        configureButton.cornerRadiusedWith(backgroundColor: .white, radius: Style.largeCornerRadius)
        configureButton.setTitle(L10n.configurationConfigureNow, for: .normal)
        laterButton.setTitle(L10n.commonLater, for: .normal)
    }
}
