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
import SwiftyUserDefaults

// MARK: - Protocols

/// Protocol that defines a business item mode used within a bottom bar in HUD.
public protocol BarItemMode {
    /// Current title.
    var title: String { get }
    /// Current image.
    var image: UIImage? { get }
    /// Current key.
    /// - Note: key must be unique by mode.
    var key: String { get }
    /// Array representing all mode values.
    static var allValues: [BarItemMode] { get }
    /// Boolean determining if current mode is available.
    var isAvailable: Bool { get }
    /// Array representing all subMode values, if existing.
    var subModes: [BarItemSubMode]? { get }
    /// Boolean describing if selecting this mode should trigger an autoclose of the bar.
    var autoClose: Bool { get }
    /// Key for log app button.
    var logKey: String { get }
}

/// Default `BarItemMode` protocol implementation.
public extension BarItemMode {
    var isAvailable: Bool {
        return true
    }

    var autoClose: Bool {
        return true
    }
}

/// Protocol that defines a business item sub-mode used within a bottom bar in HUD.
public protocol BarItemSubMode: BarItemMode, ValuableBarItem {
    /// Text that should be displayed in shutter button.
    var shutterText: String? { get }
}

/// Protocol for getting subMode values in bottom bar.
public protocol ValuableBarItem {
    /// GSDK value for current subMode.
    var value: Int? { get }
}

/// Default `BarItemSubMode` protocol implementation.
public extension BarItemSubMode {
    var subModes: [BarItemSubMode]? {
        return nil
    }

    var value: Int? {
        return nil
    }
}

/// Protocol for components displaying a `BarItemMode`.
protocol BarItemModeDisplayer {
    /// Identifier of displayed bar.
    var barId: String? { get }
}

/// Protocol for items displayed inside a ruler bar.
protocol RulerDisplayable {
    var rulerText: String? { get }
    var rulerBackgroundColor: UIColor? { get }
}

/// Protocol for subMode that use default keys in bottom bar.
protocol DefaultsLoadableBarItem {
    var rawValue: String { get }
    static var defaultKey: DefaultsKey<String> { get }
}

/// Protocol for bottom bar selection notification.
public protocol BottomBarState: ViewModelState {
    /// Observable for bottom bar item selection.
    var isSelected: Observable<Bool> { get }
}

/// Protocol that defines a business item model used within a bottom bar in HUD.
public protocol BarButtonState: BottomBarState {
    /// Button title.
    var title: String? { get }
    /// Button subtext generally representing current mode value.
    var subtext: String? { get }
    /// Button image.
    var image: UIImage? { get }
    /// Current mode value.
    var mode: BarItemMode? { get }
    /// Supported modes (all values are displayed if not defined).
    var supportedModes: [BarItemMode]? { get }
    /// If set to true, unsupported modes will be displayed and greyed out.
    var showUnsupportedModes: Bool { get }
    /// Current submode, if exists.
    var subMode: BarItemSubMode? { get }
    /// Button subtitle.
    var subtitle: String? { get }
    /// Current button availability.
    var enabled: Bool { get }
    /// Current reasons why buttons are not enabled.
    /// Keys are BarItemMode.key fields.
    var unavailableReason: [String: String] { get }
    /// Maximum number of items displayed at the same time on segmented bar.
    var maxItems: Int? { get }
    /// When `true` the button is not touchable and only displays the image (no text).
    var singleMode: Bool { get }
}

/// Extensions for default implementation of `BarButtonState` fields.
extension BarButtonState {
    var singleMode: Bool { false }
}

/// Protocol for an item that can get deselected.
protocol Deselectable: AnyObject {
    /// Deselect item.
    func deselect()
}

/// Base viewModel used for button views in bottom bar.
class BarButtonViewModel<T: BottomBarState>: DroneWatcherViewModel<T>, Deselectable {
    /// Bar identifier.
    var barId: String

    // MARK: - init
    /// Constructor.
    ///
    /// - Parameters:
    ///    - barId: bar identifier
    init(barId: String) {
        self.barId = barId
    }

    // MARK: - Internal Funcs
    /// Toggles bar button selection state.
    func toggleSelectionState() {
        state.value.isSelected.set(!state.value.isSelected.value)
    }

    /// Selects bar button.
    func select() {
        state.value.isSelected.set(true)
    }

    /// Deselect bar button.
    func deselect() {
        state.value.isSelected.set(false)
    }

    /// Udpate state with mode.
    func update(mode: BarItemMode) {
        assert(false) // Must override...
    }

    /// Udpate state with sub mode.
    func update(subMode: BarItemSubMode) {
        assert(false) // Must override...
    }
}

/// Base viewModel for bottom bar setting that use an automatic mode.
class AutomatableBarButtonViewModel<T: BottomBarState>: BarButtonViewModel<T>, Copying {
    /// Toggle setting automatic mode.
    func toggleAutomaticMode() {
        assert(false) // Must override...
    }

    /// Returns a copy of the current viewModel.
    func copy() -> Self {
        fatalError("Must override...")
    }
}
