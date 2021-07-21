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

import Combine
import UIKit
import SwiftyUserDefaults
import GroundSdk

/// View controller for bottom bar imaging settings bar.
final class ImagingSettingsBarViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var imagingSettingsBarStackView: UIStackView!
    @IBOutlet private weak var autoExposureStackView: UIStackView!
    @IBOutlet private weak var generalSettingsStackView: UIStackView!
    @IBOutlet private weak var specificSettingsStackView: UIStackView!
    @IBOutlet private weak var recordingItemsStackView: UIStackView!
    @IBOutlet private weak var photoItemsStackView: UIStackView!
    @IBOutlet private weak var dynamicRangeItemStackView: UIStackView!
    @IBOutlet private weak var autoExposureButton: UIControl!
    @IBOutlet private weak var autoExposurePadlockImageView: UIImageView!
    @IBOutlet private weak var autoModeButton: UIControl!
    @IBOutlet private weak var autoModeImageView: UIImageView!
    @IBOutlet private weak var shutterSpeedItemView: ImagingBarItemView!
    @IBOutlet private weak var cameraIsoItemView: ImagingBarItemView!
    @IBOutlet private weak var whiteBalanceItemView: ImagingBarItemView!
    @IBOutlet private weak var evCompensationItemView: ImagingBarItemView!
    @IBOutlet private weak var dynamicRangeItemView: DynamicRangeItemView!
    @IBOutlet private weak var photoResolutionItemView: ImagingBarItemView!
    @IBOutlet private weak var photoFormatItemView: ImagingBarItemView!
    @IBOutlet private weak var videoResolutionItemView: ImagingBarItemView!
    @IBOutlet private weak var framerateItemView: ImagingBarItemView!

    // MARK: - Internal Properties
    fileprivate(set) var isAutoExposureLocked: Bool = false
    weak var bottomBarDelegate: BottomBarViewControllerDelegate?

    // MARK: - Private Properties
    private weak var delegate: BottomBarContainerDelegate?
    private var autoModeViewModel = ImagingBarAutoModeViewModel()
    private var cameraModeViewModel = CameraModeViewModel()
    private var shutterSpeedItemViewModel = ImagingBarShutterSpeedViewModel()
    private var cameraIsoItemViewModel = ImagingBarCameraIsoViewModel()
    private var whiteBalanceItemViewModel = ImagingBarWhiteBalanceViewModel()
    private var evCompensationItemViewModel = ImagingBarEvCompensationViewModel()
    private var dynamicRangeBarViewModel = DynamicRangeBarViewModel()
    private var photoFormatItemViewModel = ImagingBarPhotoFormatViewModel()
    private var photoResolutionItemViewModel = ImagingBarPhotoResolutionViewModel()
    private var videoResolutionItemViewModel = ImagingBarVideoResolutionViewModel()
    private var framerateItemViewModel = ImagingBarFramerateViewModel()
    private var imagingSettingsBarViewModel = ImagingSettingsBarViewModel()
    // TODO injection
    private var exposureLockViewModel = ExposureLockViewModel(exposureLockService: Services.hub.exposureLockService)
    private var deselectableViewModels = [Deselectable]()
    /// Combine subscriptions.
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Setup
    static func instantiate(delegate: BottomBarContainerDelegate? = nil) -> ImagingSettingsBarViewController {
        let imagingSettingsBarVc = StoryboardScene.ImagingSettingsBar.initialScene.instantiate()
        imagingSettingsBarVc.delegate = delegate

        return imagingSettingsBarVc
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        deselectableViewModels = [shutterSpeedItemViewModel,
                                  cameraIsoItemViewModel,
                                  whiteBalanceItemViewModel,
                                  evCompensationItemViewModel,
                                  dynamicRangeBarViewModel,
                                  photoFormatItemViewModel,
                                  photoResolutionItemViewModel,
                                  videoResolutionItemViewModel,
                                  framerateItemViewModel]
        setupViewModels()
        initUI()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension ImagingSettingsBarViewController {
    @IBAction func autoExposurePadklockTouchedUpInside(_ sender: Any) {
        isAutoExposureLocked = !isAutoExposureLocked
        updateLockAEButtonUI(isLocked: isAutoExposureLocked)
        exposureLockViewModel.toggleExposureLock()
    }

    @IBAction func autoModeButtonTouchedUpInside(_ sender: Any) {
        autoModeViewModel.toggleAutoMode()
        logEvent(with: LogEvent.LogKeyHUDBottomBarButton.shutterSpeedSetting.name,
                 and: autoModeViewModel.state.value.isActive.logValue)
    }

    @IBAction func shutterSpeedItemTouchedUpInside(_ sender: Any) {
        shutterSpeedItemViewModel.toggleSelectionState()
        logEvent(with: LogEvent.LogKeyHUDBottomBarButton.shutterSpeedSetting.name,
                 and: shutterSpeedItemViewModel.state.value.mode?.key)
    }

    @IBAction func cameroIsoItemTouchedUpInside(_ sender: Any) {
        cameraIsoItemViewModel.toggleSelectionState()
        logEvent(with: LogEvent.LogKeyHUDBottomBarButton.cameraIsoSetting.name,
                 and: cameraIsoItemViewModel.state.value.mode?.key)
    }

    @IBAction func whiteBalanceItemTouchedUpInside(_ sender: Any) {
        whiteBalanceItemViewModel.toggleSelectionState()
        logEvent(with: LogEvent.LogKeyHUDBottomBarButton.whiteBalanceSetting.name,
                 and: whiteBalanceItemViewModel.state.value.mode?.key)
    }

    @IBAction func evCompensationItemTouchedUpInside(_ sender: Any) {
        evCompensationItemViewModel.toggleSelectionState()
        logEvent(with: LogEvent.LogKeyHUDBottomBarButton.evCompensationSetting.name,
                 and: evCompensationItemViewModel.state.value.isSelected.value.logValue)
    }

    @IBAction func dynamicRangeTouchedUpInside(_ sender: Any) {
        dynamicRangeBarViewModel.toggleSelectionState()
        logEvent(with: LogEvent.LogKeyHUDBottomBarButton.dynamicRangeSetting.name,
                 and: dynamicRangeBarViewModel.state.value.isSelected.value.logValue)
    }

    @IBAction func photoFormatItemTouchedUpInside(_ sender: Any) {
        photoFormatItemViewModel.toggleSelectionState()
        logEvent(with: LogEvent.LogKeyHUDBottomBarButton.photoFormatSetting.name,
                 and: photoFormatItemViewModel.state.value.mode?.key)
    }

    @IBAction func photoResolutionItemTouchedUpInside(_ sender: Any) {
        photoResolutionItemViewModel.toggleSelectionState()
        logEvent(with: LogEvent.LogKeyHUDBottomBarButton.photoResolutionSetting.name, and: photoResolutionItemViewModel.state.value.mode?.key)
    }

    @IBAction func videoResolutionItemTouchedUpInside(_ sender: Any) {
        videoResolutionItemViewModel.toggleSelectionState()
        logEvent(with: LogEvent.LogKeyHUDBottomBarButton.videoResolutionSetting.name, and: videoResolutionItemViewModel.state.value.mode?.key)
    }

    @IBAction func framerateItemTouchedUpInside(_ sender: Any) {
        framerateItemViewModel.toggleSelectionState()
        logEvent(with: LogEvent.LogKeyHUDBottomBarButton.framerateSetting.name,
                 and: framerateItemViewModel.state.value.mode?.key)
    }
}

// MARK: - Private Funcs
private extension ImagingSettingsBarViewController {
    /// Initializes interfaces.
    func initUI() {
        // Sets up corners
        autoExposureStackView.customCornered(corners: [.allCorners], radius: Style.mediumCornerRadius)
        dynamicRangeItemStackView.customCornered(corners: [.allCorners], radius: Style.mediumCornerRadius)
        specificSettingsStackView.customCornered(corners: [.allCorners], radius: Style.mediumCornerRadius)

        // Sets up the border of general setings
        generalSettingsStackView.setBorder(borderColor: ColorName.yellowSea.color, borderWidth: Style.largeBorderWidth)

        // Sets up item bar colors
        shutterSpeedItemView.unselectedBackgroundColor = ColorName.yellowSea30.color
        shutterSpeedItemView.selectedBackgroundColor = ColorName.yellowSea.color
        shutterSpeedItemView.unselectedTextColor = ColorName.sambuca.color
        shutterSpeedItemView.selectedTextColor = ColorName.sambuca.color

        cameraIsoItemView.unselectedBackgroundColor = ColorName.yellowSea30.color
        cameraIsoItemView.selectedBackgroundColor = ColorName.yellowSea.color
        cameraIsoItemView.unselectedTextColor = ColorName.sambuca.color
        cameraIsoItemView.selectedTextColor = ColorName.sambuca.color
    }

    /// Sets up all imaging bar view models.
    func setupViewModels() {
        // Setup state update callbacks.
        cameraModeViewModel.state.valueChanged = { [weak self] state in
            self?.photoItemsStackView.isHidden = state.cameraMode == .recording
            self?.recordingItemsStackView.isHidden = state.cameraMode == .photo
        }

        // Setup dynamic range view model and its item view.
        dynamicRangeBarViewModel.state.valueChanged = { [weak self] state in
            self?.dynamicRangeItemView.model = state
        }

        dynamicRangeBarViewModel.state.value.isSelected.valueChanged = { [weak self] isSelected in
            guard let viewModel = self?.dynamicRangeBarViewModel else {
                return
            }
            isSelected ? self?.delegate?.showLevelTwo(viewModel: viewModel) : self?.delegate?.hideLevelTwo(viewModel: viewModel)
            self?.dynamicRangeItemView.model = viewModel.state.value
            if isSelected {
                self?.deselectAllViewModels(except: type(of: viewModel))
            }
        }

        dynamicRangeItemView.model = dynamicRangeBarViewModel.state.value

        // Setup other view models and their associated item views.
        setup(viewModel: shutterSpeedItemViewModel, itemView: shutterSpeedItemView)
        setup(viewModel: cameraIsoItemViewModel, itemView: cameraIsoItemView)
        setup(viewModel: evCompensationItemViewModel, itemView: evCompensationItemView)
        setup(viewModel: whiteBalanceItemViewModel, itemView: whiteBalanceItemView)
        setup(viewModel: photoFormatItemViewModel, itemView: photoFormatItemView)
        setup(viewModel: photoResolutionItemViewModel, itemView: photoResolutionItemView)
        setup(viewModel: videoResolutionItemViewModel, itemView: videoResolutionItemView)
        setup(viewModel: framerateItemViewModel, itemView: framerateItemView)

        exposureLockViewModel.statePublisher
            .sink { [unowned self] state in
                isAutoExposureLocked = state.locked
                updatePadlockForExposureLock(exposureLockState: state)
            }
            .store(in: &cancellables)

        imagingSettingsBarViewModel.state.valueChanged = { [weak self] state in
            self?.evCompensationItemView.isEnabled = state.isShutterAndISOManual == false
            self?.evCompensationItemView.alphaWithEnabledState(state.isShutterAndISOManual == false)
        }

        autoModeViewModel.state.valueChanged = { [weak self] state in
            self?.updateAutoMode(state: state)
        }
        updateAutoMode(state: autoModeViewModel.state.value)
    }

    /// Sets up a view model and its associated item view.
    ///
    /// - Parameters:
    ///    - viewModel: view model to setup
    ///    - itemView: associated item view
    func setup<T: ImagingBarState>(viewModel: BarButtonViewModel<T>,
                                   itemView: ImagingBarItemView) {
        // Arguments must be used as weak
        // otherwise they will not deinit properly.
        weak var weakViewModel = viewModel
        weak var weakItemView = itemView

        // Setup state update callback.
        weakViewModel?.state.valueChanged = { state in
            weakItemView?.model = state
        }
        // Setup selection state callback.
        weakViewModel?.state.value.isSelected.valueChanged = { [weak self] isSelected in
            guard let strongViewModel = weakViewModel else {
                return
            }
            isSelected ? self?.delegate?.showLevelTwo(viewModel: strongViewModel) : self?.delegate?.hideLevelTwo(viewModel: strongViewModel)
            weakItemView?.model = strongViewModel.state.value
            if isSelected {
                self?.deselectAllViewModels(except: type(of: strongViewModel))
            }
        }
        // Setup initial state.
        weakItemView?.model = weakViewModel?.state.value
    }

    /// Deselect all view models except view model from given class type.
    ///
    /// - Parameters:
    ///    - classType: string describing view model type that should remain selected
    func deselectAllViewModels(except classType: AnyClass? = nil) {
        deselectableViewModels
            .filter({ type(of: $0) != classType })
            .forEach({ $0.deselect() })
    }

    /// Update UI with given auto mode state.
    func updateAutoMode(state: ImagingBarAutoModeState) {
        if state.isActive {
            // Close level two bars if needed.
            shutterSpeedItemViewModel.deselect()
            cameraIsoItemViewModel.deselect()
            whiteBalanceItemViewModel.deselect()
        }
        evCompensationItemView.isEnabled = state.isActive
        evCompensationItemView.alphaWithEnabledState(state.isActive)
        autoModeImageView.image = state.image
        autoModeButton.backgroundColor = ColorName.yellowSea.color
    }

    /// Calls log event.
    ///
    /// - Parameters:
    ///     - itemName: Button name
    ///     - newValue: New value
    func logEvent(with itemName: String, and newValue: String?) {
        LogEvent.logAppEvent(itemName: itemName,
                             newValue: newValue,
                             logType: .button)
    }
}

// MARK: - AE Lock
private extension ImagingSettingsBarViewController {
    /// Updates lockAEButton UI according to lock state.
    ///
    /// - Parameters:
    ///    - isLocked: Boolean to precise the auto exposure button status
    func updateLockAEButtonUI(isLocked: Bool) {
        isAutoExposureLocked = isLocked
        autoExposureButton.backgroundColor = isLocked ? ColorName.yellowSea.color : ColorName.white90.color
        autoExposurePadlockImageView.image = isLocked ? Asset.BottomBar.Icons.lockAElocked.image : Asset.BottomBar.Icons.lockAEEnabled.image
        autoExposurePadlockImageView.tintColor = ColorName.sambuca.color
    }

    /// Updates lockAEButton visibility.
    ///
    /// - Parameters:
    ///    - isEnabled: Boolean to precise if the lock button is enabled
    func updateLockAEButtonVisibility(isEnabled: Bool) {
        updateLockAEButtonUI(isLocked: isEnabled)
        autoExposureButton.isEnabled = isEnabled
        autoExposureButton.alphaWithEnabledState(autoExposureButton.isEnabled)
        autoExposurePadlockImageView.alphaWithEnabledState(autoExposureButton.isEnabled)
    }

    /// Updates UI regading exposure lock state.
    ///
    /// - Parameters:
    ///    - exposureLockState: current exposure lock state
    func updatePadlockForExposureLock(exposureLockState: ExposureLockState) {
        switch exposureLockState {
        case .unavailable:
            updateLockAEButtonVisibility(isEnabled: false)
            updateAutoModeBarUI(isLocked: false)
        case .unlocked:
            updateLockAEButtonVisibility(isEnabled: true)
            updateLockAEButtonUI(isLocked: false)
            updateAutoModeBarUI(isLocked: false)
        case .lockingOnCurrentValues,
             .lockingOnRegion:
            updateLockAEButtonVisibility(isEnabled: false)
            updateLockAEButtonUI(isLocked: true)
            updateAutoModeBarUI(isLocked: true)
        case .lockedOnCurrentValues,
             .lockOnRegion:
            updateLockAEButtonVisibility(isEnabled: true)
            updateLockAEButtonUI(isLocked: true)
            updateAutoModeBarUI(isLocked: true)
        }
    }

    /// Updates auto mode bar according to lockAEButton state.
    ///
    /// - Parameters:
    ///    - isLocked: Boolean to precise the auto exposure button status
    func updateAutoModeBarUI(isLocked: Bool) {
        generalSettingsStackView.isUserInteractionEnabled = !isLocked
        generalSettingsStackView.alphaWithEnabledState(generalSettingsStackView.isUserInteractionEnabled)
    }
}
