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
import CoreData

/// State for `FlightReportViewModel`.

final class FlightReportState: ViewModelState, EquatableState, Copying {
    // MARK: - Internal Properties
    /// Whether a flight report should be displayed.
    fileprivate(set) var shouldDisplayFlightReport: Bool = false

    // MARK: - Init
    required init() { }

    /// Init.
    ///
    /// - Parameters:
    ///    - shouldDisplayFlightReport: whether a flight report should be displayed
    init(shouldDisplayFlightReport: Bool) {
        self.shouldDisplayFlightReport = shouldDisplayFlightReport
    }

    // MARK: - Equatable
    func isEqual(to other: FlightReportState) -> Bool {
        return self.shouldDisplayFlightReport == other.shouldDisplayFlightReport
    }

    // MARK: - Copying
    func copy() -> FlightReportState {
        return FlightReportState(shouldDisplayFlightReport: self.shouldDisplayFlightReport)
    }
}

/// View model for flight report display in HUD.

final class FlightReportViewModel: DroneWatcherViewModel<FlightReportState> {
    // MARK: - Private Properties
    private var gutmaLogsDownloadObserver: Any?
    private var gutmaLogsObservationTimer: Timer?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?
    private var oldFlyingIndicatorsState: FlyingIndicatorsState?

    // MARK: - Private Enums
    private enum Constants {
        static let gutmaLogsObservationDelay: TimeInterval = 15.0
    }

    // MARK: - Deinit
    deinit {
        removeGutmaLogsDownloadObserver()
        removeTimer()
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        listenFlyingIndicators(drone: drone)
    }
}

// MARK: - Private Funcs
private extension FlightReportViewModel {
    /// Starts watcher for drone's flying indicators.
    func listenFlyingIndicators(drone: Drone) {
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [weak self] flyingIndicators in
            guard let flyingIndicators = flyingIndicators else {
                return
            }
            switch (flyingIndicators.state, self?.oldFlyingIndicatorsState) {
            case (.landed, .flying),
                 (.emergencyLanding, .flying),
                 (.landed, .emergencyLanding):
                self?.addGutmaLogsDownloadObserver()
            default:
                break
            }
            if flyingIndicators.flyingState == .takingOff {
                let copy = self?.state.value.copy()
                copy?.shouldDisplayFlightReport = false
                self?.state.set(copy)
            }
            self?.oldFlyingIndicatorsState = flyingIndicators.state
        }
    }

    /// Starts observer for gutma logs download.
    func addGutmaLogsDownloadObserver() {
        removeTimer()

        guard let context = CoreDataManager.shared.currentContext else {
            return
        }

        gutmaLogsDownloadObserver = NotificationCenter.default
            .addObserver(forName: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                         object: context,
                         queue: nil) { [weak self] notification in
                            guard let userInfo = notification.userInfo,
                                let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>,
                                inserts.contains(where: { $0 is FlightDataModel })
                                else {
                                    return
                            }
                            let copy = self?.state.value.copy()
                            copy?.shouldDisplayFlightReport = true
                            self?.state.set(copy)
        }

        // Observer should be removed after a delay to avoid notification from old gutmas download.
        gutmaLogsObservationTimer = Timer.scheduledTimer(withTimeInterval: Constants.gutmaLogsObservationDelay,
                                                         repeats: false) { [weak self] _ in
                                                            self?.removeGutmaLogsDownloadObserver()
                                                            self?.removeTimer()
        }
    }

    /// Removes timer for gutma logs download.
    func removeTimer() {
        gutmaLogsObservationTimer?.invalidate()
        gutmaLogsObservationTimer = nil
    }

    /// Removes observer for gutma logs download.
    func removeGutmaLogsDownloadObserver() {
        NotificationCenter.default.remove(observer: gutmaLogsDownloadObserver)
        gutmaLogsDownloadObserver = nil
    }
}
