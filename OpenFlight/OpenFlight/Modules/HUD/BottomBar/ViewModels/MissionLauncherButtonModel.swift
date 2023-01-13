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

/// Model for `MissionLauncherButton`
class MissionLauncherButtonModel {

    /// Cancellables
    private var cancellables = Set<AnyCancellable>()
    /// Coordinator
    weak var coordinator: HUDCoordinator? {
        didSet {
            guard let coordinator = coordinator else { return }
            coordinator.showMissionLauncherPublisher.sink { [unowned self] in
                selected = $0
            }
            .store(in: &cancellables)
        }
    }
    /// Is the mission launcher (aka MissionProviderSelector) shown
    @Published private(set) var selected = false
    /// The mission's image
    @Published private(set) var image: UIImage!
    /// Is the mission launcher button enabled
    @Published private(set) var isEnabled = true
    /// Is the mission launcher button hidden
    @Published private(set) var isHidden = false

    /// Init
    /// - Parameters:
    ///   - currentMissionManager: the current mission manager
    ///   - navigationStackService: Navigation stack service needed to handle the button state according current stack.
    init(currentMissionManager: CurrentMissionManager,
         navigationStackService: NavigationStackService) {
        currentMissionManager.modePublisher.sink { [unowned self] mode in
            image = mode.icon
        }
        .store(in: &cancellables)
        // Hide mission button when we coming from another view than Dashboard
        navigationStackService.stackPublisher
            .sink { [unowned self] in
                // Hide button only if navigation stack counts more than 1 element in order to
                // avoid visual glitch when pushing Dashboard controller.
                isHidden = $0.count > 1
            }
            .store(in: &cancellables)
    }
}
