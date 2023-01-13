//    Copyright (C) 2022 Parrot Drones SAS
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

/// Gallery media player ViewController.

final class MediaBrowserViewController: UIViewController {
    private var browserManager: MediaBrowserManager!
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Outlets
    // Top Toolbar
    @IBOutlet private weak var topToolbarView: UIStackView!
    @IBOutlet private weak var backButton: UIButton!
    @IBOutlet private weak var mediaTitleView: GalleryMediaTitleView!
    @IBOutlet private weak var actionsView: UIView!
    @IBOutlet private weak var topSoundButton: UIButton!
    @IBOutlet private weak var topDeleteButton: UIButton!
    @IBOutlet private weak var topShareButton: UIButton!
    @IBOutlet private weak var topDownloadButton: DownloadButton!
    @IBOutlet private weak var pagerContainerView: UIView!

    @IBOutlet private weak var downloadProgressView: GalleryLoadingView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    // MARK: - Private Properties
    private var pageControlInitialTransform: CGAffineTransform = .init(rotationAngle: .pi / 2)
    private var media: GalleryMedia { browserManager.activeMedia }

    // MARK: - Constants
    private enum Constants {
        static let autoHideControlResetViewTag = 1
        static let controlsTapViewTag = 2
        static let autoHideControlsTimerDelay: TimeInterval = 2
        static let pageControlMargin: CGFloat = 30
        static let progressViewFullStyleBottomMargin: CGFloat = 8
        static let toolbarGradientMaxAlpha: CGFloat = 0.7
    }

    // MARK: - Setup
    /// Instantiates view controller.
    ///
    /// - Parameter browserManager: the browser manager
    /// - Returns: a `MediaBrowserViewController`
    static func instantiate(browserManager: MediaBrowserManager) -> MediaBrowserViewController {
        // TODO: [GalleryRework] Extract VM browser handling from manager to dedicated VM.
        let viewController = StoryboardScene.MediaBrowserViewController.initialScene.instantiate()
        viewController.browserManager = browserManager

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        addPagerController()
        initView()
        observeViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        LogEvent.log(.screen(LogEvent.Screen.galleryViewer))
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Update gradient @didLayoutSubviews in order to avoid display issue if layer not rendered yet.
        topToolbarView.addGradient(startAlpha: Constants.toolbarGradientMaxAlpha)
    }

    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var prefersStatusBarHidden: Bool { true }

    /// Adds pager child view controller to dedicated container.
    func addPagerController() {
        let pagerViewController = MediaPagerViewController.instantiate(browserManager: browserManager)
        add(pagerViewController, in: pagerContainerView)
    }

    /// Observes Gallery VM updates.
    func observeViewModel() {

        browserManager.$activeMedia
            .receive(on: DispatchQueue.main)
            .sink { [weak self] media in
                self?.mediaTitleView.model = media
                self?.updateActionState(of: media)
        }
        .store(in: &cancellables)

        browserManager.downloadIdsPublisher
            .combineLatest(browserManager.deleteUidsPublisher)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.updateActionState(of: self.media)
            }
            .store(in: &cancellables)

        browserManager.$areControlsShown.removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] areShown in
            self?.topToolbarView.showFromEdge(.top, show: areShown)
        }
        .store(in: &cancellables)

        browserManager.$downloadTaskState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.downloadProgressView.setProgress(state.progress, status: state.status)
            }
            .store(in: &cancellables)

        browserManager.$availableActionTypes.removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] availableTypes in
                self?.updateButtonsAvailability(with: availableTypes)
            }
            .store(in: &cancellables)

        browserManager.$activeActionTypes.removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] types in
                self?.updateButtons(activeTypes: types)
            }
            .store(in: &cancellables)

        browserManager.$isVideoMuted.removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isMuted in
                self?.updateVideoMuteButtonState(isMuted)
            }
            .store(in: &cancellables)
    }
}

// MARK: - Actions
private extension MediaBrowserViewController {
    @objc func singleTapRecognized() {
        browserManager.didSingleTap()
    }

    @IBAction func backButtonTouchedUpInside(_ sender: AnyObject) {
        browserManager.didTapBack()
    }

    @IBAction func topDeleteButtonTouchedUpInside(_ sender: AnyObject) {
        browserManager.didTapDelete()
    }

    @IBAction func topShareButtonTouchedUpInside(_ sender: UIView) {
        browserManager.didTapShare(srcView: sender)
    }

    @IBAction func topDownloadButtonTouchedUpInside(_ sender: AnyObject) {
        browserManager.didTapDownload()
    }

    @IBAction func topSoundButtonTouchedUpInside(_ sender: Any) {
        browserManager.didTapMute()
    }
}

// MARK: - Private Funcs
private extension MediaBrowserViewController {
    /// Init view elements.
    func initView() {
        downloadProgressView.delegate = self

        // Top Toolbar
        mediaTitleView.style = .light

        // Tap gesture for controls dismissal gesture recognition.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(singleTapRecognized))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
    }

    /// Toggles controls display.
    ///
    /// - Parameters:
    ///    - show: Display controls if `true`, hide them otherwise.
    func showControls(_ show: Bool) {
        topToolbarView.showFromEdge(.top, show: show)
    }

    /// Updates video mute button state in top toolbar.
    ///
    /// - Parameter isMuted: whether the video is muted
    func updateVideoMuteButtonState(_ isMuted: Bool) {
        topSoundButton.setImage(isMuted ? Asset.Gallery.Player.icSoundOff.image : Asset.Gallery.Player.icSoundOn.image,
                                for: .normal)
    }

    /// Updates tool bar buttons state according to available actions.
    ///
    /// - Parameter types: the available actions option set
    func updateButtonsAvailability(with types: GalleryActionType) {
        topShareButton.isHiddenInStackView = !browserManager.isAvailable(.share)
        topDownloadButton.isHiddenInStackView = !browserManager.isAvailable(.download)
        topSoundButton.isHiddenInStackView = !browserManager.isAvailable(.mute)
        topDeleteButton.isHiddenInStackView = !browserManager.isAvailable(.delete)
    }

    /// Updates tool bar action button state for a specific media.
    ///
    /// - Parameter media: the media to update the action state of
    func updateActionState(of media: GalleryMedia) {
        guard browserManager.isAvailable(.download) else { return }
        topDownloadButton.model = DownloadButtonModel(title: media.formattedSize,
                                                      state: browserManager.actionState(of: media))
    }

    /// Updates tool bar buttons according to active actions.
    ///
    /// - Parameter activeTypes: the active actions option set
    func updateButtons(activeTypes types: GalleryActionType) {
        // Disable buttons if corresponding action is already ongoing.
        topDeleteButton.isEnabled = !types.contains(.delete)
        topShareButton.isEnabled = !types.contains(.share)
    }
}

// MARK: - Gallery Loading View Delegate
extension MediaBrowserViewController: GalleryLoadingViewDelegate {
    func shouldStopProgress() {
        browserManager.cancelDownload()
    }
}

extension MediaBrowserViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let controlsTapDetected = touch.view?.superview is PhotoViewerCell
        || touch.view?.tag == Constants.controlsTapViewTag
        let controlsDismissalResetDetected = touch.view?.tag == Constants.autoHideControlResetViewTag

        if controlsDismissalResetDetected {
            // Auto-hide timer needs to be reset when an active action is detected in order to prevent
            // unwanted quick dismissals.
            // Current active action buttons are: play/pause and mute buttons.
            browserManager.showControls()
        } else if !controlsTapDetected {
            // General user interaction detected => disable autoHideControlsTimer for now.
            // Will be fired back if controls are manually hidden or when new media is displayed.
            browserManager.disableControlsAutohiding()
        }

        // Handle tap only if controls dismissal is detected.
        return controlsTapDetected
    }
}
