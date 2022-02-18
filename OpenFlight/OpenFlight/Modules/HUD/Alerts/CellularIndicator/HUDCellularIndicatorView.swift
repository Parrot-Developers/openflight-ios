//    Copyright (C) 2021 Parrot Drones SAS
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

/// View which displays a 4G indicator.
final class HUDCellularIndicatorView: UIView, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var indicatorImageView: UIImageView!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var loaderImageView: UIImageView!

    // MARK: - Private Properties
    private var currentState: HUDCellularState = .noState

    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.commonInitHUDCellularIndicatorView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.commonInitHUDCellularIndicatorView()
    }

    // MARK: - Internal Funcs
    func configure(state: HUDCellularState) {
        self.currentState = state
        updateView()
        switch state {
        case .cellularConnected:
            updateConnectedView()
        case .cellularConnecting:
            updateConnectingView()
        case .noState:
            break
        }
    }
}

// MARK: - Private Funcs
private extension HUDCellularIndicatorView {
    /// Common init.
    func commonInitHUDCellularIndicatorView() {
        self.loadNibContent()

        descriptionLabel.makeUp(with: .large)
    }

    /// Updates the view according to the current state.
    func updateView() {
        descriptionLabel.text = currentState.description
        descriptionLabel.textColor = currentState.descriptionColor.color
        indicatorImageView.image = currentState.image
    }

    /// Updates connected view.
    func updateConnectedView() {
        loaderImageView.stopRotate()
        loaderImageView.isHidden = true
    }

    /// Updates connected view.
    func updateConnectingView() {
        loaderImageView.isHidden = false
        loaderImageView.startRotate()
    }
}
