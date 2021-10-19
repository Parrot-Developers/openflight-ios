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

import Reusable

// MARK: - Protocols
protocol CircleProgressViewDelegate: AnyObject {
    /// Tells that the animation is finished.
    func animationProgressFinished()
}

enum ProgressStatus {
    case inactive
    case active
    case succes
    case failure

    var color: UIColor {
        switch self {
        case .inactive: return ColorName.whiteAlbescent.color
        case .active: return ColorName.highlightColor.color
        case .succes: return ColorName.highlightColor.color
        case .failure: return ColorName.errorColor.color
        }
    }
}

/// View displaying a circle representing a progress value.
final class CircleProgressView: UIView, NibOwnerLoadable {
    // MARK: - Internal Properties
    var status: ProgressStatus = .active {
        didSet {
            guard status != oldValue else { return }
            refreshProgressLayer()
        }
    }
    var strokeColor: UIColor?
    var bgStokeColor: UIColor = UIColor(named: .whiteAlbescent) {
        didSet {
            progressLayerBackground.strokeColor = bgStokeColor.cgColor
        }
    }
    var borderWidth: CGFloat = Constants.borderWidth {
        didSet {
            drawBackgroundProgressLayer()
        }
    }
    weak var delegate: CircleProgressViewDelegate?

    // MARK: - Private Properties
    private var progressStrokeColor: UIColor {
        strokeColor ?? status.color
    }
    private var progressLayer = CAShapeLayer()
    private let progressLayerBackground = CAShapeLayer()
    private var animation = CABasicAnimation(keyPath: Constants.layerAnimationKey)

    // MARK: - Private Enums
    private enum Constants {
        static let layerAnimationKey = "strokeEnd"
        static let borderWidth: CGFloat = 3.0
        static let lineDashPattern: [NSNumber] = [10, 5]
    }

    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    // MARK: - Override Funcs
    override func layoutSubviews() {
        super.layoutSubviews()
        progressLayer.removeFromSuperlayer()
        drawBackgroundProgressLayer()
        drawProgressLayer(strokeColor: progressStrokeColor, progress: 0.0, animated: false)
    }

    // MARK: - Internal Funcs
    /// Update progress.
    ///
    /// - Parameters:
    ///     - progress: current progress value
    ///     - duration: duration
    func setProgress(_ progress: Float, duration: TimeInterval = 0.0) {
        let progress = min(1, max(0, progress))
        let isAnimated = duration > 0.0
        progressLayer.removeAnimation(forKey: Constants.layerAnimationKey)
        drawProgressLayer(strokeColor: progressStrokeColor, progress: CGFloat(progress), animated: isAnimated)
        if isAnimated {
            animateProgressLayer(duration: duration)
        }
    }

    /// Reset progress.
    func resetProgress() {
        progressLayer.removeFromSuperlayer()
        progressLayer = CAShapeLayer()
        drawProgressLayer(strokeColor: progressStrokeColor, progress: 0.0, animated: false)
    }
}

// MARK: - Private Funcs
private extension CircleProgressView {
    /// Init view.
    func commonInit() {
        self.loadNibContent()
        animation.delegate = self
    }

    /// Animate the progress view.
    ///
    /// - Parameters:
    ///     - duration: animation duration
    func animateProgressLayer(duration: TimeInterval) {
        animation.duration = duration

        // Animate progressLayer starting from currently displayed strokeEnd if available.
        // If not, animate starting from strokeStart.
        animation.fromValue = progressLayer.presentation()?.strokeEnd ?? progressLayer.strokeStart

        animation.toValue = progressLayer.strokeEnd
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        progressLayer.add(animation, forKey: Constants.layerAnimationKey)
    }

    /// Draw the progress layer.
    ///
    /// - Parameters:
    ///     - strokeColor: stroke color
    ///     - progress: current progress value
    ///     - animated: animated of not
    func drawProgressLayer(strokeColor: UIColor, progress: CGFloat, animated: Bool) {
        let center = CGPoint(x: frame.width / 2.0, y: frame.height / 2.0)
        let radius: CGFloat = (frame.width / 2.0) - borderWidth
        let startAngle: CGFloat = CGFloat(Float.pi / -2.0)
        let progressPath = UIBezierPath(arcCenter: center,
                                        radius: radius,
                                        startAngle: startAngle,
                                        endAngle: startAngle + 2.0 * CGFloat.pi,
                                        clockwise: true)

        CATransaction.begin()
        CATransaction.setDisableActions(!animated)
        progressLayer.path = progressPath.cgPath
        progressLayer.strokeColor = strokeColor.cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = borderWidth
        progressLayer.strokeEnd = progress
        CATransaction.commit()
        if progressLayer.superlayer == nil {
            layer.addSublayer(progressLayer)
        }
    }

    /// Draw the background layer.
    func drawBackgroundProgressLayer() {
        let center = CGPoint(x: frame.width / 2.0, y: frame.height / 2.0)
        let radius: CGFloat = (self.frame.width / 2.0) - borderWidth
        let startAngle: CGFloat = CGFloat(Float.pi / -2.0)
        let progressPath = UIBezierPath(arcCenter: center,
                                        radius: radius,
                                        startAngle: startAngle,
                                        endAngle: startAngle + 2.0 * CGFloat.pi,
                                        clockwise: true)
        progressLayerBackground.path = progressPath.cgPath
        progressLayerBackground.strokeColor = bgStokeColor.cgColor
        progressLayerBackground.fillColor = UIColor.clear.cgColor
        progressLayerBackground.lineWidth = borderWidth
        if !(layer.sublayers?.contains(progressLayerBackground) ?? false) {
            layer.addSublayer(progressLayerBackground)
        }
    }

    func refreshProgressLayer() {
        drawProgressLayer(strokeColor: progressStrokeColor, progress: progressLayer.strokeEnd, animated: false)
    }
}

// MARK: - CAAnimationDelegate
extension CircleProgressView: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        // Check if the animation is finished.
        guard flag else { return }
        delegate?.animationProgressFinished()
    }
}
