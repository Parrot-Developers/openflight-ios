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

/// Coordinator for gallery details screens.
public final class GalleryCoordinator: Coordinator {
    // MARK: - Public Properties
    public var navigationController: NavigationController?
    public var childCoordinators = [Coordinator]()
    public weak var parentCoordinator: Coordinator?

    // MARK: - Public Funcs
    public func start() {
        let viewController = GalleryViewController.instantiate(coordinator: self)
        viewController.modalPresentationStyle = .fullScreen
        navigationController = NavigationController(rootViewController: viewController)
        navigationController?.isNavigationBarHidden = true
        navigationController?.modalPresentationStyle = .fullScreen
    }
}

// MARK: - Internal Funcs
extension GalleryCoordinator {
    /// Dismisses gallery.
    func dismissGallery() {
        parentCoordinator?.dismissChildCoordinator()
    }

    /// Shows media player.
    ///
    /// - Parameters:
    ///    - viewModel: Gallery view model
    ///    - index: Media index in the gallery media array
    func showMediaPlayer(viewModel: GalleryMediaViewModel, index: Int) {
        let playerViewController = GalleryMediaPlayerViewController.instantiate(coordinator: self,
                                                                                viewModel: viewModel,
                                                                                index: index)
        push(playerViewController)
    }

    /// Shows sharing screen.
    ///
    /// - Parameters:
    ///    - view: source view
    ///    - items: items to share
    func showSharingScreen(fromView view: UIView, items: [Any]) {
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        navigationController?.presentSheet(viewController: activityViewController, sourceView: view)
    }

    /// Shows format SD card screen.
    ///
    /// - Parameters:
    ///    - viewModel: Gallery view model
    func showFormatSDCardScreen(viewModel: GalleryMediaViewModel) {
        let viewController = GalleryFormatSDCardViewController.instantiate(coordinator: self,
                                                                           viewModel: viewModel)
        navigationController?.present(viewController, animated: true, completion: {})
    }

    /// Dismisses format SD card screen.
    ///
    /// - Parameters:
    ///    - showToast: boolean to determine if we need to show the formatting toast message
    ///    - duration: display duration
    func dismissFormatSDCardScreen(showToast: Bool = false, duration: Double = Style.longAnimationDuration) {
        dismiss()
        if showToast {
            navigationController?.topViewController?.showToast(message: L10n.galleryFormatComplete,
                                                               duration: duration)
        }
    }

    /// Dismisses panorama generation screen.
    func dismissPanoramaGenerationScreen() {
        navigationController?.dismiss(animated: true)
    }

    /// Shows panorama visualisation screen.
    ///
    /// - Parameters:
    ///    - viewModel: Gallery view model
    ///    - url: panorama url
    func showPanoramaVisualisationScreen(viewModel: GalleryMediaViewModel, url: URL) {
        let viewController = GalleryPanoramaViewController.instantiate(coordinator: self,
                                                                       viewModel: viewModel,
                                                                       url: url)
        push(viewController)
    }

    /// Show panorama generation screen.
    ///
    /// - Parameters:
    ///    - viewModel: Gallery view model
    ///    - index: Media index in the gallery media array
    func showPanoramaGenerationScreen(viewModel: GalleryPanoramaViewModel, index: Int) {
        let viewController = GalleryPanoramaGenerationViewController.instantiate(viewModel: viewModel,
                                                                                 index: index)
        presentModal(viewController: viewController)
    }

    /// Dismisses panorama visualisation screen.
    func dismissPanoramaVisualisationScreen() {
        back()
    }
}
