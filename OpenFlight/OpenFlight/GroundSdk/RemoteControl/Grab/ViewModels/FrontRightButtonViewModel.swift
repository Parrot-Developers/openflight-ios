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

import GroundSdk


private extension ULogTag {
    static let tag = ULogTag(name: "FrontRightButtonViewModel")
}

/// ViewModel which manages takeOff or Land remote control button.
final class FrontRightButtonViewModel: DroneStateViewModel<DeviceConnectionState> {

    // MARK: - Internal Funcs
    /// Called when front right button is touched up.
    ///
    /// - Parameters:
    ///     - state: sky controller event state
    func frontRightButtonTouchedUp(_ state: SkyCtrl4ButtonEventState) {
        guard state == .pressed else { return }

        performDroneAction()
    }
}

// MARK: - Private Funcs
private extension FrontRightButtonViewModel {
    /// Performs a drone action.
    /// Actions can be TakeOff, Land, HandLand or Hand Launch.
    func performDroneAction() {
        guard let drone = drone else {
            ULog.e(.tag, "performDroneAction, no drone")
            return
        }

        if drone.isStateFlying || drone.isHandLaunchReady {
            ULog.d(.tag, "performDroneAction, drone is flying or ready to handlaunch")
            takeOffOrLandDrone()
        } else {
            // Notifies that takeOff is requested.
            ULog.d(.tag, "performDroneAction, notify takeoff request")
            NotificationCenter.default.post(name: .takeOffRequestedDidChange,
                                            object: nil,
                                            userInfo: [HUDCriticalAlertConstants.takeOffRequestedNotificationKey: true])
            // Checks is there are no critical alerts.
            guard Services.hub.ui.criticalAlert.canTakeOff else {
                ULog.d(.tag, "performDroneAction, criticalAlert.canTakeOff is true ")
                return
            }

            takeOffOrLandDrone()
        }
    }

    /// Starts Take Off or Landing action.
    func takeOffOrLandDrone() {
        guard let drone = drone,
              let manualPilotingItf = drone.getPilotingItf(PilotingItfs.manualCopter) else {
                  ULog.e(.tag, "takeOffOrLandDrone manualPilotingItf or drone is null")
                  return
              }

        if !drone.isManualPilotingActive {
            // Deactivates RTH if it is the current pilotingItf.
            if drone.getPilotingItf(PilotingItfs.returnHome)?.state == .active {
                ULog.d(.tag, "takeOffOrLandDrone deactivate rth")
                _ = drone.getPilotingItf(PilotingItfs.returnHome)?.deactivate()
            } else {
                ULog.d(.tag, "takeOffOrLandDrone activate manual")
                _ = manualPilotingItf.activate()
            }
        }

        switch manualPilotingItf.smartTakeOffLandAction {
        case .thrownTakeOff:
            if Services.hub.drone.handLaunchService.canStart {
                ULog.d(.tag, "takeOffOrLandDrone execute thrownTakeOff")
                manualPilotingItf.thrownTakeOff()
            } else {
                ULog.d(.tag, "takeOffOrLandDrone execute takeOff")
                Services.hub.drone.handLaunchService.updateTakeOffButtonPressed(true)
                manualPilotingItf.takeOff()
            }
        case .takeOff:
            ULog.d(.tag, "takeOffOrLandDrone action is .takeOff")
            Services.hub.drone.handLaunchService.updateTakeOffButtonPressed(true)
            manualPilotingItf.takeOff()
        case .land:
            ULog.d(.tag, "takeOffOrLandDrone action is .land")
            manualPilotingItf.land()
        default:
            ULog.e(.tag, "takeOffOrLandDrone action is other: \(manualPilotingItf.smartTakeOffLandAction.description)")
            break
        }
    }
}
