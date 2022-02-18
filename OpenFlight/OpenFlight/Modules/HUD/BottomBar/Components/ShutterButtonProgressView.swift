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

import Reusable

/// View displaying a shutter button progress view for lapse capture mode.

final class ShutterButtonProgressView: UIView, NibOwnerLoadable {
    // MARK: - Private Properties
    private var progressLayer = CAShapeLayer()
    private var progressLayerBackground = CAShapeLayer()
    private lazy var animation = CABasicAnimation(keyPath: Constants.layerAnimationKey)

    // MARK: - Private Enums
    private enum Constants {
        static let layerAnimationKey: String = "strokeEnd"
        static let borderWidth: CGFloat = 10.0
        static let strokeColor: UIColor = UIColor(named: .highlightColor)
        static let backgroundStrokeColor: UIColor = UIColor(named: .white20)
        static let startAngle: CGFloat = CGFloat(Float.pi / -2.0)
    }

    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    // MARK: - Internal Funcs
    /// Update progress.
    ///
    /// - Parameters:
    ///     - progress: current progress value
    ///     - duration: duration of the animation. 1second is the default value.
    func setProgress(_ progress: Float, duration: TimeInterval = 1.0) {
        let progress = min(1.0, max(0.0, progress))
        drawProgressLayer(progress: CGFloat(progress), animated: true)
        animateProgressLayer(duration: duration)
    }

    /// Animates progress from 0 to 1.
    ///
    /// - Parameters:
    ///     - duration: duration of the animation
    func animateProgress(duration: TimeInterval) {
        drawProgressLayer(progress: 0, animated: true)
        animateProgressLayer(duration: duration, from: 0)
    }

    /// Reset progress.
    func resetProgress() {
        progressLayer.removeFromSuperlayer()
        progressLayer = CAShapeLayer()
    }
}

// MARK: - Private Funcs
private extension ShutterButtonProgressView {
    /// Init view.
    func commonInit() {
        loadNibContent()
        drawBackgroundProgressLayer()
    }

    /// Draws the progress layer.
    ///
    /// - Parameters:
    ///     - progress: current progress value
    ///     - animated: tells if the view need to be animated
    func drawProgressLayer(progress: CGFloat = 0.0, animated: Bool = false) {
        CATransaction.begin()
        CATransaction.setDisableActions(!animated)
        progressLayer.path = progressPath.cgPath
        progressLayer.strokeColor = Constants.strokeColor.cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = Constants.borderWidth
        progressLayer.strokeEnd = 1.0 - progress
        CATransaction.commit()
        if progressLayer.superlayer == nil {
            layer.addSublayer(progressLayer)
        }
    }

    /// Draws the background progress layer.
    func drawBackgroundProgressLayer() {
        progressLayerBackground.path = progressPath.cgPath
        progressLayerBackground.strokeColor = Constants.backgroundStrokeColor.cgColor
        progressLayerBackground.fillColor = UIColor.clear.cgColor
        progressLayerBackground.lineWidth = Constants.borderWidth
        layer.addSublayer(progressLayerBackground)
    }

    /// Animates the progress view.
    ///
    /// - Parameters:
    ///     - duration: animation duration
    ///     - from: animation fromValue if not nil (`progressLayer` current strokeEnd will be used as fromValue otherwise)
    func animateProgressLayer(duration: TimeInterval, from: CGFloat? = nil) {
        animation.duration = duration
        if let fromValue = from {
            animation.fromValue = fromValue
        } else if let presentationStrokeEnd = progressLayer.presentation()?.strokeEnd {
            animation.fromValue = presentationStrokeEnd
        } else {
            animation.fromValue = progressLayer.strokeEnd
        }
        animation.toValue = progressLayer.strokeEnd
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        progressLayer.add(animation, forKey: Constants.layerAnimationKey)
    }

    /// The rounded rectangle bezier path with a midX top starting point.
    var progressPath: UIBezierPath {
        let path = UIBezierPath()
        let cornerRadius = Style.largeCornerRadius
        path.move(to: CGPoint(x: frame.midX, y: 0))
        path.addLine(to: CGPoint(x: frame.width - cornerRadius, y: 0))
        path.addArc(withCenter: CGPoint(x: frame.width - cornerRadius, y: cornerRadius),
                    radius: cornerRadius,
                    startAngle: -.pi / 2,
                    endAngle: 0,
                    clockwise: true)
        path.addLine(to: CGPoint(x: frame.width, y: frame.height - cornerRadius))
        path.addArc(withCenter: CGPoint(x: frame.width - cornerRadius, y: frame.height - cornerRadius),
                    radius: cornerRadius,
                    startAngle: 0,
                    endAngle: .pi / 2,
                    clockwise: true)
        path.addLine(to: CGPoint(x: cornerRadius, y: frame.height))
        path.addArc(withCenter: CGPoint(x: cornerRadius, y: frame.height - cornerRadius),
                    radius: cornerRadius,
                    startAngle: .pi / 2,
                    endAngle: .pi,
                    clockwise: true)
        path.addLine(to: CGPoint(x: 0, y: cornerRadius))
        path.addArc(withCenter: CGPoint(x: cornerRadius, y: cornerRadius),
                    radius: cornerRadius,
                    startAngle: .pi,
                    endAngle: .pi * 3 / 2,
                    clockwise: true)
        path.close()

        return path
    }
}
