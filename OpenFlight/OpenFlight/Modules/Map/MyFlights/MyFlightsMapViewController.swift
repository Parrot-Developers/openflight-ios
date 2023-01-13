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

private extension ULogTag {
    static let tag = ULogTag(name: "MyFlightsMapViewController")
}

/// View controller for my flights display.
open class MyFlightsMapViewController: AGSSceneViewController {

    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()
    public var myFlightsOverlay: TrajectoryGraphicsOverlay?
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
    private var elevationLoaded: Bool = false {
        didSet {
            updateAltitudeOffSet()
        }
    }
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
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        listenElevation()
    }

    private func getCurrentViewPoint() -> AGSViewpoint? {
        if let flightPlan = flightPlan, let dataSetting = flightPlan.dataSetting,
           !flightPlan.isEmpty {
            let envelope = dataSetting.polyline
                .envelopeWithMargin(ArcGISStyle.projectEnvelopeMarginFactor,
                                    altitudeOffset: flightPlan.isAMSL == true ? 0 : altitudeOffSet)
            return AGSViewpoint(targetExtent: envelope)
        } else if let flightPoints = myFlightsOverlay?.flightsPoints.value {
            return getViewPoint(for: flightPoints)

        }
        return nil
    }

    public func listenElevation() {
        elevationLoadedCancellable = elevationSource.$elevationLoaded
            .prepend(true)
            .filter { $0 }
            .sink { [weak self] loadStatus in
            guard loadStatus, let self = self else { return }
            self.elevationLoaded = loadStatus
        }
    }

    func updateAltitudeOffSet() {
        guard elevationLoaded else { return }
        flightPlanAltitudeRequest?.cancel()
        flightPlanAltitudeRequest = nil
        if let coordinate = flightPlan?.dataSetting?.coordinate {
            flightPlanAltitudeRequest = sceneView.scene?.baseSurface?
                .elevation(for: AGSPoint(clLocationCoordinate2D: coordinate)) { [weak self] elevation, _ in
                self?.altitudeOffSet = elevation
                self?.setViewPoint()
            }
        }

        guard let flightsPoints = flightsPoints,
              let firstPoint = flightsPoints.first?.first?.point else {
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
                ULog.d(.tag, "Apply altitude offset to flight overlay: \(altitudeOffSet)")
                self.myFlightsOverlay?.sceneProperties?.altitudeOffset = altitudeOffSet
            }
            self.setViewPoint()
        }
    }

    /// Set view point
    private func setViewPoint() {
        if let viewPoint = getCurrentViewPoint() {
            sceneView.setViewpoint(viewPoint)
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
        addMyFlightsOverlay()
        myFlightsOverlay?.displayFlightTrajectories(flightsPoints: flightsPoints,
                                                    hasAmslAltitude: hasAmslAltitude,
                                                    trajectoryState: trajectoryState,
                                                    adjustViewPoint: true)
    }

    /// Called to display a flight plan.
    ///
    /// - Parameters:
    ///    - flightPlan: flight plan model
    ///    - shouldReloadCamera: whether scene's camera should be reloaded
    func displayFlightPlan(_ flightPlan: FlightPlanModel,
                           shouldReloadCamera: Bool = false) {
        self.flightPlan = flightPlan
        addFlightPlanOverlay()
        flightPlanOverlay?.displayFlightPlan(flightPlan, shouldReloadCamera: shouldReloadCamera, mapMode: .myFlights)
        flightPlanOverlay?.sceneProperties?.surfacePlacement = flightPlan.isAMSL == true ? .absolute : .relative
        updateAltitudeOffSet()
    }

    // Add the trajectory overlay
    func addMyFlightsOverlay() {
        if let myFlightsOverlay = myFlightsOverlay {
            self.sceneView.graphicsOverlays.remove(myFlightsOverlay)
            self.myFlightsOverlay = nil
        }
        myFlightsOverlay = TrajectoryGraphicsOverlay()
        myFlightsOverlay?.sceneProperties?.surfacePlacement = .absolute
        myFlightsOverlay?.isActivePublisher
            .sink { [weak self] isActive in
                guard let self = self, let myFlightsOverlay = self.myFlightsOverlay else { return }
                if isActive {
                    self.sceneView.graphicsOverlays.insert(myFlightsOverlay, at: 0)
                } else {
                    self.sceneView.graphicsOverlays.remove(myFlightsOverlay)
                }
        }.store(in: &cancellables)
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

        flightPlanOverlay?.sceneProperties?.surfacePlacement = flightPlan?.isAMSL == true ? .absolute : .relative
        flightPlanOverlay?.isActivePublisher
            .sink { [weak self] isActive in
            guard let self = self, let flightPlanOverlay = self.flightPlanOverlay else { return }
            if isActive {
                self.sceneView.graphicsOverlays.insert(flightPlanOverlay, at: 1)
            } else {
                self.sceneView.graphicsOverlays.remove(flightPlanOverlay)
            }
        }.store(in: &cancellables)
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
        ULog.d(.tag, "Get view point for flight, altitudeOffset \(altitudeOffset?.description ?? "nil")")
        let allPoints = flightsPoints.reduce([]) { $0 + $1.map {$0.point} }
        let polyline = AGSPolyline(points: allPoints)
        let bufferedExtent = polyline.envelopeWithMargin(altitudeOffset: altitudeOffset)
        let viewPoint = AGSViewpoint(targetExtent: bufferedExtent)
        return viewPoint
    }
}
