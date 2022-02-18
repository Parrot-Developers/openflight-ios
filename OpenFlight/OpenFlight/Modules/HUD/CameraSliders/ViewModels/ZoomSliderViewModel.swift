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

/// Delegate
protocol ZoomSliderViewModelDelegate: AnyObject {
    func onZoomSliderUserAction()
}

/// ViewModel for ZoomSliderView
class ZoomSliderViewModel {

    /// State of the view
    struct State {
        let min: Float
        let max: Float
        let overLimit: Float
        let value: Float
    }

    // MARK: - Private Properties
    private weak var delegate: ZoomSliderViewModelDelegate?
    private var cancellables = Set<AnyCancellable>()
    private unowned var service: ZoomService

    // MARK: - Internal Properties
    @Published private(set) var state: State = State(min: 0, max: 0, overLimit: 0, value: 0)

    /// Init
    /// - Parameters:
    ///   - zoomService: the zoom service
    ///   - delegate: the delegate
    init(zoomService: ZoomService, delegate: ZoomSliderViewModelDelegate) {
        self.service = zoomService
        self.delegate = delegate
        listenService()
    }
}

// MARK: - Private Functions
private extension ZoomSliderViewModel {

    /// Listen to service publisher
    func listenService() {
        let minZoom = service.minZoom
        service.currentZoomPublisher
            .combineLatest(service.maxZoomPublisher, service.maxLosslessZoomPublisher)
            .sink { [unowned self] (currentZoom, maxZoom, maxLosslessZoom) in
                state = State(min: Float(minZoom),
                              max: Float(maxZoom),
                              overLimit: Float(maxLosslessZoom),
                              value: Float(currentZoom))
            }
            .store(in: &cancellables)
    }
}

// MARK: - Actions
extension ZoomSliderViewModel {

    func plusButtonHoldDown() {
        service.startZoomIn()
        delegate?.onZoomSliderUserAction()
    }

    func minusButtonHoldDown() {
        service.startZoomOut()
        delegate?.onZoomSliderUserAction()
    }

    func plusButtonTouchedUp() {
        service.stopZoomIn()
        delegate?.onZoomSliderUserAction()
    }

    func minusButtonTouchedUp() {
        service.stopZoomOut()
        delegate?.onZoomSliderUserAction()
    }

    func onDoubleTap() {
        service.resetZoom()
        delegate?.onZoomSliderUserAction()
    }
}
