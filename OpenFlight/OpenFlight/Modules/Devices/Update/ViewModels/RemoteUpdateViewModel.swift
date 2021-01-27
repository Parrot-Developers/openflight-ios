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

import UIKit
import GroundSdk
import Reachability

/// View Model for remote update process.

final class RemoteUpdateViewModel: DevicesStateViewModel<DeviceUpdateState>, DeviceUpdateProtocol {
    // MARK: - Internal Properties
    var rebootingErrorMessage: String {
        return L10n.remoteUpdateRebootingError
    }

    // MARK: - Private Properties
    private var remoteControlUpdaterRef: Ref<Updater>?
    private var reachability: Reachability?
    private var actionKey: String {
        return NSStringFromClass(type(of: self)) + SkyCtrl3ButtonEvent.frontBottomButton.description
    }

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///     - stateDidUpdate: callback to notify update state changes
    ///     - deviceUpdateStepDidUpdate: completion block to notify update step changes
    init(stateDidUpdate: ((DeviceUpdateState) -> Void)? = nil,
         deviceUpdateStepDidUpdate: ((DeviceUpdateStep) -> Void)? = nil) {
        super.init(stateDidUpdate: stateDidUpdate)
        self.state.value.deviceUpdateStep.valueChanged = deviceUpdateStepDidUpdate
        RemoteControlGrabManager.shared.disableRemoteControl()
    }

    // MARK: - Deinit
    deinit {
        reachability?.stopNotifier()
        RemoteControlGrabManager.shared.enableRemoteControl()
    }

    // MARK: - Override Funcs
    override func listenRemoteControl(remoteControl: RemoteControl) {
        super.listenRemoteControl(remoteControl: remoteControl)
        listenUpdater(remoteControl)
        listenReachability()
    }

    // MARK: - Internal Funcs
    /// Returns true if the user can start an update.
    func canStartUpdate() -> Bool {
        // Battery level.
        let updater = remoteControl?.getPeripheral(Peripherals.updater)
        return updater?.updateUnavailabilityReasons.contains(.notEnoughBattery) == false
    }

    /// Starts download or update process.
    func startUpdateProcess() {
        let updater = remoteControl?.getPeripheral(Peripherals.updater)
        if updater?.downloadableFirmwares.isEmpty == false {
            startDownload()
        } else if updater?.applicableFirmwares.isEmpty == false {
            startUpdate()
        }
    }

    /// Cancels the download or the update.
    func cancelUpdateProcess() {
        let updater = remoteControl?.getPeripheral(Peripherals.updater)
        let copy = state.value.copy()

        switch copy.deviceUpdateStep.value {
        case .downloadStarted:
            updater?.cancelDownload()
        case .downloadCompleted, .updateStarted, .uploading, .processing:
            updater?.cancelUpdate()
        default:
            break
        }
    }

    /// Checks if the network is reachable.
    func startNetworkReachability() {
        // Set a default state to nil when we start listen reachability.
        let copy = state.value.copy()
        copy.isNetworkReachable = nil
        self.state.set(copy)
        reachability?.stopNotifier()
        listenReachability()
    }
}

// MARK: - Private Funcs
private extension RemoteUpdateViewModel {
    /// Starts watcher for remote updater.
    ///
    /// - Parameters:
    ///     - remoteControl: current remote
    func listenUpdater(_ remoteControl: RemoteControl) {
        remoteControlUpdaterRef = remoteControl.getPeripheral(Peripherals.updater) { [weak self] updater in
            guard let updater = updater else {
                return
            }
            self?.updateCurrentDownload(updater)
            self?.updateCurrentUpdate(updater)
        }
    }

    /// Updates current download state.
    ///
    /// - Parameters:
    ///     - updater: current updater
    func updateCurrentDownload(_ updater: Updater) {
        guard let currentDownload = updater.currentDownload else {
            return
        }

        let copy = state.value.copy()
        switch currentDownload.state {
        case .downloading:
            copy.deviceUpdateStep.set(.downloadStarted)
        case .canceled:
            copy.deviceUpdateEvent = .downloadCanceled
        case .failed:
            copy.deviceUpdateEvent = .updateFailed
        case .success:
            copy.deviceUpdateStep.set(.downloadCompleted)
        }
        copy.currentProgress = currentDownload.currentProgress
        state.set(copy)
    }

    /// Updates current update state.
    ///
    /// - Parameters:
    ///     - updater: current updater
    func updateCurrentUpdate(_ updater: Updater) {
        guard let currentUpdate = updater.currentUpdate else {
            return
        }

        let copy = state.value.copy()
        switch currentUpdate.state {
        case .processing:
            copy.deviceUpdateStep.set(.processing)
        case .uploading:
            copy.deviceUpdateStep.set(.uploading)
        case .failed:
            copy.deviceUpdateEvent = .updateFailed
        case .canceled:
            copy.deviceUpdateEvent = .updateCanceled
        case .waitingForReboot:
            copy.deviceUpdateStep.set(.rebooting)
        case .success:
            copy.deviceUpdateStep.set(.updateCompleted)
        }
        copy.currentProgress = currentUpdate.currentProgress
        state.set(copy)
    }

    /// Starts watcher for reachability.
    func listenReachability() {
        let copy = state.value.copy()
        do {
            try reachability = Reachability()
            try reachability?.startNotifier()
        } catch {
            copy.isNetworkReachable = false
        }
        reachability?.whenReachable = { _ in
            copy.isNetworkReachable = true
            self.state.set(copy)
        }
        reachability?.whenUnreachable = {  _ in
            copy.isNetworkReachable = false
            self.state.set(copy)
        }
    }

    /// Starts download of the firmware.
    func startDownload() {
        remoteControl?.getPeripheral(Peripherals.updater)?.downloadAllFirmwares()
    }

    /// Starts update of the firmware.
    func startUpdate() {
        remoteControl?.getPeripheral(Peripherals.updater)?.updateToLatestFirmware()
    }
}
