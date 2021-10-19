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

    // Side Panel
    @IBOutlet private weak var selectionCountLabel: UILabel!
    @IBOutlet private weak var mainActionButton: ActionButton!
    @IBOutlet private weak var deleteButton: ActionButton!
    @IBOutlet private weak var selectAllButton: ActionButton!
    @IBOutlet private weak var formatSDButton: ActionButton!
    @IBOutlet private weak var selectButton: ActionButton!

    // MARK: - Private Properties
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

        setupUI()
        setupSegmentedControl()
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

            let sourceViewController = GallerySourcesViewController.instantiate(coordinator: coordinator, viewModel: viewModel)
            self.sourceViewController = sourceViewController
        }

        updateContainers()

        // Set gallery content to selectedSource.
        mediaSourceHeightConstraint.constant = GallerySourcesViewController.Constants.cellHeight
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel?.refreshMedias(source: selectedSource)
        updateContainers()
        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.gallery,
                             logType: .screen)
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
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

    @IBAction func mainActionButtonTouchedUpInside(_ sender: Any) {
        // Trigger share or download depending on available service.
        isDeviceSourceSelected
            ? mediaViewController?.mustShareSelection()
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
    }
}

// MARK: - Private Funcs
private extension GalleryViewController {
    /// Sets up UI components
    func setupUI() {
        navigationBar.addLightShadow()
        mediasInfosLabel.text = L10n.galleryNoMedia
        selectionCountLabel.makeUp(with: .regular, and: .disabledTextColor)

        setupPanelButtons()
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
    }

    /// Sets up side panel action buttons: download/share, delete, format SD, select.
    func setupPanelButtons() {
        deleteButton.model = ActionButtonModel(title: L10n.commonDelete, style: .destructive)
        formatSDButton.model = ActionButtonModel(title: L10n.galleryFormat, style: .secondary)
        mainActionButton.animateIsEnabled(false)
        deleteButton.animateIsEnabled(false)

        updateStates()
    }

    /// Updates UI according to current state (selection, source, content…).
    func updateStates() {
        updateSelectButtonsState()
        updateActionButtonsState()
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
            ? .secondary
            : .primary
        selectButton.model = ActionButtonModel(title: title, style: style)

        selectAllButton.animateIsHiddenInStackView(!isSelectionModeEnabled)
        selectButton.animateIsEnabled(galleryHasMedia)

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
            ? .primary
            : .validate
        mainActionButton.model = ActionButtonModel(title: mainActionTitle, style: mainActionStyle)

        let allButtonTitle = areAllMediaSelected
            ? L10n.commonDeselectAll
            : L10n.commonSelectAll
        selectAllButton.model = ActionButtonModel(title: allButtonTitle, style: .primary)
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

        mainActionButton.animateIsEnabled(selectionCount != 0)
        deleteButton.animateIsEnabled(selectionCount != 0)
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
        let isHidden = !(viewModel?.shouldDisplayFormatOptions ?? false)
            || viewModel?.selectionModeEnabled ?? false

        formatSDButton.animateIsHiddenInStackView(isHidden)

        guard !isHidden else { return }

        let isEnabled = viewModel?.sdCardViewModel?.state.value.canFormat ?? false
        formatSDButton.animateIsEnabled(isEnabled)
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
            self?.updateStates()
            self?.filtersViewController?.stateDidChange(state: state)
            self?.mediaViewController?.stateDidChange(state: state)
        })
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
