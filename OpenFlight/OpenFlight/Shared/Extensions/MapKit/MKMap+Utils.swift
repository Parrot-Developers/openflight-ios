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

import MapKit

/// Utility extension for `MKMapSnapshotter.Snapshot`.

extension MKMapSnapshotter.Snapshot {
    /// Return snapshot's image with polyline drawn on it.
    ///
    /// - Parameters:
    ///     - polyline: the polyline
    ///     - color: line color
    ///     - lineWidth: lineWidth
    func drawPolyline(_ polyline: MKPolyline, color: UIColor, lineWidth: CGFloat) -> UIImage {
        let image = self.image
        let bounds = CGRect(origin: CGPoint(),
                                  size: image.size)
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { context in
            let cgContext = context.cgContext
            // Draw initial map image.
            image.draw(in: bounds)
            // Turn MKMapPoint into CGPoints.
            var pointsToDraw = UnsafeBufferPointer(start: polyline.points(), count: polyline.pointCount)
                .map { self.point(for: $0.coordinate) }

            // Draw lines.
            cgContext.setLineWidth(lineWidth)

            let firstPoint = pointsToDraw.removeFirst()
            cgContext.move(to: firstPoint)
            pointsToDraw.forEach { cgContext.addLine(to: $0) }

            cgContext.setStrokeColor(color.cgColor)
            cgContext.strokePath()
        }
    }
}
