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

// MARK: - Internal Enums
/// Represents alert panel open/close mode.
enum AlertPanelMode {
    /// Alert panel is closed.
    case closed
    /// Alert panel is opened.
    case opened

    /// Returns default value.
    static var preset: AlertPanelMode {
        return .closed
    }

    /// Returns unique key for notification.
    static var notificationKey: String {
        return "alertPanelModeKey"
    }
}

/// Class that manages alert panel on HUD.

final class AlertControls: NSObject {
    // MARK: - Outlets
    @IBOutlet private weak var alertPanelView: UIView!
    @IBOutlet private weak var trailingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var widthConstraint: NSLayoutConstraint!

    // MARK: - Private Properties
    private var alertPanelMode: AlertPanelMode = .preset {
        didSet {
            if oldValue != alertPanelMode {
                NotificationCenter.default.post(name: .alertPanelModeDidChange,
                                                object: self,
                                                userInfo: [AlertPanelMode.notificationKey: alertPanelMode])
            }
        }
    }
    private var panelWidth: CGFloat {
        Layout.sidePanelWidth(alertPanelView.isRegularSizeClass)
    }
}

// MARK: - HUDAlertPanelDelegate
extension AlertControls: HUDAlertPanelDelegate {
    func showAlertPanel() {
        guard alertPanelMode == .closed else { return }
        alertPanelMode = .opened
        updateConstraints()
    }

    func hideAlertPanel() {
        guard alertPanelMode == .opened else { return }
        alertPanelMode = .closed
        updateConstraints()
    }

    /// Updates panel constraint for showing/hiding.
    ///
    /// - Parameter animated: whether changes need to be animated
    func updateConstraints(animated: Bool = true) {
        widthConstraint.constant = panelWidth
        trailingConstraint.constant = alertPanelMode == .opened ? 0 : -panelWidth
        guard animated else { return }
        UIView.animate { self.alertPanelView.superview?.layoutIfNeeded() }
    }
}
