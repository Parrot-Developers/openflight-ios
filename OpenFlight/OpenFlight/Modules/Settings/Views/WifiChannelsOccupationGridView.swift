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
import GroundSdk

// MARK: - Protocols
/// Wifi Channels Occupation Grid Delegate.
protocol WifiChannelsOccupationGridViewDelegate: AnyObject {
    /// Notifies delegate when user selected channel.
    func userDidSelectChannel(_ channel: WifiChannel)
}

/// Wifi Channels Occupation Grid View.
final class WifiChannelsOccupationGridView: WifiChannelsOccupationView {
    // MARK: - Private Enums
    private enum Constants {
        static let lineWidth: CGFloat = 0.5
        static let extraRoundingPosition: CGFloat = 0.5
        static let labelRectMargin: CGFloat = 2.0
        static let defaultColor: UIColor = ColorName.white50.color
        static let dotSize: CGSize = CGSize(width: 1.0, height: 1.0)
    }

    // MARK: - Internal Properties
    var currentChannel: WifiChannel?
    weak var delegate: WifiChannelsOccupationGridViewDelegate?

    // MARK: - Overrides Funcs
    override func draw(_ rect: CGRect) {
        // Draw selected channel.
        drawCurrentChannelItem()
        if let context = UIGraphicsGetCurrentContext(),
            !channelsOccupations.isEmpty {
            let range: CGFloat = rect.size.width / CGFloat(channelsOccupations.count + 1)

            // Draw bottom line.
            context.setStrokeColor(Constants.defaultColor.cgColor)
            context.setLineWidth(Constants.lineWidth)
            context.move(to: CGPoint(x: range / 2.0, y: 0.0))
            context.addLine(to: CGPoint(x: range / 2.0, y: rect.size.height))
            context.drawPath(using: .stroke)

            // Draw vertical lines.
            for (index, channel) in sortedChannels.enumerated() {
                context.setStrokeColor(Constants.defaultColor.cgColor)
                context.setLineWidth(Constants.lineWidth)
                context.move(to: CGPoint(x: range * CGFloat(index + 1) + range / 2.0, y: 0.0))
                context.addLine(to: CGPoint(x: range * CGFloat(index + 1) + range / 2.0, y: rect.size.height))
                context.drawPath(using: .stroke)

                let textToDisplay = "\(channel.getChannelId())"
                var color = Constants.defaultColor
                var font = ParrotFontStyle.largeMedium.font
                if channel == currentChannel {
                    color = ColorName.greenSpring.color
                    font = ParrotFontStyle.large.font
                }
                let ssidString = NSAttributedString(string: textToDisplay,
                                                    attributes: [NSAttributedString.Key.font: font,
                                                                 NSAttributedString.Key.foregroundColor: color])

                let labelRect = CGRect(x: range * CGFloat(index + 1) - ssidString.size().width / 2.0,
                                       y: frame.height / 2.0 - ssidString.size().height / 2.0,
                                       width: ssidString.size().width,
                                       height: ssidString.size().height)
                ssidString.draw(in: labelRect)
            }

            // Draw Wifi bands.
            let color = Constants.defaultColor
            let font = ParrotFontStyle.regular.font
            if has2_4GhzBand() {
                let textToDisplay = L10n.wifiBand24
                let ssidString = NSAttributedString(string: textToDisplay,
                                                    attributes: [NSAttributedString.Key.font: font,
                                                                 NSAttributedString.Key.foregroundColor: color])
                let labelRect = CGRect(x: range/2.0 + Constants.labelRectMargin,
                                       y: 0.0,
                                       width: ssidString.size().width,
                                       height: ssidString.size().height)
                ssidString.draw(in: labelRect)
            }
            if has5GhzBand() {
                let textToDisplay = L10n.wifiBand5
                let ssidString = NSAttributedString(string: textToDisplay,
                                                    attributes: [NSAttributedString.Key.font: font,
                                                                 NSAttributedString.Key.foregroundColor: color])
                let count = sortedChannels.filter({ $0.is2_4GhzBand()}).count
                let labelRect = CGRect(x: range * (CGFloat(count) + 1.0 / 2.0) + Constants.labelRectMargin,
                                       y: 0.0,
                                       width: ssidString.size().width,
                                       height: ssidString.size().height)
                ssidString.draw(in: labelRect)
            }

            // Draw dotted line.
            for index in Int(range / 2.0)...Int(rect.size.width - range / 2.0) where index % 2 == 0 {
                let rectangle = CGRect(x: CGFloat(index),
                                       y: self.frame.size.height - 1.0,
                                       width: Constants.dotSize.width,
                                       height: Constants.dotSize.height)
                context.setFillColor(UIColor.white.cgColor)
                context.setStrokeColor(UIColor.white.cgColor)
                context.fill(rectangle)
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let point = touch.location(in: self)
            let range = frame.size.width / CGFloat(channelsOccupations.count + 1)

            let channelPosition = point.x / range + Constants.extraRoundingPosition
            let channelIndex = Int(channelPosition) - 1
            if sortedChannels.indices.contains(channelIndex) {
                delegate?.userDidSelectChannel(sortedChannels[channelIndex])
            }
        }
    }
}

// MARK: - Private Funcs
private extension WifiChannelsOccupationGridView {
    /// Draws current channel item.
    func drawCurrentChannelItem() {
        if let currentChannel = currentChannel,
            let index = sortedChannels.firstIndex(of: currentChannel),
            let ctx = UIGraphicsGetCurrentContext() {

            let range: CGFloat = frame.size.width / CGFloat(channelsOccupations.count + 1)

            let rectangle = CGRect(x: range * CGFloat(index + 1) - range / 2,
                                   y: 0,
                                   width: range,
                                   height: frame.size.height)

            let color1 = UIColor(named: .greenPea50)
            let color2 = UIColor(named: .greenPea)

            ctx.setFillColor(color1.cgColor)
            ctx.setStrokeColor(color2.cgColor)

            ctx.fill(rectangle)
            ctx.stroke(rectangle)
        }
    }
}
