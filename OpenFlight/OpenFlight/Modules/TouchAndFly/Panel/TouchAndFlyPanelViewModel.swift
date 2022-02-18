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

public enum DisplayOnMap {
    case nothing
    case waypoint(location: CLLocationCoordinate2D, altitude: Double, speed: Double)
    case poi(location: CLLocationCoordinate2D, altitude: Double)
}

protocol TouchAndFlyPanelViewModel: AnyObject {
    // Display on map publisher
    var displayOnMapPublisher: AnyPublisher<DisplayOnMap, Never> { get }
}

class TouchAndFlyPanelViewModelImpl {
    // MARK: - PUBLIC / exposed ( OUT )
    @Published private(set) var buttonsDisplay = ButtonsDisplay.standard(playEnabled: false, deleteEnabled: false)
    @Published private(set) var infoStatusDrone = MessageDrone(message: "", color: .black)
    @Published private(set) var progressViewDisplay = ProgressViewDisplay.standard

    var displayOnMap = CurrentValueSubject<DisplayOnMap, Never>(.nothing)
    var displayOnMapPublisher: AnyPublisher<DisplayOnMap, Never> {
        displayOnMap.eraseToAnyPublisher()
    }

    var progressValue: AnyPublisher<Double?, Never> {
        return service.guidingProgressPublisher
    }
    var progressTimer: AnyPublisher<Double?, Never> {
        return service.guidingTimePublisher
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
    }

    public func showStream() {
        splitControls.forceStream = true
        splitControls.displayMapOr3DasChild()
        splitControls.updateCenterMapButtonStatus()
    }

    public func showMap() {
        splitControls.forceStream = false
        splitControls.displayMapOr3DasChild()
        splitControls.updateCenterMapButtonStatus()
    }

    // Listening
    private func listenStatusDrone() {
        service.runningStatePublisher
            .removeDuplicates()
            .combineLatest(service.targetPublisher)
            .sink { [unowned self] runningState, target in
                setButtonsDisplay(runnningState: runningState, target: target)
                setProgressView(runningState: runningState, target: target)
            }
            .store(in: &cancellables)

        service.runningStatePublisher
            .sink { [unowned self] runningState in
                setMessageDrone(runningState: runningState)
            }
            .store(in: &cancellables)
    }

    private func listenTarget() {
        service.targetPublisher
            .sink { [unowned self] target in
                setDashboard(target: target)
                setValueSettingRuler(target)
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

    func pause() {
        service.pause()
    }

    // Setting functions
    private func setButtonsDisplay(runnningState: TouchAndFlyRunningState, target: TouchAndFlyTarget) {
        switch runnningState {
        case .noTarget:
            buttonsDisplay = .standard(playEnabled: false, deleteEnabled: false)
        case .running:
            switch target {
            case .none:
                break
            case .wayPoint:
                buttonsDisplay = .runningWaypoint(duration: 0)
            case .poi:
                buttonsDisplay = .runningPoi
            }
        case .ready:
            buttonsDisplay = .standard(playEnabled: true, deleteEnabled: true)
        case .blocked:
            buttonsDisplay = .standard(playEnabled: false, deleteEnabled: true)
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
            displayOnMap.value = .nothing
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
    enum ButtonsDisplay {
        case standard(playEnabled: Bool, deleteEnabled: Bool) // disable
        case runningWaypoint(duration: TimeInterval)
        case runningPoi
    }

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
        return Array(-120...500).stepFiltered(with: Int(step))
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
        return Array(-120...500).stepFiltered(with: Int(step))
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
