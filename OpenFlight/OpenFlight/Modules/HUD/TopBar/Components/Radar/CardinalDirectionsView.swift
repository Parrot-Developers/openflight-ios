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
import Reusable

// MARK: - Internal Structs
/// Model for cardinal direction view.
struct CardinalDirectionsModel {
    /// Current observer heading.
    var heading: Double = 0.0
}

/// Class that adds labels for cardinal directions seperated by graduated views inside HUDRadarView.
final class CardinalDirectionsView: UIScrollView, NibOwnerLoadable {
    // MARK: - Internal Properties
    var model = CardinalDirectionsModel() {
        didSet {
            fill(with: model)
        }
    }

    // MARK: - Private Properties
    private var visibleLabels = [UILabel]()
    private var labelContainerView: UIView!
    private var initialized: Bool = false
    private var patternOffset: CGFloat = 0.0

    // MARK: - Private Enums
    private enum Constants {
        static let labelWidth: CGFloat = CGFloat(CardinalDirections.fullAngle / 3.0)
        static let contentWidth: CGFloat = 5000.0
    }

    /// Enum representing a cardinal direction.
    private enum CardinalDirections {
        case north
        case northEast
        case east
        case southEast
        case south
        case southWest
        case west
        case northWest

        var symbol: String {
            switch self {
            case .north:
                return L10n.cardinalDirectionNorth
            case .northEast:
                return L10n.cardinalDirectionNorthEast
            case .east:
                return L10n.cardinalDirectionEast
            case .southEast:
                return L10n.cardinalDirectionSouthEast
            case .south:
                return L10n.cardinalDirectionSouth
            case .southWest:
                return L10n.cardinalDirectionSouthWest
            case .west:
                return L10n.cardinalDirectionWest
            case .northWest:
                return L10n.cardinalDirectionNorthWest
            }
        }

        static let allCases: [CardinalDirections] = [.north,
                                                     .northEast,
                                                     .east,
                                                     .southEast,
                                                     .south,
                                                     .southWest,
                                                     .west,
                                                     .northWest]

        static let fullAngle: Float = 360.0
    }

    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.loadNibContent()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNibContent()
    }

    // MARK: - Override Funcs
    override func layoutSubviews() {
        super.layoutSubviews()

        if !initialized {
            commonInit()
            initialized = true
        }

        recenterIfNeeded()

        // tile content in visible bounds
        let visibleBounds = convert(bounds, to: labelContainerView)
        let minimumVisibleX = visibleBounds.minX
        let maximumVisibleX = visibleBounds.maxX

        tileLabelsFromMinX(minimumVisibleX: minimumVisibleX, toMaxX: maximumVisibleX)
    }
}

// MARK: - Private Funcs
private extension CardinalDirectionsView {
    /// Common Init.
    func commonInit() {
        contentSize = CGSize(width: Constants.contentWidth, height: bounds.size.height)
        labelContainerView = GraduatedView(frame: CGRect(x: 0, y: 0, width: contentSize.width, height: contentSize.height))
        addSubview(labelContainerView)
        labelContainerView.isUserInteractionEnabled = false
        labelContainerView.backgroundColor = .clear
        showsHorizontalScrollIndicator = false
        isScrollEnabled = false
    }

    /// Fills view with given model.
    ///
    /// - Parameters:
    ///    - model: model containing current observer heading
    func fill(with model: CardinalDirectionsModel) {
        let startOffset = (contentSize.width - bounds.size.width) / 2.0
        let cardinalOffset = Constants.labelWidth * CGFloat(CardinalDirections.allCases.count) * CGFloat(model.heading) / CGFloat(CardinalDirections.fullAngle)
        let centerOffset = (bounds.size.width - Constants.labelWidth) / 2.0
        contentOffset = CGPoint(x: startOffset + cardinalOffset - centerOffset - patternOffset, y: 0.0)
    }

    /// Recenters the view if the distance from center is too high.
    func recenterIfNeeded() {
        let currentOffset = contentOffset
        let contentWidth = contentSize.width
        let centerOffsetX = (contentWidth - bounds.size.width) / 2.0
        let distanceFromCenter = abs(currentOffset.x - centerOffsetX)

        if distanceFromCenter > (contentWidth / 4.0) {
            contentOffset = CGPoint(x: centerOffsetX, y: currentOffset.y)

            // Move content by the same amount so it appears to stay still.
            for label in visibleLabels {
                var center = labelContainerView.convert(label.center, to: self)
                center.x += (centerOffsetX - currentOffset.x)
                label.center = convert(center, to: labelContainerView)
            }
        }
    }

    /// Creates a new label with given string and adds it to container.
    ///
    /// - Parameters:
    ///    - text: text to display
    func insertLabel(text: String) -> UILabel {
        let label = UILabel(frame: CGRect(x: 0.0,
                                          y: 0.0,
                                          width: Constants.labelWidth,
                                          height: labelContainerView.frame.height))
        label.text = text
        label.textAlignment = .center
        label.makeUp()
        labelContainerView.addSubview(label)
        return label
    }

    /// Creates a new label on the right of the container.
    ///
    /// - Parameters:
    ///    - rightEdge: distance between label and container edge
    func placeNewLabelOnRight(rightEdge: CGFloat) -> CGFloat {
        var text = CardinalDirections.north.symbol
        if let lastText = visibleLabels.last?.text,
            let lastIndex = CardinalDirections.allCases.firstIndex(where: { $0.symbol == lastText }),
            lastIndex < CardinalDirections.allCases.count - 1 {
            text = CardinalDirections.allCases[lastIndex + 1].symbol
        }
        let label = insertLabel(text: text)
        // add rightmost label at the end of the array
        visibleLabels.append(label)

        label.frame.origin.x = rightEdge
        label.frame.origin.y = labelContainerView.bounds.size.height - label.frame.size.height

        return label.frame.maxX
    }

    /// Creates a new label on the left of the container.
    ///
    /// - Parameters:
    ///    - leftEdge: distance between label and container edge
    func placeNewLabelOnLeft(leftEdge: CGFloat) -> CGFloat {
        var text = CardinalDirections.northWest.symbol
        if let firstText = visibleLabels.first?.text,
            let firstIndex = CardinalDirections.allCases.firstIndex(where: { $0.symbol == firstText }),
            firstIndex >= 1 {
            text = CardinalDirections.allCases[firstIndex - 1].symbol
        }
        let label = insertLabel(text: text)
        // add leftmost label at the beginning of the array
        visibleLabels.insert(label, at: 0)

        label.frame.origin.x = leftEdge - label.frame.size.width
        label.frame.origin.y = labelContainerView.bounds.size.height - label.frame.size.height

        return label.frame.minX
    }

    /// Updates all labels for cardinal direction to view.
    ///
    /// - Parameters:
    ///    - minimumVisibleX: minimum position for a label to be visible.
    ///    - maximumVisibleX: maximum position for a label to be visible.
    func tileLabelsFromMinX(minimumVisibleX: CGFloat, toMaxX maximumVisibleX: CGFloat) {
        // the upcoming tiling logic depends on already having at least one label in the visibleLabels array, so
        // to kick off the tiling we need to make sure there's at least one label
        if visibleLabels.isEmpty {
            patternOffset = minimumVisibleX.truncatingRemainder(dividingBy: Constants.labelWidth)
            _ = placeNewLabelOnRight(rightEdge: minimumVisibleX - patternOffset)
        }

        // add labels that are missing on right side
        if let lastLabel = visibleLabels.last {
            var rightEdge = lastLabel.frame.maxX
            while rightEdge < maximumVisibleX {
                rightEdge = placeNewLabelOnRight(rightEdge: rightEdge)
            }
        }
        // add labels that are missing on left side
        if let firstLabel = visibleLabels.first {
            var leftEdge = firstLabel.frame.minX
            while leftEdge > minimumVisibleX {
                leftEdge = placeNewLabelOnLeft(leftEdge: leftEdge)
            }
        }

        // remove labels that have fallen off right edge
        var lastLabel = visibleLabels.last
        while lastLabel != nil, lastLabel?.frame.origin.x ?? 0 > maximumVisibleX {
            lastLabel?.removeFromSuperview()
            visibleLabels.removeLast()
            lastLabel = visibleLabels.last
        }

        // remove labels that have fallen off left edge
        var firstLabel = visibleLabels.first
        while firstLabel != nil, firstLabel?.frame.maxX ?? 0 < minimumVisibleX {
            firstLabel?.removeFromSuperview()
            visibleLabels.removeFirst()
            firstLabel = visibleLabels.first
        }
    }
}
