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

final class ControllerInfosState: ViewModelState, EquatableState {
    // MARK: - Internal Properties
    /// Observable for current controller.
    fileprivate(set) var currentController = Observable(Controller.userDevice)
    /// Observable for current controller battery level.
    fileprivate(set) var batteryLevel = Observable(BatteryValueModel())
    /// Obsservable for controller gps strength.
    fileprivate(set) var gpsStrength = Observable(UserLocationGpsStrength.unauthorized)

    // MARK: - Public Funcs
    func isEqual(to other: ControllerInfosState) -> Bool {
        return self.batteryLevel.value == other.batteryLevel.value
            && self.gpsStrength.value == other.gpsStrength.value
    }
}

// MARK: - ControllerInfosViewModel
/// ViewModel for ControllerInfos, notifies on current controller, battery level and gps strength changes.

final class ControllerInfosViewModel: RemoteControlWatcherViewModel<ControllerInfosState> {
    // MARK: - Private Properties
    private let groundSdk = GroundSdk()
    private var remoteControlStateRef: Ref<DeviceState>?
    private var batteryInfoRef: Ref<BatteryInfo>?
    private var userLocationManager: LocationManager

    // MARK: - Init
    private init() {
        fatalError("Forbidden init")
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - userLocationManager: provider for user location update callbacks
    ///    - controllerDidChange: called when controller changes
    ///    - batteryLevelDidChange: called when battery level changes
    ///    - gosStrengthDidChange: called when gps strength changes
    init(userLocationManager: LocationManager,
         controllerDidChange: ((Controller) -> Void)? = nil,
         batteryLevelDidChange: ((BatteryValueModel) -> Void)? = nil,
         gpsStrengthDidChange: ((UserLocationGpsStrength) -> Void)? = nil) {
        self.userLocationManager = userLocationManager
        super.init()
        state.value.currentController.valueChanged = controllerDidChange
        state.value.batteryLevel.valueChanged = batteryLevelDidChange
        state.value.gpsStrength.valueChanged = gpsStrengthDidChange
        listenUserDeviceBattery()
        listenUserLocation()
    }

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Override Funcs
    override func listenRemoteControl(remoteControl: RemoteControl) {
        listenState(remoteControl: remoteControl)
        listenBatteryLevel(remoteControl: remoteControl)
    }
}

// MARK: - Private Funcs
private extension ControllerInfosViewModel {
    /// Starts watcher for remote control state.
    func listenState(remoteControl: RemoteControl) {
        remoteControlStateRef = remoteControl.getState { [weak self] state in
            switch state?.connectionState {
            case .connected:
                self?.state.value.currentController.set(.remoteControl)
            default:
                self?.state.value.currentController.set(.userDevice)
            }
            self?.computeBatteryLevel()
        }
    }

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

    /// Starts watcher for user location.
    func listenUserLocation() {
        userLocationManager.onLocationUpdate = { [weak self] in
            guard let userLocation = self?.groundSdk.getFacility(Facilities.userLocation) else {
                return
            }
            self?.state.value.gpsStrength.set(userLocation.gpsStrength)
        }
        // Set initial state.
        state.value.gpsStrength.set(groundSdk.getFacility(Facilities.userLocation)?.gpsStrength)
    }

    /// Computes current battery level and updates state accordingly.
    @objc func computeBatteryLevel() {
        switch state.value.currentController.value {
        case .userDevice:
            state.value.batteryLevel.set(UIDevice.current.batteryValueModel)
        case .remoteControl:
            guard let remoteControl = remoteControl,
                let batteryInfo = remoteControl.getInstrument(Instruments.batteryInfo) else {
                    state.value.batteryLevel.set(BatteryValueModel(currentValue: nil, alertLevel: .none))
                    return
            }
            state.value.batteryLevel.set(batteryInfo.batteryValueModel)
        }
    }
}
