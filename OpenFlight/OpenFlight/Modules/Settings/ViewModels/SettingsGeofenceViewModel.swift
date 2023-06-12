//    Copyright (C) 2020 Parrot Drones SAS
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

import SwiftyUserDefaults
import GroundSdk
import Combine

/// Geofence setting view model.
open class SettingsGeofenceViewModel: SettingsViewModelProtocol {
    // MARK: - Published Properties
    @Published private(set) var isGeofenceActivated: Bool = GeofencePreset.geofenceMode.isGeofenceActive
    @Published private(set) var altitude: Double = Defaults.maxAltitudeSetting ?? GeofencePreset.defaultAltitude
    @Published private(set) var distance: Double = GeofencePreset.defaultDistance
    @Published private(set) var minDistance: Double = GeofencePreset.defaultDistance
    @Published private(set) var maxDistance: Double = GeofencePreset.maxDistance
    @Published private(set) var minAltitude: Double = GeofencePreset.minAltitude
    /// Max altitude is not provided by the drone, it's a preset.
    @Published private(set) var maxAltitude: Double = GeofencePreset.maxAltitude

    // MARK: - Public Properties
    /// Returns the setting entry for geoFence mode.
    var geoFenceModeEntry: SettingEntry {
        return SettingEntry(setting: SettingsGeofenceViewModel.geofenceModeModel(geofence: geofence),
                            title: L10n.settingsAdvancedTitleGeofenceActivate,
                            itemLogKey: LogEvent.LogKeyAdvancedSettings.geofence)
    }

    /// Returns the setting entry for alitude slider.
    var geoFenceAltitudeEntry: SettingEntry {
        let sliderSetting = SliderSetting(min: minAltitude, max: maxAltitude, value: altitude)
        return SettingEntry(setting: sliderSetting,
                            title: L10n.settingsAdvancedTitleGeofenceMaxAlt,
                            unit: UnitType.distance,
                            defaultValue: Float(altitude),
                            isEnabled: geofence?.mode.value.isGeofenceActive ?? GeofencePreset.geofenceMode.isGeofenceActive,
                            itemLogKey: LogEvent.LogKeyAdvancedSettings.geofenceAltitude.description,
                            settingStepperSlider: SettingStepperSlider(limitIntervalChange: Float(sliderSetting.min),
                                                                       leftIntervalStep: 1,
                                                                       rightIntervalStep: 1))
    }

    /// Returns the setting entry for distance slider.
    var geoFenceDistanceEntry: SettingEntry {
        let sliderSetting = SliderSetting(min: minDistance, max: maxDistance, value: distance)
        return SettingEntry(setting: sliderSetting,
                            title: L10n.settingsAdvancedTitleGeofenceMaxDist,
                            unit: UnitType.distance,
                            defaultValue: Float(distance),
                            isEnabled: geofence?.mode.value.isGeofenceActive ?? GeofencePreset.geofenceMode.isGeofenceActive,
                            itemLogKey: LogEvent.LogKeyAdvancedSettings.geofenceDistance.description,
                            settingStepperSlider: SettingStepperSlider(limitIntervalChange: Float(sliderSetting.min),
                                                                       leftIntervalStep: 1,
                                                                       rightIntervalStep: 1))
    }

    open var settingEntries: [SettingEntry] {
        return [SettingEntry(setting: SettingsCellType.geoFence)]
    }
    open var infoHandler: ((SettingMode.Type) -> Void)?
    open var isUpdating: Bool? = false

    // MARK: - Private Properties
    private(set) var notifyChangePublisher = CurrentValueSubject<Void, Never>(())
    private var currentDroneHolder: CurrentDroneHolder
    private var cancellables = Set<AnyCancellable>()
    private var geofence: Geofence?

    // MARK: - Ground SDK References
    private var geofenceRef: Ref<Geofence>?
    private var geofenceDistanceRef: Ref<Geofence>?

    public init(currentDroneHolder: CurrentDroneHolder) {
        self.currentDroneHolder = currentDroneHolder

        $altitude
            .sink { altitude in
                Defaults.maxAltitudeSetting = altitude
            }
            .store(in: &cancellables)

        currentDroneHolder.dronePublisher
            .sink { [weak self] drone in
                guard let self = self else { return }
                self.listenGeofence(drone)
                self.listenDistanceGeofence(drone)
            }
            .store(in: &cancellables)
    }

    // MARK: - Internal Funcs
    /// Save geofence altitude value in drone.
    ///
    /// - Parameters:
    ///     - altitude: altitude to save
    func saveGeofenceAltitude(_ altitude: Double) {
        guard let geofence = geofence else { return }
        geofence.maxAltitude.value = altitude
    }

    /// Save geofence distance value in drone.
    ///
    /// - Parameters:
    ///     - distance: distance to save
    func saveGeofenceDistance(_ distance: Double) {
        guard let geofence = geofence else { return }
        geofence.maxDistance.value = distance
    }

    /// Reset geofence settings to default.
    open func resetSettings() {
        guard let geofence = geofence else { return }
        geofence.maxAltitude.value = GeofencePreset.defaultAltitude
        geofence.maxDistance.value = GeofencePreset.defaultDistance
        geofence.mode.value = GeofencePreset.geofenceMode
        Defaults.maxAltitudeSetting = GeofencePreset.defaultAltitude
    }

    /// Geofence is a special case because this settings is displayed as boolean.
    static func geofenceModeModel(geofence: Geofence?) -> DroneSettingModel? {
        guard let currentGeofenceMode = geofence?.mode else {
            return nil
        }

        return DroneSettingModel(allValues: GeofenceMode.allValues,
                                 supportedValues: GeofenceMode.allValues,
                                 currentValue: currentGeofenceMode.value,
                                 isUpdating: currentGeofenceMode.updating) { [weak geofence] mode in
                                    // Altitude value is set to max when there is no geofence (mode == .altitude).
                                    if let mode = mode as? GeofenceMode {
                                        switch mode {
                                        case .altitude:
                                            // Set mode, then altitude value.
                                            geofence?.mode.value = .altitude
                                            Defaults.maxAltitudeSetting = geofence?.maxAltitude.value
                                            // Set drone's maxAltitude.max to max altitude
                                            geofence?.maxAltitude.value = geofence?.maxAltitude.max ?? GeofencePreset.maxAltitude
                                        case .cylinder:
                                            // Set altitude value, then mode.
                                            geofence?.maxAltitude.value = Defaults.maxAltitudeSetting ?? GeofencePreset.maxAltitude
                                            geofence?.mode.value = .cylinder
                                        }
                                    }
        }
    }
}

// MARK: - Private Funcs
private extension SettingsGeofenceViewModel {
    /// Listen geofence.
    func listenGeofence(_ drone: Drone) {
        geofenceRef = drone.getPeripheral(Peripherals.geofence) { [unowned self] geofence in
            if let altitude = geofence?.maxAltitude.value,
               let minAltitude = geofence?.maxAltitude.min,
               let minDistance = geofence?.maxDistance.min,
               let maxDistance = geofence?.maxDistance.max {
                isGeofenceActivated = geofence?.mode.value.isGeofenceActive ?? GeofencePreset.geofenceMode.isGeofenceActive
                if isGeofenceActivated {
                    // Update only altitude. Distance must not be updated here.
                    self.altitude = altitude
                }
                // Update min/max (change only first time).
                self.maxDistance = maxDistance
                self.minAltitude = minAltitude
                self.minDistance = minDistance
                isUpdating = geofence?.mode.updating ?? false
            }
            self.geofence = geofence
            notifyChangePublisher.send()
        }
    }

    /// Listen geofence, dedicated to distance.
    func listenDistanceGeofence(_ drone: Drone) {
        geofenceDistanceRef = drone.getPeripheral(Peripherals.geofence) { [unowned self] geofence in
            if let distance = geofence?.maxDistance.value {
                // Update only distance. Altitude must not be updated here.
                self.distance = distance
                notifyChangePublisher.send()
            }
        }
    }
}
