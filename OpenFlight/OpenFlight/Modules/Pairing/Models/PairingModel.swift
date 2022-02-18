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

// MARK: - Protocol
/// Parent model for controller pairing.
protocol PairingModel {
    // MARK: - Internal Properties
    // State.
    var pairingState: PairingState { get }
    // Title.
    var title: String { get }
    // Background color of the cell corresponding of the pairing state.
    var backgroundColor: UIColor { get }
    // Border color of the cell corresponding of the pairing state.
    var borderColor: UIColor { get }
    // Cell Image.
    var image: UIImage { get }
    // Cell Image tint color.
    var imageTintColor: UIColor { get }
    // Action Title.
    var actionTitle: String? { get }
}

extension PairingModel {
    var backgroundColor: UIColor {
        switch pairingState {
        case .todo:
            return UIColor(named: .whiteAlbescent)
        case .doing,
             .done:
            return .white
        }
    }

    var borderColor: UIColor {
        switch pairingState {
        case .todo,
             .done:
            return .clear
        case .doing:
            return UIColor(named: .highlightColor)
        }
    }
}

// MARK: - Internal Enums
/// Enum which specify connection state of the controller.
enum PairingState {
    case todo
    case doing
    case done
}

/// Remote pairing model.
class RemotePairingModel: PairingModel {
    // MARK: - Internal Properties
    var pairingState: PairingState
    var image: UIImage = Asset.Pairing.icRemotePhoneMediumPairing.image
    var imageTintColor: UIColor = UIColor(named: .defaultTextColor)
    var title: String = L10n.pairingConnectToTheController
    var actionTitle: String?

    var errorMessage: String = L10n.pairingControllerNotRecognized

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - state: specify the current state of the model
    init(state: PairingState = .todo) {
        self.pairingState = state
    }
}

/// Drone with remote pairing model.
class DroneWithRemotePairingModel: PairingModel {
    // MARK: - Internal Properties
    var pairingState: PairingState
    var image: UIImage = Asset.Pairing.icDronePairing.image
    var imageTintColor: UIColor = UIColor(named: .defaultTextColor)
    var title: String = L10n.pairingTurnOnDrone
    var actionTitle: String?

    var errorMessage: String = L10n.pairingDroneNotDetected

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - state: specify the current state of the model
    init(state: PairingState = .todo) {
        self.pairingState = state
    }
}

/// Wifi pairing model.
class WifiPairingModel: PairingModel {
    // MARK: - Internal Properties
    var pairingState: PairingState

    var image: UIImage = Asset.Pairing.icPairingPhoneMedium.image
    var imageTintColor: UIColor = UIColor(named: .defaultTextColor)
    var title: String = L10n.pairingDroneConnectToWifi
    var actionTitle: String?

    var errorMessage: String = L10n.pairingDroneWhereIsWifiPassword

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - state: specify the current state of the model
    init(state: PairingState = .todo) {
        self.pairingState = state
    }
}

/// Drone pairing model without remote.
class DroneWithoutRemotePairingModel: PairingModel {
    // MARK: - Internal Properties
    var pairingState: PairingState

    var image: UIImage = Asset.Pairing.icDronePairing.image
    var imageTintColor: UIColor = UIColor(named: .defaultTextColor)
    var title: String = L10n.pairingTurnOnDrone
    var actionTitle: String? = L10n.pairingWithController

    var errorMessage: String = L10n.commonDone

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - state: specify the current state of the model
    init(state: PairingState = .todo) {
        self.pairingState = state
    }
}
