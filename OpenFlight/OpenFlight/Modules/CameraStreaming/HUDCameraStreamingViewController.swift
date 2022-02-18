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
import GroundSdk
import Combine

// MARK: - Internal Enums
public enum HUDCameraStreamingMode {
    case fullscreen
    case preview
}

// MARK: - Protocols
public protocol HUDCameraStreamingViewControllerDelegate: AnyObject {
    /// Called when the stream content zone changes.
    func didUpdate(contentZone: CGRect?)
}

/// View controller that manages the different states and layers of the streaming.
public final class HUDCameraStreamingViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var snowView: SnowView!
    @IBOutlet private weak var streamView: StreamView!

    // MARK: - Internal Properties
    weak var delegate: HUDCameraStreamingViewControllerDelegate?
    /// Current mode of the streaming view (most layers are removed for preview mode.
    public var mode: HUDCameraStreamingMode = .fullscreen

    // MARK: - Private Properties
    private var contentZone: CGRect = .zero
    private var cancellables = Set<AnyCancellable>()
    /// Whether streaming is enabled.
    private var streamingEnabled: Bool?

    // TODO: wrong injection
    private unowned var currentMissionManager = Services.hub.currentMissionManager
    // Views.
    private var borderView: UIView?
    private var proposalAndTrackingView: ProposalAndTrackingView?
    // ViewModels.
    private let cameraStreamingViewModel = HUDCameraStreamingViewModel()
    private var trackingViewModel: TrackingViewModel? {
        didSet {
            guard trackingViewModel == nil else { return }
            clearTrackingAndProposalsView()
        }
    }

    // MARK: - Private Enums
    private enum Constants {
        static let streamMiniatureBorderWidth: CGFloat = 2.0
        static let streamMiniatureBorderColor: UIColor = .white
    }

    // MARK: - Setup
    public static func instantiate() -> HUDCameraStreamingViewController {
        return StoryboardScene.HUDCameraStreaming.initialScene.instantiate()
    }

    // MARK: - Deinit
    deinit {
        deinitStream()
    }

    // MARK: - Override Funcs
    public override func viewDidLoad() {
        super.viewDidLoad()

        if !Platform.isSimulator {
            setupViewModels()
        }
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        snowView.isHidden = false
        enableMonitoring(streamingEnabled ?? true)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        updateContentZone(to: streamView.contentZone)
        streamView.contentZoneListener = { [weak self] contentZone in
            self?.updateContentZone(to: contentZone)
        }
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        enableMonitoring(false)
        streamView.contentZoneListener = nil
    }

    public override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Internal Funcs
extension HUDCameraStreamingViewController {

    /// Add a border to the stream view.
    func addBorder() {
        borderView?.removeFromSuperview()
        let borderView = UIView(frame: view.frame)
        borderView.setBorder(borderColor: Constants.streamMiniatureBorderColor,
                             borderWidth: Constants.streamMiniatureBorderWidth)
        view.addSubview(borderView)
        self.borderView = borderView
    }

    /// Removes the border of the stream view.
    func removeBorder() {
        borderView?.removeFromSuperview()
        borderView = nil
    }

    /// Stops the stream (⚠️ only works after viewDidAppear).
    func stopStream() {
        streamingEnabled = false
        enableMonitoring(false)
    }

    /// Restarts previously stopped stream.
    func restartStream() {
        streamingEnabled = true
        enableMonitoring(true)
    }
}

// MARK: - Private Funcs
private extension HUDCameraStreamingViewController {

    /// Sets up view models associated with the view.
    func setupViewModels() {
        cameraStreamingViewModel.state.valueChanged = { [weak self] state in
            self?.onStateUpdate(state)
        }
        onStateUpdate(cameraStreamingViewModel.state.value)

        cameraStreamingViewModel.$cameraLive
            .sink { [unowned self] cameraLive in
                onCameraLiveUpdate(cameraLive)
            }.store(in: &cancellables)

        cameraStreamingViewModel.$snowVisible
            .sink { [unowned self] snowVisible in
                snowView.isHidden = !snowVisible
            }.store(in: &cancellables)

        listenMissionMode()
    }

    /// Listens current mission mode.
    func listenMissionMode() {
        currentMissionManager.modePublisher.sink { [unowned self] in
            if $0.isTrackingMode {
                setupTrackingViewModel()
            } else {
                clearTracking()
            }
        }
        .store(in: &cancellables)
    }

    /// Sets up tracking view model.
    func setupTrackingViewModel() {
        if trackingViewModel == nil {
            trackingViewModel = TrackingViewModel()
            trackingViewModel?.enableMonitoring(true)
        }

        if proposalAndTrackingView == nil {
            proposalAndTrackingView = ProposalAndTrackingView(frame: CGRect.zero,
                                                              delegate: self)
            proposalAndTrackingView?.updateFrame(contentZone)
            view.addSubview(proposalAndTrackingView)
        }
        trackingViewModel?.state.valueChanged = { [weak self] state in
            if let currentTilt = state.tilt {
                self?.proposalAndTrackingView?.updateTilt(currentTilt)
            }

            if let trackingInfo = state.trackingInfo {
                self?.proposalAndTrackingView?.trackInfoDidChange(trackingInfo)
            }

            if state.droneNotConnected == true {
                self?.proposalAndTrackingView?.clearTrackingAndProposals()
            }
        }
    }

    /// Enables or disables monitoring for all view models.
    ///
    /// - Parameters:
    ///    - enabled: whether monitoring is enabled
    func enableMonitoring(_ enabled: Bool) {
        cameraStreamingViewModel.enableMonitoring(enabled)
        trackingViewModel?.enableMonitoring(enabled)
    }

    /// Called when streaming state is updated.
    ///
    /// - Parameters:
    ///    - state: state from HUDCameraStreamingViewModel
    func onStateUpdate(_ state: HUDCameraStreamingState) {
        if !state.streamEnabled {
            clearTracking()
        } else if currentMissionManager.mode.isTrackingMode,
            trackingViewModel == nil {
            setupTrackingViewModel()
            proposalAndTrackingView?.updateFrame(contentZone)
        }
        updateOverexposure()
    }

    /// Called when camera live is updated.
    ///
    /// - Parameters:
    ///    - cameraLive: camera live from drone
    func onCameraLiveUpdate(_ cameraLive: CameraLive?) {
        streamView.setStream(stream: cameraLive)
    }

    /// Updates the visibility of overexposure areas.
    func updateOverexposure() {
        let overexposureSetting = cameraStreamingViewModel.state.value.overexposureSetting
        streamView.zebrasEnabled = overexposureSetting.boolValue
    }

    /// Updates the content zone of the stream.
    ///
    /// - Parameters:
    ///    - zone: new size to update
    func updateContentZone(to zone: CGRect) {
        guard let scale = view.window?.screen.nativeScale else {
            return
        }

        let frame = zone.reduce(by: scale)

        delegate?.didUpdate(contentZone: frame)
        proposalAndTrackingView?.updateFrame(frame)
        contentZone = frame
    }

    /// Removes all traces from tracking functionnality.
    func clearTracking() {
        trackingViewModel?.enableMonitoring(false)
        trackingViewModel = nil
    }

    /// Removes tracking and proposals view.
    func clearTrackingAndProposalsView() {
        proposalAndTrackingView?.clearTrackingAndProposals(clearDrawView: true)
        proposalAndTrackingView?.removeFromSuperview()
        proposalAndTrackingView = nil
    }

    /// Deinit stream.
    func deinitStream() {
        streamView.setStream(stream: nil)
    }
}

// MARK: - ProposalAndTracking Delegate
extension HUDCameraStreamingViewController: ProposalAndTrackingDelegate {
    func didDrawSelection(_ frame: CGRect) {
        guard let proposalAndTrackingView = proposalAndTrackingView else {
            return
        }

        let frameSelected = CGRect(x: CGFloat(frame.minX / proposalAndTrackingView.frame.width),
                                   y: CGFloat(frame.minY / proposalAndTrackingView.frame.height),
                                   width: CGFloat(frame.width / proposalAndTrackingView.frame.width),
                                   height: CGFloat(frame.height / proposalAndTrackingView.frame.height))

        trackingViewModel?.sendSelectionToDrone(frame: frameSelected)
    }

    func didSelect(proposalId: UInt) {
        trackingViewModel?.sendProposalToDrone(proposalId: proposalId)
    }

    func didDeselectTarget() {
        trackingViewModel?.removeAllTargets()
    }
}
