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
    private var panelCoordinator: FlightPlanPanelCoordinator?
    private var projectManager: ProjectManager

    init(editionService: FlightPlanEditionService,
         panelCoordinator: FlightPlanPanelCoordinator?,
         projectManager: ProjectManager) {
        self.editionService = editionService
        self.panelCoordinator = panelCoordinator
        self.projectManager = projectManager
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
                                editionService: editionService,
                                panelCoordinator: panelCoordinator,
                                projectManager: projectManager)
    }
}

private protocol ProjectNameProvider {
    func title(ofFlightPlan flightPlan: FlightPlanModel?) -> String
    func update(title: String, ofFlightPlan flightPlan: FlightPlanModel?)
}

private struct ProjectNameCellProvider: ProjectNameMenuTableViewCellProvider, ProjectNameProvider {

    var flightPlan: FlightPlanModel?
    var editionService: FlightPlanEditionService
    var panelCoordinator: FlightPlanPanelCoordinator?
    var projectManager: ProjectManager

    // When it's a project creation, prompt user to edit the title at the opening.
    var isTitleEditionNeeded: Bool { projectManager.isCurrentProjectBrandNew }

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
        return flightPlan.pictorModel.name
    }

    func update(title: String, ofFlightPlan flightPlan: FlightPlanModel?) {
        // Ensure the FP exist and the title is not empty.
        guard let flightPlan = flightPlan,
              !title.isEmpty
        else { return }
        let newTitle: String
        // Check if the title has been modified.
        if flightPlan.pictorModel.name != title {
            // Generate an unique title.
            // If the new title is already used by another project,
            // use the same rule than for a project creation (adding ' ({index})' suffix).
            newTitle = projectManager.renamedProjectTitle(for: title,
                                                             of: projectManager.project(for: flightPlan))
        } else {
            // No change has been done. But we must update the name handled
            // in `editionService` to continue edition process (behavior to be improved).
            newTitle = title
        }
        // Store the new name.
        editionService.rename(flightPlan, title: newTitle)
    }
}
