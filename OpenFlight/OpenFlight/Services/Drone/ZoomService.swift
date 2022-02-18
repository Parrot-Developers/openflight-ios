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
import GroundSdk

/// Drone camera zoom service
public protocol ZoomService: AnyObject {
    // MARK: - Zoom values
    /// Current zoom value
    var currentZoomPublisher: AnyPublisher<Double, Never> { get }
    /// Minimum zoom value
    var minZoom: Double { get }
    /// Max zoom considering lossy allowance parameter
    var maxZoomPublisher: AnyPublisher<Double, Never> { get }
    /// Max lossless zoom value
    var maxLosslessZoomPublisher: AnyPublisher<Double, Never> { get }
    /// Max lossy zoom (overall max)
    var maxLossyZoomPublisher: AnyPublisher<Double, Never> { get }

    // MARK: - Other state parameters
    /// Is zoom available in the current context
    var isZoomAvailablePublisher: AnyPublisher<Bool, Never> { get }
    /// Is lossy zoom allowed
    var lossyZoomAllowedPublisher: AnyPublisher<Bool, Never> { get }
    /// Sends true when overzooming occurs
    var overzoomingEventPublisher: AnyPublisher<Bool, Never> { get }

    // MARK: - Actions
    /// Start zooming in
    func startZoomIn()
    /// Stop zooming in
    func stopZoomIn()
    /// Start zooming out
    func startZoomOut()
    /// Stop zooming out
    func stopZoomOut()
    /// Reset zoom
    func resetZoom()
    /// Allow or forbid lossy zoom applying zoom velocity quality mode
    /// - Parameter mode: the mode to apply
    func setQualityMode(_ mode: Camera2ZoomVelocityControlQualityMode)
    /// Controls the camera zoom with given velocity.
    ///
    /// - Parameters:
    ///    - velocity: velocity (between -1.0 and 1.0)
    func setZoomVelocity(_ velocity: Double)
}

/// Implementation for `ZoomService`
class ZoomServiceImpl {

    // MARK: - Constants
    private enum Constants {
        static let roundPrecision: Int = 2
        static let minZoom: Double = 1.0
        static let defaultZoomInVelocity: Double = 1.0
        static let defaultZoomOutVelocity: Double = -1.0
    }

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var cameraRef: Ref<MainCamera2>?
    private var zoomRef: Ref<Camera2Zoom>?
    private unowned var activeFlightPlanWatcher: ActiveFlightPlanExecutionWatcher
    private var currentZoomSubject = CurrentValueSubject<Double, Never>(1)
    private var maxLosslessZoomSubject = CurrentValueSubject<Double, Never>(3.0)
    private var maxLossyZoomSubject = CurrentValueSubject<Double, Never>(1.4)
    private var maxZoomSubject = CurrentValueSubject<Double, Never>(1.4)
    private var isZoomAvailableSubject = CurrentValueSubject<Bool, Never>(false)
    private var lossyZoomAllowedSubject = CurrentValueSubject<Bool, Never>(false)
    private var overzoomingEventSubject = PassthroughSubject<Bool, Never>()
    private var overzoomingSubject = CurrentValueSubject<Bool, Never>(false)

    // MARK: - Internal properties
    let minZoom = Constants.minZoom

    // MARK: - Init

    /// Init
    /// - Parameters:
    ///     - currentDroneHolder: the current drone holder
    ///     - activeFlightPlanWatcher: the active flight plan watcher
    init(currentDroneHolder: CurrentDroneHolder,
         activeFlightPlanWatcher: ActiveFlightPlanExecutionWatcher) {
        self.activeFlightPlanWatcher = activeFlightPlanWatcher
        currentDroneHolder.dronePublisher.sink { [unowned self] in
            listenCamera(drone: $0)
        }
        .store(in: &cancellables)

        lossyZoomAllowedPublisher.combineLatest(maxLosslessZoomPublisher, maxLossyZoomPublisher)
            .sink { [unowned self] (lossyAllowed, maxLossless, maxLossy) in
                maxZoomSubject.value = lossyAllowed ? maxLossy : maxLossless
            }
            .store(in: &cancellables)

        activeFlightPlanWatcher.hasActiveFlightPlanWithTimeOrGpsLapsePublisher
            .removeDuplicates()
            .sink { [unowned self] _ in
                setAvailability()
                checkMaxZoom()
            }
            .store(in: &cancellables)
    }
}

private extension ZoomServiceImpl {

    /// Set the zoom availability
    func setAvailability() {
        let hasZoom = cameraRef?.value?.zoom != nil
        let hasTimeOrGpsLapse: Bool
        if let camera = cameraRef?.value, let mode = camera.mode {
            switch mode {
            case .recording:
                hasTimeOrGpsLapse = false
            case .photo:
                if let photoMode = camera.config[Camera2Params.photoMode]?.value {
                    switch photoMode {
                    case .single, .bracketing, .burst:
                        hasTimeOrGpsLapse = false
                    case .timeLapse, .gpsLapse:
                        hasTimeOrGpsLapse = true
                    }
                } else {
                    hasTimeOrGpsLapse = false
                }
            }
        } else {
            hasTimeOrGpsLapse = false
        }
        let activeFlightPlanWithTimeOrGpsLapse = activeFlightPlanWatcher.hasActiveFlightPlanWithTimeOrGpsLapse
        isZoomAvailableSubject.send(hasZoom && !activeFlightPlanWithTimeOrGpsLapse && !hasTimeOrGpsLapse)
    }

    /// Starts watcher for camera.
    func listenCamera(drone: Drone) {
        // reset zoom component reference on drone change
        zoomRef = nil

        cameraRef = drone.getPeripheral(Peripherals.mainCamera2) { [unowned self] camera in
            guard let camera = camera else {
                setAvailability()
                return
            }

            lossyZoomAllowedSubject.value = camera.config[Camera2Params.zoomVelocityControlQualityMode]?.value.isLossyAllowed == true
            listenZoom(camera: camera)
        }
    }

    /// Starts watching for camera zoom component.
    ///
    /// - Parameters:
    ///    - camera: the camera
    func listenZoom(camera: Camera2) {
        // do not register zoom observer if not needed
        guard zoomRef?.value == nil else { return }

        zoomRef = camera.getComponent(Camera2Components.zoom) { [unowned self] zoom in
            setAvailability()
            guard let zoom = zoom else {
                return
            }
            maxLosslessZoomSubject.value = zoom.maxLossLessLevel
            maxLossyZoomSubject.value = zoom.maxLevel
            currentZoomSubject.value = zoom.level
            checkMaxZoom()
        }
    }

    /// Checks if zoom max is reached.
    func checkMaxZoom() {
        let roundedMax = maxZoomSubject.value.rounded(toPlaces: Constants.roundPrecision)
        let roundedCurrent = currentZoomSubject.value.rounded(toPlaces: Constants.roundPrecision)
        overzoomingSubject.value = roundedCurrent >= roundedMax
        if roundedCurrent > roundedMax {
            zoomRef?.value?.control(mode: .level, target: maxZoomSubject.value)
        }
    }
}

extension ZoomServiceImpl: ZoomService {

    var currentZoomPublisher: AnyPublisher<Double, Never> { currentZoomSubject.eraseToAnyPublisher() }

    var maxZoomPublisher: AnyPublisher<Double, Never> { maxZoomSubject.eraseToAnyPublisher() }

    var maxLosslessZoomPublisher: AnyPublisher<Double, Never> { maxLosslessZoomSubject.eraseToAnyPublisher() }

    var maxLossyZoomPublisher: AnyPublisher<Double, Never> { maxLossyZoomSubject.eraseToAnyPublisher() }

    var isZoomAvailablePublisher: AnyPublisher<Bool, Never> { isZoomAvailableSubject.eraseToAnyPublisher() }

    var lossyZoomAllowedPublisher: AnyPublisher<Bool, Never> { lossyZoomAllowedSubject.eraseToAnyPublisher() }

    var overzoomingEventPublisher: AnyPublisher<Bool, Never> {
        overzoomingSubject.removeDuplicates()
            .filter { $0 }
            .merge(with: overzoomingEventSubject)
            // do not trigger overzooming event when zoom is unavailable
            .filter { [unowned self] _ in isZoomAvailableSubject.value }
            .eraseToAnyPublisher()
    }

    func startZoomIn() {
        setZoomVelocity(Constants.defaultZoomInVelocity)
    }

    func stopZoomIn() {
        setZoomVelocity(0)
    }

    func startZoomOut() {
        setZoomVelocity(Constants.defaultZoomOutVelocity)
    }

    func stopZoomOut() {
        setZoomVelocity(0)
    }

    func resetZoom() {
        guard let zoom: Camera2Zoom = zoomRef?.value else { return }
        zoom.resetLevel()
    }

    func setQualityMode(_ mode: Camera2ZoomVelocityControlQualityMode) {
        guard let camera = cameraRef?.value else { return }
        let currentEditor = camera.currentEditor
        let currentConfig = camera.config
        currentEditor[Camera2Params.zoomVelocityControlQualityMode]?.value = mode
        currentEditor.saveSettings(currentConfig: currentConfig)
    }

    func setZoomVelocity(_ velocity: Double) {
        guard let zoom: Camera2Zoom = zoomRef?.value else { return }
        let max = maxZoomSubject.value
        let roundedMax = max.rounded(toPlaces: Constants.roundPrecision)
        let roundedMin = minZoom.rounded(toPlaces: Constants.roundPrecision)
        let roundedCurrent = currentZoomSubject.value.rounded(toPlaces: Constants.roundPrecision)
        if velocity > 0, roundedCurrent >= roundedMax {
            overzoomingEventSubject.send(true)
            return
        }
        if velocity < 0, roundedCurrent <= roundedMin {
            return
        }
        guard isZoomAvailableSubject.value else { return }

        zoom.control(mode: .velocity, target: velocity)
    }
}
