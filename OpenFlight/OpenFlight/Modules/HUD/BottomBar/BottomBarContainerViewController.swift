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
/// Protocol used to show and hide bottom bar levels.
protocol BottomBarContainerDelegate: AnyObject {
    /// Opens level one level and displays appropriate bar given viewModel.
    func showLevelOne<T: BarButtonState>(viewModel: BarButtonViewModel<T>)
    /// Closes level one with animation.
    func hideLevelOne<T: BarButtonState>(viewModel: BarButtonViewModel<T>)
    /// Opens level two level and displays appropriate bar given viewModel.
    func showLevelTwo<T: BarButtonState>(viewModel: BarButtonViewModel<T>)
    /// Closes level two with animation.
    func hideLevelTwo<T: BarButtonState>(viewModel: BarButtonViewModel<T>)
}

/// View controller that manages bottom bar levels.

final class BottomBarContainerViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet private weak var containerStackView: MainContainerStackView!
    @IBOutlet private weak var levelOneContainerView: UIView!
    @IBOutlet private weak var levelTwoContainerView: UIView!

    // MARK: - Internal Properties
    weak var coordinator: HUDCoordinator?
    weak var bottomBarService: HudBottomBarService?

    // MARK: - Private Properties
    private var levelOneViewController: BottomBarLevelViewController!
    private var levelTwoViewController: BottomBarLevelTwoViewController!
    private let panoramaModeViewModel = PanoramaModeViewModel()
    private var cancellables = Set<AnyCancellable>()

    private var isPanoramaInProgress: Bool = false {
        didSet {
            containerStackView.showFromEdge(.bottom, show: !isPanoramaInProgress, fadeFrom: 1)
        }
    }
    private var bottomBarMode: BottomBarMode = .preset {
        didSet {
            if bottomBarMode != oldValue {
                bottomBarService?.set(mode: bottomBarMode)
                NotificationCenter.default.post(name: .bottomBarModeDidChange,
                                                object: self,
                                                userInfo: [BottomBarMode.notificationKey: bottomBarMode])
            }
        }
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        view.translatesAutoresizingMaskIntoConstraints = false
        listenPanoramaMode()
        listenToMissionPanel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Bottom bar snaps to safe area (if available) or main padding guide.
        containerStackView.hasMinLeftPadding = true
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let bottomBarViewControler = segue.destination as? BottomBarViewController {
            bottomBarViewControler.delegate = self
            bottomBarViewControler.coordinator = coordinator
            bottomBarViewControler.bottomBarService = bottomBarService
        } else if let levelOneViewController = segue.destination as? BottomBarLevelViewController {
            self.levelOneViewController = levelOneViewController
        } else if let levelTwoViewController = segue.destination as? BottomBarLevelTwoViewController {
            self.levelTwoViewController = levelTwoViewController
        }
    }
}

// MARK: - Private Funcs
private extension BottomBarContainerViewController {
    /// Listens to missions panel display state changes.
    func listenToMissionPanel() {
        guard let coordinator = coordinator else { return }
        coordinator.showMissionLauncherPublisher.sink { [unowned self] isShown in
            containerStackView.screenBorders = isShown ? [.bottom] : [.left, .bottom]
        }
        .store(in: &cancellables)
    }

    /// Starts watcher for panorama mode.
    func listenPanoramaMode() {
        panoramaModeViewModel.$status
            .sink { [unowned self] status in
                self.updatePanoramaBarState(status: status)
            }
            .store(in: &cancellables)
    }

    func updatePanoramaBarState(status: PanoramaModeViewModel.PanoramaStatus) {
        guard panoramaModeViewModel.status != .success else {
            // Delay progress bar success status update, as last panorama notifications may arrive too fast to be distinguished.
            // (e.g. 20 last percents of animation + switch to idle state may occur in a few milliseconds.)
            DispatchQueue.main.asyncAfter(deadline: .now() + Style.mediumAnimationDuration) {
                self.isPanoramaInProgress = status == .inProgress
            }
            return
        }

        isPanoramaInProgress = status != .idle
    }

    /// Hides the level two bar.
    func hideLevelTwo() {
        guard levelTwoContainerView.isHidden == false else {
            return
        }

        levelTwoContainerView.animateIsHidden(true, duration: Style.fastAnimationDuration) { _ in
            self.levelTwoViewController.removeLevelView()
        }
    }
}

// MARK: - BottomBarContainerDelegate
extension BottomBarContainerViewController: BottomBarContainerDelegate {

    func showLevelOne<T: BarButtonState>(viewModel: BarButtonViewModel<T>) {
        guard bottomBarMode != .levelOneOpened || !levelOneViewController.isSameBarDisplayed(viewModel: viewModel) else { return }

        bottomBarMode = .levelOneOpened
        switch viewModel {
        case is CameraWidgetViewModel:
            levelOneViewController.addImagingSettingsBar(delegate: self,
                                                         bottomBarService: bottomBarService)
        default:
            levelOneViewController.addSegmentedBar(viewModel: viewModel)
        }

        levelOneContainerView.animateIsHidden(false, duration: Style.fastAnimationDuration)

        // Autohide level two when a new level one bar is displayed.
        hideLevelTwo()
    }

    func hideLevelOne<T: BarButtonState>(viewModel: BarButtonViewModel<T>) {
        guard levelOneContainerView.isHidden == false
                && levelOneViewController.isSameBarDisplayed(viewModel: viewModel) else {
            return
        }

        levelOneContainerView.animateIsHidden(true, duration: Style.fastAnimationDuration) { _ in
            switch viewModel {
            case is CameraWidgetViewModel:
                self.levelOneViewController.removeImagingSettingsBar()
            default:
                self.levelOneViewController.removeLevelView()
            }
            self.bottomBarMode = .closed
        }

        // Autohide level two when level one is hidden.
        hideLevelTwo()
    }

    func showLevelTwo<T: BarButtonState>(viewModel: BarButtonViewModel<T>) {
        bottomBarMode = .levelTwoOpened
        switch viewModel {
        case is DynamicRangeBarViewModel:
            levelTwoViewController.addDynamicRangeBar(viewModel: viewModel as? DynamicRangeBarViewModel)
        case is ImagingBarEvCompensationViewModel:
            levelTwoViewController.addEvCompensationBar()
        case is AutomatableBarButtonViewModel<AutomatableRulerImagingBarState>:
            levelTwoViewController.addAutomatableRulerBar(viewModel: viewModel as? AutomatableBarButtonViewModel<AutomatableRulerImagingBarState>)
        case is ImagingBarWhiteBalanceViewModel:
            levelTwoViewController.addWhiteBalanceBar(viewModel: viewModel as? ImagingBarWhiteBalanceViewModel)
        default:
            levelTwoViewController.addSegmentedBar(viewModel: viewModel)
        }

        levelTwoContainerView.animateIsHidden(false, duration: Style.fastAnimationDuration)
    }

    func hideLevelTwo<T: BarButtonState>(viewModel: BarButtonViewModel<T>) {
        guard levelTwoViewController.isSameBarDisplayed(viewModel: viewModel) else {
            return
        }
        bottomBarMode = .levelOneOpened
        hideLevelTwo()
    }
}
