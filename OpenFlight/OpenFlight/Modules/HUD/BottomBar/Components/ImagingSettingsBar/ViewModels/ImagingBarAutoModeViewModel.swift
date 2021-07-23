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
import SwiftyUserDefaults

/// State for `ImagingBarAutoModeViewModel`.
final class ImagingBarAutoModeState: ViewModelState, EquatableState, Copying {
    // MARK: - Private Properties
    /// Boolean describing auto mode state.
    fileprivate(set) var isActive = false
    /// Image for current state.
    var image: UIImage {
        return isActive
            ? Asset.BottomBar.Icons.iconManualAutoAuto.image
            : Asset.BottomBar.Icons.iconManualAutoManual.image
    }
    var imageTintColor: UIColor {
        return isActive
            ? .white
            : ColorName.defaultTextColor.color
    }

    // MARK: - Init
    required init() { }

    init(isActive: Bool) {
        self.isActive = isActive
    }

    // MARK: - Internal Funcs
    func isEqual(to other: ImagingBarAutoModeState) -> Bool {
        return self.isActive == other.isActive
    }

    // MARK: - Copying
    func copy() -> ImagingBarAutoModeState {
        return ImagingBarAutoModeState(isActive: self.isActive)
    }
}

/// View model for imaging bar auto mode setting. In this mode exposure settings
/// and white balance settings are all monitored automatically.

final class ImagingBarAutoModeViewModel: DroneWatcherViewModel<ImagingBarAutoModeState> {
    // MARK: - Private Properties
    private var cameraRef: Ref<MainCamera2>?

    // MARK: - Init
    override init() {
        super.init()
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        listenCamera(drone: drone)
    }

    // MARK: - Internal Funcs
    /// Toggle auto mode.
    func toggleAutoMode() {
        if let camera = drone?.currentCamera,
           let exposureMode = camera.config[Camera2Params.exposureMode]?.value {
            let editor = camera.currentEditor
            editor[Camera2Params.exposureMode]?.value = exposureMode.automaticIsoAndShutterSpeed ?
                .manual : exposureMode.toAutomaticMode()
            editor.saveSettings(currentConfig: camera.config)
        }
    }
}

// MARK: - Private Funcs
private extension ImagingBarAutoModeViewModel {
    /// Starts watcher for camera.
    ///
    /// - Parameter drone: drone to observe
    func listenCamera(drone: Drone) {
        cameraRef = drone.getPeripheral(Peripherals.mainCamera2) { [unowned self] camera in
            guard let camera = camera,
                  let exposureMode = camera.config[Camera2Params.exposureMode] else {
                return
            }

            let copy = state.value.copy()
            copy.isActive = exposureMode.value.automaticIsoAndShutterSpeed
            state.set(copy)
        }
    }
}
