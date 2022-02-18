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
import Combine

public class DashboardMyFlightsCellModel {

    public let service: FlightService
    public let cloudSynchroWatcher: CloudSynchroWatcher?

    public var lastFlight: AnyPublisher<FlightModel?, Never> { service.lastFlight }
    private var isSynchronizingSubject = CurrentValueSubject<Bool, Never>(false)
    private var summarySubject = PassthroughSubject<AllFlightsSummary, Never>()
    private var cancellable = Set<AnyCancellable>()

    init(service: FlightService,
         cloudSynchroWatcher: CloudSynchroWatcher?) {
        self.service = service
        self.cloudSynchroWatcher = cloudSynchroWatcher
        self.service.updateFlights()
        cloudSynchroWatcher?.isSynchronizingDataPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] isSynch in
                self?.isSynchronizingSubject.value = isSynch
            }.store(in: &cancellable)

        service.allFlightsSummary
            .receive(on: RunLoop.main)
            .sink { [weak self] flightsSummary in
                self?.summarySubject.send(flightsSummary)
            }.store(in: &cancellable)
    }

    func reloadAllFlights() {
        service.updateFlights()
    }

    var isSynchronizingData: AnyPublisher<Bool, Never> {
        isSynchronizingSubject.eraseToAnyPublisher()
    }

    public var summary: AnyPublisher<AllFlightsSummary, Never> { summarySubject.eraseToAnyPublisher()  }

}
