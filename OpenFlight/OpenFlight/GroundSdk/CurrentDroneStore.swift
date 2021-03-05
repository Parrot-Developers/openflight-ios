// Copyright (C) 2020 Parrot Drones SAS
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
import SwiftyUserDefaults

// MARK: - Internal Enums
enum DroneConstants {
    /// UID of the default drone.
    static let defaultDroneUid = DeviceModel.drone(.anafi2).defaultModelUid
}

/// Utility class that stores current drone uid to defaults.

public final class CurrentDroneStore {

    // MARK: - Constants
    private enum Constants {
        static let autoConnectionRestartDelay: TimeInterval = 1.0
    }

    // MARK: - Public Properties
    /// Currently stored drone uid.
    static var currentDroneUid: String {
        // Last connected or defaut drone uid.
        return Defaults[\.lastConnectedDroneUID] ?? DroneConstants.defaultDroneUid
    }

    // Returns the current connected drone if there is one.
    public static var currentConnectedDrone: Drone? {
        guard currentDroneUid != DeviceModel.drone(.anafi2).defaultModelUid,
              let drone = GroundSdk().getDrone(uid: CurrentDroneStore.currentDroneUid),
              drone.isConnected else {
            return nil
        }

        return drone
    }

    // MARK: - Private Properties
    private let groundSdk = GroundSdk()
    private var currentDroneWatcher = CurrentDroneWatcher()
    private var stateRef: Ref<DeviceState>?
    /// Ref on current drone dri.
    private var driRef: Ref<Dri>?

    // MARK: - Init
    public init() {
        currentDroneWatcher.start { [weak self] drone in
            self?.listenState(drone)
            self?.listenDri(drone)
        }
    }

    // MARK: - Public Funcs
    /// Removes last connected drone uid from user default if given uid matches with stored one.
    /// Use this method to complete drone forget action.
    ///
    /// - Parameters:
    ///    - uid: uid of the drone that needs to be cleared
    static func clearLastConnectedDroneIfNeeded(uid: String) {
        if Defaults.lastConnectedDroneUID == uid {
            // Temporary stop AutoConnection.
            GroundSdk().getFacility(Facilities.autoConnection)?.stop()
            // Remove from defaults.
            Defaults.remove(\.lastConnectedDroneUID)
            Defaults.remove(\.lastDriId)
            // Restarts AutoConnection after a delay.
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.autoConnectionRestartDelay) {
                GroundSdk().getFacility(Facilities.autoConnection)?.start()
            }
        }
    }
}

// MARK: - Private Funcs
private extension CurrentDroneStore {
    func listenState(_ drone: Drone) {
        stateRef = drone.getState { [weak self] state in
            if let state = state, state.connectionState == .connected {
                // Enable streaming by default.
                if !drone.isUpdating {
                    drone.getPeripheral(Peripherals.streamServer)?.enabled = true
                }

                // Store current drone.
                Defaults.lastConnectedDroneUID = drone.uid

                if let flightCameraRecorder = drone.getPeripheral(Peripherals.flightCameraRecorder) {
                    flightCameraRecorder.activePipelines.value = flightCameraRecorder.activePipelines.supportedValues
                }

                // Resets the media meta data customId if it is already set.
                // Can happen if there is a crash/killing app during a flight plan execution.
                if let customId = drone.getPeripheral(Peripherals.mainCamera2)?.mediaMetadata?.customId,
                   !customId.isEmpty,
                   self?.isDroneStillRunningFlightPlan(drone: drone, executionId: customId) == false {
                    drone.getPeripheral(Peripherals.mainCamera2)?.mediaMetadata?.customId = ""
                }
            }
        }
    }

    /// Checks if drone is running the flight plan after a connection lost.
    ///
    /// - Parameters:
    ///    - drone: drone
    ///    - executionId: flight plan execution
    func isDroneStillRunningFlightPlan(drone: Drone, executionId: String) -> Bool {
        guard drone.getPilotingItf(PilotingItfs.flightPlan)?.state == .active,
              let executions = FlightPlanManager.shared.currentFlightPlanViewModel?.executions,
              let execution = executions.first(where: { $0.executionId == executionId }) else {
            return false
        }

        return execution.state != .completed
    }

    /// Dri listener.
    func listenDri(_ drone: Drone) {
        driRef = drone.getPeripheral(Peripherals.dri) { dri in
            guard dri?.mode?.value == true,
                  let driId = dri?.droneId?.id else {
                return
            }

            Defaults.lastDriId = driId
        }
    }
}
