//    Copyright (C) 2020 Parrot Drones SAS
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
import Reusable
import GroundSdk

private extension ULogTag {
    static let tag = ULogTag(name: "CameraShutterButton")
}

/// Shutter button for HUD. Displays current recording/photo capture state.

final class CameraShutterButton: UIControl, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var innerView: UIView!
    @IBOutlet private weak var recordingTimeStackView: UIStackView!
    @IBOutlet private weak var recordingTimeLabel: UILabel!
    @IBOutlet private weak var remainingRecordTimeLabel: UILabel!
    @IBOutlet private weak var infoImageView: UIImageView!
    @IBOutlet private weak var stopView: UIView!
    @IBOutlet private weak var centerLabel: UILabel!
    @IBOutlet private weak var shutterButtonProgressView: ShutterButtonProgressView!

    // MARK: - Internal Properties
    var model: CameraShutterButtonState? {
        didSet {
            updateButton()
        }
    }

    // MARK: - Private Properties
    private var isBlinking: Bool = false
    private var photosCount = 0
    private var recordingColor: UIColor {
        isEnabled ? Constants.defaultRecordingColor : Constants.unavailableRecordingColor
    }

    // MARK: - Private Enums
    private enum Constants {
        static let defaultBorderWidth: CGFloat = 1.0
        static let defaultBorderColor = ColorName.white.color
        static let defaultBackgroundColor = ColorName.black.color
        static let defaultAnimationDuration: TimeInterval = 0.2
        static let defaultPhotoCaptureColor = ColorName.white.color
        static let takePhotoCaptureColor = ColorName.white20.color
        static let unavailablePhotoCaptureColor = ColorName.white20.color
        static let lapseInProgressPhotoCaptureColor = ColorName.black.color
        static let defaultRecordingColor = ColorName.errorColor.color
        static let activeRecordingColor = ColorName.errorColor.color.withAlphaComponent(0.5)
        static let unavailableRecordingColor = ColorName.disabledErrorColor.color
        static let countDownLapseColor = ColorName.black.color
    }

    // MARK: - Override Properties
    override var isEnabled: Bool {
        didSet {
            isBlinking = false
            updateButton()
        }
    }

    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInitCameraShutterButton()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInitCameraShutterButton()
    }
}

// MARK: - Private Funcs
private extension CameraShutterButton {
    /// Common init.
    func commonInitCameraShutterButton() {
        loadNibContent()
        setBorder(borderColor: Constants.defaultBorderColor, borderWidth: Constants.defaultBorderWidth)
        backgroundColor = Constants.defaultBackgroundColor
        shutterButtonProgressView.clipsToBounds = true
        clipsToBounds = true
        shutterButtonProgressView.applyCornerRadius(Style.largeCornerRadius)
        recordingTimeLabel.font = FontStyle.current.font(isRegularSizeClass, monospacedDigits: true)
        remainingRecordTimeLabel.font = FontStyle.caps.font(isRegularSizeClass, monospacedDigits: true)
        centerLabel.makeUp(with: .large, and: .black)
        stopView.applyCornerRadius()
    }

    /// Updates button with current model.
    func updateButton() {
        guard let model = model else { return }

        switch model.cameraMode {
        case .recording:
            updateRecordingMode(model: model)
        case .photo:
            updatePhotoMode(model: model)
        }
    }

    /// Updates button for current recording mode.
    ///
    /// - Parameters:
    ///     - model: current button state
    func updateRecordingMode(model: CameraShutterButtonState) {
        guard model.enabled else {
            applyRecordingUnavailableStyle()
            return
        }

        guard model.isStorageReady else {
            applyRecordingUnavailableStyle(image: model.userStorageState.shutterIcon)
            return
        }

        guard !model.userStorageState.hasStorageError else {
            applyRecordingUnavailableStyle(image: Asset.BottomBar.ShutterButtonIcons.Error.icSdError.image)
            return
        }

        switch model.recordingTimeState.functionState {
        case .started:
            applyRecordingStartedStyle()
        case .stopping(reason: .errorInternal, savedMediaId: nil):
            applyRecordingUnavailableStyle(image: Asset.BottomBar.ShutterButtonIcons.Error.icError.image)
        case .stopped:
            applyRecordingStoppedStyle(labelText: model.cameraCaptureSubMode?.shutterText)
        case .starting, .stopping:
            applyRecordingUnavailableStyle()
        }

        // Show recording time if available.
        if let recordingTime = model.recordingTimeState.recordingTime {
            recordingTimeLabel.text = recordingTime.formattedString
        }

        // Show remaining time if available.
        if let remainingRecordTime = model.recordingTimeState.remainingRecordTime {
            remainingRecordTimeLabel.text = "-\(remainingRecordTime.formattedString)"
        }
    }

    /// Updates button for current photo mode.
    ///
    /// - Parameters:
    ///     - model: current button state
    func updatePhotoMode(model: CameraShutterButtonState) {
        guard model.enabled else {
            applyPhotoCaptureUnavailableStyle()
            return
        }

        guard model.isStorageReady else {
            applyPhotoCaptureUnavailableStyle(image: model.userStorageState.shutterIcon)
            return
        }

        guard !model.userStorageState.hasStorageError else {
            applyPhotoCaptureUnavailableStyle(image: Asset.BottomBar.ShutterButtonIcons.Error.icSdError.image)
            return
        }

        switch (model.photoFunctionState, model.cameraCaptureMode) {
        case (.stopping(let reason, _), .timelapse):
            if reason != .captureDone {
                applyPhotoCaptureUnavailableStyle()
            }
        case (_, .panorama):
            guard let state = model.panoramaModeState else {
                applyPhotoCaptureUnavailableStyle()
                return
            }
            updatePhotoCapturePanoramaStyle(with: state)
        case (.started, .timelapse):
            guard let state = model.lapseModeState else { return }
            updateTimeLapseModeProgressView(with: state)
        case (.started, .gpslapse):
            guard let state = model.lapseModeState else { return }
            updateGpsLapseModeProgressView(with: state)
        case (.stopped, .timelapse),
             (.stopped, .gpslapse):
            shutterButtonProgressView.isHidden = true
            applyLapseModeStyle(labelText: nil)
            photosCount = 0
        case (.started, _):
            applyPhotoCaptureTakePhotoStyle()
        case (.stopping(reason: Camera2PhotoCaptureState.StopReason.errorInternal, savedMediaId: nil), _):
            applyPhotoCaptureUnavailableStyle(image: Asset.BottomBar.ShutterButtonIcons.Error.icError.image)
        case (.stopping, _):
            applyPhotoCaptureUnavailableStyle()
        default:
            shutterButtonProgressView.isHidden = true
            applyPhotoCaptureStyle(labelText: model.cameraCaptureSubMode?.shutterText)
        }
    }

    /// Apply given style to shutter button and animate changes.
    ///
    /// - Parameters:
    ///    - outerCornerRadius: corner radius for outer part, rounded if nil
    ///    - innerCornerRadius: corner radius for inner part, rounded if nil
    ///    - innerBackgroundColor: color for inner background
    ///    - recordingTimeHidden: recording time labels visibility
    ///    - stopViewHidden: stop view visibility
    ///    - image: centered image
    ///    - labelText: shutter button label text
    func updateStyle(outerCornerRadius: CGFloat? = nil,
                     innerCornerRadius: CGFloat? = nil,
                     innerBackgroundColor: UIColor,
                     recordingTimeHidden: Bool = true,
                     stopViewHidden: Bool = true,
                     image: UIImage? = nil,
                     labelText: String? = nil) {
        centerLabel.text = labelText
        infoImageView.image = image
        infoImageView.isHidden = image == nil
        if image == nil {
            infoImageView.alpha = 0.0
        }
        recordingTimeStackView.isHidden = recordingTimeHidden
        addCornerRadiusAnimation(toValue: outerCornerRadius ?? frame.height / 2,
                                 duration: Constants.defaultAnimationDuration)
        innerView.addCornerRadiusAnimation(toValue: innerCornerRadius ?? innerView.frame.height / 2,
                                           duration: Constants.defaultAnimationDuration)
        UIView.animate(withDuration: Constants.defaultAnimationDuration) {
            self.innerView.backgroundColor = innerBackgroundColor
            self.infoImageView.alpha = 1.0
            self.stopView.alpha = stopViewHidden ? 0.0 : 1.0
            guard let model = self.model else { return }
            let canShowProgressView = model.photoFunctionState.isStarted
                && model.cameraCaptureMode == .timelapse
            self.shutterButtonProgressView.isHidden = !canShowProgressView
            self.innerView.setBorder(borderColor: canShowProgressView ? .black : .clear,
                                     borderWidth: canShowProgressView ? Style.mediumBorderWidth : 0.0)
        }
    }

    /// Starts a blinking animation between two colors.
    ///
    /// - Parameters:
    ///    - firstColor: the first color
    ///    - secondColor: the second color
    func startBlinking(with firstColor: UIColor, and secondColor: UIColor) {
        UIView.animate(withDuration: Style.longAnimationDuration,
                       delay: 0.0,
                       options: [.repeat, .autoreverse, .allowUserInteraction],
                       animations: {
                        self.innerView.backgroundColor = firstColor
                        self.innerView.backgroundColor = secondColor
                       })
        isBlinking = true
    }
}

// MARK: CameraShutterButton Recording Style
/// Private extension for Shutter button in recording mode.
private extension CameraShutterButton {
    /// Apply style for recording started.
    func applyRecordingStartedStyle() {
        updateStyle(outerCornerRadius: Style.largeCornerRadius,
                    innerCornerRadius: Style.mediumCornerRadius,
                    innerBackgroundColor: Constants.activeRecordingColor,
                    recordingTimeHidden: false)
        if !isBlinking {
            startBlinking(with: recordingColor,
                          and: Constants.activeRecordingColor)
        }
    }

    /// Apply style for recording stopped.
    ///
    /// - Parameters:
    ///     - labelText: shutter button text
    func applyRecordingStoppedStyle(labelText: String? = nil) {
        setBorder(borderColor: Constants.defaultBorderColor, borderWidth: Constants.defaultBorderWidth)
        updateStyle(innerBackgroundColor: recordingColor,
                    labelText: labelText)
        isBlinking = false
    }

    /// Apply style for unavailable recording.
    ///
    /// - Parameters:
    ///     - image: image in the shutter button
    func applyRecordingUnavailableStyle(image: UIImage? = nil) {
        updateStyle(innerBackgroundColor: Constants.unavailableRecordingColor,
                    image: image)
        isBlinking = false
    }
}

// MARK: CameraShutterButton Photo Capture Style
/// Private extension for Shutter button in photo capture mode.
private extension CameraShutterButton {
    /// Update shutter button for panorama mode.
    ///
    /// - Parameters:
    ///     - state: current panorama state
    func updatePhotoCapturePanoramaStyle(with state: PanoramaModeState) {
        if state.inProgress {
            applyPhotoCaptureInProgressStyle()
        } else if state.available {
            applyPhotoCaptureStyle()
        } else {
            applyPhotoCaptureUnavailableStyle()
        }
    }

    /// Apply style for photo capture.
    ///
    /// - Parameters:
    ///     - labelText: shutter button text
    func applyPhotoCaptureStyle(labelText: String? = nil) {
        setBorder(borderColor: Constants.defaultBorderColor, borderWidth: Constants.defaultBorderWidth)
        updateStyle(innerBackgroundColor: Constants.defaultPhotoCaptureColor,
                    labelText: labelText)
        isBlinking = false
    }

    /// Apply style for taking photo.
    func applyPhotoCaptureTakePhotoStyle() {
        updateStyle(innerBackgroundColor: Constants.takePhotoCaptureColor)
        isBlinking = false
    }

    /// Apply style for timelapse/gpslapse in progress.
    func applyPhotoCaptureInProgressStyle() {
        updateStyle(innerBackgroundColor: Constants.lapseInProgressPhotoCaptureColor,
                    stopViewHidden: false)

    }

    /// Apply style for unavailable photo capture.
    ///
    /// - Parameters:
    ///     - image: shutter button image to display
    func applyPhotoCaptureUnavailableStyle(image: UIImage? = nil) {
        updateStyle(innerBackgroundColor: Constants.unavailablePhotoCaptureColor,
                    image: image)
        isBlinking = false
    }
}

// MARK: CameraShutterButton Progress View
/// Private extension for Shutter button progress view. Used for Timelapse and Gpslapse mode.
private extension CameraShutterButton {
    /// Updates progress view for timelapse photo mode.
    ///
    /// - Parameters:
    ///     - state: current timelapse state
    func updateTimeLapseModeProgressView(with state: PhotoLapseState) {
        applyLapseModeInProgressStyle(photosCount: state.photosNumber)

        guard photosCount != state.photosNumber else { return }
        photosCount = state.photosNumber
        shutterButtonProgressView.animateProgress(duration: TimeInterval(state.selectedValue) - Style.mediumAnimationDuration)
    }

    /// Updates progress view for gpslapse photo mode.
    ///
    /// - Parameters:
    ///     - state: current gpslapse state
    func updateGpsLapseModeProgressView(with state: PhotoLapseState) {
        applyLapseModeInProgressStyle(photosCount: state.photosNumber)
    }

    /// Apply style for timelapse and gpslapse mode.
    ///
    /// - Parameters:
    ///     - labelText: shutter button text
    func applyLapseModeStyle(labelText: String? = nil) {
        setBorder(borderColor: Constants.defaultBorderColor, borderWidth: Constants.defaultBorderWidth)
        updateStyle(innerBackgroundColor: Constants.defaultPhotoCaptureColor,
                    labelText: labelText)
        shutterButtonProgressView.resetProgress()
        centerLabel.textColor = Constants.countDownLapseColor
    }

    /// Apply in progress style for timelapse and gpslapse mode.
    ///
    /// - Parameters:
    ///     - photoCount: number of photos taken during the session
    func applyLapseModeInProgressStyle(photosCount: Int) {
        setBorder(borderColor: .clear, borderWidth: Style.noBorderWidth)
        updateStyle(outerCornerRadius: Style.largeCornerRadius,
                    innerCornerRadius: Style.mediumCornerRadius,
                    innerBackgroundColor: Constants.defaultPhotoCaptureColor,
                    labelText: String(photosCount))
    }
}
