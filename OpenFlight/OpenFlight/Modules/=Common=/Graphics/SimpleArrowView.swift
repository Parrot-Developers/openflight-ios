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

/// View that draws a simple arrow (isosceles triangle).
public final class SimpleArrowView: UIView {
    // MARK: - Public Properties
    /// Current orientation of the arrow.
    public var orientation: ArrowOrientation = .top {
        didSet {
            redrawTriangle()
        }
    }
    /// Current color of the arrow.
    public var color: UIColor = .white {
        didSet {
            redrawTriangle()
        }
    }

    // MARK: - Private Properties
    private var drawnLayer: CAShapeLayer?
    private var currentTriangle: Triangle {
        switch orientation {
        case .left:
            return Triangle(summitA: CGPoint(x: frame.width, y: 0),
                            summitB: CGPoint(x: frame.width, y: frame.height),
                            summitC: CGPoint(x: 0, y: frame.height / 2))
        case .right:
            return Triangle(summitA: CGPoint(x: 0, y: 0),
                            summitB: CGPoint(x: 0, y: frame.height),
                            summitC: CGPoint(x: frame.width, y: frame.height / 2))
        case .top:
            return Triangle(summitA: CGPoint(x: 0, y: frame.height),
                            summitB: CGPoint(x: frame.width, y: frame.height),
                            summitC: CGPoint(x: frame.width / 2, y: 0))
        case .bottom:
            return Triangle(summitA: CGPoint(x: 0, y: 0),
                            summitB: CGPoint(x: frame.width, y: 0),
                            summitC: CGPoint(x: frame.width / 2, y: frame.height))
        }
    }

    // MARK: - Public Enums
    /// Enum representing arrow orientation.
    public enum ArrowOrientation {
        case left
        case right
        case top
        case bottom
    }

    // MARK: - Private Structs
    /// Struct containing the coordinates of the triangle summits.
    private struct Triangle {
        var summitA: CGPoint
        var summitB: CGPoint
        var summitC: CGPoint
    }

    // MARK: - Override Funcs
    override public func draw(_ rect: CGRect) {
        super.draw(rect)
        redrawTriangle()
    }
}

// MARK: - Private Funcs
private extension SimpleArrowView {
    /// Removes previously drawn triangle and draws a new one with current properties.
    func redrawTriangle() {
        drawnLayer?.removeFromSuperlayer()
        let triangle = currentTriangle
        let path = UIBezierPath()
        path.move(to: triangle.summitA)
        path.addLine(to: triangle.summitB)
        path.addLine(to: triangle.summitC)
        path.close()
        let sublayer = CAShapeLayer()
        sublayer.path = path.cgPath
        sublayer.fillColor = color.cgColor
        layer.addSublayer(sublayer)
        drawnLayer = sublayer
    }
}
