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

/// Class that manages mission launcher menu on HUD.

final class MissionControls: NSObject {
    // MARK: - Outlets
    @IBOutlet private weak var missionLauncherView: UIView!

    // MARK: - Private Properties
    private var missionLauncherDisplayed: Bool = false {
        didSet {
            if oldValue != missionLauncherDisplayed {
                if missionLauncherDisplayed {
                    Services.hub.ui.uiComponentsDisplayReporter.missionMenuIsDisplayed()
                } else {
                    Services.hub.ui.uiComponentsDisplayReporter.missionMenuIsHidden()
                }
            }
        }
    }

    // MARK: - Private Enums
    private enum Constants {
        static let animationDuration: TimeInterval = 0.2
    }

    // MARK: - Internal Funcs
    /// Show mission launcher view controller with given viewModel.
    func showMissionLauncher(completion: ((Bool) -> Void)? = nil) {
        missionLauncherDisplayed = true
        guard missionLauncherView.isHidden == true else { return }
        UIView.animate(withDuration: Constants.animationDuration, animations: {
            self.missionLauncherView.isHidden = false
        }, completion: completion)
    }

    /// Hides mission launcher view controller.
    func hideMissionLauncher() {
        guard missionLauncherView.isHidden == false else { return }
        UIView.animate(withDuration: Constants.animationDuration, animations: {
            self.missionLauncherView.isHidden = true
        }, completion: { _ in
            self.missionLauncherDisplayed = false
        })
    }
}
