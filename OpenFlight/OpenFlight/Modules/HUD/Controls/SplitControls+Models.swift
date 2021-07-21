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

// MARK: - Public Enums
/// Split mode between stream and secondary view in HUD.
public enum SplitScreenMode {
    /// View is split between stream and secondary view.
    case splited
    /// Secondary view is displayed fullscreen.
    case secondary
    /// Stream is displayed fullscreen.
    case stream

    // Preset value for SplitScreenMode.
    static var preset: SplitScreenMode {
        return .splited
    }
}

/// Public SplitControls constants.
enum SplitControlsConstants {
    /// Key used in `userInfo` notification.
    static let splitScreenModeKey = "splitScreenModeKey"
}

// MARK: - Protocols
/// Protocol used to get notified on stream size change.
protocol SplitControlsDelegate: AnyObject {
    /// Informs delegate about stream width change.
    func streamSizeDidChange(width: CGFloat)
}

/// Protocol used to restore the map view.
///
/// Note: this is needed because, when entering Flight Plan edition,
/// map view is transferred to the new view controller. This protocol
/// is used to restore it back to its original container.
public protocol MapViewRestorer: AnyObject {
    /// Adds map view controller in view
    ///
    /// - Parameters:
    ///     - map: map view controller
    ///     - parent: parent view controller
    func addMap(_ map: UIViewController, parent: UIViewController)
    /// Restores map view if needed.
    func restoreMapIfNeeded()
}
