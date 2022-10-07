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

// MARK: - Protocols
/// Protocol used to deselect view models.
protocol DeselectAllViewModelsDelegate: AnyObject {
    /// Deselect all view models except view model from given class type.
    ///
    /// - Parameters:
    ///    - classType: string describing view model type that should remain selected
    func deselectAllViewModels(except classType: AnyClass?)
}

/// Protocol used to knows if a view must be present in bottom bar, whatever happen.
public protocol MandatoryBottomBarView { }

/// Enum that represent all elements in right stack of the bottom bar.
public enum ImagingStackElement {
    case cameraMode
    case cameraSettings
    case shutterButton

    /// Returns the classic imaging stack with the camera mode, the camera settings and the shutter button.
    public static var classicStack: [ImagingStackElement] = [
        .cameraMode,
        .cameraSettings,
        .shutterButton
    ]
}

/// HUD Bottom bar view controller.
/// Manages widgets like Camera mode, camera settings or Speed settings.
final class BottomBarViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var bottomBarView: UIView!
    @IBOutlet private weak var mainStackView: MainStackView!
    @IBOutlet private weak var behaviorStackView: UIStackView!
    @IBOutlet private weak var missionLauncherButton: MissionLauncherButton!
    @IBOutlet private weak var rightStackView: UIStackView!
    @IBOutlet private weak var cameraWidgetView: CameraWidgetView!
    @IBOutlet private weak var cameraModeView: BarButtonView! {
        didSet {
            cameraModeView.roundedCorners = [.topLeft, .bottomLeft]
        }
    }

    @IBOutlet private weak var shutterButtonView: UIView!
    @IBOutlet private weak var cameraShutterButton: CameraShutterButton!

    // MARK: - Internal Properties
    weak var delegate: BottomBarContainerDelegate?
    weak var bottomBarService: HudBottomBarService?
    weak var coordinator: HUDCoordinator? {
        didSet {
            guard let coordinator = coordinator else { return }
            missionLauncherButtonModel.coordinator = coordinator
            showMissionLauncherCancellable = coordinator.showMissionLauncherPublisher.sink { [unowned self] in
                if $0 {
                    deselectAllViewModels(except: type(of: missionLauncherButtonModel))
                }
                hideElementsIfNeeded(isMissionLauncherShown: $0)
            }
        }
    }

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    // TODO: wrong injection
    private let missionLauncherButtonModel = MissionLauncherButtonModel(currentMissionManager: Services.hub.currentMissionManager,
                                                                        navigationStackService: Services.hub.ui.navigationStack)
    private let cameraWidgetViewModel = CameraWidgetViewModel(exposureLockService: Services.hub.drone.exposureLockService)
    private let cameraCaptureModeViewModel = CameraCaptureModeViewModel(
        panoramaService: Services.hub.panoramaService, currentMissionManager: Services.hub.currentMissionManager)
    private let cameraShutterButtonViewModel = CameraShutterButtonViewModel()
    private let bottomBarViewModel = BottomBarViewModel()
    private let landingStates = HUDLandingViewModel()
    private var deselectableViewModels = [Deselectable]()
    private let currentMissionManager: CurrentMissionManager = Services.hub.currentMissionManager
    private let runManager: FlightPlanRunManager = Services.hub.flightPlan.run
    private var runningState: FlightPlanRunningState?
    private var isMissionLauncherShown: Bool = false
    private var stateMachineCancellable: AnyCancellable?
    private var showMissionLauncherCancellable: AnyCancellable?

    // MARK: - Private Enums
    private enum Constants {
        static let defaultAnimationDuration: TimeInterval = 0.35
        static let fadeValue: CGFloat = 0.9
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        missionLauncherButton.model = missionLauncherButtonModel
        observeViewModels()
        initViewModelsState()
        observeViewModelsIsSelectedChange()
        view.translatesAutoresizingMaskIntoConstraints = false

        bottomBarService?.modePublisher.sink { [weak self] mode in
            if mode == .closed {
                self?.deselectAllViewModels()
            }
        }
        .store(in: &cancellables)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let missionMode = bottomBarViewModel.state.value.missionMode
        updateView(for: missionMode)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Auto close when view disappears.
        deselectAllViewModels()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension BottomBarViewController {
    @IBAction func missionLauncherButtonTouchedUpInside(_ sender: Any) {
        guard let coordinator = coordinator else { return }
        if coordinator.isMissionLauncherShown {
            coordinator.hideMissionLauncher()
        } else {
            coordinator.showMissionLauncher()
        }
        logEvent(with: LogEvent.LogKeyHUDBottomBarButton.missionLauncher.name,
                 and: coordinator.isMissionLauncherShown.logValue)
    }

    @IBAction func cameraWidgetTouchedUpInside(_ sender: Any) {
        cameraWidgetViewModel.toggleSelectionState()
        logEvent(with: LogEvent.LogKeyHUDBottomBarButton.cameraWidget.name,
                 and: cameraWidgetViewModel.state.value.isSelected.value.logValue)
    }

    @IBAction func cameraModeTouchedUpInside(_ sender: Any) {
        cameraCaptureModeViewModel.toggleSelectionState()
        logEvent(with: LogEvent.LogKeyHUDBottomBarButton.cameraMode.name, and: cameraCaptureModeViewModel.state.value.isSelected.value.logValue)
    }

    @IBAction func cameraShutterButtonTouchedUpInside(_ sender: Any) {
        cameraShutterButtonViewModel.toggleCapture()
        logEvent(with: LogEvent.LogKeyHUDBottomBarButton.cameraShutter.name, and: cameraShutterButtonViewModel.state.value.cameraCaptureMode.description)
    }
}

// MARK: - Private Funcs
private extension BottomBarViewController {
    /// Update bottom bar view.
    ///
    /// - Parameters:
    ///     - missionMode: update the UI for this mission mode.
    func updateView(for missionMode: MissionMode?) {
        behaviorStackView(for: missionMode)
        loadRightStack(for: missionMode)
    }

    /// Load views in left stackview.
    ///
    /// - Parameters:
    ///     - missionMode: updates the UI for this mission mode.
    func behaviorStackView(for missionMode: MissionMode?) {
        // Remove all views in left stackView.
        behaviorStackView.safelyRemoveArrangedSubviews()
        deselectableViewModels = [cameraWidgetViewModel, cameraCaptureModeViewModel]

        // Add views for a specific mission.
        // If RTH is enabled, add only mandatory views.
        let isReturnHomeActive = landingStates.isReturHomeActiveValue == true
        let views = missionMode?.bottomBarLeftStack?()
            .filter { isReturnHomeActive ? $0 is MandatoryBottomBarView : true } ?? []

        addMissionViews(views)
        view.layoutIfNeeded()
    }

    /// Add mission views in bottom left view stack.
    ///
    /// - Parameters:
    ///     - views: views to add
    func addMissionViews(_ views: [UIView]) {
        // Apply specific treatment for views.
        for view in views {
            if let barButtonView = view as? BehaviourModeView {
                barButtonView.delegate = delegate
                barButtonView.deselectAllViewModelsDelegate = self
                deselectableViewModels.append(barButtonView.viewModel)

                behaviorStackView.addArrangedSubview(barButtonView)
            }
        }

        // Hide empty behaviorStackView in order to avoid extra spacing.
        behaviorStackView.hideIfEmpty()
    }

    /// Displays views in right stackview.
    ///
    /// - Parameters:
    ///     - missionMode: updates the UI for this mission mode.
    func loadRightStack(for missionMode: MissionMode?) {
        guard let missionMode = missionMode else {
            [cameraModeView, cameraWidgetView, shutterButtonView].forEach { $0?.alpha = Constants.fadeValue }
            cameraShutterButton.isEnabled = false
            return
        }

        var isHidden = false
        if missionMode.flightPlanProvider != nil {
            switch runningState {
            case .playing,
                 .paused:
                isHidden = isMissionLauncherShown
            default:
                isHidden = true
            }
        }
        rightStackView.isHidden = isHidden
        shutterButtonView.isHidden = isHidden
        guard !isHidden else { return }

        let rightStack = missionMode.bottomBarRightStack
        cameraModeView.alpha = rightStack.contains(.cameraMode) ? 1 : Constants.fadeValue
        cameraModeView.isEnabled = rightStack.contains(.cameraMode)
        cameraWidgetView.alpha = rightStack.contains(.cameraSettings) ? 1 : Constants.fadeValue
        cameraWidgetView.isEnabled = rightStack.contains(.cameraSettings)
        shutterButtonView.alpha = rightStack.contains(.shutterButton) ? 1 : Constants.fadeValue
        cameraShutterButton.isEnabled = missionMode.isCameraShutterButtonEnabled

        let removeSeparators = !cameraModeView.isEnabled && !cameraWidgetView.isEnabled
        removeSeparators
            ? rightStackView.removeSeparators()
            : rightStackView.updateSeparators()
    }

    /// Hides stack elements if mission panel is open.
    ///
    /// - Parameters:
    ///    - isMissionLauncherShown: Mission launcher opening state.
    func hideElementsIfNeeded(isMissionLauncherShown: Bool = false) {
        self.isMissionLauncherShown = isMissionLauncherShown
        rightStackView?.isHidden = isMissionLauncherShown
        behaviorStackView?.isHidden = isMissionLauncherShown || behaviorStackView.subviews.isEmpty
        shutterButtonView?.isHidden = isMissionLauncherShown

        let missionMode = bottomBarViewModel.state.value.missionMode
        if missionMode.flightPlanProvider != nil {
            updateView(for: missionMode)
        }
    }

    /// Observes View Models state changes.
    func observeViewModels() {
        bottomBarViewModel.state.valueChanged = { [weak self] state in
            UIView.animate(withDuration: Constants.defaultAnimationDuration) {
                self?.bottomBarView.alphaHidden(state.shouldHide)
            }
            self?.updateView(for: state.missionMode)
            self?.listenStateMachine(missionMode: state.missionMode)
        }
        cameraWidgetViewModel.state.valueChanged = { [weak self] state in
            self?.cameraWidgetView.model = state
        }
        cameraCaptureModeViewModel.state.valueChanged = { [weak self] state in
            self?.cameraModeView.model = state
        }
        cameraShutterButtonViewModel.state.valueChanged = { [weak self] state in
            self?.cameraShutterButton.model = state
        }
        cameraShutterButtonViewModel.hideBottomBarEventPublisher.sink { [unowned self] _ in
            deselectAllViewModels(except: nil)
        }
        .store(in: &cancellables)

        landingStates.isBasicRthActive
            .removeDuplicates()
            .sink { [unowned self] _ in
                updateView(for: bottomBarViewModel.state.value.missionMode)
            }
            .store(in: &cancellables)
    }

    /// Inits View Models state.
    func initViewModelsState() {
        cameraWidgetView.model = cameraWidgetViewModel.state.value
        cameraModeView.model = cameraCaptureModeViewModel.state.value
        cameraShutterButton.layoutIfNeeded()
        cameraShutterButton.model = cameraShutterButtonViewModel.state.value
    }

    /// Observes View Models isSelected changes.
    func observeViewModelsIsSelectedChange() {
        cameraWidgetViewModel.state.value.isSelected.valueChanged = { [weak self] isSelected in
            guard let self = self else { return }

            let viewModel = self.cameraWidgetViewModel
            if !isSelected {
                self.delegate?.hideLevelOne(viewModel: viewModel)
            } else if self.rightStackView.isHiddenInStackView == false {
                // Camera widget is not hidden and VM is selected => show level one.
                // (Need to ensure camera widget is visible, as VM update may be received after bottom bar is hidden,
                // e.g. when switching mission right after an AE lock long press.)
                self.delegate?.showLevelOne(viewModel: viewModel)
                self.deselectAllViewModels(except: type(of: viewModel))
            }

            self.cameraWidgetView.model = viewModel.state.value
        }
        cameraCaptureModeViewModel.state.value.isSelected.valueChanged = { [weak self] isSelected in
            guard let viewModel = self?.cameraCaptureModeViewModel else { return }
            isSelected ? self?.delegate?.showLevelOne(viewModel: viewModel) : self?.delegate?.hideLevelOne(viewModel: viewModel)
            self?.cameraModeView.model = viewModel.state.value
            if isSelected {
                self?.deselectAllViewModels(except: type(of: viewModel))
            }
        }
    }

    /// Listen state machine and running state
    ///
    /// - Parameters:
    ///     - missionMode: The current mission mode
    func listenStateMachine(missionMode: MissionMode) {
        stateMachineCancellable = missionMode.stateMachine?.statePublisher
            .combineLatest(runManager.statePublisher)
            .sink(receiveValue: { [weak self] (_, runningState) in
                guard let self = self else { return }
                self.runningState = runningState
                self.loadRightStack(for: missionMode)
            })
    }

    /// Calls log event.
    ///
    /// - Parameters:
    ///     - itemName: Button name
    ///     - newValue: New value
    func logEvent(with itemName: String, and newValue: String?) {
        LogEvent.log(.button(item: itemName, value: newValue ?? ""))
    }
}

// MARK: - DeselectAllViewModelsDelegate
extension BottomBarViewController: DeselectAllViewModelsDelegate {
    func deselectAllViewModels(except classType: AnyClass? = nil) {
        deselectableViewModels
            .filter({ type(of: $0) != classType })
            .forEach({ $0.deselect() })
    }
}
