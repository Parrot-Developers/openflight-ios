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

/// Protocol for `ManagePlansViewController` navigation.
public protocol FlightPlanManagerCoordinator: class {
    /// Starts manage plans modal.
    func startManagePlans()

    /// Starts Flight Plan history modal.
    ///
    /// - Parameters:
    ///     - flightPlanViewModel: Flight Plan ViewModel
    func startFlightPlanHistory(flightPlanViewModel: FlightPlanViewModel)

    /// Close manage plans view.
    func closeManagePlans()
}

/// `FlightPlanManagerCoordinator` default implementation.
extension FlightPlanManagerCoordinator where Self: Coordinator {
    public func startManagePlans() {
        let viewController = ManagePlansViewController.instantiate(coordinator: self)
        presentModal(viewController: viewController, animated: false)
        NotificationCenter.default.post(name: .modalPresentDidChange,
                                        object: self,
                                        userInfo: [BottomBarViewControllerNotifications.notificationKey: true])
    }

    public func startFlightPlanHistory(flightPlanViewModel: FlightPlanViewModel) {
        let viewController = FlightPlanFullHistoryViewController.instantiate(coordinator: self,
                                                                             viewModel: flightPlanViewModel)
        presentModal(viewController: viewController)
    }

    public func closeManagePlans() {
        self.dismiss(animated: false)
        // Notify observers about flight plan modal's visibility status.
        NotificationCenter.default.post(name: .modalPresentDidChange,
                                        object: self,
                                        userInfo: [BottomBarViewControllerNotifications.notificationKey: false])
    }
}
