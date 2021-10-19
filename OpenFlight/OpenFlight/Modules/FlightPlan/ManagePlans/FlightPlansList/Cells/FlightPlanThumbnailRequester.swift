//
//  Copyright (C) 2021 Parrot Drones SAS.
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
import MapKit

class FlightPlanThumbnailRequester {

    func requestPlacemark(flightPlan: FlightPlanModel, completion: @escaping (CLPlacemark?) -> Void) {
        guard
            flightPlan.shouldRequestPlacemark,
            let location = flightPlan.dataSetting?.coordinate
            else {
                return
        }
        let center = CLLocation(latitude: location.latitude, longitude: location.longitude)
        CLGeocoder().reverseGeocodeLocation(center) { (placemarks: [CLPlacemark]?, error: Error?) in
            guard let place = placemarks?.first,
                  error == nil else { completion(nil) ; return }
            completion(place)
        }
    }

    func requestThumbnail(flightPlan: FlightPlanModel,
                          thumbnailSize: CGSize? = nil,
                          completion: @escaping (UIImage?) -> Void) {
        guard flightPlan.shouldRequestThumbnail,
              let center = flightPlan.dataSetting?.coordinate
            else {
                return
        }
        var polyline: MKPolyline?

        let mapSnapshotterOptions = MKMapSnapshotter.Options()
        if flightPlan.points.isEmpty {
            let region = MKCoordinateRegion(center: center,
                                            span: MKCoordinateSpan(latitudeDelta: FlightViewModelConstants.coordinateSpan,
                                                                   longitudeDelta: FlightViewModelConstants.coordinateSpan))
            mapSnapshotterOptions.region = region
        } else {
            let poly = MKPolyline(coordinates: flightPlan.points, count: flightPlan.points.count)
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
        DispatchQueue.global(qos: .background).async {
            snapShotter.start { (snapshot: MKMapSnapshotter.Snapshot?, _) in
                if let polyline = polyline {
                    completion(
                        snapshot?.drawPolyline(polyline,
                                               color: ColorName.blueDodger.color,
                                               lineWidth: FlightViewModelConstants.lineWidth)
                        )
                } else {
                    completion(snapshot?.image)
                }
            }
        }
    }
}
