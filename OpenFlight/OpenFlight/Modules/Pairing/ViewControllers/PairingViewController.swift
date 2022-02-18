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

/// View Controller used to manage Pairing.
final class PairingViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var topBarHeightConstraint: NSLayoutConstraint!

    // MARK: - Private Properties
    private weak var coordinator: PairingCoordinator?
    private var pairingList: [PairingModel] = []
    private var viewModel: PairingViewModel = PairingViewModel()
    private var heightRatio: CGFloat = 1.0
    private var isFirstDisplay: Bool = true

    // MARK: - Private Enums
    private enum Constants {
        static let defaultLanscapeMargin: CGFloat = 40.0
        static let defaultPortraitMargin: CGFloat = 20.0
        static let activeCellExtraHeight: CGFloat = 80.0
        static let secondScreen: CGFloat = 2.0
    }

    // MARK: - Setup
    static func instantiate(coordinator: PairingCoordinator) -> PairingViewController {
        let viewController = StoryboardScene.Pairing.initialScene.instantiate()
        viewController.coordinator = coordinator

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = L10n.pairingHowToConnectDroneTitle
        topBarHeightConstraint.constant = Layout.fileNavigationBarHeight(isRegularSizeClass)

        collectionView.register(cellType: PairingCell.self)
        collectionView.backgroundColor = UIColor.clear

        // Setup viewmodel.
        viewModel.state.valueChanged = { [weak self] _ in
            self?.updateView()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if isFirstDisplay {
            // Reload data the first that we enter in the pairing menu.
            updateView()
            isFirstDisplay = false
        }

        LogEvent.log(.screen(LogEvent.Screen.pairing))
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension PairingViewController {
    @IBAction func dismissPairingTouchedUpInside(_ sender: Any) {
        // Hide each element when we dismiss the view controller.
        collectionView.isHidden = true
        titleLabel.isHidden = true
        coordinator?.dismissPairing()
    }
}

// MARK: - Private Funcs
private extension PairingViewController {
    /// Updates view.
    ///
    /// - Parameters:
    ///     - state: connection state
    func updateView(_ state: DeviceConnectionState = DeviceConnectionState()) {
        let list = viewModel.pairingList

        pairingList = list
        collectionView?.reloadData()
    }

    /// Toggles the controller style.
    func toggleControllerStyle() {
        if viewModel.currentControllerStyle == Controller.remoteControl {
            viewModel.setControllerStyle(controllerStyle: Controller.userDevice)
        } else {
            viewModel.setControllerStyle(controllerStyle: Controller.remoteControl)
        }
    }
}

// MARK: - Collection View data source
extension PairingViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pairingList.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let pairingEntry = pairingList[indexPath.row]
        let cell = collectionView.dequeueReusableCell(for: indexPath) as PairingCell
        cell.setup(pairingEntry, indexPath)
        cell.navDelegate = self
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var width: CGFloat = 0.0
        var height: CGFloat = 0.0

        if UIApplication.isLandscape {
            height = collectionView.frame.height
            // Set content width to the second of the screen with 1 margin.
            width = (collectionView.frame.width - Constants.defaultLanscapeMargin)  / Constants.secondScreen
        } else {
            width = collectionView.frame.width
            switch pairingList[indexPath.row].pairingState {
            case .doing:
                height = width + Constants.activeCellExtraHeight
            default:
                height = width
            }
        }
        return CGSize(width: width, height: height)
    }
}

// MARK: - Collection View delegate flow layout
extension PairingViewController: UICollectionViewDelegateFlowLayout {
    /// Func used to define spacing between different lines for each section.
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return UIApplication.isLandscape ? Constants.defaultLanscapeMargin : Constants.defaultPortraitMargin * heightRatio
    }
}

/// Delegate implementation of PairingViewController.
// MARK: - PairingCellDelegate
extension PairingViewController: PairingCellDelegate {
    func canFly() {
        coordinator?.dismissPairing()
    }

    func remoteNotRecognized() {
        coordinator?.startControllerNotRecognizedInfo()
    }

    func droneNotDetected() {
        coordinator?.startControllerDroneNotDetected()
    }

    func whereIsWifiPassword() {
        coordinator?.startControllerWhereIsWifi()
    }

    func startWifiSettings() {
        // Open wifi parameters.
        if let url = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }

    func switchOnDroneDone() {
        viewModel.isDroneSwitchedOn = true
        updateView()
    }

    func onClickAction() {
        toggleControllerStyle()
        viewModel.isDroneSwitchedOn = false
        updateView()
    }
}
