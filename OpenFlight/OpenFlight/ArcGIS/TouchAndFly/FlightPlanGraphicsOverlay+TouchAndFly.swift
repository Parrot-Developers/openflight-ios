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

import ArcGIS

/// Utility extension for `FlightPlanGraphicsOverlay` usage with Touch and Fly.
extension FlightPlanGraphicsOverlay {
    // MARK: - Internal Properties

    /// Returns Touch and Fly's waypoint graphic, if any.
    var touchAndFlyWayPointGraphic: FlightPlanWayPointGraphic? {
        return self.graphics
            .compactMap { $0 as? FlightPlanWayPointGraphic }
            .first(where: { $0.isTouchAndFlyPoint })
    }

    /// Returns Touch and Fly's drone to waypoint line, if any.
    var touchAndFlyWayPointLineGraphic: TouchAndFlyDroneToPointLineGraphic? {
        return self.graphics
            .compactMap { $0 as? TouchAndFlyDroneToPointLineGraphic }
            .first
    }

    /// Returns Touch and Fly's point of interest graphic, if any.
    var touchAndFlyPoiPointGraphic: FlightPlanPoiPointGraphic? {
        return self.graphics
            .compactMap { $0 as? FlightPlanPoiPointGraphic }
            .first(where: { $0.isTouchAndFlyPoint })
    }

    // MARK: - Internal Funcs
    /// Removes all graphics associated with Touch and Fly feature.
    func clearTouchAndFlyGraphics() {
        let touchAndFlyGraphics = self.graphics
            .compactMap { $0 as? AGSGraphic }
            .filter { $0.attributes[AGSConstants.touchAndFlyGraphicKey] as? Bool == true}
        self.graphics.removeObjects(in: touchAndFlyGraphics)
    }
}
