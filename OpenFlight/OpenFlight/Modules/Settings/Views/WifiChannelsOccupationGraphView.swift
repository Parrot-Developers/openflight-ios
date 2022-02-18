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
import GroundSdk

/// Wifi Channels Occupation Graph View.
final class WifiChannelsOccupationGraphView: WifiChannelsOccupationView {
    // MARK: - Private Properties
    private let topSlopeArray: [CGFloat] = [0.15, 0.06, 0.03, 0.33, 0.3]
    private let topInterceptArray: [CGFloat] = [0.42, 0.69, 0.87, 0.81, 0.79]
    private let bottomSlopeArray: [CGFloat] = [0.42, 0.96, 0.6, 0.96, 2.28]
    private let bottomInterceptArray: [CGFloat] = [0.09, 0.75, 1.92, 3.0, 3.0]

    // MARK: - Overrides
    override func draw(_ rect: CGRect) {
        if let context: CGContext = UIGraphicsGetCurrentContext() {

            let height: CGFloat = rect.size.height
            let columnWidth: CGFloat = rect.size.width / CGFloat(channelsOccupations.count + 1)

            // for each entry, draw a curve to the path
            for (index, channel) in sortedChannels.enumerated() {
                let path = CGMutablePath()
                let occupation = channelsOccupations[channel] ?? 0
                let channelIndex = index + 1

                let rangeWidth: CGFloat = channel.is2_4GhzBand() ? 5.0 : 1.0
                let numberOfChannelRecover: Int = channel.is2_4GhzBand() ? 5 : 1
                let topSlope = topSlopeArray[numberOfChannelRecover - 1]
                let topIntercept = topInterceptArray[numberOfChannelRecover - 1]
                let bottomSlope = bottomSlopeArray[numberOfChannelRecover - 1]
                let bottomIntercept = bottomInterceptArray[numberOfChannelRecover - 1]

                // add a path that goes from startPoint to endPoint passing by middlePoint
                // startPoint is at the bottom, in the middle of the current column
                let startPoint = CGPoint(x: (columnWidth * (CGFloat(channelIndex) - rangeWidth)) + columnWidth / 2.0, y: -1.0)
                // endPoint is at the bottom, in the middle of the next column
                let endPoint = CGPoint(x: (columnWidth * (CGFloat(channelIndex) + (rangeWidth - 1.0))) + columnWidth / 2.0, y: -1.0)
                // middle point is the peak
                let occupationRatio = (maxOccupation > 0) ? CGFloat(occupation) / CGFloat(maxOccupation) : 0.0
                let middlePoint = CGPoint(x: columnWidth * CGFloat(channelIndex), y: occupationRatio * frame.size.height)

                path.move(to: CGPoint(x: startPoint.x, y: height - (startPoint.y)))

                // first draw the ascending curve (from startPoint to middlePoint)
                var deltaYFactor = CGFloat(middlePoint.y - startPoint.y) / CGFloat(Values.oneHundred)
                var controlPointXTopFactor = deltaYFactor * topSlope + topIntercept
                var controlPointXBottomFactor = deltaYFactor * bottomSlope + bottomIntercept

                path.addCurve(to: CGPoint(x: middlePoint.x, y: height - middlePoint.y),
                               control1: CGPoint(x: startPoint.x + columnWidth * controlPointXBottomFactor, y: height - startPoint.y),
                               control2: CGPoint(x: middlePoint.x - columnWidth * controlPointXTopFactor, y: height - middlePoint.y))

                // then draw the descending curve (from middlePoint to endPoint)
                deltaYFactor = (middlePoint.y - endPoint.y) / CGFloat(Values.oneHundred)
                controlPointXTopFactor = deltaYFactor * topSlope + topIntercept
                controlPointXBottomFactor = deltaYFactor * bottomSlope + bottomIntercept

                path.addCurve(to: CGPoint(x: endPoint.x, y: height - endPoint.y),
                               control1: CGPoint(x: middlePoint.x + columnWidth * controlPointXTopFactor, y: height - middlePoint.y),
                               control2: CGPoint(x: endPoint.x - columnWidth * controlPointXBottomFactor, y: height - endPoint.y))

                // close the path
                path.closeSubpath()

                context.addPath(path)

                let strokeColor = UIColor.clear.cgColor
                let fillColor = ColorName.disabledHighlightColor.color.cgColor
                context.setStrokeColor(strokeColor)
                context.setFillColor(fillColor)
                context.drawPath(using: .fillStroke)
            }
        }
    }
}
