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
import GroundSdk
import Combine

private extension ULogTag {
    static let tag = ULogTag(name: "RthService")
}

/// RTH service.
public protocol RthService: AnyObject {
    /// Indicates if RTH is currently active
    var isActive: Bool { get }
    /// Publisher for RTH active state.
    var isActivePublisher: AnyPublisher<Bool, Never> { get }
}

/// Implementation of `RthService`.
public class RthServiceImpl {

    // MARK: Private properties

    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()
    /// The RTH piloting interface reference.
    private var returnHomeRef: Ref<ReturnHomePilotingItf>?
    /// The RTH active state.
    private var isActiveSubject = CurrentValueSubject<Bool, Never>(false)

    // MARK: init

    /// Constructor.
    ///
    /// - Parameters:
    ///   - currentDroneHolder: drone holder
    public init(currentDroneHolder: CurrentDroneHolder) {
        // listen to drone changes
        listen(dronePublisher: currentDroneHolder.dronePublisher)
    }
}

// MARK: Private functions
private extension RthServiceImpl {

    /// Listens for the current drone.
    ///
    /// - Parameter dronePublisher: the drone publisher
    func listen(dronePublisher: AnyPublisher<Drone, Never>) {
        dronePublisher.sink { [weak self] drone in
            self?.listenToRth(drone: drone)
        }
        .store(in: &cancellables)
    }

    /// Listens to drone's RTH state.
    ///
    /// - Parameter drone: drone to monitor
    func listenToRth(drone: Drone) {
        returnHomeRef = drone.getPilotingItf(PilotingItfs.returnHome) { [weak self] _ in
            ULog.i(.tag, "updateReturnHomeState isReturningHome: \(drone.isReturningHome) isForceLandingInProgress: \(drone.isForceLandingInProgress)")
            self?.isActiveSubject.value = drone.isReturningHome && !drone.isForceLandingInProgress
        }
    }
}

// MARK: RthService protocol conformance
extension RthServiceImpl: RthService {
    public var isActivePublisher: AnyPublisher<Bool, Never> { isActiveSubject.eraseToAnyPublisher() }
    public var isActive: Bool { isActiveSubject.value }
}
