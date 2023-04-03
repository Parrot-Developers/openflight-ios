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
import ArcGIS
import GroundSdk
import Combine
import Pictor

private extension ULogTag {
    static let tag = ULogTag(name: "MyFlightsMapViewController")
}

/// View controller for my flights display.
open class MyFlightsMapViewController: AGSSceneViewController {

    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()
    public var myFlightsOverlays: [TrajectoryGraphicsOverlay] = []
    private var flightPlanOverlay: FlightPlanGraphicsOverlay?
    public var flightPlanEditionService: FlightPlanEditionService?
    private var bamService: BannerAlertManagerService?
    private var missionsStore: MissionsStore?
    private var rthService: RthService?
    private var flightPlanRunManager: FlightPlanRunManager?
    private var memoryPressureMonitor: MemoryPressureMonitorService?

    private var hasAmslAltitude = false
    private var viewModel = MyFlightsViewModel()
    private var flightsPoints: [[TrajectoryPoint]]?
    public var flightPlan: FlightPlanModel?
    private var altitudeOffSet: Double = 0.0

    /// Request for elevation of 'my flight' first point.
    private var myFlightAltitudeRequest: AGSCancelable? {
        willSet {
            if myFlightAltitudeRequest?.isCanceled() == false {
                myFlightAltitudeRequest?.cancel()
            }
        }
    }

    /// Request for elevation of 'my flight' first point.
    private var flightPlanAltitudeRequest: AGSCancelable? {
        willSet {
            if flightPlanAltitudeRequest?.isCanceled() == false {
                flightPlanAltitudeRequest?.cancel()
            }
        }
    }

    /// Currrent elevation request if any, `nil` otherwise.
    private var elevationRequest: AGSCancelable? {
        willSet {
            if elevationRequest?.isCanceled() == false {
                elevationRequest?.cancel()
            }
        }
    }

    public static func instantiate(bamService: BannerAlertManagerService,
                                   missionsStore: MissionsStore,
                                   flightPlanEditionService: FlightPlanEditionService,
                                   flightPlanRunManager: FlightPlanRunManager,
                                   memoryPressureMonitor: MemoryPressureMonitorService) -> MyFlightsMapViewController {
        let viewController = StoryboardScene.MyFlightsMap.initialScene.instantiate()
        viewController.bamService = bamService
        viewController.missionsStore = missionsStore
        viewController.flightPlanEditionService = flightPlanEditionService
        viewController.flightPlanRunManager = flightPlanRunManager
        viewController.memoryPressureMonitor = memoryPressureMonitor
        return viewController
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        setBaseSurface(enabled: true)
        addMyFlightsOverlays()
        addFlightPlanOverlay()
    }

    public override func getCenter(completion: @escaping(AGSViewpoint?) -> Void) {
        getCurrentViewPoint { viewPoint in
            completion(viewPoint)
        }
    }

    /// Get Current view point to center map.
    ///
    /// - Returns: the current view point
    private func getCurrentViewPoint(completion: @escaping(AGSViewpoint?) -> Void) {
        if let flightPlan = flightPlan, let dataSetting = flightPlan.dataSetting,
           !flightPlan.isEmpty {
            if let amsl = flightPlan.isAMSL, amsl {
                getFlightPlanAMSLViewPoint(dataSetting: dataSetting) { viewPoint in
                    completion(viewPoint)
                }
            } else {
                if let coordinate = dataSetting.coordinate {
                    getFlightPlanATOViewPoint(coordinate: coordinate, dataSetting: dataSetting) { viewPoint in
                        completion(viewPoint)
                    }
                } else {
                    completion(nil)
                }
            }
        } else if let flightPoints = myFlightsOverlays.first?.flightsPoints.value {
            completion(getViewPoint(for: flightPoints))
        } else {
            completion(nil)
        }
    }

    /// Get flight plan in AMSL view point
    ///
    /// - Returns: the view point
    private func getFlightPlanAMSLViewPoint(dataSetting: FlightPlanDataSetting,
                                            completion: @escaping(AGSViewpoint?) -> Void) {
        if sceneView.scene?.baseSurface?.isEnabled == false {
            let envelope = dataSetting.flatPolyline
                .envelopeWithMargin(altitudeOffset: 0.0)
            completion(AGSViewpoint(targetExtent: envelope))
        } else {
            let envelope = dataSetting.polyline
                .envelopeWithMargin(ArcGISStyle.projectEnvelopeMarginFactor, altitudeOffset: nil)

            completion(AGSViewpoint(targetExtent: envelope))
        }
    }

    /// Get flight plan in ATO view point
    ///
    /// - Returns: the view point
    private func getFlightPlanATOViewPoint(coordinate: CLLocationCoordinate2D,
                                           dataSetting: FlightPlanDataSetting,
                                           completion: @escaping(AGSViewpoint?) -> Void) {
        let point = AGSPoint(clLocationCoordinate2D: coordinate)
        if sceneView.scene?.baseSurface?.isEnabled == false {
            let envelope = dataSetting.flatPolyline
                .envelopeWithMargin(altitudeOffset: 0.0)
            completion(AGSViewpoint(targetExtent: envelope))
        } else {
            elevationRequest = nil
            elevationRequest = sceneView.scene?.baseSurface?.elevation(for: point) { altitude, _  in
                let envelope = dataSetting.polyline
                    .envelopeWithMargin(ArcGISStyle.projectEnvelopeMarginFactor,
                                        altitudeOffset: altitude)
                completion(AGSViewpoint(targetExtent: envelope))
            }
        }
    }

    override func updateAltitudeOffSet() {
        guard elevationLoaded else { return }
        flightPlanAltitudeRequest?.cancel()
        flightPlanAltitudeRequest = nil
        if let coordinate = flightPlan?.dataSetting?.coordinate {
            flightPlanAltitudeRequest = sceneView.scene?.baseSurface?
                .elevation(for: AGSPoint(clLocationCoordinate2D: coordinate)) { [weak self] elevation, _ in
                self?.altitudeOffSet = elevation
                self?.mapViewModel.refreshViewPoint.value = true
            }
        }

        guard let flightsPoints = flightsPoints,
              let firstPoint = flightsPoints.first?.first?.agsPoint else {
            return
        }

        myFlightAltitudeRequest?.cancel()
        myFlightAltitudeRequest = nil

        myFlightAltitudeRequest = sceneView.scene?.baseSurface?.elevation(for: firstPoint) { [weak self] elevation, error in
            guard let self = self else { return }
            self.myFlightAltitudeRequest = nil
            guard error == nil else {
                ULog.w(.tag, "Failed to get elevation for flight: \(error.debugDescription)")
                return
            }
            let altitudeOffSet = elevation - firstPoint.z
            if !self.hasAmslAltitude
                || altitudeOffSet > 0 {
                ULog.i(.tag, "Apply altitude offset to flight overlay: \(altitudeOffSet)")
                self.myFlightsOverlays.first?.sceneProperties?.altitudeOffset = altitudeOffSet
            }
            self.mapViewModel.refreshViewPoint.value = true
        }
    }

    // MARK: - Internal Funcs
    /// Displays flights trajectories and adjusts map viewpoint to show them.
    ///
    /// - Parameters:
    ///    - flightsPoints: flights trajectories
    ///    - hasAmslAltitude: `true` if flights points have altitudes in AMSL
    ///    - trajectoryState: the state of the trajectory
    public func displayFlightTrajectories(flightsPoints: [[TrajectoryPoint]],
                                          hasAmslAltitude: Bool,
                                          trajectoryState: TrajectoryState = .none) {
        self.flightsPoints = flightsPoints
        self.hasAmslAltitude = hasAmslAltitude
        for myFlightsOverlay in myFlightsOverlays {
            myFlightsOverlay.displayFlightTrajectories(flightsPoints: flightsPoints,
                                                       hasAmslAltitude: hasAmslAltitude,
                                                       trajectoryState: trajectoryState,
                                                       adjustViewPoint: true)
        }
    }

    /// Called to display a flight plan.
    ///
    /// - Parameters:
    ///    - flightPlan: flight plan model
    ///    - shouldReloadCamera: whether scene's camera should be reloaded
    func displayFlightPlan(_ flightPlan: FlightPlanModel,
                           shouldReloadCamera: Bool = false) {
        self.flightPlan = flightPlan
        flightPlanOverlay?.displayFlightPlan(flightPlan, shouldReloadCamera: shouldReloadCamera, mapMode: .myFlights)
        flightPlanOverlay?.sceneProperties?.surfacePlacement = flightPlan.isAMSL == true ? .absolute : .relative
        updateAltitudeOffSet()
    }

    /// Add the trajectory overlay
    private func addMyFlightsOverlays() {
        let flightsOverlay = TrajectoryGraphicsOverlay(type: .trajectory)
        sceneView.graphicsOverlays.add(flightsOverlay)
        myFlightsOverlays.append(flightsOverlay)

        let drapedFlightsOverlay = TrajectoryGraphicsOverlay(type: .draped)
        sceneView.graphicsOverlays.add(drapedFlightsOverlay)
        myFlightsOverlays.append(drapedFlightsOverlay)
    }

    /// Add the flight plan overlay
    private func addFlightPlanOverlay() {
        if let flightPlanOverlay = flightPlanOverlay {
            self.sceneView.graphicsOverlays.remove(flightPlanOverlay)
            self.flightPlanOverlay = nil
        }
        flightPlanOverlay = FlightPlanGraphicsOverlay(bamService: bamService,
                                                      missionsStore: missionsStore,
                                                      flightPlanEditionService: flightPlanEditionService,
                                                      flightPlanRunManager: flightPlanRunManager,
                                                      memoryPressureMonitor: memoryPressureMonitor)
        if let flightPlanOverlay = flightPlanOverlay {
            flightPlanOverlay.sceneProperties?.surfacePlacement = flightPlan?.isAMSL == true ? .absolute : .relative
            sceneView.graphicsOverlays.add(flightPlanOverlay)
        }
    }

    /// Updates current view point.
    ///
    /// - Parameters:
    ///    - viewPoint: new view point
    ///    - animated: whether wiew point change should be animated
    func updateViewPoint(_ viewPoint: AGSViewpoint, animated: Bool = false) {
        guard !mapViewModel.isMiniMap.value else { return }
        if animated {
            ignoreCameraAdjustments = true
            sceneView.setViewpoint(viewPoint,
                                   duration: Style.fastAnimationDuration) { [weak self] _ in
                self?.ignoreCameraAdjustments = false
            }
        } else {
            sceneView.setViewpoint(viewPoint)
        }
    }

    /// Get view point from trajectory points and altitude.
    ///
    /// - Parameters:
    ///    - for: trajectories points to display
    ///    - altitudeOffset: altitude offset to apply to trajectory points to compute zoom level
    func getViewPoint(for flightsPoints: [[TrajectoryPoint]], altitudeOffset: Double? = nil) -> AGSViewpoint {
        ULog.i(.tag, "Get view point for flight, altitudeOffset \(altitudeOffset?.description ?? "nil")")
        let allPoints = flightsPoints.reduce([]) { $0 + $1.map {$0.agsPoint} }
        let polyline = AGSPolyline(points: allPoints)
        let bufferedExtent = polyline.envelopeWithMargin(ArcGISStyle.projectEnvelopeMarginFactor, altitudeOffset: altitudeOffset)
        let viewPoint = AGSViewpoint(targetExtent: bufferedExtent)
        return viewPoint
    }
}
