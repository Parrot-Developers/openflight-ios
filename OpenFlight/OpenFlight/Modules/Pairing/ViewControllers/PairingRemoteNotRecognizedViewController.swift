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

import UIKit

/// View controller managing remote not recognized screen.
final class PairingRemoteNotRecognizedViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var panelView: UIView! {
        didSet {
            panelView.customCornered(corners: [.topLeft, .topRight],
                                     radius: Style.largeCornerRadius,
                                     backgroundColor: .white,
                                     borderColor: .clear)
        }
    }
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var firstStepLabel: UILabel!
    @IBOutlet private weak var secondStepLabel: UILabel!
    @IBOutlet private weak var thirdStepLabel: UILabel!

    // MARK: - Private Properties
    private weak var coordinator: PairingCoordinator?

    // MARK: - Setup
    static func instantiate(coordinator: Coordinator) -> PairingRemoteNotRecognizedViewController {
        let viewController = StoryboardScene.PairingRemoteNotRecognized.initialScene.instantiate()
        viewController.coordinator = coordinator as? PairingCoordinator

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        LogEvent.log(.screen(LogEvent.Screen.pairingHowToConnectRemoteToPhone))

        UIView.animate(withDuration: Style.shortAnimationDuration,
                       delay: Style.shortAnimationDuration,
                       animations: {
            self.view.backgroundColor = ColorName.nightRider80.color
        })
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        view.backgroundColor = .clear
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension PairingRemoteNotRecognizedViewController {
    @IBAction func closeButtonTouchedUpInside(_ sender: Any) {
        coordinator?.dismiss()
    }

    /// Background button touched.
    @IBAction func backgroundButtonTouchedUpInside(_ sender: Any) {
        coordinator?.dismiss()
    }
}

// MARK: - Private Funcs
private extension PairingRemoteNotRecognizedViewController {
    /// Update the view.
    func initView() {
        titleLabel.text = L10n.pairingHowToConnectRemote
        titleLabel.font = FontStyle.title.font(isRegularSizeClass)

        firstStepLabel.text = L10n.pairingPlugUsbCable
        firstStepLabel.font = FontStyle.big.font(isRegularSizeClass)

        secondStepLabel.text = L10n.pairingMakeSureBatteryCharged
        secondStepLabel.font = FontStyle.big.font(isRegularSizeClass)

        thirdStepLabel.text = L10n.pairingTryDifferentCable
        thirdStepLabel.font = FontStyle.big.font(isRegularSizeClass)
    }
}
