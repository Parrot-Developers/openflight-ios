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

/// State for imaging settings bar view models.

class ImagingBarState: BarButtonState, EquatableState, Copying {
    // MARK: - Internal Properties
    /// Default title (used if current mode is nil).
    var title: String?
    var subtext: String?
    /// Default image (used if current mode as no image).
    var image: UIImage?
    var mode: BarItemMode?
    var supportedModes: [BarItemMode]?
    var showUnsupportedModes: Bool = false
    var subMode: BarItemSubMode?
    var subtitle: String?
    var enabled: Bool = true
    var isSelected: Observable<Bool> = Observable(false)
    var unavailableReason: [String: String] = [:]

    // MARK: - Init
    required init() { }

    /// Init.
    ///
    /// - Parameters:
    ///    - mode: current mode
    ///    - supportedModes: current supported modes
    ///    - isSelected: observer for selected state
    ///    - unavailableReason: Reason why button is not available
    init(mode: BarItemMode?,
         subMode: BarItemSubMode? = nil,
         supportedModes: [BarItemMode]?,
         showUnsupportedModes: Bool = false,
         isSelected: Observable<Bool>,
         unavailableReason: [String: String]? = nil) {
        self.mode = mode
        self.subMode = subMode
        self.supportedModes = supportedModes
        self.showUnsupportedModes = showUnsupportedModes
        self.isSelected = isSelected
        self.unavailableReason = unavailableReason ?? [:]
    }

    // MARK: - Internal Funcs
    func isEqual(to other: ImagingBarState) -> Bool {
        return self.mode?.key == other.mode?.key
            && self.subMode?.key == other.subMode?.key
            && self.supportedModes?.map { $0.key } == other.supportedModes?.map { $0.key }
            && self.showUnsupportedModes == other.showUnsupportedModes
            && self.enabled == other.enabled
    }

    /// Returns a copy of the object.
    func copy() -> Self {
        if let copy = ImagingBarState(mode: self.mode,
                                      subMode: self.subMode,
                                      supportedModes: self.supportedModes,
                                      showUnsupportedModes: self.showUnsupportedModes,
                                      isSelected: self.isSelected) as? Self {
            copy.image = self.image
            return copy
        } else {
            fatalError("Must override...")
        }
    }
}

/// State for `ImagingBarShutterSpeedViewModel` and `ImagingBarCameraIsoViewModel`.

final class AutomatableRulerImagingBarState: ImagingBarState {
    // MARK: - Internal Properties
    /// Observer for current exposure setting mode.
    var exposureSettingsMode: Observable<Camera2ExposureMode> = Observable(.automatic)
    /// Boolean for setting automatic state.
    var isAutomatic: Bool = false

    // MARK: - Override Funcs
    override func isEqual(to other: ImagingBarState) -> Bool {
        guard let other = other as? AutomatableRulerImagingBarState else {
            return false
        }
        return super.isEqual(to: other)
            && self.image == other.image
            && self.enabled == other.enabled
            && self.title == other.title
            && self.isAutomatic == other.isAutomatic
    }

    override func copy() -> AutomatableRulerImagingBarState {
        let copy = AutomatableRulerImagingBarState(mode: self.mode, supportedModes: self.supportedModes, isSelected: self.isSelected)
        copy.image = self.image
        copy.exposureSettingsMode = self.exposureSettingsMode
        copy.enabled = self.enabled
        copy.title = self.title
        copy.isAutomatic = self.isAutomatic
        return copy
    }
}
