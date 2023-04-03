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

/// Output of `UpdateService`: exposes udpate state.
public enum UpdateState: Equatable {
    /// Device is up to date.
    case upToDate
    /// Device update is recommended.
    case recommended
    /// Device update is required.
    case required

    /// Whether an update is available.
    var isAvailable: Bool {
        self == .recommended || self == .required
    }
}

/// Update service.
public protocol UpdateService: AnyObject {
    /// Publisher for drone update state.
    var droneUpdatePublisher: AnyPublisher<UpdateState?, Never> { get }
    /// Publisher for remote control update state.
    var remoteUpdatePublisher: AnyPublisher<UpdateState?, Never> { get }
}

/// Implementation of `UpdateService`.
class UpdateServiceImpl {

    // MARK: Private properties

    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()
    /// References to peripherals.
    private var droneUpdaterRef: Ref<Updater>?
    private var droneSystemInfoRef: Ref<SystemInfo>?
    private var remoteUpdaterRef: Ref<Updater>?
    private var remoteSystemInfoRef: Ref<SystemInfo>?
    /// Drone update state.
    private var droneUpdateSubject = CurrentValueSubject<UpdateState?, Never>(nil)
    /// Remote control update state.
    private var remoteUpdateSubject = CurrentValueSubject<UpdateState?, Never>(nil)

    // MARK: init

    /// Constructor.
    ///
    /// - Parameters:
    ///   - currentDroneHolder: drone holder
    ///   - currentRemoteControlHolder: remote control holder
    init(currentDroneHolder: CurrentDroneHolder,
         currentRemoteControlHolder: CurrentRemoteControlHolder) {
        listen(currentDroneHolder: currentDroneHolder)
        listen(currentRemoteControlHolder: currentRemoteControlHolder)
    }
}

// MARK: Private functions
private extension UpdateServiceImpl {

    /// Listens to current drone.
    ///
    /// - Parameter currentDroneHolder: drone holder
    func listen(currentDroneHolder: CurrentDroneHolder) {
        currentDroneHolder.dronePublisher
            .sink { [unowned self] drone in
                listenDroneUpdater(drone: drone)
                listenDroneSystemInfo(drone: drone)
            }
            .store(in: &cancellables)
    }

    /// Listens to current remote control.
    ///
    /// - Parameter currentRemoteControlHolder: remote control holder
    func listen(currentRemoteControlHolder: CurrentRemoteControlHolder) {
        currentRemoteControlHolder.remoteControlPublisher
            .sink { [unowned self] in
                guard let remoteControl = $0 else {
                    return
                }
                listenRemoteUpdater(remoteControl: remoteControl)
                listenRemoteSystemInfo(remoteControl: remoteControl)
            }
            .store(in: &cancellables)
    }

    /// Listens to drone updater changes.
    ///
    /// - Parameter drone: drone to monitor
    func listenDroneUpdater(drone: Drone) {
        droneUpdaterRef = drone.getPeripheral(Peripherals.updater) { [unowned self] updater in
            droneUpdateSubject.value = drone.isSimulator ? .upToDate : getDroneUpdateState(updater: updater, systemInfo: droneSystemInfoRef?.value)
        }
    }

    /// Listens to drone system info changes.
    ///
    /// - Parameter drone: drone to monitor
    func listenDroneSystemInfo(drone: Drone) {
        droneSystemInfoRef = drone.getPeripheral(Peripherals.systemInfo) { [unowned self] systemInfo in
            droneUpdateSubject.value = drone.isSimulator ? .upToDate : getDroneUpdateState(updater: droneUpdaterRef?.value, systemInfo: systemInfo)
        }
    }

    /// Retrieves drone update state from updater and system info.
    ///
    /// - Parameters:
    ///   - updater: the drone updater
    ///   - systemInfo: the drone system info
    func getDroneUpdateState(updater: Updater?, systemInfo: SystemInfo?) -> UpdateState? {
        if let updater = updater {
            if !updater.applicableFirmwares.isEmpty
                || (systemInfo?.isFirmwareBlacklisted == true
                    && !updater.downloadableFirmwares.isEmpty) {
                return .required
            } else if !updater.downloadableFirmwares.isEmpty {
                return .recommended
            } else {
                return .upToDate
            }
        } else {
            return nil
        }
    }

    /// Listens to remote control updater changes.
    ///
    /// - Parameter remoteControl: remote control to monitor
    func listenRemoteUpdater(remoteControl: RemoteControl) {
        remoteUpdaterRef = remoteControl.getPeripheral(Peripherals.updater) { [unowned self] updater in
            remoteUpdateSubject.value = getRemoteUpdateState(updater: updater, systemInfo: remoteSystemInfoRef?.value)
        }
    }

    /// Listens to remote control system info changes.
    ///
    /// - Parameter remoteControl: remote control to monitor
    func listenRemoteSystemInfo(remoteControl: RemoteControl) {
        remoteSystemInfoRef = remoteControl.getPeripheral(Peripherals.systemInfo) { [unowned self] systemInfo in
            remoteUpdateSubject.value = getRemoteUpdateState(updater: remoteUpdaterRef?.value, systemInfo: systemInfo)
        }
    }

    /// Retrieves remote control update state from updater and system info.
    ///
    /// - Parameters:
    ///   - updater: the remote control updater
    ///   - systemInfo: the remote control system info
    func getRemoteUpdateState(updater: Updater?, systemInfo: SystemInfo?) -> UpdateState? {
        if let updater = updater {
            if systemInfo?.isFirmwareBlacklisted == true
                && !updater.downloadableFirmwares.isEmpty {
                return .required
            } else if updater.isUpToDate {
                return .upToDate
            } else {
                return .recommended
            }
        } else {
            return nil
        }
    }
}

// MARK: `UpdateService` protocol conformance
extension UpdateServiceImpl: UpdateService {

    var droneUpdatePublisher: AnyPublisher<UpdateState?, Never> { droneUpdateSubject.eraseToAnyPublisher() }

    var remoteUpdatePublisher: AnyPublisher<UpdateState?, Never> { remoteUpdateSubject.eraseToAnyPublisher() }
}
