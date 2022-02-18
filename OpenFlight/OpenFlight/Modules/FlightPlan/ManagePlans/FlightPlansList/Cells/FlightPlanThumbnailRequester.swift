//    Copyright (C) 2021 Parrot Drones SAS
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
import SdkCore

private extension ULogTag {
    static let tag = ULogTag(name: "FPThumbnailRequester")
}

enum FlightPlanThumbnailRequesterConstants {
    static let coordinateSpan: CLLocationDegrees = 0.005
    static let lineWidth: CGFloat = 5.0
    static let thumbnailMarginRatio: Double = 0.2
    static let thumbnailSize: CGSize = CGSize(width: 180.0, height: 160.0)
}

public class FlightPlanThumbnailRequester {

    public init() {}

    public func requestThumbnail(flightPlan: FlightPlanModel,
                                 thumbnailSize: CGSize? = nil,
                                 completion: @escaping (UIImage?) -> Void) {
        guard let center = flightPlan.dataSetting?.coordinate else {
                ULog.d(.tag, "Clearing thumbnail of flightPlan '\(flightPlan.uuid)'. No coordinate available.")
                completion(nil) // clear thumbnail
                return
        }
        var polyline: MKPolyline?

        let mapSnapshotterOptions = MKMapSnapshotter.Options()
        if flightPlan.points.isEmpty {
            let region = MKCoordinateRegion(center: center,
                                            span: MKCoordinateSpan(latitudeDelta: FlightPlanThumbnailRequesterConstants.coordinateSpan,
                                                                   longitudeDelta: FlightPlanThumbnailRequesterConstants.coordinateSpan))
            mapSnapshotterOptions.region = region
        } else {
            let poly = MKPolyline(coordinates: flightPlan.points, count: flightPlan.points.count)
            polyline = poly
            var mapRect = poly.boundingMapRect
            let xOffset = mapRect.width * FlightPlanThumbnailRequesterConstants.thumbnailMarginRatio
            let yOffset = mapRect.height * FlightPlanThumbnailRequesterConstants.thumbnailMarginRatio
            mapRect = mapRect.insetBy(dx: -xOffset, dy: -yOffset)
            // Do not set x offet to add bottom margin to the screenshot.
            mapRect = mapRect.offsetBy(dx: 0.0, dy: yOffset)
            mapSnapshotterOptions.mapRect = mapRect
        }
        mapSnapshotterOptions.mapType = .satellite
        mapSnapshotterOptions.size = thumbnailSize ?? FlightPlanThumbnailRequesterConstants.thumbnailSize

        let snapShotter = MKMapSnapshotter(options: mapSnapshotterOptions)
        DispatchQueue.global(qos: .userInteractive).async {
            snapShotter.start { (snapshot: MKMapSnapshotter.Snapshot?, _) in
                guard let snapshot = snapshot else { return completion(nil) }
                let image: UIImage
                if let polyline = polyline {
                    image = snapshot.drawPolyline(polyline,
                                                  color: ColorName.blueDodger.color,
                                                  lineWidth: FlightPlanThumbnailRequesterConstants.lineWidth)
                } else {
                    image = snapshot.image
                }
                ULog.d(.tag, "Generated thumbnail of flightPlan '\(flightPlan.uuid)'")
                completion(image)
            }
        }
    }
}
