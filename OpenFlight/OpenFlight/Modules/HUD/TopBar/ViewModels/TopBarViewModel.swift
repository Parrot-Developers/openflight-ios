//
//  Copyright (C) 2020 Parrot Drones SAS.
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
import GroundSdk

/// State for `TopBarViewModel`.

final class TopBarState: DevicesConnectionState {
    // MARK: - Internal Properties
    /// Inform about item's visibility.
    fileprivate(set) var shouldHide: Bool = false
    /// Tells if the mission mode panel is opened.
    fileprivate(set) var isMissionModePanelOpened: Bool = false
    /// Hide Drone action buttons if remote is connected or if the drone is disconnected.
    var shouldHideDroneAction: Bool {
        return remoteControlConnectionState?.isConnected() == true
            || droneConnectionState?.isConnected() == false
    }
    /// Hide telemetry if there is no remote or drone, it can be disconnected or nil and if the mission mode panel is opened.
    var shouldHideTelemetry: Bool {
        return !shouldHideDroneAction && isMissionModePanelOpened
    }
    /// Hide radar if there is no remote or drone, it can be disconnected or nil.
    var shouldHideRadar: Bool {
        !shouldHideDroneAction
    }

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - droneConnectionState: drone connection state
    ///    - remoteControlConnectionState: drone connection state
    ///    - shouldHide: item visibility
    ///    - isMissionModePanelOpened: tells if the mission mode panel is open
    init(droneConnectionState: DeviceConnectionState?,
         remoteControlConnectionState: DeviceConnectionState?,
         shouldHide: Bool,
         isMissionModePanelOpened: Bool) {
        super.init(droneConnectionState: droneConnectionState, remoteControlConnectionState: remoteControlConnectionState)
        self.shouldHide = shouldHide
        self.isMissionModePanelOpened = isMissionModePanelOpened
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DevicesConnectionState) -> Bool {
        guard let other = other as? TopBarState else {
            return false
        }
        return super.isEqual(to: other)
            && self.shouldHide == other.shouldHide
            && self.isMissionModePanelOpened == other.isMissionModePanelOpened
    }

    // MARK: - Copying Implementation
    override func copy() -> TopBarState {
        return TopBarState(droneConnectionState: self.droneConnectionState,
                           remoteControlConnectionState: self.remoteControlConnectionState,
                           shouldHide: self.shouldHide,
                           isMissionModePanelOpened: self.isMissionModePanelOpened)
    }
}

/// View model for `HUDTopBarViewController`.

final class TopBarViewModel: DevicesStateViewModel<TopBarState> {
    // MARK: - Private Properties
    private var modalPresentationObserver: Any?
    private var missionLauncherPresentationObserver: Any?

    // MARK: - Init
    override init() {
        super.init()

        observeModalPresentation()
        observeMissionLauncherPresentation()
    }

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.remove(observer: modalPresentationObserver)
        modalPresentationObserver = nil
        NotificationCenter.default.remove(observer: missionLauncherPresentationObserver)
        missionLauncherPresentationObserver = nil
    }
}

// MARK: - Private Funcs
private extension TopBarViewModel {
    /// Starts watcher for modal presentation.
    func observeModalPresentation() {
        modalPresentationObserver = NotificationCenter.default.addObserver(
            forName: .modalPresentDidChange,
            object: nil,
            queue: nil) { [weak self] notification in
                guard let isModalPresented = notification.userInfo?[BottomBarViewControllerNotifications.notificationKey] as? Bool else {
                    return
                }
                let copy = self?.state.value.copy()
                copy?.shouldHide = isModalPresented
                self?.state.set(copy)
        }
    }

    /// Starts watcher for mission launcher mode presentation.
    func observeMissionLauncherPresentation() {
        modalPresentationObserver = NotificationCenter.default.addObserver(
            forName: .missionLauncherModeDidChange,
            object: nil,
            queue: nil) { [weak self] notification in
                if let missionLauncherMode = notification.userInfo?[MissionLauncherMode.notificationKey] as? MissionLauncherMode {
                    let copy = self?.state.value.copy()
                    copy?.isMissionModePanelOpened = missionLauncherMode == .opened
                    self?.state.set(copy)
                }
        }
    }
}
