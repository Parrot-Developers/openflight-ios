// Copyright (C) 2021 Parrot Drones SAS
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
}

open class FlightPlanExecutionViewModel {

    struct ExecutionSetting {
        let key: String
        let value: String
    }

    let flightPlan: FlightPlanModel
    private let coordinator: DashboardCoordinator?
    private let flightPlanExecutionDetailsSettingsProvider: FlightPlanExecutionDetailsSettingsProvider
    private unowned let flightRepository: FlightRepository
    private let flightPlanUiStateProvider: FlightPlanUiStateProvider

    init(flightPlan: FlightPlanModel,
         flightRepository: FlightRepository,
         coordinator: DashboardCoordinator?,
         flightPlanExecutionDetailsSettingsProvider: FlightPlanExecutionDetailsSettingsProvider,
         flightPlanUiStateProvider: FlightPlanUiStateProvider) {
        self.flightPlan = flightPlan
        self.coordinator = coordinator
        self.flightPlanExecutionDetailsSettingsProvider = flightPlanExecutionDetailsSettingsProvider
        self.flightRepository = flightRepository
        self.flightPlanUiStateProvider = flightPlanUiStateProvider
    }

    /// Back button tapped.
    func didTapBack() {
        coordinator?.back()
    }

    /// Ask confirmation to delete flight.
    func askForDeletion() {
        coordinator?.showDeleteFlightPopupConfirmation(didTapDelete: {
            Services.hub.flightPlan.manager.delete(flightPlan: self.flightPlan)
            self.coordinator?.back()
        })
     }

    var executionSettingsProvider: FlightExecutionDetailsSettingsCellProvider {
        let settings = flightPlanExecutionDetailsSettingsProvider
            .settings(forExecution: flightPlan)
            .map { FlightPlanExecutionViewModel.ExecutionSetting(key: $0.key, value: $0.value) }
        return CellProviderImpl(settings: settings)
    }

    var executionInfoProvider: FlightPlanExecutionInfoCellProvider {
        let flights = flightPlan.flightPlanFlights?
            .map { $0.flightUuid }
            .compactMap(flightRepository.loadFlight)
            ?? []
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
                                                       date: date,
                                                       location: location,
                                                       flights: flights)
    }

    var actions: [FlightDetailsActionCellModel] {
        [FlightDetailsActionCellModel(buttonTitle: L10n.dashboardMyFlightDeleteExecution,
                                      action: .delete)]
    }

    var flightsSectionHeaderModel: FlightDetailsSectionHeaderCellModel {
        FlightDetailsSectionHeaderCellModel(title: L10n.dashboardMyFlightPlanExecutionFlights,
                                            count: executionInfoProvider.flights.count)
    }

    func flightCellModelForFlight(at index: Int) -> FlightExecutionDetailsFlightsCellModel {
        let flight = executionInfoProvider.flights[index]
        return FlightExecutionDetailsFlightsCellModel(coordinator: coordinator,
                                                      flight: flight)
    }

    var statusCellModel: FlightExecutionDetailsStatusCellModel {
       FlightExecutionDetailsStatusCellModel(flightPlan: flightPlan,
                                              flightPlanUiStateProvider: flightPlanUiStateProvider,
                                              coordinator: coordinator)
    }

    /// Gutma data of flights peformed for flight plan execution.
    var gutmas: [Gutma] {
        flightPlan.flightPlanFlights?
            .map { $0.flightUuid }
            .compactMap(flightRepository.loadFlight)
            .map { $0.gutmaFile }
            .compactMap(Gutma.instantiate)
        ?? []
    }

    /// Flights trajectories points.
    public var flightsPoints: [[TrajectoryPoint]] {
        flightPlan.flightPlanFlights?
            .map { $0.flightUuid }
            .compactMap(flightRepository.loadFlight)
            .map { $0.gutmaFile }
            .compactMap(Gutma.instantiate)
            .map {
                // start time of trajectory to draw
                let startTime = $0.flightPlanStartTimestamp(flightPlanUuid: flightPlan.uuid)
                // end time of trajectory to draw
                let endTime = $0.flightPlanEndTimestamp(flightPlanUuid: flightPlan.uuid)
                return $0.points(startTime: startTime, endTime: endTime)
            }
        ?? []
    }

    /// Whether trajectory points altitudes are in ASML.
    public var hasAsmlAltitude: Bool {
        if let flightPlanFlight = flightPlan.flightPlanFlights?.first,
           let flight = flightRepository.loadFlight(flightPlanFlight.flightUuid),
           let gutma = Gutma.instantiate(with: flight.gutmaFile) {
            return gutma.hasAsmlAltitude
        } else {
            return false
        }
    }
}

private struct FlightPlanExecutionInfoCellProviderImpl: FlightPlanExecutionInfoCellProvider {
    let title: String
    let executionTitle: String
    let date: Date
    let location: CLLocationCoordinate2D
    let flights: [FlightModel]
}

private struct CellProviderImpl: FlightExecutionDetailsSettingsCellProvider {
    let settings: [FlightPlanExecutionViewModel.ExecutionSetting]
}
