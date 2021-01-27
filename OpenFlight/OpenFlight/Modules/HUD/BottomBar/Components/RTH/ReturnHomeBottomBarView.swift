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
import Reusable

/// Bottom bar widget for Return Home feature.

final class ReturnHomeBottomBarView: UIView, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var barButtonView: BarButtonView!
    @IBOutlet private weak var stopView: StopView!

    // MARK: - Private Properties
    private var viewModel: ReturnHomeBottomBarViewModel = ReturnHomeBottomBarViewModel()

    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInitReturnHomeBottomBarView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInitReturnHomeBottomBarView()
    }
}

// MARK: - Private Funcs
private extension ReturnHomeBottomBarView {
    /// Common init.
    func commonInitReturnHomeBottomBarView() {
        initView()
        initViewModel()
    }

    /// Inits the view.
    func initView() {
        self.loadNibContent()
        self.stopView.style = .bottomBar
        self.stopView.delegate = self
    }

    /// Inits the view model which is in charge of updating the view.
    func initViewModel() {
        viewModel.state.value.rthTypeDescription.valueChanged = { [weak self] _ in
            self?.updateView()
        }
        updateView()
    }

    /// Updates the view.
    func updateView() {
        barButtonView.model = BottomBarButtonState(title: L10n.settingsAdvancedCategoryRth.uppercased(),
                                                   subtext: viewModel.state.value.rthTypeDescription.value)
        self.barButtonView.currentMode.adjustsFontSizeToFitWidth = true
        self.barButtonView.currentMode.minimumScaleFactor = Style.minimumScaleFactor
    }
}

// MARK: - StopViewDelegate
extension ReturnHomeBottomBarView: StopViewDelegate {
    func didClickOnStop() {
        viewModel.stopReturnHome()
    }
}
