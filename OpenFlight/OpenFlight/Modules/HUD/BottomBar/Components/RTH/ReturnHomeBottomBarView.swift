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
import Reusable
import Combine

/// Bottom bar widget for Return Home feature.
final class ReturnHomeBottomBarView: UIView, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var barButtonView: BarButtonView!
    @IBOutlet private weak var stopView: StopView!

    // MARK: - Private Properties
    private var viewModel: ReturnHomeBottomBarViewModel = ReturnHomeBottomBarViewModel()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
}

// MARK: - Private Funcs
private extension ReturnHomeBottomBarView {
    /// Common init.
    func commonInit() {
        initView()
        bindViewModel()
        setupUI()
    }
    /// Inits the view.
    func initView() {
        loadNibContent()
        stopView.style = .bottomBar
        stopView.delegate = self
    }
    /// Setup view
    func setupUI() {
        barButtonView.currentMode.adjustsFontSizeToFitWidth = true
        barButtonView.currentMode.minimumScaleFactor = Style.minimumScaleFactor
        barButtonView.customCornered(corners: [.topRight, .bottomRight], radius: Style.noBorderWidth)
        barButtonView.customCornered(corners: [.topLeft, .bottomLeft], radius: Style.largeFitCornerRadius)
        barButtonView.backgroundColor = ColorName.greyLightReturn.color
    }
    /// bind the viewmodel
    func bindViewModel() {
        viewModel.$rthTarget
            .sink { [unowned self] rthValue in
                // update model of returnHomeBottomBarView
                barButtonView.model = BottomBarButtonState(
                    title: L10n.settingsAdvancedCategoryRth.uppercased(),
                    subtext: rthValue)
                setupUI()
            }
            .store(in: &cancellables)
    }
}

// MARK: - StopViewDelegate
extension ReturnHomeBottomBarView: StopViewDelegate {
    func didClickOnStop() {
        viewModel.stopReturnHome()
    }
}
