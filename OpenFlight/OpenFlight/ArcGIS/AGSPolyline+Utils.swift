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

import ArcGIS

/// Utility extension for `AGSPolyline`.

public extension AGSPolyline {
    // MARK: - Public Properties
    /// Returns middle point of the polyline, if any.
    var middlePoint: AGSPoint? {
        return pointAt(percent: Constants.middleFactor)
    }

    // MARK: - Private Enums
    private enum Constants {
        static let middleFactor: Double = 0.5
    }

    // MARK: - Public Funcs
    /// Returns a copy of the polyline with a new first point.
    ///
    /// - Parameters:
    ///    - point: new first point
    /// - Returns: new computed polyline
    func replacingFirstPoint(_ point: AGSPoint) -> AGSPolyline {
        // Init with all segments end points.
        var allPoints = self.parts.array()
            .flatMap { return $0.array() }
            .map { return $0.endPoint }
        // Add new start point.
        allPoints.insert(point, at: 0)

        return AGSPolyline(points: allPoints)
    }

    /// Returns a copy of the polyline with a new last point.
    ///
    /// - Parameters:
    ///    - point: new last point
    /// - Returns: new computed polyline
    func replacingLastPoint(_ point: AGSPoint) -> AGSPolyline {
        // Init with all segments start points.
        var allPoints = self.parts.array()
            .flatMap { return $0.array() }
            .map { return $0.startPoint }
        // Add new end point.
        allPoints.append(point)

        return AGSPolyline(points: allPoints)
    }

    /// Returns point at given percent of the polyline.
    ///
    /// - Parameters:
    ///    - percent: percent to apply
    /// - Returns: computed point
    func pointAt(percent: Double) -> AGSPoint? {
        return AGSGeometryEngine.point(along: self,
                                       distance: AGSGeometryEngine.length(of: self) * percent)
    }
}
