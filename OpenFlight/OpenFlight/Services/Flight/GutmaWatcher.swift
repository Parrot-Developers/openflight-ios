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

import Foundation
import GroundSdk
import Combine

private extension ULogTag {
    static let tag = ULogTag(name: "GutmaWatcher")
}

public protocol GutmaWatcher: AnyObject {
    var flightEnded: AnyPublisher<FlightModel, Never> { get }
}

open class GutmaWatcherImpl {

    private enum Constants {
        static let lastFlightObservationDelay: TimeInterval = 15.0
    }

    private let userInfo: UserInformation
    private let service: FlightService

    private var cancellables = Set<AnyCancellable>()
    private var watchLastFlight = false
    private var watchLastFlightTimer: Timer?
    private var gutmaRef: Ref<GutmaLogManager>?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?
    private var oldFlyingIndicatorsState: FlyingIndicatorsState?

    private var flightEndedSubject = PassthroughSubject<FlightModel, Never>()

    init(userInfo: UserInformation, service: FlightService, currentDroneHolder: CurrentDroneHolder) {
        self.userInfo = userInfo
        self.service = service
        currentDroneHolder.dronePublisher
            .sink { [unowned self] in listenFlyingIndicators(drone: $0) }
            .store(in: &cancellables)
        listenGutmaLogs()
    }

    private func listenGutmaLogs() {
        gutmaRef = GroundSdk().getFacility(Facilities.gutmaLogManager) { [unowned self] gutmaLogManager in
            guard let files = gutmaLogManager?.files else {
                return
            }
            let models = files.compactMap { [unowned self] in toFlight(gutmaUrl: $0) }
            service.save(gutmaOutput: models)

            files.forEach { urlFile in
                _ = gutmaLogManager?.delete(file: urlFile)
            }
            if watchLastFlight, let lastFlight = models.first {
                watchLastFlight = false
                watchLastFlightTimer?.invalidate()
                flightEndedSubject.send(lastFlight.flight)
            }
        }
    }

    private func listenFlyingIndicators(drone: Drone) {
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [unowned self] flyingIndicators in
            guard let flyingIndicators = flyingIndicators else {
                return
            }
            switch (flyingIndicators.state, oldFlyingIndicatorsState) {
            case (.landed, .flying),
                 (.emergencyLanding, .flying),
                 (.landed, .emergencyLanding):
                watchLastFlight = true
                watchLastFlightTimer?.invalidate()
                watchLastFlightTimer = Timer.scheduledTimer(withTimeInterval: Constants.lastFlightObservationDelay, repeats: false, block: { _ in
                    watchLastFlight = false
                })
            default:
                break
            }
            oldFlyingIndicatorsState = flyingIndicators.state
        }
    }

    private func toFlight(gutmaUrl: URL) -> Gutma.Model? {
        guard let data = try? Data(contentsOf: gutmaUrl),
              let gutma = service.gutma(data: data) else {
            ULog.e(.tag, "Failed to parse gutma file at \(gutmaUrl)")
            return nil
        }
        return gutma.toFlight(apcId: userInfo.apcId, gutmaFile: data)
    }
}

extension GutmaWatcherImpl: GutmaWatcher {
    public var flightEnded: AnyPublisher<FlightModel, Never> { flightEndedSubject.eraseToAnyPublisher() }
}
