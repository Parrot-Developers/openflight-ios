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
import Combine

// MARK: - Segmented Control
private enum GallerySourceSegment: Int, CaseIterable {
    case drone
    case device

    func toGallerySourceType(isSdCardActive: Bool) -> GallerySourceType {
        switch self {
        case .drone: return isSdCardActive ? .droneSdCard : .droneInternal
        case .device: return .mobileDevice
        }
    }
}

private extension GallerySourceSegment {
    static var defaultPanel: GallerySourceSegment {
        return .drone
    }

    static func type(at index: Int) -> GallerySourceSegment {
        guard index >= 0,
              index < GallerySourceSegment.allCases.count else {
                  return GallerySourceSegment.defaultPanel
              }
        return GallerySourceSegment.allCases[index]
    }

    static func index(for panel: GallerySourceSegment) -> Int {
        switch panel {
        case .drone:
            return 0
        case .device:
            return 1
        }
    }

    var title: String {
        switch self {
        case .drone:
            return L10n.gallerySourceDroneMemory
        case .device:
            return L10n.gallerySourceLocalMemory
        }
    }
}

// MARK: - Protocols
/// Delegate that notify state change in the main view model.
protocol GalleryViewDelegate: AnyObject {
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
    // Top Bar
    @IBOutlet private weak var navigationBar: UIView!
    @IBOutlet private weak var segmentedControl: UISegmentedControl!
    @IBOutlet private weak var closeButton: UIButton!

    // Media Panel
    @IBOutlet private weak var filterContainer: UIView!
    @IBOutlet private weak var filtersContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var mediasInfosLabel: UILabel!
    @IBOutlet private weak var mediaSourceContainer: UIView!
    @IBOutlet private weak var mediaSourceHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var mediasContainer: UIView!
    @IBOutlet private weak var mediaStackView: MainContainerStackView!
    @IBOutlet private weak var loadingView: GalleryLoadingView!

    // Side Panel
    @IBOutlet private weak var sidePanelContainerStackView: RightSidePanelStackView!
    @IBOutlet private weak var selectionCountLabel: UILabel!
    @IBOutlet private weak var mainActionButton: LoaderButton!
    @IBOutlet private weak var deleteButton: ActionButton!
    @IBOutlet private weak var selectAllButton: ActionButton!
    @IBOutlet private weak var formatSDButton: ActionButton!
    @IBOutlet private weak var selectButton: ActionButton!
    @IBOutlet private weak var sdCardErrorView: UIStackView!
    @IBOutlet private weak var sdCardErrorIcon: UIImageView!
    @IBOutlet private weak var sdCardErrorLabel: UILabel!

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var filtersViewController: GalleryFiltersViewController?
    private var mediaViewController: GalleryMediaViewController?
    private var sourceViewController: GallerySourcesViewController?
    private weak var coordinator: GalleryCoordinator?
    private var viewModel: GalleryMediaViewModel?
    private var selectedMediasCount = 0

    // Convenience Computed Properties
    private var selectedSourceSegment: GallerySourceSegment {
        GallerySourceSegment.type(at: segmentedControl?.selectedSegmentIndex ?? 0)
    }
    private var selectedSource: GallerySourceType {
        selectedSourceSegment.toGallerySourceType(isSdCardActive: isSdCardActive)
    }
    private var isDeviceSourceSelected: Bool {
        viewModel?.sourceType == .mobileDevice
    }
    private var isSdCardActive: Bool {
        viewModel?.isSdCardActive ?? false
    }
    private var filteredMediasCount: Int {
        viewModel?.state.value.mediasByDate
            .map { $0.medias }
            .flatMap { $0 }
            .count ?? 0
    }
    private var galleryHasMedia: Bool {
        filteredMediasCount != 0
    }
    private var areAllMediaSelected: Bool {
        selectedMediasCount == filteredMediasCount
    }

    // MARK: - Private Enums
    private enum Constants {
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

        setupUI()
        setupViewModel()

        if let coordinator = coordinator, let viewModel = viewModel {
            let filtersViewController = GalleryFiltersViewController.instantiate(coordinator: coordinator, viewModel: viewModel)
            self.filtersViewController = filtersViewController
            filtersViewController.delegate = self
            addController(filtersViewController, inContainer: filterContainer)

            let mediaViewController = GalleryMediaViewController.instantiate(coordinator: coordinator, viewModel: viewModel)
            self.mediaViewController = mediaViewController
            mediaViewController.delegate = self
            addController(mediaViewController, inContainer: mediasContainer)
            // Listen sharing media state.
            listenSharingMediaState()

            let sourceViewController = GallerySourcesViewController.instantiate(coordinator: coordinator, viewModel: viewModel)
            self.sourceViewController = sourceViewController
        }

        updateContainers()

        // Set gallery content to selectedSource.
        mediaSourceHeightConstraint.constant = Layout.buttonIntrinsicHeight(isRegularSizeClass) + Layout.mainSpacing(isRegularSizeClass)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel?.refreshMedias(source: selectedSource)
        updateContainers()
        LogEvent.log(.screen(LogEvent.Screen.gallery))
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Init loading view state at didAppear, as `showFromEdge` needs to be aware
        // of its actual height in order to correctly hide/show it.
        loadingView.setProgress(viewModel?.downloadProgress, status: viewModel?.downloadStatus)
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    /// Update display when orientation changed.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        updateContainers()
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

    @IBAction func mainActionButtonTouchedUpInside(_ sender: UIView) {
        // Trigger share or download depending on available service.
        isDeviceSourceSelected
        ? mediaViewController?.mustShareSelection(srcView: sender)
        : mediaViewController?.mustDownloadSelection()
    }

    @IBAction func deleteButtonTouchedUpInside(_ sender: Any) {
        mediaViewController?.mustDeleteSelection()
    }

    @IBAction func formatSDButtonTouchedUpInside(_ sender: Any) {
        guard let viewModel = viewModel else { return }

        self.coordinator?.showFormatSDCardScreen(viewModel: viewModel)
    }

    @IBAction func selectAllButtonTouchedUpInside(_ sender: Any) {
        areAllMediaSelected
        ? mediaViewController?.mustDeselectAll()
        : mediaViewController?.mustSelectAll()
    }

    @IBAction func selectButtonTouchedUpInside(_ sender: Any) {
        viewModel?.selectionModeEnabled.toggle()
        updateSelectButtonsState()
        updateFormatSDButtonState()
        mediaViewController?.multipleSelectionDidChange(enabled: viewModel?.selectionModeEnabled ?? false)
    }

    @IBAction func sourceDidChange(_ sender: Any) {
        mediaViewController?.sourceDidChange(source: selectedSource)
        updateSelectionMode(with: false) // Force selection mode reset.
        updateFormatSDButtonState()
        updateSDCardErrorState()
    }
}

// MARK: - Private Funcs
private extension GalleryViewController {
    /// Sets up UI components
    func setupUI() {
        navigationBar.addShadow()
        mediasInfosLabel.text = L10n.galleryNoMedia
        selectionCountLabel.makeUp(with: .regular, and: .disabledTextColor)
        mediaStackView.enabledMargins = [.left, .top, .right]
        sidePanelContainerStackView.enabledMargins = [.left, .bottom, .right]
        loadingView.delegate = self

        setupSegmentedControl()
        setupPanelButtons()
        sdCardErrorView.alphaHidden(true)
    }

    /// Sets up top segmented control for gallery source selection.
    func setupSegmentedControl() {
        segmentedControl.removeAllSegments()
        for source in GallerySourceSegment.allCases {
            segmentedControl.insertSegment(withTitle: source.title,
                                           at: segmentedControl.numberOfSegments,
                                           animated: false)
        }
        segmentedControl.customMakeup()
        // Select .device segment by default. Will be updated by VM state changes or user interaction.
        segmentedControl.selectedSegmentIndex = GallerySourceSegment.index(for: .device)
    }

    /// Sets up side panel action buttons: download/share, delete, format SD, select.
    func setupPanelButtons() {
        deleteButton.setup(title: L10n.commonDelete, style: .destructive)
        formatSDButton.setup(title: L10n.galleryFormatSdCard, style: .secondary1)
        sdCardErrorLabel.makeUp(with: .regular, and: .errorColor)
        sdCardErrorLabel.font = FontStyle.current.font(isRegularSizeClass)
        sdCardErrorIcon.tintColor = ColorName.errorColor.color
        mainActionButton.isEnabled = false
        deleteButton.isEnabled = false

        updateStates()
    }

    /// Updates UI according to current state (selection, source, content…).
    func updateStates() {
        updateSelectButtonsState()
        updateActionButtonsState()
        updateSDCardErrorState()
        updateFormatSDButtonState()
        updateMediaInfosLabelState()
        updateSegmentedControlState()
    }

    /// Updates select button state according to current selection mode.
    func updateSelectButtonsState() {
        let isSelectionModeEnabled = viewModel?.selectionModeEnabled ?? false
        let title = isSelectionModeEnabled
        ? L10n.cancel
        : L10n.commonSelect
        let style: ActionButtonStyle = isSelectionModeEnabled
        ? .secondary1
        : .default1
        selectButton.setup(title: title, style: style)

        selectAllButton.animateIsHiddenInStackView(!isSelectionModeEnabled)
        selectButton.isEnabled = galleryHasMedia

        // Need to show selection count if `isSelectionModeEnabled`, source storage info else.
        selectionCountLabel.animateIsHidden(!isSelectionModeEnabled)
        mediaSourceContainer.animateIsHidden(isSelectionModeEnabled)
    }

    /// Updates mediaInfos label (empty gallery) according to content.
    func updateMediaInfosLabelState() {
        mediasInfosLabel.animateIsHidden(galleryHasMedia)
    }

    /// Updates side panel action buttons according to current state (source and selection).
    func updateActionButtonsState() {
        let mainActionTitle = isDeviceSourceSelected
        ? L10n.commonShare
        : L10n.commonDownload
        let mainActionStyle: ActionButtonStyle = isDeviceSourceSelected
        ? .default1
        : .validate
        mainActionButton.setup(title: mainActionTitle, style: mainActionStyle)
        mainActionButton.loaderColor = ColorName.defaultTextColor.color

        let allButtonTitle = areAllMediaSelected
        ? L10n.commonDeselectAll
        : L10n.commonSelectAll
        selectAllButton.setup(title: allButtonTitle, style: .default1)
    }

    /// Updates selection count label with current selected medias count and size (if available).
    func updateSelectionCountLabel(selectionCount: Int, size: UInt64) {
        if isDeviceSourceSelected {
            selectionCountLabel.text = String(format: "%d %@",
                                              selectionCount,
                                              L10n.galleryMediaSelected.lowercased())
        } else {
            selectionCountLabel.text = String(format: "%d %@ (%@)",
                                              selectionCount,
                                              L10n.galleryMediaSelected.lowercased(),
                                              StorageUtils.sizeForFile(size: size))
        }

        let downloadInDrone = !isDeviceSourceSelected && viewModel?.downloadStatus == .running
        mainActionButton.isEnabled = selectionCount != 0 && !downloadInDrone
        deleteButton.isEnabled = selectionCount != 0
    }

    /// Updates source selection according to VM changes.
    func updateSegmentedControlState() {
        guard let viewModel = viewModel else { return }

        segmentedControl.selectedSegmentIndex = GallerySourceSegment.index(for: viewModel.sourceType == .mobileDevice ? .device : .drone)
    }

    /// Updates selection mode.
    ///
    /// - Parameters:
    ///    - isEnabled: Forces selection mode to true/false if not nil.
    func updateSelectionMode(with isEnabled: Bool? = nil) {
        if let isEnabled = isEnabled {
            // Force selection enabling/disabling.
            viewModel?.selectionModeEnabled = isEnabled
        } else {
            viewModel?.selectionModeEnabled.toggle()
        }

        updateSelectButtonsState()
        updateFormatSDButtonState()
        mediaViewController?.multipleSelectionDidChange(enabled: viewModel?.selectionModeEnabled ?? false)
    }

    /// Updates format SD button state depending on feature availability.
    func updateFormatSDButtonState() {
        guard let viewModel = viewModel, let sdCardViewModel = viewModel.sdCardViewModel else { return }
        let isHidden = selectedSource == .mobileDevice || viewModel.selectionModeEnabled

        formatSDButton.animateIsHiddenInStackView(isHidden)

        guard !isHidden else { return }

        let isEnabled = sdCardViewModel.state.value.canFormat
        formatSDButton.isEnabled = isEnabled
    }

    /// Updates SD card error view state.
    func updateSDCardErrorState() {
        guard let viewModel = viewModel else { return }
        let formatNeeded = viewModel.state.value.isFormatNeeded
        let showError = (formatNeeded || viewModel.isSdCardMissing) && selectedSource != .mobileDevice
        UIView.animate {
            self.sdCardErrorView.alphaHidden(!showError)
        }
        sdCardErrorLabel.text = formatNeeded
                                ? L10n.alertSdcardFormatErrorTitle
                                : L10n.alertNoSdcardErrorTitle
    }

    /// Update containers display.
    func updateContainers() {
        addSourcesView(to: mediaSourceContainer)
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

    /// Sets up view model.
    func setupViewModel() {
        viewModel = GalleryMediaViewModel(onMediaStateUpdate: { [weak self] state in
            guard let self = self else { return }
            self.updateStates()
            self.filtersViewController?.stateDidChange(state: state)
            self.mediaViewController?.stateDidChange(state: state)
        })

        // Listen to drone's memory download state changes.
        guard let viewModel = viewModel else { return }
        viewModel.$downloadProgress
            .combineLatest(viewModel.$downloadStatus)
            .sink { [weak self] (progress, status) in
                self?.loadingView.setProgress(progress, status: status)
            }
            .store(in: &cancellables)

        // Listen to formatting capability state.
        // `GallerySDMediaViewModel.canFormat` state can either be updated by SD peripheral events
        // or by flyingIndicators instruments (SD card formatting is forbidden when drone is flying).
        viewModel.$canFormat
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.updateFormatSDButtonState()
            }
            .store(in: &cancellables)
    }

    /// Update Sharing button loader according to sharing state.
    func listenSharingMediaState() {
        mediaViewController?.$isSharingMedia
            .sink { [weak self] in
                $0 ?
                self?.mainActionButton.startLoader() :
                self?.mainActionButton.stopLoader()
            }
            .store(in: &cancellables)
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
        updateStates()
        mediaViewController?.multipleSelectionDidChange(enabled: viewModel?.selectionModeEnabled ?? false)
    }

    func multipleSelectionEnabled() {
        viewModel?.selectionModeEnabled = true
        updateStates()
        mediaViewController?.multipleSelectionDidChange(enabled: viewModel?.selectionModeEnabled ?? false)
    }

    func didUpdateMediaSelection(count: Int, size: UInt64) {
        selectedMediasCount = count
        updateSelectionCountLabel(selectionCount: count, size: size)
        updateActionButtonsState()
    }
}

// MARK: - Gallery Loading View Delegate.
extension GalleryViewController: GalleryLoadingViewDelegate {
    func shouldStopProgress() {
        viewModel?.cancelDownloads()
    }
}
