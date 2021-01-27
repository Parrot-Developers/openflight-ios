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

/// Utility extension for `NotificationCenter`.
public extension NotificationCenter {
    /// Removes observer.
    ///
    /// - Parameters:
    ///    - observer: observer to remove (nilable)
    func remove(observer: Any?) {
        guard let observer = observer else { return }

        removeObserver(observer)
    }
}

/// Utility extension for `Notification.Name` to list all custom notifications.
public extension Notification.Name {
    static let splitModeDidChange = NSNotification.Name("splitModeDidChange")
    static let bottomBarModeDidChange = NSNotification.Name("bottomBarModeDidChange")
    static let alertPanelModeDidChange = NSNotification.Name("alertPanelModeDidChange")
    static let missionLauncherModeDidChange = NSNotification.Name("missionLauncherModeDidChange")
    static let modalPresentDidChange = NSNotification.Name("modalPresentDidChange")
    static let handDetectedAlertModalPresentDidChange = NSNotification.Name("handDetectedAlertModalPresentDidChange")
    static let joysticksAvailabilityDidChange = NSNotification.Name("joysticksAvailabilityDidChange")
    static let takeOffRequestedDidChange = NSNotification.Name("takeOffRequestedDidChange")
    static let flightPlanExecutionDidStart = NSNotification.Name("flightPlanExecutionDidStart")
}
