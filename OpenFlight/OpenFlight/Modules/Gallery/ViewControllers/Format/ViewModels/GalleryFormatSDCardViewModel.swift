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
import Combine

/// ViewModel for SDCard formatting.

final class GalleryFormatSDCardViewModel: NSObject {

    // MARK: - Published Properties
    @Published private(set) var isFlying: Bool = false

    // MARK: - Private Properties
    private weak var galleryViewModel: GalleryMediaViewModel?
    private var sdCardListener: GallerySdMediaListener?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?
    private var currentDrone = Services.hub.currentDroneHolder
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Internal Properties
    var selectedFormattingType: FormattingType = .quick
    var canFormat: Bool {
        return galleryViewModel?.sdCardViewModel?.state.value.canFormat ?? false
    }

    // MARK: - Private Enums
    private enum Constants {
        static let partitioningMaxPercentage: Float = 10.0
        static let newPartitionMinPercentage: Float = 90.0
    }

    // MARK: - Deinit
    deinit {
        galleryViewModel?.sdCardViewModel?.unregisterListener(sdCardListener)
    }

    // MARK: - Init
    ///
    /// - Parameters:
    ///    - galleryViewModel: gallery view model
    init(galleryViewModel: GalleryMediaViewModel?) {
        super.init()
        self.galleryViewModel = galleryViewModel
        currentDrone.dronePublisher
            .sink { [unowned self] drone in
                listenFlyingState(drone: drone)
            }
            .store(in: &cancellables)
    }
}

// MARK: - Internal Funcs
extension GalleryFormatSDCardViewModel {
    /// Format SD Card.
    func format() {
        galleryViewModel?.sdCardViewModel?.format(selectedFormattingType)
    }

    /// Called when we need to start listening to the formatting progress.
    ///
    /// - Parameters:
    ///    - block: block to execute for each update
    func startListeningToFormattingProgress(_ block: @escaping (FormattingStep, Float, FormattingState) -> Void) {
        sdCardListener = galleryViewModel?.sdCardViewModel?.registerListener(didChange: { state in
            guard let formattingProgress = state.formattingProgress,
                let formattingState = state.formattingState,
                let formattingStep = state.formattingStep else {
                    return
            }
            let formattingProgressAsFloat: Float = Float(formattingProgress) / 100.0
            var currentShare: Float = 0.0
            var currentShareStart: Float = 0.0
            var displayedProgress: Float = 0.0
            switch formattingStep {
            case .partitioning:
                currentShareStart = 0.0
                currentShare = Constants.partitioningMaxPercentage / 100.0
            case .clearingData:
                currentShareStart = Constants.partitioningMaxPercentage / 100.0
                currentShare = (Constants.newPartitionMinPercentage - Constants.partitioningMaxPercentage) / 100.0
            case .creatingFs:
                currentShareStart = Constants.newPartitionMinPercentage / 100.0
                currentShare = (100.0 - Constants.newPartitionMinPercentage) / 100.0
                if formattingProgress == 100 {
                    self.formatCompleted()
                }
            }
            displayedProgress = currentShareStart + formattingProgressAsFloat * currentShare
            block(formattingStep, displayedProgress, formattingState)
        })
    }

    /// Starts observing changes for flying indicators and updates the flyingState published property.
    ///
    /// - Parameter drone: The current drone
    func listenFlyingState(drone: Drone) {
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [weak self] flyingIndicator in
            if flyingIndicator?.flyingState == .flying || flyingIndicator?.flyingState == .waiting {
                self?.isFlying = true
            } else {
                self?.isFlying = false
            }
        }
    }

    /// Called when we need to stop listening to the formatting progress.
    func stopListeningToFormattingProgress() {
        galleryViewModel?.sdCardViewModel?.unregisterListener(sdCardListener)
    }

    /// Called when format process is completed.
    func formatCompleted() {
        galleryViewModel?.sdCardViewModel?.formatCompleted()
    }
}
