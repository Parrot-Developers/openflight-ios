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

/// Custom view for the cameraman mode in the bottom bar.
public final class CameramanModeView: UIView, NibOwnerLoadable {

    // MARK: - Outlets
    @IBOutlet private weak var stateView: BarButtonView! {
        didSet {
            stateView.backgroundColor = ColorName.whiteAlbescent.color
            stateView.currentMode.adjustsFontSizeToFitWidth = true
            stateView.currentMode.minimumScaleFactor = Style.minimumScaleFactor
        }
    }
    @IBOutlet private weak var stopView: StopView! {
        didSet {
            self.stopView.delegate = self
            self.stopView.customCornered(corners: [.topRight, .bottomRight],
                                         radius: Style.largeCornerRadius,
                                         backgroundColor: ColorName.errorColor.color,
                                         borderColor: .clear,
                                         borderWidth: Style.noBorderWidth)
        }
    }

    // MARK: - Private Properties
    private var viewModel: CameramanModeViewModel?

    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInitCameramanModeView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInitCameramanModeView()
    }
}

// MARK: - Private Funcs
private extension CameramanModeView {

    /// Basic init for the view.
    func commonInitCameramanModeView() {
        self.loadNibContent()
        self.setupViewModel()

        guard let currentState = self.viewModel?.state.value.currentState else { return }
        self.updateStackView(cameramanState: currentState)
        stopView.accessibilityIdentifier = "StopCameraman"
    }

    /// Setup all observers.
    func setupViewModel() {
        self.viewModel = CameramanModeViewModel()

        self.viewModel?.state.valueChanged = { [weak self] state in
            self?.updateStackView(cameramanState: state.currentState)
        }
    }

    /// Updates UI for the stackview.
    ///
    /// - Parameters:
    ///    - cameramanState: Cameraman state.
    func updateStackView(cameramanState: CameramanModeState) {
        stateView.model = buttonStateModel(for: cameramanState)
        stateView.backgroundColor = ColorName.whiteAlbescent.color
        stopView.isHidden = cameramanState != .tracking
        let corners: UIRectCorner = stopView.isHidden ? [.allCorners] : [.topLeft, .bottomLeft]
        stateView.customCornered(corners: corners, radius: Style.largeFitCornerRadius)
    }

    /// Returns a BarButtonState for a specific state.
    ///
    /// - Parameters:
    ///    - state: Cameraman state.
    /// - Returns: A BarButtonState.
    func buttonStateModel(for state: CameramanModeState) -> BarButtonState {
        return BottomBarButtonState(title: L10n.missionModeCameraman.uppercased(),
                                    subtext: state.title)
    }
}

// MARK: - StopViewDelegate
extension CameramanModeView: StopViewDelegate {
    public func didClickOnStop() {
        self.viewModel?.removeAllTargets()
    }
}
