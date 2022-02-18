//    Copyright (C) 2021 Parrot Drones SAS
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
import SwiftyUserDefaults

public protocol CellularPairingAvailabilityService: AnyObject {

    func updateAvailabilityState()

    var isPairingProcessDismissedPublisher: AnyPublisher<Bool, Never> { get }
    var isCellularAvailablePublisher: AnyPublisher<Bool, Never> { get }
    var isDroneAlreadyPairedPublisher: AnyPublisher<Bool, Never> { get }

}

class CellularPairingAvailabilityServiceImpl {

    private var cellularRef: Ref<Cellular>?
    private var pairingModalObserver: DefaultsDisposable?
    private var academyApiService: AcademyApiService
    private var dronesPairedObserver: DefaultsDisposable?
    private var currentDroneHolder: CurrentDroneHolder
    private var connectedDroneHolder: ConnectedDroneHolder
    private var cellularPairingService: CellularPairingService
    private var cancellables = Set<AnyCancellable>()

    var isPairingProcessDismissedSubject = CurrentValueSubject<Bool, Never>(false)
    var isCellularAvailableSubject = CurrentValueSubject<Bool, Never>(false)
    var isDroneAlreadyPairedSubject = CurrentValueSubject<Bool, Never>(false)

    init(currentDroneHolder: CurrentDroneHolder,
         connectedDroneHolder: ConnectedDroneHolder,
         academyApiService: AcademyApiService,
         cellularPairingService: CellularPairingService) {
        self.currentDroneHolder = currentDroneHolder
        self.connectedDroneHolder = connectedDroneHolder
        self.academyApiService = academyApiService
        self.cellularPairingService = cellularPairingService
        listenDronesPairedList()
        listenPairingModalDefaults()
        listenPairingAvailability()

        connectedDroneHolder.dronePublisher
            .compactMap { $0 }
            .sink { [unowned self] drone in
                listenCellular(drone)
                updatePairedDronesIfNeeded()
            }
            .store(in: &cancellables)
    }
}

extension CellularPairingAvailabilityServiceImpl: CellularPairingAvailabilityService {

    // MARK: - Internal Funcs
    /// Updates cellular pairing process availability state.
    func updateAvailabilityState() {
        updateCellularAvailability(with: connectedDroneHolder.drone?.getPeripheral(Peripherals.cellular))
        updateDronePairingState()
    }
}

private extension CellularPairingAvailabilityServiceImpl {

    /// Updates visibility of the process according to drone list.
    func updateVisibilityState() {
        guard connectedDroneHolder.drone?.isConnected != nil else { return }

        let uid = connectedDroneHolder.drone?.uid

        isPairingProcessDismissedSubject.value = Defaults.dronesListPairingProcessHidden.customContains(uid)
    }

    /// Observes default to checks if the pairing modal has been already dismissed.
    func listenPairingModalDefaults() {
        pairingModalObserver = Defaults.observe(\.dronesListPairingProcessHidden) { [weak self] _ in
            self?.updateVisibilityState()
        }

        updateVisibilityState()
    }

    /// Starts watcher for Cellular.
    func listenCellular(_ drone: Drone) {
        cellularRef = drone.getPeripheral(Peripherals.cellular) { [weak self] cellular in
            self?.updateCellularAvailability(with: cellular)
        }
        updateCellularAvailability(with: drone.getPeripheral(Peripherals.cellular))
    }

    /// Updates cellular availability state.
    ///
    /// - Parameters:
    ///     - cellular: current cellular reference's value
    func updateCellularAvailability(with cellular: Cellular?) {
        isCellularAvailableSubject.value = cellular?.isSimCardInserted == true
    }

    /// Update local paired drone list with Academy call.
    func updatePairedDronesIfNeeded() {
        academyApiService.performPairedDroneListRequest { cellularPairedDronesList in
            guard cellularPairedDronesList != nil else {
                self.updateDronePairingState()
                return
            }

            let pairedList = cellularPairedDronesList?
                .filter({ $0.pairedFor4G == true })
                .compactMap { return $0.serial } ?? []

            Defaults.cellularPairedDronesList = pairedList

            // User account update should be done on the main Thread.
            DispatchQueue.main.async {
                self.updateDronePairingState()
                guard let jsonString: String = ParserUtils.jsonString(cellularPairedDronesList),
                      let userAccount = GroundSdk().getFacility(Facilities.userAccount) else {
                    return
                }

                // Updates UserAccount paired drones list.
                userAccount.set(droneList: jsonString)
            }
        }
    }

    /// Checks if the drone is already paired.
    func updateDronePairingState() {
        isDroneAlreadyPairedSubject.value = currentDroneHolder.drone.isAlreadyPaired == true
    }

    /// Starts watcher for drones already paired list.
    func listenDronesPairedList() {
        dronesPairedObserver = Defaults.observe(\.cellularPairedDronesList) { [weak self] _ in
            self?.updateDronePairingState()
            self?.updatePairedDronesIfNeeded()
        }
    }

    /// When pairing is available, start a pairing process
    func listenPairingAvailability() {
        connectedDroneHolder.dronePublisher
            .combineLatest(isCellularAvailablePublisher.removeDuplicates(),
                           isDroneAlreadyPairedPublisher.removeDuplicates())
            .sink { [unowned self] (drone, isCellularAvailable, isDroneAlreadyPaired) in
                guard isCellularAvailable,
                      drone?.state.connectionState == .connected,
                      !isDroneAlreadyPaired else { return }
                cellularPairingService.startPairingProcessRequest()
            }
            .store(in: &cancellables)
    }
}

extension CellularPairingAvailabilityServiceImpl {

    var isPairingProcessDismissedPublisher: AnyPublisher<Bool, Never> { isPairingProcessDismissedSubject.eraseToAnyPublisher() }
    var isCellularAvailablePublisher: AnyPublisher<Bool, Never> { isCellularAvailableSubject.eraseToAnyPublisher() }
    var isDroneAlreadyPairedPublisher: AnyPublisher<Bool, Never> { isDroneAlreadyPairedSubject.eraseToAnyPublisher() }
}
