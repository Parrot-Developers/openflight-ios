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
    case expandButton
    case collapseButton
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
    @IBOutlet private weak var behaviorStackView: UIStackView!
    @IBOutlet private weak var subBehaviorStackView: UIStackView!
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
    @IBOutlet private weak var expandButton: UIButton!
    @IBOutlet private weak var collapseButton: UIButton!

    // MARK: - Internal Properties
    weak var delegate: BottomBarContainerDelegate?
    weak var coordinator: HUDCoordinator? {
        didSet {
            guard let coordinator = coordinator else { return }
            missionLauncherButtonModel.coordinator = coordinator
            coordinator.showMissionLauncherPublisher.sink { [unowned self] in
                if $0 {
                    deselectAllViewModels(except: type(of: missionLauncherButtonModel))
                }
            }
            .store(in: &cancellables)
        }
    }

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    // TODO: wrong injection
    private let missionLauncherButtonModel = MissionLauncherButtonModel(currentMissionManager: Services.hub.currentMissionManager)
    private let cameraWidgetViewModel = CameraWidgetViewModel(exposureLockService: Services.hub.drone.exposureLockService)
    private let cameraCaptureModeViewModel = CameraCaptureModeViewModel()
    private let cameraShutterButtonViewModel = CameraShutterButtonViewModel()
    private let bottomBarViewModel = BottomBarViewModel()
    private let landingStates = HUDLandingViewModel()
    private let settingRth = SettingsRthViewModel()
    private var deselectableViewModels = [Deselectable]()
    // MARK: - Private Enums
    private enum Constants {
        static let defaultAnimationDuration: TimeInterval = 0.35
        static let collapseAnimationDuration: TimeInterval = 0.2
        static let fadeInAnimationDuration: TimeInterval = 0.1
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        missionLauncherButton.model = missionLauncherButtonModel
        deselectableViewModels = [missionLauncherButtonModel as Deselectable, cameraWidgetViewModel, cameraCaptureModeViewModel]
        observeViewModels()
        initViewModelsState()
        observeViewModelsIsSelectedChange()
        collapseButton.isHidden = true
        expandButton.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        initButtons()

        let missionMode = self.bottomBarViewModel.state.value.missionMode
        self.updateView(for: missionMode)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        rightStackView.updateSeparators()
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

    @IBAction func collapseButtonTouchedUpInside(_ sender: Any) {
        updateExpandAndCollapseViews(isCollapsing: true)
    }

    @IBAction func expandButtonTouchedUpInside(_ sender: Any) {
        updateExpandAndCollapseViews(isCollapsing: false)
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
    /// Init collapse and expand buttons.
    func initButtons() {
        collapseButton.customCornered(corners: [.topLeft, .bottomLeft],
                                      radius: Style.largeCornerRadius,
                                      backgroundColor: .clear,
                                      borderColor: .clear)
        expandButton.customCornered(corners: [.topLeft, .bottomLeft],
                                    radius: Style.largeCornerRadius,
                                    backgroundColor: .clear,
                                    borderColor: .clear)
    }

    /// Update expand and collapse view.
    ///
    /// - Parameters:
    ///     - isCollapsing: tells if we are collapsing or expanding the view
    func updateExpandAndCollapseViews(isCollapsing: Bool) {
        self.collapseButton.isHidden = isCollapsing
        self.expandButton.isHidden = !isCollapsing
        self.handleVisibiltyRightStack(hide: true)

        UIView.animate(withDuration: Constants.collapseAnimationDuration, animations: {
            let stackToLoad: [ImagingStackElement]? = isCollapsing ?
                self.bottomBarViewModel.state.value.missionMode.bottomBarRightStack :
                [.collapseButton, .cameraMode, .cameraSettings, .shutterButton]

            self.loadRightStack(for: stackToLoad)
        }, completion: { _ in
            self.rightStackView.updateSeparators()
            self.handleVisibiltyRightStack(hide: false)
        })
    }

    /// Hide or display the elements in the right stack.
    ///
    /// - Parameters:
    ///     - hide: boolean that specify if the elements in the right stack must be hidden or displayed
    func handleVisibiltyRightStack(hide: Bool) {
        self.cameraModeView.alpha = hide ? 0.0 : 1.0
        self.expandButton.alpha = hide ? 0.0 : 1.0
        self.collapseButton.alpha = hide ? 0.0 : 1.0
        self.cameraWidgetView.alpha = hide ? 0.0 : 1.0
        self.shutterButtonView.alpha = hide ? 0.0 : 1.0
    }

    /// Update bottom bar view.
    ///
    /// - Parameters:
    ///     - missionMode: update the UI for this mission mode.
    func updateView(for missionMode: MissionMode?) {
        self.behaviorStackView(for: missionMode)
        self.loadRightStack(for: missionMode?.bottomBarRightStack)
    }

    /// Load views in left stackview.
    ///
    /// - Parameters:
    ///     - missionMode: updates the UI for this mission mode.
    func behaviorStackView(for missionMode: MissionMode?) {
        // Remove all views in left stackView.
        self.behaviorStackView.safelyRemoveArrangedSubviews()
        self.subBehaviorStackView.safelyRemoveArrangedSubviews()

        let isReturningToHome = landingStates.state.value.isReturnHomeActive == true

        if isReturningToHome {
            let view = ReturnHomeBottomBarView()
            view.addBlurEffect()
            self.subBehaviorStackView.addArrangedSubview(view)
        }

        // Add views for a specific mission.
        var views: [UIView] = missionMode?.bottomBarLeftStack?() ?? []

        // If RTH is enabled, add only mandatory views.
        if isReturningToHome {
            views = views.filter({ $0 is MandatoryBottomBarView })
            // get the view for return home
            if !views.isEmpty {
                let separator = SeparatorView(size: Style.bottomBarSeparatorWidth,
                                              backColor: .clear)
                self.subBehaviorStackView.addArrangedSubview(separator)
            }
        }
        addMissionViews(views)
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
                self.deselectableViewModels.append(barButtonView.viewModel)
            }

            if view is BehaviourModeView {
                self.behaviorStackView.addArrangedSubview(view)
            }
            if !(view is SeparatorView) && !(view is BehaviourModeView) {
                 self.subBehaviorStackView.addArrangedSubview(view)
            }
        }

        // Prevents the BehaviourModeView to be hidden when the drone is connecting in some case.
        self.behaviorStackView.layoutIfNeeded()
        self.subBehaviorStackView.layoutIfNeeded()
    }

    /// Displays views in right stackview.
    ///
    /// - Parameters:
    ///     - stackElements: updates the UI with the imaging stack to display
    func loadRightStack(for stackElements: [ImagingStackElement]?) {
        guard let rightStack = stackElements else {
            self.expandButton.isHidden = true
            self.collapseButton.isHidden = true
            self.cameraModeView.isHidden = true
            self.cameraWidgetView.isHidden = true
            self.shutterButtonView.isHidden = true
            return
        }

        self.expandButton.isHidden = !rightStack.contains(.expandButton)
        self.collapseButton.isHidden = !rightStack.contains(.collapseButton)
        self.cameraModeView.isHidden = !rightStack.contains(.cameraMode)
        self.cameraWidgetView.isHidden = !rightStack.contains(.cameraSettings)
        self.shutterButtonView.isHidden = !rightStack.contains(.shutterButton)

        self.rightStackView.updateSeparators()
    }

    /// Observes View Models state changes.
    func observeViewModels() {
        bottomBarViewModel.state.valueChanged = { [weak self] state in
            UIView.animate(withDuration: Constants.defaultAnimationDuration) {
                self?.bottomBarView.alphaHidden(state.shouldHide)
            }

            self?.updateView(for: state.missionMode)
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
        landingStates.state.valueChanged = { [weak self] _ in
            self?.updateView(for: self?.bottomBarViewModel.state.value.missionMode)
        }
    }

    /// Inits View Models state.
    func initViewModelsState() {
        cameraWidgetView.model = cameraWidgetViewModel.state.value
        cameraModeView.model = cameraCaptureModeViewModel.state.value
        cameraShutterButton.model = cameraShutterButtonViewModel.state.value
    }

    /// Observes View Models isSelected changes.
    func observeViewModelsIsSelectedChange() {
        cameraWidgetViewModel.state.value.isSelected.valueChanged = { [weak self] isSelected in
            guard let viewModel = self?.cameraWidgetViewModel else { return }
            isSelected ? self?.delegate?.showLevelOne(viewModel: viewModel) : self?.delegate?.hideLevelOne(viewModel: viewModel)
            self?.cameraWidgetView.model = viewModel.state.value
            if isSelected {
                self?.deselectAllViewModels(except: type(of: viewModel))
            }
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

// MARK: - DeselectAllViewModelsDelegate
extension BottomBarViewController: DeselectAllViewModelsDelegate {
    func deselectAllViewModels(except classType: AnyClass? = nil) {
        deselectableViewModels
            .filter({ type(of: $0) != classType })
            .forEach({ $0.deselect() })
    }
}
