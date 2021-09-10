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
    /// Called when user clicked on the action button.
    func onClickAction()
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
    @IBOutlet private weak var loadingView: UIView!
    @IBOutlet private weak var loadingImageView: UIImageView!
    // Action view.
    @IBOutlet private weak var actionView: UIView!
    @IBOutlet private weak var actionButton: UIButton!
    // Error view.
    @IBOutlet private weak var errorView: UIView!
    @IBOutlet private weak var errorButton: UIButton!
    // Check icon.
    @IBOutlet private weak var checkView: UIView!

    // MARK: - Internal Properties
    weak var navDelegate: PairingCellDelegate?
    var delayedTaskComponents = DelayedTaskComponents()

    // MARK: - Private Enums
    private enum Constants {
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
        updateDescriptionLabel(title: nil)
        updateErrorButton(isHidden: true, title: nil)
        checkView.isHidden = true
        indexLabel.isHidden = false
        // Cancel each delayed task.
        cancelDelayedTask(key: Constants.remoteNotRecognizedTaskKey)
        cancelDelayedTask(key: Constants.droneWaitingTaskKey)
        cancelDelayedTask(key: Constants.droneNotDetectedTaskKey)
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        // Restart animation when we come back to the view.
        if newWindow != nil,
            loadingView.isHidden == false,
            self.window == nil {
            loadingImageView.startRotate()
        }
    }

    // MARK: - Internal Funcs
    /// Setup function which is responsaible of updating each cell of the pairing view.
    ///
    /// - Parameters:
    ///    - entry: Model which is provided by the controller
    ///    - indexPath: index of the cell
    func setup(_ entry: PairingModel, _ indexPath: IndexPath) {
        let taskIsDoing = entry.pairingState == .doing
        let taskIsDone = entry.pairingState == .done

        // Clear animations and views.
        updateDescriptionLabel(title: entry.title)
        updateErrorButton(isHidden: true, title: nil)
        updateActionButton(title: entry.actionTitle)
        loadingImageView.stopRotate()
        loadingView.isHidden = true
        checkView.isHidden = !taskIsDone
        indexLabel.isHidden = taskIsDone

        // Setup all cells according to a specified Model.
        // It can be a remote, a drone, a fly or a wifi pairing cell.
        if let entry = entry as? RemotePairingModel {
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
                    self.loadingView.isHidden = !(taskIsDoing)
                    self.loadingImageView.startRotate()},
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
            updateErrorButton(isHidden: !taskIsDoing, title: entry.errorMessage)
            if taskIsDoing {
                removeUserInteraction()
                errorButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.whereIsWifiPassword)))
            }
        } else if let entry = entry as? DroneWithoutRemotePairingModel {
            removeUserInteraction()
            updateErrorButton(isHidden: !taskIsDoing, title: entry.errorMessage, titleColor: entry.errorTextColor)
            // Set the radius and the border for error and wifi settings buttons.
            errorButton.cornerRadiusedWith(backgroundColor: entry.errorBackgroundColor,
                                           borderColor: entry.errorBorderColor,
                                           radius: Style.largeCornerRadius,
                                           borderWidth: Style.mediumBorderWidth)
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
        bgView.cornerRadiusedWith(backgroundColor: entry.backgroundColor,
                                  borderColor: entry.borderColor,
                                  radius: Style.largeCornerRadius,
                                  borderWidth: Style.largeBorderWidth)
        modelImageView.image = entry.image
        modelImageView.tintColor = entry.imageTintColor
    }
}

// MARK: - Private Funcs
private extension PairingCell {
    /// Init view of the cell.
    func initView() {
        errorButton.setTitleColor(UIColor(named: .defaultTextColor), for: .normal)
        checkView.roundCornered()
        // Set the radius and color of action button.
        actionButton.cornerRadiusedWith(backgroundColor: UIColor(named: .whiteAlbescent),
                                        borderColor: .clear,
                                        radius: Style.largeCornerRadius,
                                        borderWidth: Style.noBorderWidth)
    }

    /// Update the index and the view.
    ///
    /// - Parameters:
    ///    - indexPath: index of the current cell
    ///    - state: state of the current cell
    func updateIndexView(_ indexPath: IndexPath, _ state: PairingState) {
        indexLabel.text = "\(indexPath.row + 1)"
        let bgColor: UIColor = state == PairingState.todo ? .clear : ColorName.highlightColor.color
        let borderColor: UIColor = state == PairingState.todo ? ColorName.defaultTextColor.color : .clear
        let textColor: UIColor = state == PairingState.todo ? ColorName.defaultTextColor.color : Color.white
        indexLabel.textColor = textColor
        indexLabel.clipsToBounds = true
        indexLabel.cornerRadiusedWith(backgroundColor: bgColor,
                                      borderColor: borderColor,
                                      radius: indexLabel.frame.width / 2,
                                      borderWidth: Style.mediumBorderWidth)
    }

    /// Update the label which describe the state for each pairing step.
    ///
    /// - Parameters:
    ///    - title: title for the label
    func updateDescriptionLabel(title: String?) {
        stateDescriptionLabel.text = title
    }

    /// Update the action button which gives info to user.
    ///
    /// - Parameters:
    ///    - title: title for the label. If title is nil, the button will be hidden.
    func updateActionButton(title: String?) {
        actionView.isHidden = title == nil
        actionButton.setTitle(title, for: .normal)
    }

    /// Update the error button which gives info to user.
    ///
    /// - Parameters:
    ///    - isHidden: specify if we need to hide the current view
    ///    - title: title for the button
    func updateErrorButton(isHidden: Bool, title: String?, titleColor: UIColor = ColorName.defaultTextColor.color) {
        errorButton.isHidden = isHidden
        errorButton.setTitle(title, for: .normal)
        errorButton.setTitleColor(titleColor, for: .normal)

        // Set the radius and the border for error button.
        errorButton.cornerRadiusedWith(backgroundColor: .clear,
                                       borderColor: UIColor(named: .defaultTextColor),
                                       radius: Style.largeCornerRadius,
                                       borderWidth: Style.mediumBorderWidth)
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

    @IBAction func actionButtonTouchedUpInside(_ sender: Any) {
        navDelegate?.onClickAction()
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
