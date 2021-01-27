// Copyright (C) 2020 Parrot Drones SAS
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
import GroundSdk

// MARK: - TargetState
/// Every case for a target.
enum TargetState {
    case drawing
    case pending
    case locked
    case proposal

    var color: UIColor {
        switch self {
        case .drawing:
            return ColorName.blueDodger.color
        case .locked:
            return ColorName.greenSpring.color
        case .pending:
            return ColorName.yellowSea.color
        case .proposal:
            return ColorName.gold.color
        }
    }

    var enabledColor: CGColor {
        return self.color.withAlphaComponent(0.5).cgColor
    }

    var disabledColor: CGColor {
        return self.color.withAlphaComponent(0.0).cgColor
    }
}

// MARK: - ProposalDelegate
/// Protocol for TargetView.
protocol ProposalDelegate: class {
    /// To call when proposal have been selected.
    ///
    /// - Parameters:
    ///    - proposalId: Proposal selected.
    func didSelect(proposalId: UInt)

    /// To call when user click on close button on top of a target.
    func didDeselectTarget()
}

// MARK: - TargetView
/// This view draw itself to show a target rectangle.
/// This rectangle can have multiple states and so on modifies its border and background color.
final class TargetView: UIView {

    // MARK: - Internal Properties
    var state: TargetState = .drawing {
        didSet {
            self.drawState()
        }
    }

    // MARK: - Private Properties
    private weak var delegate: ProposalDelegate?
    private var closeButtonView: UIView?
    private var closeButton: UIButton?
    private var topCircleGradientLayer = CAGradientLayer()
    private var bottomCircleGradientLayer = CAGradientLayer()
    private var backGradientLayer = CAGradientLayer()
    private var selectionLayer = CAShapeLayer()
    private var tapGesture: UITapGestureRecognizer?
    private var uid: UInt = 0
    private var tilt: Double = 0.0
    private var circleHeight: CGFloat {
        return self.bounds.height / (Constants.maxTilt / CGFloat(tilt))
    }

    // MARK: - Constants
    private enum Constants {
        // The 0.552284749831 value correspond to the formula to get the optimal distance for a control point.
        // Formula: 4*(sqrt(2)-1)/3
        static let controlPointRatio: CGFloat = 0.552284749831
        static let dashPattern: [NSNumber] = [6, 2]
        static let maxTilt: CGFloat = 90.0
        static let selectionBorderSize: CGFloat = 2.0
        static let circleInset: CGFloat = 2.0
        static let circleWidth: CGFloat = 4.0
        static let closedButtonSize: CGFloat = 16.0
        static let closedButtonPadding: CGFloat = 20.0
        static let closedImageButtonPadding: CGFloat = 4.0
    }

    // MARK: - Init
    override func layoutSubviews() {
        super.layoutSubviews()
        self.drawState()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    /// Custom init.
    ///
    /// - Parameters:
    ///    - frame: Frame.
    ///    - targetId: The id of the target returned by the drone.
    ///    - state: State of the target.
    ///    - delegate: Proposal delegate.
    ///    - tilt: Gimbal tilt.
    init(frame: CGRect,
         targetId: UInt = 0,
         state: TargetState = .drawing,
         delegate: ProposalDelegate? = nil,
         tilt: Double = 0.0) {
        super.init(frame: frame)
        self.uid = targetId
        self.delegate = delegate
        self.state = state
        self.tilt = tilt
        self.commonInit()
    }

    // MARK: - Deinit
    deinit {
        self.removeLayers()
        self.removeTapGesture(true)
        self.removeCloseButton(true)
    }
}

// MARK: - Internal Funcs
extension TargetView {

    /// Update the view.
    ///
    /// - Parameters:
    ///    - frame: Frame.
    ///    - tilt: Gimbal tilt.
    func updateView(frame: CGRect, tilt: Double? = nil) {
        self.frame = frame

        if let strongTilt = tilt {
            self.tilt = strongTilt
        }
    }
}

// MARK: - Internal Funcs
private extension TargetView {

    /// Basic init for the view.
    func commonInit() {
        self.clipsToBounds = false
    }

    /// Adds tap gesture to the view.
    func addTapGesture() {
        guard self.tapGesture == nil else { return }

        self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(tap:)))
        self.tapGesture?.numberOfTapsRequired = 1
        self.tapGesture?.numberOfTouchesRequired = 1
        self.addGestureRecognizer(self.tapGesture)
    }

    /// Removes tap gesture to the view.
    ///
    /// - Parameters:
    ///    - forced: boolean to force remove the view.
    func removeTapGesture(_ forced: Bool = false) {
        guard self.tapGesture != nil,
            self.state != .proposal || forced == true else {
                return
        }

        self.removeGestureRecognizer(self.tapGesture)
        self.tapGesture = nil
    }

    /// Remove every layers on the view.
    func removeLayers() {
        self.backGradientLayer.removeFromSuperlayer()
        self.topCircleGradientLayer.removeFromSuperlayer()
        self.bottomCircleGradientLayer.removeFromSuperlayer()
        self.selectionLayer.removeFromSuperlayer()
    }

    /// Updates the view in terms of the current state.
    func drawState() {
        self.removeLayers()
        self.removeCloseButton()
        self.removeTapGesture()

        switch state {
        // Case where user is drawing the selection.
        case .drawing:
            self.drawSelectionFrame()
        // Case where a target is tracked.
        case .locked:
            self.drawBackTargetLocked()
            self.drawBottomCircle()
            self.drawCloseButton()
        // Case where a target is lost.
        case .pending:
            self.drawBackTargetLocked(drawDashPattern: true)
            self.drawTopCircle(drawDashPattern: true)
            self.drawBottomCircle(drawDashPattern: true)
            self.drawCloseButton()
        // Case where the drone returns proposals.
        case .proposal:
            self.drawBackProposal()
            self.drawBottomCircle()
            self.addTapGesture()
        }
    }

    /// Draws a rectangle shape when user trace a movement with his finger.
    func drawSelectionFrame() {
        self.selectionLayer = CAShapeLayer()

        let rectPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: Style.mediumCornerRadius)
        self.selectionLayer.path = rectPath.cgPath
        self.selectionLayer.fillColor = self.state.enabledColor
        self.selectionLayer.strokeColor = self.state.color.cgColor
        self.selectionLayer.lineWidth = Constants.selectionBorderSize
        self.selectionLayer.lineDashPattern = Constants.dashPattern
        self.layer.addSublayer(self.selectionLayer)
    }

    /// Draws the shape for the back view with a gradient color for a proposal.
    func drawBackProposal() {
        self.backGradientLayer = CAGradientLayer()

        self.backGradientLayer.frame = bounds
        self.backGradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        self.backGradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        self.backGradientLayer.colors = [self.state.disabledColor,
                                         self.state.enabledColor]
        let centerCircleHeight: CGFloat = self.bounds.height - (circleHeight / 2.0)
        let backPath = UIBezierPath(rect: CGRect(x: 0.0,
                                                 y: centerCircleHeight,
                                                 width: 0.0,
                                                 height: 0.0))

        // Draws a base rectangle from the top of the view to the circle middle by following the next steps.
        //
        //   <---3---
        //   |       ^
        //   4       |
        //   |       2
        //   v       |
        //   X---1--->

        // Add line 1
        backPath.addLine(to: CGPoint(x: self.bounds.width, y: centerCircleHeight))
        // Add line 2
        backPath.addLine(to: CGPoint(x: self.bounds.width, y: 0.0))
        // Add line 3
        backPath.addLine(to: CGPoint(x: 0.0, y: 0.0))
        // Add line 4
        backPath.addLine(to: CGPoint(x: 0.0, y: centerCircleHeight))

        // Next steps will draw two curves to display a semi-circle at the bottom of the current path.
        let heightControlPoint = self.getControlPoint(length: self.circleHeight)
        let widthControlPoint = self.getControlPoint(length: self.bounds.width)

        // Generate two control points for the first curve and add the curve to the current path.
        let firstCircleControlPoint1 = CGPoint(x: 0.0,
                                               y: centerCircleHeight + heightControlPoint)
        let firstCircleControlPoint2 = CGPoint(x: (self.bounds.width / 2.0) - widthControlPoint,
                                               y: self.bounds.height)
        backPath.addCurve(to: CGPoint(x: self.bounds.width / 2.0, y: self.bounds.height),
                          controlPoint1: firstCircleControlPoint1,
                          controlPoint2: firstCircleControlPoint2)

        // Generate two control points for the second curve and add the curve to the current path.
        let secondCircleControlPoint1 = CGPoint(x: (self.bounds.width / 2.0) + widthControlPoint,
                                                y: self.bounds.height)
        let secondCircleControlPoint2 = CGPoint(x: self.bounds.width,
                                                y: centerCircleHeight + heightControlPoint)
        backPath.addCurve(to: CGPoint(x: self.bounds.width, y: centerCircleHeight),
                          controlPoint1: secondCircleControlPoint1,
                          controlPoint2: secondCircleControlPoint2)

        // Create a layer to add the back path on.
        let backLayer = CAShapeLayer()
        backLayer.path = backPath.cgPath

        // Apply a mask with the shape of the current path to the gradient layer.
        self.backGradientLayer.mask = backLayer
        // Add the gradient layer with the gradient color and the wanted shape to the view.
        self.layer.addSublayer(self.backGradientLayer)
    }

    /// Draws the shape for the back view with a gradient color for a locked target.
    ///
    /// - Parameters:
    ///    - drawDashPattern: Specify if a dash pattern must be applied.
    func drawBackTargetLocked(drawDashPattern: Bool = false) {
        self.backGradientLayer = CAGradientLayer()

        self.backGradientLayer.frame = bounds
        self.backGradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        self.backGradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        self.backGradientLayer.colors = [self.state.enabledColor,
                                         self.state.disabledColor]
        let centerCircleHeight: CGFloat = self.bounds.height - (circleHeight / 2.0)
        let backPath = UIBezierPath(rect: CGRect(x: 0.0,
                                                 y: centerCircleHeight,
                                                 width: 0.0,
                                                 height: 0.0))

        let heightControlPoint = self.getControlPoint(length: self.circleHeight)
        let widthControlPoint = self.getControlPoint(length: self.bounds.width)

        // Next steps will draw a semi circle at the bottom of the frame.
        let firstCircleControlPoint1 = CGPoint(x: 0.0,
                                               y: centerCircleHeight + heightControlPoint)
        let firstCircleControlPoint2 = CGPoint(x: (self.bounds.width / 2.0) - widthControlPoint,
                                               y: self.bounds.height)
        backPath.addCurve(to: CGPoint(x: self.bounds.width / 2.0, y: self.bounds.height),
                          controlPoint1: firstCircleControlPoint1,
                          controlPoint2: firstCircleControlPoint2)

        let secondCircleControlPoint1 = CGPoint(x: (self.bounds.width / 2.0) + widthControlPoint,
                                                y: self.bounds.height)
        let secondCircleControlPoint2 = CGPoint(x: self.bounds.width,
                                                y: centerCircleHeight + heightControlPoint)
        backPath.addCurve(to: CGPoint(x: self.bounds.width, y: centerCircleHeight),
                          controlPoint1: secondCircleControlPoint1,
                          controlPoint2: secondCircleControlPoint2)

        // Next steps will draw a semi circle at the top of the frame.
        backPath.addQuadCurve(to: CGPoint(x: self.bounds.width / 2.0, y: 0.0),
                              controlPoint: CGPoint(x: self.bounds.width, y: 0.0))
        backPath.addQuadCurve(to: CGPoint(x: 0.0, y: centerCircleHeight),
                              controlPoint: CGPoint(x: 0, y: 0))

        // Create a layer to add the back path on.
        let backLayer = CAShapeLayer()
        backLayer.path = backPath.cgPath
        backLayer.lineDashPattern = drawDashPattern ? Constants.dashPattern : []

        // Apply a mask with the shape of the current path to the gradient layer.
        self.backGradientLayer.mask = backLayer
        // Add the gradient layer with the gradient color and the wanted shape to the view.
        self.layer.addSublayer(self.backGradientLayer)
    }

    /// Draws a semi-circle line at the top of the view.
    ///
    /// - Parameters:
    ///    - drawDashPattern: Specify if a dash pattern must be applied.
    func drawTopCircle(drawDashPattern: Bool = false) {
        self.topCircleGradientLayer = CAGradientLayer()
        let centerCircleHeight: CGFloat = self.bounds.height - self.circleHeight / 2.0

        // Instantiate frame for the gradient color.
        let gradientFrame = CGRect(x: 0.0,
                                   y: 0.0,
                                   width: self.bounds.width,
                                   height: centerCircleHeight)

        self.topCircleGradientLayer.frame = gradientFrame
        // Start point of the gradient will be on the center of the width and on the top of the frame.
        self.topCircleGradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        // End point of the gradient will be on the center of the width and on the bottom of the frame.
        self.topCircleGradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        self.topCircleGradientLayer.colors = [self.state.color.withAlphaComponent(1.0).cgColor,
                                              self.state.color.withAlphaComponent(0.0).cgColor]

        let circlePath = UIBezierPath(rect: CGRect(x: 0.0,
                                                   y: centerCircleHeight,
                                                   width: 0.0,
                                                   height: 0.0))

        circlePath.addLine(to: CGPoint(x: self.bounds.width - Constants.circleInset,
                                       y: centerCircleHeight))

        circlePath.addQuadCurve(to: CGPoint(x: self.bounds.width / 2.0, y: Constants.circleInset),
                                controlPoint: CGPoint(x: self.bounds.width, y: 0.0))
        circlePath.addQuadCurve(to: CGPoint(x: Constants.circleInset, y: centerCircleHeight),
                                controlPoint: CGPoint(x: 0, y: 0))

        // Create a layer to add the circle path on.
        let circleLayer = CAShapeLayer()
        circleLayer.path = circlePath.cgPath
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.strokeColor = UIColor.white.cgColor
        circleLayer.lineWidth = Constants.circleWidth
        circleLayer.lineDashPattern = drawDashPattern ? Constants.dashPattern : []

        // Apply a mask with the shape of the current path to the gradient layer.
        self.topCircleGradientLayer.mask = circleLayer
        // Add the gradient layer with the gradient color and the wanted shape to the view.
        self.layer.addSublayer(self.topCircleGradientLayer)
    }

    /// Draws a circle with gradient color at the bottom of the view.
    ///
    /// - Parameters:
    ///    - drawDashPattern: Specify if a dash pattern must be applied.
    func drawBottomCircle(drawDashPattern: Bool = false) {
        self.bottomCircleGradientLayer = CAGradientLayer()

        // Instantiate frame for the gradient color.
        let gradientFrame = CGRect(x: 0.0,
                                   y: self.bounds.height - self.circleHeight,
                                   width: self.bounds.width,
                                   height: self.circleHeight)
        self.bottomCircleGradientLayer.frame = gradientFrame
        // Start point of the gradient will be on the center of the width and on the top of the frame.
        self.bottomCircleGradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        // End point of the gradient will be on the center of the width and on the bottom of the frame.
        self.bottomCircleGradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        self.bottomCircleGradientLayer.colors = [self.state.disabledColor,
                                                 self.state.color.cgColor]

        // Instantiate frame for the circle path with an inset to get the full size of the line width.
        var circleFrame = CGRect(x: 0.0,
                                 y: 0.0,
                                 width: gradientFrame.width,
                                 height: gradientFrame.height)
        circleFrame = circleFrame.insetBy(dx: Constants.circleInset,
                                          dy: Constants.circleInset)
        // Instantiate a path to get an oval shape whatever the size of the frame specified.
        let circlePath = UIBezierPath(ovalIn: circleFrame)
        // Create a layer to add the circle path on.
        let circleLayer = CAShapeLayer()
        circleLayer.path = circlePath.cgPath
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.strokeColor = UIColor.white.cgColor
        circleLayer.lineWidth = Constants.circleWidth
        circleLayer.lineDashPattern = drawDashPattern ? Constants.dashPattern : []

        // Apply a mask with the shape of the current path to the gradient layer.
        self.bottomCircleGradientLayer.mask = circleLayer
        // Add the gradient layer with the gradient color and the wanted shape to the view.
        self.layer.addSublayer(self.bottomCircleGradientLayer)
    }

    /// Draws a close button at the top of the view.
    func drawCloseButton() {
        let buttonSize = Constants.closedButtonSize + Constants.closedButtonPadding
        let buttonFrame = CGRect(center: CGPoint(x: self.bounds.width / 2.0, y: 0.0),
                                 width: buttonSize,
                                 height: buttonSize)

        if let strongCloseButton = self.closeButtonView {
            self.closeButtonView?.frame = buttonFrame
            self.closeButton?.backgroundColor = self.state.color
            self.bringSubviewToFront(strongCloseButton)
        } else {
            self.closeButtonView = self.instantiateCloseButton(frame: buttonFrame)
            self.addSubview(self.closeButtonView)
        }
    }

    /// Returns the distance at which the control point must be in order to make an oval shape.
    ///
    /// - Parameters:
    ///    - length: Length of the radius circle.
    /// - Returns: The distance of the control point.
    func getControlPoint(length: CGFloat) -> CGFloat {
        return ((length / 2.0) * Constants.controlPointRatio)
    }

    /// Creates the close button view.
    ///
    /// - Parameters:
    ///    - frame: frame of the view.
    /// - Returns: The generated view.
    func instantiateCloseButton(frame: CGRect) -> UIView {
        let closedButtonView = UIView(frame: frame)
        let closeButtonFrame = CGRect(center: CGPoint(x: frame.width / 2.0, y: frame.height / 2.0),
                                      width: Constants.closedButtonSize,
                                      height: Constants.closedButtonSize)
        let closedButton = UIButton(frame: closeButtonFrame)
        closedButton.setImage(Asset.Common.Icons.icCloseBlack.image, for: .normal)
        closedButton.backgroundColor = self.state.color
        closedButton.clipsToBounds = true
        closedButton.roundCornered()
        closedButton.imageEdgeInsets = UIEdgeInsets(top: Constants.closedImageButtonPadding,
                                                    left: Constants.closedImageButtonPadding,
                                                    bottom: Constants.closedImageButtonPadding,
                                                    right: Constants.closedImageButtonPadding)
        self.closeButton = closedButton
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(closeButtonTouchedUpInside(tap:)))
        closedButtonView.addGestureRecognizer(tapGesture)
        closedButtonView.addSubview(closedButton)

        return closedButtonView
    }

    /// Removes close button view and button from superview.
    ///
    /// - Parameters:
    ///    - forced: boolean to force remove the view.
    func removeCloseButton(_ forced: Bool = false) {
        var mustRemoveButton: Bool
        switch self.state {
        case .locked, .pending:
            mustRemoveButton = forced || false
        default:
            mustRemoveButton = forced || true
        }

        guard mustRemoveButton else { return }

        if self.closeButton != nil {
            self.closeButton?.removeFromSuperview()
            self.closeButton = nil
        }

        if self.closeButtonView != nil {
            self.closeButtonView?.removeFromSuperview()
            self.closeButtonView = nil
        }
    }
}

// MARK: - Actions
private extension TargetView {

    /// Action triggered when user tap on the view.
    @objc func handleTap(tap: UITapGestureRecognizer) {
        self.delegate?.didSelect(proposalId: uid)
    }

    /// Action triggered when user tap on the close button view.
    @objc func closeButtonTouchedUpInside(tap: UITapGestureRecognizer) {
        self.delegate?.didDeselectTarget()
    }
}
