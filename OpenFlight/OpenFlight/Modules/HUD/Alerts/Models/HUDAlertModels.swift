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

// MARK: - Protocols
/// Protocol that defines an alert to display on HUD.
public protocol HUDAlertType {
    /// Alert category level.
    var level: HUDAlertLevel { get }
    /// Alert category.
    var category: AlertCategoryType { get }
    /// Alert raw value.
    var priority: String { get }
    /// Label for the alert type.
    var label: String { get }
    /// Associated icon to the alert type.
    var icon: UIImage? { get }
    /// Action associated with the alert type.
    var actionType: AlertActionType? { get }
    /// Minimal delay between two vibrations for this alert.
    var vibrationDelay: TimeInterval { get }
    /// Checks if alert is the same as given one.
    ///
    /// - Parameters:
    ///    - other: alert to test
    /// - Returns: result of test
    func isSameAlert(as other: HUDAlertType?) -> Bool
}

// MARK: - Public Funcs
public extension HUDAlertType {
    func isSameAlert(as other: HUDAlertType?) -> Bool {
        guard let other = other else {
            return false
        }
        return self.level == other.level
            && self.priority == other.priority
    }
}

// MARK: - Public Enums
/// Category for HUD alert.
public enum AlertCategoryType {
    case animations
    case autoLanding
    case componentsCamera
    case componentsImu
    case componentsMotor
    case conditions
    case conditionsWind
    case flightZone
    case geofence
    case obstacleAvoidance
    case sdCard
    case takeoff
    case wifi
    case flightMode
}

/// Stores constants about alerts.
public enum HUDAlertConstants {
    /// Default vibration delay.
    public static let defaultVibrationDelay: TimeInterval = 90.0
}

/// Alert level for HUD alert.
public enum HUDAlertLevel: Int {
    case critical = 1
    case warning
    case info
    case tutorial

    /// Color for alert.
    var color: UIColor {
        switch self {
        case .critical:
            return ColorName.redTorch.color
        case .warning:
            return ColorName.black60.color
        default:
            return .clear
        }
    }

    /// Color for alert icon.
    var iconColor: UIColor {
        switch self {
        case .critical:
            return ColorName.white.color
        case .warning:
            return ColorName.orangePeel.color
        default:
            return .clear
        }
    }

    /// Returns true if alert is an error.
    var isError: Bool {
        switch self {
        case .critical, .warning:
            return true
        case .info, .tutorial:
            return false
        }
    }
}

/// Action type for HUD alert.
public enum AlertActionType {
    case landing
    case rth
}
