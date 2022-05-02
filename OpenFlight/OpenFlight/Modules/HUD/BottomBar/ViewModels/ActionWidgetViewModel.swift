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

import UIKit
import Combine

/// A view model describing the action widgets.
final class ActionWidgetViewModel {
    /// Whether an action widget is displayed.
    @Published private(set) var isActionWidgetShown = false
    /// Whether RTH widget should be shown.
    @Published private(set) var shouldShowRthWidget = false
    /// Whether panorama widget should be shown.
    @Published private(set) var shouldShowPanoramaWidget = false
    /// The active mission widgets.
    @Published private(set) var missionWidgets: (() -> [UIView])?

    // MARK: - Private Properties

    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()

    /// An option set describing the active action widgets.
    struct ActionWidgetType: OptionSet {
        let rawValue: Int

        /// RTH widget.
        static let rth = ActionWidgetType(rawValue: 1 << 1)
        /// Panorama widget.
        static let panorama = ActionWidgetType(rawValue: 1 << 0)
        /// Mission widget.
        static let mission = ActionWidgetType(rawValue: 1 << 2)
    }

    /// The active action widgets.
    private var actionWidgetTypes: ActionWidgetType = [] {
        didSet {
            guard oldValue.isEmpty != actionWidgetTypes.isEmpty else { return }
            isActionWidgetShown = !actionWidgetTypes.isEmpty
        }
    }

    // MARK: - Init
    init(rthService: RthService,
         panoramaService: PanoramaService,
         currentMissionManager: CurrentMissionManager) {
        listenToRth(rthService)
        listenToPanorama(panoramaService)
        listenToMissionMode(currentMissionManager)
    }
}

// MARK: - Listening Functions

private extension ActionWidgetViewModel {

    /// Listens to RTH service.
    ///
    /// - Parameter service: the RTH service
    func listenToRth(_ service: RthService) {
        service.isActivePublisher.removeDuplicates().sink { [weak self] isActive in
            guard let self = self else { return }
            self.shouldShowRthWidget = isActive
            self.updateShownState(actionWidgetType: .rth, isShown: isActive)
        }
        .store(in: &cancellables)
    }

    /// Listens to panorama service.
    ///
    /// - Parameter service: the panorama service
    func listenToPanorama(_ service: PanoramaService) {
        service.panoramaOngoingPublisher.sink { [weak self] isOngoing in
            guard let self = self else { return }
            self.shouldShowPanoramaWidget = isOngoing
            self.updateShownState(actionWidgetType: .panorama, isShown: isOngoing)
        }
        .store(in: &cancellables)
    }

    /// Listens to mission mode manager.
    ///
    /// - Parameter missionManager: the mission manager
    func listenToMissionMode(_ missionManager: CurrentMissionManager) {
        missionManager.modePublisher.sink { [weak self] mode in
            guard let self = self else { return }
            self.missionWidgets = self.getMissionWidgets(for: mode)
            self.updateShownState(actionWidgetType: .mission, isShown: self.missionWidgets != nil)
        }
        .store(in: &cancellables)
    }
}

// MARK: - Widgets State Handling

private extension ActionWidgetViewModel {

    /// Gets mission widgets from mission mode stack state.
    ///
    /// - Parameter missionMode: the mission mode
    func getMissionWidgets(for missionMode: MissionMode?) -> (() -> [UIView])? {
        guard let stack = missionMode?.bottomBarLeftStack else { return nil }

        // Filter out `BehaviourModeView` views as they are displayed in bottom bar.
        let missionWidgets = stack().filter { !($0 is BehaviourModeView) }
        return missionWidgets.isEmpty ? nil : { missionWidgets }
    }

    /// Updates global action widgets option set for a specific type.
    ///
    /// - Parameters:
    ///    - actionWidgetType: the action widget type to update in global option set.
    ///    - isShown: whether the widget is shown
    func updateShownState(actionWidgetType: ActionWidgetType, isShown: Bool) {
        if isShown {
            actionWidgetTypes.insert(actionWidgetType)
        } else {
            actionWidgetTypes.remove(actionWidgetType)
        }
    }
}
