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

import GroundSdk
import SwiftyUserDefaults
import UIKit
import Combine

// MARK: - Internal Enums
/// Describes different cellular connection state.
enum CellularConnectionState: Equatable {
    case ready
    case searching
    case denied(_ hasError: Bool)
    case none

    /// Return description color.
    var descriptionColor: UIColor {
        switch self {
        case .searching:
            return ColorName.highlightColor.color
        case .denied:
            return ColorName.errorColor.color
        default:
            return ColorName.defaultTextColor.color
        }
    }

    /// Tells if the description is hidden.
    var isDescriptionHidden: Bool {
        switch self {
        case .searching:
            return false
        case .denied(let hasError):
            return !hasError
        default:
            return true
        }
    }
}

/// View Model in charge of drone cellular connection.
final class CellularAccessCardPinViewModel {

    // MARK: - Internal Properties
    private enum Constants {
        static let requiredPinNumber: Int = 4
    }

    /// Data source provided to the view controller.
    var dataSource: [Int] = [1, 2, 3, 4, 5,
                             6, 7, 8, 9, 0]

    /// Current cellular connection state.
    @Published private(set) var cellularConnectionState: CellularConnectionState = .none
    /// Description title.
    @Published private(set) var descriptionTitle: String?
    /// Tells if we can show the loader view.
    @Published private(set) var shouldShowLoader: Bool = false
    /// Connection state of the device.
    @Published private(set) var connectionState: DeviceState.ConnectionState = .disconnected
    /// Tells if we can enable the ok button.
    @Published private var enableOkButton: Bool = false
    /// The pinCode
    @Published private(set) var pinCode: String = ""

    var shouldEnableOkButton: AnyPublisher<Bool, Never> {
        $enableOkButton
            .removeDuplicates()
            .combineLatest($pinCode.removeDuplicates())
            .map { (shouldEnable, pincode) in
                return shouldEnable && pincode.count >= Constants.requiredPinNumber
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Private Properties
    private var cellularRef: Ref<Cellular>?
    private var cancellables = Set<AnyCancellable>()
    private var detailsCellularIsSource: Bool

    private let currentDroneHolder: CurrentDroneHolder
    private let pinCodeService: PinCodeService
    private let cellularService: CellularService

    private weak var coordinator: Coordinator?

    // MARK: - Init

    init(coordinator: Coordinator,
         detailsCellularIsSource: Bool = false,
         currentDroneHolder: CurrentDroneHolder,
         pinCodeService: PinCodeService,
         cellularService: CellularService) {
        self.coordinator = coordinator
        self.detailsCellularIsSource = detailsCellularIsSource
        self.currentDroneHolder = currentDroneHolder
        self.pinCodeService = pinCodeService
        self.cellularService = cellularService

        currentDroneHolder.dronePublisher
            .sink { [weak self] drone in
                guard let self = self else { return }
                self.listenCellular(drone: drone)
            }
            .store(in: &cancellables)

        cellularService.cellularStatusPublisher
            .removeDuplicates()
            .sink { [weak self] status in
                guard let self = self else { return }
                self.enableOkButton = status == .simBlocked ? false : true
            }
            .store(in: &cancellables)
    }

    // MARK: - Internal Funcs
    /// Connects drone via cellular.
    ///
    /// - Parameters:
    ///     - pinCode: code pin for cellular access
    func connect() {
        guard let cellular = currentDroneHolder.drone.getPeripheral(Peripherals.cellular) else { return }

        updateLoaderState(shouldShow: true)
        _ = cellular.enterPinCode(pincode: pinCode)
    }

    /// Dismisses the cellular access modal.
    /// We can show it again if the application restarts or if the drone is connected again.
    func dismissCellularModal() {
        updateLoaderState(shouldShow: false)
        pinCodeService.resetPinCodeRequested()
    }

    func dismissPinCodeView(animated: Bool) {
        coordinator?.dismiss(animated: animated) {
            if self.detailsCellularIsSource {
                if let coordinator = self.coordinator as? DroneCoordinator {
                    coordinator.displayDroneDetailsCellular()
                }
            }
        }
    }

    func addDigitToPinCode(number: String) {
        pinCode += number
    }

    func removeLastDigit() {
        guard !pinCode.isEmpty else { return }
        pinCode.removeLast()
    }
}

private extension CellularAccessCardPinViewModel {

    /// Starts watcher for Cellular.
    func listenCellular(drone: Drone) {
        cellularRef = drone.getPeripheral(Peripherals.cellular) { [unowned self] _ in
            updateState(drone: drone)
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
            guard cellular.pinRemainingTries < 3 else {
                cellularConnectionState = .denied(false)
                descriptionTitle = nil
                return
            }

            cellularConnectionState = .denied(true)
            switch cellular.pinRemainingTries {
            case 0:
                descriptionTitle = L10n.pinErrorLocked
            case 1:
                descriptionTitle = L10n.pinErrorRemainingAttemptsSingular(cellular.pinRemainingTries)
            default:
                descriptionTitle = L10n.pinErrorRemainingAttemptsPlural(cellular.pinRemainingTries)
            }
        default:
            cellularConnectionState = CellularConnectionState.none
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
