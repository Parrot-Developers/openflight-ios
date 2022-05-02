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
import CoreLocation
import Combine

protocol FlightExecutionDetailsSettingsCellProvider {
    var settings: [FlightPlanExecutionViewModel.ExecutionSetting] { get }
}

protocol FlightPlanExecutionInfoCellProvider {
    var title: String { get }
    var date: Date { get }
    var location: CLLocationCoordinate2D { get }
    var flights: [FlightModel] { get }
    var executionTitle: String { get }
    var flightPlan: FlightPlanModel { get }
    var flightService: FlightService { get }

    var summaryProvider: FlightDetailsSummaryViewProvider { get }
}

open class FlightPlanExecutionViewModel {

    struct ExecutionSetting {
        let key: String
        let value: String
    }

    let flightPlan: FlightPlanModel
    private weak var coordinator: FlightPlanExecutionDetailsCoordinator?
    private let flightPlanExecutionDetailsSettingsProvider: FlightPlanExecutionDetailsSettingsProvider
    private weak var flightRepository: FlightRepository?
    private weak var flightPlanRepository: FlightPlanRepository?
    private let flightPlanUiStateProvider: FlightPlanUiStateProvider
    private let flightService: FlightService
    private let navigationStack: NavigationStackService

    init(flightPlan: FlightPlanModel,
         flightRepository: FlightRepository,
         flightPlanRepository: FlightPlanRepository,
         coordinator: FlightPlanExecutionDetailsCoordinator,
         flightPlanExecutionDetailsSettingsProvider: FlightPlanExecutionDetailsSettingsProvider,
         flightPlanUiStateProvider: FlightPlanUiStateProvider,
         flightService: FlightService,
         navigationStack: NavigationStackService) {
        self.flightPlan = flightPlanRepository.getFlightPlan(withUuid: flightPlan.uuid) ?? flightPlan
        self.coordinator = coordinator
        self.flightPlanExecutionDetailsSettingsProvider = flightPlanExecutionDetailsSettingsProvider
        self.flightRepository = flightRepository
        self.flightPlanRepository = flightPlanRepository
        self.flightPlanUiStateProvider = flightPlanUiStateProvider
        self.flightService = flightService
        self.navigationStack = navigationStack
    }

    /// Back button tapped.
    func didTapBack() {
        coordinator?.dismissDetails()
    }

    /// Ask confirmation to delete flight.
    func askForDeletion() {
        coordinator?.showDeleteFlightPopupConfirmation(didTapDelete: { [unowned self] in
            Services.hub.flightPlan.manager.delete(flightPlan: flightPlan)
            coordinator?.dismissDetails()
        })
     }

    var executionSettingsProvider: FlightExecutionDetailsSettingsCellProvider {
        let settings = flightPlanExecutionDetailsSettingsProvider
            .settings(forExecution: flightPlan)
            .map { FlightPlanExecutionViewModel.ExecutionSetting(key: $0.key, value: $0.value) }
        return CellProviderImpl(settings: settings)
    }

    var executionInfoProvider: FlightPlanExecutionInfoCellProvider {
        let flightUuids = flightPlan.flightPlanFlights?.map({ $0.flightUuid }) ?? []
        let flights = flightRepository?.getFlights(withUuids: flightUuids) ?? []
        let project = Services.hub.flightPlan.projectManager.project(for: flightPlan)

        let title = project?.title ?? Style.dash
        let location = flights.first?.location.coordinate
            ?? flightPlan.points.first
            ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let date = flightPlan.flightPlanFlights?.first?.dateExecutionFlight ?? Date.distantPast

        let executionTitle = Services.hub.missionsStore.missionFor(flightPlan: flightPlan)?
            .mission
            .flightPlanProvider?
            .executionTitle.localizedUppercase ??
            L10n.dashboardMyFlightsPlanExecution.localizedUppercase

        return FlightPlanExecutionInfoCellProviderImpl(title: title,
                                                       executionTitle: executionTitle,
                                                       flightPlan: flightPlan,
                                                       date: date,
                                                       location: location,
                                                       flights: flights,
                                                       flightService: flightService)
    }

    var actions: [FlightDetailsActionCellModel] {
        [FlightDetailsActionCellModel(buttonTitle: L10n.dashboardMyFlightDeleteExecution,
                                      action: .delete)]
    }

    var statusCellModel: FlightExecutionDetailsStatusCellModel {
        let flightPlan = flightPlanRepository?.getFlightPlan(withUuid: self.flightPlan.uuid) ?? flightPlan
        return FlightExecutionDetailsStatusCellModel(flightPlan: flightPlan,
                                                     flightPlanUiStateProvider: flightPlanUiStateProvider,
                                                     coordinator: coordinator)
    }

    var flightPlanUiStateProviderPublisher: AnyPublisher<FlightPlanStateUiParameters, Never> {
        flightPlanUiStateProvider
            .uiStatePublisher(for: flightPlan)
            .eraseToAnyPublisher()
    }

    /// Flights trajectories points.
    public var flightsPoints: [[TrajectoryPoint]] {
        guard let flightRepository = flightRepository,
              let flightPlanAndFlightLinks = flightPlan.flightPlanFlights
        else { return [] }

        let flightUuids = flightPlanAndFlightLinks.map({ $0.flightUuid })

        return flightRepository.getFlights(withUuids: flightUuids)
            .compactMap { flightService.gutma(flight: $0) }
            .map { gutma in
                gutma.flightPlanPoints(flightPlan)
            }
    }

    /// Whether trajectory points altitudes are in ASML.
    public var hasAsmlAltitude: Bool {
        if let flightPlanFlight = flightPlan.flightPlanFlights?.first,
           let flight = flightRepository?.getFlight(withUuid: flightPlanFlight.flightUuid),
           let gutma = flightService.gutma(flight: flight) {
            return gutma.hasAsmlAltitude
        } else {
            return false
        }
    }
}

private struct FlightPlanExecutionInfoCellProviderImpl: FlightPlanExecutionInfoCellProvider {
    let title: String
    let executionTitle: String
    let flightPlan: FlightPlanModel
    let date: Date
    let location: CLLocationCoordinate2D
    let flights: [FlightModel]
    let flightService: FlightService

    var summaryProvider: FlightDetailsSummaryViewProvider {
        // An execution can span multiple flights. The (duration,power,distance)
        // related to an execution thus constists of the sum of sub-executions
        // in all flights related with the execution.
        let sum = flights.reduce((duration: 0.0,
                                  battery: 0.0,
                                  distance: 0.0,
                                  photoCount: 0,
                                  videoCount: 0)) { sum, flight in
            let gutma = flightService.gutma(flight: flight)
            let duration = gutma?.flightPlanDuration(flightPlan) ?? 0
            let battery = gutma?.flightPlanBatteryConsumption(flightPlan) ?? 0
            let distance = gutma?.flightPlanDistance(flightPlan) ?? 0
            let photoCount = gutma?.flightPlanPhotoCount(flightPlan) ?? 0
            let videoCount = gutma?.flightPlanVideoCount(flightPlan) ?? 0
            return (duration: sum.duration + duration,
                    battery: sum.battery + battery,
                    distance: sum.distance + distance,
                    photoCount: sum.photoCount + photoCount,
                    videoCount: sum.videoCount + videoCount)
        }
        return FlightExecutionSummaryProvider(duration: sum.duration,
                                              batteryConsumption: Int(sum.battery),
                                              distance: sum.distance,
                                              photoCount: Int(sum.photoCount),
                                              videoCount: Int(sum.videoCount))
    }
}

private struct FlightExecutionSummaryProvider: FlightDetailsSummaryViewProvider {
    let duration: Double
    let batteryConsumption: Int
    let distance: Double
    let photoCount: Int
    let videoCount: Int
}

private struct CellProviderImpl: FlightExecutionDetailsSettingsCellProvider {
    let settings: [FlightPlanExecutionViewModel.ExecutionSetting]
}
