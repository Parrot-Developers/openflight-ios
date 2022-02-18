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
import AudioToolbox

/// Manages HUD's banner alert view.
final class HUDAlertBannerViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var mainLabel: UILabel! {
        didSet {
            mainLabel.makeUp(with: .large)
        }
    }
    @IBOutlet private weak var backgroundView: UIView! {
        didSet {
            backgroundView.applyCornerRadius(Style.mediumCornerRadius)
        }
    }

    // MARK: - Private Properties
    private var viewModel = HUDAlertBannerViewModel()

    // MARK: - Private Enums
    private enum Constants {
        static let delayBetweenTwoCriticalVibrations: TimeInterval = 0.6
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.state.valueChanged = { [weak self] state in
            self?.updateView(state: state)
        }
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Private Funcs
private extension HUDAlertBannerViewController {
    /// Updates the view with given state.
    ///
    /// - Parameters:
    ///    - state: current banner state
    func updateView(state: HUDAlertBannerState) {
        guard state.isConnected(),
            let alert = state.alert
            else {
                backgroundView.isHidden = true
                return
        }
        mainLabel.text = alert.label
        imageView.image = alert.icon
        imageView.isHidden = alert.icon == nil
        imageView.tintColor = alert.level.iconColor
        backgroundView.backgroundColor = alert.level.color
        mainLabel.textColor = alert.level.textColor
        backgroundView.isHidden = false
        if state.shouldVibrate {
            vibrateNow(withSecondVibration: alert.level == .critical)
        }
        view.layoutIfNeeded()
    }

    /// Starts phone vibration.
    ///
    /// - Parameters:
    ///    - secondVibration: if true, device vibrates a second time
    func vibrateNow(withSecondVibration secondVibration: Bool) {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        if secondVibration {
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.delayBetweenTwoCriticalVibrations) {
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            }
        }
    }
}
