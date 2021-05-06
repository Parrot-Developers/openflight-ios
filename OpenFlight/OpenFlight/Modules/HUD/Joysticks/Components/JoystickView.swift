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

/// Custom view which display a joystick.

final class JoystickView: UIView, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var backgroundJoystickView: UIView!
    @IBOutlet private weak var backgroundImageView: UIImageView!
    @IBOutlet private weak var foregroundStickView: UIImageView!
    @IBOutlet private weak var touchZoneView: CustomTouchView!

    // MARK: - Private Properties
    var joystickType: JoystickType = JoystickType.gazYaw {
        didSet {
            backgroundImageView?.image = joystickType.backgroundImage
        }
    }
    let pilotingViewModel: JoysticksPilotingViewModel = JoysticksPilotingViewModel()

    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInitJoystickView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInitJoystickView()
    }
}

// MARK: - Private Funcs
private extension JoystickView {
    /// Common init.
    func commonInitJoystickView() {
        self.loadNibContent()
        self.touchZoneView.delegate = self
    }

    /// Update stick view point location.
    ///
    /// - Parameters:
    ///     - touchedPoint: point returned by touch move.
    ///     - backgroundView: background of the joystick
    ///     - foregroundView: foregroundView of the joystick
    /// - Returns: new point location
    func updatePoint(touchedPoint: CGPoint, backgroundView: UIView, foregroundView: UIView) -> CGPoint {
        // Current delta in x and y.
        let diffX: Float = Float(touchedPoint.x - backgroundView.center.x)
        let diffY: Float = Float(touchedPoint.y - backgroundView.center.y)
        let distance: Float = (diffX * diffX + diffY * diffY).squareRoot()
        // Convert to radians.
        let angle: Float = atan2(diffY, diffX)

        let foregroundRadius = foregroundView.bounds.width / 2
        let wRadius: Float = Float(backgroundView.frame.size.width - foregroundRadius) / 2.0
        let hRadius: Float = Float(backgroundView.frame.size.height - foregroundRadius) / 2.0

        let maxX = wRadius * cosf(angle)
        let maxY = hRadius * sinf(angle)
        let maxDistance = sqrtf(maxX * maxX + maxY * maxY)

        let returnedX = distance > maxDistance ? backgroundView.center.x + CGFloat(maxX) : touchedPoint.x
        let returnedY = distance > maxDistance ? backgroundView.center.y + CGFloat(maxY) : touchedPoint.y
        let returnPoint = CGPoint(x: returnedX, y: returnedY)
        return returnPoint
    }
}

// MARK: - CustomTouchViewDelegate
extension JoystickView: CustomTouchViewDelegate {
    func touchBegan(at point: CGPoint) {
        backgroundJoystickView.center = point
        foregroundStickView.center = point
    }

    func touchMoved(to point: CGPoint) {
        self.foregroundStickView.center = self.updatePoint(touchedPoint: point,
                                                           backgroundView: backgroundJoystickView,
                                                           foregroundView: foregroundStickView)
        pilotingViewModel.newMotorConsignFrom(foregroundView: foregroundStickView,
                                              backgroundView: backgroundJoystickView,
                                              type: joystickType)
    }

    func touchEnded(at point: CGPoint) {
        self.backgroundJoystickView.center = self.touchZoneView.realCenter
        self.foregroundStickView.center = self.touchZoneView.realCenter
        pilotingViewModel.releaseJoystick(type: joystickType)
    }
}
