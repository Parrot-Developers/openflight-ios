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
import Combine

class ProjectCellModel {

    @Published private(set) var thumbnail: UIImage!
    @Published private(set) var title: String?
    @Published private(set) var description: String?
    @Published private(set) var projectTypeIcon: UIImage?
    @Published private(set) var isSelected: Bool = false
    @Published private(set) var hasExecutions: Bool = false

    private let project: ProjectModel!

    enum Constants {
        static let defaultThumbnail = Asset.MyFlights.projectPlaceHolder.image
    }

    init(project: ProjectModel,
         isSelected: Bool,
         projectManager: ProjectManager) {
        self.project = project
        self.isSelected = isSelected

        thumbnail = Constants.defaultThumbnail

        let editableFlightPlan = project.flightPlans?.first { $0.state == .editable }

        title = project.title ?? editableFlightPlan?.dataSetting?.coordinate?.coordinatesDescription
        description = project.lastUpdated.commonFormattedString

        thumbnail = editableFlightPlan?.thumbnail?.thumbnailImage ?? Constants.defaultThumbnail

        if !project.isSimpleFlightPlan,
           let executionType = Services.hub.flightPlan.typeStore.typeForKey(editableFlightPlan?.type) {
            projectTypeIcon = executionType.icon
        } else {
            projectTypeIcon = nil
        }

        hasExecutions =  !projectManager.executedFlightPlans(for: project).isEmpty
    }
}
