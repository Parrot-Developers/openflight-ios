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

/// Dedicated view controller to show localization access screen.
public final class OnboardingLocalizationViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var gpsTitleLabel: UILabel!
    @IBOutlet private weak var gpsSubtitleLabel: UILabel!
    @IBOutlet private weak var gpsDescriptionLabel: UILabel!
    @IBOutlet private weak var continueButton: UIButton!

    // MARK: - Private Properties
    private var coordinator: OnboardingCoordinator?

    // MARK: - Init
    static func instantiate(coordinator: OnboardingCoordinator) -> OnboardingLocalizationViewController {
        let viewController = StoryboardScene.OnboardingLocalizationViewController.initialScene.instantiate()
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
private extension OnboardingLocalizationViewController {
    @IBAction func continueButtonTouchedUpInside(_ sender: Any) {
        coordinator?.showOnBoardingThirdScreen()
    }
}

// MARK: - Private Funcs
private extension OnboardingLocalizationViewController {
    /// Initializes UI and wordings.
    func initUI() {
        titleLabel.makeUp(with: .huge)
        titleLabel.text = L10n.authorizationsTitle
        gpsTitleLabel.makeUp(with: .small, and: .greenSpring)
        gpsTitleLabel.text = L10n.commonRequired.uppercased()
        gpsSubtitleLabel.makeUp(with: .huge)
        gpsSubtitleLabel.text = L10n.permissionGpsPositionTitle
        gpsDescriptionLabel.makeUp(with: .big)
        gpsDescriptionLabel.text = L10n.permissionGpsPositionContent
        continueButton.cornerRadiusedWith(backgroundColor: .white, radius: Style.largeCornerRadius)
        continueButton.setTitle(L10n.commonContinue, for: .normal)
    }
}
