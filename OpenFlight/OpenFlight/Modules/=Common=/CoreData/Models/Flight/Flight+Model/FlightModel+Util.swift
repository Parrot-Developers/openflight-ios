//
//  FlightModel+Util.swift
//  OpenFlight
//
//  Created by Pierre Mardon on 23/08/2021.
//  Copyright © 2021 Parrot Drones SAS. All rights reserved.
//

import Foundation
import CoreLocation
public extension FlightModel {

    var location: CLLocation {
        CLLocation(latitude: startLatitude, longitude: startLongitude)
    }
    var formattedDate: String? {
        startTime?.formattedString(dateStyle: .full, timeStyle: .medium)
    }
    var mediumFormattedDate: String? {
        startTime?.formattedString(dateStyle: .medium, timeStyle: .medium)
    }
    var shortFormattedDate: String? {
        startTime?.formattedString(dateStyle: .medium, timeStyle: .short)
    }
    var formattedDuration: String {
        duration.formattedHmsString ?? Style.dash
    }
    var longFormattedDuration: String {
        duration.longFormattedString
    }
    var shortFormattedDuration: String {
        duration.formattedString
    }
    var coordinateDescription: String {
        location.coordinate.coordinatesDescription
    }
    var batteryConsumptionPercents: String {
        Double(batteryConsumption).asPercent()
    }
    var formattedDistance: String {
        UnitHelper.stringDistanceWithDouble(distance)
    }
    var isLocationValid: Bool {
        location.coordinate.isValid
    }

    var formattedPosition: String {
        guard location.coordinate.isValid else {
            return L10n.dashboardMyFlightUnknownLocation
        }

        return location.coordinate.coordinatesDescription
    }

    var formattedPhotoCount: String {
        return photoCount > 0 ? "\(photoCount)" : Style.dash
    }

    var formattedVideoCount: String {
        return videoCount > 0 ? "\(videoCount)" : Style.dash
    }
}
