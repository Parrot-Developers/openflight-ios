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

/// Modal presented to enter a pin number for cellular access.
final class CellularAccessCardPinViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var mainView: UIView!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var okButton: UIButton!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var pinTextField: UITextField!
    @IBOutlet private weak var fieldView: UIView!
    @IBOutlet private weak var pinVisibilityButton: UIButton!
    @IBOutlet private weak var loadingImageView: UIImageView!

    // MARK: - Private Properties
    private weak var coordinator: Coordinator?
    private let viewModel = CellularAccessCardPinViewModel()
    private var pinCode: String = ""

    // MARK: - Private Enums
    private enum Constants {
        static let sectionNumber: Int = 1
        static let requiredPinNumber: Int = 4
        static let maxPinNumber: Int = 8
        static let cellsPerRowLandscape: Int = 5
        static let cellsPerRowPortrait: Int = 3
        static let standardCellSize: CGSize = CGSize(width: 68.0, height: 68.0)
    }

    // MARK: - Setup
    static func instantiate(coordinator: Coordinator) -> CellularAccessCardPinViewController {
        let viewController = StoryboardScene.CellularAccessCardPin.initialScene.instantiate()
        viewController.coordinator = coordinator

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        initCollectionView()
        initViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.pairing4gPinDialog, logType: .screen)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        UIView.animate(withDuration: Style.shortAnimationDuration) {
            self.view.backgroundColor = ColorName.greyDark60.color
        }
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        collectionView.reloadData()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension CellularAccessCardPinViewController {
    @IBAction func okButtonTouchedUpInside(_ sender: Any) {
        logEvent(with: LogEvent.LogKeyCellularAccessCardPin.confirmPin, and: pinCode.description)
        viewModel.connect(pinCode: pinCode)
    }

    @IBAction func cancelButtonTouchedUpInside(_ sender: Any) {
        logEvent(with: LogEvent.LogKeyCellularAccessCardPin.cancel)
        guard !pinCode.isEmpty else { return }

        pinCode.removeLast()
        updateTextFieldContent()
        updateOkButton(isEnabled: pinCode.count >= Constants.requiredPinNumber)
    }

    @IBAction func pinVisibilityButtonTouchedUpInside(_ sender: Any) {
        logEvent(with: LogEvent.LogKeyCellularAccessCardPin.pinVisibility)
        pinTextField.toggleVisibility()
        pinVisibilityButton.setImage(pinTextField.isSecureTextEntry
                                        ? Asset.Common.Icons.icPasswordShow.image
                                        : Asset.Common.Icons.icPasswordHide.image, for: .normal)
    }

    @IBAction func closeButtonTouchedUpInside(_ sender: Any) {
        logEvent(with: LogEvent.LogKeyCellularAccessCardPin.close)
        self.view.backgroundColor = .clear
        viewModel.dismissCellularModal()
        coordinator?.dismiss()
    }
}

// MARK: - Private Funcs
private extension CellularAccessCardPinViewController {
    /// Inits collection view.
    func initCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(cellType: PinNumberCollectionViewCell.self)
        collectionView.backgroundColor = .clear
    }

    /// Inits the view.
    func initView() {
        mainView.addBlurEffect()
        pinTextField.isEnabled = false
        okButton.makeup(with: .large, color: .white)
        pinTextField.backgroundColor = .clear
        fieldView.cornerRadiusedWith(backgroundColor: ColorName.white20.color,
                                     borderColor: .white,
                                     radius: Style.largeCornerRadius,
                                     borderWidth: Style.mediumBorderWidth)
        titleLabel.makeUp(with: .huge)
        titleLabel.text = L10n.pinModalSimCardPin
        descriptionLabel.makeUp(with: .large, and: .redTorch)
        updateOkButton(isEnabled: pinCode.count >= Constants.requiredPinNumber)
    }

    /// Inits the view model.
    func initViewModel() {
        viewModel.state.valueChanged = { [weak self] _ in
            self?.updateView()
        }
        updateView()
    }

    /// Updates the view.
    func updateView() {
        let state = viewModel.state.value
        if state.cellularConnectionState == .ready {
            coordinator?.dismiss {
                (self.coordinator as? HUDCoordinator)?.displayPairingSuccess()
            }
        } else {
            descriptionLabel.isHidden = state.canShowLabel == true
            descriptionLabel.text = state.descriptionTitle
            descriptionLabel.textColor = state.cellularConnectionState?.descriptionColor
        }

        updateLoaderView(shouldShow: state.shouldShowLoader == true)
    }

    /// Updates loader image view.
    ///
    /// - Parameters:
    ///     - shouldShow: true if loader need to be shown
    func updateLoaderView(shouldShow: Bool) {
        updateOkButton(isEnabled: !shouldShow)
        loadingImageView.isHidden = !shouldShow
        shouldShow ? loadingImageView.startRotate() : loadingImageView.stopRotate()
    }

    /// Updates content of the pin field.
    func updateTextFieldContent() {
        pinTextField.text = pinCode
    }

    /// Updates Ok button according to pin textfield state.
    ///
    /// - Parameters:
    ///     - isEnabled: tells if ok button need to be enabled
    func updateOkButton(isEnabled: Bool) {
        let pinNumberIsCompleted: Bool = pinCode.count >= Constants.requiredPinNumber
        let backgroundColor = pinNumberIsCompleted ? ColorName.greenSpring20.color : ColorName.white20.color
        let textColor = pinNumberIsCompleted ? ColorName.greenSpring.color : ColorName.white50.color
        okButton.isEnabled = pinNumberIsCompleted
        okButton.cornerRadiusedWith(backgroundColor: backgroundColor,
                                    radius: Style.largeCornerRadius)
        okButton.setTitleColor(textColor, for: .normal)
    }

    /// Calls log event.
    ///
    /// - Parameters:
    ///     - itemName: Button name
    ///     - newValue: Value changed
    func logEvent(with itemName: String, and newValue: String? = nil) {
        LogEvent.logAppEvent(itemName: itemName,
                             newValue: newValue,
                             logType: .button)
    }
}

// MARK: - UICollectionViewDataSource
extension CellularAccessCardPinViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.dataSource.count
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return Constants.sectionNumber
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(for: indexPath) as PinNumberCollectionViewCell
        cell.fill(with: viewModel.dataSource[indexPath.row])
        cell.delegate = self

        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension CellularAccessCardPinViewController: UICollectionViewDelegateFlowLayout {
    /// Func used to define size of each item.
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else {
            return Constants.standardCellSize
        }

        if indexPath.row == viewModel.dataSource.count - 1 && !UIApplication.isLandscape {
            // Center last item of the datasource in portrait mode.
            return CGSize(width: collectionView.frame.width, height: Constants.standardCellSize.height)
        } else {
            let cellsNumber = UIApplication.isLandscape ? Constants.cellsPerRowLandscape : Constants.cellsPerRowPortrait
            let width = flowLayout.getDynamicCellWidth(cellsPerRow: cellsNumber,
                                                       width: collectionView.bounds.width)
            return CGSize(width: width, height: Constants.standardCellSize.height)
        }
    }
}

// MARK: - PinNumberCollectionViewCellDelegate
extension CellularAccessCardPinViewController: PinNumberCollectionViewCellDelegate {
    func updatePinNumber(number: Int?) {
        guard let number = number,
              let pinLength = pinTextField.text?.count,
              pinLength < Constants.maxPinNumber else {
            return
        }

        pinCode += "\(number)"
        updateTextFieldContent()
        updateOkButton(isEnabled: pinCode.count >= Constants.requiredPinNumber)
    }
}
