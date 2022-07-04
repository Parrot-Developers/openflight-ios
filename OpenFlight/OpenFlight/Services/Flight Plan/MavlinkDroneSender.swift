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

public enum MavlinkDroneSenderError: Error {
    case noPilotingItf
    case uploadTimeout
    case uploadFailure
    case unknown
}

public protocol MavlinkDroneSender {
    func cleanup()
    func sendToDevice(_ path: String, customFlightPlanId: String, _ completion: @escaping (Result<Bool, MavlinkDroneSenderError>) -> Void)
}

public class MavlinkDroneSenderImpl {

    private let typeStore: FlightPlanTypeStore
    private var cancellables = Set<AnyCancellable>()
    private var pilotingItfRef: Ref<FlightPlanPilotingItf>?
    /// Completion closure for the upload part, only for internal use
    private var uploadCompletion: ((Result<Bool, MavlinkDroneSenderError>) -> Void)?
    private var waitUploadTimer: Timer?

    init(typeStore: FlightPlanTypeStore, currentDroneHolder: CurrentDroneHolder) {
        self.typeStore = typeStore
        listenPilotingItf(currentDroneHolder: currentDroneHolder)
    }

    public func cleanup() {
        waitUploadTimer?.invalidate()
        waitUploadTimer = nil
        uploadCompletion = nil
    }
}

extension MavlinkDroneSenderImpl: MavlinkDroneSender {
    public func sendToDevice(_ path: String, customFlightPlanId: String, _ completion: @escaping (Result<Bool, MavlinkDroneSenderError>) -> Void) {
        guard let pilotingItf = pilotingItfRef?.value else {
            completion(.failure(.noPilotingItf))
            return
        }
        uploadCompletion = completion
        waitUploadTimer = Timer.scheduledTimer(withTimeInterval: Constants.maxUploadWaitingTime, repeats: false) { [unowned self] _ in
            guard let uploadCompletion = uploadCompletion else { return }
            pilotingItf.cancelPendingUpload()
            uploadCompletion(.failure(.uploadTimeout))
        }
        waitUploadTimer?.tolerance = FlightPlanConstants.timerTolerance
        pilotingItf.uploadFlightPlan(filepath: path, customFlightPlanId: customFlightPlanId)
    }
}

private extension MavlinkDroneSenderImpl {

    enum Constants {
        static let maxUploadWaitingTime: TimeInterval = 10
    }

    func listenPilotingItf(currentDroneHolder: CurrentDroneHolder) {
        currentDroneHolder.dronePublisher.sink { [unowned self] in
            pilotingItfRef = $0.getPilotingItf(PilotingItfs.flightPlan) { [unowned self] pilotingItf in
                // Only interested when we have an upload going on
                guard let uploadCompletion = uploadCompletion else { return }

                // Proper cleanup on resolution
                let localCompletion: (Result<Bool, MavlinkDroneSenderError>) -> Void = {
                    self.cleanup()
                    uploadCompletion($0)
                }
                guard let pilotingItf = pilotingItf else {
                    localCompletion(.failure(.noPilotingItf))
                    return
                }
                switch pilotingItf.latestUploadState {
                case .uploading:
                    // Still waiting
                    return
                case .uploaded:
                    if pilotingItf.flightPlanFileIsKnown, pilotingItf.state == .idle {
                        localCompletion(.success(true))
                    }
                case .failed:
                    localCompletion(.failure(.uploadFailure))
                case .none:
                    localCompletion(.failure(.unknown))
                }
            }
        }
        .store(in: &cancellables)
    }
}
