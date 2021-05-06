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

import GroundSdk
import SwiftyUserDefaults

// MARK: - Internal Enums
/// Notification value for joysticks visibility.
enum JoysticksStateNotifications {
    /// Returns unique key for joysticks notifications.
    static var joysticksAvailabilityNotificationKey: String {
        return "joysticksAvailabilityNotification"
    }
}

/// State for `JoysticksAvailabilityViewModel`.

final class JoysticksAvailabilityState: DevicesConnectionState {
    // MARK: - Internal Properties
    /// Tells if we need to hide joysticks.
    fileprivate(set) var shouldHideJoysticks: Bool = false
    /// Tells if the bottom bar is opened.
    fileprivate(set) var isBottomBarOpened: Bool = false
    /// Tells if Joysticks are available.
    fileprivate(set) var allowingJoysticks: Bool = false

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - droneConnectionState: drone connection state
    ///    - remoteControlConnectionState: remote control connection state
    ///    - shouldHideJoysticks: tells if we need to hide joysticks
    ///    - allowingJoysticks: tells if Joysticks are available
    ///    - isBottomBarOpened: tells if bottom bar is opened
    init(droneConnectionState: DeviceConnectionState?,
         remoteControlConnectionState: DeviceConnectionState?,
         shouldHideJoysticks: Bool,
         allowingJoysticks: Bool,
         isBottomBarOpened: Bool) {
        super.init(droneConnectionState: droneConnectionState,
                   remoteControlConnectionState: remoteControlConnectionState)
        self.shouldHideJoysticks = shouldHideJoysticks
        self.allowingJoysticks = allowingJoysticks
        self.isBottomBarOpened = isBottomBarOpened
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DevicesConnectionState) -> Bool {
        guard let other = other as? JoysticksAvailabilityState else {
            return false
        }
        return super.isEqual(to: other)
            && self.shouldHideJoysticks == other.shouldHideJoysticks
            && self.allowingJoysticks == other.allowingJoysticks
            && self.isBottomBarOpened == other.isBottomBarOpened
    }

    override func copy() -> JoysticksAvailabilityState {
        return JoysticksAvailabilityState(droneConnectionState: self.droneConnectionState,
                                          remoteControlConnectionState: self.remoteControlConnectionState,
                                          shouldHideJoysticks: self.shouldHideJoysticks,
                                          allowingJoysticks: self.allowingJoysticks,
                                          isBottomBarOpened: self.isBottomBarOpened)
    }
}

/// ViewModel for joysticks button, notifies on jogs availability.

final class JoysticksAvailabilityViewModel: DevicesStateViewModel<JoysticksAvailabilityState> {
    // MARK: - Private Properties
    private var remoteConnectionStateRef: Ref<DeviceState>?
    private var droneConnectionStateRef: Ref<DeviceState>?
    private var defaultsDisposable: DefaultsDisposable?
    private var bottomBarModeObserver: Any?

    // MARK: - Init
    override init() {
        super.init()

        listenDefaults()
        listenBottomBarModeChanges()
        updateJoysticksAvailability()
    }

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.remove(observer: bottomBarModeObserver)
        bottomBarModeObserver = nil
        defaultsDisposable?.dispose()
        defaultsDisposable = nil
    }

    // MARK: - Override Funcs
    override func listenRemoteControl(remoteControl: RemoteControl) {
        super.listenRemoteControl(remoteControl: remoteControl)
        listenRemoteControlState(remoteControl: remoteControl)
    }

    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)
        listenDroneState(drone: drone)
    }

    // MARK: - Internal Funcs
    /// Update jogs button visibiility.
    func toggleJogsButtonVisibility() {
        let copy = state.value.copy()
        copy.shouldHideJoysticks = !copy.shouldHideJoysticks
        state.set(copy)
        updateItemsVisibility()
    }
}

// MARK: - Private Funcs
private extension JoysticksAvailabilityViewModel {
    /// Starts watcher for remote control state.
    func listenRemoteControlState(remoteControl: RemoteControl) {
        remoteConnectionStateRef = remoteControl.getState { [weak self] _ in
            self?.updateJoysticksAvailability()
        }
    }

    /// Starts watcher for drone state.
    func listenDroneState(drone: Drone) {
        droneConnectionStateRef = drone.getState { [weak self] _ in
            self?.updateJoysticksAvailability()
        }
    }

    /// Starts watcher for bottom bar mode changes.
    func listenBottomBarModeChanges() {
        bottomBarModeObserver = NotificationCenter.default.addObserver(forName: .bottomBarModeDidChange,
                                                                       object: nil,
                                                                       queue: nil) { [weak self] notification in
            if let bottomBarMode = notification.userInfo?[BottomBarMode.notificationKey] as? BottomBarMode {
                let copy = self?.state.value.copy()
                copy?.isBottomBarOpened = bottomBarMode != .closed
                self?.state.set(copy)
                self?.updateItemsVisibility()
            }
        }
    }

    /// Update joysticks availability according to remote and drone state.
    func updateJoysticksAvailability() {
        let copy = state.value.copy()
        copy.allowingJoysticks = remoteConnectionStateRef?.value?.connectionState != .connected
            && droneConnectionStateRef?.value?.connectionState == .connected
        state.set(copy)
        state.set(copy)
        updateItemsVisibility()
    }

    /// Send notifications about joysticks availability.
    func updateItemsVisibility() {
        let copy = state.value.copy()
        let shouldShowJoysticks = !copy.shouldHideJoysticks && !copy.isBottomBarOpened && state.value.allowingJoysticks
        NotificationCenter.default.post(name: .joysticksAvailabilityDidChange,
                                        object: self,
                                        userInfo: [JoysticksStateNotifications.joysticksAvailabilityNotificationKey:
                                            shouldShowJoysticks])
    }

    /// Starts watcher for mission mode change in Default.
    func listenDefaults() {
        defaultsDisposable = Defaults.observe(\.userMissionMode, options: [.new]) { [weak self] _ in
            DispatchQueue.userDefaults.async {
                let copy = self?.state.value.copy()
                let currentMissionMode = MissionsManager.shared.missionSubModeFor(key: Defaults.userMissionMode)
                copy?.shouldHideJoysticks = currentMissionMode?.key != ClassicMission.manualMode.key
                self?.state.set(copy)
                self?.updateItemsVisibility()
            }
        }
    }
}
