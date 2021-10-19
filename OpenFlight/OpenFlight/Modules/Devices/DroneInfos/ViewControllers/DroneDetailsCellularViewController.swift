//
//  Copyright (C) 2021 Parrot Drones SAS.
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

import Combine
import UIKit
import GroundSdk

final class DroneDetailsCellularViewController: UIViewController {

    // MARK: - Outlet

    @IBOutlet private weak var enterPinButton: UIButton!
    @IBOutlet private weak var forgetPinButton: UIButton!
    @IBOutlet private weak var showDebugButton: UIButton!
    @IBOutlet private weak var cellularView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var cellularStatusLabel: UILabel!
    @IBOutlet private weak var operatorNameLabel: UILabel!
    @IBOutlet private weak var controllerErrorLabel: UILabel!

    // Cellular view outlet

    @IBOutlet private weak var controllerImageView: UIImageView!
    @IBOutlet private weak var bottomLeftBranchImage: UIImageView!
    @IBOutlet private weak var leftInternetImage: UIImageView!
    @IBOutlet private weak var topLeftBranchImage: UIImageView!
    @IBOutlet private weak var cellularStatusImage: UIImageView!
    @IBOutlet private weak var topRightBranchImage: UIImageView!
    @IBOutlet private weak var rightInternetImage: UIImageView!
    @IBOutlet private weak var bottomRightBranchImage: UIImageView!
    @IBOutlet private weak var droneStatusImage: UIImageView!

    // MARK: - Private Enums
    private enum Constants {
        static let alphaEnabled: CGFloat = 1
        static let alphaDisabled: CGFloat = 0.6
    }

    // MARK: - Variables

    private var viewModel: DroneDetailCellularViewModel!
    private var cancellables = Set<AnyCancellable>()

    static func instantiate(viewModel: DroneDetailCellularViewModel) -> DroneDetailsCellularViewController {
        let viewController = StoryboardScene.DroneDetailCellularViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        return viewController
    }

    // MARK: - View life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        addTouchGesture()
        bindViewModel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        addColorTransition()
    }

    // MARK: - Action

    @objc func closeCellularViewFromTouch() {
        viewModel.dismissView()
    }

    @IBAction func closeCellularView(_ sender: Any) {
        viewModel.dismissView()
    }

    @IBAction func showCellularDebug(_ sender: Any) {
        viewModel.showDebug()
    }

    @IBAction func enterPin(_ sender: Any) {
        viewModel.showPinCode()
    }

    @IBAction func unpairUser(_ sender: Any) {
        viewModel.forgetPin()
    }
}

// MARK: - Private Extension

private extension DroneDetailsCellularViewController {

    /// Adds a tap gesture recognizer to dismiss the modal
    func addTouchGesture() {
        let touchGesture = UITapGestureRecognizer(target: self, action: #selector(closeCellularViewFromTouch))
        touchGesture.delegate = self
        view.addGestureRecognizer(touchGesture)
    }

    /// Adds a background to the view at the back
    func addColorTransition() {
        UIView.animate(withDuration: Style.shortAnimationDuration, delay: 0, options: .allowUserInteraction) {
            self.view.backgroundColor = ColorName.greyDark60.color
        }
    }

    /// Setsup the basic UI
    func setupUI() {

        // Label's title
        titleLabel.text = L10n.droneDetailsCellularAccess
        enterPinButton.setTitle(L10n.drone4gEnterPin, for: .normal)
        forgetPinButton.setTitle(L10n.cellularForgetPin, for: .normal)
        showDebugButton.setTitle(L10n.drone4gShowDebug, for: .normal)

        // Corner radius
        enterPinButton.layer.cornerRadius = Style.largeCornerRadius
        forgetPinButton.layer.cornerRadius = Style.largeCornerRadius
        showDebugButton.layer.cornerRadius = Style.largeCornerRadius
        cellularView.customCornered(corners: [.topLeft, .topRight], radius: Style.largeCornerRadius)

        // Border
        showDebugButton.layer.borderWidth = Style.mediumBorderWidth
        showDebugButton.layer.borderColor = ColorName.defaultTextColor.color.cgColor
    }

    func bindViewModel() {

        bindDroneSide()
        bindRemoteSide()
        bind4GIcon()

        viewModel.controllerError
            .sink { [unowned self] remoteError in
                controllerErrorLabel.text = remoteError
            }
            .store(in: &cancellables)

        // Enter pin button's state
        viewModel.isEnterPinEnabled
            .sink { [unowned self] isEnabled in
                if isEnabled {
                    enterPinButton.isEnabled = true
                    enterPinButton.alpha = Constants.alphaEnabled
                } else {
                    enterPinButton.isEnabled = false
                    enterPinButton.alpha = Constants.alphaDisabled
                }
            }
            .store(in: &cancellables)

        // Cellular status label's text
        viewModel.cellularStatus
            .combineLatest(viewModel.drone)
            .sink { [unowned self] (cellularStatus, drone) in
                if drone == nil {
                    cellularStatusLabel.text = nil
                    return
                }

                cellularStatusLabel.text = cellularStatus.cellularDetailsTitle
                cellularStatusLabel.textColor = cellularStatus.detailsTextColor.color

                forgetPinButton.isEnabled = cellularStatus == .cellularConnected
                forgetPinButton.alpha = forgetPinButton.isEnabled ?  Constants.alphaEnabled : Constants.alphaDisabled
            }
            .store(in: &cancellables)

        // Operator label's text
        viewModel.operatorName
            .sink { [unowned self] operatorName in
                operatorNameLabel.text = operatorName
            }
            .store(in: &cancellables)
    }
}

extension DroneDetailsCellularViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
         if touch.view?.isDescendant(of: cellularView) == true {
            return false
         }
         return true
    }
}

private extension DroneDetailsCellularViewController {

    /// Binds all remote's elements from the view model
    func bindRemoteSide() {
        viewModel.controllerImage
            .sink { [unowned self] in
                controllerImageView.image = $0
            }
            .store(in: &cancellables)

        viewModel.leftInternetImage
            .sink { [unowned self] in
                leftInternetImage.image = $0
            }
            .store(in: &cancellables)

        viewModel.bottomLeftBranchImage
            .sink { [unowned self] in
                bottomLeftBranchImage.image = $0
            }
            .store(in: &cancellables)

        viewModel.topLeftBranchImage
            .sink { [unowned self] in
                topLeftBranchImage.image = $0
            }
            .store(in: &cancellables)
    }

    /// Binds all drone's element from the view model
    func bindDroneSide() {
        viewModel.droneImage
            .sink { [unowned self] droneImage in
                droneStatusImage.image = droneImage
            }
            .store(in: &cancellables)

        viewModel.rightInternetImage
            .sink { [unowned self] in
                rightInternetImage.image = $0
            }
            .store(in: &cancellables)

        viewModel.bottomRightBranchImage
            .sink { [unowned self] in
                bottomRightBranchImage.image = $0
            }
            .store(in: &cancellables)

        viewModel.topRightBranchImage
            .sink { [unowned self] in
                topRightBranchImage.image = $0
            }
            .store(in: &cancellables)
    }

    func bind4GIcon() {
        viewModel.cellularImage
            .sink { [unowned self] in
                cellularStatusImage.image = $0
            }
            .store(in: &cancellables)
    }
}
