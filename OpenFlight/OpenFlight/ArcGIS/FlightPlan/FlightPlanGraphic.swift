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

import ArcGIS

/// Base class for Flight Plan graphical items.
open class FlightPlanGraphic: EditableAGSGraphic {
    // MARK: - Public Properties
    /// Type of graphical item.
    var itemType: FlightPlanGraphicItemType {
        return .none
    }

    var graphicIsSelected = false {
        didSet {
            updateColors(isSelected: graphicIsSelected)
        }
    }

    // MARK: - Override Properties
    public override var isSelected: Bool {
        didSet {
            updateColors(isSelected: isSelected)
        }
    }

    // MARK: - Public Funcs
    /// Updates the graphical item colors.
    ///
    /// - Parameters:
    ///    - isSelected: whether item is selected
    func updateColors(isSelected: Bool) {
        /// Implement in children.
    }
}

// MARK: - Comparable
extension FlightPlanGraphic: Comparable {
    static public func < (lhs: FlightPlanGraphic, rhs: FlightPlanGraphic) -> Bool {
        return lhs.itemType.rawValue < rhs.itemType.rawValue
    }
}

/// The Flight Plan Graphics Generation Result.
///
/// - Description: Structure containing the generation status and generated graphics array.
public struct FlightPlanGraphicsGenerationResult {

    /// The result status enum.
    public enum Status {
        /// Unable the generate graphics (e.g. due to critical memory pressure).
        case failed
        /// Only some graphics have been generated (e.g. only the trajectory lines).
        /// `FlightPlanGraphicsMode` parameter describes succeeded graphics generated.
        case partially(FlightPlanGraphicsMode)
        /// Some Pois are missing (low memory issue occured during the POI genetation).
        case incompletePois
        /// All needed graphics have been generated.
        case succeeded
    }

    /// The result status.
    let status: Status
    /// The generated graphics.
    let graphics: [FlightPlanGraphic]

    /// Constructor.
    ///
    /// - Parameters:
    ///    - status: the result status
    ///    - graphics: the generated graphics
    public init(status: Status, graphics: [FlightPlanGraphic]) {
        self.status = status
        self.graphics = graphics
    }

    /// Constructor for partial generation.
    ///
    /// - Parameters:
    ///    - mode: the succeeded generated graphics mode
    ///    - graphics: the partially generated graphics
    public init(partially mode: FlightPlanGraphicsMode, graphics: [FlightPlanGraphic]) {
        self.status = .partially(mode)
        self.graphics = graphics.filtered(for: mode)
    }

    /// Constructor for succeeded generation.
    ///
    /// - Parameter graphics: the generated graphics
    public init(succeeded graphics: [FlightPlanGraphic]) {
        self.status = .succeeded
        self.graphics = graphics
    }

    /// A succeeded empty result.
    static let empty = FlightPlanGraphicsGenerationResult(status: .succeeded, graphics: [])

    /// A failed result.
    static let failed = FlightPlanGraphicsGenerationResult(status: .failed, graphics: [])
}

/// The Flight Plan Graphics Mode.
///
///    • `onlyTrajectory`: only the trajectory  lines are shown.
///    • `trajectoryAndArrows`: the trajectory  lines and direction arrows are shown.
///    • `whithoutArrows`: all graphics are shown except the direction arrows.
///    • `complete`: all graphics are shown (way poins, pois...).
public enum FlightPlanGraphicsMode {
    case onlyTrajectory
    case trajectoryAndArrows
    case whithoutArrows
    case complete

    /// Whether the mode includes direction arrows.
    var isArrowIncluded: Bool {
        self == .trajectoryAndArrows
        || self == .complete
    }

    /// Whether the mode includes WP markers.
    var isWayPointMarkersIncluded: Bool {
        self == .whithoutArrows
        || self == .complete
    }

    /// Whether the mode includes POI markers.
    var isPoiMarkersIncluded: Bool {
        self == .complete
    }
}

// MARK: - Graphics Array Helpers
public extension Array where Element == FlightPlanGraphic {
    /// Returns the filtered graphics according passed mode.
    ///
    /// - Parameter mode: the flight plan graphics mode used for filtering
    func filtered(for mode: FlightPlanGraphicsMode) -> Self {
        switch mode {
        case .onlyTrajectory:
            return filter { $0 is FlightPlanWayPointLineGraphic }
        case .trajectoryAndArrows:
            return filter {
                $0 is FlightPlanWayPointLineGraphic
                || $0 is FlightPlanWayPointArrowGraphic
            }
        case .whithoutArrows:
            return filter { !($0 is FlightPlanWayPointArrowGraphic) }
        case .complete:
            return self
        }
    }
}

// MARK: - Flight Plan Helpers
extension FlightPlanModel {
    /// Private Constants.
    private enum Constants {
        /// Maximum number of waypoints to display the markers on the map.
        static let wayPointMarkersMaxCount = 40_000
        /// Maximum number of waypoints to display the direction arrows on the map.
        static let directionArrowsMaxCount = 20_000
    }

    /// The default graphics mode.
    /// To prevent high memory consumption and bad lisibility,
    /// some graphics are not shown depending on the number of waypoints.
    var defaultGraphicsMode: FlightPlanGraphicsMode {
        // No restriction needed for unkown number of way points.
        guard let wayPointCount = dataSetting?.wayPoints.count
        else { return .complete }

        switch wayPointCount {
        case Constants.wayPointMarkersMaxCount...:
            return .onlyTrajectory
        case Constants.directionArrowsMaxCount...:
            return .trajectoryAndArrows
        default:
            return .complete
        }
    }
}
