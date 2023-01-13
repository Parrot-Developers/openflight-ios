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

import GroundSdk
import Combine
import ArcGIS

private extension ULogTag {
    static let tag = ULogTag(name: "HomeLocationGraphicsOverlay")
}

/// A home location graphics overlay.
public final class HomeLocationGraphicsOverlay: CommonGraphicsOverlay {

    static let Key = "HomeLocationGraphicsOverlayKey"

    /// The view model.
    private var viewModel: HomeLocationGraphicsOverlayViewModel!
    /// The home point graphic.
    private var homePointGraphic: HomePointGraphic?

    /// Prohibits the use of constructor without services injection.
    @available(swift, obsoleted: 1, message: "Use init with services in parameters.")
    override public init() {}

    // MARK: - Init
    /// Constructor.
    ///
    /// - Parameters:
    ///    - rthService: the RTH service
    ///    - mapViewModel: the map view model (used to listen to mini-map publisher)
    public init(rthService: RthService, mapViewModel: CommonMapViewModel) {
        viewModel = HomeLocationGraphicsOverlayViewModel(rthService: rthService)

        super.init()

        sceneProperties?.surfacePlacement = .drapedFlat

        viewModel.$location.removeDuplicates()
            .combineLatest(viewModel.$indicatorState.removeDuplicates(),
                           mapViewModel.isMiniMapPublisher.removeDuplicates())
            .sink { [weak self] location, state, isMiniMap in
                self?.updateIndicator(at: location,
                                      state: state,
                                      size: isMiniMap ? .large : .regular)
            }
            .store(in: &cancellables)
    }
}

private extension HomeLocationGraphicsOverlay {

    /// Updates indicator graphic according to provided location and state.
    ///
    /// - Parameters:
    ///    - location: the indicator location
    ///    - state: the indicator state
    ///    - size: the indicator size
    func updateIndicator(at location: Location3D?, state: HomeIndicatorState, size: HomeIndicatorState.Size) {
        guard let location = location else {
            // Invalid location => remove graphic.
            remove()
            return
        }

        ULog.i(.tag, "Update indicator at \(location) | state: \(state) | size: \(size)")

        if homePointGraphic == nil {
            draw(at: location, image: state.image(size: size))
        } else {
            update(at: location, image: state.image(size: size))
        }
    }

    /// Removes current indicator (if existing) from graphics.
    func remove() {
        guard let homePointGraphic = homePointGraphic else { return }

        ULog.i(.tag, "Remove home point graphic")

        graphics.remove(homePointGraphic)
        self.homePointGraphic = nil
    }

    /// Draws a new home indicator.
    ///
    /// - Parameters:
    ///    - location: the location to draw the indicator at
    ///    - image: the indicator image
    func draw(at location: Location3D, image: UIImage) {
        // Remove any potential existing indicator before drawing a new one.
        remove()

        let homePointGraphic = HomePointGraphic(homeLocation: location.agsPoint,
                                                image: image)
        graphics.add(homePointGraphic)
        self.homePointGraphic = homePointGraphic
    }

    /// Updates home indicator with specific location and image.
    ///
    /// - Parameters:
    ///    - location: the location to draw the indicator at
    ///    - image: the indicator image
    func update(at location: Location3D, image: UIImage) {
        homePointGraphic?.geometry = location.agsPoint
        homePointGraphic?.updateSymbol(image: image)
    }
}
