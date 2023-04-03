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

import Combine
import GroundSdk

class BatteryUpdateChecklistViewModel {
    private var batteryGaugeUpdaterService: BatteryGaugeUpdaterService
    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()
    /// Subject for the datasource.
    private var datasourceSubject = CurrentValueSubject<[BatteryUpdateReasonsCellContent], Never>([])
    /// Publisher for the datasource.
    var datasourcePublisher: AnyPublisher<[BatteryUpdateReasonsCellContent], Never> {
        datasourceSubject.eraseToAnyPublisher()
    }
    /// The datasource contains the list of requirements to check before update.
    var datasource: [BatteryUpdateReasonsCellContent] {
        set { datasourceSubject.value = newValue }
        get { datasourceSubject.value }
    }

    /// The list of unavailability reasons given by the peripheral
    @Published var unavailabilityReasons: Set<BatteryGaugeUpdaterUnavailabilityReasons> = []

    /// Init
    /// - Parameter batteryGaugeUpdaterService: the injected battery gauge updater service
    init(batteryGaugeUpdaterService: BatteryGaugeUpdaterService) {
        self.batteryGaugeUpdaterService = batteryGaugeUpdaterService
        listenBatteryUpdater()
    }

    /// Listens to the battery updater periphperal and updates the unavailability reasons.
    func listenBatteryUpdater() {
        batteryGaugeUpdaterService.unavailabilityReasonsPublisher
            .sink { [weak self] unavailabilityReasons in
                guard let self = self else { return }
                self.unavailabilityReasons = unavailabilityReasons
                self.updateReasonsList(unavailabilityReasons)
            }
            .store(in: &cancellables)
    }

    /// Updates the datasource with the list of unavailability reasons.
    /// - Parameter unavailabilityReasons: set of unavailability reasons given by the peripheral
    func updateReasonsList(_ unavailabilityReasons: Set<BatteryGaugeUpdaterUnavailabilityReasons>) {
        let droneCell = cellContent(
            unavailable: unavailabilityReasons.contains(.droneNotLanded),
            title: L10n.batteryUpdateDroneLanded)
        let chargeCell = cellContent(
            unavailable: unavailabilityReasons.contains(.insufficientCharge),
            title: L10n.batteryUpdateCharge)
        let usbCell = cellContent(
            unavailable: unavailabilityReasons.contains(.notUsbPowered),
            title: L10n.batteryUpdateUsbPowered)
        datasource = [droneCell, chargeCell, usbCell]
    }


    /// Returns a cell content for the table view.
    /// - Parameters:
    ///     - unavailable: `true` if the element is in the unavailability reasons (the requrement is not met)
    ///     - title: title of the requirement
    /// - Returns: the cell content
    private func cellContent(unavailable: Bool, title: String) -> BatteryUpdateReasonsCellContent {
        return BatteryUpdateReasonsCellContent(
            status: unavailable ? .bad : .good,
            text: title)
    }
}
