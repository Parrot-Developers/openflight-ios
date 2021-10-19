// Copyright (C) 2020 Parrot Drones SAS
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
import Combine

/// View Controller used to display content of the Dashboard.
final class DashboardViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var collectionView: UICollectionView!

    // MARK: - Private Properties
    private weak var coordinator: DashboardCoordinator?
    private var viewModel: DashboardViewModel!
    private var cancellables = [AnyCancellable]()

    // MARK: - Init
    static func instantiate(coordinator: DashboardCoordinator, viewModel: DashboardViewModel) -> DashboardViewController {
        let viewController = StoryboardScene.Dashboard.initialScene.instantiate()
        viewController.coordinator = coordinator
        viewModel.initViewModels()
        viewController.viewModel = viewModel
        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.collectionView.reloadData()
        self.setNeedsStatusBarAppearanceUpdate()
        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.dashboard, logType: .screen)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var shouldAutorotate: Bool {
        return true
    }

    /// Reload data when orientation changed.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // Better use invalidateLayout to trigger layout update
        self.collectionView.collectionViewLayout.invalidateLayout()
        self.setNeedsStatusBarAppearanceUpdate()
    }

    /// We should show status bar in portrait mode.
    override var prefersStatusBarHidden: Bool {
        return UIApplication.isLandscape
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
}

// MARK: - Actions
private extension DashboardViewController {
    /// Come back to HUD when user tap on back button.
    @IBAction func flyButtonTouchedUpInside(_ sender: Any) {
        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.hud, logType: .screen)
        dimissDashboard()
    }
}

// MARK: - Collection View delegate
extension DashboardViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        // item from dataSource subscript
        let item = self.viewModel.dataSource[indexPath.section, indexPath.item]

        switch item {
        case .content(.myFlights):
            logEvent(with: LogEvent.LogKeyDashboardButton.myFlights)
            self.coordinator?.startMyFlights()
        case .content(.remoteInfos):
            logEvent(with: LogEvent.LogKeyDashboardButton.controllerDetails)
            self.coordinator?.startRemoteInfos()
        case .content(.droneInfos):
            logEvent(with: LogEvent.LogKeyDashboardButton.droneDetails)
            self.coordinator?.startDroneInfos()
        case .content(.galleryMedia):
            logEvent(with: LogEvent.LogKeyDashboardButton.gallery)
            self.coordinator?.startMedias()
        case .content(.photogrammetryDebug):
            self.coordinator?.startPhotogrammetryDebug()
        case .content(.settings):
            self.coordinator?.startSettings()
        case .content(.projectManager):
            self.coordinator?.startProjectManager()
        default:
            break
        }
    }
}

// MARK: - Collection View data source
extension DashboardViewController: UICollectionViewDataSource {
    /// Func used to fill the collection view.
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell: UICollectionViewCell = UICollectionViewCell()
        // item from dataSource subscript
        guard let item = self.viewModel.dataSource[indexPath.section, indexPath.item] else { return UICollectionViewCell() }

        switch item {
        case .header(.header):
            cell = createHeaderCell(indexPath: indexPath)
        case .header(.logo):
            cell = createDashboardLogoCell(logoImage: viewModel.appLogo, indexPath: indexPath)
        case .content:
            cell = createContentCell(indexPath)
        case .footer:
            cell = createFooterCell(DashboardFooterViewModel(), indexPath)
        }

        return cell
    }

    /// Func used to define the number of sections in the collection view.
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.viewModel.dataSource.sections.count
    }

    /// Func used to define the number of items in each section of the collection view.
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let items = self.viewModel.dataSource[section]
        return items.count
    }

    // MARK: - Helpers
    /// Create the content of cells for the section 1.
    private func createContentCell(_ indexPath: IndexPath) -> UICollectionViewCell {
        let contentType = self.viewModel.dataSource[indexPath.section, indexPath.item]
        switch contentType {
        case .content(.dashboardMyAccount):
            return createDashboardAccountCell(self.viewModel.dashboardMyAccountViewModel, indexPath)
        case .content(.remoteInfos):
            return createRemoteCell(self.viewModel.remoteInfosViewModel, indexPath)
        case .content(.droneInfos):
            return createDroneCell(self.viewModel.droneInfosViewModel, indexPath)
        case .content(.galleryMedia):
            return createMediasCell(self.viewModel.galleryMediaViewModel, indexPath)
        case .content(.myFlights):
            return createMyFlightsCell(indexPath)
        case .content(.photogrammetryDebug):
            return createPhotogrammetryDebugCell(indexPath: indexPath)
        case .content(.settings):
            return createSettingsCell(indexPath: indexPath)
        case .content(.projectManager):
            return createProjectManagerCell(viewModel.dashboardProjectManagerCellModel, indexPath)
        default:
            assertionFailure("\(String(describing: contentType)) not yet implemented")
        }

        return UICollectionViewCell()
    }
}

// MARK: - Collection View delegate flow layout
extension DashboardViewController: UICollectionViewDelegateFlowLayout {
    /// Func used to define size of each item in the collection view.
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        guard let item = self.viewModel?.dataSource[indexPath.section, indexPath.item] else { return .zero}

        return item.getComputedSize(width: collectionView.frame.width, height: collectionView.frame.height, isRegularSizeClass: self.isRegularSizeClass)
    }

    /// Func used to define top, left, bottom and right insets between sections.
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        guard let section = self.viewModel?.dataSource.sections[section] else { return .zero }
        return section.getComputedInsets(width: collectionView.frame.width, height: collectionView.frame.height, isRegularSizeClass: self.isRegularSizeClass)
    }

    /// Func used to define spacing between different lines for each section.
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return self.viewModel.dataSource.sections[section].minimumLineSpacing
    }

    /// Func used to define spacing between different items for each section.
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return self.viewModel.dataSource.sections[section].minimumInteritemSpacing
    }
}

// MARK: - Private Funcs
private extension DashboardViewController {
    /// Instantiate the Header Cell.
    ///
    /// - Parameters:
    ///    - indexPath: index of the cell
    /// - Returns: DashboardHeaderCell
    func createHeaderCell(indexPath: IndexPath) -> DashboardHeaderCell {
        let dashboardHeaderCell = collectionView.dequeueReusableCell(for: indexPath) as DashboardHeaderCell
        dashboardHeaderCell.delegate = self
        return dashboardHeaderCell
    }

    /// Instantiate dashboard logo Cell.
    ///
    /// - Parameters:
    ///    - appLogo:
    ///    - indexPath: index of the cell
    /// - Returns: DashboardLogoCell
    func createDashboardLogoCell(logoImage: UIImage, indexPath: IndexPath) -> DashboardLogoCell {
        let dashboardLogoCell = collectionView.dequeueReusableCell(for: indexPath) as DashboardLogoCell
        dashboardLogoCell.logoImage = logoImage
        return dashboardLogoCell
    }

    /// Instantiate dashboard account cell.
    ///
    /// - Parameters:
    ///    - viewModel: ViewModel for the cell
    ///    - indexPath: index of the cell
    /// - Returns: DashboardProfileCell
    func createDashboardAccountCell(_ viewModel: DashboardMyAccountViewModel, _ indexPath: IndexPath) -> DashboardMyAccountCell {
        let dashboardMyAccountCell = self.collectionView.dequeueReusableCell(for: indexPath) as DashboardMyAccountCell

        let accountView = AccountManager.shared.currentAccount?.dashboardAccountView ?? MyAccountView()
        accountView.dashboardCoordinator = coordinator
        dashboardMyAccountCell.fill(view: accountView)

        return dashboardMyAccountCell
    }

    /// Instantiate the User Device Cell.
    ///
    /// - Parameters:
    ///    - viewModel: ViewModel for the cell
    /// - Returns: DashboardDeviceCell
    func createUserDeviceCell(_ viewModel: UserDeviceViewModel, _ indexPath: IndexPath) -> DashboardDeviceCell {
        let userDeviceCell = collectionView.dequeueReusableCell(for: indexPath) as DashboardDeviceCell
        userDeviceCell.setup(state: viewModel.state.value)

        return userDeviceCell
    }

    /// Instantiate the Remote Cell.
    ///
    /// - Parameters:
    ///    - viewModel: ViewModel for the cell
    /// - Returns: DashboardDeviceCell
    func createRemoteCell(_ viewModel: RemoteInfosViewModel, _ indexPath: IndexPath) -> DashboardDeviceCell {
        let remoteCell = collectionView.dequeueReusableCell(for: indexPath) as DashboardDeviceCell
        remoteCell.setup(state: viewModel.state.value)
        remoteCell.setup(delegate: self)
        return remoteCell
    }

    /// Instantiates the Drone Cell.
    ///
    /// - Parameters:
    ///    - viewModel: ViewModel for the cell
    /// - Returns: DashboardDroneCell
    func createDroneCell(_ viewModel: DroneInfosViewModel, _ indexPath: IndexPath) -> DashboardDroneCell {
        let droneCell = collectionView.dequeueReusableCell(for: indexPath) as DashboardDroneCell
        droneCell.setup(viewModel)
        droneCell.setup(delegate: self)
        return droneCell
    }

    /// Instantiates the Medias Cell.
    ///
    /// - Parameters:
    ///    - viewModel: ViewModel for the cell
    /// - Returns: DashboardMediasCell
    func createMediasCell(_ viewModel: GalleryMediaViewModel, _ indexPath: IndexPath) -> DashboardMediasCell {
        let mediaCell = collectionView.dequeueReusableCell(for: indexPath) as DashboardMediasCell
        mediaCell.viewModel = viewModel
        mediaCell.setup(state: viewModel.state.value)

        return mediaCell
    }

    /// Instantiates the My Flights Cell.
    ///
    /// - Parameters:
    ///    - viewModel: ViewModel for the cell
    /// - Returns: DashboardInfosCell
    func createMyFlightsCell(_ indexPath: IndexPath) -> DashboardMyFlightsCell {
        let myFlightCell = collectionView.dequeueReusableCell(for: indexPath) as DashboardMyFlightsCell
        let viewModel = DashboardMyFlightsCellModel(service: Services.hub.flight.service)
        myFlightCell.setup(viewModel: viewModel)
        return myFlightCell
    }

    /// Instantiates the Project Manager Cell.
    ///
    /// - Parameters:
    ///    - viewModel: ViewModel for the cell
    ///    - indexPath: The indexPath of the cell
    /// - Returns: DashboardProjectManagerCell
    func createProjectManagerCell(_ viewModel: DashboardProjectManagerCellModel, _ indexPath: IndexPath) -> DashboardProjectManagerCell {
        let projectManagerCell = collectionView.dequeueReusableCell(for: indexPath) as DashboardProjectManagerCell
        projectManagerCell.setup(viewModel: viewModel)
        return projectManagerCell
    }

    func createPhotogrammetryDebugCell(indexPath: IndexPath) -> DashboardPhotogrammetryDebugCell {
        let cell = collectionView.dequeueReusableCell(for: indexPath) as
            DashboardPhotogrammetryDebugCell
        cell.delegate = self
        return cell
    }

    func createSettingsCell(indexPath: IndexPath) -> DashboardSettingsCell {
        let cell = collectionView.dequeueReusableCell(for: indexPath) as DashboardSettingsCell
        cell.setup()
        return cell
    }

    /// Instantiates the Footer Cell.
    ///
    /// - Parameters:
    ///    - indexPath: index of the cell
    /// - Returns: DashboardFooterCell
    func createFooterCell(_ viewModel: DashboardFooterViewModel, _ indexPath: IndexPath) -> DashboardFooterCell {
        let dashboardFooterCell = collectionView.dequeueReusableCell(for: indexPath) as DashboardFooterCell

        dashboardFooterCell.delegate = self
        dashboardFooterCell.setup(state: viewModel.state.value)

        return dashboardFooterCell
    }

    /// Comes back to the HUD.
    @objc func dimissDashboard() {
        LogEvent.logAppEvent(itemName: LogEvent.LogKeyCommonButton.back, logType: .button)
        coordinator?.dismissDashboard()
    }

    /// Inits the view.
    func initView() {
        // Register cells which will be displayed in the collection view.
        collectionView.register(cellType: DashboardHeaderCell.self)
        collectionView.register(cellType: DashboardLogoCell.self)
        collectionView.register(cellType: DashboardMyAccountCell.self)
        collectionView.register(cellType: DashboardDeviceCell.self)
        collectionView.register(cellType: DashboardDroneCell.self)
        collectionView.register(cellType: DashboardMyFlightsCell.self)
        collectionView.register(cellType: DashboardFooterCell.self)
        collectionView.register(cellType: DashboardMediasCell.self)
        collectionView.register(cellType: DashboardPhotogrammetryDebugCell.self)
        collectionView.register(cellType: DashboardSettingsCell.self)
        collectionView.register(cellType: DashboardProjectManagerCell.self)
    }

    /// bind View Model.
    func bindViewModel() {
        self.viewModel?.$viewState
            .sink(receiveValue: { [unowned self] value in
                switch value {
                case .reloadData:
                    self.collectionView.reloadData()
                default:
                    break
                }
            })
            .store(in: &cancellables)
    }

    /// Calls log event.
    ///
    /// - Parameters:
    ///     - itemName: Button name
    func logEvent(with itemName: String) {
        LogEvent.logAppEvent(itemName: itemName,
                             logType: .simpleButton)
    }
}

// MARK: - DashboardDeviceCellDelegate
extension DashboardViewController: DashboardDeviceCellDelegate {
    func startUpdate(_ model: DeviceUpdateModel) {
        logEvent(with: model == .drone
                    ? LogEvent.LogKeyDashboardButton.droneUpdate
                    : LogEvent.LogKeyDashboardButton.remoteUpdate)
        coordinator?.startUpdate(model: model)
    }
}

// MARK: - DashboardHeaderCellDelegate
extension DashboardViewController: DashboardHeaderCellDelegate {
    func dismissDasboard() {
        LogEvent.logAppEvent(itemName: LogEvent.LogKeyCommonButton.back, logType: .button)
        coordinator?.dismissDashboard()
    }
}

// MARK: - DashboardFooterCellDelegate
extension DashboardViewController: DashboardFooterCellDelegate {
    func startConfidentiality() {
        LogEvent.logAppEvent(itemName: LogEvent.LogKeyDashboardDataConfidentialityButton.dataConfidentiality.name,
                             logType: .simpleButton)
        coordinator?.startConfidentiality()
    }

    func startParrotDebugScreen() {
        LogEvent.logAppEvent(itemName: LogEvent.EventLoggerScreenConstants.debugLogs,
                             logType: .simpleButton)
        coordinator?.startParrotDebug()
    }
}

extension DashboardViewController: DashboardPhotogrammetryDebugCellDelegate {
    func startPhotogrammetryDebug() {
        coordinator?.startPhotogrammetryDebug()
    }
}
