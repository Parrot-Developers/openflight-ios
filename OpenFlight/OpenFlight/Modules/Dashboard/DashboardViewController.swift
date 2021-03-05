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

/// View Controller used to display content of the Dashboard.
final class DashboardViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var collectionView: UICollectionView!

    // MARK: - Private Properties
    private weak var coordinator: DashboardCoordinator?
    private var dashboardHeaderItems: [DashboardHeaderModel] {
        return DashboardItemCellType.headerItems
            .compactMap { return $0.model }
    }

    private var viewModelsLandscape: [AnyObject]!
    private var viewModelsPortrait: [AnyObject]!
    private var dashboardViewModels: [AnyObject] {
        if UIApplication.isLandscape {
            return viewModelsLandscape
        } else {
            return viewModelsPortrait
        }
    }

    // MARK: - Private Enums
    private enum SizeConstants {
        static let titleNavBarHeight: CGFloat = 40.0
        static let defaultWidth: CGFloat = 150.0
        static let commonCellHeight: CGFloat = 140.0
        static let portraitCellHeight: CGFloat = 100.0
        static let headerPortraitHeight: CGFloat = 50.0
        static let headerLandscapeHeight: CGFloat = 34.0
        static let footerHeight: CGFloat = 37.0
        static let headerWidth: CGFloat = 50.0
        static let headerWidthDelta: CGFloat = 62.0
    }
    private enum MarginConstants {
        static let defaultLanscapeMargin: CGFloat = 15.0
        static let defaultPortraitMargin: CGFloat = 10.0
        static let topPortraitMargin: CGFloat = 22.0
        static let topLandscapeMargin: CGFloat = 14.0
        static let commonCellInset: CGFloat = 24.0
        static let globalInset: CGFloat = 12.0
    }
    private enum Constants {
        static let quarterScreen: CGFloat = 4.0
        static let oneThirdScreen: CGFloat = 3.0
        static let halfScreen: CGFloat = 2.0
        static let numberFooterItems: Int = 1
    }
    private enum SectionType: Int, CaseIterable {
        case header
        case content
        case footer
    }

    // MARK: - Init
    static func instantiate(coordinator: DashboardCoordinator) -> DashboardViewController {
        let viewController = StoryboardScene.Dashboard.initialScene.instantiate()
        viewController.coordinator = coordinator

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        initViewModels()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.collectionView.reloadData()
        self.setNeedsStatusBarAppearanceUpdate()
        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.dashboard, logType: .screen)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }

    override var shouldAutorotate: Bool {
        return true
    }

    /// Reload data when orientation changed.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        collectionView.reloadData()
        self.setNeedsStatusBarAppearanceUpdate()
    }

    /// We should show status bar in portrait mode.
    override var prefersStatusBarHidden: Bool {
        return UIApplication.isLandscape
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
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
        let viewModel = dashboardViewModels[indexPath.row]
        let sectionType = SectionType(rawValue: indexPath.section)

        switch sectionType {
        case .header where collectionView.cellForItem(at: indexPath) is DashboardLoginCell:
            logEvent(with: LogEventScreenManager.shared.logEventProvider?.logStringWithKey(logKey: .parrot) ?? "")
            self.coordinator?.startLogin()
        case .header where collectionView.cellForItem(at: indexPath) is DashboardProviderCell:
            logEvent(with: LogEvent.LogKeyDashboardButton.pilot)
            self.coordinator?.startProviderProfile()
        case .content:
            switch viewModel {
            case let myFlightsViewModel as MyFlightsViewModel:
                logEvent(with: LogEvent.LogKeyDashboardButton.myFlights)
                self.coordinator?.startMyFlights(myFlightsViewModel)
            case _ as MarketingViewModel:
                logEvent(with: LogEvent.LogKeyDashboardButton.marketing)
                self.coordinator?.startMarketing()
            case is RemoteInfosViewModel:
                logEvent(with: LogEvent.LogKeyDashboardButton.controllerDetails)
                self.coordinator?.startRemoteInfos()
            case is DroneInfosViewModel<DroneInfosState>:
                logEvent(with: LogEvent.LogKeyDashboardButton.droneDetails)
                self.coordinator?.startDroneInfos()
            case is GalleryMediaViewModel:
                logEvent(with: LogEvent.LogKeyDashboardButton.gallery)
                self.coordinator?.startMedias()
            default:
                break
            }
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
        guard let sectionType = SectionType(rawValue: indexPath.section) else { return UICollectionViewCell() }

        switch sectionType {
        case .header:
            let headerItem = dashboardHeaderItems[indexPath.row]
            switch headerItem.type {
            case .header:
                cell = createHeaderCell(indexPath: indexPath)
            case .provider:
                cell = createProviderCell(indexPath: indexPath)
            case .loginProvider:
                cell = createLoginProviderCell(indexPath: indexPath)
            default:
                assertionFailure("\(headerItem.self) not yet implemented")
            }
        case .content:
            cell = createContentCell(indexPath)
        case .footer:
            cell = createFooterCell(indexPath: indexPath)
        }

        return cell
    }

    /// Func used to define the number of sections in the collection view.
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return SectionType.allCases.count
    }

    /// Func used to define the number of items in each section of the collection view.
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var nbOfItems: Int = 0
        guard let sectionType = SectionType(rawValue: section) else { return 0 }

        switch sectionType {
        case .header:
            nbOfItems = self.dashboardHeaderItems.count
        case .content:
            nbOfItems = self.dashboardViewModels.count
        case .footer:
            nbOfItems = Constants.numberFooterItems
        }

        return nbOfItems
    }

    // MARK: - Helpers
    /// Create the content of cells for the section 1.
    private func createContentCell(_ indexPath: IndexPath) -> UICollectionViewCell {
        let viewModel = dashboardViewModels[indexPath.row]
        switch viewModel {
        case let userDeviceViewModel as UserDeviceViewModel:
            return createUserDeviceCell(userDeviceViewModel, indexPath)
        case let remoteViewModel as RemoteInfosViewModel:
            return createRemoteCell(remoteViewModel, indexPath)
        case let droneViewModel as DroneInfosViewModel<DroneInfosState>:
            return createDroneCell(droneViewModel, indexPath)
        case let galleryMediaViewModel as GalleryMediaViewModel:
            return createMediasCell(galleryMediaViewModel, indexPath)
        case let myFlightsViewModel as MyFlightsViewModel:
            return createMyFlightsCell(myFlightsViewModel, indexPath)
        case let marketingViewModel as MarketingViewModel:
            return createMarketingCell(marketingViewModel, indexPath)
        default:
            assertionFailure("\(viewModel) not yet implemented")
        }

        return UICollectionViewCell()
    }

    /// Return the corresponding identifier.
    ///
    /// - Parameters:
    ///    - viewModel: View Model of a selected cell
    ///
    /// - Returns: Cell identifier
    func getCellReuseIdentifier(_ viewModel: AnyObject) -> String {
        switch viewModel {
        case is UserDeviceViewModel,
             is RemoteInfosViewModel,
             is DroneInfosViewModel<DroneInfosState>:
            return DashboardDeviceCell.reuseIdentifier
        case is GalleryMediaViewModel:
            return DashboardMediasCell.reuseIdentifier
        case is MarketingViewModel:
            return DashboardMarketingCell.reuseIdentifier
        case is MyFlightsViewModel:
            return DashboardMyFlightsCell.reuseIdentifier
        default:
            return ""
        }
    }
}

// MARK: - Collection View delegate flow layout
extension DashboardViewController: UICollectionViewDelegateFlowLayout {
    /// Func used to define size of each item in the collection view.
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var width: CGFloat = 0.0
        var height: CGFloat = 0.0

        guard let sectionType = SectionType(rawValue: indexPath.section) else { return CGSize.zero }

        let viewModel = dashboardViewModels[indexPath.row]
        if UIApplication.isLandscape {
            switch sectionType {
            case .header:
                height = SizeConstants.headerLandscapeHeight
                // Set content width to whole screen without inset and the margin.
                width = (collectionView.frame.width - MarginConstants.defaultLanscapeMargin - MarginConstants.commonCellInset) / Constants.halfScreen
            case .content:
                height = SizeConstants.commonCellHeight
                switch viewModel {
                case is MarketingViewModel:
                    width = (collectionView.frame.width - MarginConstants.defaultLanscapeMargin - MarginConstants.commonCellInset) / Constants.oneThirdScreen
                case is MyFlightsViewModel:
                    // Set content width to the half of the screen without inset and the margin.
                    width = (collectionView.frame.width - MarginConstants.defaultLanscapeMargin - MarginConstants.commonCellInset)
                        * (Constants.halfScreen / Constants.oneThirdScreen)
                default:
                    // Set content width to the quarter of the screen without inset and the 3 margins.
                    width = (collectionView.frame.width - 3 * MarginConstants.defaultLanscapeMargin - MarginConstants.commonCellInset) / Constants.quarterScreen
                }
            case .footer:
                height = SizeConstants.footerHeight
                width = collectionView.frame.width - MarginConstants.commonCellInset
            }
        } else {
            switch sectionType {
            case .header:
                height = SizeConstants.headerPortraitHeight
                if dashboardHeaderItems[indexPath.row].type == DashboardItemCellType.header {
                    width = SizeConstants.headerWidth
                } else {
                    // Set content width to the whole screen.
                    width = collectionView.frame.width - MarginConstants.commonCellInset - SizeConstants.headerWidthDelta
                }
            case .content:
                height = SizeConstants.commonCellHeight
                switch viewModel {
                case is RemoteInfosViewModel,
                     is DroneInfosViewModel<DroneInfosState>,
                     is UserDeviceViewModel,
                     is GalleryMediaViewModel:
                    // Set content width to the half of the screen without inset and the margin.
                    width = (collectionView.frame.width - MarginConstants.defaultPortraitMargin - MarginConstants.commonCellInset) / Constants.halfScreen
                case is MyFlightsViewModel,
                     is MarketingViewModel:
                    height = SizeConstants.commonCellHeight
                    // Set content width to the whole screen.
                    width = collectionView.frame.width - MarginConstants.commonCellInset
                default:
                    height = SizeConstants.portraitCellHeight
                    // Set content width to the whole screen.
                    width = collectionView.frame.width - MarginConstants.commonCellInset
                }
            case .footer:
                height = SizeConstants.footerHeight
                // Set content width to the whole screen.
                width = collectionView.frame.width - MarginConstants.commonCellInset
            }
        }

        return CGSize(width: width, height: height)
    }

    /// Func used to define top, left, bottom and right insets between sections.
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        var bottomMargin: CGFloat = 0.0
        var topMargin: CGFloat = 0.0
        if UIApplication.isLandscape {
            bottomMargin = MarginConstants.defaultLanscapeMargin
            if section == SectionType.header.rawValue {
                topMargin = MarginConstants.topLandscapeMargin
            }
        } else {
            bottomMargin = MarginConstants.defaultPortraitMargin
            if section == SectionType.header.rawValue {
                topMargin = MarginConstants.topPortraitMargin
            }
        }

        return UIEdgeInsets(top: topMargin,
                            left: MarginConstants.globalInset,
                            bottom: bottomMargin,
                            right: MarginConstants.globalInset)
    }

    /// Func used to define spacing between different lines for each section.
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return UIApplication.isLandscape ? MarginConstants.defaultLanscapeMargin : MarginConstants.defaultPortraitMargin
    }

    /// Func used to define spacing between different items for each section.
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return UIApplication.isLandscape ? MarginConstants.defaultLanscapeMargin : MarginConstants.defaultPortraitMargin
    }
}

// MARK: - Private Funcs
private extension DashboardViewController {
    /// Instantiate the Header Cell.
    ///
    /// - Parameters:
    ///    - indexPath: index of the cell
    ///
    /// - Returns: DashboardHeaderCell
    func createHeaderCell(indexPath: IndexPath) -> DashboardHeaderCell {
        let dashboardHeaderCell = collectionView.dequeueReusableCell(for: indexPath) as DashboardHeaderCell
        dashboardHeaderCell.delegate = self

        return dashboardHeaderCell
    }

    /// Instantiate Login part to Provider in the Header Cell.
    ///
    /// - Parameters:
    ///    - indexPath: index of the cell
    ///
    /// - Returns: DashboardLoginCell
    func createLoginProviderCell(indexPath: IndexPath) -> DashboardLoginCell {
        let dashboardLoginCell = self.collectionView.dequeueReusableCell(for: indexPath) as DashboardLoginCell
        if let currentAccount = AccountManager.shared.currentAccount {
            dashboardLoginCell.setLogo(currentAccount.icon)
        }

        return dashboardLoginCell
    }

    /// Instantiate Provider part of the Header Cell.
    ///
    /// - Parameters:
    ///    - indexPath: index of the cell
    ///
    /// - Returns: DashboardProviderCell
    func createProviderCell(indexPath: IndexPath) -> DashboardProviderCell {
        let dashboardProviderCell = collectionView.dequeueReusableCell(for: indexPath) as DashboardProviderCell
        if let currentAccount = AccountManager.shared.currentAccount,
           let userName = currentAccount.userName {
            dashboardProviderCell.setProfile(icon: currentAccount.userAvatar, name: userName)
        }

        return dashboardProviderCell
    }

    /// Instantiate the User Device Cell.
    ///
    /// - Parameters:
    ///    - viewModel: ViewModel for the cell
    ///
    /// - Returns: DashboardDeviceCell
    func createUserDeviceCell(_ viewModel: UserDeviceViewModel, _ indexPath: IndexPath) -> DashboardDeviceCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: getCellReuseIdentifier(viewModel), for: indexPath)
        guard let userDeviceCell = cell as? DashboardDeviceCell else { return DashboardDeviceCell() }

        userDeviceCell.setup(state: viewModel.state.value)

        return userDeviceCell
    }

    /// Instantiate the Remote Cell.
    ///
    /// - Parameters:
    ///    - viewModel: ViewModel for the cell
    ///
    /// - Returns: DashboardDeviceCell
    func createRemoteCell(_ viewModel: RemoteInfosViewModel, _ indexPath: IndexPath) -> DashboardDeviceCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: getCellReuseIdentifier(viewModel), for: indexPath)
        guard let remoteCell = cell as? DashboardDeviceCell else { return DashboardDeviceCell() }

        remoteCell.setup(state: viewModel.state.value)
        remoteCell.setup(delegate: self)

        return remoteCell
    }

    /// Instantiate the Drone Cell.
    ///
    /// - Parameters:
    ///    - viewModel: ViewModel for the cell
    ///
    /// - Returns: DashboardDeviceCell
    func createDroneCell(_ viewModel: DroneInfosViewModel<DroneInfosState>, _ indexPath: IndexPath) -> DashboardDeviceCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: getCellReuseIdentifier(viewModel), for: indexPath)
        guard let droneCell = cell as? DashboardDeviceCell else { return DashboardDeviceCell() }

        droneCell.setup(state: viewModel.state.value)
        droneCell.setup(delegate: self)
        return droneCell
    }

    /// Instantiate the Medias Cell.
    ///
    /// - Parameters:
    ///    - viewModel: ViewModel for the cell
    ///
    /// - Returns: DashboardMediasCell
    func createMediasCell(_ viewModel: GalleryMediaViewModel, _ indexPath: IndexPath) -> DashboardMediasCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: getCellReuseIdentifier(viewModel), for: indexPath)
        guard let mediaCell = cell as? DashboardMediasCell else { return DashboardMediasCell() }

        mediaCell.viewModel = viewModel
        mediaCell.setup(state: viewModel.state.value)

        return mediaCell
    }

    /// Instantiate the My Flights Cell.
    ///
    /// - Parameters:
    ///    - viewModel: ViewModel for the cell
    ///
    /// - Returns: DashboardInfosCell
    func createMyFlightsCell(_ viewModel: MyFlightsViewModel, _ indexPath: IndexPath) -> DashboardMyFlightsCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: getCellReuseIdentifier(viewModel), for: indexPath)
        guard let myFlightCell = cell as? DashboardMyFlightsCell else { return DashboardMyFlightsCell() }

        myFlightCell.setup(state: viewModel.state.value)

        return myFlightCell
    }

    /// Instantiate the Marketing Cell.
    ///
    /// - Parameters:
    ///    - viewModel: ViewModel for the cell
    ///    - indexPath: index of the cell
    ///
    /// - Returns: DashboardMarketingCell
    func createMarketingCell(_ viewModel: MarketingViewModel, _ indexPath: IndexPath) -> DashboardMarketingCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: getCellReuseIdentifier(viewModel), for: indexPath)
        guard let marketingCell = cell as? DashboardMarketingCell else { return DashboardMarketingCell() }

        return marketingCell
    }

    /// Instantiate the Footer Cell.
    ///
    /// - Parameters:
    ///    - indexPath: index of the cell
    ///
    /// - Returns: DashboardFooterCell
    func createFooterCell(indexPath: IndexPath) -> DashboardFooterCell {
        let dashboardFooterCell = collectionView.dequeueReusableCell(for: indexPath) as DashboardFooterCell
        dashboardFooterCell.coordinator = coordinator

        return dashboardFooterCell
    }

    /// Come back to the HUD.
    @objc func dimissDashboard() {
        LogEvent.logAppEvent(itemName: LogEvent.LogKeyCommonButton.back, logType: .button)
        coordinator?.dismissDashboard()
    }

    /// Inits the view.
    func initView() {
        // Register cells which will be displayed in the collection view.
        collectionView.register(cellType: DashboardHeaderCell.self)
        collectionView.register(cellType: DashboardLoginCell.self)
        collectionView.register(cellType: DashboardProviderCell.self)
        collectionView.register(cellType: DashboardDeviceCell.self)
        collectionView.register(cellType: DashboardMyFlightsCell.self)
        collectionView.register(cellType: DashboardMarketingCell.self)
        collectionView.register(cellType: DashboardFooterCell.self)
        collectionView.register(cellType: DashboardMediasCell.self)
        // Clear the background of the collection view.
        collectionView.backgroundColor = UIColor.clear
    }

    /// Inits View Models.
    func initViewModels() {
        let myFlightsViewModel = MyFlightsViewModel()
        myFlightsViewModel.state.valueChanged = { [weak self] _ in
            self?.collectionView.reloadData()
        }

        let galleryMediaViewModel = GalleryMediaViewModel(stateDidUpdate: { [weak self] _ in
            self?.collectionView.reloadData()
        })
        galleryMediaViewModel.refreshMedias()

        // Fill the view model tab with all dashboard view model.
        viewModelsLandscape = [UserDeviceViewModel(userLocationManager: UserLocationManager()),
                               RemoteInfosViewModel(),
                               DroneInfosViewModel(),
                               galleryMediaViewModel,
                               MarketingViewModel(),
                               myFlightsViewModel]
        viewModelsPortrait = [UserDeviceViewModel(userLocationManager: UserLocationManager()),
                              RemoteInfosViewModel(),
                              DroneInfosViewModel(),
                              galleryMediaViewModel,
                              MarketingViewModel(),
                              myFlightsViewModel]
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
        switch model {
        case .drone:
            // FIXME: StartUpdate is not functional for drone.
            logEvent(with: LogEvent.LogKeyDashboardButton.droneUpdate)
            self.coordinator?.startDroneInfos()
        case .remote:
            logEvent(with: LogEvent.LogKeyDashboardButton.remoteUpdate)
            coordinator?.startUpdate(model: model)
        }
    }
}

// MARK: - DashboardHeaderCellDelegate
extension DashboardViewController: DashboardHeaderCellDelegate {
    func dismissDasboard() {
        LogEvent.logAppEvent(itemName: LogEvent.LogKeyCommonButton.back, logType: .button)
        coordinator?.dismissDashboard()
    }
}
