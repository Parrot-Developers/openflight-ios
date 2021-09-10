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

import Combine
import GroundSdk

/// View model for imaging settings bar ev compensation item.
final class ImagingBarEvCompensationViewModel: BarButtonViewModel<ImagingBarState> {
    // MARK: - Private Properties

    /// Available EV compensation values count.
    @Published private var availableValuesCount = 0
    /// Whether exposure mode is full manual.
    @Published private var exposureModeManual = false
    /// Camera peripheral reference.
    private var cameraRef: Ref<MainCamera2>?
    /// Camera exposure lock service.
    private unowned var exposureLockService: ExposureLockService
    /// Combine subscriptions.
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Override Funcs

    /// Constructor.
    ///
    /// - Parameter exposureLockService: camera exposure lock service
    init(exposureLockService: ExposureLockService) {
        self.exposureLockService = exposureLockService
        super.init(barId: "EvCompensation")

        // compute EV compensation setting availability
        exposureLockService.statePublisher
            .combineLatest($exposureModeManual, $availableValuesCount)
            .sink { [unowned self] exposureLockState, exposureModeManual, availableValuesCount in
                let copy = state.value.copy()
                copy.enabled = !exposureLockState.locked
                    && !exposureLockState.locking
                    && !exposureModeManual
                    && availableValuesCount > 1
                state.set(copy)
                if !copy.enabled {
                    // autoclose if necessary
                    state.value.isSelected.set(false)
                }
            }
            .store(in: &cancellables)
    }

    override func listenDrone(drone: Drone) {
        listenCamera(drone: drone)
    }

    override func update(mode: BarItemMode) {
        guard let camera = drone?.currentCamera,
            !camera.config.updating,
            let evCompensation = mode as? Camera2EvCompensation
            else {
                return
        }
        let currentEditor = camera.currentEditor
        currentEditor[Camera2Params.exposureCompensation]?.value = evCompensation
        currentEditor.saveSettings(currentConfig: camera.config)
    }
}

// MARK: - Private Funcs
private extension ImagingBarEvCompensationViewModel {
    /// Starts watcher for camera.
    func listenCamera(drone: Drone) {
        cameraRef = drone.getPeripheral(Peripherals.mainCamera2) { [unowned self] camera in
            guard let camera = camera,
                let exposureCompensation = camera.config[Camera2Params.exposureCompensation],
                let exposureMode = camera.config[Camera2Params.exposureMode] else {
                return
            }

            let copy = state.value.copy()
            copy.mode = exposureCompensation.value
            copy.supportedModes = exposureCompensation.currentSupportedValues.sorted()
            state.set(copy)
            availableValuesCount = exposureCompensation.currentSupportedValues.count
            exposureModeManual = exposureMode.value == .manual
        }
    }
}
