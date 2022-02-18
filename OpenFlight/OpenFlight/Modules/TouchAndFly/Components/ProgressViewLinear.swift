//    Copyright (C) 2021 Parrot Drones SAS
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

import Foundation
import UIKit

public enum LinearProgressBarState {
    case determinate(percentage: CGFloat)
    case indeterminate
}

open class LinearProgressBar: UIView {
    private let firstProgressComponent = CAShapeLayer()
    private let secondProgressComponent = CAShapeLayer()
    private lazy var progressComponents = [firstProgressComponent, secondProgressComponent]

    private(set) var isAnimating = false
    open private(set) var state: LinearProgressBarState = .indeterminate
    var animationDuration: TimeInterval = 2.5

    open var progressBarHeight: CGFloat = 2.0 {
        didSet {
            updateProgressBarWidth()
        }
    }

    open var progressBarColor: UIColor = .systemBlue {
        didSet {
            updateProgressBarColor()
        }
    }

    open var cornerRadius: CGFloat = 0 {
        didSet {
            updateCornerRadius()
        }
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)

        prepare()
        prepareLines()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        prepare()
        prepareLines()
    }

    override open func layoutSubviews() {
        super.layoutSubviews()

        updateLineLayers()
    }

    private func prepare() {
        clipsToBounds = true
    }

    func prepareLines() {
        progressComponents.forEach {
            $0.fillColor = progressBarColor.cgColor
            $0.lineWidth = progressBarHeight
            $0.strokeColor = progressBarColor.cgColor
            $0.strokeStart = 0
            $0.strokeEnd = 0
            layer.addSublayer($0)
        }
    }

    private func updateLineLayers() {
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: 0, y: bounds.midY))
        linePath.addLine(to: CGPoint(x: bounds.width, y: bounds.midY))

        progressComponents.forEach {
            $0.path = linePath.cgPath
            $0.frame = CGRect(x: 0, y: 0, width: bounds.width, height: progressBarHeight)
        }
    }

    private func updateProgressBarColor() {
        progressComponents.forEach {
            $0.fillColor = progressBarColor.cgColor
            $0.strokeColor = progressBarColor.cgColor
        }
    }

    private func updateProgressBarWidth() {
        progressComponents.forEach {
            $0.lineWidth = progressBarHeight
        }
        updateLineLayers()
    }

    private func updateCornerRadius() {
        layer.cornerRadius = cornerRadius
    }

    open func startAnimating() {
        guard !isAnimating else { return }
        isAnimating = true
        applyProgressAnimations()
    }

    open func stopAnimating() {
        guard isAnimating else { return }
        isAnimating = false
        removeProgressAnimations()
    }

    // MARK: - Private

    private func applyProgressAnimations() {
        applyFirstComponentAnimations(to: firstProgressComponent)
        applySecondComponentAnimations(to: secondProgressComponent)
    }

    private func applyFirstComponentAnimations(to layer: CALayer) {
        let strokeEndAnimation = CAKeyframeAnimation(keyPath: "strokeEnd")
        strokeEndAnimation.values = [0, 1]
        strokeEndAnimation.keyTimes = [0, NSNumber(value: 1.2 / animationDuration)]
        strokeEndAnimation.timingFunctions = [CAMediaTimingFunction(name: .easeOut),
                                              CAMediaTimingFunction(name: .easeOut)]

        let strokeStartAnimation = CAKeyframeAnimation(keyPath: "strokeStart")
        strokeStartAnimation.values = [0, 1.2]
        strokeStartAnimation.keyTimes = [NSNumber(value: 0.25 / animationDuration),
                                         NSNumber(value: 1.8 / animationDuration)]
        strokeStartAnimation.timingFunctions = [CAMediaTimingFunction(name: .easeIn),
                                                CAMediaTimingFunction(name: .easeIn)]

        [strokeEndAnimation, strokeStartAnimation].forEach {
            $0.duration = animationDuration
            $0.repeatCount = .infinity
        }

        layer.add(strokeEndAnimation, forKey: "firstComponentStrokeEnd")
        layer.add(strokeStartAnimation, forKey: "firstComponentStrokeStart")

    }

    private func applySecondComponentAnimations(to layer: CALayer) {
        let strokeEndAnimation = CAKeyframeAnimation(keyPath: "strokeEnd")
        strokeEndAnimation.values = [0, 1.1]
        strokeEndAnimation.keyTimes = [NSNumber(value: 1.375 / animationDuration), 1]

        let strokeStartAnimation = CAKeyframeAnimation(keyPath: "strokeStart")
        strokeStartAnimation.values = [0, 1]
        strokeStartAnimation.keyTimes = [NSNumber(value: 1.825 / animationDuration), 1]

        [strokeEndAnimation, strokeStartAnimation].forEach {
            $0.timingFunctions = [CAMediaTimingFunction(name: .easeOut),
                                  CAMediaTimingFunction(name: .easeOut)]
            $0.duration = animationDuration
            $0.repeatCount = .infinity
        }

        layer.add(strokeEndAnimation, forKey: "secondComponentStrokeEnd")
        layer.add(strokeStartAnimation, forKey: "secondComponentStrokeStart")
    }

    private func removeProgressAnimations() {
        progressComponents.forEach { $0.removeAllAnimations() }
    }
}
