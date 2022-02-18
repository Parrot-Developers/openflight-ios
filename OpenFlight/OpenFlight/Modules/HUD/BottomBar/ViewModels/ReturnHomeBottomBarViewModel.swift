//    Copyright (C) 2020 Parrot Drones SAS
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

import GroundSdk
import Combine

private extension ULogTag {
    static let tag = ULogTag(name: "ReturnHomeBottomBarVM")
}

final class ReturnHomeBottomBarViewModel {

    /// Current target to RTH
    @Published private(set) var rthPreferredTarget: String?

    // MARK: - Private Properties
    private let currentDrone = Services.hub.currentDroneHolder
    private let currentMissionManager = Services.hub.currentMissionManager
    private var returnHomeRef: Ref<ReturnHomePilotingItf>?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init() {
        // Listen Setting : RTH
        currentDrone.dronePublisher
            .combineLatest(currentMissionManager.modePublisher)
            .sink { [unowned self] (drone, missionMode) in
                returnHomeRef = drone.getPilotingItf(PilotingItfs.returnHome) { rth in
                    rthPreferredTarget = missionMode.rthTitle(rth?.preferredTarget.target) // default
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Internal Funcs
    /// Stops Return Home.
    func stopReturnHome() {
        ULog.i(.tag, "stopReturnHome")
        currentDrone.drone.cancelReturnHome()
    }
}
