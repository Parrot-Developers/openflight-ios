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

/// Delegate protocol for `GimbalTiltSliderViewModel`
protocol GimbalTiltSliderViewModelDelegate: AnyObject {

    /// Called when the user starts interacting with the slider
    func onGimbalTiltSliderStartInteraction()
    /// Called when the user stops interacting with the slider
    func onGimbalTiltSliderStopInteraction()
}

/// ViewModel for `GimbalTiltSliderView`
class GimbalTiltSliderViewModel {

    private unowned var service: GimbalTiltService
    private weak var delegate: GimbalTiltSliderViewModelDelegate?

    init(service: GimbalTiltService, delegate: GimbalTiltSliderViewModelDelegate) {
        self.service = service
        self.delegate = delegate
    }
}

extension GimbalTiltSliderViewModel {

    /// Tilt value publisher
    var tiltValue: AnyPublisher<Double, Never> { service.currentTiltPublisher }

    /// Tilt upper bound publisher
    var tiltUpperBound: AnyPublisher<Double, Never> { service.tiltRangePublisher.map { $0.upperBound }.eraseToAnyPublisher() }

    /// Called when gimbal pitch velocity should be updated.
    ///
    /// - Parameters:
    ///    - velocity: new velocity to apply
    func setPitchVelocity(_ velocity: Double) {
        service.setTiltVelocity(velocity)
    }

    /// Called on double tap on the slider
    func onDoubleTap() {
        service.resetTilt()
    }

    /// Called when user starts interacting with slider.
    func onStartInteraction() {
        delegate?.onGimbalTiltSliderStartInteraction()
    }

    /// Called when user stops interacting with slider.
    func onStopInteraction() {
        delegate?.onGimbalTiltSliderStopInteraction()
    }
}
