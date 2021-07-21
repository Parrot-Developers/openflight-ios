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
/// Protocol used to manage navigation for each cell.

protocol PairingCellDelegate: AnyObject {
    /// Called when user can fly.
    func canFly()
    /// Called when user can't find the remote.
    func remoteNotRecognized()
    /// Called when user can't find the drone.
    func droneNotDetected()
    /// Called when user want to acces to wifi settings of the iPhone.
    func startWifiSettings()
    /// Called when user can't find the password.
    func whereIsWifiPassword()
    /// Called when user switched on the drone when there is no remote connected.
    func switchOnDroneDone()
}

/// Pairing Cell used in the pairing collection view.

final class PairingCell: UICollectionViewCell, NibReusable, DelayedTaskProvider {
    // MARK: - Outlets
    // Index of the cell.
    @IBOutlet private weak var indexLabel: UILabel!
    // Image of the current cell.
    @IBOutlet private weak var modelImageView: UIImageView!
    // Description view.
    @IBOutlet private weak var stateDescriptionLabel: UILabel!
    @IBOutlet private weak var stateDescriptionView: UIView!
    // Cell view.
    @IBOutlet private weak var cellView: UIView!
    @IBOutlet private weak var bgView: UIView!
    // Loading view.
    @IBOutlet private weak var loadingImageview: UIImageView!
    // Error view.
    @IBOutlet private weak var errorView: UIView!
    @IBOutlet private weak var errorButton: UIButton!
    // Check icon.
    @IBOutlet private weak var checkImageView: UIImageView!

    // MARK: - Internal Properties
    weak var navDelegate: PairingCellDelegate?
    var delayedTaskComponents = DelayedTaskComponents()

    // MARK: - Private Enums
    private enum Constants {
        static let borderWidth: CGFloat = 1.0
        static let remoteNotRecognizedDelay: Double = 10.0
        static let remoteNotRecognizedTaskKey: String = "remoteNotRecognized"
        static let droneWaitingDelay: Double = 2.0
        static let droneWaitingTaskKey: String = "droneWaiting"
        static let droneNotDetectedDelay: Double = 5.0
        static let droneNotDetectedTaskKey: String = "droneNotDetected"
    }

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()
        initView()
    }

    override func prepareForReuse() {
        // Clear animations and views.
        updateDescriptionLabel(isHidden: true, title: nil)
        updateErrorButton(isHidden: true, title: nil)
        checkImageView.isHidden = true
        // Cancel each delayed task.
        cancelDelayedTask(key: Constants.remoteNotRecognizedTaskKey)
        cancelDelayedTask(key: Constants.droneWaitingTaskKey)
        cancelDelayedTask(key: Constants.droneNotDetectedTaskKey)
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        // Restart animation when we come back to the view.
        if newWindow != nil,
            loadingImageview.isHidden == false,
            self.window == nil {
            loadingImageview.startRotate()
        }
    }

    // MARK: - Internal Funcs
    /// Setup function which is responsaible of updating each cell of the pairing view.
    ///
    /// - Parameters:
    ///    - entry: Model which is provided by the controller
    ///    - indexPath: index of the cell
    func setup(_ entry: PairingModel, _ indexPath: IndexPath) {
        // Clear animations and views.
        updateDescriptionLabel(isHidden: true, title: nil)
        updateErrorButton(isHidden: true, title: nil)
        loadingImageview.stopRotate()
        loadingImageview.isHidden = true
        checkImageView.isHidden = true
        let taskIsDoing = entry.pairingState == .doing
        let taskIsDone = entry.pairingState == .done

        // Setup all cells according to a specified Model.
        // It can be a remote, a drone, a fly or a wifi pairing cell.
        if let entry = entry as? RemotePairingModel {
            updateDescriptionLabel(isHidden: !(taskIsDoing), title: entry.title)
            if taskIsDoing {
                removeUserInteraction()
                errorButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(remoteNotRecognized)))
                // Show an error button if the remote is not connected after 10s.
                setupDelayedTask({self.updateErrorButton(isHidden: !(taskIsDoing), title: entry.errorMessage)},
                                 delay: Constants.remoteNotRecognizedDelay,
                                 key: Constants.remoteNotRecognizedTaskKey)
            }
        } else if let entry = entry as? DroneWithRemotePairingModel {
            if taskIsDoing {
                removeUserInteraction()
                // Show an indication if the drone is not connected after 2s.
                setupDelayedTask({
                    self.updateDescriptionLabel(isHidden: !(taskIsDoing), title: entry.title)
                    self.loadingImageview.isHidden = !(taskIsDoing)
                    self.loadingImageview.startRotate()},
                                 delay: Constants.droneWaitingDelay,
                                 key: Constants.droneWaitingTaskKey)

                // Show an error button if the drone is not connected after 15s.
                setupDelayedTask({
                    self.updateErrorButton(isHidden: !(taskIsDoing), title: entry.errorMessage)
                    self.errorButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.droneNotDetected)))},
                                 delay: Constants.droneNotDetectedDelay,
                                 key: Constants.droneNotDetectedTaskKey)
            }
        } else if let entry = entry as? WifiPairingModel {
            // Show wifi button view.
            updateDescriptionLabel(isHidden: !taskIsDoing, title: entry.title)
            updateErrorButton(isHidden: !taskIsDoing, title: entry.errorMessage)
            if taskIsDoing {
                removeUserInteraction()
                errorButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.whereIsWifiPassword)))
            }
        } else if let entry = entry as? DroneWithoutRemotePairingModel {
            removeUserInteraction()
            updateDescriptionLabel(isHidden: !taskIsDoing, title: entry.title)
            updateErrorButton(isHidden: !taskIsDoing, title: entry.errorMessage)
            if taskIsDone {
                checkImageView.isHidden = false
            }
            if taskIsDoing {
                removeUserInteraction()
                errorButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.switchOnDroneDone)))
                // User can come back to the HUD when he can fly.
            }
        } else if entry is FlyPairingModel {
            if taskIsDoing {
                cellView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.dismissPairingView)))
                // User can come back to the HUD when he can fly.
            }
        }
        updateIndexView(indexPath, entry.pairingState)
        bgView.backgroundColor = entry.backgroundColor
        modelImageView.image = entry.image
    }
}

// MARK: - Private Funcs
private extension PairingCell {
    /// Init view of the cell.
    func initView() {
        errorButton.setTitleColor(UIColor(named: .white), for: .normal)
        // Set the radius and the border for error and wifi settings buttons.
        errorButton.cornerRadiusedWith(backgroundColor: UIColor.clear,
                                       borderColor: UIColor(named: .white),
                                       radius: Style.largeCornerRadius,
                                       borderWidth: Constants.borderWidth)
        errorButton.titleLabel?.textAlignment = .center
    }

    /// Update the index and the view.
    ///
    /// - Parameters:
    ///    - indexPath: index of the current cell
    ///    - state: state of the current cell
    func updateIndexView(_ indexPath: IndexPath, _ state: PairingState) {
        indexLabel.text = "\(indexPath.row + 1)"
        let bgColor: UIColor = state == PairingState.doing ? UIColor.white : UIColor.clear
        let textColor: UIColor = state == PairingState.doing ? UIColor.black : UIColor.white
        indexLabel.textColor = textColor
        indexLabel.clipsToBounds = true
        indexLabel.cornerRadiusedWith(backgroundColor: bgColor,
                                      borderColor: UIColor.white,
                                      radius: indexLabel.frame.width / 2,
                                      borderWidth: Constants.borderWidth)
    }

    /// Update the label which describe the state for each pairing step.
    ///
    /// - Parameters:
    ///    - isHidden: specify if we need to hide the current view
    ///    - title: title for the label
    func updateDescriptionLabel(isHidden: Bool, title: String?) {
        stateDescriptionView.isHidden = isHidden
        stateDescriptionLabel.text = title
    }

    /// Update the error button which gives info to user.
    ///
    /// - Parameters:
    ///    - isHidden: specify if we need to hide the current view
    ///    - title: title for the button
    func updateErrorButton(isHidden: Bool, title: String?) {
        errorView.isHidden = isHidden
        errorButton.setTitle(title, for: .normal)
    }

    /// Remove all user interaction on error button.
    func removeUserInteraction() {
        errorButton.removeGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.whereIsWifiPassword)))
        errorButton.removeGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.droneNotDetected)))
        errorButton.removeGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.remoteNotRecognized)))
        errorButton.removeGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.switchOnDroneDone)))
    }
}

// MARK: - Actions
private extension PairingCell {
    @IBAction func wifiButtonTouchedUpInside(_ sender: Any) {
        navDelegate?.startWifiSettings()
    }

    @objc func dismissPairingView(tap: UITapGestureRecognizer) {
        navDelegate?.canFly()
    }

    @objc func remoteNotRecognized(tap: UITapGestureRecognizer) {
        navDelegate?.remoteNotRecognized()
    }

    @objc func droneNotDetected(tap: UITapGestureRecognizer) {
        navDelegate?.droneNotDetected()
    }

    @objc func whereIsWifiPassword(tap: UITapGestureRecognizer) {
        navDelegate?.whereIsWifiPassword()
    }

    @objc func switchOnDroneDone(tap: UITapGestureRecognizer) {
        navDelegate?.switchOnDroneDone()
    }
}
