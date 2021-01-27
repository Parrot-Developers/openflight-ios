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

import SwiftyUserDefaults
import GroundSdk

/// Geofence state unsed in `GeofenceViewModel`.

final class GeofenceState: DeviceConnectionState {
    // MARK: - Internal Properties
    var isGeofenceActivated: Bool
    var altitude: Double {
        didSet {
            Defaults.maxAltitudeSetting = altitude
        }
    }
    var distance: Double
    /// Max altitude is not provided by the drone, it's a preset.
    var maxAltitude: Double {
        return GeofencePreset.maxAltitude
    }
    var maxDistance: Double
    var minAltitude: Double
    var minDistance: Double
    var isUpdating: Bool

    // MARK: - Init

    required init() {
        isGeofenceActivated = true
        altitude = Defaults.maxAltitudeSetting ?? GeofencePreset.defaultAltitude
        distance = GeofencePreset.defaultDistance
        maxDistance = GeofencePreset.maxDistance
        minAltitude = GeofencePreset.minAltitude
        minDistance = GeofencePreset.minDistance
        isUpdating = false
        super.init()
    }

    // MARK: - Override Funcs

    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? GeofenceState else {
            return false
        }
        return super.isEqual(to: other) &&
            self.isGeofenceActivated == other.isGeofenceActivated &&
            self.altitude == other.altitude &&
            self.distance == other.distance &&
            self.maxAltitude == other.maxAltitude &&
            self.maxDistance == other.maxDistance &&
            self.minAltitude == other.minAltitude &&
            self.minDistance == other.minDistance &&
            self.isUpdating == other.isUpdating
    }

    override func copy() -> GeofenceState {
        let copy = GeofenceState()
        copy.isGeofenceActivated = self.isGeofenceActivated
        copy.altitude = self.altitude
        copy.distance = self.distance
        copy.maxDistance = self.maxDistance
        copy.minAltitude = self.minAltitude
        copy.minDistance = self.minDistance
        copy.isUpdating = self.isUpdating
        return copy
    }
}

/// Geofence setting view model.

final class GeofenceViewModel: DroneWatcherViewModel<GeofenceState> {
    // MARK: - Private Properties
    private var geofenceRef: Ref<Geofence>?
    private var geofenceDistanceRef: Ref<Geofence>?

    // MARK: - Internal Properties
    var settingEntries: [SettingEntry] {
        let geofence = drone?.getPeripheral(Peripherals.geofence)
        return [SettingEntry(setting: GeofenceViewModel.geofenceModeModel(geofence: geofence),
                             title: L10n.settingsAdvancedCategoryGeofence,
                             itemLogKey: LogEvent.LogKeyAdvancedSettings.geofence),
                SettingEntry(setting: SettingsCellType.grid)]
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        listenGeofence(drone)
        listenDistanceGeofence(drone)
    }

    // MARK: - Internal Funcs
    /// Save geofence in drone.
    ///
    /// - Parameters:
    ///     - altitude: altitude to save
    ///     - distance: distance to save
    func saveGeofence(altitude: Double, distance: Double) {
        let geofence = drone?.getPeripheral(Peripherals.geofence)
        geofence?.maxAltitude.value = altitude
        geofence?.maxDistance.value = distance
    }

    /// Reset geofence settings to default.
    func resetSettings() {
        let geofence = drone?.getPeripheral(Peripherals.geofence)
        geofence?.maxAltitude.value = GeofencePreset.defaultAltitude
        geofence?.maxDistance.value = GeofencePreset.defaultDistance
        geofence?.mode.value = GeofencePreset.geofence
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
private extension GeofenceViewModel {
    /// Listen geofence.
    func listenGeofence(_ drone: Drone) {
        geofenceRef = drone.getPeripheral(Peripherals.geofence) { [weak self] geofence in
            if let altitude = geofence?.maxAltitude.value,
                let minAltitude = geofence?.maxAltitude.min,
                let minDistance = geofence?.maxDistance.min,
                let maxDistance = geofence?.maxDistance.max,
                let copy = self?.state.value.copy() {
                copy.isGeofenceActivated = geofence?.mode.value.isGeofenceActive ?? false
                if copy.isGeofenceActivated {
                    // Update only altitude. Distance must not be updated here.
                    copy.altitude = altitude
                }
                // Update min/max (change only first time).
                copy.maxDistance = maxDistance
                copy.minAltitude = minAltitude
                copy.minDistance = minDistance
                copy.isUpdating = geofence?.mode.updating ?? false
                self?.state.set(copy)
            }
        }
    }

    /// Listen geofence, dedicated to distance.
    func listenDistanceGeofence(_ drone: Drone) {
        geofenceDistanceRef = drone.getPeripheral(Peripherals.geofence) { [weak self] geofence in
            if let distance = geofence?.maxDistance.value {
                let copy = self?.state.value.copy()
                // Update only distance. Altitude must not be updated here.
                copy?.distance = distance
                self?.state.set(copy)
            }
        }
    }
}
