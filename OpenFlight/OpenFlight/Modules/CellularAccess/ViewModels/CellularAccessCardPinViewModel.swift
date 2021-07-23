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
import Combine

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
            return ColorName.highlightColor.color
        case .denied:
            return ColorName.redTorch.color
        case .none:
            return ColorName.defaultTextColor.color
        default:
            return nil
        }
    }
}

/// View Model in charge of drone cellular connection.
final class CellularAccessCardPinViewModel {

    // MARK: - Internal Properties
    /// Data source provided to the view controller.
    var dataSource: [Int] = [1, 2, 3, 4, 5,
                             6, 7, 8, 9, 0]

    /// Current cellular connection state.
    @Published private(set) var cellularConnectionState: CellularConnectionState?
    /// Description title.
    @Published private(set) var descriptionTitle: String?
    /// Tells if we can show the loader view.
    @Published private(set) var shouldShowLoader: Bool = false
    /// Connection state of the device
    @Published private(set) var connectionState: DeviceState.ConnectionState = .disconnected

    /// Tells if we need to show the description label.
    var hideLabel: AnyPublisher<Bool, Never> {
        $cellularConnectionState.map { (cellularConnectionState: CellularConnectionState?) -> Bool in
            guard let state = cellularConnectionState else { return true }
            switch state {
            case .denied, .searching:
                return false
            default:
                return true
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Private Properties
    private var cellularRef: Ref<Cellular>?
    private var cancellables = Set<AnyCancellable>()

    // TODO - Wrong injection
    private let currentDroneHolder = Services.hub.currentDroneHolder

    // MARK: - Init

    init() {
        currentDroneHolder.dronePublisher
            .sink { [unowned self] drone in
                listenCellular(drone: drone)
            }
            .store(in: &cancellables)
    }

    // MARK: - Internal Funcs
    /// Connects drone via cellular.
    ///
    /// - Parameters:
    ///     - pinCode: code pin for cellular access
    func connect(pinCode: String) {
        guard let cellular = currentDroneHolder.drone.getPeripheral(Peripherals.cellular) else { return }

        updateLoaderState(shouldShow: true)
        _ = cellular.enterPinCode(pincode: pinCode)
    }

    /// Dismisses the cellular access modal.
    /// We can show it again if the application restarts or if the drone is connected again.
    func dismissCellularModal() {
        guard let cellular = currentDroneHolder.drone.getPeripheral(Peripherals.cellular) else { return }

        cellular.mode.value = .disabled
        updateLoaderState(shouldShow: false)
    }
}

private extension CellularAccessCardPinViewModel {

    /// Starts watcher for Cellular.
    func listenCellular(drone: Drone) {
        cellularRef = drone.getPeripheral(Peripherals.cellular) { [weak self] _ in
            self?.updateState(drone: drone)
        }
        updateState(drone: drone)
    }

    /// Updates the state according to cellular values.
    func updateState(drone: Drone) {
        updateLoaderState(shouldShow: false)

        guard let cellular = drone.getPeripheral(Peripherals.cellular) else {
            cellularConnectionState = CellularConnectionState.none
            return
        }

        switch (cellular.simStatus, cellular.registrationStatus) {
        case (.ready, _):
            cellularConnectionState = .ready
        case(.absent, _):
            cellularConnectionState = CellularConnectionState.none
        case(_, .searching):
            cellularConnectionState = .searching
            descriptionTitle = L10n.pinModalUnlocking
        case(.locked, _):
            cellularConnectionState = CellularConnectionState.denied
            switch cellular.pinRemainingTries {
            case 0:
                descriptionTitle = L10n.pinErrorLocked
            case 1:
                descriptionTitle = L10n.pinErrorRemainingAttemptsSingular(cellular.pinRemainingTries)
            case 2:
                descriptionTitle = L10n.pinErrorRemainingAttemptsPlural(cellular.pinRemainingTries)
            default:
                descriptionTitle = ""
            }
        default:
            cellularConnectionState = CellularConnectionState.none
            descriptionTitle = ""
        }
    }

    /// Updates loader state.
    ///
    /// - Parameters:
    ///     - shouldShow: tells if if we need to show the loader
    func updateLoaderState(shouldShow: Bool) {
        shouldShowLoader = shouldShow
    }
}
