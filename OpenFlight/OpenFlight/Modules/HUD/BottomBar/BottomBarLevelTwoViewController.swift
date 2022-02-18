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

/// HUD Bottom bar level two view.
/// Can display level two views like segmented bars & graduated bars.

final class BottomBarLevelTwoViewController: UIViewController {
    // MARK: - Private Properties
    private var levelView: UIView?

    // MARK: - Override Properties
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
    }

    // MARK: - Internal Funcs
    /// Add segmented bar view.
    ///
    /// - Parameters:
    ///    - viewModel: model representing the contents
    func addSegmentedBar<T: BarButtonState>(viewModel: BarButtonViewModel<T>) {
        removeLevelView()
        let segmentedBarView = SegmentedBarView<T>()
        segmentedBarView.viewModel = viewModel
        view.addWithConstraints(subview: segmentedBarView)
        levelView = segmentedBarView
    }

    /// Add dynamic range segmented bar view.
    ///
    /// - Parameters:
    ///    - viewModel: model representing the contents
    func addDynamicRangeBar(viewModel: DynamicRangeBarViewModel?) {
        removeLevelView()
        let dynamicRangeBarView = DynamicRangeBarView()
        dynamicRangeBarView.viewModel = viewModel
        view.addWithConstraints(subview: dynamicRangeBarView)
        levelView = dynamicRangeBarView
    }

    /// Add EV compensation bar view.
    func addEvCompensationBar() {
        removeLevelView()
        let evCompensationBarView = ImagingBarEvCompensationBarView()
        view.addWithConstraints(subview: evCompensationBarView)
        levelView = evCompensationBarView
    }

    /// Add automatable bar view.
    func addAutomatableRulerBar<T: AutomatableRulerImagingBarState>(viewModel: AutomatableBarButtonViewModel<T>?) {
        guard let viewModel = viewModel else {
            return
        }
        removeLevelView()
        let automatableBarView = ImagingBarAutomatableRulerBarView<T>()
        automatableBarView.setup(viewModel: viewModel)
        view.addWithConstraints(subview: automatableBarView)
        levelView = automatableBarView
    }

    /// Add white balance bar view.
    func addWhiteBalanceBar(viewModel: ImagingBarWhiteBalanceViewModel?) {
        removeLevelView()
        let whiteBalanceBarView = ImagingBarWhiteBalanceBarView()
        whiteBalanceBarView.viewModel = viewModel
        view.addWithConstraints(subview: whiteBalanceBarView)
        levelView = whiteBalanceBarView
    }

    /// Check if current segmented bar view is of the same type as given view model type.
    ///
    /// - Parameters:
    ///    - viewModel: the view model
    func isSameBarDisplayed<T: BarButtonState>(viewModel: BarButtonViewModel<T>) -> Bool {
        return (levelView as? BarItemModeDisplayer)?.barId == viewModel.barId
    }

    /// Remove active view.
    func removeLevelView() {
        levelView?.removeFromSuperview()
        levelView = nil
    }
}
// MARK: - Private Funcs
private extension BottomBarLevelTwoViewController {
    /// Initializes interfaces.
    func initUI() {
        view.translatesAutoresizingMaskIntoConstraints = false
        // Sets up corners
        view.customCornered(corners: [.allCorners], radius: Style.fitLargeCornerRadius)
    }
}
