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

import UIKit
import MapKit

// MARK: - Internal Enums
enum FlightViewModelConstants {
    static let coordinateSpan: CLLocationDegrees = 0.005
    static let lineWidth: CGFloat = 5.0
    static let thumbnailMarginRatio: Double = 0.2
    static let thumbnailSize: CGSize = CGSize(width: 180.0, height: 160.0)
}

/// Cloud status enum.

enum CloudStatus: String {
    case offline
    case uploading
    case online
}

// MARK: - Protocols
/// Flight Plan and flight data common helpers.

protocol FlightViewModelProtocol: AnyObject {
    /// Flight location.
    var location: CLLocationCoordinate2D? { get }
    /// Flight points.
    var points: [CLLocationCoordinate2D] { get }
    /// Returns true if a thumbnail request is needed.
    var shouldRequestThumbnail: Bool { get }
    /// Performs a thumbnail request.
    func requestThumbnail(thumbnailSize: CGSize?)
    /// Updates thumbnail image.
    func updateThumbnail(_ image: UIImage?)
    /// Returns true if a placemark request is needed.
    var shouldRequestPlacemark: Bool { get }
    /// Request placemark regarding location.
    func requestPlacemark()
    /// Update placemark.
    func updatePlacemark(_ placemark: CLPlacemark?)
}

/// Flight Plan and flight state common helpers.

protocol FlightStateProtocol {
    var cloudStatus: String? { get set }
    var cloudStatusEnum: CloudStatus? { get set }
}

extension FlightViewModelProtocol {
    func requestPlacemark() {
        guard shouldRequestPlacemark,
            let location = location
            else {
                return
        }
        let center = CLLocation(latitude: location.latitude, longitude: location.longitude)
        CLGeocoder().reverseGeocodeLocation(center) { [weak self] (placemarks: [CLPlacemark]?, error: Error?) in
            guard let place = placemarks?.first,
                error == nil else { return }
            self?.updatePlacemark(place)
        }
    }

    func requestThumbnail(thumbnailSize: CGSize? = nil) {
        guard shouldRequestThumbnail,
            let center = location
            else {
                return
        }
        var polyline: MKPolyline?

        let mapSnapshotterOptions = MKMapSnapshotter.Options()
        if points.isEmpty {
            let region = MKCoordinateRegion(center: center,
                                            span: MKCoordinateSpan(latitudeDelta: FlightViewModelConstants.coordinateSpan,
                                                                   longitudeDelta: FlightViewModelConstants.coordinateSpan))
            mapSnapshotterOptions.region = region
        } else {
            let poly = MKPolyline(coordinates: points, count: points.count)
            polyline = poly
            var mapRect = poly.boundingMapRect
            let xOffset = mapRect.width * FlightViewModelConstants.thumbnailMarginRatio
            let yOffset = mapRect.height * FlightViewModelConstants.thumbnailMarginRatio
            mapRect = mapRect.insetBy(dx: -xOffset, dy: -yOffset)
            // Do not set x offet to add bottom margin to the screenshot.
            mapRect = mapRect.offsetBy(dx: 0.0, dy: yOffset)
            mapSnapshotterOptions.mapRect = mapRect
        }
        mapSnapshotterOptions.mapType = .satellite
        mapSnapshotterOptions.size = thumbnailSize ?? FlightViewModelConstants.thumbnailSize

        let snapShotter = MKMapSnapshotter(options: mapSnapshotterOptions)
        DispatchQueue.global(qos: .background).async { [weak self] in
            snapShotter.start { [weak self] (snapshot: MKMapSnapshotter.Snapshot?, _) in
                if let polyline = polyline {
                    self?.updateThumbnail(
                        snapshot?.drawPolyline(polyline,
                                               color: ColorName.blueDodger.color,
                                               lineWidth: FlightViewModelConstants.lineWidth)
                    )
                } else {
                    self?.updateThumbnail(snapshot?.image)
                }
            }
        }
    }
}

extension FlightStateProtocol {
    // Use string value (persisted) as enum.
    var cloudStatusEnum: CloudStatus? {
        get {
            guard let type = cloudStatus,
                let enumValue = CloudStatus(rawValue: type)
                else { return nil }
            return enumValue
        }
        set {
            cloudStatus = newValue?.rawValue ?? nil
        }
    }

    var icon: UIImage? {
        // TODO: to be completed
        switch self.cloudStatusEnum {
        case .offline:
            return Asset.MyFlights.cloudNotStored.image
        default:
            return nil
        }
    }
}
