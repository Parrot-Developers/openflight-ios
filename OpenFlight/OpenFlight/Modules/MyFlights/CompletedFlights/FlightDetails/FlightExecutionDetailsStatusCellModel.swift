//
//
//  Copyright (C) 2021 Parrot Drones SAS.
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

class FlightExecutionDetailsStatusCellModel {
    // FlightPlan Status
    @Published private(set) var statusText: String?
    @Published private(set) var statusTextColor: Color?

    // Uploading Photo State
    @Published private(set) var uploadingPhotosCount: Int?
    @Published private(set) var uploadingExtraIcon: UIImage?
    @Published private(set) var uploadingProgressText: String?

    // Uploading Photo State
    @Published private(set) var uploadPausedText: String?
    @Published private(set) var uploadPausedProgressText: String?

    // Freemium text
    @Published private(set) var freemiumText: String?

    // Action Button
    @Published private(set) var actionButtonText: String?
    @Published private(set) var actionButtonTextColor: UIColor?
    @Published private(set) var actionButtonColor: UIColor?
    @Published private(set) var actionButtonProgress: Double?
    @Published private(set) var actionButtonProgressColor: UIColor?
    @Published private(set) var actionButtonAction: ((Coordinator?) -> Void)?

    private let flightPlan: FlightPlanModel!
    private let flightPlanUiStateProvider: FlightPlanUiStateProvider!
    let coordinator: DashboardCoordinator?

    private var cancellables = Set<AnyCancellable>()

    init(flightPlan: FlightPlanModel,
         flightPlanUiStateProvider: FlightPlanUiStateProvider,
         coordinator: DashboardCoordinator?) {
        self.flightPlan = flightPlan
        self.flightPlanUiStateProvider = flightPlanUiStateProvider
        self.coordinator = coordinator
        addSubsribers()
    }

    func addSubsribers() {
        flightPlanUiStateProvider.uiStatePublisher(for: flightPlan)
            .sink { [unowned self] stateUiParameters in
                statusText = stateUiParameters.statusText
                statusTextColor = stateUiParameters.statusTextColor

                uploadingPhotosCount = stateUiParameters.uploadingPhotosCount
                uploadingExtraIcon = stateUiParameters.uploadingExtraIcon
                uploadingProgressText = stateUiParameters.uploadingProgressText

                uploadPausedText = stateUiParameters.uploadPausedText
                uploadPausedProgressText = stateUiParameters.uploadPausedProgressText

                freemiumText = stateUiParameters.freemiumText

                actionButtonText = stateUiParameters.actionButtonText
                actionButtonTextColor = stateUiParameters.actionButtonTextColor
                actionButtonColor = stateUiParameters.actionButtonColor
                actionButtonProgress = stateUiParameters.actionButtonProgress
                actionButtonProgressColor = stateUiParameters.actionButtonProgressColor

                actionButtonAction = stateUiParameters.actionButtonCallback
            }
            .store(in: &cancellables)
    }
}
