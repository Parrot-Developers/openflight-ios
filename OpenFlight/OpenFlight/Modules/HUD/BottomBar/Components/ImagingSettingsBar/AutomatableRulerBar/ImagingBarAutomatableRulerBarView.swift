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

/// View that displays a `CenteredRulerBarView` with shutter speed or camera iso.

final class ImagingBarAutomatableRulerBarView<T: AutomatableRulerImagingBarState>: UIView, NibOwnerLoadable, NibLoadable, BarItemModeDisplayer {
    // MARK: - Outlets
    @IBOutlet private weak var centeredRulerBarContainer: UIView!
    @IBOutlet private weak var autoButton: UIButton!

    // MARK: - Internal Properties
    static var nib: UINib {
        return UINib(nibName: "ImagingBarAutomatableRulerBarView", bundle: Bundle.currentBundle(for: self))
    }
    var modeKey: String? {
        return self.viewModel?.state.value.mode?.key
    }

    // MARK: - Private Properties
    private var viewModel: AutomatableBarButtonViewModel<T>?
    private var centeredRulerBarView: CenteredRulerBarView<T>?

    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInitImagingBarShutterSpeedBarView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInitImagingBarShutterSpeedBarView()
    }

    // MARK: - Internal Funcs
    /// Setup bar view with view model.
    ///
    /// - Parameters:
    ///     - viewModel: Automatable view model.
    func setup(viewModel: AutomatableBarButtonViewModel<T>) {
        self.viewModel = viewModel.copy()
        self.viewModel?.state.value.exposureSettingsMode.valueChanged = { [weak self] _ in
            guard let isAutomatic = self?.viewModel?.state.value.isAutomatic else {
                return
            }
            self?.updateAutomaticMode(isAutomatic: isAutomatic)
        }
        addRulerBar()
    }

    // MARK: - Actions
    @IBAction private func autoButtonTouchedUpInside(_ sender: Any) {
        viewModel?.toggleAutomaticMode()
    }
}

// MARK: - Private Funcs
private extension ImagingBarAutomatableRulerBarView {
    /// Common init.
    func commonInitImagingBarShutterSpeedBarView() {
        self.loadNibContent()
        self.addBlurEffect()
    }

    /// Add ruler displaying current mode values.
    func addRulerBar() {
        removeRulerBar()
        let centeredRulerBarView = CenteredRulerBarView<T>()
        centeredRulerBarView.viewModel = viewModel
        centeredRulerBarContainer.addWithConstraints(subview: centeredRulerBarView)
        self.centeredRulerBarView = centeredRulerBarView
    }

    /// Remove ruler.
    func removeRulerBar() {
        centeredRulerBarView?.removeFromSuperview()
        centeredRulerBarView = nil
    }

    /// Update UI with given automatic setting.
    ///
    /// - Parameters:
    ///    - isAutomatic: boolean describing if setting is monitored automatically.
    func updateAutomaticMode(isAutomatic: Bool) {
        autoButton.cornerRadiusedWith(backgroundColor: isAutomatic ? ColorName.greenSpring20.color : .clear,
                                      borderColor: isAutomatic ? ColorName.greenSpring.color: .clear,
                                      radius: Style.largeCornerRadius,
                                      borderWidth: Style.largeBorderWidth)
        centeredRulerBarView?.isAutomatic = isAutomatic
    }
}
