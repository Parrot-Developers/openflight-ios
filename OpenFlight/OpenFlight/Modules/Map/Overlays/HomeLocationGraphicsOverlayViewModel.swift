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

import Combine
import ArcGIS
import GroundSdk

/// Home indicator state.
public enum HomeIndicatorState {

    /// Active state (nominal).
    case active
    /// Degraded state (reflects an unsual but non-critical state).
    case degraded
    /// Error state (critical).
    case error
    /// Hidden state.
    case hidden

    /// Indicator size.
    enum Size {
        case regular, large
    }

    /// The image to use for home graphic according to state.
    ///
    /// - Parameter size: the size of the image (`regular` or `large`)
    func image(size: Size) -> UIImage {
        switch self {
        case .active, .hidden:
            return size == .regular ? Asset.Map.icHome.image : Asset.Map.icHomeLarge.image
        case .degraded:
            return size == .regular ? Asset.Map.icHomeWarning.image : Asset.Map.icHomeWarningLarge.image
        case .error:
            return size == .regular ? Asset.Map.icHomeCritical.image : Asset.Map.icHomeCriticalLarge.image
        }
    }
}

/// A home location indicator view model.
public class HomeLocationGraphicsOverlayViewModel {

    /// The home location.
    @Published private(set) var location: Location3D?
    /// The indicator state.
    @Published private(set) var indicatorState: HomeIndicatorState = .active

    /// Combine cancellables
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    /// Constructor.
    ///
    /// - Parameter rthService: the RTH service
    init(rthService: RthService) {
        listen(to: rthService)
    }
}

private extension HomeLocationGraphicsOverlayViewModel {

    /// Listens to RTH service and update indicator state accordingly.
    ///
    /// - Parameter rthService: the RTH service
    func listen(to rthService: RthService) {
        rthService.homeDestinationPublisher
            .combineLatest(rthService.homeIndicatorStatePublisher)
            .sink { [weak self] homeDestination, indicatorState in
                self?.updateHomeState(homeLocation: homeDestination?.location,
                                      indicatorState: indicatorState)
            }
            .store(in: &cancellables)
    }

    /// Updates home state according to provided parameters.
    ///
    /// - Parameters:
    ///    - homeLocation: the home indicator location
    ///    - indicatorState: the home indicator state
    func updateHomeState(homeLocation: Location3D?, indicatorState: HomeIndicatorState) {
        guard indicatorState != .hidden else {
            // Indicator is hidden => clear location.
            location = nil
            return
        }

        // Update indicator state.
        self.indicatorState = indicatorState

        // Update location.
        if let homeLocation = homeLocation {
            location = homeLocation
        }
    }
}
