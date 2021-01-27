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

// MARK: - Protocols
/// Protocol describing tilt slider view commands.
protocol TiltSliderViewDelegate: class {
    /// Called when gimbal pitch velocity should be updated.
    ///
    /// - Parameters:
    ///    - velocity: new velocity to apply
    func setPitchVelocity(_ velocity: Double)
    /// Called when gimbal pitch should be reset to default value.
    func resetPitch()
    /// Called when user starts interacting with slider.
    func didStartInteracting()
    /// Called when user stops interacting with slider.
    func didStopInteracting()
}

/// View displaying the deployed tilt controller.

final class TiltSliderView: UIView, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var mainView: UIView!
    @IBOutlet private weak var handleView: UIView!
    @IBOutlet private weak var topArrowView: SimpleArrowView!
    @IBOutlet private weak var bottomArrowView: SimpleArrowView!
    @IBOutlet private weak var tiltIndicatorView: UIView!

    @IBOutlet private weak var handleViewYConstraint: NSLayoutConstraint!
    @IBOutlet private weak var tiltIndicatorViewYConstraint: NSLayoutConstraint!
    @IBOutlet private weak var progressViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var progressViewBottomConstraint: NSLayoutConstraint!

    // MARK: - Internal Properties
    weak var tiltState: GimbalTiltState? {
        didSet {
            setTiltIndicatorPosition()
        }
    }
    weak var delegate: TiltSliderViewDelegate?

    // MARK: - Private Properties
    private var longPressGestureRecognizer: UILongPressGestureRecognizer!
    private var doubleTapGestureRecognizer: UITapGestureRecognizer!

    // MARK: - Private Enums
    private enum Constants {
        static let tiltIndicatorDelta: CGFloat = 5.0
        static let defaultHandlePosition: CGFloat = 0.0
        static let defaultVelocity: Double = 0.0
        static let arrowActiveAlpha: CGFloat = 1.0
        static let arrowInactiveAlpha: CGFloat = 0.5
    }

    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInitTiltView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInitTiltView()
    }
}

// MARK: - Private Funcs
private extension TiltSliderView {
    /// Sets up UI and gesture recognizers.
    func commonInitTiltView() {
        self.loadNibContent()
        handleView.roundCornered()
        mainView.roundCornered()
        tiltIndicatorView.roundCornered()
        bottomArrowView.orientation = .bottom

        setLongPressGesture()
        setDoubleTapGesture()
    }

    /// Sets up long press gesture recognizer.
    func setLongPressGesture() {
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self,
                                                                  action: #selector(onLongPress))
        longPressGestureRecognizer.minimumPressDuration = 0
        handleView.addGestureRecognizer(longPressGestureRecognizer)
    }

    /// Sets up double tap gesture recognizer.
    func setDoubleTapGesture() {
        doubleTapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                            action: #selector(onDoubleTap))
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        longPressGestureRecognizer.require(toFail: doubleTapGestureRecognizer)
        handleView.addGestureRecognizer(doubleTapGestureRecognizer)
    }

    /// Called when a long press on handle view occurs.
    @objc func onLongPress(sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .began:
            delegate?.didStartInteracting()
            fallthrough
        case .possible, .changed:
            let pointY = sender.location(in: self.mainView).y
            let clampedY = (0...mainView.frame.height).clamp(pointY)
            let constraintValue = mainView.frame.height / 2 - clampedY
            setHandlePosition(at: constraintValue)
            let velocity = Double(constraintValue / (mainView.frame.height / 2))
            delegate?.setPitchVelocity(velocity)
        case .ended, .cancelled, .failed:
            setHandlePosition(at: Constants.defaultHandlePosition)
            delegate?.setPitchVelocity(Constants.defaultVelocity)
            delegate?.didStopInteracting()
        @unknown default:
            break
        }
    }

    /// Called when a double tap on handle view occurs.
    @objc func onDoubleTap(sender: UITapGestureRecognizer) {
        delegate?.resetPitch()
    }

    /// Moves handle view to given position.
    func setHandlePosition(at value: CGFloat) {
        handleViewYConstraint.constant = value
        bottomArrowView.alpha = value < 0 ? Constants.arrowActiveAlpha : Constants.arrowInactiveAlpha
        topArrowView.alpha = value > 0 ? Constants.arrowActiveAlpha : Constants.arrowInactiveAlpha
    }

    /// Moves tilt indicator to given position.
    func setTiltIndicatorPosition() {
        guard let currentValue = tiltState?.current,
            let range = tiltState?.range,
            range.upperBound != 0
            else {
                return
        }
        let halfHeight = mainView.frame.height / 2 - Constants.tiltIndicatorDelta
        let position = CGFloat(currentValue) * halfHeight / CGFloat(range.upperBound)
        tiltIndicatorViewYConstraint.constant = position

        if position > 0 {
            progressViewTopConstraint.constant = position + Constants.tiltIndicatorDelta
            progressViewBottomConstraint.constant = 0
        } else if position < 0 {
            progressViewTopConstraint.constant = 0
            progressViewBottomConstraint.constant = position - Constants.tiltIndicatorDelta
        } else {
            progressViewTopConstraint.constant = 0
            progressViewBottomConstraint.constant = 0
        }
    }
}
