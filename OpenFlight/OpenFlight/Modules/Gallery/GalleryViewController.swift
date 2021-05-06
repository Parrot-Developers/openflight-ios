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

import UIKit

// MARK: - Protocols
/// Delegate that notify state change in the main view model.
protocol GalleryViewDelegate: class {
    /// Handle change in state.
    ///
    /// - Parameters:
    ///    - state: new gallery state
    func stateDidChange(state: GalleryMediaState)

    /// Handle change in multiple selection.
    ///
    /// - Parameters:
    ///    - enable: multiple selection
    func multipleSelectionDidChange(enabled: Bool)

    /// Handle change in source.
    ///
    /// - Parameters:
    ///    - source: new source
    func sourceDidChange(source: GallerySourceType)
}

/// Gallery home.
final class GalleryViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var bgLeftView: UIView! {
        didSet {
            bgLeftView.backgroundColor = ColorName.black.color
        }
    }
    @IBOutlet private weak var bgView: UIView! {
        didSet {
            bgView.backgroundColor = ColorName.black80.color
        }
    }
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var titleLabel: UILabel! {
        didSet {
            titleLabel.makeUp(with: .huge)
            titleLabel.text = L10n.galleryTitle
        }
    }
    @IBOutlet private weak var filterContainer: UIView!
    @IBOutlet private weak var filtersContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var formatButton: UIButton! {
        didSet {
            formatButton.makeup(with: .large, color: .white)
        }
    }
    @IBOutlet private weak var selectButton: UIButton! {
        didSet {
            selectButton.makeup(with: .large, color: .white)
        }
    }
    @IBOutlet private weak var mediasInfosLabel: UILabel! {
        didSet {
            mediasInfosLabel.text = L10n.galleryNoMedia
            mediasInfosLabel.makeUp()
        }
    }
    @IBOutlet private weak var leftSourcesContainer: UIView!
    @IBOutlet private weak var mediasContainer: UIView!
    @IBOutlet private weak var bottomSourcesContainer: UIView!
    @IBOutlet private weak var bottomContainerHeightConstraint: NSLayoutConstraint!

    // MARK: - Private Properties
    private var filtersViewController: GalleryFiltersViewController?
    private var mediaViewController: GalleryMediaViewController?
    private var sourceViewController: GallerySourcesViewController?
    private weak var coordinator: GalleryCoordinator?
    private var viewModel: GalleryMediaViewModel?

    // MARK: - Private Enums
    private enum Constants {
        static let closeButtonSize = CGSize(width: 25.0, height: 25.0)
        static let filtersMinimumHeight: CGFloat = 37.0
    }

    // MARK: - Setup
    static func instantiate(coordinator: GalleryCoordinator) -> GalleryViewController {
        let viewController = StoryboardScene.GalleryViewController.initialScene.instantiate()
        viewController.coordinator = coordinator

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationBar()
        setupViewModel()
        setupFormatButton()
        updateSelectButtonAndMediasInfoLabel()
        setupBottomContainerHeightConstraint()

        if let coordinator = coordinator, let viewModel = viewModel {
            let filtersViewController = GalleryFiltersViewController.instantiate(coordinator: coordinator, viewModel: viewModel)
            self.filtersViewController = filtersViewController
            filtersViewController.delegate = self
            addController(filtersViewController, inContainer: filterContainer)

            let mediaViewController = GalleryMediaViewController.instantiate(coordinator: coordinator, viewModel: viewModel)
            self.mediaViewController = mediaViewController
            mediaViewController.delegate = self
            addController(mediaViewController, inContainer: mediasContainer)

            let sourceViewController = GallerySourcesViewController.instantiate(coordinator: coordinator, viewModel: viewModel)
            self.sourceViewController = sourceViewController
            sourceViewController.delegate = self
            self.sourceViewController = sourceViewController
        }

        updateContainers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel?.refreshMedias()
        self.updateContainers()
        updateSelectButtonAndMediasInfoLabel()
        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.gallery,
                             logType: .screen)
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }

    /// Update display when orientation changed.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        updateContainers()
        updateSelectButtonAndMediasInfoLabel()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension GalleryViewController {
    /// Close button clicked.
    @IBAction func closeButtonTouchedUpInside(_ sender: AnyObject) {
        self.coordinator?.dismissGallery()
    }

    /// Format button clicked.
    @IBAction func formatButtonTouchedUpInside(_ sender: AnyObject) {
        guard let viewModel = viewModel else { return }

        self.coordinator?.showFormatSDCardScreen(viewModel: viewModel)
    }

    /// Select button clicked.
    @IBAction func selectButtonTouchedUpInside(_ sender: AnyObject) {
        viewModel?.selectionModeEnabled.toggle()
        updateSelectButtonAndMediasInfoLabel()
        mediaViewController?.multipleSelectionDidChange(enabled: viewModel?.selectionModeEnabled ?? false)
    }
}

// MARK: - Private Funcs
private extension GalleryViewController {
    /// Update containers display.
    func updateContainers() {
        bgLeftView.isHidden = !UIApplication.isLandscape
        bottomSourcesContainer.isHidden = UIApplication.isLandscape

        closeButton.isHidden = !UIApplication.isLandscape
        selectButton.isHidden = !UIApplication.isLandscape
        titleLabel.isHidden = !UIApplication.isLandscape
        // Make the navigation bar visible in portrait mode.
        self.navigationController?.setNavigationBarHidden(UIApplication.isLandscape, animated: false)

        let container: UIView = UIApplication.isLandscape ? leftSourcesContainer : bottomSourcesContainer
        addSourcesView(to: container)

        sourceViewController?.reloadContent()
    }

    /// Add Sources view to dedicated container view.
    ///
    /// - Parameters:
    ///     - destinationContainerView: destination container view
    func addSourcesView(to destinationContainerView: UIView) {
        guard let sourceViewController = sourceViewController,
              sourceViewController.view.superview != destinationContainerView else {
            return
        }

        // Add child view controller first time.
        let isContainingSourcesViewController = self.children.contains(sourceViewController)

        if !isContainingSourcesViewController {
            addChild(sourceViewController)
        }
        sourceViewController.view.removeFromSuperview()
        sourceViewController.view.frame = destinationContainerView.bounds
        destinationContainerView.addSubview(sourceViewController.view)

        if !isContainingSourcesViewController {
            sourceViewController.didMove(toParent: self)
        }
    }

    /// Add controller in a dedicated container.
    ///
    /// - Parameters:
    ///    - controller: controller to add
    ///    - inContainer: container where controller'view will be added
    func addController(_ controller: UIViewController, inContainer: UIView) {
        addChild(controller)
        inContainer.addWithConstraints(subview: controller.view)
        controller.didMove(toParent: self)
    }

    /// Update view for the navigation bar.
    func setupNavigationBar() {
        self.title = titleLabel.text

        // Navigation bar display.
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.tintColor = ColorName.white.color
        self.navigationController?.navigationBar.barTintColor = ColorName.black.color
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.font: ParrotFontStyle.huge.font,
            NSAttributedString.Key.foregroundColor: ColorName.white.color
        ]

        // Add left button to come back to the HUD.
        let backButton = UIButton(frame: CGRect(origin: CGPoint(),
                                                size: Constants.closeButtonSize))
        backButton.setImage(Asset.Common.Icons.icBack.image, for: .normal)
        backButton.addTarget(self,
                             action: #selector(closeButtonTouchedUpInside),
                             for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)

        // Add right button to select medias.
        let selectBarButton = UIBarButtonItem(title: L10n.commonSelect,
                                              style: .done,
                                              target: self,
                                              action: #selector(selectButtonTouchedUpInside))
        selectBarButton.setTitleTextAttributes([
            NSAttributedString.Key.font: ParrotFontStyle.large.font,
            NSAttributedString.Key.foregroundColor: ColorName.white.color
        ], for: .normal)
        selectBarButton.setTitleTextAttributes([
            NSAttributedString.Key.font: ParrotFontStyle.large.font,
            NSAttributedString.Key.foregroundColor: ColorName.white50.color
        ], for: .disabled)
        self.navigationItem.rightBarButtonItem = selectBarButton

        self.removeBackButtonText()
    }

    /// Sets up view model.
    func setupViewModel() {
        viewModel = GalleryMediaViewModel(onMediaStateUpdate: { [weak self] state in
            self?.filtersViewController?.stateDidChange(state: state)
            self?.mediaViewController?.stateDidChange(state: state)
            self?.updateSelectButtonAndMediasInfoLabel()
        })
    }

    /// Sets up format button.
    func setupFormatButton() {
        guard let viewModel = viewModel else { return }

        self.formatButton.isHidden = !viewModel.shouldDisplayFormatOptions
        self.formatButton.setTitle(L10n.galleryFormat, for: .normal)
    }

    /// Updates select button and medias infos label.
    func updateSelectButtonAndMediasInfoLabel() {
        let numberOfMedias: Int = viewModel?.numberOfMedias ?? 0
        var buttonText = L10n.commonSelect

        if let selectionModeEnabled = viewModel?.selectionModeEnabled {
            buttonText = selectionModeEnabled ? L10n.cancel : L10n.commonSelect
        }

        self.navigationItem.rightBarButtonItem?.title = buttonText
        self.selectButton.setTitle(buttonText, for: .normal)

        let titleColor: UIColor = numberOfMedias != 0
            ? ColorName.white.color
            : ColorName.white10.color
        mediasInfosLabel.isHidden = numberOfMedias != 0
        selectButton.isEnabled = numberOfMedias != 0
        selectButton.setTitleColor(titleColor, for: .normal)
        self.navigationItem.rightBarButtonItem?.isEnabled = numberOfMedias != 0
    }

    /// Sets up bottom container height constraint.
    func setupBottomContainerHeightConstraint() {
        if !UIApplication.isLandscape {
            bottomContainerHeightConstraint.constant += UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0.0
        } else {
            bottomContainerHeightConstraint.constant += UIApplication.shared.keyWindow?.safeAreaInsets.left ?? 0.0
        }
    }
}

// MARK: - Containter Size Delegate
extension GalleryViewController: ContainterSizeDelegate {
    func contentDidUpdateHeight(_ height: CGFloat) {
        var adjustedHeight = height

        if adjustedHeight < Constants.filtersMinimumHeight {
            adjustedHeight = Constants.filtersMinimumHeight
        }

        filtersContainerHeightConstraint.constant = adjustedHeight
    }
}

// MARK: - GalleryMediaView Delegate
extension GalleryViewController: GalleryMediaViewDelegate {
    func multipleSelectionActionTriggered() {
        viewModel?.selectionModeEnabled = false
        updateSelectButtonAndMediasInfoLabel()
        mediaViewController?.multipleSelectionDidChange(enabled: viewModel?.selectionModeEnabled ?? false)
    }

    func multipleSelectionEnabled() {
        viewModel?.selectionModeEnabled = true
        updateSelectButtonAndMediasInfoLabel()
        mediaViewController?.multipleSelectionDidChange(enabled: viewModel?.selectionModeEnabled ?? false)
    }
}

// MARK: - GallerySourcesView Delegate
extension GalleryViewController: GallerySourcesViewDelegate {
    func sourceDidChange(source: GallerySourceType) {
        mediaViewController?.sourceDidChange(source: source)
        setupFormatButton()
        updateSelectButtonAndMediasInfoLabel()
    }
}
