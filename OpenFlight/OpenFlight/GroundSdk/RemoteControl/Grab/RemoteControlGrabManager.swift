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

/// Class that manages remote control grabs, allowing multiple grabs and avoiding conflicts.

final class RemoteControlGrabManager {
    // MARK: - Shared Instance
    static let shared = RemoteControlGrabManager()

    // MARK: - Private Properties
    private var currentRemoteControlWatcher = CurrentRemoteControlWatcher()
    private var remoteControlStateRef: Ref<DeviceState>?
    private var grabbedButtons = [SkyCtrl3Button]()
    private var grabbedAxis = [SkyCtrl3Axis]()
    private var eventsForButton: [SkyCtrl3ButtonEvent: [String: ((SkyCtrl3ButtonEventState) -> Void)]] = [:]
    private var eventsForAxis: [SkyCtrl3AxisEvent: [String: ((Int) -> Void)]] = [:]
    private var isRemoteControlDisabled: Bool = false

    // MARK: - Init
    private init() {
        listenRemoteControl()
    }
}

// MARK: - Internal Funcs
extension RemoteControlGrabManager {
    /// Completely disables SkyController actions, overriding any other grab.
    func disableRemoteControl() {
        isRemoteControlDisabled = true
        updateGrabRemoteControl()
    }

    /// Re-enables SkyController actions, restoring previously overriden grabs.
    func enableRemoteControl() {
        isRemoteControlDisabled = false
        updateGrabRemoteControl()
    }

    /// Grabs given axis.
    ///
    /// - Parameters:
    ///    - axis: axis to grab
    func grabAxis(_ axis: SkyCtrl3Axis) {
        grabbedAxis.append(axis)
        updateGrabRemoteControl()
    }

    /// Releases given axis.
    ///
    /// - Parameters:
    ///    - axis: axis to release
    func ungrabAxis(_ axis: SkyCtrl3Axis) {
        if let index = grabbedAxis.firstIndex(where: {$0 == axis}) {
            grabbedAxis.remove(at: index)
            updateGrabRemoteControl()
        }
    }

    /// Grabs given button.
    ///
    /// - Parameters:
    ///    - button: button to grab
    func grabButton(_ button: SkyCtrl3Button) {
        grabbedButtons.append(button)
        updateGrabRemoteControl()
    }

    /// Relases given button.
    ///
    /// - Parameters:
    ///    - button: button to release
    func ungrabButton(_ button: SkyCtrl3Button) {
        if let index = grabbedButtons.firstIndex(where: {$0 == button}) {
            grabbedButtons.remove(at: index)
            updateGrabRemoteControl()
        }
    }

    /// Adds an action to a specific axis event.
    /// (⚠️ axis should be grabbed for this to work).
    ///
    /// - Parameters:
    ///    - axisEvent: affected event
    ///    - key: unique key of the action
    ///    - action: action to trigger when event occurs
    func addAction(for axisEvent: SkyCtrl3AxisEvent, key: String, action: @escaping ((Int) -> Void)) {
        if eventsForAxis[axisEvent] == nil {
            eventsForAxis[axisEvent] = [:]
        }
        eventsForAxis[axisEvent]?[key] = action
    }

    /// Removes an action previously attached to a specific axis event.
    ///
    /// - Parameters:
    ///    - axisEvent: affected event
    ///    - key: unique key of the action
    func removeAction(for axisEvent: SkyCtrl3AxisEvent, key: String) {
        eventsForAxis[axisEvent]?[key] = nil
    }

    /// Adds an action to a specific button event.
    /// (⚠️ button should be grabbed for this to work).
    ///
    /// - Parameters:
    ///    - buttonEvent: affected event
    ///    - key: unique key of the action
    ///    - action: action to trigger when event occurs
    func addAction(for buttonEvent: SkyCtrl3ButtonEvent, key: String, action: @escaping ((SkyCtrl3ButtonEventState) -> Void)) {
        if eventsForButton[buttonEvent] == nil {
            eventsForButton[buttonEvent] = [:]
        }
        eventsForButton[buttonEvent]?[key] = action
    }

    /// Removes an action previously attached to a specific button event.
    ///
    /// - Parameters:
    ///    - buttonEvent: affected event
    ///    - key: unique key of the action
    func removeAction(for buttonEvent: SkyCtrl3ButtonEvent, key: String) {
        eventsForButton[buttonEvent]?[key] = nil
    }
}

// MARK: - Private Funcs
private extension RemoteControlGrabManager {
    /// Starts watcher for remote control.
    func listenRemoteControl() {
        currentRemoteControlWatcher.start { [weak self] remoteControl in
            self?.listenState(remoteControl: remoteControl)
        }
    }

    /// Starts watcher for remote control's state.
    func listenState(remoteControl: RemoteControl) {
        remoteControlStateRef = remoteControl.getState { [weak self] _ in
            if remoteControl.isConnected {
                self?.updateGrabRemoteControl()
            }
        }
    }

    /// Updates grab RemoteControl with current properties.
    func updateGrabRemoteControl() {
        guard let remoteControl = currentRemoteControlWatcher.remoteControl,
            remoteControl.isConnected,
            let skyCtrl3 = remoteControl.getPeripheral(Peripherals.skyCtrl3Gamepad) else {
                return
        }

        if isRemoteControlDisabled {
            skyCtrl3.grab(buttons: SkyCtrl3Button.allCases, axes: SkyCtrl3Axis.allCases)
            skyCtrl3.axisEventListener = nil
            skyCtrl3.buttonEventListener = nil
        } else {
            skyCtrl3.grab(buttons: Set(grabbedButtons), axes: Set(grabbedAxis))
            skyCtrl3.axisEventListener = { [weak self] newEvent, newState in
                self?.eventsForAxis[newEvent]?.forEach { $0.value(newState) }
            }
            skyCtrl3.buttonEventListener = { [weak self] newEvent, newState in
                self?.eventsForButton[newEvent]?.forEach { $0.value(newState) }
            }
        }
    }
}
