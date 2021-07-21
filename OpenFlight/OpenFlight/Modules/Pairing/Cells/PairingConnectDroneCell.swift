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
import Reusable

// MARK: - Protocols
protocol PairingConnectDroneCellDelegate: AnyObject {
    /// Forget the current drone.
    ///
    /// - Parameters:
    ///     - uid: current drone uid
    func forgetDrone(uid: String)
}

/// Custom cell used to show a drone in the discovered drones list.
final class PairingConnectDroneCell: UITableViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var droneView: UIView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var wifiImageView: UIImageView!
    @IBOutlet private weak var errorView: UIView!
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet private weak var cellularAvailableImageView: UIImageView!
    @IBOutlet private weak var forgetButton: UIButton!

    // MARK: - Internal Properties
    weak var delegate: PairingConnectDroneCellDelegate?

    // MARK: - Private Properties
    private var uid: String = ""

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()

        initView()
    }

    // MARK: - Internal Funcs
    /// Sets up the view for the cell.
    /// - Parameters:
    ///    - droneModel: The model of the drone
    ///    - failedToConnect: Connection failed
    ///    - isConnecting: Drone currently connecting
    ///    - unpairStatus: Potential unpair status
    func setup(droneModel: RemoteConnectDroneModel,
               failedToConnect: Bool,
               isConnecting: Bool,
               unpairStatus: UnpairDroneState?) {
        resetView()

        self.uid = droneModel.droneUid

        if unpairStatus?.shouldShowError == true {
            errorView.isHidden = false
            errorLabel.text = unpairStatus?.title
            errorLabel.textColor = UIColor(named: .redTorch)
        } else if failedToConnect {
            errorView.isHidden = false
            errorLabel.text = L10n.pairingRemoteDroneFailedConnectDrone
            errorLabel.textColor = UIColor(named: .redTorch)
        } else if isConnecting {
            errorView.isHidden = false
            errorLabel.text = L10n.connecting
            errorLabel.textColor = UIColor(named: .greenSpring)
        }

        forgetButton.isHidden = !droneModel.isKnown
        cellularAvailableImageView.isHidden = !droneModel.isDronePaired
        nameLabel.text = droneModel.droneName
        wifiImageView.image = droneModel.rssiImage

        if droneModel.isDroneConnected {
            droneView.cornerRadiusedWith(backgroundColor: ColorName.greenSpring20.color,
                                         borderColor: ColorName.greenSpring.color,
                                         radius: Style.largeCornerRadius,
                                         borderWidth: Style.mediumBorderWidth)
        } else {
            droneView.cornerRadiusedWith(backgroundColor: UIColor(named: .white10),
                                         radius: Style.largeCornerRadius)
        }
    }
}

// MARK: - Actions
private extension PairingConnectDroneCell {
    @IBAction func forgetButtonTouchedUpInside(_ sender: Any) {
        delegate?.forgetDrone(uid: uid)
    }
}

// MARK: - Private Funcs
private extension PairingConnectDroneCell {
    /// Inits view.
    func initView() {
        errorView.backgroundColor = .clear
        forgetButton.makeup(color: .redTorch,
                            and: .normal)
        forgetButton.setTitle(L10n.commonForget, for: .normal)
    }

    /// Resets view.
    func resetView() {
        uid = ""
        cellularAvailableImageView.isHidden = true
        errorView.isHidden = true
        nameLabel.text = nil
        forgetButton.isHidden = true
        errorLabel.text = nil
    }
}
