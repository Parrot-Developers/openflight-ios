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

/// Draws a progress view showing current tilt position on a round view.

final class TiltButtonProgressView: UIView {
    // MARK: - Internal Properties
    /// Tilt value
    var value: Double = 0 {
        didSet {
            drawProgress()
        }
    }

    // MARK: - Private Properties
    private var backgroundLayer: CAShapeLayer?
    private var borderLayer: CAShapeLayer?

    // MARK: - Override Funcs
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        drawProgress()
    }
}

// MARK: - Private Funcs
private extension TiltButtonProgressView {
    /// Removes previously drawned progress and draws a new one with current parameters.
    func drawProgress() {
        // Remove layers if needed.
        backgroundLayer?.removeFromSuperlayer()
        borderLayer?.removeFromSuperlayer()

        // Draw border.
        let path = UIBezierPath(arcCenter: self.bounds.center,
                                radius: self.frame.width / 2,
                                startAngle: 0,
                                endAngle: CGFloat(-value).toRadians,
                                clockwise: value < 0)

        path.addArc(withCenter: path.currentPoint,
                    radius: 1,
                    startAngle: 0,
                    endAngle: 2 * CGFloat.pi,
                    clockwise: true)

        let border = CAShapeLayer()
        border.path = path.cgPath
        border.lineWidth = 1
        border.strokeColor = UIColor(named: .highlightColor).cgColor
        border.fillColor = UIColor.clear.cgColor

        layer.addSublayer(border)
        borderLayer = border

        // Close path and draw background.
        path.addLine(to: self.bounds.center)
        path.addLine(to: CGPoint(x: self.frame.width, y: self.frame.height / 2))

        let background = CAShapeLayer()
        background.path = path.cgPath
        background.fillColor = ColorName.disabledHighlightColor.color.cgColor

        layer.addSublayer(background)
        backgroundLayer = background
    }
}
