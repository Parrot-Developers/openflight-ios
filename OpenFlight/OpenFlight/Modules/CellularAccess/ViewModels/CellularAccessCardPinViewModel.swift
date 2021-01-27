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
import UIKit

// MARK: - Internal Enums
/// Describes different cellular connection state.
enum CellularConnectionState {
    case ready
    case searching
    case denied
    case none

    /// Return description color.
    var descriptionColor: UIColor? {
        switch self {
        case .searching:
            return ColorName.greenSpring.color
        case .denied:
            return ColorName.redTorch.color
        case .none:
            return ColorName.white.color
        default:
            return nil
        }
    }
}

/// State for `CellularAccessCardPinViewModel`.
final class CellularAccessCardPinState: DeviceConnectionState {
    // MARK: - Internal Properties
    /// Current cellular connection state.
    fileprivate(set) var cellularConnectionState: CellularConnectionState?
    /// Description title.
    fileprivate(set) var descriptionTitle: String?
    /// Tells if we can show the loader view.
    fileprivate(set) var shouldShowLoader: Bool = false

    /// Tells if we need to show the description label.
    var canShowLabel: Bool {
        return cellularConnectionState == .denied
            && cellularConnectionState == .searching
    }

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///     - connectionState: drone connection state
    ///     - cellularConnectionState: current connection state for cellular acces
    ///     - descriptionTitle: description text
    ///     - shouldShowLoader: tells if loader view can be shown
    init(connectionState: DeviceState.ConnectionState,
         cellularConnectionState: CellularConnectionState?,
         descriptionTitle: String?,
         shouldShowLoader: Bool) {
        super.init(connectionState: connectionState)

        self.cellularConnectionState = cellularConnectionState
        self.descriptionTitle = descriptionTitle
        self.shouldShowLoader = shouldShowLoader
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? CellularAccessCardPinState else { return false }
        return super.isEqual(to: other)
            && self.cellularConnectionState == other.cellularConnectionState
            && self.descriptionTitle == other.descriptionTitle
            && self.shouldShowLoader == other.shouldShowLoader
    }

    override func copy() -> CellularAccessCardPinState {
        let copy = CellularAccessCardPinState(connectionState: connectionState,
                                              cellularConnectionState: cellularConnectionState,
                                              descriptionTitle: descriptionTitle,
                                              shouldShowLoader: shouldShowLoader)
        return copy
    }
}

/// View Model in charge of drone cellular connection.
final class CellularAccessCardPinViewModel: DroneStateViewModel<CellularAccessCardPinState> {
    // MARK: - Internal Properties
    /// Data source provided to the view controller.
    var dataSource: [Int] = [1, 2, 3, 4, 5,
                             6, 7, 8, 9, 0]

    // MARK: - Private Properties
    private var cellularRef: Ref<Cellular>?

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)

        listenCellular(drone: drone)
    }

    // MARK: - Internal Funcs
    /// Connect drone via cellular.
    ///
    /// - Parameters:
    ///     - pinCode: code pin for cellular access
    func connect(pinCode: String) {
        guard let cellular = drone?.getPeripheral(Peripherals.cellular) else { return }

        updateLoaderState(shouldShow: true)
        _ = cellular.enterPinCode(pincode: pinCode)
    }

    /// Dismisses the cellular access modal.
    /// We can show it again if the application restarts or if the drone is connected again.
    func dismissCellularModal() {
        updateLoaderState(shouldShow: false)
    }
}

private extension CellularAccessCardPinViewModel {
    /// Starts watcher for Cellular.
    func listenCellular(drone: Drone) {
        cellularRef = drone.getPeripheral(Peripherals.cellular) { [weak self] _ in
            self?.updateState()
        }
        updateState()
    }

    /// Updates the state according to cellular values.
    func updateState() {
        updateLoaderState(shouldShow: false)

        let copy = state.value.copy()

        guard let cellular = drone?.getPeripheral(Peripherals.cellular) else {
            copy.cellularConnectionState = CellularConnectionState.none
            state.set(copy)
            return
        }

        switch (cellular.simStatus, cellular.registrationStatus) {
        case (.ready, _):
            copy.cellularConnectionState = .ready
        case(_, .searching):
            copy.cellularConnectionState = .searching
            copy.descriptionTitle = L10n.pinModalUnlocking
        case(.locked, _) where cellular.isPinCodeInvalid:
            copy.cellularConnectionState = CellularConnectionState.denied
            switch cellular.pinRemainingTries {
            case 0, 1:
                copy.descriptionTitle = L10n.pinErrorRemainingAttemptsSingular(cellular.pinRemainingTries)
            default:
                copy.descriptionTitle = L10n.pinErrorRemainingAttemptsPlural(cellular.pinRemainingTries)
            }
        default:
            copy.cellularConnectionState = CellularConnectionState.none
            copy.descriptionTitle = ""
        }

        if cellular.simStatus == .ready {
            copy.cellularConnectionState = .ready
        } else if cellular.registrationStatus == .searching {
            copy.cellularConnectionState = .searching
            copy.descriptionTitle = L10n.pinModalUnlocking
        } else if cellular.isPinCodeInvalid,
                  cellular.simStatus == .locked {
            copy.cellularConnectionState = CellularConnectionState.denied
            switch cellular.pinRemainingTries {
            case 0, 1:
                copy.descriptionTitle = L10n.pinErrorRemainingAttemptsSingular(cellular.pinRemainingTries)
            default:
                copy.descriptionTitle = L10n.pinErrorRemainingAttemptsPlural(cellular.pinRemainingTries)
            }
        } else {
            copy.cellularConnectionState = CellularConnectionState.none
            copy.descriptionTitle = ""
        }

        state.set(copy)
    }

    /// Updates loader state.
    ///
    /// - Parameters:
    ///     - shouldShow: tells if if we need to show the loader
    func updateLoaderState(shouldShow: Bool) {
        let copy = state.value.copy()
        copy.shouldShowLoader = shouldShow
        state.set(copy)
    }
}
