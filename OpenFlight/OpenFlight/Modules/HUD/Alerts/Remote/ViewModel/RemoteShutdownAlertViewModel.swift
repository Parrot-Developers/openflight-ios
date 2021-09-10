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

import Foundation
import Combine
import GroundSdk

final class RemoteShutdownAlertViewModel {

    // MARK: - Published Properties

    /// Duration before mpp shutdown.
    @Published private(set) var durationBeforeShutDown: TimeInterval = 0.0
    @Published private(set) var connectionState: DeviceState.ConnectionState = .disconnected
    @Published private var firstTimeButtonPressed: Bool = true
    @Published private(set) var isShutdownProcessDone: Bool = false
    @Published var isShutdownButtonPressed: Bool = false

    /// Helpes to know if the alert has to be displayed.
    var canShowModal: AnyPublisher<Bool, Never> {
        $connectionState
            .combineLatest($durationBeforeShutDown)
            .map { (connectionState, durationBeforeShutDown) in
                return durationBeforeShutDown > 0.0 && connectionState == .connected
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Private properties

    private var remoteControleStateRef: Ref<DeviceState>?
    private var connectedRemote = Services.hub.connectedRemoteControlHolder
    private var cancellables = Set<AnyCancellable>()

    init() {
        connectedRemote.remoteControlPublisher
            .compactMap { $0 }
            .sink { [unowned self] remoteControl in
                listenRemoteControl(remoteControl: remoteControl)
            }
            .store(in: &cancellables)

        $firstTimeButtonPressed
            .combineLatest($connectionState, $durationBeforeShutDown)
            .sink { [weak self] (firstTimeButtonPressed, connectionState, durationBeforeShutDown) in
                let condition = durationBeforeShutDown == 0.0 && firstTimeButtonPressed == false
                self?.isShutdownButtonPressed = condition && connectionState == .connected
            }
            .store(in: &cancellables)
    }

    func updateFirstTimeButton() {
        firstTimeButtonPressed = false
    }

    func updateShutdownProcess() {
        isShutdownProcessDone = true
    }

    private func listenRemoteControl(remoteControl: RemoteControl) {
        remoteControleStateRef = remoteControl.getState { [weak self] deviceState in
            guard let remoteState = deviceState else { return }
            self?.connectionState = remoteState.connectionState
            self?.durationBeforeShutDown = remoteState.durationBeforeShutDown
        }
    }
}
