//    Copyright (C) 2021 Parrot Drones SAS
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

public final class DroneDetailsCellularViewController: UIViewController {

    // MARK: - Outlet

    @IBOutlet private weak var enterPinButton: ActionButton!
    @IBOutlet private weak var forgetPinButton: ActionButton!
    @IBOutlet private weak var showSupportButton: ActionButton!
    @IBOutlet private weak var cellularView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var cellularStatusLabel: UILabel!
    @IBOutlet private weak var connectionStatusLabel: UILabel!
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

    // MARK: - Variables

    private var viewModel: DroneDetailCellularViewModel!
    private var cancellables = Set<AnyCancellable>()

    public static func instantiate(viewModel: DroneDetailCellularViewModel) -> DroneDetailsCellularViewController {
        let viewController = StoryboardScene.DroneDetailCellularViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        return viewController
    }

    // MARK: - View life cycle

    public override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        addTouchGesture()
        bindViewModel()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        addColorTransition()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.backgroundColor = .clear
    }

    // MARK: - Action

    @objc func closeCellularViewFromTouch() {
        viewModel.dismissView()
    }

    @IBAction func closeCellularView(_ sender: Any) {
        viewModel.dismissView()
    }

    @IBAction func showCellularSupport(_ sender: Any) {
        viewModel.showSupport()
    }

    @IBAction func enterPin(_ sender: Any) {
        viewModel.showPinCode()
    }

    @IBAction func unpairUser(_ sender: Any) {
        // Not only the current user, but all paired users to the current drone are unpaired.
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
        titleLabel.font = FontStyle.title.font(isRegularSizeClass)

        // Setup buttons
        enterPinButton.setup(title: L10n.drone4gEnterPin, style: .default2)
        forgetPinButton.setup(title: L10n.cellularForgetPin, style: .default2)
        showSupportButton.setup(title: "", style: .secondary1)
        cellularView.customCornered(corners: [.topLeft, .topRight], radius: Style.largeCornerRadius)

        cellularStatusLabel.makeUp(with: .smallText, color: .defaultTextColor)
        controllerErrorLabel.makeUp(with: .smallText, color: .defaultTextColor)
    }

    func bindViewModel() {
        bindDroneSide()
        bindRemoteSide()
        bind4GIcon()

        viewModel.$isSupportButtonHidden
            .removeDuplicates()
            .sink { [unowned self] in
                showSupportButton.isHidden = $0
            }
            .store(in: &cancellables)

        viewModel.$isSupportButtonEnabled
            .removeDuplicates()
            .sink { [unowned self] in
                showSupportButton.isEnabled = $0
            }
            .store(in: &cancellables)

        viewModel.$supportButtonTitle
            .removeDuplicates()
            .sink { [unowned self] in
                showSupportButton.updateTitle($0)
            }
            .store(in: &cancellables)

        viewModel.controllerStatus
            .sink { [unowned self] remoteStatus in
                controllerErrorLabel.text = remoteStatus
            }
            .store(in: &cancellables)

        // Enter pin button's state
        viewModel.isEnterPinEnabled
            .sink { [unowned self] isEnabled in
                enterPinButton.isEnabled = isEnabled
            }
            .store(in: &cancellables)

        viewModel.cellularStatusString
            .removeDuplicates()
            .sink { [unowned self] cellularStatusText in
                cellularStatusLabel.text = cellularStatusText
            }
            .store(in: &cancellables)

        viewModel.isForgetPinEnabled
            .removeDuplicates()
            .combineLatest(viewModel.isFlying.removeDuplicates())
            .sink { [unowned self] (isEnterPinEnabled, isFlying) in
                forgetPinButton.isEnabled = isEnterPinEnabled && !isFlying
            }
            .store(in: &cancellables)

        // Operator label's text
        viewModel.operatorName
            .combineLatest(viewModel.$connectionStatusColor, viewModel.cellularLinkState)
            .sink { [unowned self] (operatorName, connectionStatusColor, cellularLinkState) in

                connectionStatusLabel.text = operatorName ?? cellularLinkState ?? L10n.commonNotConnected
                connectionStatusLabel.textColor = connectionStatusColor.color
            }
            .store(in: &cancellables)

    }
}

extension DroneDetailsCellularViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
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
