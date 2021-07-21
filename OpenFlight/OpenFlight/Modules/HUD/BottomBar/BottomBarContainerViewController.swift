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
    @IBOutlet private weak var bottomBarContainerView: UIView!
    @IBOutlet private weak var levelOneContainerView: UIView!
    @IBOutlet private weak var levelTwoContainerView: UIView!
    @IBOutlet private weak var panoramaProgressView: PanoramaProgressBarView!

    // MARK: - Internal Properties
    weak var bottomBarDelegate: BottomBarViewControllerDelegate?
    weak var coordinator: HUDCoordinator?

    // MARK: - Private Properties
    private var levelOneViewController: BottomBarLevelViewController!
    private var levelTwoViewController: BottomBarLevelTwoViewController!
    private let panoramaModeViewModel = PanoramaModeViewModel()
    private var isPanoramaInProgress: Bool = false {
        didSet {
            self.bottomBarContainerView.isHidden = isPanoramaInProgress
            self.panoramaProgressView.isHidden = !isPanoramaInProgress
        }
    }
    private var bottomBarMode: BottomBarMode = .preset {
        didSet {
            if bottomBarMode != oldValue {
                NotificationCenter.default.post(name: .bottomBarModeDidChange,
                                                object: self,
                                                userInfo: [BottomBarMode.notificationKey: bottomBarMode])
            }
        }
    }

    // MARK: - Private Enums
    private enum Constants {
        static let animationDuration: TimeInterval = 0.1
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        view.translatesAutoresizingMaskIntoConstraints = false
        self.listenPanoramaMode()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let bottomBarViewControler = segue.destination as? BottomBarViewController {
            bottomBarViewControler.delegate = self
            bottomBarViewControler.coordinator = coordinator
            bottomBarViewControler.bottomBarDelegate = bottomBarDelegate
        } else if let levelOneViewController = segue.destination as? BottomBarLevelViewController {
            self.levelOneViewController = levelOneViewController
            self.levelOneViewController.bottomBarDelegate = bottomBarDelegate
        } else if let levelTwoViewController = segue.destination as? BottomBarLevelTwoViewController {
            self.levelTwoViewController = levelTwoViewController
        }
    }
}

// MARK: - Private Funcs
private extension BottomBarContainerViewController {

    /// Starts watcher for panorama mode.
    func listenPanoramaMode() {
        self.panoramaModeViewModel.state.valueChanged = { [weak self] state in
            guard let strongSelf = self,
                  strongSelf.isPanoramaInProgress != state.inProgress else {
                return
            }
            strongSelf.isPanoramaInProgress = state.inProgress
        }
    }

    /// Hides the level two bar.
    func hideLevelTwo() {
        guard levelTwoContainerView.isHidden == false else {
            return
        }
        UIView.animate(withDuration: Constants.animationDuration,
                       animations: {
                        self.levelTwoContainerView.isHidden = true
                        self.levelTwoContainerView.alpha = 0.0
                       }, completion: { _ in
                        self.levelTwoViewController.removeLevelView()
                       })
    }
}

// MARK: - BottomBarContainerDelegate
extension BottomBarContainerViewController: BottomBarContainerDelegate {

    func showLevelOne<T: BarButtonState>(viewModel: BarButtonViewModel<T>) {
        bottomBarMode = .levelOneOpened
        switch viewModel {
        case is CameraWidgetViewModel:
            levelOneViewController.addImagingSettingsBar(delegate: self)
            bottomBarDelegate?.showAETargetZone()
        default:
            levelOneViewController.addSegmentedBar(viewModel: viewModel)
        }
        self.levelOneContainerView.alpha = 0.0
        UIView.animate(withDuration: Constants.animationDuration,
                       animations: {
                        self.levelOneContainerView.isHidden = false
                        self.levelOneContainerView.alpha = 1.0
                       })

        // Autohide level two when a new level one bar is displayed.
        hideLevelTwo()
    }

    func hideLevelOne<T: BarButtonState>(viewModel: BarButtonViewModel<T>) {
        guard levelOneContainerView.isHidden == false
                && levelOneViewController.isSameBarDisplayed(viewModel: viewModel) else {
            return
        }

        UIView.animate(withDuration: Constants.animationDuration,
                       animations: {
                        self.levelOneContainerView.isHidden = true
                        self.levelOneContainerView.alpha = 0.0
                       }, completion: { _ in
                        switch viewModel {
                        case is CameraWidgetViewModel:
                            self.levelOneViewController.removeImagingSettingsBar()
                            self.bottomBarDelegate?.hideAETargetZone()
                        default:
                            self.levelOneViewController.removeLevelView()
                        }
                        self.bottomBarMode = .closed
                       })
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
        self.levelTwoContainerView.alpha = 0.0
        UIView.animate(withDuration: Constants.animationDuration,
                       animations: {
                        self.levelTwoContainerView.isHidden = false
                        self.levelTwoContainerView.alpha = 1.0
                       })
    }

    func hideLevelTwo<T: BarButtonState>(viewModel: BarButtonViewModel<T>) {
        guard levelTwoViewController.isSameBarDisplayed(viewModel: viewModel) else {
            return
        }
        bottomBarMode = .levelOneOpened
        hideLevelTwo()
    }
}
