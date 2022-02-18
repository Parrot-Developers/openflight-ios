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

class FlightPlanEditionMenuViewModel {

    @Published private(set) var viewState: ViewState?
    private var editionService: FlightPlanEditionService

    init(editionService: FlightPlanEditionService) {
        self.editionService = editionService
    }

    enum ViewState {
        case update(FlightPlanModel?)
        case refresh
    }

    func updateModel(_ model: FlightPlanModel?) {
        viewState = .update(model)
    }

    func refreshContent() {
        viewState = .refresh
    }

    func projectNameCellProvider(forFlightPlan flightPlan: FlightPlanModel?) -> ProjectNameMenuTableViewCellProvider {
        ProjectNameCellProvider(flightPlan: flightPlan,
                                editionService: editionService)
    }
}

private protocol ProjectNameProvider {
    func title(ofFlightPlan flightPlan: FlightPlanModel?) -> String
    func update(title: String, ofFlightPlan flightPlan: FlightPlanModel?)
}

private struct ProjectNameCellProvider: ProjectNameMenuTableViewCellProvider, ProjectNameProvider {

    var flightPlan: FlightPlanModel?
    var editionService: FlightPlanEditionService

    var title: String {
        get {
            title(ofFlightPlan: flightPlan)
        }
        set {
            update(title: newValue, ofFlightPlan: flightPlan)
        }
    }

    func title(ofFlightPlan flightPlan: FlightPlanModel?) -> String {
        guard let flightPlan = flightPlan else { return "" }
        return flightPlan.customTitle
    }

    func update(title: String, ofFlightPlan flightPlan: FlightPlanModel?) {
        guard let flightPlan = flightPlan else { return }
        editionService.rename(flightPlan, title: title)
    }
}
