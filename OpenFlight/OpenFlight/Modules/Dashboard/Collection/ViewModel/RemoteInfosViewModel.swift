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

// MARK: - RemoteInfosState
/// State for `RemoteInfosViewModel`.
final class RemoteInfosState: ViewModelState {
    // MARK: - Internal Properties
    /// Observable for current battery level.
    fileprivate(set) var remoteBatteryLevel: Observable<BatteryValueModel> = Observable(BatteryValueModel())
    /// Observable for current name.
    fileprivate(set) var remoteName: Observable<String> = Observable(String())
    /// Observable for current connection state.
    fileprivate(set) var remoteConnectionState: Observable<DeviceState.ConnectionState> = Observable(DeviceState.ConnectionState.disconnected)
    /// Observable for remote update.
    fileprivate(set) var remoteNeedUpdate: Observable<Bool> = Observable(false)
    /// Observable for remote update.
    fileprivate(set) var remoteUpdateVersion: Observable<String> = Observable(String())
    /// Observable for remote calibration.
    fileprivate(set) var remoteNeedCalibration: Observable<Bool> = Observable(false)
}

// MARK: - RemoteInfosViewModel
/// ViewModel for Remote Infos, notifies on battery level, state and name of the remote.
final class RemoteInfosViewModel: RemoteControlWatcherViewModel<RemoteInfosState> {
    // MARK: - Internal Properties
    /// Returns drone model.
    var remoteModel: String {
        return remoteControl?.publicName ?? state.value.remoteName.value
    }

    // MARK: - Private Properties
    private var batteryInfoRef: Ref<BatteryInfo>?
    private var nameRef: Ref<String>?
    private var connectionStateRef: Ref<DeviceState>?
    private var gsdk: GroundSdk = GroundSdk()
    private var updaterRef: Ref<Updater>?
    private var remoteMagnetometerRef: Ref<Magnetometer>?

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - batteryLevelDidChange: called when battery level changes
    ///    - nameDidChange: called when device name changes
    ///    - stateDidChange: called when state changes
    ///    - needUpdateDidChange: called when remote update availability changes
    ///    - remoteUpdateVersionDidChange: called when remote update version changes
    ///    - needCalibrationDidChange: called when remote calibration availability changes
    init(batteryLevelDidChange: ((BatteryValueModel) -> Void)? = nil,
         nameDidChange: ((String) -> Void)? = nil,
         stateDidChange: ((DeviceState.ConnectionState) -> Void)? = nil,
         needUpdateDidChange: ((Bool) -> Void)? = nil,
         remoteUpdateVersionDidChange: ((String) -> Void)? = nil,
         needCalibrationDidChange: ((Bool) -> Void)? = nil) {
        super.init()

        state.value.remoteBatteryLevel.valueChanged = batteryLevelDidChange
        state.value.remoteName.valueChanged = nameDidChange
        state.value.remoteConnectionState.valueChanged = stateDidChange
        state.value.remoteNeedUpdate.valueChanged = needUpdateDidChange
        state.value.remoteUpdateVersion.valueChanged = remoteUpdateVersionDidChange
        state.value.remoteNeedCalibration.valueChanged = needCalibrationDidChange
    }

    // MARK: - Override Funcs
    override func listenRemoteControl(remoteControl: RemoteControl) {
        listenBatteryLevel(remoteControl: remoteControl)
        listenName(remoteControl)
        listenConnectionState(remoteControl)
        queryRemoteUpdate()
        listenRemoteUpdate(remoteControl)
        listenRemoteMagnetometer(remoteControl)
    }
}

// MARK: - Private Funcs
private extension RemoteInfosViewModel {
    /// Starts watcher for remote battery.
    ///
    /// - Parameters:
    ///    - remoteControl: current Remote
    func listenBatteryLevel(remoteControl: RemoteControl) {
        batteryInfoRef = remoteControl.getInstrument(Instruments.batteryInfo) { [weak self] batteryInfo in
            self?.updateBatteryLevel(batteryInfo)
        }
    }

    /// Updates current battery level and state.
    ///
    /// - Parameters:
    ///    - batteryInfo: GroundSdk battery info instrument if available, `nil` otherwise
    func updateBatteryLevel(_ batteryInfo: BatteryInfo?) {
        let batteryValueModel = BatteryValueModel(currentValue: batteryInfo?.batteryLevel)
        state.value.remoteBatteryLevel.set(batteryValueModel)
    }

    /// Starts watcher for remote name.
    func listenName(_ remoteControl: RemoteControl) {
        nameRef = remoteControl.getName(observer: { [weak self] name in
            guard let name = name else {
                self?.state.value.remoteName.set(String())
                return
            }

            self?.state.value.remoteName.set(name)
        })
    }

    /// Starts watcher for connection state.
    func listenConnectionState(_ remoteControl: RemoteControl) {
        connectionStateRef = remoteControl.getState { [weak self] deviceState in
            self?.state.value.remoteConnectionState.set(deviceState?.connectionState)
        }
    }

    /// Query remote update.
    func queryRemoteUpdate() {
        gsdk.getFacility(Facilities.firmwareManager)?.queryRemoteUpdates()
    }

    /// Starts watcher for remote update.
    func listenRemoteUpdate(_ remoteControl: RemoteControl) {
        updaterRef = remoteControl.getPeripheral(Peripherals.updater) { [weak self] updater in
            guard let updater = updater else {
                self?.state.value.remoteNeedUpdate.set(false)
                self?.state.value.remoteUpdateVersion.set(nil)
                return
            }

            self?.state.value.remoteNeedUpdate.set(!updater.isUpToDate)
            self?.state.value.remoteUpdateVersion.set(updater.idealVersion?.description)
        }
    }

    /// Starts watcher for remote calibration.
    func listenRemoteMagnetometer(_ remoteControl: RemoteControl) {
        remoteMagnetometerRef = remoteControl.getPeripheral(Peripherals.magnetometer) { [weak self] magnetometer in
            self?.state.value.remoteNeedCalibration.set(magnetometer?.calibrationState == .required)
        }
    }
}
