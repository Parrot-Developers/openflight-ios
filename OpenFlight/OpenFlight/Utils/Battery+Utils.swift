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

// MARK: - Private Enums
private enum Constants {
    static let veryCriticalLevel: Int = 5
    static let criticalLevel: Int = 10
    static let warningLevel: Int = 20
}

// MARK: - Public Structs
/// Struct representing a battery value and its associated alert level.
public struct BatteryValueModel: Equatable {
    /// Battery value.
    var currentValue: Int?

    /// Alert level for current battery value.
    var alertLevel: AlertLevel {
        guard let value = currentValue else {
            return .none
        }

        switch value {
        case ...Constants.veryCriticalLevel:
            return .veryCritical
        case Constants.veryCriticalLevel...Constants.criticalLevel:
            return .critical
        case Constants.criticalLevel...Constants.warningLevel:
            return .warning
        case Constants.warningLevel...:
            return .ready
        default:
            return .none
        }
    }

    /// Image for current alert level.
    var batteryImage: UIImage {
        switch alertLevel {
        case .critical,
             .veryCritical:
            return Asset.Remote.icBatteryCritic.image
        case .warning:
            return Asset.Remote.icBatteryLow.image
        case .ready:
            return Asset.Remote.icBatteryFull.image
        case .none:
            return Asset.Remote.icBatteryNone.image
        }
    }

    var batteryRemoteControl: UIImage {
        switch alertLevel {
        case .critical,
             .veryCritical:
            return Asset.Remote.icBatteryRemoteCritic.image
        case .warning:
            return Asset.Remote.icBatteryRemoteLow.image
        case .ready:
            return Asset.Remote.icBatteryRemoteFull.image
        case .none:
            return Asset.Remote.icBatteryRemoteNone.image
        }
    }

    var batteryUserDevice: UIImage {
        switch alertLevel {
        case .critical,
             .veryCritical:
            return Asset.Remote.icBatteryUserDeviceCritic.image
        case .warning:
            return Asset.Remote.icBatteryUserDeviceLow.image
        case .ready:
            return Asset.Remote.icBatteryUserDeviceFull.image
        case .none:
            return Asset.Remote.icBatteryUserDeviceNone.image
        }
    }
}
