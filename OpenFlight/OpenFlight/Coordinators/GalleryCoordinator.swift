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

    // MARK: - Private Properties
    /// The media services.
    private let mediaServices: MediaServices
    /// The camera recording service.
    private let cameraRecordingService: CameraRecordingService

    // MARK: Init
    /// Constructor.
    ///
    /// - Parameters:
    ///    - mediaServices: the media services
    ///    - cameraRecordingService: the camera recording service
    init(mediaServices: MediaServices,
         cameraRecordingService: CameraRecordingService) {
        self.mediaServices = mediaServices
        self.cameraRecordingService = cameraRecordingService
    }

    // MARK: - Public Funcs
    public func start() {
        let viewModel = GalleryViewModel(mediaServices: mediaServices)
        viewModel.delegate = self
        let viewController = GalleryViewController.instantiate(viewModel: viewModel)
        viewController.modalPresentationStyle = .fullScreen
        navigationController = NavigationController(rootViewController: viewController)
        navigationController?.isNavigationBarHidden = true
        navigationController?.modalPresentationStyle = .fullScreen
    }
}

// MARK: - Internal Funcs
extension GalleryCoordinator {

    /// Presents a common alert in case of error.
    ///
    /// - Parameters:
    ///     - title: alert title
    ///     - message: alert message
    func showErrorAlert(title: String = L10n.error, message: String) {
        let cancelAction = AlertAction(title: L10n.ok, actionHandler: nil)
        let alert = AlertViewController.instantiate(title: title,
                                                    message: message,
                                                    cancelAction: cancelAction,
                                                    validateAction: nil)
        navigationController?.present(alert, animated: true, completion: nil)
    }
}

extension GalleryCoordinator: GalleryNavigationDelegate {

    /// Closes gallery screen.
    func close() {
        parentCoordinator?.dismissChildCoordinator()
    }

    /// Shows media browser.
    ///
    /// - Parameters:
    ///    - media: the media to display
    ///    - index: the media's index in filtered media list
    ///    - filter: the filter to apply to media list
    func showMediaBrowser(media: GalleryMedia, index: Int, filter: Set<GalleryMediaType>) {

        let browserManager = MediaBrowserManager(mediaServices: mediaServices,
                                                 cameraRecordingService: cameraRecordingService,
                                                 activeMediaIndex: index,
                                                 activeMedia: media,
                                                 filter: filter)
        browserManager.delegate = self
        let playerViewController = MediaBrowserViewController.instantiate(browserManager: browserManager)
        push(playerViewController)
    }

    /// Closes media browser.
    func closeMediaBrowser() {
        back()
    }

    /// Shows sharing screen.
    ///
    /// - Parameters:
    ///    - view: source view
    ///    - items: items to share
    ///    - completion: action to execute on complete
    func showSharingScreen(fromView view: UIView, items: [Any], completion: (() -> Void)? = nil) {
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        navigationController?.presentSheet(viewController: activityViewController, sourceView: view)
        activityViewController.completionWithItemsHandler = { [weak self] (_, _, _, error) in
            completion?()
            if let error = error {
                self?.showErrorAlert(title: L10n.alertSystemErrorTitle,
                                     message: L10n.alertSystemErrorMessage + " \(error)")
            }
        }
    }

    /// Shows formatting screen.
    func showFormattingScreen() {
        let formattingCoordinator = FormattingCoordinator(userStorageService: mediaServices.userStorageService)
        formattingCoordinator.parentCoordinator = self
        formattingCoordinator.start()
        present(childCoordinator: formattingCoordinator, overFullScreen: true)
    }

    /// Shows a deletion confirmation popup alert.
    ///
    /// - Parameters:
    ///   - message: the confirmation message to display
    ///   - action: the delete action block
    func showDeleteConfirmationPopup(message: String, action: (() -> Void)?) {
        let deleteAction = AlertAction(title: L10n.commonDelete,
                                       style: .destructive,
                                       isActionDelayedAfterDismissal: false,
                                       actionHandler: action)
        let cancelAction = AlertAction(title: L10n.cancel,
                                       style: .default2)
        navigationController?.showAlert(title: L10n.commonDelete,
                                        message: message,
                                        cancelAction: cancelAction,
                                        validateAction: deleteAction)
    }

    /// Shows an alert for full media or single resource removal choice proposal.
    ///
    /// - Parameters:
    ///    - message: the popup message
    ///    - resourcesCount: the number of resources of the media
    ///    - mediaAction: the media delete action
    ///    - resourceAction: the resource delete action
    func showDeleteMediaOrResourceAlert(message: String,
                                        resourcesCount: Int,
                                        mediaAction: (() -> Void)?,
                                        resourceAction: (() -> Void)?) {
        let deleteResourceAction = AlertAction(title: L10n.galleryDeleteResource,
                                               style: .destructive,
                                               borderWidth: Style.mediumBorderWidth,
                                               isActionDelayedAfterDismissal: false,
                                               actionHandler: resourceAction)
        let deleteMediaAction = AlertAction(title: L10n.galleryDeleteMedia(resourcesCount),
                                            style: .destructive,
                                            actionHandler: mediaAction)
        let cancelAction = AlertAction(title: L10n.cancel,
                                       style: .default2,
                                       actionHandler: {})

        navigationController?.showAlert(title: L10n.commonDelete,
                                        message: message,
                                        cancelAction: cancelAction,
                                        validateAction: deleteResourceAction,
                                        secondaryAction: deleteMediaAction)
    }

    /// Shows an action failure popup alert.
    ///
    /// - Parameters:
    ///   - message: the error message to display
    ///   - retryAction: the retry action block
    func showActionErrorAlert(message: String, retryAction: @escaping () -> Void) {
        let retryAction = AlertAction(title: L10n.commonRetry,
                                      style: .destructive,
                                      isActionDelayedAfterDismissal: false,
                                      actionHandler: retryAction)
        let cancelAction = AlertAction(title: L10n.cancel,
                                       style: .default2,
                                       isActionDelayedAfterDismissal: false) {}

        navigationController?.showAlert(title: L10n.error,
                                       message: message,
                                       cancelAction: cancelAction,
                                       validateAction: retryAction)
    }

    /// Shows panorama visualisation screen.
    ///
    /// - Parameter url: panorama url
    func showImmersivePanoramaScreen(url: URL?) {
        guard let url = url else { return }
        let viewModel = ImmersivePanoramaViewModel(url: url)
        viewModel.delegate = self
        let viewController = ImmersivePanoramaViewController.instantiate(viewModel: viewModel)
        push(viewController)
    }

    /// Shows panorama generation screen.
    ///
    /// - Parameter media: the panorama media to generate
    func showPanoramaGenerationScreen(for media: GalleryMedia) {
        let viewModel = GalleryPanoramaGenerationViewModel(mediaServices: mediaServices,
                                                           media: media)
        viewModel.delegate = self
        let viewController = GalleryPanoramaGenerationViewController.instantiate(viewModel: viewModel)
        presentModal(viewController: viewController)
    }

    /// Dismisses panorama generation screen.
    func dismissPanoramaGenerationScreen() {
        navigationController?.dismiss(animated: true)
    }

    /// Dismisses immersive panorama screen.
    func dismissImmersivePanoramaScreen() {
        back()
    }
}
