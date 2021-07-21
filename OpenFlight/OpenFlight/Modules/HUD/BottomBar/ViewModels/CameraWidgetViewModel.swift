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

import UIKit
import GroundSdk
import SwiftyUserDefaults

/// State for `CameraWidgetViewModel`.

class CameraWidgetState: BarButtonState, EquatableState, Copying {
    // MARK: - Internal Properties
    /// Observable for bottom bar item selection.
    var isSelected: Observable<Bool>
    /// String representing camera resolution in recording mode, photo format in photo mode.
    var labelCameraSpecificProperty1: String
    /// String representing camera fps in recording mode.
    var labelCameraSpecificProperty2: String?
    /// String representing camera shutter speed.
    var labelShutterSpeed: String
    /// String representing camera exposure compensation.
    var labelExposureCompensation: String
    /// Color representing camera exposure compensation.
    var exposureColor: Color
    /// Boolean to determine if camera is in photo mode or recording mode.
    var isPhotoMode: Bool
    /// Boolean to indicate if photo signature is activated.
    var isPhotoSignatureEnabled: Bool

    var title: String?
    var subtext: String?
    var image: UIImage?
    var mode: BarItemMode?
    var supportedModes: [BarItemMode]?
    var showUnsupportedModes: Bool = false
    var subMode: BarItemSubMode?
    var subtitle: String?
    var enabled: Bool = true
    var unavailableReason: [String: String] = [:]

    // MARK: - Init
    required init() {
        isSelected = Observable(false)
        self.labelCameraSpecificProperty1 = Style.dash
        self.labelShutterSpeed = Style.dash
        self.labelExposureCompensation = Style.dash
        self.exposureColor = ColorName.white50.color
        self.isPhotoMode = false
        self.isPhotoSignatureEnabled = true
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - labelCameraSpecificProperty1: string representing camera resolution in recording mode, photo format in photo mode
    ///    - labelCameraSpecificProperty2: string representing camera fps in recording mode
    ///    - labelShutterSpeed: string representing camera shutter speed
    ///    - labelExposureCompensation: string representing camera exposure compensation
    ///    - exposureColor: color representing camera exposure compensation
    ///    - isPhotoMode: boolean to determine if camera is in photo mode or recording mode
    ///    - isPhotoSignatureEnabled: boolean to indicate if photo signature is activated
    ///    - isSelected: observable for bottom bar item selection
    init(labelCameraSpecificProperty1: String,
         labelCameraSpecificProperty2: String? = nil,
         labelShutterSpeed: String,
         labelExposureCompensation: String,
         exposureColor: Color,
         isPhotoMode: Bool,
         isPhotoSignatureEnabled: Bool,
         isSelected: Observable<Bool>) {
        self.labelCameraSpecificProperty1 = labelCameraSpecificProperty1
        self.labelCameraSpecificProperty2 = labelCameraSpecificProperty2
        self.labelShutterSpeed = labelShutterSpeed
        self.labelExposureCompensation = labelExposureCompensation
        self.exposureColor = exposureColor
        self.isPhotoMode = isPhotoMode
        self.isPhotoSignatureEnabled = isPhotoSignatureEnabled
        self.isSelected = isSelected
    }

    /// Updates state.
    ///
    /// - Parameters:
    ///    - labelCameraSpecificProperty1: string representing camera resolution in recording mode, photo format in photo mode
    ///    - labelCameraSpecificProperty2: string representing camera fps in recording mode
    ///    - labelShutterSpeed: string representing camera shutter speed
    ///    - labelExposureCompensation: string representing camera exposure compensation
    ///    - exposureColor: color representing camera exposure compensation
    ///    - isPhotoMode: boolean to determine if camera is in photo mode or recording mode
    ///    - isPhotoSignatureEnabled: boolean to indicate if photo signature is activated
    func update(with labelCameraSpecificProperty1: String,
                labelCameraSpecificProperty2: String? = nil,
                labelShutterSpeed: String,
                labelExposureCompensation: String,
                exposureColor: Color,
                isPhotoMode: Bool,
                isPhotoSignatureEnabled: Bool) {
        self.labelCameraSpecificProperty1 = labelCameraSpecificProperty1
        self.labelCameraSpecificProperty2 = labelCameraSpecificProperty2
        self.labelShutterSpeed = labelShutterSpeed
        self.labelExposureCompensation = labelExposureCompensation
        self.exposureColor = exposureColor
        self.isPhotoMode = isPhotoMode
        self.isPhotoSignatureEnabled = isPhotoSignatureEnabled
    }

    // MARK: - Internal Funcs
    func isEqual(to other: CameraWidgetState) -> Bool {
        return self.labelCameraSpecificProperty1 == other.labelCameraSpecificProperty1
            && self.labelCameraSpecificProperty2 == other.labelCameraSpecificProperty2
            && self.labelShutterSpeed == other.labelShutterSpeed
            && self.labelExposureCompensation == other.labelExposureCompensation
            && self.exposureColor == other.exposureColor
            && self.isPhotoMode == other.isPhotoMode
            && self.isPhotoSignatureEnabled == other.isPhotoSignatureEnabled
    }

    /// Returns a copy of the object.
    func copy() -> Self {
        if let copy = CameraWidgetState(labelCameraSpecificProperty1: labelCameraSpecificProperty1,
                                        labelCameraSpecificProperty2: labelCameraSpecificProperty2,
                                        labelShutterSpeed: labelShutterSpeed,
                                        labelExposureCompensation: labelExposureCompensation,
                                        exposureColor: exposureColor,
                                        isPhotoMode: isPhotoMode,
                                        isPhotoSignatureEnabled: isPhotoSignatureEnabled,
                                        isSelected: isSelected) as? Self {
            return copy
        } else {
            fatalError("Must override...")
        }
    }
}

/// View model to manage camera widget in HUD Bottom bar.
final class CameraWidgetViewModel: BarButtonViewModel<CameraWidgetState> {
    // MARK: - Private Properties
    private var mainCameraRef: Ref<MainCamera2>?
    private var exposureValuesRef: Ref<Camera2ExposureIndicator>?
    private var lastExposureValue: Camera2ShutterSpeed? {
        guard let lastShutterSpeedRawValue = Defaults.lastShutterSpeedValue,
              let lastShutterSpeed = Camera2ShutterSpeed(rawValue: lastShutterSpeedRawValue) else {
            return nil
        }

        return lastShutterSpeed
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        listenCamera(drone: drone)
        listenExposureValues(drone: drone)
    }
}

// MARK: - Private Funcs
private extension CameraWidgetViewModel {
    /// Starts watcher for camera.
    func listenCamera(drone: Drone) {
        mainCameraRef = drone.getPeripheral(Peripherals.mainCamera2) { [weak self] _ in
            self?.updateState(drone: drone)
        }
    }

    /// Starts watcher for exposure values (ShutterSpeed).
    func listenExposureValues(drone: Drone) {
        exposureValuesRef = drone.getPeripheral(Peripherals.mainCamera2)?.getComponent(Camera2Components.exposureIndicator,
                                                                                       observer: { [weak self] exposureIndicator in
                if let rawShutterSpeedValue = exposureIndicator?.shutterSpeed.rawValue {
                    Defaults.lastShutterSpeedValue = rawShutterSpeedValue
                }
                if let rawCameraIsoValue = exposureIndicator?.isoSensitivity.rawValue {
                    Defaults.lastCameraIsoValue = rawCameraIsoValue
                }
                self?.updateState(drone: drone)
        })
    }

    /// Updates state from camera and exposure values.
    func updateState(drone: Drone?) {
        guard let camera = drone?.getPeripheral(Peripherals.mainCamera2),
              let cameraMode = camera.mode,
              let evCompensation = camera.config[Camera2Params.exposureCompensation]?.value else {
            return
        }

        let shutterSpeed = camera.getComponent(Camera2Components.exposureIndicator)?.shutterSpeed
        guard let photoSignature = camera.config[Camera2Params.photoDigitalSignature]?.value else { return }

        let newState = state.value.copy()
        switch cameraMode {
        case .recording:
            guard let resolution = camera.config[Camera2Params.videoRecordingResolution]?.value,
                  let framerate = camera.config[Camera2Params.videoRecordingFramerate]?.value else {
                return
            }

            newState.update(with: resolution.title,
                            labelCameraSpecificProperty2: framerate.fpsTitle,
                            labelShutterSpeed: shutterSpeed?.shortTitle ?? L10n.unitSecond.dashPrefixed,
                            labelExposureCompensation: evCompensation.title,
                            exposureColor: evCompensation == .ev0_00 ? UIColor.white.withAlphaComponent(0.5) : UIColor(named: .yellowSea),
                            isPhotoMode: false,
                            isPhotoSignatureEnabled: false)
        case .photo:
            guard let photoFormat = camera.photoFormatMode else { return }

            newState.update(with: photoFormat.title,
                            labelShutterSpeed: shutterSpeed?.shortTitle ?? L10n.unitSecond.dashPrefixed,
                            labelExposureCompensation: evCompensation.title,
                            exposureColor: evCompensation == .ev0_00 ? UIColor.white.withAlphaComponent(0.5) : UIColor(named: .yellowSea),
                            isPhotoMode: true,
                            isPhotoSignatureEnabled: photoSignature == .drone)
        }
        state.set(newState)
    }
}
