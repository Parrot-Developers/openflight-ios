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
import Combine
import ArcGIS
import GroundSdk
import SwiftyUserDefaults

/// Delegate for handling map auto scroll
public protocol MapAutoScrollDelegate: AnyObject {
    func geoViewForAutoScroll() -> AGSGeoView
    func shouldAutoScroll() -> Bool
    func shouldAutoScrollToCenter() -> Bool
    func getCenter() -> CLLocationCoordinate2D?
    func setCenter(coordinates: CLLocationCoordinate2D)
    func locationToScreen(_ location: AGSPoint) -> CGPoint
}

/// ViewModel for `CommonMapViewController`
public class CommonMapViewModel {
    // MARK: Private Properties
    private let locationsTracker: LocationsTracker = Services.hub.locationsTracker
    /// Combine cancellables
    private var cancellables = Set<AnyCancellable>()
    private var autoScrollCancellables = Set<AnyCancellable>()
    /// Network service
    public let networkService: NetworkService = Services.hub.systemServices.networkService

    // MARK: Public Properties
    public var networkReachablePublisher: AnyPublisher<Bool, Never> { networkService.networkReachable }
    public var centerStatePublisher: AnyPublisher<MapCenterState, Never> { centerState.eraseToAnyPublisher() }
    public var centerState = CurrentValueSubject<MapCenterState, Never>(.none)

    public var refreshViewPointPublisher: AnyPublisher<Bool, Never> { refreshViewPoint.eraseToAnyPublisher() }
    public var refreshViewPoint = CurrentValueSubject<Bool, Never>(true)

    public var isMiniMapPublisher: AnyPublisher<Bool, Never> { isMiniMap.eraseToAnyPublisher() }
    public var isMiniMap = CurrentValueSubject<Bool, Never>(false)
    public var largeMapRatio: Double?

    internal var mapTypePublisher: AnyPublisher<SettingsMapDisplayType, Never> { mapTypeSubject.removeDuplicates().eraseToAnyPublisher() }
    private var mapTypeSubject = CurrentValueSubject<SettingsMapDisplayType, Never>(SettingsMapDisplayType.current)
    private var mapTypeObserver: DefaultsDisposable?

    /// Terrain elevation source.
    public var keyboardIsHidden: Bool = true
    public var lastValidPoints: (screen: CGPoint?, map: AGSPoint?)

    /// Delegate to apply autoscroll depending on the map 2D/3D and the mission behaviour.
    private weak var autoScrollDelegate: MapAutoScrollDelegate?
    /// Old drone location for auto scroll.
    private var oldDroneLocation: Location3D?
    /// Flag to check if the view is visible in order to pause auto scroll.
    open var isViewControllerVisible = false

    private enum Constants {
        static let mapInsideInsets = UIEdgeInsets(top: 50, left: 80, bottom: 70, right: 40)
        static let safetyInsideMargin: Double = 30
        static let autoScrollSpeed: Double = 0.5
    }

    // MARK: Init

    /// Init
    /// - Parameters:
    ///  - networkService: the network service
    init() {

        // Add keyboard observer to block or not touch on the map.
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        mapTypeObserver = Defaults.observe(DefaultsKeys.userMiniMapTypeSettingKey, options: [.new]) { [weak self] _ in
            self?.mapTypeSubject.value = SettingsMapDisplayType.current
        }
    }

    @objc private func keyboardWillAppear() {
        keyboardIsHidden = false
    }

    @objc private func keyboardWillDisappear() {
        keyboardIsHidden = true
    }

    // MARK: - AutoScroll

    /// Enable Map auto scroll.
    ///
    /// - Parameters:
    ///    - delegate: new drone location
    open func enableAutoScroll(delegate: MapAutoScrollDelegate) {
        autoScrollDelegate = delegate
        autoScrollCancellables = Set<AnyCancellable>()
        locationsTracker.drone3DLocationPublisher(animated: true, absoluteAltitude: true)
            .sink { [weak self] location in
                guard let self = self, let coordinates = location.coordinates else { return }
                if self.checkAutoScroll(location: coordinates) {
                    self.makeAutoScroll(location: coordinates)
                }
                self.oldDroneLocation = coordinates
            }.store(in: &autoScrollCancellables)
    }

    /// Disable Map auto scroll.
    open func disableAutoScroll() {
        autoScrollDelegate = nil
        autoScrollCancellables = Set<AnyCancellable>()
    }

    /// Checks if we should apply auto scroll.
    ///
    /// - Parameters:
    ///    - location: new drone location
    open func checkAutoScroll(location: Location3D) -> Bool {
        guard let oldDroneLocation = self.oldDroneLocation,
              let autoScrollDelegate = autoScrollDelegate,
              isViewControllerVisible,
              !autoScrollDelegate.geoViewForAutoScroll().isNavigating,
              isInside(point: oldDroneLocation.agsPoint, safely: false) else {
            return false
        }
        if Services.hub.drone.rthService.isActive,
           let rthLocation = locationsTracker.returnHomeLocation,
           isInside(point: AGSPoint(clLocationCoordinate2D: rthLocation), safely: true) {
            return false
        }
        if !isInside(point: location.agsPoint, safely: false) {
            return true
        }
        return autoScrollDelegate.shouldAutoScroll()
    }

    /// Move the map to apply auto scroll.
    ///
    /// - Parameters:
    ///    - location: new drone location
    open func makeAutoScroll(location: Location3D) {
        guard let autoScrollDelegate = autoScrollDelegate,
              let oldDroneLocation = oldDroneLocation,
              let mapCenter = autoScrollDelegate.getCenter() else {
            return
        }
        let droneCenterDistance = oldDroneLocation.coordinate.distance(from: mapCenter)
        let movedDistance = oldDroneLocation.coordinate.distance(from: location.coordinate)
        let maxDistance = movedDistance * Constants.autoScrollSpeed
        let movingStep = min(1, (maxDistance / droneCenterDistance))
        let centeringLatitude = oldDroneLocation.coordinate.latitude - mapCenter.latitude
        let centeringLongitude = oldDroneLocation.coordinate.longitude - mapCenter.longitude
        let movementLatitude = location.coordinate.latitude - oldDroneLocation.coordinate.latitude
        let movementLongitude = location.coordinate.longitude - oldDroneLocation.coordinate.longitude
        var offsetLatitude: CLLocationDegrees = 0
        var offsetLongitude: CLLocationDegrees = 0

        if autoScrollDelegate.shouldAutoScrollToCenter() {
            // Auto scroll and centering when moving away from center
            if movementLatitude * centeringLatitude < 0 {
                offsetLatitude = abs(movementLatitude) > abs(centeringLatitude) ? centeringLatitude : 0
            } else {
                offsetLatitude = movementLatitude + (centeringLatitude * movingStep)
            }
            if movementLongitude * centeringLongitude < 0 {
                offsetLongitude = abs(movementLongitude) > abs(centeringLongitude) ? centeringLongitude : 0
            } else {
                offsetLongitude = movementLongitude + (centeringLongitude * movingStep)
            }
        } else {
            // Auto scroll with no centering
            offsetLatitude = movementLatitude
            offsetLongitude = movementLongitude
        }

        guard offsetLatitude != 0 || offsetLongitude != 0 else { return }

        let coordinate = CLLocationCoordinate2D(latitude: mapCenter.latitude + offsetLatitude, longitude: mapCenter.longitude + offsetLongitude)
        autoScrollDelegate.setCenter(coordinates: coordinate)
    }

    /// Checks if the point is inside the a visible zone on the screen.
    ///
    /// - Parameters:
    ///    - point: ags point
    ///    - safely: specify if the point represents the drone or not to adjust margin size
    ///    - referenceToAmsl: if the scene is in 3D and the point altitude is not in amsl,
    ///    you should specify the altitude diference between your point reference and amsl
    /// - Returns: boolean indicating if the location is inside the zone
    public func isInside(point: AGSPoint, safely: Bool, referenceToAmsl: Double = 0) -> Bool {
        guard let geoView = autoScrollDelegate?.geoViewForAutoScroll() else { return false }
        let locationPoint: AGSPoint
        if (geoView as? AGSSceneView)?.scene?.baseSurface?.isEnabled == true {
            locationPoint = AGSPoint(x: point.x, y: point.y, z: point.z + referenceToAmsl, spatialReference: .wgs84())
        } else {
            locationPoint = AGSPoint(x: point.x, y: point.y, z: 0.0, spatialReference: .wgs84())
        }
        guard let screenPoint = autoScrollDelegate?.locationToScreen(locationPoint),
              !screenPoint.isOriginPoint else { return false }
        let borderMargin = safely ? Constants.safetyInsideMargin : 0.0
        var edgeInsets = UIEdgeInsets(top: Constants.mapInsideInsets.top + borderMargin,
                                      left: Constants.mapInsideInsets.left + borderMargin,
                                      bottom: Constants.mapInsideInsets.bottom + borderMargin,
                                      right: Constants.mapInsideInsets.right + borderMargin)
        if isMiniMap.value, let mapRatio = largeMapRatio {
            let isMiniMapWider = geoView.bounds.width / geoView.bounds.height > mapRatio
            if isMiniMapWider {
                let extraWidth = (geoView.bounds.width - (geoView.bounds.height * mapRatio)) / 2
                edgeInsets.left += extraWidth
                edgeInsets.right += extraWidth
            } else {
                let extraHeight = (geoView.bounds.height - (geoView.bounds.width / mapRatio)) / 2
                edgeInsets.top += extraHeight
                edgeInsets.bottom += extraHeight
            }
        }
        let zone = CGRect(x: max(0, edgeInsets.left),
                          y: max(0, edgeInsets.top),
                          width: max(0, geoView.bounds.width - edgeInsets.left - edgeInsets.right),
                          height: max(0, geoView.bounds.height - edgeInsets.top - edgeInsets.bottom))
        return zone.contains(screenPoint)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
    }
}
