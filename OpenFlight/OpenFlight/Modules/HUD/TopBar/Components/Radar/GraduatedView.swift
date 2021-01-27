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

import UIKit

/// View drawing an horizontal graduation.

final class GraduatedView: UIView {

    // MARK: - Private Enums
    private enum Constants {
        static let graduationWidth: CGFloat = 1
        static let graduationSpace: CGFloat = 7.5
        static let divisionsNumber: CGFloat = 14
        static let strokeColor: UIColor = .white
        static let heightMultiplier: CGFloat = 1/4
    }

    // MARK: - Override Funcs
    override func draw(_ rect: CGRect) {
        drawSections()
    }

    // MARK: - Private Funcs
    private func drawSections() {
        let path = UIBezierPath()
        path.lineWidth = Constants.graduationWidth
        let patternWidth = (Constants.divisionsNumber + 2) * Constants.graduationSpace
        let spaceOffset = patternWidth / 2
        var valX: CGFloat = 0.0

        while valX < bounds.width {
            if (valX - spaceOffset).truncatingRemainder(dividingBy: patternWidth) == 0.0 {
                valX += Constants.graduationSpace * 2
                continue
            }
            let start = CGPoint(x: valX - Constants.graduationSpace / 2, y: 0)
            let end = CGPoint(x: valX - Constants.graduationSpace / 2, y: bounds.height * Constants.heightMultiplier)
            path.move(to: start)
            path.addLine(to: end)
            valX += Constants.graduationSpace
        }

        path.close()
        Constants.strokeColor.setStroke()
        path.stroke()
    }
}
