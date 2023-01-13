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

public final class FormattingCoordinator: Coordinator {
    // MARK: - Properties
    public var navigationController: NavigationController?
    public var childCoordinators = [Coordinator]()
    public weak var parentCoordinator: Coordinator?

    /// The user storage service.
    public let userStorageService: UserStorageService

    // MARK: Init
    /// Constructor.
    ///
    /// - Parameter userStorageService: the user storage service
    public init(userStorageService: UserStorageService) {
        self.userStorageService = userStorageService
    }

    // MARK: - Public Funcs
    public func start() {
        let viewModel = GalleryFormatSDCardViewModel(userStorageService: userStorageService)
        viewModel.delegate = self
        let viewController = GalleryFormatSDCardViewController.instantiate(viewModel: viewModel)
        navigationController = NavigationController(rootViewController: viewController)
        navigationController?.isNavigationBarHidden = true
    }
}

extension FormattingCoordinator: FormattingNavigationDelegate {

    /// Informs of a close view request with optional toast message.
    ///
    /// - Parameters:
    ///    - message: the toast message to display (if any)
    ///    - duration: the toast message duration (relevant only if `message` is non-`nil`)
    func close(message: String?, duration: TimeInterval) {
        dismiss()
        // Diplay toast message if needed.
        if let message = message {
            parentCoordinator?.navigationController?.showToast(message: message,
                                                               duration: duration)
        }
    }
}
