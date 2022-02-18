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
            return ColorName.highlightColor.color
        case .pending:
            return ColorName.yellowSea.color
        case .proposal:
            return ColorName.gold.color
        }
    }

    var enabledColor: CGColor {
        return color.withAlphaComponent(0.5).cgColor
    }
}

// MARK: - ProposalDelegate
/// Protocol for TargetView.
protocol ProposalDelegate: AnyObject {
    /// Called when proposal have been selected.
    ///
    /// - Parameters:
    ///    - proposalId: proposal selected
    func didSelect(proposalId: UInt)

    /// Called when user clicked on close button on top of a target.
    func didDeselectTarget()
}

// MARK: - TargetView
/// This view draws itself to show a target rectangle.
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

    // MARK: - Constants
    private enum Constants {
        static let dashPattern: [NSNumber] = [6, 2]
        static let selectionBorderSize: CGFloat = 2.0
    }

    // MARK: - Init
    override func layoutSubviews() {
        super.layoutSubviews()
        drawState()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    /// Constructor.
    ///
    /// - Parameters:
    ///    - frame: frame
    ///    - targetId: the target ID returned by the drone
    ///    - state: the target state
    ///    - delegate: proposal delegate
    ///    - tilt: gimbal tilt
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
        commonInit()
    }

    // MARK: - Deinit
    deinit {
        removeLayers()
        removeTapGesture(true)
        removeCloseButton(true)
    }
}

// MARK: - Internal Funcs
extension TargetView {

    /// Updates the view.
    ///
    /// - Parameters:
    ///    - frame: frame
    ///    - tilt: gimbal tilt
    func updateView(frame: CGRect, tilt: Double? = nil) {
        switch state {
        case .locked, .pending:
            let newFrame = CGRect(x: frame.origin.x,
                                  y: frame.origin.y,
                                  width: frame.width,
                                  height: frame.height)
            self.frame = newFrame
        case .drawing, .proposal:
            self.frame = frame
        }

        if let tilt = tilt {
            self.tilt = abs(tilt)
        }
    }
}

// MARK: - Internal Funcs
private extension TargetView {

    /// Base init for the view.
    func commonInit() {
        clipsToBounds = false
    }

    /// Adds tap gesture to the view.
    func addTapGesture() {
        guard tapGesture == nil else { return }

        tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(tap:)))
        tapGesture?.numberOfTapsRequired = 1
        tapGesture?.numberOfTouchesRequired = 1
        addGestureRecognizer(tapGesture)
    }

    /// Removes tap gesture to the view.
    ///
    /// - Parameters:
    ///    - forced: boolean to force remove the view.
    func removeTapGesture(_ forced: Bool = false) {
        guard tapGesture != nil,
              state != .proposal || forced == true else {
                  return
              }

        removeGestureRecognizer(tapGesture)
        tapGesture = nil
    }

    /// Removed all layers from the view.
    func removeLayers() {
        backGradientLayer.removeFromSuperlayer()
        topCircleGradientLayer.removeFromSuperlayer()
        bottomCircleGradientLayer.removeFromSuperlayer()
        selectionLayer.removeFromSuperlayer()
    }

    /// Updates the view with the current state.
    func drawState() {
        removeLayers()
        removeCloseButton()
        removeTapGesture()
        switch state {
            // case where user is drawing the selection
        case .drawing:
            drawSelectionFrame()
            // case where a target is tracked
        case .locked:
            drawSimpleRectangle()
            // case where a target is lost
        case .pending:
            drawSimpleRectangle()
            // case where the drone returns proposals
        case .proposal:
            drawSimpleRectangle()
            addTapGesture()
        }
    }

    func drawSimpleRectangle() {
        backgroundColor = state.color.withAlphaComponent(0.5)
    }

    /// Draws a rectangle shape when user trace a movement with his finger.
    func drawSelectionFrame() {
        selectionLayer = CAShapeLayer()

        let rectPath = UIBezierPath(roundedRect: bounds, cornerRadius: Style.mediumCornerRadius)
        selectionLayer.path = rectPath.cgPath
        selectionLayer.fillColor = state.enabledColor
        selectionLayer.strokeColor = state.color.cgColor
        selectionLayer.lineWidth = Constants.selectionBorderSize
        selectionLayer.lineDashPattern = Constants.dashPattern
        layer.addSublayer(selectionLayer)
    }

    /// Removes close button view and button from superview.
    ///
    /// - Parameters:
    ///    - forced: boolean to force remove the view
    func removeCloseButton(_ forced: Bool = false) {
        var mustRemoveButton: Bool
        switch state {
        case .locked, .pending:
            mustRemoveButton = forced || false
        default:
            mustRemoveButton = forced || true
        }

        guard mustRemoveButton else { return }

        if closeButton != nil {
            closeButton?.removeFromSuperview()
            closeButton = nil
        }

        if closeButtonView != nil {
            closeButtonView?.removeFromSuperview()
            closeButtonView = nil
        }
    }
}

// MARK: - Actions
private extension TargetView {

    /// Action triggered when user tap on the view.
    @objc func handleTap(tap: UITapGestureRecognizer) {
        delegate?.didSelect(proposalId: uid)
    }

    /// Action triggered when user tap on the close button view.
    @objc func closeButtonTouchedUpInside(tap: UITapGestureRecognizer) {
        delegate?.didDeselectTarget()
    }
}
