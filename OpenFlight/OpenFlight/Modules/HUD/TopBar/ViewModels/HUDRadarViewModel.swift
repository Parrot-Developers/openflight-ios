//
//  Copyright (C) 2020 Parrot Drones SAS.
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

import GroundSdk
import CoreLocation
import CoreMotion

// MARK: - HUDRadarState
/// State for HUDRadarViewModel

final class HUDRadarState: DevicesConnectionState {
    // MARK: - Internal Properties
    /// User heading, as returned by remote compass instrument when connected.
    /// Uses DeviceMotion to determine smartphone heading otherwise.
    fileprivate(set) var userHeading: Double?
    /// Drone heading, as returned by compass instrument.
    fileprivate(set) var droneHeading: Double?
    /// Drone gps location.
    fileprivate(set) var droneLocation: CLLocation?
    /// User gps location.
    fileprivate(set) var userLocation: CLLocation?

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - droneConnectionState: drone connection state
    ///    - remoteControlConnectionState: remote control connection state
    ///    - userHeading: remote heading
    ///    - droneHeading: drone heading
    ///    - droneLocation: drone gps location
    ///    - userLocation: user gps location
    init(droneConnectionState: DeviceConnectionState?,
         remoteControlConnectionState: DeviceConnectionState?,
         userHeading: Double?,
         droneHeading: Double?,
         droneLocation: CLLocation?,
         userLocation: CLLocation?) {
        super.init(droneConnectionState: droneConnectionState, remoteControlConnectionState: remoteControlConnectionState)
        self.userHeading = userHeading
        self.droneHeading = droneHeading
        self.droneLocation = droneLocation
        self.userLocation = userLocation
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DevicesConnectionState) -> Bool {
        guard let other = other as? HUDRadarState else {
            return false
        }
        return super.isEqual(to: other)
            && self.userHeading == other.userHeading
            && self.droneHeading == other.droneHeading
            && self.droneLocation == other.droneLocation
            && self.userLocation == other.userLocation
    }

    override func copy() -> HUDRadarState {
        let copy = HUDRadarState(droneConnectionState: self.droneConnectionState,
                                 remoteControlConnectionState: self.remoteControlConnectionState,
                                 userHeading: self.userHeading,
                                 droneHeading: self.droneHeading,
                                 droneLocation: self.droneLocation,
                                 userLocation: self.userLocation)
        return copy
    }
}

/// ViewModel for HUDRadar, notifies on remote/drone heading and gps location changes.

final class HUDRadarViewModel: DevicesStateViewModel<HUDRadarState> {

    // MARK: - Private Enums
    private enum Constants {
        static let deviceMotionUpdateInterval = 1/30.0
    }

    // MARK: - Private Properties
    private let groundSdk = GroundSdk()
    private var userLocationRef: Ref<UserLocation>?
    private var droneCompassRef: Ref<Compass>?
    private var droneGpsRef: Ref<Gps>?
    private var remoteControlCompassRef: Ref<Compass>?
    private var remoteStateRef: Ref<DeviceState>?
    private lazy var motionManager = CMMotionManager()
    private var orientationRight: Bool {
        return UIApplication.shared.statusBarOrientation == .landscapeRight
    }
    /// User heading in radians based on CoreMotion.
    private var userHeading: Double {
        guard let deviceMotion = motionManager.deviceMotion else { return 0 }
        if orientationRight {
            return -deviceMotion.attitude.yaw + (deviceMotion.attitude.yaw > 0 ? (2 * Double.pi) : 0)
        }
        return Double.pi - deviceMotion.attitude.yaw
    }

    // MARK: - Init
    override init(stateDidUpdate: ((HUDRadarState) -> Void)? = nil) {
        super.init(stateDidUpdate: stateDidUpdate)
        listenUserLocation()
        startDeviceMotionIfNeeded()
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)
        listenCompass(drone: drone)
        listenGps(drone: drone)
    }

    override func listenRemoteControl(remoteControl: RemoteControl) {
        super.listenRemoteControl(remoteControl: remoteControl)
        listenCompass(remoteControl: remoteControl)
    }

    override func remoteControlConnectionStateDidChange() {
        startDeviceMotionIfNeeded()
    }
}

// MARK: - Private Funcs
private extension HUDRadarViewModel {

    /// Starts DeviceMotion tracking when remoteControl is not connected.
    func startDeviceMotionIfNeeded() {
        #if DEBUG
        // Disable device motion updates due to CoreMotion's
        // thread issues with iPhones XR/XS running iOS 12.
        guard #available(iOS 13, *) else {
            return
        }
        #endif
        state.value.remoteControlConnectionState?.isConnected() == true ? stopTracking() : startTracking()
    }

    /// Starts DeviceMotion tracking.
    func startTracking() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = Constants.deviceMotionUpdateInterval
        motionManager.showsDeviceMovementDisplay = false
        motionManager.startDeviceMotionUpdates(using: .xTrueNorthZVertical, to: .main) { [weak self] _, _ in
            let copy = self?.state.value.copy()
            copy?.userHeading = self?.userHeading.toDegrees()
            self?.state.set(copy)
        }
    }

    /// Stops DeviceMotion tracking.
    func stopTracking() {
        motionManager.stopDeviceMotionUpdates()
    }

    /// Starts watcher for user location.
    func listenUserLocation() {
        userLocationRef = groundSdk.getFacility(Facilities.userLocation) { [weak self] userLocation in
            let copy = self?.state.value.copy()
            copy?.userLocation = userLocation?.location
            self?.state.set(copy)
        }
    }

    /// Starts watcher for drone compass.
    func listenCompass(drone: Drone) {
        droneCompassRef = drone.getInstrument(Instruments.compass) { [weak self] compass in
            let copy = self?.state.value.copy()
            copy?.droneHeading = compass?.heading
            self?.state.set(copy)
        }
    }

    /// Starts watcher for drone gps.
    func listenGps(drone: Drone) {
        droneGpsRef = drone.getInstrument(Instruments.gps) { [weak self] gps in
            let copy = self?.state.value.copy()
            copy?.droneLocation = gps?.lastKnownLocation
            self?.state.set(copy)
        }
    }

    /// Starts watcher for remote control compass.
    func listenCompass(remoteControl: RemoteControl) {
        remoteControlCompassRef = remoteControl.getInstrument(Instruments.compass) { [weak self] compass in
            let copy = self?.state.value.copy()
            copy?.userHeading = compass?.heading
            self?.state.set(copy)
        }
    }
}
