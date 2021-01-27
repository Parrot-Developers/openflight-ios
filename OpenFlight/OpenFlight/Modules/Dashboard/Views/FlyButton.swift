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

/// View which manages fly button states.

final class FlyButton: UIControl, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var flyImageView: UIImageView!
    @IBOutlet private weak var flyLabel: UILabel!
    @IBOutlet private weak var globalView: UIView!
    @IBOutlet private weak var labelView: UIView!

    // MARK: - Private Properties
    private var droneStateViewModel: DroneStateViewModel<DeviceConnectionState>?

    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInitFlyButton()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInitFlyButton()
    }

    /// Changes fly label visibility when orientation changed.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        labelView.isHidden = !UIApplication.isLandscape
    }

    /// Updates fly button when the view is redraw.
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        updateFlyButton(state: droneStateViewModel?.state.value)
    }
}

// MARK: - Private Funcs
private extension FlyButton {
    /// Inits the view.
    func commonInitFlyButton() {
        self.loadNibContent()
        listenViewModel()
        globalView.cornerRadiusedWith(backgroundColor: ColorName.greyShark.color,
                                      radius: Style.largeCornerRadius)
        labelView.isHidden = !UIApplication.isLandscape
    }

    /// Observes drone state update.
    func listenViewModel() {
        droneStateViewModel = DroneStateViewModel(stateDidUpdate: { [weak self] state in
            self?.updateFlyButton(state: state)
        })
    }

    /// Updates the view according to drone state.
    ///
    /// - Parameters:
    ///     - state: current drone state
    func updateFlyButton(state: DeviceConnectionState?) {
        state?.isConnected() == true ? activateFlyAnimation() : deactivateFlyAnimation()
    }

    /// Activates fly animation.
    func activateFlyAnimation() {
        globalView.cornerRadiusedWith(backgroundColor: ColorName.greenSpring20.color,
                                      radius: Style.largeCornerRadius)
        // Stop current animation if one.
        flyImageView.stopAnimating()
        let flyAnimationImages: [UIImage] = Asset.Dashboard.Fly.allValues.map { $0.image }
        flyImageView.animationImages = flyAnimationImages
        flyImageView.animationDuration = Style.longAnimationDuration
        flyImageView.startAnimating()
        flyLabel.makeUp(with: .big, and: .greenSpring)
        flyLabel.text = L10n.dashboardStartButtonFly.capitalized
    }

    /// Deactivates fly animation.
    func deactivateFlyAnimation() {
        flyImageView.stopAnimating()
        flyLabel.makeUp(with: .large, and: .white)
        flyImageView.image = Asset.Common.Icons.icRightArrow.image
        flyLabel.text = L10n.dashboardStartButtonPiloting.capitalized
        globalView.cornerRadiusedWith(backgroundColor: ColorName.greyShark.color,
                                      radius: Style.largeCornerRadius)
    }
}
