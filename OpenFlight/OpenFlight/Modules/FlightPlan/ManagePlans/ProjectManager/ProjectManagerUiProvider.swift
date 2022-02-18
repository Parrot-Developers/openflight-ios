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

/// Project manager UI parameters..
public struct ProjectManagerUiParameters {

    public struct ProjectType {
        let icon: UIImage?
        let title: String?
        let flightPlanProvider: FlightPlanProvider?
        let isStantardFlightPlan: Bool

        public init(icon: UIImage?,
                    title: String?,
                    flightPlanProvider: FlightPlanProvider?,
                    isStantardFlightPlan: Bool = false) {
            self.icon = icon
            self.title = title
            self.flightPlanProvider = flightPlanProvider
            self.isStantardFlightPlan = isStantardFlightPlan
        }
    }

    public init(projectTypes: [ProjectType]) {
        self.projectTypes = projectTypes
    }

    let projectTypes: [ProjectType]
}

/// Project manager UI Provider.
public protocol ProjectManagerUiProvider {
    /// Add another provider in the execution chain.
    ///
    /// - Parameter provider: another projects provider
    func add(provider: ProjectManagerUiProvider)

    /// Returns the parameters that need to be displayed in the Project Manager view.
    ///
    func uiParameters() -> ProjectManagerUiParameters
}

class ProjectManagerUiProviderImpl: ProjectManagerUiProvider {
    private var optionalProviders: [ProjectManagerUiProvider] = []

    func add(provider: ProjectManagerUiProvider) {
        optionalProviders.append(provider)
    }

    func uiParameters() -> ProjectManagerUiParameters {
        var projectTypes = [ProjectManagerUiParameters.ProjectType]()
        let flightPlanProjectType = ProjectManagerUiParameters.ProjectType(icon: Asset.Dashboard.icFlightModeStandard.image,
                                                                           title: L10n.commonFlightPlan,
                                                                           flightPlanProvider: FlightPlanMissionMode.standard.missionMode.flightPlanProvider,
                                                                           isStantardFlightPlan: true)
        projectTypes.append(flightPlanProjectType)

        let otherProjectTypes = optionalProviders.lazy.compactMap { $0.uiParameters().projectTypes }
        otherProjectTypes.forEach { projectTypes.append(contentsOf: $0) }

        return ProjectManagerUiParameters(projectTypes: projectTypes)
    }
}
