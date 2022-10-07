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

import Foundation

/// Arrrow graphic class
class ArrowGraphic: UIView {
    private enum Constants {
        static let arrowLength = 52.0
        static let headWidth = 10.0
        static let headHeight = 17.0
        static let lineWidth = 1.0
    }
    private var color: Color = ColorName.greenSpring.color

    enum ArrowDirection {
        case horizontal
        case vertical
    }
    var direction: ArrowDirection = .horizontal

    required init?(coder: NSCoder) {
        fatalError("Should never init with coder")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    convenience init(color: Color, direction: ArrowDirection) {
        let frame = CGRect(center: CGPoint.zero, width: Constants.headWidth, height: Constants.arrowLength)
        self.init(frame: frame)

        backgroundColor = .clear
        self.color = color
        self.direction = direction
        if direction == .horizontal {
            self.transform = transform.rotated(by: CGFloat.pi / 2)
        }
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.beginPath()
        // Draw an arrow.
        context.move(to: CGPoint(x: (rect.maxX - Constants.lineWidth) / 2, y: rect.maxY))
        context.addLine(to: CGPoint(x: (rect.maxX - Constants.lineWidth) / 2, y: rect.minY + Constants.headHeight))
        context.addLine(to: CGPoint(x: rect.minX, y: rect.minY + Constants.headHeight))
        context.addLine(to: CGPoint(x: rect.maxX / 2, y: rect.minY))
        context.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + Constants.headHeight))
        context.addLine(to: CGPoint(x: (rect.maxX + Constants.lineWidth) / 2, y: rect.minY + Constants.headHeight))
        context.addLine(to: CGPoint(x: (rect.maxX + Constants.lineWidth) / 2, y: rect.maxY))
        context.closePath()
        context.setFillColor(color.cgColor)
        context.fillPath()
    }

    /// Update the origin position
    ///
    /// - Parameters:
    ///    - position: the new position of the arrow
    func updatePosition(_ position: CGPoint) {
        var origin: CGPoint
        switch direction {
        case .horizontal:
            origin = CGPoint(x: position.x, y: position.y - Constants.headWidth / 2)
        case .vertical:
            origin = CGPoint(x: position.x - Constants.headWidth / 2, y: position.y - Constants.arrowLength)
        }
        frame = CGRect(origin: origin, size: frame.size)
    }
}
