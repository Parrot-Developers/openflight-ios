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

/// View controller that manages action widgets.
final class ActionWidgetContainerViewController: UIViewController {
    /// The view model.
    var viewModel: ActionWidgetViewModel!

    // MARK: Outlets
    @IBOutlet private weak var returnHomeView: ReturnHomeBottomBarView!
    @IBOutlet private weak var panoramaProgressBar: PanoramaProgressBarView!
    @IBOutlet private weak var missionWidgetsContainerView: UIView!

    // MARK: Private Properties
    private var cancellables = Set<AnyCancellable>()
    private enum Constants {
        static let missionWidgetsTag = 1
        static let hiddenWidgetScale: CGFloat = 0.3
    }

    // MARK: - Init

    /// Constructor.
    ///
    /// - Parameter viewModel: the view model
    /// - Returns: the view controller
    static func instantiate(viewModel: ActionWidgetViewModel) -> ActionWidgetContainerViewController {
        let viewController = StoryboardScene.ActionWidgetContainer.initialScene.instantiate()
        viewController.viewModel = viewModel
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        observeViewModel()
    }
}

// MARK: - Private Funcs
private extension ActionWidgetContainerViewController {

    /// Observes the view model.
    private func observeViewModel() {
        /// RTH widget.
        viewModel.$shouldShowRthWidget.sink { [weak self] shouldShow in
            self?.updateRthWidget(show: shouldShow)
        }
        .store(in: &cancellables)

        /// Panorama widget.
        viewModel.$shouldShowPanoramaWidget.sink { [weak self] shouldShow in
            self?.updatePanoramaWidget(show: shouldShow)
        }
        .store(in: &cancellables)

        /// Mission widgets.
        viewModel.$missionWidgets.sink { [weak self] widgets in
            self?.updateMissionWidgets(with: widgets)
        }
        .store(in: &cancellables)

        /// Global widgets state.
        viewModel.$isActionWidgetShown.sink { isShown in
            if isShown {
                Services.hub.ui.uiComponentsDisplayReporter.actionWidgetIsShown()
            } else {
                Services.hub.ui.uiComponentsDisplayReporter.actionWidgetIsHidden()
            }
        }
        .store(in: &cancellables)
    }

    /// Updates the RTH widget display state.
    ///
    /// - Parameter show: whether the widget needs to be shown
    func updateRthWidget(show: Bool) {
        returnHomeView.showFromEdge(.bottom,
                                    offset: Layout.mainBottomMargin(isRegularSizeClass),
                                    show: show,
                                    fadeFrom: 1)
        if show {
            // RTH widget is displayed over mission widgets => Need to hide current mission widgets container.
            missionWidgetsContainerView.scaleOut(scale: Constants.hiddenWidgetScale, remove: false)
        } else {
            // RTH widget is removed => Bring current mission widgets back.
            missionWidgetsContainerView.scaleIn()
        }
    }

    /// Updates the panorama widget display state.
    ///
    /// - Parameter show: whether the widget needs to be shown
    func updatePanoramaWidget(show: Bool) {
        panoramaProgressBar.showFromEdge(.bottom, show: show, fadeFrom: 1)
    }

    /// Updates mission widgets display state.
    ///
    /// - Parameter widgets: the current mission widgets constructor
    func updateMissionWidgets(with widgets: (() -> [UIView])?) {
        // Current design only supports 1 single action widget per mission.
        let currentWidget = missionWidgetsContainerView.subviews.filter { $0.tag == Constants.missionWidgetsTag }.first

        // No new mission widget to show => Dismiss current widget with a bottom sliding animation.
        guard let newWidgets = widgets, !newWidgets().isEmpty else {
            currentWidget?.showFromEdge(.bottom,
                                        offset: Layout.mainBottomMargin(self.isRegularSizeClass),
                                        show: false) {
                currentWidget?.removeFromSuperview()
            }
            return
        }

        // Dismiss current widget with a scale out animation and remove it from container stack.
        currentWidget?.scaleOut(scale: Constants.hiddenWidgetScale, remove: true)

        // Add new mission widget.
        guard let newWidget = newWidgets().first else { return }
        newWidget.tag = Constants.missionWidgetsTag
        missionWidgetsContainerView.addAndSlideIn(newWidget)
        view.layoutIfNeeded()
    }
}

// MARK: - Private Animations Convenience Functions

private extension UIView {
    /// Resets view transform (used to bring back a scaled down widget).
    func scaleIn() {
        UIView.animate(withDuration: Style.shortAnimationDuration, delay: 0, options: .curveEaseOut) {
            self.alpha = 1
            self.transform = .identity
        }
    }

    /// Scales out view and remove from superview if needed.
    ///
    /// - Parameters:
    ///    - scale: the scaling factor
    ///    - remove: whether the view needs to be removed from superview once the animation is completed
    func scaleOut(scale: CGFloat, remove: Bool) {
        UIView.animate(withDuration: Style.shortAnimationDuration, delay: 0, options: .curveEaseOut) {
            self.alpha = 0
            self.transform = .init(scaleX: scale, y: scale).concatenating(.init(translationX: 0, y: -Layout.buttonIntrinsicHeight(self.isRegularSizeClass) / 2))
        } completion: { _ in
            if remove {
                self.removeFromSuperview()
            }
        }
    }

    /// Adds a view with a sliding animation.
    ///
    /// - Parameter view: the view to add
    func addAndSlideIn(_ view: UIView) {
        addWithConstraints(subview: view)
        view.transform = .init(translationX: 0, y: Layout.mainBottomMargin(isRegularSizeClass) + Layout.buttonIntrinsicHeight(isRegularSizeClass))
        UIView.animate(withDuration: Style.shortAnimationDuration, delay: 0, options: .curveEaseOut) {
            view.transform = .identity
        }
    }
}
