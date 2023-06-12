//    Copyright (C) 2023 Parrot Drones SAS
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

import Foundation
import GroundSdk
import Combine

private extension ULogTag {
    static let tag = ULogTag(name: "BatteryGaugeUpdaterService")
}

/// Service for the battery gauge updater peripheral.
///
/// This service reads the state, progress and unavailability reasons of the peripheral
/// and can send prepare and update commands.
/// The battery update is made of two steps, prepare and update.
/// The prepare command can be sent when the readyToPrepare state is reached and there are no unavailability reasons.
/// The update command can then be sent when the readyToUpdate state is reached.
protocol BatteryGaugeUpdaterService {
    var unavailabilityReasonsPublisher: AnyPublisher<Set<BatteryGaugeUpdaterUnavailabilityReasons>, Never> { get }
    var statePublisher: AnyPublisher<BatteryGaugeUpdaterState?, Never> { get }
    var currentProgressPublisher: AnyPublisher<UInt, Never> { get }

    /// Sends the prepare update command to the battery gauge updater.
    func prepareUpdate()
    /// Sends the update command to the battery gauge updater.
    func update()
}

class BatteryGaugeUpdaterServiceImpl {
    private var batteryGaugeUpdaterRef: Ref<BatteryGaugeUpdater>?
    private var batteryGaugeUpdater: BatteryGaugeUpdater?
    private let unavailabilityReasonsSubject = CurrentValueSubject<Set<BatteryGaugeUpdaterUnavailabilityReasons>, Never>([])
    private let stateSubject = CurrentValueSubject<BatteryGaugeUpdaterState?, Never>(nil)
    private let currentProgressSubject = CurrentValueSubject<UInt, Never>(0)
    private var cancellables = Set<AnyCancellable>()

    init(currentDroneHolder: CurrentDroneHolder) {
        currentDroneHolder.dronePublisher
            .sink { [unowned self] drone in
                listenBatteryGaugeUpdater(drone)
            }
            .store(in: &cancellables)
    }

    /// Listens to the `batteryGaugeUpdater` peripheral.
    /// - Parameter drone: the current drone
    private func listenBatteryGaugeUpdater(_ drone: Drone) {
        batteryGaugeUpdaterRef = drone.getPeripheral(Peripherals.batteryGaugeUpdater) { [unowned self] batteryGaugeUpdater in
            guard let batteryGaugeUpdater = batteryGaugeUpdater else {
                self.stateSubject.value = nil
                return
            }

            ULog.i(.tag, "Battery gauge state: \(batteryGaugeUpdater.state), "
                   + "progress: \(batteryGaugeUpdater.currentProgress), "
                   + "unavailabilityReasons:\(batteryGaugeUpdater.unavailabilityReasons.map { return $0.description })")
            self.batteryGaugeUpdater = batteryGaugeUpdater
            unavailabilityReasonsSubject.value = batteryGaugeUpdater.unavailabilityReasons
            stateSubject.value = batteryGaugeUpdater.state
            currentProgressSubject.value = batteryGaugeUpdater.currentProgress
        }
    }
}

// MARK: BatteryGaugeUpdaterService protocol conformance
extension BatteryGaugeUpdaterServiceImpl: BatteryGaugeUpdaterService {
    var unavailabilityReasonsPublisher: AnyPublisher<Set<BatteryGaugeUpdaterUnavailabilityReasons>, Never> {
        unavailabilityReasonsSubject.eraseToAnyPublisher()
    }
    var statePublisher: AnyPublisher<BatteryGaugeUpdaterState?, Never> { stateSubject.eraseToAnyPublisher() }
    var currentProgressPublisher: AnyPublisher<UInt, Never> { currentProgressSubject.eraseToAnyPublisher() }

    func prepareUpdate() {
        ULog.i(.tag, "Sending prepare update command")
        guard let updater = batteryGaugeUpdaterRef?.value else { return }
        updater.prepareUpdate()
    }

    func update() {
        ULog.i(.tag, "Sending update command")
        guard let updater = batteryGaugeUpdaterRef?.value else { return }
        updater.update()
    }
}
