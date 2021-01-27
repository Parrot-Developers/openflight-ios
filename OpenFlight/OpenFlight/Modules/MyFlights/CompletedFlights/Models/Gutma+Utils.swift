// Copyright (C) 2020 Parrot Drones SAS
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
import CoreLocation
import ArcGIS

// MARK: - Internal Enums
enum GutmaConstants {
    static let dateFormatLogging: String = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
    static let dateFormatFile: String = "yyyy-MM-dd'T'HH:mm:ssZ"
    static let extensionName: String = "gutma"
}

// MARK: - Gutma helpers.

extension Gutma {
    var flightLocation: CLLocation? {
        // Last position is used here to get the most accurate value.
        return self.exchange?.message?.flightLogging?.finalPosition
    }

    var startDate: Date? {
        if let dateString = self.exchange?.message?.flightLogging?.loggingStartDtg {
            let formatter = DateFormatter()
            formatter.dateFormat = GutmaConstants.dateFormatFile
            return formatter.date(from: dateString)
        }
        return nil
    }

    var duration: TimeInterval {
        return self.exchange?.message?.flightLogging?.duration ?? 0.0
    }

    var flightId: String? {
        return self.exchange?.message?.flightData?.flightID
    }

    var batteryConsumption: String {
        return self.exchange?.message?.flightLogging?.batteryConsumption?.asPercent() ?? Style.dash
    }

    var distance: Double {
        return self.exchange?.message?.flightLogging?.distance ?? 0.0
    }

    var file: File? {
        return self.exchange?.message?.file
    }

    var points: [AGSPoint] {
        return self.exchange?.message?.flightLogging?.points ?? []
    }

    /// Returns Data object from a Gutma.
    public func asData() -> Data? {
        return try? JSONEncoder().encode(self)
    }
}

// MARK: - Data helper dedicated to Gutma.

extension Data {
    /// Returns Gutma object from JSON data.
    func asGutma() -> Gutma? {
        do {
            return try JSONDecoder().decode(Gutma.self, from: self)
        } catch {
            // Hack for Gutma encoding issue.
            if let data = String(data: self, encoding: String.Encoding.ascii)?
                .data(using: String.Encoding.utf8) {
                return try? JSONDecoder().decode(Gutma.self, from: data)
            }
        }
        return nil
    }
}

// MARK: - FlightLogging helpers.

extension FlightLogging {
    /// Start flight date.
    var startDate: Date? {
        if let dateString = self.loggingStartDtg {
            let formatter = DateFormatter()
            formatter.dateFormat = GutmaConstants.dateFormatLogging
            return formatter.date(from: dateString)
        }
        return nil
    }

    /// Flight duration.
    var duration: TimeInterval? {
        if let first = self.item(for: .timestamp, atIndex: 0),
            let last = self.item(for: .timestamp, atIndex: (self.flightLoggingItems?.count ?? 0) - 1) {
            return last - first
        }
        return nil
    }

    /// Flight battery consumption.
    var batteryConsumption: Double? {
        var initialBatteryValue: Double = 1.0
        let itemCount = self.flightLoggingItems?.count ?? 0
        // Find real battery value (0 is not a real one for a initial value).
        for index in 0...itemCount {
            if let value = self.item(for: .batteryCurrent, atIndex: index), value > 0.0 {
                initialBatteryValue = value
                break
            }
        }
        let finalBatteryValue = self.item(for: .batteryCurrent, atIndex: itemCount - 1) ?? 0.0
        if let batteryCapacity = self.item(for: .batteryCapacity, atIndex: itemCount - 1),
            batteryCapacity > 0.0 {
            return ((initialBatteryValue - finalBatteryValue) / batteryCapacity) * Values.oneHundred
        } else {
            return nil
        }
    }

    /// Returns final position.
    var finalPosition: CLLocation? {
        let itemCount = self.flightLoggingItems?.count ?? 0
        if let location = location(at: itemCount - 1) {
            return CLLocation(latitude: location.latitude, longitude: location.longitude)
        } else {
            return nil
        }
    }

    /// Returns all points as AGSPoint.
    var points: [AGSPoint] {
        return self.flightLoggingItems?.enumerated().compactMap({ (offset, _) -> AGSPoint? in
            guard let location = location(at: offset) else {
                return nil
            }

            return AGSPoint(x: location.longitude,
                            y: location.latitude,
                            spatialReference: AGSSpatialReference.wgs84())
        }) ?? []
    }

    /// Add distance between all points.
    var distance: Double {
        var computedDistance: Double = 0.0
        guard let nbItems = self.flightLoggingItems?.count
            else { return computedDistance }

        var previousLocation: CLLocation?
        for index in 0...nbItems {
            if let loc = location(at: index) {
                let location = CLLocation(latitude: loc.latitude, longitude: loc.longitude)
                if let previousLocation = previousLocation {
                    computedDistance += location.distance(from: previousLocation)
                }
                previousLocation = location
            }
        }
        return computedDistance
    }
}

// MARK: - Private helpers
private extension FlightLogging {
    /// Return location regarding FlightLogging index
    ///
    /// - Parameters:
    ///     - index: FlightLogging index
    /// - Returns: location as CLLocationCoordinate2D?
    func location(at index: Int) -> CLLocationCoordinate2D? {
        let longitude = self.item(for: .longitude, atIndex: index) ?? 0.0
        let latitude = self.item(for: .latitude, atIndex: index) ?? 0.0
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        return coordinate.isValid ? coordinate : nil
    }

    /// Logging keys.
    enum LoggingKeys: String, CaseIterable {
        case timestamp = "timestamp"
        case longitude = "gps_lon"
        case latitude = "gps_lat"
        case altitude = "gps_altitude"
        case speedVx = "speed_vx"
        case speedVy = "speed_vy"
        case batteryVoltage = "battery_voltage"
        case batteryCurrent = "battery_current"
        case batteryCapacity = "battery_capacity"
    }

    /// Returns flightLoggingItems regarding flightLoggingKeys.
    ///
    /// - Parameters:
    ///     - key: flightLoggingKeys
    ///     - atIndex: flightLoggingItems index
    func item(for key: LoggingKeys, atIndex: Int) -> Double? {
        if let items = self.flightLoggingItems,
            atIndex >= 0,
            items.count > atIndex,
            let valueIndex = self.index(for: key.rawValue),
            items[atIndex].count == LoggingKeys.allCases.count {
            let item = items[atIndex]
            return item[valueIndex]
        }
        return nil
    }

    /// Returns flightLoggingKeys index.
    func index(for key: String) -> Int? {
        return self.flightLoggingKeys?.firstIndex(of: key)
    }
}
