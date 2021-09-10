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

import GroundSdk

/// State for `FlightPlanPhotoCountViewModel`.
final class FlightPlanPhotoCountState: ViewModelState, EquatableState, Copying {
    // MARK: - Internal Properties
    /// Returns number of photos taken during the flight plan.
    fileprivate(set) var photoNumber: Int?

    /// Returns the photo number description.
    var photoNumberDesc: String {
        guard let photoNumber = photoNumber else { return Style.dash }

        return "\(photoNumber)"
    }

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///     - photoNumber: photo number
    convenience init(photoNumber: Int?) {
        self.init()

        self.photoNumber = photoNumber
    }

    // MARK: - Copying
    func copy() -> FlightPlanPhotoCountState {
        return FlightPlanPhotoCountState(photoNumber: photoNumber)
    }

    // MARK: - Equatable
    func isEqual(to other: FlightPlanPhotoCountState) -> Bool {
        return self.photoNumber == other.photoNumber
    }
}

/// Flight plan photo count view model.
final class FlightPlanPhotoCountViewModel: DroneWatcherViewModel<FlightPlanPhotoCountState> {
    // MARK: - Private Properties
    private var flightModel: FlightPlanModel?
    private var mediaListRef: Ref<[MediaItem]>?

    // MARK: - Init
    /// Inits
    ///
    /// - Parameters:
    ///     - flightModel: current flight plan model
    init(flightModel: FlightPlanModel) {
        self.flightModel = flightModel

        super.init()
    }

    // MARK: - Deinit
    deinit {
        mediaListRef = nil
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        listenMedias(drone)
    }
}

// MARK: - Private Funcs
private extension FlightPlanPhotoCountViewModel {
    /// Starts watcher on MediaList from mediaStore peripherial.
    func listenMedias(_ drone: Drone) {
        mediaListRef = drone.getPeripheral(Peripherals.mediaStore)?.newList { [weak self] droneMediaList in
            guard let droneMedias = droneMediaList else { return }

            self?.updatePhotoCount(medias: droneMedias)
        }
    }

    /// Updates number of photos taken during a flight plan execution.
    ///
    /// - Parameters:
    ///     - medias: list of drone medias
    func updatePhotoCount(medias: [MediaItem]) {
        let correspondingMedias = medias.filter { $0.customId == flightModel?.uuid }
        let copy = state.value.copy()
        copy.photoNumber = correspondingMedias.count
        state.set(copy)
    }
}
