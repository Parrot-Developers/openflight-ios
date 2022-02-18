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

/// Dedicated view controller to show settings DRI infos.
final class SettingsDRIViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var containerPanel: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var titleDescriptionLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!

    // MARK: - Private Properties
    private var coordinator: SettingsCoordinator?

    // MARK: - Init
    static func instantiate(coordinator: SettingsCoordinator) -> SettingsDRIViewController {
        let viewController = StoryboardScene.SettingsDRIViewController.initialScene.instantiate()
        viewController.coordinator = coordinator

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        UIView.animate(withDuration: Style.shortAnimationDuration, delay: Style.shortAnimationDuration) {
            self.view.backgroundColor = ColorName.nightRider80.color
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.backgroundColor = .clear
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension SettingsDRIViewController {
    /// Close action.
    @IBAction func closeButtonTouchedUpInside(_ sender: Any) {
        closeView()
    }

    @IBAction func backgroundButtonTouchedUpInside(_ sender: Any) {
        closeView()
    }
}

// MARK: - Private Funcs
private extension SettingsDRIViewController {
    /// Initializes UI and wordings.
    func initUI() {
        containerPanel.customCornered(corners: [.topLeft, .topRight], radius: Style.largeCornerRadius)
        titleLabel.text = L10n.settingsConnectionBroadcastDri
        titleDescriptionLabel.text = L10n.settingsConnectionDriDialogTitle
        descriptionLabel.text = L10n.settingsConnectionDriDialogText
    }

    /// Closes the view.
    func closeView() {
        coordinator?.dismiss()
    }
}
