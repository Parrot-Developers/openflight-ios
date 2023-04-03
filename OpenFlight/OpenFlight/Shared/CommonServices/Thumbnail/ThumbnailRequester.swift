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
import Pictor

public class ThumbnailRequester {

    public init() {}

    private typealias BoundedTrajectory = (MKMapRect, MKPolyline)

    private enum Constants {
        static let coordinateSpan: CLLocationDegrees = 0.005
        static let lineWidth: CGFloat = 3.5
        static let thumbnailMarginRatio: Double = 0.4
        static let thumbnailSize: CGSize = CGSize(width: 180.0, height: 160.0)
        static let thumbnailSizeWithTrajectory: CGSize = CGSize(width: 350.0, height: 100.0)
    }

    /// Creates user a thumbnail using the flightplan and an optional size.
    ///
    /// - Parameters:
    ///   - flightPlan: contains the plan UUID and points
    ///   - thumbnailSize: a custom CGSize that supercedes the standard thumbnail size - the latter used if nil is passed in
    ///   - completion: obtains a thumbnail UIImage if success
    public func requestThumbnail(center: CLLocationCoordinate2D,
                                 points: [CLLocationCoordinate2D] = [],
                                 completion: @escaping (UIImage?) -> Void) {
        var polyline: MKPolyline?

        var mapSnapshotterOptions: MKMapSnapshotter.Options
        if let boundedTrajectory = makeBoundedTrajectory(points: points) {
            mapSnapshotterOptions = prepareMapSnapshotterOptions(size: Constants.thumbnailSizeWithTrajectory)
            mapSnapshotterOptions.mapRect = boundedTrajectory.0
            polyline = boundedTrajectory.1
        } else {
            mapSnapshotterOptions = prepareMapSnapshotterOptions(size: Constants.thumbnailSize)
            let span = MKCoordinateSpan(latitudeDelta: Constants.coordinateSpan,
                                        longitudeDelta: Constants.coordinateSpan)
            let region = MKCoordinateRegion(center: center,
                                            span: span)
            mapSnapshotterOptions.region = region
        }

        let snapShotter = MKMapSnapshotter(options: mapSnapshotterOptions)

        DispatchQueue.global(qos: .userInteractive).async {
            snapShotter.start { (snapshot: MKMapSnapshotter.Snapshot?, _) in
                self.generateThumbnail(from: snapshot, with: polyline, completion: completion)
            }
        }
    }

    private func prepareMapSnapshotterOptions(size: CGSize) -> MKMapSnapshotter.Options {
        let options = MKMapSnapshotter.Options()
        options.mapType = .satellite
        options.size = size
        return options
    }

    private func makeBoundedTrajectory(points: [CLLocationCoordinate2D]) -> BoundedTrajectory? {
        guard !points.isEmpty else {
            return nil
        }
        let poly = MKPolyline(coordinates: points, count: points.count)
        var mapRect = poly.boundingMapRect
        let thumbnailMarginRatioConstant = Constants.thumbnailMarginRatio
        let offset = max(mapRect.width, mapRect.height) * thumbnailMarginRatioConstant
        // Inset map rect in order to add inner padding.
        mapRect = mapRect.insetBy(dx: -offset, dy: -offset)
        // Add extra bottom padding in order to keep some space below trajectory for FP details display.
        mapRect = mapRect.offsetBy(dx: 0, dy: offset / 2)

        return (mapRect, poly)
    }

    private func generateThumbnail(from snapshot: MKMapSnapshotter.Snapshot?,
                                   with polyline: MKPolyline?,
                                   completion: (UIImage?) -> Void) {
        guard let snapshot = snapshot else {
            completion(nil)
            return
        }
        let image: UIImage
        if let polyline = polyline {
            image = snapshot.drawPolyline(polyline,
                                          color: ColorName.blueDodger.color,
                                          lineWidth: Constants.lineWidth)
        } else {
            image = snapshot.image
        }
        completion(image)
    }
}
