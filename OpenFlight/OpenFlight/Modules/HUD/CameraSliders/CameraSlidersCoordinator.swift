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

/// Coordinator for the camera sliders views
class CameraSlidersCoordinator {

    private weak var viewController: CameraSlidersViewController?
    private weak var viewModel: CameraSlidersViewModel?
    private unowned var services: ServiceHub

    /// Init
    /// - Parameters:
    ///   - services: services hub
    ///   - viewController: the camera sliders view controller
    init(services: ServiceHub, viewController: CameraSlidersViewController) {
        self.viewController = viewController
        self.services = services
        let viewModel = CameraSlidersViewModel(joysticksAvailabilityService: services.ui.joysticksAvailabilityService,
                                               zoomService: services.drone.zoomService,
                                               tiltService: services.drone.gimbalTiltService)
        self.viewModel = viewModel
        viewController.viewModel = viewModel
        viewController.coordinator = self
    }

    func zoomSliderViewModel() -> ZoomSliderViewModel {
        return ZoomSliderViewModel(zoomService: services.drone.zoomService, delegate: self)
    }

    func gimbalTiltSliderViewModel() -> GimbalTiltSliderViewModel {
        return GimbalTiltSliderViewModel(service: services.drone.gimbalTiltService, delegate: self)
    }
}

extension CameraSlidersCoordinator: ZoomSliderViewModelDelegate {
    func onZoomSliderUserAction() {
        viewModel?.keepZoomSliderOpenedForATime()
    }
}

extension CameraSlidersCoordinator: GimbalTiltSliderViewModelDelegate {
    func onGimbalTiltSliderStartInteraction() {
        viewModel?.keepGimbalTiltSliderOpened()
    }

    func onGimbalTiltSliderStopInteraction() {
        viewModel?.scheduleGimbalSliderHiding()
    }
}
