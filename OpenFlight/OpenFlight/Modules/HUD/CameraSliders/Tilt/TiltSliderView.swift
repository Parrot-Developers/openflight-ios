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

    // MARK: - Private Properties
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var doubleTapGestureRecognizer: UITapGestureRecognizer!
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Internal Properties
    var viewModel: GimbalTiltSliderViewModel! {
        didSet {
            viewModel.tiltValue
                .combineLatest(viewModel.tiltUpperBound)
                .sink { [unowned self] (value, upperBound) in
                    setTiltIndicatorPosition(currentValue: value, upperBound: upperBound)
                }
                .store(in: &cancellables)
        }
    }

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

        setPanGesture()
        setDoubleTapGesture()
    }

    /// Sets up pan gesture recognizer.
    func setPanGesture() {
        panGestureRecognizer = UIPanGestureRecognizer(target: self,
                                                      action: #selector(onPan))
        handleView.addGestureRecognizer(panGestureRecognizer)
    }

    /// Sets up double tap gesture recognizer.
    func setDoubleTapGesture() {
        doubleTapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                            action: #selector(onDoubleTap))
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        handleView.addGestureRecognizer(doubleTapGestureRecognizer)
    }

    /// Called when a pan gesture on handle view occurs.
    @objc func onPan(sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            viewModel.onStartInteraction()
            fallthrough
        case .possible, .changed:
            let pointY = sender.location(in: self.mainView).y
            let clampedY = (0...mainView.frame.height).clamp(pointY)
            let constraintValue = mainView.frame.height / 2 - clampedY
            setHandlePosition(at: constraintValue)
            let velocity = Double(constraintValue / (mainView.frame.height / 2))
            viewModel.setPitchVelocity(velocity)
        case .ended, .cancelled, .failed:
            setHandlePosition(at: Constants.defaultHandlePosition)
            viewModel.setPitchVelocity(Constants.defaultVelocity)
            viewModel.onStopInteraction()
        @unknown default:
            break
        }
    }

    /// Called when a double tap on handle view occurs.
    @objc func onDoubleTap(sender: UITapGestureRecognizer) {
        panGestureRecognizer.isEnabled = false
        panGestureRecognizer.isEnabled = true
        viewModel.onDoubleTap()
    }

    /// Moves handle view to given position.
    func setHandlePosition(at value: CGFloat) {
        handleViewYConstraint.constant = value
        bottomArrowView.alpha = value < 0 ? Constants.arrowActiveAlpha : Constants.arrowInactiveAlpha
        topArrowView.alpha = value > 0 ? Constants.arrowActiveAlpha : Constants.arrowInactiveAlpha
    }

    /// Moves tilt indicator to given position.
    func setTiltIndicatorPosition(currentValue: Double, upperBound: Double) {
        let halfHeight = mainView.frame.height / 2 - Constants.tiltIndicatorDelta
        let position = CGFloat(currentValue) * halfHeight / CGFloat(upperBound)
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
