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

import CoreGraphics

/// Utility extension for `CGRect`.

public extension CGRect {

    /// Returns center of the current CGRect.
    var center: CGPoint { return CGPoint(x: midX, y: midY) }

    /// Creates a CGRect with its center, width and height.
    ///
    /// - Parameters:
    ///    - center: the center of the rect
    ///    - width: the width of the rect
    ///    - height: the height of the rect
    init(center: CGPoint, width: CGFloat, height: CGFloat) {
        self.init(origin: CGPoint(x: center.x - width / 2, y: center.y - height / 2), size: CGSize(width: width, height: height))
    }

    /// Reduces rect using given scale.
    ///
    /// - Parameters:
    ///    - scale: the scale with which the rect needs to be reduced
    /// - Returns: a new CGRect with size and origin reduced by a given scale
    func reduce(by scale: CGFloat) -> CGRect {
        return CGRect(x: origin.x / scale, y: origin.y / scale, width: width / scale, height: height / scale)
    }

    /// Computes given point absolute coordinates from its relative position inside CGRect.
    ///
    /// - Parameters:
    ///    - relX: point X position inside CGRect (relative position, from left (0.0) to right (1.0))
    ///    - relY: point Y position inside CGRect (relative position, from top (0.0) to bottom (1.0))
    /// - Returns: given point absolute coordinates
    func pointAt(relX: CGFloat, relY: CGFloat) -> CGPoint {
        return CGPoint(x: origin.x + relX * width, y: origin.y + relY * height)
    }

    /// Computes given point relative position inside CGRect.
    ///
    /// - Parameters:
    ///    - point: the point absolute coordinates
    /// - Returns: the point relative coordinates, nil if the point is not inside CGRect
    func relativeCoordinates(for point: CGPoint) -> (CGFloat, CGFloat)? {
        guard contains(point) else {
            return nil
        }
        let computedX = (point.x - origin.x) / width
        let computedY = (point.y - origin.y) / height
        return (computedX, computedY)
    }
}
