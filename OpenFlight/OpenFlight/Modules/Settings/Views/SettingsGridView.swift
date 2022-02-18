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

/// Settings grid view Manages background grid display.
class SettingsGridView: UIView {
    // MARK: - Internal Properties
    var isYAxisHidden: Bool = false
    var isXAxisHidden: Bool = false

    // MARK: - Private Properties
    private var path = UIBezierPath()
    private var gridSize: CGFloat {
        return bounds.height / gridSizeDivisor
    }
    private var gridSizeDivisor : CGFloat {
        let divisor = isRegularSizeClass ? Constants.gridAverageSizeRegular : Constants.gridAverageSize
        return round(bounds.height / divisor)
    }

    // MARK: - Private Enums
    private enum Constants {
        static let gridLineWidth: CGFloat = 1.0
        static let axisLineWidth: CGFloat = 2.0
        static let gridAverageSize: CGFloat = 25
        static let gridAverageSizeRegular: CGFloat = 50
    }

    // MARK: - Override Funcs
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        UIColor.white.setFill()
        context.fill(rect)

        drawGrid()
        ColorName.defaultTextColor20.color.setStroke()
        path.stroke()

        drawGridAxes()
        ColorName.defaultTextColor.color.setStroke()
        path.stroke()
    }

    // MARK: - Internal Funcs
    /// Compute value to create an exponential like function.
    ///
    /// - Parameters:
    ///    - value: the value to transform in percent
    ///    - max: the max value
    ///    - min: the min value
    class func computeExponentialLike(value: Double, max: Double, min: Double) -> Double {
        return (pow(value, 2) / pow(Values.oneHundred, 2)) * (max - min) + min
    }

    /// Reverse the value of the exponential like function.
    ///
    /// - Parameters:
    ///    - value: the value to transform in percent
    ///    - max: the max value
    ///    - min: the min value
    class func reverseExponentialLike(value: Double, max: Double, min: Double) -> Double {
        let result = sqrt(((value - min) / (max - min)) * pow(Values.oneHundred, 2))
        return result.isNaN ? 0 : result
    }
}

// MARK: - Private Funcs
private extension SettingsGridView {
    /// Draw grid.
    func drawGrid() {
        path = UIBezierPath()
        path.lineWidth = Constants.gridLineWidth

        // Horizontal lines.
        for index in 0...Int(bounds.height) {
            let start = CGPoint(x: CGFloat(index) * gridSize, y: 0.0)
            let end = CGPoint(x: CGFloat(index) * gridSize, y: bounds.height)
            path.move(to: start)
            path.addLine(to: end)
        }

        // Vertical lines.
        for index in 0...Int(bounds.width / gridSizeDivisor) - 1 {
            let start = CGPoint(x: 0, y: CGFloat(index) * gridSize)
            let end = CGPoint(x: bounds.width, y: CGFloat(index) * gridSize)
            path.move(to: start)
            path.addLine(to: end)
        }
        path.close()
    }

    /// Draw axes.
    func drawGridAxes() {
        path = UIBezierPath()
        path.lineWidth = Constants.axisLineWidth

        // X axis
        if !isXAxisHidden {
            let start = CGPoint(x: 0, y: bounds.height)
            let end = CGPoint(x: bounds.width, y: bounds.height)
            path.move(to: start)
            path.addLine(to: end)
        }

        // Y axis
        if !isYAxisHidden {
            let start = CGPoint(x: 0, y: 0)
            let end = CGPoint(x: 0, y: bounds.height)
            path.move(to: start)
            path.addLine(to: end)
        }

        path.close()
    }
}
