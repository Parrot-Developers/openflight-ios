//    Copyright (C) 2022 Parrot Drones SAS
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

extension SettingsGridDisplayType {

    var gridMultiple: UInt {
        switch self {
        case .none:
            return 0
        case .s3x3:
            return 3
        case .s6x6:
            return 6
        }
    }
}

/// Grid view (3x3, 6x6)
final class GridView: OverlayStreamView {

    // MARK: Private Properties
    private enum Constants {
        static let lineWidth: CGFloat = 0.5
        static let strokeLineWidth: CGFloat = 1.5
        static let strokeAlpha: CGFloat = 0.25

        static let crosshairLineLength: CGFloat = 8
        static let crosshairStrokeLineLength: CGFloat = 8.5
    }
    private var lineColor = ColorName.white.color
    private var strokeColor = ColorName.black.color.withAlphaComponent(Constants.strokeAlpha)
    private var contentZone: CGRect = CGRect.zero

    // MARK: Public Properties
    var gridDisplayType: SettingsGridDisplayType = .none {
        didSet {
            guard oldValue != gridDisplayType else { return }
            contentMode = .redraw
            setNeedsDisplay()
        }
    }

    override func update(frame: CGRect) {
        super.update(frame: frame)
        contentZone = frame
        contentMode = .redraw
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        drawGrid()
        drawCrosshair()
    }
}

private extension GridView {

    var gridWidth: CGFloat {
        contentZone.width / CGFloat(gridDisplayType.gridMultiple)
    }

    var gridHeight: CGFloat {
        contentZone.height / CGFloat(gridDisplayType.gridMultiple)
    }

    func getGridPath(lineWidth: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        path.lineWidth = lineWidth

        for index in 1...Int(gridDisplayType.gridMultiple) - 1 {
            // Horizontal lines
            let start = CGPoint(x: contentZone.origin.x + CGFloat(index) * gridWidth, y: contentZone.origin.y)
            let end = CGPoint(x: contentZone.origin.x + CGFloat(index) * gridWidth, y: contentZone.origin.y + contentZone.height)
            path.move(to: start)
            path.addLine(to: end)
        }

        for index in 1...Int(gridDisplayType.gridMultiple) - 1 {
            // Vertical lines
            let start = CGPoint(x: contentZone.origin.x, y: contentZone.origin.y + CGFloat(index) * gridHeight)
            let end = CGPoint(x: contentZone.origin.x + contentZone.width, y: contentZone.origin.y + CGFloat(index) * gridHeight)
            path.move(to: start)
            path.addLine(to: end)
        }
        path.close()

        return path
    }

    func getCrosshairPath(lineWidth: CGFloat, lineLength: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        path.lineWidth = lineWidth
        let center = contentZone.center

        // Horizontal line
        path.move(to: CGPoint(x: center.x - lineLength, y: center.y))
        path.addLine(to: CGPoint(x: center.x + lineLength, y: center.y))

        // Vertical line
        path.move(to: CGPoint(x: center.x, y: center.y - lineLength))
        path.addLine(to: CGPoint(x: center.x, y: center.y + lineLength))

        path.close()

        return path
    }

    func drawGrid() {
        guard gridDisplayType != .none else { return }

        // Draw stroke
        let strokePath = getGridPath(lineWidth: Constants.strokeLineWidth)
        strokeColor.setStroke()
        strokePath.stroke()

        // Draw line
        let linePath = getGridPath(lineWidth: Constants.lineWidth)
        lineColor.setStroke()
        linePath.stroke()
    }

    func drawCrosshair() {
        guard gridDisplayType == .s3x3 else { return }

        // Draw stroke
        let strokePath = getCrosshairPath(lineWidth: Constants.strokeLineWidth, lineLength: Constants.crosshairStrokeLineLength)
        strokeColor.setStroke()
        strokePath.stroke()

        // Draw line
        let linePath = getCrosshairPath(lineWidth: Constants.lineWidth, lineLength: Constants.crosshairLineLength)
        lineColor.setStroke()
        linePath.stroke()
    }
}
