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

// MARK: - Protocols
/// Protocol describing alert panel state.
public protocol AlertPanelState {
    /// Alert title.
    var title: String? { get }
    /// Alert subtitle.
    var subtitle: String? { get }
    /// Alert title image
    var titleImage: UIImage? { get }
    /// Alert subtitle color. Used for animation color too.
    var subtitleColor: UIColor? { get }
    /// Main image of the panel.
    var icon: UIImage? { get }
    /// Set of image for the animation.
    var animationImages: [UIImage]? { get }
    /// Current state.
    var state: AlertPanelCurrentState? { get set }
    /// Boolean describing if alert has been force hidden.
    var isAlertForceHidden: Bool { get set }
    /// Countdown for action.
    var countdown: Int? { get }
    /// Initial countdown value.
    var initialCountdown: TimeInterval? { get }
    /// Tells if start view need to be displayed.
    var startViewIsVisible: Bool { get }
    /// Tells if action label need to be displayed.
    var actionLabelIsVisible: Bool { get }
    /// Action label description text.
    var actionLabelText: String? { get }
    /// Provides a Return to Home alert type only in case of RTH feature.
    var rthAlertType: RthAlertType? { get }
    /// Provides stop button style.
    var stopViewStyle: StopViewStyle? { get }
    /// Tells if we need to show the alert panel.
    var shouldShowAlertPanel: Bool { get }
    /// Tells if the alert has a text count down.
    var hasTextCountdown: Bool { get }
    /// Tells if the alert has an animation.
    var hasAnimation: Bool { get }
    /// Custom countdown message function.
    /// It is used to provide a string with an associated countdown directly in the view.
    var countdownMessage: ((Int) -> String)? { get }
}

/// Protocol used to describes alert panel methods.
public protocol AlertPanelActionType {
    /// Starts alert action.
    func startAction()
    /// Cancels alert action.
    func cancelAction()
}

// MARK: - Public Enums
public enum AlertPanelCurrentState {
    case unavailable
    case available
    case started

    /// String describing alert panel current state.
    var description: String {
        switch self {
        case .unavailable:
            return "Unavailable"
        case .available:
            return "Available"
        case .started:
            return "Started"
        }
    }
}

/// Enum which indiquates all Battery alert types.
public enum RthAlertType: Int {
    /// Auto Landing alert.
    case autoLandingAlert
    /// Drone battery critical alert.
    case droneBatteryCriticalAlert
    /// Drone battery warning alert.
    case droneBatteryWarningAlert

    /// Returns the alert subtitle.
    var subtitle: String? {
        switch self {
        case .autoLandingAlert:
            return L10n.alertReturnHomeDroneVeryLowBattery
        case .droneBatteryCriticalAlert:
            return L10n.alertReturnHomeDroneVeryLowBattery
        case .droneBatteryWarningAlert:
            return L10n.alertReturnHomeDroneLowBattery
        }
    }

    /// Returns alert priority.
    var priority: Int {
        return rawValue
    }
}

// MARK: - Internal Enums
/// Describes the device type.
enum DeviceType {
    case drone
    case userDevice
    case remoteControl
}

/// Notification values for alert panel.
enum HUDPanelNotifications {
    /// Returns unique key for Hand Launch and Hand Land notifications.
    static var handDetectedNotificationKey: String {
        return "handModalPresentDidChange"
    }
}
