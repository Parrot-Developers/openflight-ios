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
import GroundSdk

/// Gallery home.
final class GalleryViewController: UIViewController {

    public override var prefersHomeIndicatorAutoHidden: Bool { true }
    public override var prefersStatusBarHidden: Bool { true }

    // MARK: - Outlets
    // Top Bar
    @IBOutlet private weak var navigationBar: UIView!
    @IBOutlet private weak var segmentedControl: SettingsSegmentedControl!
    @IBOutlet private weak var closeButton: UIButton!

    // Media Panel
    @IBOutlet private weak var filterContainer: UIView!
    @IBOutlet private weak var filtersContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var mediaListStackView: UIStackView!
    @IBOutlet private weak var mediaListStateIcon: UIImageView!
    @IBOutlet private weak var mediaListStateLabel: UILabel!
    @IBOutlet private weak var mediaSourceContainer: UIView!
    @IBOutlet private weak var mediaSourceHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var mediasContainer: UIView!
    @IBOutlet private weak var mediaStackView: MainContainerStackView!
    @IBOutlet private weak var downloadProgressView: GalleryLoadingView!

    // Side Panel
    @IBOutlet private weak var sidePanelContainerStackView: RightSidePanelStackView!
    @IBOutlet private weak var selectionCountLabel: UILabel!
    @IBOutlet private weak var mainActionButton: LoaderButton!
    @IBOutlet private weak var deleteButton: LoaderButton!
    @IBOutlet private weak var selectAllButton: ActionButton!
    @IBOutlet private weak var formatSDButton: ActionButton!
    @IBOutlet private weak var selectButton: ActionButton!
    @IBOutlet private weak var sdCardErrorView: UIStackView!
    @IBOutlet private weak var sdCardErrorIcon: UIImageView!
    @IBOutlet private weak var sdCardErrorLabel: UILabel!

    // MARK: - Private Properties
    /// The cancellables.
    private var cancellables = Set<AnyCancellable>()
    /// The view model.
    private var viewModel: GalleryViewModel!

    // MARK: - Setup
    static func instantiate(viewModel: GalleryViewModel) -> GalleryViewController {
        let viewController = StoryboardScene.GalleryViewController.initialScene.instantiate()
        viewController.viewModel = viewModel

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        setupChildControllers()
        setupUI()
        setupViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        LogEvent.log(.screen(LogEvent.Screen.gallery))
    }
}

// MARK: - Actions
private extension GalleryViewController {
    /// Close button clicked.
    @IBAction func closeButtonTouchedUpInside(_ sender: AnyObject) {
        viewModel.close()
    }

    @IBAction func mainActionButtonTouchedUpInside(_ sender: UIView) {
        viewModel.didTapMainAction(srcView: sender)
    }

    @IBAction func deleteButtonTouchedUpInside(_ sender: Any) {
        viewModel.didTapDelete()
    }

    @IBAction func formatSDButtonTouchedUpInside(_ sender: Any) {
        viewModel.didTapFormat()
    }

    @IBAction func selectAllButtonTouchedUpInside(_ sender: Any) {
        viewModel.toggleSelectAll()
    }

    @IBAction func selectButtonTouchedUpInside(_ sender: Any) {
        viewModel.toggleSelectMode()
    }
}

// MARK: - Private Funcs
private extension GalleryViewController {

    /// Sets up child view controllers.
    func setupChildControllers() {
        let filtersViewController = GalleryFiltersViewController.instantiate(viewModel: viewModel)
        addController(filtersViewController, inContainer: filterContainer)

        let sourceViewController = GallerySourcesViewController.instantiate(viewModel: viewModel)
        addController(sourceViewController, inContainer: mediaSourceContainer)

        let mediaViewController = GalleryMediaViewController.instantiate(viewModel: viewModel)
        addController(mediaViewController, inContainer: mediasContainer)
    }

    /// Sets up UI components
    func setupUI() {
        navigationBar.addShadow()
        selectionCountLabel.makeUp(with: .regular, and: .disabledTextColor)
        mediaStackView.enabledMargins = [.left]
        mediaStackView.spacing = 0
        sidePanelContainerStackView.enabledMargins = [.left, .bottom, .right]
        downloadProgressView.delegate = self

        setupSegmentedControl()
        setupPanelButtons()
        updateButtons(activeTypes: [])
        updateButtons(enabledTypes: [])
        sdCardErrorView.alphaHidden(true)
    }

    /// Sets up top segmented control for gallery source selection.
    func setupSegmentedControl() {
        viewModel.selectDefaultStorage()
        let segments = GallerySourceSegment.allCases.map { SettingsSegment(title: $0.title, disabled: false, image: nil) }
        segmentedControl.delegate = self
        segmentedControl.segmentModel = SettingsSegmentModel(segments: segments,
                                                             selectedIndex: GallerySourceSegment(source: viewModel.storageSourceType).index,
                                                             isBoolean: false)
    }

    /// Sets up side panel action buttons: download/share, delete, format SD, select.
    func setupPanelButtons() {
        mainActionButton.loaderColor = ColorName.defaultTextColor.color
        deleteButton.setup(title: L10n.commonDelete, style: .destructive)
        deleteButton.loaderColor = .white
        formatSDButton.setup(title: L10n.galleryFormatSdCard, style: .secondary1)
        sdCardErrorLabel.makeUp(with: .regular, and: .errorColor)
        sdCardErrorLabel.font = FontStyle.current.font(isRegularSizeClass)
        sdCardErrorIcon.tintColor = ColorName.errorColor.color
    }

    /// Updates select button state according to current selection mode.
    func updateSelectionMode(isEnabled: Bool) {
        let title = isEnabled
        ? L10n.cancel
        : L10n.commonSelect
        let style: ActionButtonStyle = isEnabled
        ? .secondary1
        : .default1
        selectButton.setup(title: title, style: style)

        selectAllButton.animateIsHiddenInStackView(!isEnabled)

        // Need to show selection count if `isEnabled`, source storage info else.
        selectionCountLabel.animateIsHidden(!isEnabled)
        mediaSourceContainer.animateIsHidden(isEnabled)
    }

    /// Updates side panel action buttons according to current state (source and selection).
    ///
    /// - Parameter type: the action button type (download or share)
    func updateMainActionButton(for type: GalleryActionType) {
        mainActionButton.setup(title: type.buttonTitle, style: type.buttonStyle)
    }

    func updateSelectButtonTitle() {
        selectAllButton.setup(title: viewModel.selectAllButtonTitle, style: .default1)
    }

    /// Updates selection count label with current selected medias count and size (if available).
    func updateSelectionCountLabel(selectionCount: Int, size: UInt64) {
        if viewModel.storageSourceType.isDeviceSource {
            selectionCountLabel.text = String(format: "%d %@",
                                              selectionCount,
                                              L10n.galleryMediaSelected.lowercased())
        } else {
            selectionCountLabel.text = String(format: "%d %@ (%@)",
                                              selectionCount,
                                              L10n.galleryMediaSelected.lowercased(),
                                              StorageUtils.sizeForFile(size: size))
        }
    }

    func updateMediaListStateInfo(_ state: MediaListState) {
        mediaListStackView.isHidden = !state.hasInfoMessage
        mediaListStateIcon.image = state.icon
        mediaListStateIcon.tintColor = ColorName.highlightColor.color
        mediaListStateLabel.text = state.label
        if state.hasInfoMessage {
            mediaListStateIcon.startRotate()
        } else {
            mediaListStateIcon.stopRotate()
        }
    }

    /// Updates SD card error view state.
    func updateSDCardErrorState(_ state: UserStorageState?) {
        if let state = state {
            sdCardErrorLabel.text = state == .needsFormat
            ? L10n.alertSdcardFormatErrorTitle
            : L10n.alertNoSdcardErrorTitle
            sdCardErrorView.alphaHidden(false)
        } else {
            sdCardErrorView.alphaHidden(true)
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
        viewModel.$downloadTaskState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.downloadProgressView.setProgress(state.progress, status: state.status)
            }
            .store(in: &cancellables)

        viewModel.$sdCardErrorState
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
            self?.updateSDCardErrorState(state)
        }
        .store(in: &cancellables)

        viewModel.$mediaListState
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
            self?.updateMediaListStateInfo(state)
        }
        .store(in: &cancellables)

        viewModel.$mainActionType
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] actionType in
                self?.updateMainActionButton(for: actionType)
        }
        .store(in: &cancellables)

        viewModel.$activeActionTypes
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] types in
                self?.updateButtons(activeTypes: types)
            }
            .store(in: &cancellables)

        viewModel.$enabledActionTypes
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] types in
                self?.updateButtons(enabledTypes: types)
            }
            .store(in: &cancellables)

        viewModel.$isFormatStorageAvailable
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAvailable in
                guard let self = self else { return }
                self.formatSDButton.isHiddenInStackView = !isAvailable
                if isAvailable {
                    self.formatSDButton.isEnabled = self.viewModel.isEnabled(.format)
                }
            }
            .store(in: &cancellables)

        viewModel.$filterItems
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateSelectButtonTitle()
        }
        .store(in: &cancellables)

        viewModel.selectedMediaUidsPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] uids in
                guard let self = self else { return }
                self.updateSelectionCountLabel(selectionCount: uids.count, size: self.viewModel.selectedMedias.size)
                self.updateSelectButtonTitle()
            }
            .store(in: &cancellables)
    }

    func updateButtons(enabledTypes types: GalleryActionType) {
        let isShareAvailable = types.contains(.share) && viewModel.mainActionType == .share
        let isDownloadAvailable = types.contains(.download) && viewModel.mainActionType == .download
        mainActionButton.isEnabled = isShareAvailable || isDownloadAvailable
        deleteButton.isEnabled = types.contains(.delete)
        formatSDButton.isEnabled = types.contains(.format)
        selectButton.isEnabled = types.contains(.select)
    }

    func updateButtons(activeTypes types: GalleryActionType) {
        if types.contains(.delete) {
            deleteButton.startLoader()
        } else {
            deleteButton.stopLoader()
        }
        let isSharing = types.contains(.share)
        DispatchQueue.main.async {
            isSharing ? self.mainActionButton.startLoader() : self.mainActionButton.stopLoader()
        }
        segmentedControl.alphaWithEnabledState(!isSharing)
        updateSelectionMode(isEnabled: types.contains(.select))
    }
}

// MARK: - Gallery Loading View Delegate.
extension GalleryViewController: GalleryLoadingViewDelegate {
    func shouldStopProgress() {
        viewModel.cancelDownload()
    }
}

// MARK: - SettingsSegmentedControlDelegate
extension GalleryViewController: SettingsSegmentedControlDelegate {
    func select(sourceSegment: GallerySourceSegment) {
        viewModel.setStorageSource(for: sourceSegment)
    }

    func settingsSegmentedControlDidChange(sender: SettingsSegmentedControl, selectedSegmentIndex: Int) {
        select(sourceSegment: GallerySourceSegment(index: selectedSegmentIndex))
    }
}
