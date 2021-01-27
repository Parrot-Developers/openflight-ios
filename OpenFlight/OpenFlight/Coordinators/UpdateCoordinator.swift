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

/// Coordinator for device update screens.
public final class UpdateCoordinator: Coordinator {
    // MARK: - Public Properties
    public var navigationController: NavigationController?
    public var childCoordinators = [Coordinator]()
    public var parentCoordinator: Coordinator?

    // MARK: - Internal Properties
    var deviceUpdateType: DeviceUpdateType?

    // MARK: - Private Properties
    private var model: DeviceUpdateModel = .remote

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///     - deviceModel: can be a remote of a drone.
    public init(model: DeviceUpdateModel) {
        self.model = model
    }

    // MARK: - Public Funcs
    public func start() {
        var viewController: UIViewController = UIViewController()

        switch model {
        case .drone:
            guard let deviceUpdateType = deviceUpdateType else { return }
            viewController = DeviceUpdateViewController.instantiate(coordinator: self, deviceUpdateType: deviceUpdateType)
        default:
            viewController = DeviceConfirmUpdateViewController.instantiate(coordinator: self, model: model)
        }

        // Prevents not fullscreen presentation style since iOS 13.
        self.navigationController = NavigationController(rootViewController: viewController)
        self.navigationController?.isNavigationBarHidden = true
        self.navigationController?.modalPresentationStyle = .fullScreen
    }
}

// MARK: - Update Navigation
extension UpdateCoordinator {
    /// Starts update screen.
    ///
    /// - Parameters:
    ///     - deviceUpdateType: type of the update
    func startUpdate(deviceUpdateType: DeviceUpdateType) {
        let viewController = DeviceUpdateViewController.instantiate(coordinator: self,
                                                                    deviceUpdateType: deviceUpdateType)
        self.push(viewController)
    }

    /// Dismisses device update screens.
    func dismissDeviceUpdate() {
        self.parentCoordinator?.dismissChildCoordinator()
    }
}
