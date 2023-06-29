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

private extension ULogTag {
    static let tag = ULogTag(name: "SettingsGeofenceViewModel")
}

/// Geofence setting view model.
open class SettingsGeofenceViewModel: SettingsViewModelProtocol {

    // MARK: - Observable properties
    private var isGeofenceActivatedSubject = CurrentValueSubject<Bool, Never>(GeofencePreset.geofenceMode.isGeofenceActive)
    public var isGeofenceActivatedPublisher: AnyPublisher<Bool, Never> {
        isGeofenceActivatedSubject.eraseToAnyPublisher()
    }

    private var minAltitudeSubject = CurrentValueSubject<Double, Never>(GeofencePreset.minAltitude)
    public var minAltitudePublisher: AnyPublisher<Double, Never> {
        minAltitudeSubject.eraseToAnyPublisher()
    }

    private var altitudeSubject = CurrentValueSubject<Double, Never>(Defaults.maxAltitudeSetting ?? GeofencePreset.defaultAltitude)
    public var altitudePublisher: AnyPublisher<Double, Never> {
        altitudeSubject.eraseToAnyPublisher()
    }

    private var minDistanceSubject = CurrentValueSubject<Double, Never>(GeofencePreset.defaultDistance)
    public var minDistancePublisher: AnyPublisher<Double, Never> {
        minDistanceSubject.eraseToAnyPublisher()
    }

    private var distanceSubject = CurrentValueSubject<Double, Never>(GeofencePreset.defaultDistance)
    public var distancePublisher: AnyPublisher<Double, Never> {
        distanceSubject.eraseToAnyPublisher()
    }

    private var maxDistanceSubject = CurrentValueSubject<Double, Never>(GeofencePreset.maxDistance)
    public var maxDistancePublisher: AnyPublisher<Double, Never> {
        maxDistanceSubject.eraseToAnyPublisher()
    }

    private var isUpdatingSubject = CurrentValueSubject<Bool, Never>(false)
    public var isUpdatingPublisher: AnyPublisher<Bool, Never> {
        isUpdatingSubject.eraseToAnyPublisher()
    }

    // MARK: - Open Properties
    /// Returns the setting entry for geoFence mode.
    open var geoFenceModeEntry: SettingEntry {
        return SettingEntry(setting: SettingsGeofenceViewModel.geofenceModeModel(geofence: geofence),
                            title: L10n.settingsAdvancedTitleGeofenceActivate,
                            itemLogKey: LogEvent.LogKeyAdvancedSettings.geofence)
    }

    /// Returns the setting entry for alitude slider.
    open var geoFenceAltitudeEntry: SettingEntry {
        let sliderSetting = SliderSetting(min: minAltitudeSubject.value, max: maxAltitude, value: altitudeSubject.value)
        return SettingEntry(setting: sliderSetting,
                            title: L10n.settingsAdvancedTitleGeofenceMaxAlt,
                            unit: UnitType.distance,
                            defaultValue: Float(altitudeSubject.value),
                            isEnabled: geofence?.mode.value.isGeofenceActive ?? GeofencePreset.geofenceMode.isGeofenceActive,
                            itemLogKey: LogEvent.LogKeyAdvancedSettings.geofenceAltitude.description,
                            settingStepperSlider: SettingStepperSlider(limitIntervalChange: Float(sliderSetting.min),
                                                                       leftIntervalStep: 1,
                                                                       rightIntervalStep: 1))
    }

    /// Returns the setting entry for distance slider.
    open var geoFenceDistanceEntry: SettingEntry {
        let sliderSetting = SliderSetting(min: minDistanceSubject.value, max: maxDistanceSubject.value, value: distanceSubject.value)
        return SettingEntry(setting: sliderSetting,
                            title: L10n.settingsAdvancedTitleGeofenceMaxDist,
                            unit: UnitType.distance,
                            defaultValue: Float(distanceSubject.value),
                            isEnabled: geofence?.mode.value.isGeofenceActive ?? GeofencePreset.geofenceMode.isGeofenceActive,
                            itemLogKey: LogEvent.LogKeyAdvancedSettings.geofenceDistance.description,
                            settingStepperSlider: SettingStepperSlider(limitIntervalChange: 1000.0,
                                                                       leftIntervalStep: 10,
                                                                       rightIntervalStep: 100))
    }

    open var settingEntries: [SettingEntry] {
        return [SettingEntry(setting: SettingsCellType.geoFence)]
    }
    open var infoHandler: ((SettingMode.Type) -> Void)?
    open var isUpdating: Bool? = false

    // MARK: - Private Properties
    /// Max altitude stays as a preset.
    private var maxAltitude: Double = GeofencePreset.maxAltitude
    private var currentDroneHolder: CurrentDroneHolder
    private var cancellables = Set<AnyCancellable>()
    private var geofence: Geofence?

    // MARK: - Ground SDK References
    private var geofenceRef: Ref<Geofence>?
    private var geofenceDistanceRef: Ref<Geofence>?

    public init(currentDroneHolder: CurrentDroneHolder) {
        self.currentDroneHolder = currentDroneHolder

        altitudePublisher
            .sink { altitude in
                Defaults.maxAltitudeSetting = altitude
            }
            .store(in: &cancellables)

        currentDroneHolder.dronePublisher
            .sink { [weak self] drone in
                guard let self = self else { return }
                self.listenGeofence(drone)
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
        geofenceRef = drone.getPeripheral(Peripherals.geofence) { [weak self] newGeofence in
            guard let self = self else { return }

            if let altitude = newGeofence?.maxAltitude.value,
               let minAltitude = newGeofence?.maxAltitude.min,
               let minDistance = newGeofence?.maxDistance.min,
               let maxDistance = newGeofence?.maxDistance.max {
                self.isGeofenceActivatedSubject.value = newGeofence?.mode.value.isGeofenceActive ?? GeofencePreset.geofenceMode.isGeofenceActive
                if self.isGeofenceActivatedSubject.value == true {
                    // Update only altitude. Distance must not be updated here.
                    self.altitudeSubject.value = altitude
                }
                // Update min/max (change only first time).
                self.maxDistanceSubject.value = maxDistance
                self.minAltitudeSubject.value = minAltitude
                self.minDistanceSubject.value = minDistance
                self.isUpdating = newGeofence?.mode.updating ?? false
            }
            if let distance = newGeofence?.maxDistance.value {
                // Update only distance. Altitude must not be updated here.
                self.distanceSubject.value = distance
            }
            self.isUpdatingSubject.value = self.isUpdating ?? false
            self.geofence = newGeofence

            ULog.i(.tag, "Did receive new geoFence attributes: isGeoFenceActive = \(self.isGeofenceActivatedSubject.value) | " +
                   "currentAlt = \(self.altitudeSubject.value) | currentDist = \(self.distanceSubject.value) | " +
                   "centerAltitude = \(self.geofence?.center?.altitude) | centerCoordinate \(self.geofence?.center?.coordinate)")
        }
    }
}
