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

// MARK: - ControllerInfosState
/// State for ControllerInfosViewModel.
final class ControllerInfosState: DevicesConnectionState {
    // MARK: - Internal Properties
    /// Current controller battery level.
    fileprivate(set) var batteryLevel = BatteryValueModel()
    /// Current controller gps strength.
    fileprivate(set) var gpsStrength = UserLocationGpsStrength.unavailable
    /// Current controller.
    var currentController: Controller {
        switch self.remoteControlConnectionState?.connectionState {
        case .connected, .connecting:
            return .remoteControl
        default:
            return .userDevice
        }
    }

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - droneConnectionState: drone connection state
    ///    - remoteControlConnectionState: remote control connection state
    ///    - batteryLevel: current controller battery level
    ///    - gpsStrength: current controller gps strength
    init(droneConnectionState: DeviceConnectionState?,
         remoteControlConnectionState: DeviceConnectionState?,
         batteryLevel: BatteryValueModel,
         gpsStrength: UserLocationGpsStrength) {
        super.init(droneConnectionState: droneConnectionState,
                   remoteControlConnectionState: remoteControlConnectionState)

        self.batteryLevel = batteryLevel
        self.gpsStrength = gpsStrength
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DevicesConnectionState) -> Bool {
        guard let other = other as? ControllerInfosState else { return false }

        return super.isEqual(to: other)
            && self.batteryLevel == other.batteryLevel
            && self.gpsStrength == other.gpsStrength
    }

    override func copy() -> ControllerInfosState {
        return ControllerInfosState(droneConnectionState: self.droneConnectionState,
                                    remoteControlConnectionState: self.remoteControlConnectionState,
                                    batteryLevel: self.batteryLevel,
                                    gpsStrength: self.gpsStrength)
    }
}

// MARK: - ControllerInfosViewModel
/// ViewModel for ControllerInfos, notifies on current controller, battery level and gps strength changes.
final class ControllerInfosViewModel: DevicesStateViewModel<ControllerInfosState> {
    // MARK: - Private Properties
    private let groundSdk = GroundSdk()
    private var batteryInfoRef: Ref<BatteryInfo>?
    private var alarmsRef: Ref<Alarms>?

    // MARK: - Init
    /// Init.
    override init() {
        super.init()

        listenUserDeviceBattery()
    }

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)

        listenAlarms(drone)
    }

    override func listenRemoteControl(remoteControl: RemoteControl) {
        super.listenRemoteControl(remoteControl: remoteControl)

        listenBatteryLevel(remoteControl: remoteControl)
    }

    override func remoteControlConnectionStateDidChange() {
        super.remoteControlConnectionStateDidChange()

        computeBatteryLevel()
    }
}

// MARK: - Private Funcs
private extension ControllerInfosViewModel {
    /// Starts watcher for remote control battery level.
    func listenBatteryLevel(remoteControl: RemoteControl) {
        batteryInfoRef = remoteControl.getInstrument(Instruments.batteryInfo) { [weak self] _ in
            self?.computeBatteryLevel()
        }
    }

    /// Starts watcher for user device battery level.
    func listenUserDeviceBattery() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.computeBatteryLevel),
                                               name: UIDevice.batteryLevelDidChangeNotification,
                                               object: nil)
        computeBatteryLevel()
    }

    /// Starts watcher for drone alarm.
    func listenAlarms(_ drone: Drone) {
        alarmsRef = drone.getInstrument(Instruments.alarms) { [weak self] alarms in
            let unreliableControllerLocationAlarm = alarms?.getAlarm(kind: .unreliableControllerLocation)
            self?.updateGpsStrength(unreliableControllerLocationAlarm: unreliableControllerLocationAlarm)
        }
    }

    /// Updates gps strength
    ///
    /// - Parameters:
    ///     - unreliableControllerLocationAlarm: Controller location alarm
    func updateGpsStrength(unreliableControllerLocationAlarm: Alarm?) {
        let copy = self.state.value.copy()
        switch unreliableControllerLocationAlarm?.level {
        case .critical,
             .warning:
            copy.gpsStrength = .gpsKo
        case .off:
            copy.gpsStrength = .gpsFixed
        default:
            copy.gpsStrength = .unavailable
        }
        self.state.set(copy)
    }

    /// Computes current battery level and updates state accordingly.
    @objc func computeBatteryLevel() {
        let copy = self.state.value.copy()
        switch state.value.currentController {
        case .userDevice:
            copy.batteryLevel = UIDevice.current.batteryValueModel
        case .remoteControl:
            copy.batteryLevel = BatteryValueModel(currentValue: remoteControl?.getInstrument(Instruments.batteryInfo)?.batteryLevel)
        }
        self.state.set(copy)
    }
}
