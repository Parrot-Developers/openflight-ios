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
import SwiftyUserDefaults
import Combine

private extension ULogTag {
    static let tag = ULogTag(name: "RemoteControlUpdater")
}

public protocol RemoteControlUpdater {
    /// send mapping to remote controller
    func updateRemoteMapping()
}

class RemoteControlUpdaterImpl: RemoteControlUpdater {
    private var currentRemoteControlHolder: CurrentRemoteControlHolder
    private var remoteControl: RemoteControl?
    private var remoteControlStateRef: Ref<DeviceState>?
    private var drone: Drone?
    private var cancellables = Set<AnyCancellable>()

    init(currentRemoteControlHolder: CurrentRemoteControlHolder) {
        self.currentRemoteControlHolder = currentRemoteControlHolder
        listenRemoteControl()
    }

    private func listenRemoteControl() {
        ULog.d(.tag, "listen starting")
        currentRemoteControlHolder.remoteControlPublisher
            .sink { [unowned self] in
                guard let remoteControl = $0 else {
                    return
                }
                self.remoteControl = remoteControl
                listenConnectionState()
            }
            .store(in: &cancellables)
    }

    /// Listen to controller connection state
    private func listenConnectionState() {
        ULog.d(.tag, "listen connection state starting")
        remoteControlStateRef = remoteControl?.getState { [unowned self] deviceState in
            switch deviceState?.connectionState {
            case .connected:
                ULog.d(.tag, "device connected")
                self.updateRemoteMapping()
            default:
                break
            }
        }
    }

    func updateRemoteMapping() {
        let currentDroneHolder = Services.hub.currentDroneHolder
        drone = currentDroneHolder.drone
        guard let remoteControl = remoteControl,
              let skyCtrl4 = remoteControl.getPeripheral(Peripherals.skyCtrl4Gamepad),
              let droneModel = drone?.model else {
                  return
              }

        guard let rawUserMode = Defaults.userControlModeSetting,
              let controlMode = ControlsSettingsMode(value: rawUserMode) else {
                  return
              }

        skyCtrl4.volatileMappingSetting?.value = false

        ULog.d(.tag, "updating remote with mode \(controlMode.value)")
        switch controlMode {
        case .mode1:
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlPitch,
                                                                     axisEvent: .leftStickVertical, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlYawRotationSpeed,
                                                                     axisEvent: .leftStickHorizontal, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlThrottle,
                                                                     axisEvent: .rightStickVertical, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlRoll,
                                                                     axisEvent: .rightStickHorizontal, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .tiltCamera,
                                                                     axisEvent: .leftSlider, buttonEvents: []))
            reverseAxes([.leftSlider])
        case .mode1Inversed:
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlThrottle,
                                                                     axisEvent: .leftStickVertical, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlRoll,
                                                                     axisEvent: .leftStickHorizontal, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlPitch,
                                                                     axisEvent: .rightStickVertical, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlYawRotationSpeed,
                                                                     axisEvent: .rightStickHorizontal, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .tiltCamera,
                                                                     axisEvent: .leftSlider, buttonEvents: []))
            reverseAxes([.leftSlider])
        case .mode2:
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlThrottle,
                                                                     axisEvent: .leftStickVertical, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlYawRotationSpeed,
                                                                     axisEvent: .leftStickHorizontal, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlPitch,
                                                                     axisEvent: .rightStickVertical, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlRoll,
                                                                     axisEvent: .rightStickHorizontal, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .tiltCamera,
                                                                     axisEvent: .leftSlider, buttonEvents: []))
            reverseAxes([.leftSlider])
        case .mode2Inversed:
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlPitch,
                                                                     axisEvent: .leftStickVertical, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlRoll,
                                                                     axisEvent: .leftStickHorizontal, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlThrottle,
                                                                     axisEvent: .rightStickVertical, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlYawRotationSpeed,
                                                                     axisEvent: .rightStickHorizontal, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .tiltCamera,
                                                                     axisEvent: .leftSlider, buttonEvents: []))
            reverseAxes([.leftSlider])
        }
    }

    /// Dedicated helper to handle inverted axes.
    ///
    /// - Parameters:
    ///     - axes: set of Sky controller axis
    private func reverseAxes(_ axes: Set<SkyCtrl4Axis>) {
        guard let remoteControl = remoteControl,
              let skyCtrl4 = remoteControl.getPeripheral(Peripherals.skyCtrl4Gamepad),
              let droneModel = drone?.model else {
                  return
              }

        SkyCtrl4Axis.allCases.forEach { axe in
            if (skyCtrl4.reversedAxes(forDroneModel: droneModel)?.contains(axe) == false && axes.contains(axe))
                || (skyCtrl4.reversedAxes(forDroneModel: droneModel)?.contains(axe) == true && !axes.contains(axe)) {
                skyCtrl4.reverse(axis: axe, forDroneModel: droneModel)
            }
        }
    }
}
