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

/// Displays a view with informations about the drone (system, flight time, etc).
final class DroneDetailsInformationsViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var mainView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var droneNameLabel: UILabel!
    @IBOutlet private weak var droneNameView: UIView!
    @IBOutlet private weak var imeiTitleLabel: UILabel!
    @IBOutlet private weak var imeiValueLabel: UILabel!
    @IBOutlet private weak var resetButton: UIButton!
    @IBOutlet private weak var collectionView: UICollectionView!

    // MARK: - Private Properties
    private weak var coordinator: Coordinator?
    private var viewModel = DroneDetailsInformationsViewModel()
    private var items = [DroneDetailsCollectionViewCellModel]()

    // MARK: - Private Enums
    private enum Constants {
        static let cellsPerRow: Int = 2
        static let standardCellSize: CGSize = CGSize(width: 150.0, height: 50.0)
    }

    // MARK: - Setup
    static func instantiate(coordinator: Coordinator) -> DroneDetailsInformationsViewController {
        let viewController = StoryboardScene.DroneDetails.droneDetailsInformationsViewController.instantiate()
        viewController.coordinator = coordinator

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        setupCollectionView()
        setupViewModel()

        addCloseButton(onTapAction: #selector(closeButtonTouchedUpInside(_:)),
                       targetView: mainView,
                       style: .cross)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        UIView.animate(withDuration: Style.shortAnimationDuration) {
            self.view.backgroundColor = ColorName.greyDark60.color
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        collectionView.reloadData()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension DroneDetailsInformationsViewController {
    @objc func closeButtonTouchedUpInside(_ sender: UIButton) {
        closeView()
    }

    @IBAction func backgroundButtonTouchedUpInside(_ sender: Any) {
        closeView()
    }

    @IBAction func droneNameViewTouchedUpInside(_ sender: Any) {
        // TODO: implement rename drone.
    }

    @IBAction func resetButtonTouchedUpInside(_ sender: Any) {
        let validateAction = AlertAction(title: L10n.commonReset, actionHandler: { [weak self] in
            self?.viewModel.resetDrone()
            LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.droneInformations.name,
                                 itemName: LogEvent.LogKeyDroneDetailsInformationsButton.resetDroneInformations,
                                 newValue: nil,
                                 logType: .button)
        })

        self.showAlert(title: L10n.droneDetailsResetTitle,
                       message: L10n.droneDetailsResetDescription,
                       validateAction: validateAction)
    }
}

// MARK: - Private Funcs
private extension DroneDetailsInformationsViewController {
    /// Sets up the view.
    func setupView() {
        mainView.applyCornerRadius(Style.largeCornerRadius,
                                   maskedCorners: [.layerMinXMinYCorner,
                                                   .layerMaxXMinYCorner])
        titleLabel.makeUp(with: .huge)
        titleLabel.text = L10n.droneDetailsInformations
        droneNameView.cornerRadiusedWith(backgroundColor: .clear,
                                         borderColor: ColorName.white20.color,
                                         radius: Style.largeCornerRadius,
                                         borderWidth: Style.mediumBorderWidth)
        droneNameLabel.makeUp(with: .huge)
        imeiTitleLabel.makeUp(with: .large, and: .white)
        imeiTitleLabel.text = L10n.droneDetailsImei
        imeiValueLabel.makeUp(with: .regular, and: .white50)
        droneNameView.setBorder(borderColor: ColorName.white20.color, borderWidth: Style.mediumBorderWidth)
        resetButton.setTitle(L10n.commonReset, for: .normal)
        resetButton.makeup(with: .large, color: .white)
        resetButton.cornerRadiusedWith(backgroundColor: .clear,
                                       borderColor: ColorName.white.color,
                                       radius: Style.largeCornerRadius,
                                       borderWidth: Style.largeBorderWidth)
    }

    /// Sets up informations collection view.
    func setupCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(cellType: DroneDetailsCollectionViewCell.self)
    }

    /// Sets up view model.
    func setupViewModel() {
        viewModel.state.valueChanged = { [weak self] state in
            self?.updateView(state)
        }
        updateView(viewModel.state.value)
    }

    /// Updates the view with given state.
    ///
    /// - Parameters:
    ///    - state: current state
    func updateView(_ state: DroneDetailsInformationsState) {
        self.items = state.items
        self.droneNameLabel.text = state.name
        self.imeiValueLabel.text = state.imei ?? Style.dash
        self.resetButton.isEnabled = state.isConnected()
        self.resetButton.alphaWithEnabledState(state.isConnected())
    }

    /// Closes the view.
    func closeView() {
        self.view.backgroundColor = .clear
        coordinator?.dismiss()
    }
}

// MARK: - UICollectionViewDataSource
extension DroneDetailsInformationsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(for: indexPath) as DroneDetailsCollectionViewCell
        if indexPath.row < items.count {
            cell.model = items[indexPath.row]
        }
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension DroneDetailsInformationsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else {
            return Constants.standardCellSize
        }
        let width = flowLayout.getDynamicCellWidth(cellsPerRow: Constants.cellsPerRow,
                                                   width: collectionView.bounds.width)
        let height = flowLayout.getDynamicCellHeight(cellsPerRow: Constants.cellsPerRow,
                                                     height: collectionView.bounds.height,
                                                     count: items.count)
        return CGSize(width: width, height: height)
    }
}
