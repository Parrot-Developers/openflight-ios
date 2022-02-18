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

import GroundSdk

// MARK: - Protocols
/// Protocol describing location manager interface.

protocol LocationManager {
    /// Completion block called when a location update is available.
    var onLocationUpdate: (() -> Void)? { get set }
}

/// Manager that provides a callback to listener everytime user location gets updated
/// or when last provided location has expired.

public final class UserLocationManager: LocationManager {
    // MARK: - Public Properties
    public var onLocationUpdate: (() -> Void)?

    // MARK: - Private Properties
    private let groundSdk = GroundSdk()
    private var userLocationRef: Ref<UserLocation>?
    private var gpsValidityTimer: Timer?

    // MARK: - Init
    public init() {
        userLocationRef = groundSdk.getFacility(Facilities.userLocation) { [weak self] userLocation in
            guard let userLocation = userLocation else {
                return
            }
            self?.gpsValidityTimer = nil
            if userLocation.isGpsActive, let validityTimerDuration = userLocation.remainingFixedTime {
                /// When UserLocation is fixed, it is considered valid only for a given time.
                /// Timer fires only if UserLocation never gets updated afterwards,
                /// notifying listeners that UserLocation validity has changed.
                self?.gpsValidityTimer = Timer.scheduledTimer(withTimeInterval: validityTimerDuration,
                                                              repeats: false,
                                                              block: { _ in
                                                                self?.onLocationUpdate?()
                })
            }
            self?.onLocationUpdate?()
        }
    }
}
