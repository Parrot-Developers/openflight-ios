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

// MARK: - UserDeviceInfosState
/// State for `UserDeviceViewModel`.
final class UserDeviceInfosState: ViewModelState {
    // MARK: - Internal properties
    /// Observable for current battery level.
    fileprivate(set) var userDeviceBatteryLevel = Observable(BatteryValueModel())
    /// Observable for gps strength level.
    fileprivate(set) var userDeviceGpsStrength = Observable(UserLocationGpsStrength.unavailable)
}

// MARK: - UserDeviceViewModel
/// View model for user device informations.
final class UserDeviceViewModel: BaseViewModel<UserDeviceInfosState> {
    // MARK: - Private Properties
    private let groundSdk = GroundSdk()
    private var userLocationManager: LocationManager

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - userLocationManager: provider for user location update callbacks
    ///    - batteryLevelDidChange: called when battery level changes
    ///    - gpsStrengthDidChange: called when gps strength changes
    init(userLocationManager: LocationManager,
         batteryLevelDidChange: ((BatteryValueModel) -> Void)? = nil,
         gpsStrengthDidChange: ((UserLocationGpsStrength) -> Void)? = nil) {
        self.userLocationManager = userLocationManager
        super.init()
        self.state.value.userDeviceBatteryLevel.valueChanged = batteryLevelDidChange
        self.state.value.userDeviceGpsStrength.valueChanged = gpsStrengthDidChange

        listenBatteryInfo()
        listenGpsInfos()
    }

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Private Funcs
private extension UserDeviceViewModel {
    /// Listener for user device battery.
    func listenBatteryInfo() {
        // Start observer for user device battery.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.updateBatteryLevel),
                                               name: UIDevice.batteryLevelDidChangeNotification,
                                               object: nil)
        // Need to call this function one time because user device battery will not change at the very moment.
        updateBatteryLevel()
    }

    /// Listener for user device Gps.
    func listenGpsInfos() {
        userLocationManager.onLocationUpdate = { [weak self] in
            guard let userLocation = self?.groundSdk.getFacility(Facilities.userLocation) else { return }

            self?.state.value.userDeviceGpsStrength.set(userLocation.gpsStrength)
        }
    }

    /// Update the battery value.
    @objc func updateBatteryLevel() {
        state.value.userDeviceBatteryLevel.set(UIDevice.current.batteryValueModel)
    }
}
