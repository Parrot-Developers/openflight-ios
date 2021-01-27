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

@IBDesignable
class ZoomSlider: UISlider {
    // MARK: - Internal Properties
    var underLimitColor = UIColor(named: .greenSpring).withAlphaComponent(0.6)
    var overLimitColor = UIColor(named: .orangePeel).withAlphaComponent(0.6)
    var overLimitValue: Float = 1.0 {
        didSet {
            drawSlider()
        }
    }

    // MARK: - Override Properties
    override var value: Float {
        didSet {
            drawSlider()
        }
    }

    override var maximumValue: Float {
        didSet {
            drawSlider()
        }
    }

    // MARK: - Private Enums
    private enum Constants {
        static let trackHeight: CGFloat = 2.5
        static let limitHeight: CGFloat = 2.0
        static let topBottomMargin: CGFloat = 2.0
    }

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()

        isUserInteractionEnabled = false
        transform = transform.rotated(by: CGFloat(-0.5 * .pi))

        setThumbImage(UIImage(), for: .normal)
        setThumbImage(UIImage(), for: .selected)
        setThumbImage(UIImage(), for: .highlighted)
        setThumbImage(UIImage(), for: .disabled)

        minimumTrackTintColor = UIColor.darkGray.withAlphaComponent(0.6)
        maximumTrackTintColor = UIColor.darkGray.withAlphaComponent(0.6)

        layer.cornerRadius = min(frame.size.width, frame.size.height) / 2
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        drawSlider()
    }

    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        var newRect = super.trackRect(forBounds: bounds)
        newRect.size.height = Constants.trackHeight
        newRect.origin.y = (bounds.size.height - Constants.trackHeight) / 2
        return newRect
    }
}

// MARK: - Private Funcs
private extension ZoomSlider {
    /// Draws the slider.
    func drawSlider() {
        addUnderLimitSubview()
        addOverLimitSubview()
        addLimitSubview()
    }

    /// Adds the over limit subview (representing lossy part of the zoom).
    func addOverLimitSubview() {
        removeSubview(withBackgroundColor: overLimitColor)

        guard overLimitValue < maximumValue else {
            return
        }

        let overLimitStartRatio = (overLimitValue-minimumValue) / (maximumValue-minimumValue)
        var overLimitRatio: Float = 0.0
        if maximumValue-overLimitValue != 0 {
            overLimitRatio = (max(overLimitValue, value)-overLimitValue) / (maximumValue-overLimitValue)
        }
        var frame = self.frame
        frame.size.height = Constants.trackHeight
        let startY = self.frame.size.height * CGFloat(overLimitStartRatio) + Constants.limitHeight
        frame.size.width = max((self.frame.size.height - startY) * CGFloat(overLimitRatio) - Constants.topBottomMargin, 0)
        frame.origin.y = (self.frame.size.width - Constants.trackHeight) / 2
        frame.origin.x = startY

        addSubview(frame: frame, backgroundColor: overLimitColor, roundedCorner: true)
    }

    /// Adds the under limit subview (representing lossless part of the zoom).
    func addUnderLimitSubview() {
        guard maximumValue > minimumValue else {
            return
        }
        let overLimitRatio = (min(overLimitValue, value)-minimumValue) / (maximumValue-minimumValue)
        var frame = self.frame
        frame.size.height = Constants.trackHeight
        frame.size.width = max(self.frame.size.height * CGFloat(overLimitRatio) - Constants.topBottomMargin, 0)
        frame.origin.y = (self.frame.size.width - Constants.trackHeight) / 2
        frame.origin.x = Constants.topBottomMargin

        removeSubview(withBackgroundColor: underLimitColor)
        addSubview(frame: frame, backgroundColor: underLimitColor, roundedCorner: true)
    }

    /// Adds the subview separating lossless and lossy parts of the zoom.
    func addLimitSubview() {
        let limitColor = backgroundColor?.withAlphaComponent(0.3) ?? UIColor.darkGray
        removeSubview(withBackgroundColor: limitColor)

        guard overLimitValue < maximumValue else {
            return
        }

        let overLimitRatio = (overLimitValue-minimumValue) / (maximumValue-minimumValue)
        var frame = self.frame
        frame.size.height = Constants.trackHeight
        frame.size.width = Constants.limitHeight
        frame.origin.y = (self.frame.size.width - Constants.trackHeight) / 2
        frame.origin.x = self.frame.size.height * CGFloat(overLimitRatio)

        addSubview(frame: frame, backgroundColor: limitColor, roundedCorner: false)
    }

    /// Adds a subview with given properties.
    ///
    /// - Parameters:
    ///    - frame: the frame of the subview
    ///    - backgroundColor: the background color of the subview
    ///    - roundedCorner: whether the subview's corner should round or not
    func addSubview(frame: CGRect, backgroundColor: UIColor, roundedCorner: Bool) {
        let viewToAdd: UIView = UIView(frame: frame)
        viewToAdd.backgroundColor = backgroundColor
        if roundedCorner {
            viewToAdd.roundCornered()
        }
        addSubview(viewToAdd)
    }

    /// Removes previously added subviews.
    ///
    /// - Parameters:
    ///    - color: color of the subviews to remove
    func removeSubview(withBackgroundColor color: UIColor) {
        for view in self.subviews where view.backgroundColor == color {
            view.removeFromSuperview()
        }
    }
}
