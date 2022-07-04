//    Copyright (C) 2022 Parrot Drones SAS
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
import Combine
import GroundSdk

final class DroneDetailsBatteryViewModel {

    private struct Constants {
        static let kelvinTemperature = 273.15
    }

    @Published private(set) var capacity: String = Style.dash
    @Published private(set) var health: String = Style.dash
    @Published private(set) var cycles: String = Style.dash
    @Published private(set) var temperature: String = Style.dash
    @Published private(set) var serialNumber: String = Style.dash
    @Published private(set) var totalVoltage: String = Style.dash
    @Published private(set) var voltage1: String = Style.dash
    @Published private(set) var voltage2: String = Style.dash
    @Published private(set) var voltage3: String = Style.dash
    @Published private(set) var progress1: Float = 0.0
    @Published private(set) var progress2: Float = 0.0
    @Published private(set) var progress3: Float = 0.0

    private weak var coordinator: DroneCoordinator?
    private var batteryRef: Ref<BatteryInfo>?
    private let connectedDroneHolder: ConnectedDroneHolder
    private var cancellables = Set<AnyCancellable>()
    init(coordinator: DroneCoordinator, connectedDroneHolder: ConnectedDroneHolder) {
        self.coordinator = coordinator
        self.connectedDroneHolder = connectedDroneHolder

        connectedDroneHolder.dronePublisher
            .removeDuplicates()
            .sink { [weak self] drone in
                guard let self = self else { return }
                self.listenBatteryInfo(drone)
            }
            .store(in: &cancellables)
    }

    func dismissView() {
        coordinator?.dismiss()
    }
}

private extension DroneDetailsBatteryViewModel {

    func listenBatteryInfo(_ drone: Drone?) {
        batteryRef = drone?.getInstrument(Instruments.batteryInfo) { [weak self] batteryInfos in
            guard let self = self else { return }
            self.updateBatteryInfo(batteryInfos: batteryInfos)
            self.setTotalVoltage(batteryInfos: batteryInfos)
            self.setVoltage(batteryInfos: batteryInfos)
            self.setProgress(batteryInfos: batteryInfos)
        }
    }

    func updateBatteryInfo(batteryInfos: BatteryInfo?) {
        guard batteryInfos != nil else {
            dismissView()
            return
        }
        health = batteryInfos?.batteryHealth.flatMap { String($0) + "%" } ?? Style.dash
        cycles = batteryInfos?.cycleCount.flatMap { String($0) } ?? Style.dash
        serialNumber = batteryInfos?.batteryDescription?.serial ?? Style.dash
        temperature = batteryInfos?.temperature.flatMap { String(format: "%.1f", Double($0) - Constants.kelvinTemperature) + " °C" } ?? Style.dash
        capacity = batteryInfos?.capacity.flatMap { String($0.fullChargeCapacity) + " mAH" } ?? Style.dash
    }

    func setTotalVoltage(batteryInfos: BatteryInfo?) {
        guard let batteryInfos = batteryInfos,
              let batteryDescription = batteryInfos.batteryDescription,
              !batteryInfos.cellVoltages.isEmpty,
              batteryInfos.cellVoltages.count == batteryDescription.cellCount
        else {
            totalVoltage = Style.dash
            return
        }

        let cellVoltage = batteryInfos
            .cellVoltages
            .compactMap { $0 }

        guard cellVoltage.count >= 3 else { return }

        let totalCellVoltages = Double(cellVoltage[0] + cellVoltage[1] + cellVoltage[2])

        totalVoltage = String(format: "%.1f", totalCellVoltages/1000.0) + "V"
    }

    func setVoltage(batteryInfos: BatteryInfo?) {
        guard let batteryInfos = batteryInfos,
              let batteryDescription = batteryInfos.batteryDescription,
              !batteryInfos.cellVoltages.isEmpty,
              batteryInfos.cellVoltages.count == batteryDescription.cellCount
        else {
            voltage1 = Style.dash
            voltage2 = Style.dash
            voltage3 = Style.dash
            return
        }

        let stringCellVoltage = batteryInfos
            .cellVoltages
            .compactMap { $0 }
            .map { String($0) }

        guard stringCellVoltage.count >= 3 else { return }

        voltage1 = stringCellVoltage[0] + "mV"
        voltage2 = stringCellVoltage[1] + "mV"
        voltage3 = stringCellVoltage[2] + "mV"
    }

    func setProgress(batteryInfos: BatteryInfo?) {
        guard let batteryInfos = batteryInfos,
              let cellMaxVoltage = batteryInfos.batteryDescription?.cellMaxVoltage,
              let batteryDescription = batteryInfos.batteryDescription,
              !batteryInfos.cellVoltages.isEmpty,
              batteryInfos.cellVoltages.count == batteryDescription.cellCount,
              cellMaxVoltage != 0 else {
            progress1 = 0.0
            progress2 = 0.0
            progress3 = 0.0
            return
        }

        let cellVoltages = batteryInfos
            .cellVoltages
            .compactMap { $0 }

        guard cellVoltages.count >= 3 else { return }

        let minVoltage = Float(batteryDescription.cellMinVoltage)
        let maxVoltage = Float(cellMaxVoltage)

        let cellVoltage1 = Float(cellVoltages[0])
        let cellVoltage2 = Float(cellVoltages[1])
        let cellVoltage3 = Float(cellVoltages[2])

        if maxVoltage == minVoltage { return }

        progress1 = (cellVoltage1 - minVoltage)/(maxVoltage - minVoltage)
        progress2 = (cellVoltage2 - minVoltage)/(maxVoltage - minVoltage)
        progress3 = (cellVoltage3 - minVoltage)/(maxVoltage - minVoltage)
    }
}
