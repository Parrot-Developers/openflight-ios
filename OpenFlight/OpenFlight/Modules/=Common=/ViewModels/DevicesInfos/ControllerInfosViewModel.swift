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
import Combine

// MARK: - ControllerInfosViewModel
/// ViewModel for ControllerInfos, notifies on current controller, battery level and gps strength changes.
final class ControllerInfosViewModel {
    // MARK: - Private Properties
    /// Current controller battery level.
    @Published private(set) var batteryLevel: BatteryValueModel = BatteryValueModel()
    /// Current controller gps strength.
    @Published private(set) var gpsStrength: UserLocationGpsStrength = UserLocationGpsStrength.unavailable
    /// Current controller connection state
    @Published private(set) var remoteControlConnectionState: DeviceState.ConnectionState = .disconnected
    /// Current controller
    @Published private(set) var currentController: Controller = .userDevice

    private var batteryInfoRef: Ref<BatteryInfo>?
    private var alarmsRef: Ref<Alarms>?
    private var remoteControlStateRef: Ref<DeviceState>?
    private var cancellables = Set<AnyCancellable>()

    // TODO - Wrong injection
    private var connectedRemoteControlHolder = Services.hub.connectedRemoteControlHolder

    /// Listens for update from the remote controller
    /// - Parameter remoteControl: The current remote controller
    func listenRemoteControl(remoteControl: RemoteControl) {
        remoteControlStateRef = remoteControl.getState { [weak self] remoteControlState in
            self?.remoteControlConnectionState = remoteControlState?.connectionState ?? .disconnected
            self?.computeBatteryLevel(remoteControl: remoteControl)
        }
    }

    // MARK: - Init
    init() {
        listenUserDeviceBattery()

        Services.hub.currentDroneHolder.dronePublisher
            .sink { [unowned self] drone in
                listenAlarms(drone)
            }
            .store(in: &cancellables)

        connectedRemoteControlHolder.remoteControlPublisher
            .sink { [unowned self] remoteControl in
                guard let remoteControl = remoteControl else {
                    currentController = .userDevice
                    return
                }
                currentController = .remoteControl
                listenRemoteControl(remoteControl: remoteControl)
                listenBatteryLevel(remoteControl: remoteControl)
            }
            .store(in: &cancellables)
    }
}

// MARK: - Private Funcs
private extension ControllerInfosViewModel {
    /// Starts watcher for remote control battery level.
    ///
    /// - Parameters:
    ///     - remoteControl: the current remote control
    func listenBatteryLevel(remoteControl: RemoteControl) {
        batteryInfoRef = remoteControl.getInstrument(Instruments.batteryInfo) { [weak self] _ in
            self?.computeBatteryLevel(remoteControl: remoteControl)
        }
    }

    /// Starts watcher for user device battery level.
    func listenUserDeviceBattery() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.handleDeviceBatteryLevelChange),
                                               name: UIDevice.batteryLevelDidChangeNotification,
                                               object: nil)
        computeBatteryLevel(remoteControl: nil)
    }

    /// Starts watcher for drone alarm.
    ///
    /// - Parameters:
    ///     - drone: the current drone
    func listenAlarms(_ drone: Drone) {
        alarmsRef = drone.getInstrument(Instruments.alarms) { [weak self] alarms in
            let unreliableControllerLocationAlarm = alarms?.getAlarm(kind: .unreliableControllerLocation)
            self?.updateGpsStrength(unreliableControllerLocationAlarm: unreliableControllerLocationAlarm)
        }
    }

    /// Handles device's battery level changes.
    ///
    /// - Parameters:
    ///     - notification: the current notification
    @objc func handleDeviceBatteryLevelChange(notification: NSNotification) {
        guard connectedRemoteControlHolder.remoteControl == nil else {
            // Listens currently remote control
            return
        }

        computeBatteryLevel(remoteControl: nil)
    }

    /// Updates gps strength
    ///
    /// - Parameters:
    ///     - unreliableControllerLocationAlarm: Controller location alarm
    func updateGpsStrength(unreliableControllerLocationAlarm: Alarm?) {
        switch unreliableControllerLocationAlarm?.level {
        case .critical,
             .warning:
            gpsStrength = .gpsKo
        case .off:
            gpsStrength = .gpsFixed
        default:
            gpsStrength = .unavailable
        }
    }

    /// Computes current battery level and updates state accordingly.
    ///
    /// - Parameters:
    ///     - remoteControl: the current remote control
    func computeBatteryLevel(remoteControl: RemoteControl?) {
        guard let remoteControl = remoteControl else {
            batteryLevel = UIDevice.current.batteryValueModel
            return
        }
        batteryLevel = BatteryValueModel(currentValue: remoteControl.getInstrument(Instruments.batteryInfo)?.batteryLevel)
    }
}
