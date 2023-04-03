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

import Foundation
import Pictor

/// View Model used to display handle behavior of DashBoardViewController
final class DashboardViewModel {

    @Published var viewState: ViewState = .initialize

    var dataSource = DashboardDataSource()
    var appLogo: UIImage = Asset.Logo.icLogoParrotApp.image

    let dashboardMediasViewModel: DashboardMediasViewModel
    var dashboardMyAccountViewModel: DashboardMyAccountViewModel
    var remoteInfosViewModel: RemoteInfosViewModel
    var droneInfosViewModel: DroneInfosViewModel
    var userDeviceViewModel: UserDeviceViewModel
    var dashboardProjectManagerCellModel: DashboardProjectManagerCellModel
    var myFlightsCellModel: DashboardMyFlightsCellModel
    let dashboardUiProvider: DashboardUiProvider

    private let service: VariableAssetsService
    private let projectManager: ProjectManager
    private let synchroService: SynchroService?
    private let projectManagerUiProvider: ProjectManagerUiProvider!
    private let flightService: FlightService
    /// The media services.
    private let mediaServices: MediaServices

    enum ViewState {
        case initialize
        case reloadData
    }

    // MARK: - Init
    /// Constructor.
    ///
    /// - Parameters:
    ///    - service: the variable assets service
    ///    - projectManager: the project manager
    ///    - synchroService: the cloud synchro service
    ///    - dashboardUiProvider: the dashboard UI provider
    ///    - flightService: the flight service
    ///    - mediaServices: the media services
    init(service: VariableAssetsService,
         projectManager: ProjectManager,
         synchroService: SynchroService?,
         projectManagerUiProvider: ProjectManagerUiProvider,
         dashboardUiProvider: DashboardUiProvider,
         flightService: FlightService,
         mediaServices: MediaServices) {
        self.service = service
        self.projectManager = projectManager
        self.synchroService = synchroService
        self.projectManagerUiProvider = projectManagerUiProvider
        self.dashboardUiProvider = dashboardUiProvider
        self.flightService = flightService
        self.mediaServices = mediaServices

        appLogo = service.appLogo

        // Fill the view model tab with all dashboard view model.
        dashboardMediasViewModel = DashboardMediasViewModel(mediaServices: mediaServices)
        dashboardMyAccountViewModel =  DashboardMyAccountViewModel()
        remoteInfosViewModel = RemoteInfosViewModel()
        droneInfosViewModel = DroneInfosViewModel()
        userDeviceViewModel = UserDeviceViewModel(userLocationManager: UserLocationManager())
        myFlightsCellModel = DashboardMyFlightsCellModel(service: flightService,
                                                         synchroService: synchroService)
        dashboardProjectManagerCellModel = DashboardProjectManagerCellModel(manager: projectManager,
                                                                            synchroService: synchroService,
                                                                            projectManagerUiProvider: projectManagerUiProvider)
    }
}
