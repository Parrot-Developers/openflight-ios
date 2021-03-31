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
protocol FlightPlanPanelCustomDisplay: class {
    var flightPlanPanelProgressView: FlightPlanPanelProgressView? { get }
    /// Dedicated function for specific setup regarding mission sub mode.
    func setupExtraContent(with state: FlightPlanPanelState)
}

extension FlightPlanPanelCustomDisplay where Self: UIViewController {
    func setupExtraContent(with state: FlightPlanPanelState) {
        // Nothing in default implementation.
    }
}

/// Manages HUD's flight plan right panel.

final class FlightPlanPanelViewController: UIViewController, FlightPlanPanelCustomDisplay {
    // MARK: - Outlets
    @IBOutlet private weak var projectView: UIView!
    @IBOutlet private weak var projectNameLabel: UILabel! {
        didSet {
            projectNameLabel.makeUp(with: .small, and: .white50)
            projectNameLabel.text = L10n.flightPlanMenuProject.uppercased()
        }
    }
    @IBOutlet private weak var projectButton: UIButton! {
        didSet {
            projectButton.makeup()
        }
    }
    @IBOutlet private weak var historyButton: UIButton!
    @IBOutlet private weak var historySeparator: UIView!
    @IBOutlet private weak var playButton: UIButton! {
        didSet {
            playButton.makeup(with: .regular, color: .white)
        }
    }
    @IBOutlet weak var arrowView: SimpleArrowView! {
        didSet {
            arrowView.orientation = .bottom
        }
    }
    @IBOutlet private weak var stopButton: UIButton! {
        didSet {
            stopButton.backgroundColor = ColorName.redTorch.color
            stopButton.applyCornerRadius(Style.largeCornerRadius)
            stopButton.setImage(Asset.Common.Icons.stop.image, for: .normal)
        }
    }
    @IBOutlet private weak var editButton: UIButton! {
        didSet {
            editButton.applyCornerRadius(Style.largeCornerRadius)
            editButton.backgroundColor = ColorName.white20.color
            editButton.makeup(with: .large, color: .greenSpring)
        }
    }
    @IBOutlet private weak var buttonsStackView: UIStackView!
    @IBOutlet private weak var estimationsView: FlightPlanPanelEstimationView!
    @IBOutlet private weak var estimationsStackView: UIStackView!
    @IBOutlet private weak var noFlightPlanLabel: UILabel!
    @IBOutlet private weak var cameraStreamingContainerView: UIView!
    @IBOutlet private weak var progressViewContainer: UIView!
    @IBOutlet private weak var bottomStackViewSafeAreaTrailingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var bottomStackViewSuperviewTrailingConstraint: NSLayoutConstraint!

    // MARK: - Internal Properties
    weak var delegate: FlightPlanEditionViewControllerDelegate?
    weak var managerCoordinator: FlightPlanManagerCoordinator?
    /// Expose this label to customize it in extensions.
    var infoLabel: UILabel {
        return noFlightPlanLabel
    }
    /// Expose this button to customize it in extensions.
    var actionButton: UIButton {
        return editButton
    }
    var flightPlanPanelProgressView: FlightPlanPanelProgressView?

    // MARK: - Private Properties
    private var flightPlanPanelViewModel = FlightPlanPanelViewModel()
    private weak var cameraStreamingViewController: HUDCameraStreamingViewController?

    // MARK: - Private Enums
    private enum Constants {
        static let disableControlsDuration: TimeInterval = 0.75
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        let progressView = FlightPlanPanelProgressView(frame: progressViewContainer.frame)
        progressViewContainer.addWithConstraints(subview: progressView)
        self.flightPlanPanelProgressView = progressView

        updateEstimations()
        updateView(state: flightPlanPanelViewModel.state.value)
        setupOrientationObserver()

        panelDidHide()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Estimations may change regarding measurement system.
        updateEstimations(state: flightPlanPanelViewModel.state.value)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Internal Funcs
    /// Starts streaming component.
    func startStream() {
        let cameraStreamingVC = HUDCameraStreamingViewController.instantiate()
        self.addChild(cameraStreamingVC)
        cameraStreamingContainerView.addWithConstraints(subview: cameraStreamingVC.view)
        cameraStreamingVC.mode = .preview
        cameraStreamingVC.didMove(toParent: self)
        self.cameraStreamingViewController = cameraStreamingVC
    }

    /// Stops streaming component.
    func stopStream() {
        self.cameraStreamingContainerView.subviews.first?.removeFromSuperview()
        self.cameraStreamingViewController?.removeFromParent()
        self.cameraStreamingViewController = nil
    }

    /// Panel did show.
    func panelDidShow() {
        self.view.isHidden = false
        flightPlanPanelViewModel.state.valueChanged = { [weak self] state in
            self?.updateView(state: state)
        }
        updateView(state: flightPlanPanelViewModel.state.value)
    }

    /// Panel did hide.
    func panelDidHide() {
        flightPlanPanelViewModel.state.valueChanged = nil
        self.view.isHidden = true
    }
}

// MARK: - Actions
private extension FlightPlanPanelViewController {
    /// History button touched up inside.
    @IBAction func historyTouchUpInside(_ sender: Any) {
        if let flightPlanViewModel = FlightPlanManager.shared.currentFlightPlanViewModel {
            managerCoordinator?.startFlightPlanHistory(flightPlanViewModel: flightPlanViewModel)
        }
    }

    /// Project button touched up inside.
    @IBAction func projectTouchUpInside(_ sender: Any) {
        managerCoordinator?.startManagePlans()
    }

    /// Play button touched up inside.
    @IBAction func playButtonTouchedUpInside(_ sender: Any) {
        LogEvent.logAppEvent(itemName: LogEvent.LogKeyHUDPanelButton.play.name,
                             newValue: nil,
                             logType: .button)
        disableControlsForDelay()
        flightPlanPanelViewModel.startFlightPlan()
    }

    /// Edit button touched up inside.
    @IBAction func editButtonTouchedUpInside(_ sender: Any) {
        LogEvent.logAppEvent(itemName: LogEvent.LogKeyHUDPanelButton.edit.name,
                             newValue: nil,
                             logType: .button)

        // Creates a new flight plan if there is no loaded flight plan.
        if flightPlanPanelViewModel.state.value.isFlightPlanLoaded == false,
           let flightPlanProvider = flightPlanPanelViewModel.state.value.missionMode.flightPlanProvider {
            guard flightPlanProvider.flightPlanCoordinator != nil else {
                FlightPlanManager.shared.new(flightPlanProvider: flightPlanProvider)
                delegate?.startFlightPlanEdition()
                return
            }

            delegate?.startNewFlightPlan(flightPlanProvider: flightPlanProvider, creationCompletion: { [weak self] flightPlanCreated in
                DispatchQueue.main.async { [weak self] in
                    guard flightPlanCreated else { return }

                    FlightPlanManager.shared.new(flightPlanProvider: flightPlanProvider)
                    self?.delegate?.startFlightPlanEdition()
                }
            })
        } else {
            delegate?.startFlightPlanEdition()
        }
    }

    /// Stop button touched up inside.
    @IBAction func stopButtonTouchedUpInside(_ sender: Any) {
        LogEvent.logAppEvent(itemName: LogEvent.LogKeyHUDPanelButton.stop.name,
                             newValue: nil,
                             logType: .button)
        disableControlsForDelay()
        flightPlanPanelViewModel.stopFlightPlan()
    }
}

// MARK: - Private Funcs
private extension FlightPlanPanelViewController {
    /// Update estimations.
    ///
    /// - Parameters:
    ///     - state: Flight Plan Panel State
    func updateEstimations(state: FlightPlanPanelState? = nil) {
        estimationsStackView.isHidden = state?.isFlightPlanLoaded != true
        estimationsView.updateEstimations(model: state?.flightPlanEstimations)
    }

    /// Updates the view with current state.
    ///
    /// - Parameters:
    ///    - state: current flight plan panel state
    func updateView(state: FlightPlanPanelState) {
        let isAvailableToRun = state.runFlightPlanState?.isAvailable ?? false
        let runState = state.runFlightPlanState?.runState ?? .stopped
        let isActive = runState.isActive
        playButton.isHidden = !state.isFlightPlanLoaded
        playButton.isEnabled = isAvailableToRun && state.hasWayPoints
        playButton.setTitle(state.runFlightPlanState?.formattedDuration, for: .normal)
        actionButton.isHidden = isActive
        stopButton.isHidden = !isActive
        flightPlanPanelProgressView?.isHidden = !(state.isFlightPlanLoaded && state.isConnected())
        if isActive {
            buttonsStackView.distribution = .fill
            // TODO: add progress bar + timer on play button
            switch runState {
            case .playing:
                playButton.setImage(Asset.Common.Icons.pause.image, for: .normal)
                playButton.cornerRadiusedWith(backgroundColor: .clear,
                                              borderColor: ColorName.white.color,
                                              radius: Style.largeCornerRadius,
                                              borderWidth: Style.mediumBorderWidth)
            case .paused,
                 .uploading:
                setupDefaultPlayButtonStyle()
            default:
                break
            }

            let counterView = FlightPlanPanelMediaCounterView()
            flightPlanPanelProgressView?.setExtraViews([counterView])
        } else {
            buttonsStackView.distribution = .fillEqually
            setupDefaultPlayButtonStyle()
            editButton.setTitle(state.isFlightPlanLoaded ? L10n.commonEdit : L10n.flightPlanNewFlightPlan,
                                for: .normal)
            editButton.setTitleColor(state.isFlightPlanLoaded ? ColorName.white.color : ColorName.greenSpring.color,
                                     for: .normal)
            editButton.backgroundColor = state.isFlightPlanLoaded ? ColorName.white20.color : ColorName.greenSpring20.color

            flightPlanPanelProgressView?.setExtraViews([])
        }
        updateEstimations(state: state)
        noFlightPlanLabel.isHidden = state.isFlightPlanLoaded
        projectView.isHidden = !state.isFlightPlanLoaded

        infoLabel.text = L10n.flightPlanCreateFirst
        infoLabel.makeUp(with: .large, and: .white50)

        self.setupExtraContent(with: state)

        if let runFlightPlanState = state.runFlightPlanState {
            flightPlanPanelProgressView?.model = FlightPlanPanelProgressModel(withRunFlightPlanState: runFlightPlanState)
        }

        if let viewModel = FlightPlanManager.shared.currentFlightPlanViewModel {
            historyButton.isHidden = viewModel.executions.isEmpty == true
            historySeparator.isHidden = historyButton.isHidden
            projectButton.setTitle(viewModel.state.value.title,
                                   for: .normal)
        }
    }

    // Setup default play button style.
    func setupDefaultPlayButtonStyle() {
        playButton.setImage(Asset.Common.Icons.play.image, for: .normal)
        playButton.cornerRadiusedWith(backgroundColor: ColorName.greenSpring20.color,
                                      borderColor: .clear,
                                      radius: Style.largeCornerRadius,
                                      borderWidth: Style.mediumBorderWidth)
    }

    /// Disable controls for a specified time interval.
    ///
    /// - Parameters:
    ///     - delay: enable controls after this delay
    func disableControlsForDelay(_ delay: TimeInterval = Constants.disableControlsDuration) {
        buttonsStackView.isUserInteractionEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: { [weak self] in
            self?.buttonsStackView.isUserInteractionEnabled = true
        })
    }

    /// Sets up observer for device orientation.
    func setupOrientationObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateTrailingConstraint),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
        updateTrailingConstraint()
    }

    /// Updates trailing constraint according to current orientation.
    @objc func updateTrailingConstraint() {
        switch UIApplication.shared.statusBarOrientation {
        case .landscapeLeft:
            bottomStackViewSuperviewTrailingConstraint.isActive = false
            bottomStackViewSafeAreaTrailingConstraint.isActive = true
        case .landscapeRight:
            bottomStackViewSafeAreaTrailingConstraint.isActive = false
            bottomStackViewSuperviewTrailingConstraint.isActive = true
        default:
            break
        }
    }
}
