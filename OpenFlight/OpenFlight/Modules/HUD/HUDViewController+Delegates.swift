//    Copyright (C) 2020 Parrot Drones SAS
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

/// Delegates implementations of HUDViewController.

// MARK: - HUDTopBarViewControllerNavigation
extension HUDViewController: HUDTopBarViewControllerNavigation {
    /// Opens application main Dashboard.
    func openDashboard() {
        self.coordinator?.startDashboard()
    }

    /// Opens application/drone settings view.
    func openSettings(_ type: SettingsType?) {
        self.coordinator?.startSettings(type)
    }

    /// Opens remote control details info view.
    func openRemoteControlInfos() {
        self.coordinator?.startRemoteInformation()
    }

    /// Opens drone details info view.
    func openDroneInfos() {
        self.coordinator?.startDroneInformation()
    }

    /// Returns to the previous displayed view (e.g. Project Manager, My Flights...)
    func back() {
        coordinator?.returnToPreviousView()
    }
}

// MARK: - HUDCameraStreamingViewControllerDelegate
extension HUDViewController: HUDCameraStreamingViewControllerDelegate {

    public func didUpdate(contentZone: CGRect?) {
        // Sets up current content zone wherever it is needed.
        videoControls.lockAETargetZoneViewController?.streamingContentZone = contentZone
    }
}

extension HUDViewController: HUDIndicatorViewControllerNavigation {
    /// Opens pairing.
    func openPairing() {
        self.coordinator?.startPairing()
    }
}
