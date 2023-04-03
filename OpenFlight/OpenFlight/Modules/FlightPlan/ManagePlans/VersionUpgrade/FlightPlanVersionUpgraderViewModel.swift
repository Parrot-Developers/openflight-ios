//    Copyright (C) 2022 Parrot Drones SAS
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
import GroundSdk
import Combine

private extension ULogTag {
    static let tag = ULogTag(name: "FlightPlanVersionUpgraderViewModel")
}

final class FlightPlanVersionUpgraderViewModel {

    enum UpgradeState {
        case idle
        case updating(progress: Double)
        case saving
        case ended
    }

    @Published var upgradeState: UpgradeState = .idle

    private let databaseUpdateService: DatabaseUpdateService

    init(databaseUpdateService: DatabaseUpdateService) {
        self.databaseUpdateService = databaseUpdateService
    }

    func startUpgrade() {
        // Ensure no upgrade is running.
        guard case .idle = upgradeState else {
            ULog.e(.tag, "Attempting to start an upgrade already running.")
            return
        }

        // Start database update
        databaseUpdateService.startUpdate { [weak self] totalCount, updatedCount in
            guard let self = self else { return }

            // Ends process if totalCount <= 0.
            guard totalCount > 0 else {
                self.updateState(.ended)
                return
            }

            // Calculate the progress in percent.
            let percentProgress = 100 * Double(updatedCount) / Double(totalCount)
            // When all flight plans have been updated, switch to saving state.
            if percentProgress >= 100 {
                self.updateState(.updating(progress: 100))
                self.updateState(.ended)
            } else {
                // Update the progress state.
                self.updateState(.updating(progress: percentProgress))
            }
        }
    }
}

private extension FlightPlanVersionUpgraderViewModel {
    func updateState(_ state: UpgradeState) {
        DispatchQueue.main.async {
            self.upgradeState = state
        }
    }
}
