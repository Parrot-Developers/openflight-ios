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
import Combine
import GroundSdk

public enum DisplayOnMap: Equatable {
    case nothing
    case waypoint(location: CLLocationCoordinate2D, altitude: Double, speed: Double)
    case poi(location: CLLocationCoordinate2D, altitude: Double)

    public static func == (lhs: DisplayOnMap, rhs: DisplayOnMap) -> Bool {
        switch (lhs, rhs) {
        case (.waypoint(let locationLhs, let altitudeLhs, let speedLhs), .waypoint(let locationRhs, let altitudeRhs, let speedRhs)):
            return locationLhs == locationRhs && altitudeLhs == altitudeRhs && speedLhs == speedRhs
        case (.poi(let locationLhs, let altitudeLhs), .poi(let locationRhs, let altitudeRhs)):
            return locationLhs == locationRhs && altitudeLhs == altitudeRhs
        case (.nothing, .nothing):
            return true
        default:
            return false
        }
    }
}

public enum ButtonsDisplay: Equatable {
    case standard(playEnabled: Bool, deleteEnabled: Bool) // disable
    case runningWaypoint(duration: TimeInterval)
    case runningPoi

    public static func == (lhs: ButtonsDisplay, rhs: ButtonsDisplay) -> Bool {
        switch (lhs, rhs) {
        case (.standard(let playEnabledLhs, let deleteEnabledLhs), .standard(let playEnabledRhs, let deleteEnabledRhs)):
            return playEnabledLhs == playEnabledRhs && deleteEnabledLhs == deleteEnabledRhs
        case (.runningWaypoint(let durationLhs), .runningWaypoint(let durationRhs)):
            return durationLhs == durationRhs
        case (.runningPoi, .runningPoi):
            return true
        default:
            return false
        }
    }
}

public enum StreamElement: Equatable {
    case none
    case waypoint(point: CGPoint, altitude: Double, distance: Double)
    case poi(point: CGPoint, altitude: Double, distance: Double)
    case user(point: CGPoint)

    public static func == (lhs: StreamElement, rhs: StreamElement) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case (.waypoint(let pointLhs, let altitudeLhs, _), .waypoint(let pointRhs, let altitudeRhs, _)):
            return pointLhs == pointRhs && altitudeLhs == altitudeRhs
        case (.poi(let pointLhs, let altitudeLhs, _), .poi(let pointRhs, let altitudeRhs, _)):
            return pointLhs == pointRhs && altitudeLhs == altitudeRhs
        case (.user(let pointLhs), .user(let pointRhs)):
            return pointLhs == pointRhs
        default:
            return false
        }
    }
}

protocol TouchAndFlyPanelViewModel: AnyObject {
    // Display on map publisher
    var displayOnMapPublisher: AnyPublisher<DisplayOnMap, Never> { get }
    // Buttons display publisher
    var buttonsDisplayPublisher: AnyPublisher<ButtonsDisplay, Never> { get }
    // Stream element publisher
    var streamElementPublisher: AnyPublisher<StreamElement, Never> { get }
}

class TouchAndFlyPanelViewModelImpl {
    // MARK: - PUBLIC / exposed ( OUT )
    @Published private(set) var infoStatusDrone = MessageDrone(message: "", color: .black)
    @Published private(set) var progressViewDisplay = ProgressViewDisplay.standard

    var displayOnMap = CurrentValueSubject<DisplayOnMap, Never>(.nothing)
    var displayOnMapPublisher: AnyPublisher<DisplayOnMap, Never> {
        displayOnMap.eraseToAnyPublisher()
    }

    var streamElement = CurrentValueSubject<StreamElement, Never>(.none)
    var streamElementPublisher: AnyPublisher<StreamElement, Never> {
        streamElement.eraseToAnyPublisher()
    }

    var buttonsDisplay = CurrentValueSubject<ButtonsDisplay, Never>(ButtonsDisplay.standard(playEnabled: false,
                                                                                            deleteEnabled: false))
    var buttonsDisplayPublisher: AnyPublisher<ButtonsDisplay, Never> {
        buttonsDisplay.eraseToAnyPublisher()
    }

    var progressValue: AnyPublisher<Double?, Never> {
        return service.guidingProgressPublisher
    }

    // MARK: Internal - Private Properties
    private var serviceUI: TouchAndFlyUiService
    private var service: TouchAndFlyService

    var rulerSettings: [FlightPlanSettingType] = []
    weak var splitControls: SplitControls!
    // MARK: - Cancellable
    private var cancellables = Set<AnyCancellable>()

    init(service: TouchAndFlyService,
         uiService: TouchAndFlyUiService, splitControls: SplitControls) {
        // Services
        serviceUI = uiService
        self.service = service
        self.splitControls = splitControls

        listenStatusDrone()
        listenTarget()
        listenStream()
    }

    public func showStream() {
        splitControls.forceStream = true
        splitControls.streamViewController?.doNotPauseStreamOnDisappear = true
        splitControls.displayMapOr3DasChild()
        splitControls.updateCenterMapButtonStatus()
    }

    public func showMap() {
        splitControls.forceStream = false
        splitControls.streamViewController?.doNotPauseStreamOnDisappear = true
        splitControls.displayMapOr3DasChild()
        splitControls.updateCenterMapButtonStatus()
    }

    // Listening
    private func listenStatusDrone() {
        service.runningStatePublisher
            .combineLatest(service.targetPublisher)
            .sink { [weak self] runningState, target in
                self?.setButtonsDisplay(runningState: runningState, target: target)
                self?.setProgressView(runningState: runningState, target: target)
            }
            .store(in: &cancellables)

        service.runningStatePublisher
            .sink { [weak self] runningState in
                self?.setMessageDrone(runningState: runningState)
            }
            .store(in: &cancellables)
    }

    private func listenStream() {
        service.streamElementPublisher
            .removeDuplicates()
            .sink { [weak self] streamElement in
                self?.streamElement.value = streamElement
            }
            .store(in: &cancellables)
    }

    private func listenTarget() {
        service.targetPublisher
            .sink { [weak self] target in
                self?.setValueSettingRuler(target)
                self?.setDashboard(target: target)
            }
            .store(in: &cancellables)
    }

    // Actions on the drone
    func clear() {
        service.clear()
    }

    func play() {
        service.start()
    }

    func stop() {
        service.stop()
    }

    // Setting functions

    /// Enables or disables buttons according to the current running state and target.
    /// - parameters:
    ///   - runningState: current running state
    ///   - target: current target
    private func setButtonsDisplay(runningState: TouchAndFlyRunningState, target: TouchAndFlyTarget) {
        switch runningState {
        case .noTarget:
            buttonsDisplay.value = .standard(playEnabled: false, deleteEnabled: false)
        case .running:
            switch target {
            case .none:
                break
            case .wayPoint:
                buttonsDisplay.value = .runningWaypoint(duration: 0)
            case .poi:
                buttonsDisplay.value = .runningPoi
            }
        case .ready:
            buttonsDisplay.value = .standard(playEnabled: true, deleteEnabled: true)
        case .blocked:
            buttonsDisplay.value = .standard(playEnabled: false, deleteEnabled: true)
        }
    }

    private func setDashboard(target: TouchAndFlyTarget) {
        switch target {
        case .none:
            displayOnMap.value = .nothing
        case .wayPoint(location: let location, altitude: let altitude, speed: let speed):
            displayOnMap.value = .waypoint(location: location, altitude: altitude, speed: speed)
        case .poi(location: let location, altitude: let altitude):
            displayOnMap.value = .poi(location: location, altitude: altitude)
        }
    }

    private func setMessageDrone(runningState: TouchAndFlyRunningState) {
        switch runningState {
        case .noTarget(let connection):
            switch connection {
            case true:
                infoStatusDrone.message = L10n.touchFlyPlaceWaypointPoi
                infoStatusDrone.color = UIColor.orange
            case false:
                infoStatusDrone.message = L10n.commonDroneNotConnected
                infoStatusDrone.color = UIColor.orange
            }
        case .running, .ready:
            infoStatusDrone.message = ""
        case .blocked(let messageBlocked):
            infoStatusDrone.color = UIColor.orange
            switch messageBlocked {
            case .droneAboveMaxAltitude:
                infoStatusDrone.message = L10n.alertDroneAboveMaxAltitude
            case .droneNotConnected:
                infoStatusDrone.message = L10n.commonDroneNotConnected
            case .droneGpsInfoInaccurate:
                infoStatusDrone.message = L10n.alertNoGps
            case .droneNotCalibrated:
                infoStatusDrone.message = L10n.flightPlanAlertDroneMagnetometerKo
            case .droneOutOfGeofence:
                infoStatusDrone.message = L10n.alertGeofenceReached
            case .droneTooCloseToGround:
                infoStatusDrone.message = L10n.alertDroneTooCloseGround
            case .droneNotFlying:
                infoStatusDrone.message = L10n.touchFlyTakeOffTheDrone
            case .droneTakingOff:
                infoStatusDrone.message = L10n.touchFlyTakeOffInProgress
            }
        }
    }

    private func setProgressView(runningState: TouchAndFlyRunningState, target: TouchAndFlyTarget) {
        switch runningState {
        case .noTarget:
            progressViewDisplay = .standard
        case .running:
            switch target {
            case .none:
                progressViewDisplay = .standard
            case .wayPoint:
                progressViewDisplay = .runningWaypoint
            case .poi:
                progressViewDisplay = .runningPoi
            }
        case .ready:
            progressViewDisplay = .standard
        case .blocked:
            progressViewDisplay = .standard
        }
    }

    /// Update the location of the poi or waypoint
    ///
    /// - Parameters:
    ///    - location: the new location
    ///    - type: the type
    ///    - altitude: the altitude
    func update(location: CLLocationCoordinate2D?, type: TouchStreamView.TypeView, altitude: Double? = nil) {
        switch type {
        case .waypoint:
            guard let location = location ?? service.wayPoint else { return }
            service.setWayPoint(location, altitude: altitude?.rounded())
        case .poi:
            guard let location = location ?? service.poi else { return }
            service.setPoi(location, altitude: altitude?.rounded())
        }
    }

    /// Update the position of the poi or waypoint
    ///
    /// - Parameters:
    ///    - point: the new point
    ///    - type: the type
    /// - Returns: true if a location was computed
    func update(point: CGPoint, type: TouchStreamView.TypeView) -> Bool {
        var result = false
        switch type {
        case .poi:
            if let location = service.setPoiLocation(point: point) {
                result = true
                update(location: location.coordinate, type: type, altitude: location.altitude)
            }
        case .waypoint:
            if let location = service.setWaypointLocation(point: point) {
                result = true
                update(location: location.coordinate, type: type, altitude: location.altitude)
            }
        }
        return result
    }

    /// Update horizontally or vertically an existing waypoint
    ///
    /// - Parameters:
    ///    - point: the new point
    ///    - dragDirection: the updated direction
    /// - Returns: true if a location was computed
    func update(point: CGPoint, dragDirection: TouchStreamView.DragDirection) -> Bool {
        guard
            let location = service.setWaypointLocation(point: point),
            let currentLocation = service.wayPoint
        else { return false }

        switch dragDirection {
        case .vertical:
            update(location: currentLocation, type: .waypoint, altitude: location.altitude)
        case .horizontal:
            update(location: location.coordinate, type: .waypoint, altitude: service.targetAltitude)
        default:
            return false
        }
        return true
    }
}

// Setting functions
extension TouchAndFlyPanelViewModelImpl {
    private func setValueSettingRuler(_ target: TouchAndFlyTarget) {
        rulerSettings.removeAll()

        let speedTouchAndFlySettingType = SpeedTouchAndFlySettingType(
            speedCurrentValue: 0,
            isDisabled: false)
        switch target {
        case .none:
            break
        case .wayPoint(location: _, altitude: let altitude, speed: let speed):
            let altitudeTouchAndFlySettingTypeWayPoint = WayPointAltitudeTouchAndFlySettingType(
                altitudeCurrentValue: 0,
                isDisabled: false)
            altitudeTouchAndFlySettingTypeWayPoint.currentValue = Int(altitude)
            speedTouchAndFlySettingType.currentValue = Int(speed)
            rulerSettings.append(altitudeTouchAndFlySettingTypeWayPoint)
        case .poi(location: _, altitude: let altitude):
            let altitudeTouchAndFlySettingTypePoi = PoiAltitudeTouchAndFlySettingType(
                altitudeCurrentValue: 0,
                isDisabled: false)
            altitudeTouchAndFlySettingTypePoi.currentValue = Int(altitude)
            rulerSettings.append(altitudeTouchAndFlySettingTypePoi)
        }
        rulerSettings.append(speedTouchAndFlySettingType)
    }

    func setValueAltitude(value: Int) {
        switch service.target.type {
        case .none:
            break
        case .wayPoint:
            service.set(altitude: Double(value))
        case .poi:
            service.set(altitude: Double(value))
        }
    }

    func setValueSpeed(value: Int) {
        switch service.target.type {
        case .wayPoint:
            service.setWayPoint(speed: Double(value))
        default:
            break
        }
    }
}

// Support Models
extension TouchAndFlyPanelViewModelImpl {

    enum ProgressViewDisplay {
        case standard // disable
        case runningWaypoint
        case runningPoi
    }

    struct MessageDrone {
        var message: String
        var color: UIColor
    }
}

// MARK: - Waypoint Altitude
final class WayPointAltitudeTouchAndFlySettingType: FlightPlanSettingType {
    var title: String {
        return L10n.touchFlyWpAltitude
    }
    var allValues: [Int] {
        return Array(-150 ..< -100).stepFiltered(with: Int(step / divider))
             + Array(-100 ..< 100)
             + Array(100 ..< 200).stepFiltered(with: Int(step / divider))
             + Array(200 ... 500).stepFiltered(with: Int(step))
    }
    var valueDescriptions: [String]?
    var valueImages: [UIImage]?
    var currentValue: Int?
    var type: FlightPlanSettingCellType {
        return .centeredRuler
    }
    var key: String {
        return TouchAndFlyPanelSettingsKey.altitude.rawValue
    }
    var unit: UnitType {
        return .distance
    }
    var step: Double {
        return 10.0
    }
    var divider: Double {
        return 2.0
    }
    var isDisabled: Bool
    var category: FlightPlanSettingCategory {
        return .custom(title)
    }

    internal init(
        altitudeCurrentValue: Int? = nil,
        isDisabled: Bool
    ) {
        self.currentValue = altitudeCurrentValue
        self.isDisabled = isDisabled
    }
}

// MARK: - Poi Altitude
final class PoiAltitudeTouchAndFlySettingType: FlightPlanSettingType {
    var title: String {
        return L10n.touchFlyPoiAltitude
    }
    var allValues: [Int] {
        return Array(-150 ..< -100).stepFiltered(with: Int(step / divider))
             + Array(-100 ..< 100)
             + Array(100 ..< 200).stepFiltered(with: Int(step / divider))
             + Array(200 ... 500).stepFiltered(with: Int(step))
    }
    var valueDescriptions: [String]?
    var valueImages: [UIImage]?
    var currentValue: Int?
    var type: FlightPlanSettingCellType {
        return .centeredRuler
    }
    var key: String {
        return TouchAndFlyPanelSettingsKey.altitude.rawValue
    }
    var unit: UnitType {
        return .distance
    }
    var step: Double {
        return 10.0
    }
    var divider: Double {
        return 2.0
    }
    var isDisabled: Bool
    var category: FlightPlanSettingCategory {
        return .custom(title)
    }

    internal init(
        altitudeCurrentValue: Int? = nil,
        isDisabled: Bool
    ) {
        self.currentValue = altitudeCurrentValue
        self.isDisabled = isDisabled
    }
}

// MARK: - Speed
final class SpeedTouchAndFlySettingType: FlightPlanSettingType {
    var title: String {
        return L10n.commonSpeed
    }
    // TODO: check the real value for speed
    var allValues: [Int] {
        return Array(1...12).stepFiltered(with: Int(step))
    }
    var valueDescriptions: [String]?
    var valueImages: [UIImage]?
    var currentValue: Int?
    var type: FlightPlanSettingCellType {
        return .centeredRuler
    }
    var key: String {
        return TouchAndFlyPanelSettingsKey.speed.rawValue
    }
    var unit: UnitType {
        return .speed
    }
    var step: Double {
        return 1.0
    }
    var divider: Double {
        return 1.0
    }
    var isDisabled: Bool
    var category: FlightPlanSettingCategory {
        return .custom(title)
    }

    internal init(
        speedCurrentValue: Int? = nil,
        isDisabled: Bool
    ) {
        self.currentValue = speedCurrentValue
        self.isDisabled = isDisabled
    }
}
