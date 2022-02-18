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

import UIKit
// import GroundSdk library.
import GroundSdk

/// GroundSdk Hello Drone Sample
///
/// This view controller allows the application to connect to a drone and/or a remote control.
/// It displays the connection state, battery level and video stream.
/// It allows to take off and land by button click.
class ParrotDebugStreamVC: UIViewController {

    /// Ground SDk instance.
    private let groundSdk = GroundSdk()
    /// Reference to auto connection.
    private var autoConnectionRef: Ref<AutoConnection>?

    // Drone:
    /// Current drone instance.
    private var drone: Drone?
    /// Reference to the current drone stream server Peripheral.
    private var streamServerRef: Ref<StreamServer>?
    /// Reference to the current drone live stream.
    private var liveStreamRef: Ref<CameraLive>?

    // User Interface:
    /// Video stream view.
    @IBOutlet weak var streamView: StreamView!
    /// Drone state text view.

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Reset user interface
        resetDroneUi()

        // Monitor the auto connection facility.
        // Keep the reference to be notified on update.
        autoConnectionRef = groundSdk.getFacility(Facilities.autoConnection) { [weak self] autoConnection in
            // Called when the auto connection facility is available and when it changes.

            if let self = self, let autoConnection = autoConnection {
                // Start auto connection.
                if autoConnection.state != AutoConnectionState.started {
                    autoConnection.start()
                }

                // If the drone has changed.
                if self.drone?.uid != autoConnection.drone?.uid {
                    if self.drone != nil {
                        // Stop to monitor the old drone.
                        self.stopDroneMonitors()

                        // Reset user interface drone part.
                        self.resetDroneUi()
                    }

                    // Monitor the new drone.
                    self.drone = autoConnection.drone
                    if self.drone != nil {
                        self.startDroneMonitors()
                    }
                }
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resetDroneUi()
        stopDroneMonitors()
    }

    /// Resets drone user interface part.
    private func resetDroneUi() {
        // Stop rendering the stream
        liveStreamRef?.value?.stop()
        streamView.setStream(stream: nil)
    }

    /// Starts drone monitors.
    private func startDroneMonitors() {
        // Start video stream.
        startVideoStream()
    }

    /// Stops drone monitors.
    private func stopDroneMonitors() {
        // Forget references linked to the current drone to stop their monitoring.
        liveStreamRef = nil
        streamServerRef = nil
    }

    /// Starts the video stream.
    private func startVideoStream() {
        // Monitor the stream server.
        streamServerRef = drone?.getPeripheral(Peripherals.streamServer) { [weak self] streamServer in
            // Called when the stream server is available and when it changes.

            if let self = self, let streamServer = streamServer {
                // Enable Streaming
                streamServer.enabled = true
                self.liveStreamRef = streamServer.live { liveStream in
                    // Called when the live stream is available and when it changes.

                    if let liveStream = liveStream {
                        // Set the live stream as the stream to be render by the stream view.
                        self.streamView.setStream(stream: liveStream)
                        // Play the live stream.
                        _ = liveStream.play()
                    }
                }
            }
        }
    }

    @IBAction func tapAction(_ sender: UITapGestureRecognizer) {
        self.dismiss(animated: true)
    }
}
