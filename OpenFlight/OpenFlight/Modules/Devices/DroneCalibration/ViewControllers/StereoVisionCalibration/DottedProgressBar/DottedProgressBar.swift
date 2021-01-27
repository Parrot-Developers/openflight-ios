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

import Foundation
import UIKit
import GroundSdk

/// Custom class to setup and animate dotted progress bar view.
class DottedProgressBar: UIView {

    struct DottedProgressAppearance {
        let dotRadius: CGFloat
        let dotsColor: UIColor
        let dotsProgressColor: UIColor
        let backColor: UIColor

        public init(dotRadius: CGFloat = 4.0,
                    dotsColor: UIColor = ColorName.white50.color,
                    dotsProgressColor: UIColor = ColorName.greenSpring.color,
                    backColor: UIColor = UIColor.clear) {
            self.dotRadius = dotRadius
            self.dotsColor = dotsColor
            self.dotsProgressColor = dotsProgressColor
            self.backColor = backColor
        }
    }

    open var progressAppearance: DottedProgressAppearance!

    // MARK: - Private Properties
    fileprivate var numberOfDots: Int = 1
    fileprivate var previousProgress: Int = 0
    fileprivate var currentProgress: Int = 0
    fileprivate lazy var animationQueue = DottedBarAnimationQueue()
    fileprivate var isAnimatingCurrently: Bool = false
    fileprivate lazy var walkingDot = UIView()

    // MARK: - Init
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public init(frame: CGRect) {
        progressAppearance = DottedProgressAppearance()
        super.init(frame: frame)
        setup()
    }

    public init(frame: CGRect, numberOfDots: Int, initialProgress: Int) {
        progressAppearance = DottedProgressAppearance()
        super.init(frame: frame)
        self.numberOfDots = numberOfDots
        self.currentProgress = initialProgress
        setup()
    }

    public init(appearance: DottedProgressAppearance) {
        self.progressAppearance = appearance
        super.init(frame: CGRect.zero)
        setup()
    }
}

// MARK: - Internal Funcs
extension DottedProgressBar {

    /// Sets a number of steps of progress bar.
    ///
    /// - Parameters:
    ///   - count: Number of steps/dots.
    open func setNumberOfDots(_ count: Int) {
        animationQueue.enqueue(DottedBarAnimation(type: .numberChange, value: count))
        if !isAnimatingCurrently {
            performQueuedAnimations()
        }
    }

    /// Sets a number of filled dots as current progress.
    ///
    /// - Parameters:
    ///   - progress: Number of steps/dots of current progress.
    open func setProgress(_ progress: Int) {
        animationQueue.enqueue(DottedBarAnimation(type: .progresChange, value: progress))
        if !isAnimatingCurrently {
            performQueuedAnimations()
        }
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        layout()
    }
}

// MARK: - Private Funcs
private extension DottedProgressBar {

    /// Sets up view for dotted progress bar.
    func setup() {
        backgroundColor = progressAppearance.backColor

        for number in 0..<numberOfDots {
            let dot = UIView()
            dot.backgroundColor = number == currentProgress ? progressAppearance.dotsProgressColor :
                progressAppearance.dotsColor
            dot.layer.cornerRadius = progressAppearance.dotRadius
            dot.frame = dotFrame(forIndex: number)
            addSubview(dot)
        }
    }

    /// Draws layout of dot.
    func layout() {
        for (index, dot) in subviews.enumerated() where dot != walkingDot {
            dot.layer.cornerRadius = progressAppearance.dotRadius
            dot.frame = dotFrame(forIndex: index)
        }
    }

    /// Calculating frame for given index of dot, supports vertical and horizontal alignment.
    ///
    /// - Parameters:
    ///     - index: Index of dot (including 0).
    /// - Returns: Frame rectangle for given dot index
    func dotFrame(forIndex index: Int) -> CGRect {
        guard index >= 0 else {
            return dotFrame(forIndex: 0)
        }

        if frame.size.width > frame.size.height {
            let externalFrameWidth: CGFloat = frame.size.width / CGFloat(numberOfDots)
            let externalFrame = CGRect(x: CGFloat(index) * externalFrameWidth,
                                       y: 0.0,
                                       width: externalFrameWidth,
                                       height: frame.size.height)
            return CGRect(x: externalFrame.midX - progressAppearance.dotRadius,
                          y: externalFrame.midY - progressAppearance.dotRadius,
                          width: progressAppearance.dotRadius * 2,
                          height: progressAppearance.dotRadius * 2)
        } else {
            let externalFrameHeight: CGFloat = frame.size.height / CGFloat(numberOfDots)
            let externalFrame = CGRect(x: 0.0,
                                       y: CGFloat(index) * externalFrameHeight,
                                       width: frame.size.width,
                                       height: externalFrameHeight)
            return CGRect(x: externalFrame.midX - progressAppearance.dotRadius,
                          y: externalFrame.midY - progressAppearance.dotRadius,
                          width: progressAppearance.dotRadius * 2,
                          height: progressAppearance.dotRadius * 2)
        }
    }

    /// Starting execution of all queued animations.
    func performQueuedAnimations() {
        if let nextAnimation = animationQueue.dequeue() {
            isAnimatingCurrently = true
            if nextAnimation.type == .numberChange {
                if nextAnimation.value > 0 &&
                    nextAnimation.value >= currentProgress &&
                    nextAnimation.value != numberOfDots {
                    animateNumberChange(animation: nextAnimation)
                } else {

                    ULog.e(ULogTag(name: "DottedProgressBar - invalid setNumberOfDots \(nextAnimation.value)"))
                    self.performQueuedAnimations()
                }
            } else {
                if nextAnimation.value > 0 &&
                    nextAnimation.value <= numberOfDots &&
                    nextAnimation.value != currentProgress {
                    animateProgress(animation: nextAnimation)
                } else {
                    ULog.e(ULogTag(name: "DottedProgressBar - invalid setProgress \(nextAnimation.value)"))
                    self.performQueuedAnimations()
                }
            }
        } else {
            isAnimatingCurrently = false
        }
    }

    /// Performs animation for changing the number of dots.
    ///
    /// - Parameters:
    ///     - animation: The animation model
    func animateNumberChange(animation: DottedBarAnimation) {
        numberOfDots = animation.value

        if numberOfDots > subviews.count {
            self.layout()
            for _ in 0..<(self.numberOfDots - self.subviews.count) {
                let view = UIView()
                view.backgroundColor = self.progressAppearance.dotsColor
                view.layer.cornerRadius = self.progressAppearance.dotRadius
                view.alpha = 0.0
                self.addSubview(view)
            }

            for dot in self.subviews {
                dot.alpha = 1.0
            }
            self.performQueuedAnimations()
            self.layout()
        } else {
            for index in (Int(self.numberOfDots)..<self.subviews.count).reversed() {
                self.subviews[index].alpha = 0.0
                self.subviews[index].removeFromSuperview()
            }

            self.layout()
            self.performQueuedAnimations()

        }
    }

    /// Performs animation for changing the current progress.
    ///
    /// - Parameters:
    ///     - animation The animation model
    func animateProgress(animation: DottedBarAnimation) {
        previousProgress = currentProgress
        currentProgress = animation.value

        let dotsRange: CountableClosedRange = currentProgress > previousProgress ?
            previousProgress...currentProgress - 1 :
            currentProgress...previousProgress - 1

        for index in dotsRange {
            self.subviews[index].backgroundColor =
                self.currentProgress > self.previousProgress ?
                    self.progressAppearance.dotsProgressColor :
                self.progressAppearance.dotsColor
        }

        self.walkingDot.frame = self.dotFrame(forIndex: self.currentProgress - 1)
        self.walkingDot.removeFromSuperview()
        self.performQueuedAnimations()
    }
}
