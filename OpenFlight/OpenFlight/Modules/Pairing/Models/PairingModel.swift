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

// MARK: - Protocol
/// Parent model for controller pairing.
protocol PairingModel {
    // MARK: - Internal Properties
    // State.
    var pairingState: PairingState { get }
    // Background color of the cell corresponding of the pairing state.
    var backgroundColor: UIColor { get }
    // Cell Image.
    var image: UIImage { get }
}

// MARK: - Internal Enums
/// Enum which specify connection state of the controller.
enum PairingState {
    case todo
    case doing
    case done
}

/// Enum which specify each model.
enum PairingCellModel {
    case remote
    case drone
    case fly
}

/// Remote pairing model.
class RemotePairingModel: PairingModel {
    // MARK: - Internal Properties
    var pairingState: PairingState

    var backgroundColor: UIColor {
        switch pairingState {
        case .todo:
            return UIColor(named: .white20)
        case .doing:
            return UIColor(named: .greenSpring20)
        case .done:
            return UIColor(named: .greenPea50)
        }
    }

    var image: UIImage = Asset.Pairing.icRemotePhoneMediumPairing.image
    var title: String = L10n.pairingConnectToTheController
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

    var backgroundColor: UIColor {
        switch pairingState {
        case .todo:
            return UIColor(named: .white20)
        case .doing:
            return UIColor(named: .greenSpring20)
        case .done:
            return UIColor(named: .greenPea50)
        }
    }

    var image: UIImage = Asset.Pairing.icDronePairing.image
    var title: String = L10n.pairingTurnOnDrone
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

/// Fly pairing model.
class FlyPairingModel: PairingModel {
    // MARK: - Internal Properties
    var pairingState: PairingState

    var backgroundColor: UIColor {
        switch pairingState {
        case .todo:
            return UIColor(named: .white20)
        case .doing:
            return UIColor(named: .greenSpring20)
        case .done:
            return UIColor(named: .greenPea50)
        }
    }

    var image: UIImage {
        switch pairingState {
        case .doing:
            return Asset.Pairing.icFly.image
        default:
            return Asset.Pairing.icNoFly.image
        }
    }

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - state: specify the current state of the model
    init(state: PairingState = .todo) {
        self.pairingState = state
    }
}

/// Fly pairing model.
class WifiPairingModel: PairingModel {
    // MARK: - Internal Properties
    var pairingState: PairingState

    var backgroundColor: UIColor {
        switch pairingState {
        case .todo:
            return UIColor(named: .white20)
        case .doing:
            return UIColor(named: .greenSpring20)
        case .done:
            return UIColor(named: .greenPea50)
        }
    }

    var image: UIImage = Asset.Pairing.icConnectWifi.image
    var title: String = L10n.pairingDroneConnectToWifi
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

    var backgroundColor: UIColor {
        switch pairingState {
        case .todo:
            return UIColor(named: .white20)
        case .doing:
            return UIColor(named: .greenSpring20)
        case .done:
            return UIColor(named: .greenPea50)
        }
    }

    var image: UIImage = Asset.Pairing.icDronePairing.image
    var title: String = L10n.pairingTurnOnDrone
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
