//    Copyright (C) 2022 Parrot Drones SAS
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
import GroundSdk
import Combine
import ArcGIS

private extension ULogTag {
    static let tag = ULogTag(name: "ReturnHomeGraphicsOverlay")
}

/// Return home overlay.
public final class ReturnHomeGraphicsOverlay: CommonGraphicsOverlay {

    static let Key = "ReturnHomeGraphicsOverlayKey"

    // MARK: - Private Enums
    private enum Constants {
        static let defaultColor: UIColor = ColorName.blueDodger.color
        static let lineWidth: CGFloat = 2.0
        static let nearRthAltitude = 5.0
        static let deltaDistance = 3.0
    }

    /// Trajectory steps
    ///
    /// During a RTH, the drone
    ///  1. reaches the RTH altitude,
    ///  2. moves horizontaly towards home,
    ///  3. moves to home.
    fileprivate enum TrajectoryStep {
        case firstStep
        case secondStep
        case thirdStep
    }

    // MARK: - Private Properties
    /// Graphic for the polyline of the drone trajectory.
    private var droneToPointLineGraphic: AGSGraphic?
    /// RTH altitude.
    ///
    /// The drone is expected to reach that altitude before returning to home.
    private var rthAltitude: Double = 0.0
    /// Home distance.
    private var homeDistance: CLLocationDistance = 0.0
    /// Absolute drone altitude minus its relative altitude.
    private var baseAbsoluteAltitude: Double = 0.0
    /// Drone location when the RTH starts.
    private var initialLocation: CLLocationCoordinate2D?
    /// Current step of the RTH.
    private var currentStep: TrajectoryStep = .firstStep

    // MARK: - Public Properties
    public var viewModel = ReturnHomeGraphicsOverlayViewModel()

    // MARK: - Override
    override public init() {
        super.init()
        viewModel.$isActive
            .removeDuplicates()
            .sink { [weak self] isActive in
                guard let self = self else { return }
                if isActive {
                    guard let homeLocation = self.viewModel.homeLocation,
                          let droneLocation = self.viewModel.droneLocation.coordinates
                    else { return }
                    self.startRth(droneLocation: droneLocation, homeLocation: homeLocation, minAltitude: self.viewModel.minAltitude)
                }
                self.isActive.value = isActive
            }
            .store(in: &cancellables)

        viewModel.droneLocationPublisher
            .combineLatest(viewModel.$homeLocation)
            .sink { [weak self] droneLocation, homeLocation in
                guard let self = self, let homeLocation = homeLocation, let droneLocation = droneLocation.coordinates else { return }
                if self.isActive.value {
                    self.update(homeLocation: homeLocation, droneLocation: droneLocation)
                }
            }.store(in: &cancellables)
    }

    /// Start return home
    ///
    /// - Parameters:
    ///   - droneLocation: the drone location
    ///   - homeLocation: the home location (take off point or pilot)
    ///   - minAltitude: the minimal altitude (current RTH setting)
    func startRth(droneLocation: Location3D, homeLocation: Location3D, minAltitude: Double) {
        initialLocation = droneLocation.coordinate
        let initialDistance = homeLocation.coordinate.distance(from: droneLocation.coordinate)
        // Store the base absolute altitude
        baseAbsoluteAltitude = (viewModel.droneAbsoluteLocation.coordinates?.altitude ?? 0.0) - (viewModel.droneLocation.coordinates?.altitude ?? 0.0)

        // Compute the reference RTH altitude that will be used for the drone trajectory.
        // If initial distance is more than 100m, use the RTH altitude setting.
        // Between 10 and 100m, use distance/2 if it is below the RTH altitude setting.
        // If the drone is closer than 10m, use 5m.
        switch initialDistance {
        case 100...:
            rthAltitude = minAltitude
        case 10..<100:
            rthAltitude = min(minAltitude, initialDistance/2.0)
        default:
            rthAltitude = Constants.nearRthAltitude
        }
        // If the drone is higher than the computed altitude,
        // it will move horizontally at the same altitude to the home location.
        rthAltitude = max(rthAltitude, droneLocation.altitude)
        currentStep = .firstStep
        ULog.d(.tag, "Starting RTH."
               + " Initial location: (lat: \(droneLocation.coordinate.latitude), long: \(droneLocation.coordinate.longitude) alt:\(droneLocation.altitude)"
               + ", Home location: (lat: \(homeLocation.coordinate.latitude), long: \(homeLocation.coordinate.longitude), alt: \(homeLocation.altitude)"
               + ", Initial distance: \(initialDistance)"
               + ", Base altitude: \(baseAbsoluteAltitude)"
               + ", Altitude settings: \(minAltitude)"
               + ", RTH altitude: \(rthAltitude)")
    }

    /// Updates the graphics or the RTH overlay.
    ///
    /// - Parameters:
    ///    - homeLocation: the home location (take off point or pilot)
    ///    - droneLocation: location of the drone
    func update(homeLocation: Location3D, droneLocation: Location3D) {
        // Update drone to home line.
        // In 3D, the line is made of 2 or 3 segments.
        // The drone moves vertically to the RTH altitude, then horizontally to home,
        // then down to hovering or landing.
        homeDistance = homeLocation.coordinate.distance(from: droneLocation.coordinate)
        processStep(homeLocation: homeLocation, droneLocation: droneLocation)
    }
}

private extension ReturnHomeGraphicsOverlay {
    /// Processes the display of RTH segments.
    ///
    /// - Parameters:
    ///    - homeLocation: the home location (take off point or pilot)
    ///    - droneLocation: location of the drone
    func processStep(homeLocation: Location3D, droneLocation: Location3D) {
        switch currentStep {
        case .firstStep:
            currentStep = processFirstStep(homeLocation: homeLocation, droneLocation: droneLocation)
        case .secondStep:
            currentStep = processSecondStep(homeLocation: homeLocation, droneLocation: droneLocation)
        case .thirdStep:
            currentStep = processThirdStep(homeLocation: homeLocation, droneLocation: droneLocation)
        }
    }

    /// Processes the display during the first step of the RTH.
    ///
    /// - Parameters:
    ///    - homeLocation: the home location (take off point or pilot)
    ///    - droneLocation: location of the drone
    func processFirstStep(homeLocation: Location3D, droneLocation: Location3D) -> TrajectoryStep {
        if homeDistance < Constants.deltaDistance {
            ULog.d(.tag,"first to third step. homeDistance=\(homeDistance)")
            return processThirdStep(homeLocation: homeLocation, droneLocation: droneLocation)
        }
        let distanceFromStart = initialLocation?.distance(from: droneLocation.coordinate) ?? 0.0
        if distanceFromStart > Constants.deltaDistance || droneLocation.altitude > rthAltitude - Constants.deltaDistance {
            ULog.d(.tag,"first to second step. distanceFromStart=\(distanceFromStart), droneAlt=\(droneLocation.altitude)")
            // The drone has started to move horizontally, or is close to its RTH altitude
            return processSecondStep(homeLocation: homeLocation, droneLocation: droneLocation)
        }

        let dronePoint = droneLocation.agsPoint.withAltitude(droneLocation.altitude + baseAbsoluteAltitude)
        var points = [dronePoint]
        if droneLocation.altitude <= rthAltitude {
            // if the drone is too low, it first climbs to reach the RTH altitude.
            let firstAltitudePoint = droneLocation.agsPoint.withAltitude(rthAltitude + baseAbsoluteAltitude)
            points.append(firstAltitudePoint)
        }
        let secondAltitudePoint = homeLocation.agsPoint.withAltitude(rthAltitude + baseAbsoluteAltitude)
        points.append(contentsOf: [secondAltitudePoint, homeLocation.agsPoint])
        drawLine(points)

        return .firstStep
    }

    /// Processes the display during the second step of the RTH.
    ///
    /// - Parameters:
    ///    - homeLocation: the home location (take off point or pilot)
    ///    - droneLocation: location of the drone
    func processSecondStep(homeLocation: Location3D, droneLocation: Location3D) -> TrajectoryStep {
        if homeDistance < Constants.deltaDistance || droneLocation.altitude < rthAltitude - Constants.deltaDistance {
            // The drone is over home or descending.
            ULog.d(.tag,"second to third step. homeDistance=\(homeDistance), droneAlt=\(droneLocation.altitude)")
            return processThirdStep(homeLocation: homeLocation, droneLocation: droneLocation)
        } else {
            // Still on second segment, draw second and third.
            let dronePoint = droneLocation.agsPoint.withAltitude(droneLocation.altitude + baseAbsoluteAltitude)
            let secondAltitudePoint = homeLocation.agsPoint.withAltitude(droneLocation.altitude + baseAbsoluteAltitude)
            let points = [dronePoint, secondAltitudePoint, homeLocation.agsPoint]
            drawLine(points)

            return .secondStep
        }
    }

    /// Processes the display during the third step of the RTH.
    ///
    /// - Parameters:
    ///    - homeLocation: the home location (take off point or pilot)
    ///    - droneLocation: location of the drone
    func processThirdStep(homeLocation: Location3D, droneLocation: Location3D) -> TrajectoryStep {
        if droneLocation.altitude > Constants.deltaDistance {
            let dronePoint = droneLocation.agsPoint.withAltitude(droneLocation.altitude + baseAbsoluteAltitude)
            let points = [dronePoint, homeLocation.agsPoint]
            drawLine(points)
        } else {
            // Near home, erase the remaining line.
            drawLine([])
        }
        return .thirdStep
    }

    /// Draws the RTH polyline.
    ///
    /// - Parameter points: array of AGS points defining the polyline
    func drawLine(_ points: [AGSPoint]) {
        let line = AGSPolyline(points: points)
        if let lineGraphics = droneToPointLineGraphic {
            lineGraphics.geometry = line
        } else {
            let symbol = AGSSimpleLineSymbol(style: .dot,
                                             color: Constants.defaultColor,
                                             width: Constants.lineWidth)
            let lineGraphics = AGSGraphic(geometry: line, symbol: symbol)
            graphics.add(lineGraphics)
            droneToPointLineGraphic = lineGraphics
        }
    }
}
