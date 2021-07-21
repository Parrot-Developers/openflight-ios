//
//  LDGradientView.swift
//  OpenFlight
//
//  Created by Frédéric d'HAYER on 29/06/2021.
//  Copyright © 2021 Parrot Drones SAS. All rights reserved.
//

import Foundation

@IBDesignable
class LDGradientView: UIView {
    // the gradient start colour
    @IBInspectable var startColor: UIColor?
    // the gradient end colour
    @IBInspectable var endColor: UIColor?
    // the gradient angle, in degrees anticlockwise from 0 (east/right)
    @IBInspectable var angle: CGFloat = 270

    // the gradient layer
    private var gradient: CAGradientLayer?

    override var frame: CGRect {
        didSet {
            updateGradient()
        }
    }

    // initializers
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        installGradient()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        installGradient()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // this is crucial when constraints are used in superviews
        updateGradient()
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        installGradient()
        updateGradient()
    }

    // create gradient layer
    private func createGradient() -> CAGradientLayer {
        let gradient = CAGradientLayer()
        gradient.frame = self.bounds
        return gradient
    }

    // Create a gradient and install it on the layer
    private func installGradient() {
        // if there's already a gradient installed on the layer, remove it
        if let gradient = self.gradient {
            gradient.removeFromSuperlayer()
        }
        let gradient = createGradient()
        self.layer.insertSublayer(gradient, at: 0)
        self.gradient = gradient
    }

    // Update an existing gradient
    private func updateGradient() {
        if let gradient = self.gradient {
            let startColor = self.startColor ?? UIColor.clear
            let endColor = self.endColor ?? UIColor.clear
            gradient.colors = [startColor.cgColor, endColor.cgColor]
            let (start, end) = gradientPointsForAngle(self.angle)
            gradient.startPoint = start
            gradient.endPoint = end
            gradient.frame = self.bounds
        }
    }

    private func transformToGradientSpace(_ point: CGPoint) -> CGPoint {
        // input point is in signed unit space: (-1,-1) to (1,1)
        // convert to gradient space: (0,0) to (1,1), with flipped Y axis
        return CGPoint(x: (point.x + 1) * 0.5, y: 1.0 - (point.y + 1) * 0.5)
    }

    private func oppositePoint(_ point: CGPoint) -> CGPoint {
        return CGPoint(x: -point.x, y: -point.y)
    }

    private func pointForAngle(_ angle: CGFloat) -> CGPoint {
        // convert degrees to radians
        let radians = angle * .pi / 180.0
        var anglex = cos(radians)
        var angley = sin(radians)
        // (anglex, angley) is in terms unit circle. Extrapolate to unit square to get full vector length
        if abs(anglex) > abs(angley) {
            // extrapolate x to unit length
            anglex = anglex > 0 ? 1 : -1
            angley = anglex * tan(radians)
        } else {
            // extrapolate y to unit length
            angley = angley > 0 ? 1 : -1
            anglex = angley / tan(radians)
        }
        return CGPoint(x: anglex, y: angley)
    }

    // create vector pointing in direction of angle
    private func gradientPointsForAngle(_ angle: CGFloat) -> (CGPoint, CGPoint) {
        // get vector start and end points
        let end = pointForAngle(angle)
        let start = oppositePoint(end)
        // convert to gradient space
        let point0 = transformToGradientSpace(start)
        let point1 = transformToGradientSpace(end)
        return (point0, point1)
    }

}
