//
//  Copyright (C) 2021 Parrot Drones SAS.
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

/// Gimbal tilt service
public protocol GimbalTiltService: AnyObject {

    /// Tilt availability publisher
    var tiltIsAvailablePublisher: AnyPublisher<Bool, Never> { get }
    /// Current tilt value publisher
    var currentTiltPublisher: AnyPublisher<Double, Never> { get }
    /// Tilt validity range publisher
    var tiltRangePublisher: AnyPublisher<Range<Double>, Never> { get }
    /// Overtilt event publisher
    var overTiltEventPublisher: AnyPublisher<Bool, Never> { get }
    /// Undertilt event publisher
    var underTiltEventPublisher: AnyPublisher<Bool, Never> { get }
    /// Controls the gimbal tilt with given velocity.
    ///
    /// - Parameters:
    ///    - velocity: velocity (between -1.0 and 1.0)
    func setTiltVelocity(_ velocity: Double)
    /// Reset the gimbal tilt
    func resetTilt()
}

/// Implementation for `GimbalTiltService`
class GimbalTiltServiceImpl {

    /// Constants
    private enum Constants {
        static let defaultTiltPosition: Double = 0.0
        static let roundPrecision: Int = 2
    }

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var gimbalRef: Ref<Gimbal>?
    private var deviceStateRef: Ref<DeviceState>?
    private unowned var activeFlightPlanWatcher: ActiveFlightPlanExecutionWatcher
    private var tiltIsAvailableSubject = CurrentValueSubject<Bool, Never>(false)
    private var currentTiltSubject = CurrentValueSubject<Double, Never>(0)
    private var tiltRangeSubject = CurrentValueSubject<Range<Double>, Never>(-90..<90)
    private var overTiltEventSubject = PassthroughSubject<Bool, Never>()
    private var underTiltEventSubject = PassthroughSubject<Bool, Never>()
    private var isInOverTilt = false
    private var isInUnderTilt = false

    // MARK: - Init

    /// Init
    /// - Parameters:
    ///   - connectedDroneHolder: the connected drone holder
    ///   - activeFlightPlanWatcher: the active flight plan watcher
    init(connectedDroneHolder: ConnectedDroneHolder,
         activeFlightPlanWatcher: ActiveFlightPlanExecutionWatcher) {
        self.activeFlightPlanWatcher = activeFlightPlanWatcher
        activeFlightPlanWatcher.hasActiveFlightPlanWithTimeOrGpsLapsePublisher
            .sink { [unowned self] _ in
                setAvailability()
            }
            .store(in: &cancellables)
        connectedDroneHolder.dronePublisher.sink { [unowned self] in
            guard let drone = $0 else {
                setAvailability()
                return
            }
            listenGimbal(drone: drone)
        }
        .store(in: &cancellables)
    }
}

private extension GimbalTiltServiceImpl {

    /// Set the tilt availability
    func setAvailability() {
        let gimbal = gimbalRef?.value != nil
        let activeFlightPlanWithTimeOrGpsLapse = activeFlightPlanWatcher.hasActiveFlightPlanWithTimeOrGpsLapse
        tiltIsAvailableSubject.send(gimbal && !activeFlightPlanWithTimeOrGpsLapse)
    }

    /// Starts watcher for gimbal.
    func listenGimbal(drone: Drone) {
        gimbalRef = drone.getPeripheral(Peripherals.gimbal) { [unowned self] gimbal in
            setAvailability()
            guard let gimbal = gimbal else {
                return
            }
            currentTiltSubject.value = gimbal.currentAttitude[.pitch] ?? Constants.defaultTiltPosition
            if let range = gimbal.attitudeBounds[.pitch] {
                tiltRangeSubject.value = range
            }
            checkOvertilt(gimbal)
        }
    }

    /// Checks if zoom max is reached
    func checkOvertilt(_ gimbal: Gimbal) {
        let range = tiltRangeSubject.value
        let roundedMax = range.upperBound.rounded(toPlaces: Constants.roundPrecision)
        let roundedMin = range.lowerBound.rounded(toPlaces: Constants.roundPrecision)
        let roundedCurrent = currentTiltSubject.value.rounded(toPlaces: Constants.roundPrecision)
        if roundedCurrent >= roundedMax {
            if !isInOverTilt {
                isInOverTilt = true
                overTiltEventSubject.send(true)
            }
        } else {
            isInOverTilt = false
        }
        if roundedCurrent <= roundedMin {
            if !isInUnderTilt {
                isInUnderTilt = true
                underTiltEventSubject.send(true)
            }
        } else {
            isInUnderTilt = false
        }
    }
}

/// `GimbalTiltService` conformance
extension GimbalTiltServiceImpl: GimbalTiltService {

    var tiltIsAvailablePublisher: AnyPublisher<Bool, Never> { tiltIsAvailableSubject.eraseToAnyPublisher() }

    var currentTiltPublisher: AnyPublisher<Double, Never> { currentTiltSubject.eraseToAnyPublisher() }

    var tiltRangePublisher: AnyPublisher<Range<Double>, Never> { tiltRangeSubject.eraseToAnyPublisher() }

    var overTiltEventPublisher: AnyPublisher<Bool, Never> { overTiltEventSubject.eraseToAnyPublisher() }

    var underTiltEventPublisher: AnyPublisher<Bool, Never> { underTiltEventSubject.eraseToAnyPublisher() }

    func setTiltVelocity(_ velocity: Double) {
        let range = tiltRangeSubject.value
        let roundedMax = range.upperBound.rounded(toPlaces: Constants.roundPrecision)
        let roundedMin = range.lowerBound.rounded(toPlaces: Constants.roundPrecision)
        let roundedCurrent = currentTiltSubject.value.rounded(toPlaces: Constants.roundPrecision)
        if velocity > 0, roundedCurrent >= roundedMax {
            overTiltEventSubject.send(true)
            return
        }
        if velocity < 0, roundedCurrent <= roundedMin {
            underTiltEventSubject.send(true)
            return
        }
        guard tiltIsAvailableSubject.value else { return }
        gimbalRef?.value?.control(mode: .velocity,
                       yaw: nil,
                       pitch: velocity,
                       roll: nil)
    }

    func resetTilt() {
        gimbalRef?.value?.resetAttitude()
    }
}
