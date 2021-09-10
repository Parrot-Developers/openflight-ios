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

/// Dedicated view controller to show dashboard my account screen.
final class DashboardMyAccountViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var connectedAccountsLabel: UILabel!
    @IBOutlet private weak var addMyAccountLabel: UILabel!
    @IBOutlet private weak var addMyAccountView: UIView!
    @IBOutlet private weak var firstView: UIView!
    @IBOutlet private weak var secondView: UIView!
    @IBOutlet private weak var thirdView: UIView!

    // MARK: - Private Properties
    private var coordinator: DashboardCoordinator?

    // MARK: - Init
    static func instantiate(coordinator: DashboardCoordinator) -> DashboardMyAccountViewController {
        let viewController = StoryboardScene.DashboardMyAccount.initialScene.instantiate()
        viewController.coordinator = coordinator

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initUI()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension DashboardMyAccountViewController {
    /// Called when user touches the back button.
    @IBAction func backButtonTouchedUpInside(_ sender: UIButton) {
        coordinator?.back()
    }
}

// MARK: - Private Funcs
private extension DashboardMyAccountViewController {
    /// Initializes UI and wordings.
    func initUI() {
        self.connectedAccountsLabel.makeUp(with: .small,
                                           and: .white50)
        self.addMyAccountLabel.makeUp(and: .white50)
        self.connectedAccountsLabel.text = L10n.dashboardConnectedAccounts.uppercased()
        self.addMyAccountLabel.text = Style.plusSign + L10n.dashboardAddMyAccount
        self.addMyAccountView.cornerRadiusedWith(backgroundColor: .clear,
                                                 borderColor: ColorName.white10.color,
                                                 radius: Style.largeCornerRadius,
                                                 borderWidth: Style.mediumBorderWidth)
        self.firstView.cornerRadiusedWith(backgroundColor: ColorName.white80.color,
                                          radius: Style.largeCornerRadius)
        self.secondView.cornerRadiusedWith(backgroundColor: ColorName.white80.color,
                                          radius: Style.largeCornerRadius)
        self.thirdView.cornerRadiusedWith(backgroundColor: ColorName.white80.color,
                                          radius: Style.largeCornerRadius)
    }
}
