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

import SwiftyUserDefaults

// MARK: - Internal Enums
/// Describes type of a Joystick.
enum JoystickType {
    case pitchYaw
    case gazRoll
    case gazYaw
    case pitchRoll
    case cameraTilt
    case invalid

    /// Background image of the joystick.
    var backgroundImage: UIImage? {
        switch self {
        case .pitchYaw:
            return Asset.Joysticks.icBackgroundPitchYaw.image
        case .gazRoll:
            return Asset.Joysticks.icBackgroundGazRoll.image
        case .gazYaw:
            return Asset.Joysticks.icBackgroundGazYaw.image
        case .pitchRoll:
            return Asset.Joysticks.icBackgroundPitchRoll.image
        default:
            return Asset.Joysticks.icBackgroundPitchYaw.image
        }
    }
}

/// View Model which provides type of left and right joysticks.
final class JoysticksTypeViewModel {
    // MARK: - Publish Properties
    /// Left joystick type.
    @Published private(set) var leftJoystickType: JoystickType = .gazYaw
    /// Right joystick type.
    @Published private(set) var rightJoystickType: JoystickType = .pitchRoll

    // MARK: - Private Properties
    private var disposable: DefaultsDisposable?

    // MARK: - Init
    init() {
        listenControlsMode()
    }

    // MARK: - Deinit
    deinit {
        disposable?.dispose()
        disposable = nil
    }
}

// MARK: - Private Funcs
private extension JoysticksTypeViewModel {
    /// Starts watcher for controls mode.
    func listenControlsMode() {
        disposable = Defaults.observe(\.userControlModeSetting, options: [.initial, .new]) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateJoysticks()
            }
        }
    }

    /// Update left and right joystick types.
    func updateJoysticks() {
        // Listen current control mode and update each joystick's type.
        var mode: ControlsSettingsMode = ControlsSettingsMode.defaultMode
        if let rawUserMode = Defaults.userControlModeSetting,
            let userMode = ControlsSettingsMode(value: rawUserMode) {
            mode = userMode
        }

        switch mode {
        case .mode1:
            leftJoystickType = .pitchYaw
            rightJoystickType = .gazRoll
        case .mode1Inversed:
            leftJoystickType = .gazRoll
            rightJoystickType = .pitchYaw
        case .mode2:
            leftJoystickType = .gazYaw
            rightJoystickType = .pitchRoll
        case .mode2Inversed:
            leftJoystickType = .pitchRoll
            rightJoystickType = .gazYaw
        }
    }
}
